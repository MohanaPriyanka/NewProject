/**
 * @description Handles account-related cancellation activity. See the Cancellation Process lucid chart for more detail:
 * https://lucid.app/lucidchart/28ddde15-529b-4b09-b858-35bba5e77e37/edit?shared=true&invitationId=inv_805406f1-b7d7-46cc-af1a-45901bb1d4e2&page=0_0#
 * Tested By: CSCancellationServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSCancellationAccountService {
    @TestVisible private List<Account> overdueAccounts = new List<Account>();
    @TestVisible private static final Id CANCELLED_BY_ID = [SELECT Id FROM User WHERE LastName = 'API' LIMIT 1].Id;
    public static final String AUTOMATED_CANCELLATION_COMMENT = 'Automated Cancellation';
    @TestVisible private static final String CANCELLATION_PARAGRAPH_TWO_LABEL = '{!Cancellation_Paragraph_Two__c}';
    @TestVisible private static final String DEFAULT_CANCELLATION_PARAGRAPH_TWO = '<br>Per our records, you have multiple subscriptions ' +
        'and the terms of service may vary for each. Your utility may process the cancellations at different times over ' +
        'many months. During this time, you are responsible for all solar credits transferred to your account. We will ' +
        'email you when the utility removes all your subscriptions and you stop receiving credits.</br>';
    @TestVisible private static final String CANCELLATION_PARAGRAPH_THREE_LABEL = '{!Cancellation_Paragraph_Three__c}';
    @TestVisible private static final String DEFAULT_CANCELLATION_PARAGRAPH_THREE = '<br><i>Please refer to your contract(s) for more ' +
        'details about the terms of service for each of your subscriptions including any applicable early termination fees.</i></br>';

    public String handleOverdueAccounts(Boolean preview) {
        String outputMessage = CSCancellationScheduler.ACCOUNT_OVERDUE_DESCRIPTION;
        overdueAccounts = AccountsSelector.selectCS67DaysPastDueWithAnchorOpps();
        if (!preview) {
            outputMessage = outputMessage.replace('will get', 'got');
            handleOverdueAccounts(overdueAccounts);
        }
        for (Account account : overdueAccounts) {
            outputMessage += account.Id + ', ' + account.Name + ' ' + account.Days_Past_Due__c + '\n';
        }
        return outputMessage;
    }

    // W-008422: Finds accounts that are overdue, and sets the Account's cancellation reason, comments, and request date,
    // which in turn triggers the cancellation process. We skip Anchor or Public Offtake accounts as well as those that
    // have an override checkbox checked.
    @TestVisible private static void handleOverdueAccounts(List<Account> accountList) {
        List<Account> updatedAccounts = new List<Account>();

        for (Account acct : accountList) {
            if (acct.Opportunities.isEmpty()){
                acct.Cancellation_Reason__c = 'Lack of Payment';
                acct.Cancellation_Request_Date__c = System.today();
                acct.Cancelled_By__c = CANCELLED_BY_ID;
                acct.Cancellation_Comments__c = AUTOMATED_CANCELLATION_COMMENT;
                updatedAccounts.add(acct);
            }
        }

        update updatedAccounts;
    }

    // W-008413: Called by the AccountTrigger after Property Accounts are updated with a Cancellation Request Date, to
    // remove all UASes from the next schedule Z, and send the customer(s) an email confirming their cancellation request.
    public void processSubscriptionCancellations(List<Utility_Account_Subscription__c> uasesToMarkInactive) {
        UtilityAccountSubscriptions subscriptions = new UtilityAccountSubscriptions(uasesToMarkInactive);
        subscriptions.removeFromNextScheduleZ();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Subscription_Order__c.SObjectType
            }
        );
        subscriptions.registerSubscriptionOrdersToZeroOutUAS('Cancellation', uow);
        uow.commitWork();
        sendCancellationConfirmationEmails(uasesToMarkInactive);
    }

    private static void sendCancellationConfirmationEmails(List<Utility_Account_Subscription__c> uasesCancelled) {
        List<Messaging.SingleEmailMessage> cancellationEmails = new List<Messaging.SingleEmailMessage>();
        Map<Account, Map<String, String>> accountToCancellationParagraphs = accountToCancellationParagraphs(uasesCancelled);

        for (Account account : accountToCancellationParagraphs.keySet()) {
            try {
                cancellationEmails.add(
                    CSCancellationService.createCSCancellationEmail(
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
        CSCancellationService.sendCancellationEmails(cancellationEmails);
        Logger.flushLogs();
    }

    @TestVisible
    private static Map<Account, Map<String, String>> accountToCancellationParagraphs(List<Utility_Account_Subscription__c> uasesCancelled) {
        Map<Account, Map<String, String>> accountIdToReplacementMap = new Map<Account, Map<String, String>>();
        for (Utility_Account_Subscription__c uas : uasesCancelled) {
            // We don't send cancellation confirmation for automatically cancelled accounts, so we skip them
            if (uas.Utility_Account_Log__r.Account__r.Cancellation_Comments__c == CSCancellationAccountService.AUTOMATED_CANCELLATION_COMMENT) {
                continue;
            }
            if (uas.Opportunity__r.Product__r.Cancellation_Paragraph_Two__c == null) {
                String text = 'While trying to cancel this account, we found product: ' + uas.Opportunity__r.Product__c +
                    ' to have a missing Cancellation Paragraph Two. Please ask an administrator to update it.';
                throw new Util.BWException(text);
            }

            Account account = uas.Utility_Account_Log__r.Account__r;
            addAccountToReplacementMap(accountIdToReplacementMap, account);
            resolveConflictingCancellationMessages(accountIdToReplacementMap, account, uas);
        }

        return accountIdToReplacementMap;
    }


    private static void addAccountToReplacementMap(Map<Account, Map<String, String>> accountIdToReplacementMap, Account account) {
        if (accountIdToReplacementMap.containsKey(account)) {
            return;
        }
        Map<String, String> replacements = new Map<String, String>{
            CANCELLATION_PARAGRAPH_TWO_LABEL => '',
            CANCELLATION_PARAGRAPH_THREE_LABEL => '',
            '{!Contact.FirstName}' => account.Send_Bills_Contact__r.FirstName
        };
        if (account.Client_Brand_Key__c.contains('Amp')) {
            replacements.put('{!$Label.Company_Name} Community Solar', 'Amp-{!$Label.Company_Name}');
        }
        accountIdToReplacementMap.put(account,replacements);
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
}