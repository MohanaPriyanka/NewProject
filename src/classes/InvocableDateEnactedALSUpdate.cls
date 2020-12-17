/**
 * Created by SarahRenfro on 12/15/2020.
 */

public with sharing class InvocableDateEnactedALSUpdate {
    private Set<Id> oppIds = new Set<Id>();
    private Set<Id> accountIds = new Set<Id>();
    @TestVisible
    private static ScheduleZSubscriptionSelector szsSelector = new ScheduleZSubscriptionSelector();
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static AccountsSelector acctSelector = new AccountsSelector();

    @InvocableMethod(Label='Update Replaced ALS')
    public static void updateDateRemovedFromProject(List<List<Id>> allocationScheduleIds) {
        Set<Id> alsIds = new Set<Id>(allocationScheduleIds[0]);
        List<Schedule_Z__c> scheduleZS = new AllocationScheduleSelector().selectAll(alsIds);
        if (scheduleZS.size() != 2) {
            return;
        }
        InvocableDateEnactedALSUpdate invocableService = new InvocableDateEnactedALSUpdate();
        invocableService.handleDateRemovedFromProject(scheduleZS);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleDateRemovedFromProject(List<Schedule_Z__c> scheduleZS) {
        Date oldRetiredDate;
        Date newRetiredDate;
        Id replacedScheduleZId;
        for (Schedule_Z__c als : scheduleZS) {
            if (als.Status__c == 'Replaced' || als.Status__c == 'Billing') {
                oldRetiredDate = als.Date_Schedule_Z_Retired_by_Utility__c;
                replacedScheduleZId= als.Id;
            } else if (als.Status__c == 'Enacted by Utility') {
                newRetiredDate = als.Date_Enacted_by_Utility__c;
            }
        }

        Schedule_Z__c replacedALS = new Schedule_Z__c(
            Id = replacedScheduleZId,
            Date_Schedule_Z_Retired_by_Utility__c = newRetiredDate
        );

        Savepoint sp = Database.setSavepoint();
        try {
            List<Utility_Account_Subscription__c> retiredUASes = findRetiredUASes(replacedScheduleZId, oldRetiredDate, newRetiredDate);
            update retiredUASes;
            List<Opportunity> retiredOpps = findRetiredOpportunities();
            update retiredOpps;
            List<Account> acctsToUpdate = findRetiredAccounts();
            update acctsToUpdate;
            update replacedALS;
        } catch (Exception e ) {
            Database.rollback(sp);
            Logger.logLater('InvocableDateEnactedALSUpdate', 'updateDateRemovedFromProject', 'Failed to update related UASes, Opps, and Accounts for Replaced ALS: ' + replacedScheduleZId + '; ' +
             + e.getMessage() + '; ' + e.getStackTraceString());
        }
        Logger.flushLogs();
    }

    @TestVisible
    private List<Utility_Account_Subscription__c> findRetiredUASes(Id replacedScheduleZId, Date oldRetiredDate, Date newRetiredDate) {
        List<Schedule_Z_Subscription__c> retiredSZS = szsSelector.getRetiredSZSFromALS(replacedScheduleZId);
        LIst<Utility_Account_Subscription__c> uasesToUpdate = new List<Utility_Account_Subscription__c>();
        for (Schedule_Z_Subscription__c szs : retiredSZS) {
            // Only want to update the UASes that were removed from ALS - not UASes that were finalled and therefore
            // got their "Date Removed From Project" from their UAL
            if (szs.Utility_Account_Subscription__r.Date_Removed_from_Project__c == oldRetiredDate) {
                Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                    Id = szs.Utility_Account_Subscription__c,
                    Date_Removed_from_Project__c = newRetiredDate
                );
                uasesToUpdate.add(uas);
                oppIds.add(szs.Utility_Account_Subscription__r.Opportunity__c);
            }
        }
        return uasesToUpdate;
    }

    @TestVisible
    private List<Opportunity> findRetiredOpportunities() {
        List<Opportunity> oppList = oppSelector.selectRetiredOpportunities(oppIds);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppList) {
            Date dateRemovedFromLastProject = null;
            for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
                dateRemovedFromLastProject = DateUtil.max(dateRemovedFromLastProject, uas.Date_Removed_from_Project__c);
            }
            if (opp.Date_Removed_from_Project__c != dateRemovedFromLastProject) {
                opp.Date_Removed_from_Project__c = dateRemovedFromLastProject;
                accountIds.add(opp.AccountId);
                oppsToUpdate.add(opp);
            }
        }
        return oppsToUpdate;
    }

    @TestVisible
    private List<Account> findRetiredAccounts() {
        List<Account> accountList = acctSelector.getRetiredAccounts(accountIds);
        List<Account> acctsToUpdate = new List<Account>();
        for (Account acct : accountList) {
            Date latestDateRemoved = null;
            for (Opportunity opp : acct.Opportunities) {
                latestDateRemoved = DateUtil.max(latestDateRemoved, opp.Date_Removed_from_Project__c);
            }
            if (acct.Date_Removed_from_Project__c != latestDateRemoved) {
                acct.Date_Removed_from_Project__c = latestDateRemoved;
                acctsToUpdate.add(acct);
            }
        }
        return acctsToUpdate;
    }
}