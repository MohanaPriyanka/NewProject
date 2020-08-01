/**
 * Created by peteryao on 7/28/20.
 * Tested By: CapacitySnapshotServiceTest
 */

public without sharing class CapacitySnapshotService {
    private static SharedSolarSystemsSelector systemSelector = new SharedSolarSystemsSelector();
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
        Capacity_Snapshot__c.SObjectType
    });

    public void createSnapshots() {
        uow.registerWork(new Logger());
        uow.registerNew(getSnapshots(systemSelector.getActiveSystemsWithSmallOfftakeUASes()));
        Logger.logLater('CapacitySnapshotService', 'createSnapshots', Util.getLimits(), Logger.INFO);
        uow.commitWork();
    }

    private List<Capacity_Snapshot__c> getSnapshots(List<Shared_Solar_System__c> sharedSolarSystems) {
        List<Capacity_Snapshot__c> snapshots = new List<Capacity_Snapshot__c>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            snapshots.add(getSnapshot(sss));
        }
        return snapshots;
    }

    @TestVisible
    private Capacity_Snapshot__c getSnapshot(Shared_Solar_System__c sss) {
        Capacity_Snapshot__c capacitySnapshot = new Capacity_Snapshot__c(
            Shared_Solar_System__c = sss.Id,
            As_Of_Date__c = System.today(),
            X45_60_Day_Past_Due_Active_kW__c = 0,
            X60_Day_Past_Due_Active_kW__c = 0,
            Available_Capacity__c = 0,
            QC_Capacity__c = 0,
            Waitlist_Capacity__c = 0
        );
        Decimal futureShareOfSystemTotal = 0;
        Decimal futureCustomerSubscriptionTotal = 0;

        for (Utility_Account_Subscription__c uas : sss.Utility_Account_Subscriptions__r) {
            if (uas.Opportunity__r.StageName == 'QC In Process' ||
                uas.Opportunity__r.StageName == 'Pending Quality Control Signature' ||
                uas.Opportunity__r.StageName == 'Pending BlueWave Signature') {
                capacitySnapshot.QC_Capacity__c += uas.Future_Customer_Subscription_KWDC_Rollup__c;
            } else if (uas.Shared_Solar_System__r.Waitlist__c) {
                capacitySnapshot.Waitlist_Capacity__c += uas.Future_Customer_Subscription_KWDC_Rollup__c;
                continue;
            } else {
                // The customer is taking up space on the project, so we use it for inputs to calculate available capacity
                futureShareOfSystemTotal += uas.Future_Share_of_System_Rollup__c;
                futureCustomerSubscriptionTotal += uas.Future_Customer_Subscription_KWDC_Rollup__c;

                if (uas.Opportunity__r.Account.Days_Past_Due__c >= 45 && uas.Opportunity__r.Account.Days_Past_Due__c < 60) {
                    capacitySnapshot.X45_60_Day_Past_Due_Active_kW__c += uas.Future_Customer_Subscription_KWDC_Rollup__c;
                } else if (uas.Opportunity__r.Account.Days_Past_Due__c >= 60) {
                    capacitySnapshot.X60_Day_Past_Due_Active_kW__c += uas.Future_Customer_Subscription_KWDC_Rollup__c;
                }
            }
        }
        if (futureShareOfSystemTotal > 0) {
            capacitySnapshot.Available_Capacity__c =
                futureCustomerSubscriptionTotal/(futureShareOfSystemTotal/100) - futureCustomerSubscriptionTotal;
        }
        return capacitySnapshot;
    }
}