/**
 * Created by PeterYao on 3/2/2021.
 * Tested By: SharedSolarSystemSharingServiceTest
 */

public with sharing class SharedSolarSystemSharingScheduler implements Schedulable {
    private static PartnerSSSEligibilitySelector eligibilitySelector = new PartnerSSSEligibilitySelector();
    private static SharedSolarSystemSharingService sssSharingService = new SharedSolarSystemSharingService();
    public void execute(SchedulableContext context) {
        try {
            changeSharesForRecentEligibilityRecords(Date.today(), Date.today() - 1);
        } catch (Exception e) {
            Logger.logNow('SharedSolarSystemSharingScheduler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    @TestVisible
    private void changeSharesForRecentEligibilityRecords(Date startDate, Date endDate) {
        if (startDate == endDate) {
            throw new Util.BWException('Don\'t use this to change shares that start and end on the same date');
        }
        List<Partner_Shared_Solar_System_Eligibility__c> recentEligibilities =
            eligibilitySelector.getRecentPartnerSSSEligibilities(startDate, endDate);
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilitiesToShare = new List<Partner_Shared_Solar_System_Eligibility__c>();
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilitiesToUnshare = new List<Partner_Shared_Solar_System_Eligibility__c>();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : recentEligibilities) {
            if (eligibility.Start_Date__c == startDate) {
                eligibilitiesToShare.add(eligibility);
            } else {
                eligibilitiesToUnshare.add(eligibility);
            }
        }
        if (!eligibilitiesToShare.isEmpty() || !eligibilitiesToUnshare.isEmpty()) {
            Logger.logNow(
                'SharedSolarSystemSharingScheduler',
                'changeSharesForRecentEligibilityRecords',
                'Sharing these eligibilities: ' + JSON.serialize(eligibilitiesToShare) + '\n' +
                'Unsharing these eligibilities: ' + JSON.serialize(eligibilitiesToUnshare),
                Logger.INFO
            );
        }
        sssSharingService.unshareSharedSolarSystems(eligibilitiesToUnshare);
        sssSharingService.shareSharedSolarSystems(eligibilitiesToShare);
    }
}