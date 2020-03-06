/**
* Created by Sarah Renfro on 12/6/2018.
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
    private static String AUTOMATED_CANCELLATION_COMMENT = 'Automated Cancellation';
    @TestVisible
    private static final String CANCELLATION_PARAGRAPH_TWO_LABEL = '{!Cancellation_Paragraph_Two__c}';
    @TestVisible
    private static final String DEFAULT_CANCELLATION_PARAGRAPH_TWO = '<br>Per our records, you have multiple subscriptions ' +
        'and the terms of service may vary for each. Your utility may process the cancellations at different times over ' +
        'a period of months. During this time, you are responsible for all solar credits transferred to your account. Once ' +
        'your all your subscriptions are removed and stop receiving credits you will be notified of the change via email.</br>';
    @TestVisible
    private static final String CANCELLATION_PARAGRAPH_THREE_LABEL = '{!Cancellation_Paragraph_Three__c}';
    @TestVisible
    private static final String DEFAULT_CANCELLATION_PARAGRAPH_THREE = '<br><i>Please refer to your contract(s) for more ' +
        'details about the terms of service for each of your subscriptions including any applicable early termination fees.</i></br>';

    // W-008422: Finds accounts that are overdue, and sets the Account's cancellation reason, comments, and request date,
    // which in turn triggers the cancellation process. We skip Anchor or Public Offtake accounts as well as those that
    // have an override checkbox checked.
    public static List<Account> handleOverdueAccounts() {
        List<Account> updatedAccounts = new List<Account>();
        List<Account> accountList = AccountsSelector.selectCS67DaysPastDueWithAnchorOpps();

        for (Account acct : accountList) {
            if (acct.Opportunities.isEmpty()){
                acct.Cancellation_Reason__c = 'Lack of Payment';
                acct.Cancellation_Request_Date__c = System.today();
                acct.Cancellation_Comments__c = AUTOMATED_CANCELLATION_COMMENT;
                updatedAccounts.add(acct);
            }
        }

        if (!updatedAccounts.isEmpty()) {
            update updatedAccounts;
        }
        return updatedAccounts;
    }

    // W-008413: Called by the AccountTrigger after Property Accounts are updated with a Cancellation Request Date, to
    // remove all UASes from the next schedule Z, and send the customer(s) an email confirming their cancellation request.
    public static void processSubscriptionCancellations(List<Utility_Account_Subscription__c> uasesToMarkInactive) {
        UtilityAccountSubscriptions subscriptions = new UtilityAccountSubscriptions(uasesToMarkInactive);
        subscriptions.removeFromNextScheduleZ();
        sendCancellationConfirmationEmails(uasesToMarkInactive);
    }

    private static void sendCancellationConfirmationEmails(List<Utility_Account_Subscription__c> uasesCancelled) {
        List<Messaging.SingleEmailMessage> cancellationEmails = new List<Messaging.SingleEmailMessage>();
        Map<Account, Map<String, String>> accountToCancellationParagraphs = accountToCancellationParagraphs(uasesCancelled);

        for (Account account : accountToCancellationParagraphs.keySet()) {
            try {
                cancellationEmails.add(
                    createCSEmail(
                        account,
                        'CS_Cancellation_Request_Confirmation',
                        'Cancellation Request Acknowledgement',
                        accountToCancellationParagraphs.get(account)
                    )
                );
            } catch (Util.BWException bwe) {
                Logger.logLater('CSCancellationService', 'sendCancellationConfirmationEmails', bwe.getMessage());
            }
        }
        sendCancellationEmails(cancellationEmails);
        Logger.flushLogs();
    }

    @TestVisible
    private static Map<Account, Map<String, String>> accountToCancellationParagraphs(List<Utility_Account_Subscription__c> uasesCancelled) {
        Map<Account, Map<String, String>> accountIdToReplacementMap = new Map<Account, Map<String, String>>();
        for (Utility_Account_Subscription__c uas : uasesCancelled) {
            // We don't send cancellation confirmation for automatically cancelled accounts, so we skip them
            if (uas.Utility_Account_Log__r.Account__r.Cancellation_Comments__c == AUTOMATED_CANCELLATION_COMMENT) {
                continue;
            }
            if (uas.Opportunity__r.Product__r.Cancellation_Paragraph_Two__c == null) {
                String text = 'While trying to cancel this account, we found product: ' + uas.Opportunity__r.Product__c +
                    ' to have a missing Cancellation Paragraph Two. Please ask an administrator to update it.';
                if (Trigger.new != null) {
                    ((Account) Trigger.new[0]).Cancellation_Request_Date__c.addError(text);
                    return accountIdToReplacementMap;
                } else {
                    throw new Util.BWException(text);
                }
            }

            Account account = uas.Utility_Account_Log__r.Account__r;
            addAccountToReplacementMap(accountIdToReplacementMap, account);
            resolveConflictingCancellationMessages(accountIdToReplacementMap, account, uas);
        }

        return accountIdToReplacementMap;
    }

    private static void addAccountToReplacementMap(Map<Account, Map<String, String>> accountIdToReplacementMap, Account account) {
        if (!accountIdToReplacementMap.containsKey(account)) {
            accountIdToReplacementMap.put(
                account,
                new Map<String, String>{
                    CANCELLATION_PARAGRAPH_TWO_LABEL => '',
                    CANCELLATION_PARAGRAPH_THREE_LABEL => '',
                    '{!Contact.FirstName}' => account.Send_Bills_Contact__r.FirstName
                }
            );
        }
    }

    // If two opportunities have products with conflicting cancellation information, we should show a default cancellation message
    private static void resolveConflictingCancellationMessages(Map<Account, Map<String, String>> accountIdToReplacementMap, Account account, Utility_Account_Subscription__c uas) {
        Map<String, String> replacementMap = accountIdToReplacementMap.get(account);
        if (replacementMap.get(CANCELLATION_PARAGRAPH_TWO_LABEL) == '') {
            replacementMap.put(CANCELLATION_PARAGRAPH_TWO_LABEL, uas.Opportunity__r.Product__r.Cancellation_Paragraph_Two__c);
        } else if (replacementMap.get(CANCELLATION_PARAGRAPH_TWO_LABEL) != uas.Opportunity__r.Product__r.Cancellation_Paragraph_Two__c) {
            replacementMap.put(CANCELLATION_PARAGRAPH_TWO_LABEL, DEFAULT_CANCELLATION_PARAGRAPH_TWO);
        }
        if (replacementMap.get(CANCELLATION_PARAGRAPH_THREE_LABEL) == '') {
            replacementMap.put(CANCELLATION_PARAGRAPH_THREE_LABEL, uas.Opportunity__r.Product__r.Cancellation_Paragraph_Three__c);
        } else if (replacementMap.get(CANCELLATION_PARAGRAPH_THREE_LABEL) != uas.Opportunity__r.Product__r.Cancellation_Paragraph_Three__c) {
            replacementMap.put(CANCELLATION_PARAGRAPH_THREE_LABEL, DEFAULT_CANCELLATION_PARAGRAPH_THREE);
        }
    }

    private static Messaging.SingleEmailMessage createCSEmail(Account account, String template, String subject) {
        return createCSEmail(account, template, subject, new Map<String, String>{'{!Contact.FirstName}' => account.Send_Bills_Contact__r.FirstName});
    }

    private static Messaging.SingleEmailMessage createCSEmail(Account account, String template, String subject, Map<String, String> replacements) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject(subject);
        if (account.Send_Bills_Contact__r.Email != null) {
            mail.setToAddresses(new List<String>{account.Send_Bills_Contact__r.Email});
        } else {
            throw new Util.BWException('Expected a Send Bills Contact Email for account (' +
                account.Id + '), but found none');
        }
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

        if (recentlyCancelledUALIds.isEmpty()) {
            return uasesToMarkInactive;
        }

        uasesToMarkInactive = UASSelector.selectByUAL(recentlyCancelledUALIds);
        return uasesToMarkInactive;
    }

    private static void createCaseToTransferOrTerminate(UtilityAccountSubscriptions subscriptionList) {
        String caseOwner;
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.isEmpty() || String.isBlank(systemProperties[0].Finaled_Case_Owner__c)) {
            return;
        } else {
            caseOwner = systemProperties[0].Finaled_Case_Owner__c;
        }
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

    // W-008425: Called by the CSCancellationScheduler daily to mark Opportunities as cancelled if:
    // 1. Opportunity Stage is Complete AND
    // 2. All UASes are inactive and there are no SZSes for them (waitlist cancellation) OR
    // 3. We've sent System Bills, but not for 45 days (15 days after we expect to send), so we're finished billing
    //
    // Once all opportunities under a property account are cancelled (or Duplicate, Expired, or Dead), another scheduled job
    // will send a termination letter
    public static List<Opportunity> cancelOpportunities(List<Opportunity> oppToCancelList) {
        Opportunities opportunities = new Opportunities(oppToCancelList);
        opportunities.cancel();
        return opportunities.records;
    }

    public static List<Opportunity> getOpportunitiesToCancel() {
        List<Opportunity> completeCSOpps = OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills();

        List<Opportunity> oppsToCancel = new List<Opportunity>();
        for (Opportunity opportunity : completeCSOpps) {
            if (Opportunities.allUASesTransferring(opportunity)) {
                continue;
            }
            if (Opportunities.isCancelledWaitlist(opportunity) ||
                (Opportunities.finishedBilling(opportunity) && !Opportunities.hasActiveUASes(opportunity))) {
                oppsToCancel.add(opportunity);
            }
        }

        return oppsToCancel;
    }

    // W-008424: When ALL UASes with a Schedule Z Subscription have a "Date Removed from Project" (which is set when
    // Ops marks a Utility Account Log as Finaled or a customer has cancelled), we want to update the latest
    // Date Removed from Project on the Account and confirm with the removal with the customer.
    // W-013146: Keep track of Opportunities removed from projects, since we may have Inactive UASes that are just waiting
    // to be put on a project that should prevent an account from being marked as removed.
    public static void handleOpportunitiesRemovedFromProject(Map<Id, Utility_Account_Subscription__c> oldMap, Map<Id, Utility_Account_Subscription__c> newMap) {
        Set<Id> oppIdsToCheckForRemoval = new Set<Id>();
        for (Utility_Account_Subscription__c uas : newMap.values()) {
            if (oldMap.get(uas.Id).Date_Removed_from_Project__c == null && uas.Date_Removed_from_Project__c != null ||
                oldMap.get(uas.Id).Next_Schedule_Z_Status__c != uas.Next_Schedule_Z_Status__c ||
                oldMap.get(uas.Id).Transferring_Subsc_to_Another_UAS__c != uas.Transferring_Subsc_to_Another_UAS__c) {
                oppIdsToCheckForRemoval.add(uas.Opportunity__c);
            }
        }
        List<Opportunity> oppsWithRemovedUASes = OpportunitiesSelector.selectAllCompleteCSWithUASes(oppIdsToCheckForRemoval);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppsWithRemovedUASes) {
            Date dateRemovedFromLastProject = null;
            if (!Opportunities.anyEnactedUASes(opp) ||
                Opportunities.hasActiveUASes(opp) ||
                !Opportunities.allEnactedUASesAreRemoved(opp) ||
                Opportunities.allUASesTransferring(opp)) {
                continue;
            }
            for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
                dateRemovedFromLastProject = DateUtil.max(dateRemovedFromLastProject, uas.Date_Removed_from_Project__c);
            }
            if (opp.Date_Removed_from_Project__c != dateRemovedFromLastProject) {
                opp.Date_Removed_from_Project__c = dateRemovedFromLastProject;
                oppsToUpdate.add(opp);
            }
        }
        update oppsToUpdate;
    }


    public static List<Account> processAccountsRemovedFromAllProjects(List<Account> acctsReadyForCancellation) {
        Map<Id, Messaging.SingleEmailMessage> confirmationEmailMap = new Map<Id, Messaging.SingleEmailMessage>();

        for (Account acct : acctsReadyForCancellation) {
            if (!confirmationEmailMap.containsKey(acct.Id)) {
                String utilityAccountNumbers = getRemovedUtilityAccountNumbers(acct);
                Datetime dateRemovedDT = Datetime.newInstance(
                    acct.Date_Removed_from_Project__c.year(),
                    acct.Date_Removed_from_Project__c.month(),
                    acct.Date_Removed_from_Project__c.day()
                );
                String dateRemoved = dateRemovedDT.format('MM/dd/yyyy');
                try {
                    confirmationEmailMap.put(
                        acct.Id,
                        createCSEmail(
                            acct,
                            'CS_Project_Removal_Confirmation',
                            'Subscription Removal Confirmation',
                            new Map<String, String>{
                                '{!Contact.FirstName}' => acct.Send_Bills_Contact__r.FirstName,
                                '{!Date_Removed_from_Project__c}' => dateRemoved,
                                '{!Utility_Account_Numbers}' => utilityAccountNumbers
                            }
                        )
                    );
                } catch (Util.BWException bwe) {
                    Logger.logLater('CSCancellationService', 'processAccountsRemovedFromAllProjects', bwe.getMessage());
                }
            }
        }

        if (!acctsReadyForCancellation.isEmpty()){
            update acctsReadyForCancellation;
            sendCancellationEmails(confirmationEmailMap.values());
            Logger.flushLogs();
        }
        return acctsReadyForCancellation;
    }

    @TestVisible
    private static String getRemovedUtilityAccountNumbers(Account acct) {
        Set<String> utilityAccounts = new Set<String>();
        for (Utility_Account_Log__c ual : acct.Utility_Account_Logs__r) {
            if (ual.Number_of_Removed_UASes__c > 0) {
                utilityAccounts.add(ual.Name);
            }
        }
        // foo,bar should read "foo and bar"
        // foo,bar,baz should read "foo, bar, and baz"
        String utilityAccountNumbers = String.join(new List<String>(utilityAccounts), ',');
        if (utilityAccountNumbers.countMatches(',') == 1) {
            utilityAccountNumbers = utilityAccountNumbers.replace(',', ' and ');
        } else if (utilityAccountNumbers.countMatches(',') > 1) {
            utilityAccountNumbers =
                utilityAccountNumbers.substring(0, utilityAccountNumbers.lastIndexOf(',')) + ' and ' +
                    utilityAccountNumbers.substring(utilityAccountNumbers.lastIndexOf(',')+1);
            utilityAccountNumbers = utilityAccountNumbers.replace(',', ', ');
        }
        return utilityAccountNumbers;
    }

    public static List<Account> getAccountsRemovedFromAllProjectsWithUpdatedDate() {
        List<Account> csAccounts = AccountsSelector.selectCSNotRemoved();
        return getAccountsWithDateRemovedSet(csAccounts);
    }

    @TestVisible
    private static List<Account> getAccountsWithDateRemovedSet(List<Account> csAccounts) {
        List<Account> accountsToCancel = new List<Account>();
        for (Account account : csAccounts) {
            Boolean isRemoved = true;
            Date latestDateRemoved = null;
            for (Opportunity opp : account.Opportunities) {
                if (isActive(opp)) {
                    isRemoved = false;
                    break;
                } else {
                    latestDateRemoved = DateUtil.max(latestDateRemoved, opp.Date_Removed_from_Project__c);
                }
            }
            // latestDateRemoved can be null if there aren't any active opps (e.g. DUPLICATE) and none of them have
            // been removed. In this case, we don't want to cancel the account - it was never on a project.
            if (isRemoved && latestDateRemoved != null) {
                account.Date_Removed_from_Project__c = latestDateRemoved;
                accountsToCancel.add(account);
            }
        }
        return accountsToCancel;
    }

    private static Boolean isActive(Opportunity opp) {
        return (opp.StageName != 'Cancelled' &&
            opp.StageName != 'DUPLICATE' &&
            opp.StageName != 'Expired' &&
            opp.StageName != 'Dead');
    }

    // W-008426: Called by the OpportunityTrigger to check to see if all CS opportunities are Cancelled, Expired, Duplicate,
    // or Dead. If so, we update the Account Status__c field and send the final termination letter email.
    public static List<Account> getAccountsToClose(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        //get all accounts where opportunities are either Cancelled, DUPLICATE, Expired or Dead
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToClose = new List<Account>();
        for (Opportunity opp : newOppMap.values()) {
            if (opp.Product_Line__c == 'Community Solar' &&
                (opp.StageName == 'Cancelled' && oldOppMap.get(opp.Id).StageName != 'Cancelled') ||
                (opp.StageName == 'DUPLICATE' && oldOppMap.get(opp.Id).StageName != 'DUPLICATE') ||
                (opp.StageName == 'Expired' && oldOppMap.get(opp.Id).StageName != 'Expired') ||
                (opp.StageName == 'Dead' && oldOppMap.get(opp.Id).StageName != 'Dead')) {
                accountIds.add(opp.AccountId);
            }
        }

        if (!accountIds.isEmpty()) {
            List<Account> acctsToCheck = AccountsSelector.selectNotClosed(accountIds);
            for (Account acct : acctsToCheck) {
                Boolean readyForClose = true;
                for (Opportunity opp : acct.Opportunities) {
                    if (isActive(opp)) {
                        readyForClose = false;
                        break;
                    }
                }

                if (readyForClose) {
                    accountsToClose.add(acct);
                }
            }
        }

        return accountsToClose;
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
                    createCSEmail(account,
                        'CS_Termination_Confirmation',
                        'Account Closed Confirmation')
                );
            } catch (Util.BWException bwe) {
                Logger.logLater('CSCancellationService', 'sendTerminationConfirmationEmails', bwe.getMessage());
            }
        }

        if (!terminationEmailMap.values().isEmpty()) {
            sendCancellationEmails(terminationEmailMap.values());
            Logger.flushLogs();
        }
    }

    private static void sendCancellationEmails(List<Messaging.SingleEmailMessage> emails) {
        if (Util.getSystemPropertyCheckbox('Send_CS_Cancellation_Emails__c')) {
            MessagingService.sendEmail(emails);
        } else {
            Logger.logLater(
                'CSCancellationService',
                'sendCancellationEmail',
                'Not sending ' + emails.size() + ' emails because CS Cancellation Emails is turned off via custom setting',
                Logger.WARN
            );
        }
    }
}