/**
* @description Created by Sarah Renfro on 12/6/2018.
*
* Description: Implements cancellation functionality as specified in the Automated Cancellation Process epic:
* https://bluewavesolar.my.salesforce.com/a2g0a000000K7sX and Lucid chart:
* https://www.lucidchart.com/documents/edit/28ddde15-529b-4b09-b858-35bba5e77e37/2
*
* Provides four ways to initiate a CS cancellation:
* 1. Via customer request (by updating Cancellation Request Date and Cancellation Reason)
* 2. Via processing a utility account that's been finaled by the utility
* 3. Via lack of payment after 67 days
* 4. Via removal of all subscriptions
*
* We maintain the CS Status (open vs closed) and Cancellation Reasons at the account level.
*
* Tested By: CSCancellationServiceTest
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSCancellationService {
    // W-008413: Called by the AccountTrigger after Property Accounts are updated with a Cancellation Request Date, to
    // remove all UASes from the next schedule Z, and send the customer(s) an email confirming their cancellation request.
    public static void processSubscriptionCancellations(List<Utility_Account_Subscription__c> uasesToMarkInactive) {
        CSCancellationAccountService.processSubscriptionCancellations(uasesToMarkInactive);
    }

    public static Messaging.SingleEmailMessage createCSCancellationEmail(Account account, String template, String subject, Map<String, String> replacements) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject(subject);
        if (account.Send_Bills_Contact__r.Email == null) {
            throw new Util.BWException('Expected a Send Bills Contact Email for account (' +
                account.Id + '), but found none');
        }
        mail.setToAddresses(new List<String>{account.Send_Bills_Contact__r.Email});
        mail.setHtmlBody(MessagingService.getHtmlWithReplacements(template, replacements));
        List<String> ccEmails = new List<String>();
        MessagingService.safeAddCC(account.Send_Bills_Contact__r.Additional_Email__c, ccEmails);
        MessagingService.safeAddCC(account.Additional_Contact__r.Email, ccEmails);
        MessagingService.safeAddCC(account.Additional_Contact__r.Additional_Email__c, ccEmails);
        mail.setCcAddresses(ccEmails);
        mail.setTargetObjectId(account.Send_Bills_Contact__c);
        mail.setSaveAsActivity(true);
        return mail;
    }

    // W-008411: Called by the UtilityAccountLog trigger when Ops receives an email from the Utility that an account has been
    // finaled. Updates the "Date Utility Account Cancelled" date on the Utility Account Log and creates a case specified
    // by System_Property__c.Finaled_Case_Owner__c
    public static void processFinaledUtilityAccounts(List<Utility_Account_Subscription__c> uasesToMarkInactive) {
        UtilityAccountSubscriptions subscriptions = new UtilityAccountSubscriptions(uasesToMarkInactive);
        subscriptions.handleFinaledAccounts();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Subscription_Order__c.SObjectType
            }
        );
        subscriptions.registerSubscriptionOrdersToZeroOutUAS('Cancellation', uow);
        uow.commitWork();
        createCaseToTransferOrTerminate(subscriptions);
    }

    public static List<Utility_Account_Subscription__c> getUASesForFinaledUALs(List<Utility_Account_Log__c> newUALList, Map<Id, Utility_Account_Log__c> oldUALMap) {
        Set<Id> recentlyCancelledUALIds = new Set<Id>();
        List<Utility_Account_Subscription__c> uasesToMarkInactive = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Log__c ual : newUALList) {
            if (ual.Date_Utility_Account_Cancelled__c != null &&
                oldUALMap.get(ual.Id).Date_Utility_Account_Cancelled__c == null) {
                recentlyCancelledUALIds.add(ual.Id);
            }
        }

        uasesToMarkInactive = UASSelector.selectByUAL(recentlyCancelledUALIds);
        return uasesToMarkInactive;
    }

    private static void createCaseToTransferOrTerminate(UtilityAccountSubscriptions subscriptionList) {
        String caseOwner = Util.getSystemPropertyString('Finaled_Case_Owner__c');
        Map<Id, Case> accountToCaseMap = new Map<Id, Case>();
        for (Utility_Account_Subscription__c uas : subscriptionList.records) {
            if (!accountToCaseMap.containsKey(uas.Utility_Account_Log__r.Account__c)) {
                Case transferCase = new CaseFactory().getCase(caseOwner);
                transferCase.Product_Line__c = 'Community Solar';
                transferCase.Origin = 'Other';
                transferCase.Category__c = 'Cancellation';
                transferCase.Disable_Followup_Email__c = true;
                transferCase.Sale_Status__c = 'Post-sale';
                transferCase.Subject = 'Determine handling of finaled UAL';
                transferCase.Description = uas.Utility_Account_Log__r.Account__r.Name + ' has recently had Utility Account ' +
                    uas.Utility_Account_Log__r.Name + ' ('+uas.Utility_Account_Log__c+') finaled and had ' +
                    'Transferring Subsc. to Another UAS automatically checked to pause the cancellation process.\n\n' +
                    'Please follow up with the customer to see if they want to transfer the subscription or pay an early termination fee.\n\n' +
                    'If they choose not to transfer, uncheck the transferring checkbox and add a cancellation reason on the account.';
                transferCase.AccountId = uas.Utility_Account_Log__r.Account__r.Parent_Account__c;
                transferCase.ContactId = uas.Utility_Account_Log__r.Account__r.Send_Bills_Contact__c;
                accountToCaseMap.put(uas.Utility_Account_Log__r.Account__c, transferCase);
            }
        }

        insert accountToCaseMap.values();
    }

    // W-008426: Called by the OpportunityTrigger to check to see if all CS opportunities are Cancelled, Expired, Duplicate,
    // or Dead. If so, we update the Account Status__c field and send the final termination letter email.
    public static List<Account> getAccountsToClose(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        return CSCancellationOppService.getAccountsToClose(newOppMap, oldOppMap);
    }

    public static void closeAccounts(List<Account> acctList) {
        Accounts csAccts = new Accounts(acctList);
        csAccts.close();
        sendTerminationConfirmationEmails(acctList);
    }

    private static void sendTerminationConfirmationEmails(List<Account> acctList) {
        Map<Id, Messaging.SingleEmailMessage> terminationEmailMap = new Map<Id, Messaging.SingleEmailMessage>();
        for (Account account : acctList) {
            // We should only send a termination email if the Account has been cancelled, not for instance, an account
            // that has a bunch of Dead opps.
            if (terminationEmailMap.containsKey(account.Id) ||
                account.Cancellation_Request_Date__c == null) {
                continue;
            }
            try {
                terminationEmailMap.put(
                    account.Id,
                    createCSCancellationEmail(
                        account,
                        'CS_Termination_Confirmation',
                        'Account Closed Confirmation',
                        new Map<String, String>{'{!Contact.FirstName}' => account.Send_Bills_Contact__r.FirstName}
                    )
                );
            } catch (Util.BWException bwe) {
                Logger.logLater('CSCancellationService', 'sendTerminationConfirmationEmails', bwe.getMessage());
            }
        }

        sendCancellationEmails(terminationEmailMap.values());
        Logger.flushLogs();
    }

    public static void sendCancellationEmails(List<Messaging.SingleEmailMessage> emails) {
        if (Util.getSystemPropertyCheckbox('Send_CS_Cancellation_Emails__c')) {
            MessagingService.sendEmail(emails);
            return;
        }
        Logger.logLater(
            'CSCancellationService',
            'sendCancellationEmail',
            'Not sending ' + emails.size() + ' emails because CS Cancellation Emails is turned off via custom setting',
            Logger.WARN
        );
    }

    /**
     * @description W-023716: When Customer Ops marks an Account as cancelled, a manager needs to approve so that the
     * cancellation process is smoother, streamlined, and able to be as accurate for reporting as possible
     * @param oldMap Trigger.oldMap
     * @param newMap Trigger.newMap
     */
    public static void initiateCancellationApprovalProcess(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Account> cancelledAccounts =
            (List<Account>) new SObjectFilter(
                oldMap,
                newMap.values(),
                Account.Cancellation_Request_Date__c,
                null,
                SObjectFilter.ANY_VALUE
            ).get(SObjectFilter.SOBJECT_LIST);
        CollectionUtil.setField(cancelledAccounts, Account.Cancellation_Reason_Approval_Status__c, 'Pending Approval');
    }
}