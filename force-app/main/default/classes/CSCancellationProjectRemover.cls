/**
 * @description: Handles accounts that have been removed from all projects by updating them and emailing customers they
 * have been fully removed
 * Tested By: CSCancellationServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class CSCancellationProjectRemover implements Database.Batchable<Account>, Database.Stateful {
    private static final String ACCOUNT_REMOVAL_DESCRIPTION =
        'These accounts, if any, will get marked with a Date Removed From Last Project because all of' +
            ' their opportunities have a Date Removed From Project, and subsequently be emailed that they are off all' +
            ' projects.' +
            '\n-------------';
    @TestVisible private List<Account> accountsProcessed = new List<Account>();
    private Boolean preview;
    private Autopay_Schedule__c cancellationSchedule;

    public CSCancellationProjectRemover(Boolean preview, Autopay_Schedule__c cancellationSchedule) {
        this.preview = preview;
        this.cancellationSchedule = cancellationSchedule;
    }

    public List<Account> start(Database.BatchableContext context) {
        List<Account> accountsRemovedFromAllProjects = CSCancellationProjectRemover.getAccountsRemovedFromAllProjectsWithUpdatedDate();
        Logger.logNow(
            'CSCancellationProjectRemover',
            'start',
            'Logging in case this transaction is close to limits',
            Logger.FINE
        );
        return accountsRemovedFromAllProjects;
    }

    public void execute(Database.BatchableContext context, List<Account> scopedAccountsRemovedFromAllProjects) {
        if (!preview) {
            try {
                CSCancellationProjectRemover.processAccountsRemovedFromAllProjects(scopedAccountsRemovedFromAllProjects);
            } catch (Exception e) {
                Logger.logNow('CSCancellationProjectRemover', 'execute', e.getMessage() + '\n\n' + e.getStackTraceString(), Logger.ERROR);
            }
        }
        accountsProcessed.addAll(scopedAccountsRemovedFromAllProjects);
        Logger.logNow(
            'CSCancellationProjectRemover',
            'execute',
            'Logging in case this transaction is close to limits',
            Logger.FINE
        );
    }

    public void finish(Database.BatchableContext context) {
        String outputMessage = '\n\n' + ACCOUNT_REMOVAL_DESCRIPTION;
        if (!preview) {
            outputMessage = outputMessage.replace('will get', 'got');
        }
        for (Account account : accountsProcessed) {
            outputMessage += '\n' + account.Id + ', ' + account.Name + ' ' + account.Days_Past_Due__c;
        }
        cancellationSchedule.Summary__c += outputMessage;
        cancellationSchedule.Time_Finished__c = System.now();
        update cancellationSchedule;
        if (cancellationSchedule.Send_Results_To__r.Email != null) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setPlainTextBody(cancellationSchedule.Summary__c);
            mail.setToAddresses(new List<String>{cancellationSchedule.Send_Results_To__r.Email});
            mail.setSubject('CS Cancellation'+(preview?' Preview':'')+' Results');
            MessagingService.sendEmail(new List<Messaging.Email>{mail});
        }
    }

    /**
     * @description Gets Accounts that have been removed from all projects, but not updated with a Date Removed From Project
     * @return List of Account, with Date Removed From Project set
     */
    @TestVisible
    private static List<Account> getAccountsRemovedFromAllProjectsWithUpdatedDate() {
        List<Account> csAccounts = AccountsSelector.selectCSNotRemoved();
        return getAccountsWithDateRemovedSet(csAccounts);
    }

    @TestVisible
    private static List<Account> getAccountsWithDateRemovedSet(List<Account> csAccounts) {
        List<Account> accountsToCancel = new List<Account>();
        for (Account account : csAccounts) {
            Date latestDateRemoved = null;
            if (account.Number_of_Active_Opportunities__c == 0) {
                for (Opportunity opp : account.Opportunities) {
                    latestDateRemoved = DateUtil.max(latestDateRemoved, opp.Date_Removed_from_Project__c);
                }
                if (latestDateRemoved != null) {
                    // latestDateRemoved can be null if there aren't any active opps (e.g. DUPLICATE) and none of them have
                    // been removed. In this case, we don't want to cancel the account - it was never on a project.
                    account.Date_Removed_from_Project__c = latestDateRemoved;
                    accountsToCancel.add(account);
                }
            }
        }
        return accountsToCancel;
    }

    /**
     * @description Updates Opportunities with a Date Removed from Project when UASes are updated
     * @param oldMap Trigger.oldMap
     * @param newMap Trigger.newMap
     */
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
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Opportunity.SObjectType}
        );
        for (Opportunity opp : oppsWithRemovedUASes) {
            registerDateRemovedFromProjectOnOpp(opp, uow);
        }
        uow.commitWork();
    }

    private static void registerDateRemovedFromProjectOnOpp(Opportunity opp, fflib_SObjectUnitOfWork uow) {
        Date dateRemovedFromLastProject = null;
        if (!Opportunities.anyEnactedUASes(opp) ||
            Opportunities.hasActiveUASes(opp) ||
            !Opportunities.allEnactedUASesAreRemoved(opp) ||
            Opportunities.anyUASIsTransferring(opp)) {
            return;
        }
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            dateRemovedFromLastProject = DateUtil.max(dateRemovedFromLastProject, uas.Date_Removed_from_Project__c);
        }
        if (opp.Date_Removed_from_Project__c != dateRemovedFromLastProject) {
            opp.Date_Removed_from_Project__c = dateRemovedFromLastProject;
            uow.registerDirty(opp);
        }
    }

    /**
     * @description Updates a list of accounts that are removed from all projects (per getAccountsRemovedFromAllProjectsWithUpdatedDate),
     * and sends email to customers that they have been removed from all projects.
     * @param acctsReadyForCancellation List of Accounts with Date Removed from Project set, but not committed
     * @return List of Accounts, with Date Removed from Project set
     */
    @TestVisible
    private static List<Account> processAccountsRemovedFromAllProjects(List<Account> acctsReadyForCancellation) {
        Map<Id, Messaging.SingleEmailMessage> confirmationEmailMap = new Map<Id, Messaging.SingleEmailMessage>();
        Set<Id> accountIds = CollectionUtil.getIdSet(acctsReadyForCancellation);
        Map<Id, Account> accountIdToAccountWithUALs = new Map<Id, Account>(AccountsSelector.selectAccountsWithUALs(accountIds));
        for (Account acct : acctsReadyForCancellation) {
            if (!confirmationEmailMap.containsKey(acct.Id)) {
                String utilityAccountNumbers = getRemovedUtilityAccountNumbers(accountIdToAccountWithUALs.get(acct.Id).Utility_Account_Logs__r);
                Datetime dateRemovedDT = Datetime.newInstance(
                    acct.Date_Removed_from_Project__c.year(),
                    acct.Date_Removed_from_Project__c.month(),
                    acct.Date_Removed_from_Project__c.day()
                );
                String dateRemoved = dateRemovedDT.format('MM/dd/yyyy');
                try {
                    confirmationEmailMap.put(
                        acct.Id,
                        CSCancellationService.createCSCancellationEmail(
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

        update acctsReadyForCancellation;
        CSCancellationService.sendCancellationEmails(confirmationEmailMap.values());
        Logger.flushLogs();
        return acctsReadyForCancellation;
    }


    @TestVisible
    private static String getRemovedUtilityAccountNumbers(List<Utility_Account_Log__c> utilityAccountLogs) {
        Set<String> utilityAccounts = new Set<String>();
        for (Utility_Account_Log__c ual : utilityAccountLogs) {
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
}