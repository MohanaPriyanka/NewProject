/**
 * Created by PeterYao on 8/26/2019.
 * Tested by: ZuoraReturnedPaymentServiceTest
 */

public with sharing class ZuoraReturnedPaymentService implements Queueable, Database.AllowsCallouts {
    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();
    private static ZuoraPaymentMethodSelector paymentMethodSelector = new ZuoraPaymentMethodSelector();
    @TestVisible private List<Id> paymentIdsToReturn;
    @TestVisible private static ZuoraReturnedPaymentService chainedReturnedPaymentService;
    ZuoraDebitMemoGenerator debitMemoGenerator = new ZuoraDebitMemoGenerator();
    ZuoraAccountingPeriodService accountingPeriodService = new ZuoraAccountingPeriodService();
    private static Map<Object, SObject> emailTemplatesForReturnedPayments {
        get {
            if (emailTemplatesForReturnedPayments == null) {
                List<EmailTemplate> templates = [
                    SELECT Id, HtmlValue, DeveloperName
                    FROM EmailTemplate
                    WHERE DeveloperName LIKE 'Returned_Payment_Notification%'
                ];
                emailTemplatesForReturnedPayments = CollectionUtil.mapByField(templates, EmailTemplate.DeveloperName);
            }
            return emailTemplatesForReturnedPayments;
        }
        set;
    }

    /**
     * @description Constructor used when returning multiple payments
     * @param returnedPaymentIds List of Salesforce payment Ids to return
     */
    public ZuoraReturnedPaymentService(List<Id> returnedPaymentIds) {
        this.paymentIdsToReturn = returnedPaymentIds;
    }

    /**
     * @description To avoid callout limits when returning payments in bulk, returns the first payment in paymentsToReturn
     * and then queues itself to return the rest
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        if (paymentIdsToReturn.isEmpty()) {
            return;
        }

        try {
            PaymentReturnResult result = performReturn(paymentIdsToReturn[0]);
            if (!result.success) {
                Logger.logLater('ZuoraReturnedPaymentService', 'execute', 'Could not return paymentId ' + paymentIdsToReturn[0] + '\n', Logger.ERROR);
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraReturnedPaymentService', 'execute', e.getMessage() + '\n' + e.getStackTraceString() + '\n' + paymentIdsToReturn, Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }

        paymentIdsToReturn.remove(0);
        ZuoraReturnedPaymentService paymentServiceToQueue = new ZuoraReturnedPaymentService(paymentIdsToReturn);
        if (!paymentIdsToReturn.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(paymentServiceToQueue);
        } else {
            chainedReturnedPaymentService = paymentServiceToQueue;
        }
    }

    /**
     * @description Reverses payments that are found to be returned by leaving the payment as applied, but creating a
     * new debit memo with the current effective date. Will affect aging, since the original payment is left applied.
     * @param salesforcePaymentId Salesforce Payment Id to return
     * @return result of the return, suitable for displaying to user
     */
    public PaymentReturnResult performReturn(Id salesforcePaymentId) {
        List<Zuora__Payment__c> paymentsToReturn = paymentSelector.selectById(new Set<Id>{
            salesforcePaymentId
        });
        if (paymentsToReturn.size() != 1) {
            ZuoraReturnedPaymentService.PaymentReturnResult paymentReturnResult =
                new ZuoraReturnedPaymentService.PaymentReturnResult();
            paymentReturnResult.message = 'Expected a single Zuora Payment record to reverse';
            paymentReturnResult.success = false;
            return paymentReturnResult;
        }
        Zuora__Payment__c paymentToReturn = paymentsToReturn[0];
        ZuoraAPI.Payment zuoraPayment = checkIfPaymentIsAlreadyReturned(paymentToReturn.Zuora__EXT_ID__c);
        PaymentReturnResult paymentReturnResult = executeMarkPaymentAsReturned(zuoraPayment, paymentToReturn);
        insertCaseForReturns(paymentToReturn);
        Logger.flushLogs();
        return paymentReturnResult;
    }

    @TestVisible
    private ZuoraAPI.Payment checkIfPaymentIsAlreadyReturned(String paymentId) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/payments/' + paymentId, null, false);
        ZuoraAPI.Payment payment = (ZuoraAPI.Payment) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), ZuoraAPI.Payment.class);
        // Response status can be Approved, Declined, Error, RETURNED, Voided for history, or blank for payments just coming from Zuora
        // So the Zuora Payment should have a response status of blank or Approved to be returned
        if (!String.isBlank(payment.ResponseStatus_Zcustom) && !(payment.ResponseStatus_Zcustom == 'Approved')) {
            throw new Util.FatalBWException('This payment is already marked as returned: ' + payment);
        }
        return payment;
    }

    /**
     * @description Updates the Zuora payment's Response Status to be "Returned"
     * @param paymentId The Zuora Id of the Payment to mark returned
     */
    private void markPaymentReturned(String paymentId) {
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.ResponseStatus_Zcustom = 'Returned';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + paymentId, payment, false);
        ZuoraAPI.GenericResponse genericResponse = (ZuoraAPI.GenericResponse) JSON.deserialize(response.getBody(), ZuoraAPI.GenericResponse.class);
        if (!genericResponse.success) {
            throw new Util.BWException('Did not mark payment ' + paymentId + 'as Returned:\n' + response.getBody());
        }
    }

    /**
     * @description Updates the Zuora account to remove the payment method as default for the payment provided
     * @param returnedPayment A payment (presumably with a payment method that does not work)
     * @return True, if the payment method was removed from the account
     */
    @TestVisible
    private Boolean removePaymentMethodFromAccount(Zuora__Payment__c returnedPayment) {
        String zuoraAcctId = returnedPayment.Zuora__BillingAccount__r.Zuora__Zuora_Id__c;
        Boolean paymentMethodUpdateNeeded = false;
        ZuoraAccountSelector selector = new ZuoraAccountSelector();
        ZuoraAPI.ZuoraAccount accountFromZuora = selector.getAccountFromZuora(zuoraAcctId);

        // If they've already provided a new payment method, we don't want to overwrite it:
        if (accountFromZuora.DefaultPaymentMethodId == returnedPayment.Zuora__PaymentMethodId__c) {
            ZuoraAPI.ZuoraAccount account = new ZuoraAPI.ZuoraAccount();
            account.Id = zuoraAcctId;
            account.AutoPay = false;
            account.DefaultPaymentMethodId = ZuoraPaymentMethodSelector.getDefaultPaymentMethodId();

            ZuoraAPI.ActionItems items = new ZuoraAPI.ActionItems();
            items.type = 'Account';
            items.objects = new List<ZuoraAPI.ZuoraAccount>{
                account
            };
            ZuoraAPIHelper.actionUpdate(items);
            paymentMethodUpdateNeeded = true;
        }
        return paymentMethodUpdateNeeded;
    }

    /**
     * @description Creates a case for Customer Care related to a returned payment
     * @param zuoraPayment The payment related to the case
     * @return A case ready to be inserted
     */
    public Case insertCaseForReturns(Zuora__Payment__c zuoraPayment) {
        Zuora__PaymentMethod__c paymentMethod =
            paymentMethodSelector.getSFRecordFromZuoraId(zuoraPayment.Zuora__PaymentMethodId__c);
        CaseFactory caseFactory = new CaseFactory();
        Case newCase = caseFactory.getCase('Customer_Care');
        newCase.Subject = 'Customer Transaction Marked as Returned';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Issue';
        newCase.Description = 'This transaction was marked as returned. There may be followup required with the customer to resolve issues with their payment method.';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        newCase.AccountId = zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__c;
        newCase.ContactId = zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__c;
        newCase.Zuora_Payment_Method__c = paymentMethod?.Id;

        insert newCase;
        try {
            sendCustomerEmailForReturnedPaymentCase(zuoraPayment, newCase);
        } catch (Exception e) {
            Logger.logLater('ZuoraReturnedPaymentService', 'insertCaseForReturns', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
        return newCase;
    }

    private void sendCustomerEmailForReturnedPaymentCase(Zuora__Payment__c zuoraPayment, Case newCase) {
        String templateKey = 'Returned_Payment_Notification_' + zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Client_Brand_Key__c;
        EmailTemplate template = (EmailTemplate) emailTemplatesForReturnedPayments.get(templateKey);
        if (template == null) {
            Logger.logLater('ZuoraReturnedPaymentService', 'sendCustomerEmailForReturnedPaymentCase', 'Could not find template for payment:\n' + JSON.serialize(zuoraPayment), Logger.ERROR);
            return;
        }
        if (zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__c == null ||
            zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email == null) {
            Logger.logLater('ZuoraReturnedPaymentService', 'sendCustomerEmailForReturnedPaymentCase', 'Could not send a Returned Payment email for:\n' + JSON.serialize(zuoraPayment), Logger.ERROR);
            return;
        }
        Datetime paymentDate = zuoraPayment.Zuora__SubmittedOn__c == null ? zuoraPayment.Zuora__EffectiveDate__c : zuoraPayment.Zuora__SubmittedOn__c;
        String htmlBody = template.HtmlValue
            .replace('{{{Recipient.Name}}}', zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Name)
            .replace('{{{Payment_Date}}}', paymentDate.format('MM/dd/yyyy'));
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlBody);
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setToAddresses(new List<String>{
            zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email
        });
        mail.setSubject('Community Solar Payment Returned');
        mail.setTargetObjectId(zuoraPayment.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__c);
        mail.setWhatId(newCase.Id);
        mail.setSaveAsActivity(true);
        List<Messaging.SendEmailResult> results = MessagingService.sendEmail(new List<Messaging.Email>{
            mail
        });
        MessagingService.logErrors(results, newCase.Id);
    }

    private PaymentReturnResult executeMarkPaymentAsReturned(ZuoraAPI.Payment zuoraPayment, Zuora__Payment__c sfPayment) {
        PaymentReturnResult paymentReturnResult = new PaymentReturnResult();
        try {
            if (accountingPeriodService.isInOpenPeriod(zuoraPayment.effectiveDate)) {
                cancelOrReversePayment(sfPayment, paymentReturnResult, zuoraPayment);
            } else {
                createDebitMemosForPayment(zuoraPayment, sfPayment, paymentReturnResult);
                paymentReturnResult.message = paymentReturnResult.debitMemos.size() + ' debit memos created and posted successfully';
            }
            paymentReturnResult.success = true;
            removePaymentMethodFromAccount(sfPayment);
        } catch (Exception e) {
            String message = 'Failed reversing payment ' + sfPayment.Id + ':\n' + e.getMessage() + '\n' + e.getStackTraceString();
            Logger.logLater(
                'ZuoraController',
                'reverseReturnedPayment',
                message,
                Logger.ERROR
            );
            paymentReturnResult.message = message;
            paymentReturnResult.success = false;
        }
        return paymentReturnResult;
    }

    /**
     * @description Tries to cancel a payment, and if it doesn't cancel, creates debit memos for it
     * @param sfPayment Payment to cancel
     * @param paymentReturnResult The result, that will be populated with a result message
     * @param zuoraPayment The Zuora payment, used to create debit memos if necessary
     */
    private void cancelOrReversePayment(Zuora__Payment__c sfPayment, PaymentReturnResult paymentReturnResult, ZuoraAPI.Payment zuoraPayment) {
        try {
            cancelPayment(sfPayment);
            paymentReturnResult.message = 'Payment successfully cancelled';
        } catch (Util.BWException bwe) {
            Logger.logLater('ZuoraReturnedPaymentService', 'executeMarkPaymentAsReturned', 'did not cancel, creating debit memos', Logger.INFO);
            createDebitMemosForPayment(zuoraPayment, sfPayment, paymentReturnResult);
            paymentReturnResult.message = paymentReturnResult.debitMemos.size() + ' debit memos created and posted successfully';
        }
    }

    private void createDebitMemosForPayment(ZuoraAPI.Payment zuoraPayment, Zuora__Payment__c sfPayment, PaymentReturnResult paymentReturnResult) {
        List<ZuoraAPI.DebitMemo> debitMemos = debitMemoGenerator.convertPaymentToDebitMemos(zuoraPayment);
        if (ZuoraAPIHelper.getCalloutsRemaining() < 2 * debitMemos.size() + 1) {
            throw new Util.FatalBWException('Not enough callouts remaining to create and post debit memos and mark ' +
                'the payment as returned: ' + JSON.serialize(debitMemos));
        }
        ZuoraCreditDebitMemoService.createAndPostDebitMemos(debitMemos);
        markPaymentReturned(sfPayment.Zuora__EXT_ID__c);
        paymentReturnResult.debitMemos = debitMemos;
    }

    /**
     * @description Tries to cancel a payment. Per:
     * https://knowledgecenter.zuora.com/Billing/Billing_and_Payments/Invoice_Settlement/A_Unapplied_Payments/Management_of_Unapplied_Payments/Z_Cancel_Payments
     * Once a payment has been settled, it can no longer be cancelled. Payments are typically settled within 24 to 48 hours.
     * Zuora does not error out if a payment cannot be cancelled, but the response has a status of Processed instead of Cancelled.
     * @param sfPayment A Zuora Payment to cancel
     */
    private void cancelPayment(Zuora__Payment__c sfPayment) {
        markPaymentReturned(sfPayment.Zuora__EXT_ID__c);
        HttpResponse response =
            ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/payments/' + sfPayment.Zuora__EXT_ID__c + '/cancel', null, false);
        System.debug(LoggingLevel.ERROR, response.getBody());
        CancelPaymentResult cancelResponse =
            (CancelPaymentResult) JSON.deserialize(response.getBody(), (CancelPaymentResult.class));
        if (!cancelResponse.success || cancelResponse.status == 'Processed') {
            throw new Util.BWException('Did not cancel payment ' + sfPayment.Zuora__EXT_ID__c + '\n' + response.getBody());
        }
    }

    public class CancelPaymentResult {
        public String status; // Cancelled, Processed
        public String type; // Electronic, External
        public Boolean success;
        public List<ZuoraAPI.GenericResponseReason> reasons;
    }

    public class PaymentReturnResult {
        @AuraEnabled
        public List<ZuoraAPI.DebitMemo> debitMemos;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String message;
    }
}