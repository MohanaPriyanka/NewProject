/**
 * Created by WParker on 7/31/2018, refactored for Zuora Nov, 2019.
 *
 * This class handles the creation of Cases related to failed payments from a payment run.
 * When a customer enters new payment information to resolve the issue, a trigger on Billing Account will automatically
 * close cases.
 * See Lucid Chart: https://www.lucidchart.com/documents/edit/4ad56282-3e06-42dc-9780-cbd649ba73e0/0_0
 *
 * Test Class: PaymentCaseTest
 *
 */

public without sharing class PaymentCaseCreator implements Schedulable, ZuoraDataQueryService.Processor {
    @TestVisible
    private static ZuoraAccountSelector zuoraAccountSelector = new ZuoraAccountSelector();
    @TestVisible
    private static AccountsSelector accountsSelector = new AccountsSelector();
    private static CaseFactory caseFactory = new CaseFactory();
    private Map<Id, Account> accountIdToAccountMap;
    public static final String AUTOPAY_CASE_PREFIX = 'Automatic Payment Error';

    public enum OrderCaseType {
        PAYMENT_STATUS_ERROR,
        INTERNAL_ERROR
    }

    private Map<OrderCaseType, String> caseTypeSubjectMap =
        new Map<OrderCaseType, String>{
            OrderCaseType.PAYMENT_STATUS_ERROR => 'Transaction Failed',
            OrderCaseType.INTERNAL_ERROR => 'Internal - Send to Product Team'
        };

    private static List<String> errorsWarrantingAnEmail =
        new List<String>{
            'Credit Card Declined.',
            'This transaction has been declined.',
            'Warning! Your credit card is expired',
            'The given name on the account and/or the account type does not match the actual account.',
            'The ABA code is invalid',
            'Invalid Credit Card',
            'Invalid Route.',
            'The account number is invalid',
            'The credit card has expired.',
            'The transaction has been declined because of an AVS mismatch. The address provided does not match billing address of cardholder.'
        };

    private static Map<String, String> friendlyGatewayResponseMap = new Map<String, String>{
        'Invalid Route.' =>
            'Invalid Routing Number. Please check that Bank Account Number and Routing Number are not reversed.',
        'Please enter a \'Bank Account Number\'' => 'Invalid Bank Account Number. Please double check the Bank Account Number entered.'
    };

    private static EmailTemplate autopayErrorMessageAmp {
        get {
            if (autopayErrorMessageAmp == null) {
                autopayErrorMessageAmp = [
                    SELECT Id, HtmlValue, Body, DeveloperName, Subject
                    FROM EmailTemplate
                    WHERE DeveloperName = 'CS_Autopay_Error_Message_AmpRed'
                ];
            }
            return autopayErrorMessageAmp;
        }
        set;
    }
    private static EmailTemplate autopayErrorMessageBlueWave {
        get {
            if (autopayErrorMessageBlueWave == null) {
                autopayErrorMessageBlueWave = [
                    SELECT Id, HtmlValue, Body, DeveloperName, Subject
                    FROM EmailTemplate
                    WHERE DeveloperName = 'CS_Autopay_Error_Message'
                ];
            }
            return autopayErrorMessageBlueWave;
        }
        set;
    }

    public void execute(SchedulableContext sc) {
        String queryString = ZuoraPaymentSelector.getFailedPaymentRunPaymentsFromLastDay(System.now());
        ZuoraDataQueryService.ProcessingParameter param = new ZuoraDataQueryService.ProcessingParameter();
        param.className = 'PaymentCaseCreator';
        ZuoraDataQueryService.callFromApex(queryString, param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        List<ZuoraAPI.Payment> failedAutopayPayments =
            (List<ZuoraAPI.Payment>) JSON.deserialize(response, List<ZuoraAPI.Payment>.class);

        turnOffAutopayForFailedPayments(failedAutopayPayments);
        getAccountsForCases(failedAutopayPayments);
        Map<Case, ZuoraAPI.Payment> caseToPaymentMap = createCases(failedAutopayPayments);
        sendAllRequiredEmails(caseToPaymentMap);
        Logger.flushLogs();
    }

    private void turnOffAutopayForFailedPayments(List<ZuoraAPI.Payment> payments) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        for (ZuoraAPI.Payment payment : payments) {
            ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
            actionItems.objects.add(zuoraAccount);
            zuoraAccount.Id = payment.accountId;
            zuoraAccount.AutoPay = false;
            if (actionItems.objects.size() == ZuoraAPIHelper.maxActionUpdateRecords) {
                ZuoraAPIHelper.actionUpdate(actionItems);
                actionItems.objects.clear();
            }
        }
        ZuoraAPIHelper.actionUpdate(actionItems);
    }

    @TestVisible
    private void getAccountsForCases(List<ZuoraAPI.Payment> payments) {
        Set<Id> accountIds = new Set<Id>();
        for (ZuoraAPI.Payment payment : payments) {
            accountIds.add((Id) payment.CrmId);
        }
        List<Account> failedPaymentAccounts = accountsSelector.selectAll(accountIds);
        accountIdToAccountMap = new Map<Id, Account>(failedPaymentAccounts);
    }

    @TestVisible
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Map<Case, ZuoraAPI.Payment> createCases(List<ZuoraAPI.Payment> failedAutopayPayments) {
        List<Case> casesToOpen = new List<Case>();
        Map<Case, ZuoraAPI.Payment> caseToPaymentMap = new Map<Case, ZuoraAPI.Payment>();
        Map<String, Case> accountsWithFailedPayments = new Map<String, Case>();

        for (ZuoraAPI.Payment payment : failedAutopayPayments) {
            Case caseToOpen = createCaseForPayment(payment, payment.CrmId, OrderCaseType.PAYMENT_STATUS_ERROR);
            casesToOpen.add(caseToOpen);
            accountsWithFailedPayments.put(payment.accountId, caseToOpen);
            caseToPaymentMap.put(caseToOpen, payment);
        }

        List<ZuoraAPI.ZuoraAccount> zuoraAccounts = zuoraAccountSelector.getAutopayAccountsWithBalance();
        for (ZuoraAPI.ZuoraAccount autopayAccountWithBalance : zuoraAccounts) {
            if (!accountsWithFailedPayments.containsKey(autopayAccountWithBalance.Id)) {
                Case caseToOpen = createCaseForPayment(null, autopayAccountWithBalance.CrmId, OrderCaseType.INTERNAL_ERROR);
                casesToOpen.add(caseToOpen);
                caseToPaymentMap.put(caseToOpen, null);
            }
        }
        Logger.logLater(
            'PaymentCaseCreator',
            'createCases',
            'Creating ' + casesToOpen.size() + ' cases:\n' + JSON.serialize(casesToOpen),
            Logger.DEBUG
        );
        Util.insertAndLog(casesToOpen, 'PaymentCaseCreator', 'createCases');
        return caseToPaymentMap;
    }

    @TestVisible
    private Case createCaseForPayment(ZuoraAPI.Payment payment, Id accountId, OrderCaseType type) {
        Case newCase;
        if (type == OrderCaseType.PAYMENT_STATUS_ERROR) {
            newCase = caseFactory.getCase('Customer_Care');
            newCase.ContactId = accountIdToAccountMap.get(accountId).Send_Bills_Contact__c;
        } else {
            newCase = caseFactory.getCase('Product_Support');
        }
        newCase.Description = 'The autopay payment related to this payment method failed. [Auto-generated]';
        if (payment != null) {
            newCase.Zuora_Payment_Method__r = new Zuora__PaymentMethod__c(Zuora__External_Id__c = payment.paymentMethodId);
            newCase.Description += '\n\nMessage from Gateway: \'' + payment.GatewayResponse + '\'';
        } else {
            newCase.Description = 'No payment for an autopay account with balance';
        }
        newCase.Subject = AUTOPAY_CASE_PREFIX + ' [' + caseTypeSubjectMap.get(type) + ']';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Payment';
        newCase.Sale_Status__c = 'Post-sale';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'Perch';
        newCase.Disable_Followup_Email__c = true;
        newCase.AccountId = accountId;

        return newCase;
    }

    @TestVisible
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void sendAllRequiredEmails(Map<Case, ZuoraAPI.Payment> caseToPaymentMap) {
        List<Messaging.Email> emailsToSend = new List<Messaging.Email>();

        for (Case aCase : caseToPaymentMap.keySet()) {
            List<String> emailList = new List<String>();
            ZuoraAPI.Payment payment = caseToPaymentMap.get(aCase);
            Account account = accountIdToAccountMap.get(payment?.CrmId);
            String toEmail = account?.Send_Bills_Contact__r.Email;
            String name = account?.Send_Bills_Contact__r.FirstName;
            String errorMessage = payment?.GatewayResponse;
            if (!errorsWarrantingAnEmail.contains(payment?.GatewayResponse)) {
                continue;
            }
            if (toEmail == null ||
                name == null ||
                account.Zuora__Invoices__r.isEmpty() ||
                account.Zuora__Invoices__r[0].Zuora__DueDate__c == null) {
                emailsToSend.add(sendInternalErrorEmail('Not sending autopay failure email for Payment: ' + payment?.id +
                    ' because there is no payment, email, name, or invoices for the related contact or account\n' + JSON.serialize(account)));
                continue;
            }
            emailList.add(toEmail);
            MessagingService.safeAddCC(account.Additional_Contact__r.Email, emailList);
            Date dueDate = account.Zuora__Invoices__r[0].Zuora__DueDate__c;
            String billDueDateString =
                Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day()).format('MMMMM dd, yyyy');
            emailsToSend.add(sendTransactionErrorEmail(name, billDueDateString, errorMessage, emailList,
                getBrandedTemplateToUse(account), account.Send_Bills_Contact__c, aCase));
        }
        sendEmails(emailsToSend);
    }

    private EmailTemplate getBrandedTemplateToUse(Account account) {
        EmailTemplate templateToUse = autopayErrorMessageBlueWave;
        if (account.Client_Brand_Key__c != null && account.Client_Brand_Key__c.contains('Amp')) {
            templateToUse = autopayErrorMessageAmp;
        }
        return templateToUse;
    }

    private void sendEmails(List<Messaging.Email> emailsToSend) {
        if (!Util.getSystemPropertyCheckbox('Send_Payment_Case_Emails__c')) {
            Logger.logLater('PaymentCaseCreator', 'sendAllRequiredEmails', 'Emails disabled:\n' + JSON.serialize(emailsToSend), Logger.ERROR);
            return;
        }
        List<Messaging.SendEmailResult> results = MessagingService.sendEmail(emailsToSend);
        MessagingService.logErrors(results, 'Autopay sendEmails');
    }
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private Messaging.Email sendTransactionErrorEmail(String name, String billDueDate, String errorMessage, List<String> recipientEmailAddresses, EmailTemplate template, Id contactId, Case caseToAttach) {
        String html = template.HtmlValue;

        if (friendlyGatewayResponseMap.containsKey(errorMessage)) {
            errorMessage = friendlyGatewayResponseMap.get(errorMessage);
        }
        errorMessage = '\'' + errorMessage + '\'';

        html = html.replace('&lt;First Name&gt;', name);
        html = html.replace('&lt;Error Message&gt;', errorMessage);
        html = html.replace('&lt;current bill due date&gt;', billDueDate);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject(template.Subject);
        mail.setHtmlBody(html);
        mail.setToAddresses(recipientEmailAddresses);
        mail.setSaveAsActivity(true);
        mail.setTargetObjectId(contactId);
        mail.setWhatId(caseToAttach.Id);

        return mail;
    }

    private Messaging.Email sendInternalErrorEmail(String errorMessage) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject('Autopay Email Failed');
        mail.setHtmlBody(errorMessage);
        mail.setPlainTextBody(errorMessage);
        mail.setToAddresses(new List<String>{
            'cssupport@perchenergy.com'
        });
        return mail;
    }

    public void closeAutopayCasesOnPaymentMethodUpdate(Map<Id, Zuora__CustomerAccount__c> oldCustomerAccounts, Map<Id, Zuora__CustomerAccount__c> newCustomerAccounts) {
        Set<Id> propertyAccountIds = findDefaultPaymentMethodUpdates(oldCustomerAccounts, newCustomerAccounts);
        if (!propertyAccountIds.isEmpty()) {
            closeAutopayCasesFuture(propertyAccountIds);
        }
    }

    private Set<Id> findDefaultPaymentMethodUpdates(Map<Id, Zuora__CustomerAccount__c> oldCustomerAccounts, Map<Id, Zuora__CustomerAccount__c> newCustomerAccounts) {
        Set<Id> propertyAccountIds = new Set<Id>();
        for (Zuora__CustomerAccount__c oldAccount : oldCustomerAccounts.values()) {
            if (oldAccount.Zuora__Default_Payment_Method__c != newCustomerAccounts.get(oldAccount.Id).Zuora__Default_Payment_Method__c &&
                newCustomerAccounts.get(oldAccount.Id).Zuora__Default_Payment_Method__c != null) {
                propertyAccountIds.add(oldAccount.Zuora__Account__c);
            }
        }
        return propertyAccountIds;
    }

    @Future
    public static void closeAutopayCasesFuture(Set<Id> propertyAccountsWithPaymentMethodChanges) {
        List<Case> openPaymentMethodCases = new List<Case>();
        try {
            List<Account> accounts = accountsSelector.selectAll(propertyAccountsWithPaymentMethodChanges);
            for (Account account : accounts) {
                openPaymentMethodCases.addAll(account.Cases);
            }
            for (Case paymentMethodCase : openPaymentMethodCases) {
                paymentMethodCase.Status = 'Closed';
                paymentMethodCase.Resolution__c = 'Other';
            }
            Util.updateAndLog(openPaymentMethodCases, 'PaymentCaseCreator', 'closeAutopayCasesFuture');
        } catch (Exception e) {
            Logger.logNow(
                'PaymentCaseCreator',
                'findAndCloseAutopayCasesFuture',
                JSON.serialize(propertyAccountsWithPaymentMethodChanges) + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        }
    }
}