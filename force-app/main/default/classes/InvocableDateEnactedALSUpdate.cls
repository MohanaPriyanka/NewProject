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

    /**
     * @description Invocable Method called from "Update ALS Date Enacted" that receives the current and
     * previous ALS.
     * @param params 2 paramaters passed from Flow: 1. Id for Replaced Allocation Schedule 2. New "Date Enacted by Utility"
     * that will be used to update all "Date Removed from Projects" for related records
     */
    @InvocableMethod(Label='Update Replaced ALS')
    public static void updateDateRemovedFromProject(List<List<String>> params) {
        Id replacedScheduleZId;
        Date newRetiredDate;
        for (String param : params[0]) {
            if (param.length() == 18) {
                replacedScheduleZId = param;
            } else {
                newRetiredDate = Date.parse(param);
            }
        }
        Schedule_Z__c replacedScheduleZ = new AllocationScheduleSelector().selectOne(replacedScheduleZId);
        if (replacedScheduleZ == null) {
            return;
        }
        InvocableDateEnactedALSUpdate invocableService = new InvocableDateEnactedALSUpdate();
        invocableService.handleDateRemovedFromProject(replacedScheduleZ, newRetiredDate);
    }

    /**
     * @description We need to be able to update the Date Enacted by Utility on an ALS and have the following updates occur:
     *      - Previous ALS needs to have its "Date Allocation Schedule Retired by Utility" updated to reflect the new ALS.Date_Enacted_By_Utility__c
     *      - The Date Removed From Project on all UASes that were retired with the new ALS (ie had ALSS for the old ALS but not the new)
     *          - Do not want to change the Date Removed From Project on the UASes that were finalled (they get their Date Removed From Project from their finalled UAL, not the ALS)
     *      - Reevaluate Opportunities to make sure they have the MAX(Date Removed From Project) from their UASes
     *      - Reevaluate Property Accounts to make sure they have the MAX(Date Removed From Project) from their Opps
     * @param replacedScheduleZ  Replaced Allocation Schedule
     * @param newRetiredDate  New "Date Enacted by Utility" that will be used to update all "Date Removed from Projects" for related records Allocation Schedules to update and find related records
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleDateRemovedFromProject(Schedule_Z__c replacedScheduleZ, Date newRetiredDate) {
        Date oldRetiredDate = replacedScheduleZ.Date_Schedule_Z_Retired_by_Utility__c;
        Schedule_Z__c replacedALS = new Schedule_Z__c(
            Id = replacedScheduleZ.Id,
            Date_Schedule_Z_Retired_by_Utility__c = newRetiredDate
        );

        Savepoint sp = Database.setSavepoint();
        try {
            update findRetiredUASes(replacedScheduleZ.Id, oldRetiredDate, newRetiredDate);
            update findRetiredOpportunities();
            update findRetiredAccounts();
            update replacedALS;
        } catch (Exception e ) {
            Database.rollback(sp);
            Logger.logLater('InvocableDateEnactedALSUpdate', 'updateDateRemovedFromProject', 'Failed to update related UASes, Opps, and Accounts for Replaced ALS: ' + replacedScheduleZ.Id + '; ' +
             + e.getMessage() + '; ' + e.getStackTraceString());
        }
        Logger.flushLogs();
    }

    @TestVisible
    private List<Utility_Account_Subscription__c> findRetiredUASes(Id replacedScheduleZId, Date oldRetiredDate, Date newRetiredDate) {
        List<Utility_Account_Subscription__c> uasesToUpdate = new List<Utility_Account_Subscription__c>();
        for (Schedule_Z_Subscription__c szs : szsSelector.getRetiredALSSFromALS(replacedScheduleZId)) {
            // Only want to update the UASes that were removed from ALS - not UASes that were finalled and therefore
            // got their "Date Removed From Project" from their UAL
            if (szs.Utility_Account_Subscription__r.Date_Removed_from_Project__c == oldRetiredDate) {
                szs.Utility_Account_Subscription__r.Date_Removed_from_Project__c = newRetiredDate;
                uasesToUpdate.add(szs.Utility_Account_Subscription__r);
                oppIds.add(szs.Utility_Account_Subscription__r.Opportunity__c);
            }
        }
        return uasesToUpdate;
    }

    @TestVisible
    private List<Opportunity> findRetiredOpportunities() {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppSelector.selectRetiredOpportunities(oppIds)) {
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
        List<Account> acctsToUpdate = new List<Account>();
        for (Account acct : acctSelector.getRetiredAccounts(accountIds)) {
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