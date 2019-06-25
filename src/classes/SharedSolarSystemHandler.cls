public without sharing class SharedSolarSystemHandler implements Schedulable {

    public void execute(SchedulableContext sch) {
        updateSSS();
    }

    public void updateSSS() {
        Map<Id, Shared_Solar_System__c> oldSSSMap = new Map<Id, Shared_Solar_System__c>();
        List<Shared_Solar_System__c> newSSSList = getSSSList();
        List<Shared_Solar_System__c> sssToUpdateList = new List<Shared_Solar_System__c>();

        for (Shared_Solar_System__c oldSSS : getSSSList()){
            oldSSSMap.put(oldSSS.Id, oldSSS);
        }
        summarizeCapacity(newSSSList);

        for (Shared_Solar_System__c newSSS : newSSSList){
            if (newSSS.Reserved_capacity_kW_DC__c != oldSSSMap.get(newSSS.Id).Reserved_capacity_kW_DC__c ||
                newSSS.Capacity_committed_kW_DC__c != oldSSSMap.get(newSSS.Id).Capacity_committed_kW_DC__c ||
                newSSS.Anchor_capacity_reserved__c != oldSSSMap.get(newSSS.Id).Anchor_capacity_reserved__c){
                    sssToUpdateList.add(newSSS);
            }
        }
        update sssToUpdateList;
    }

    public List<Shared_Solar_System__c> getSSSList() {
        return [
            SELECT Id, Anchor_Capacity_Reserved__c, Capacity_Committed_kW_DC__c,
                Reserved_Capacity_kW_DC__c, Total_CS_Capacity__c,
                Total_Capacity_Committed_Reserved__c, Maximum_Subscription_Capacity_kW_DC__c
            FROM Shared_Solar_System__c
        ];
    }

    public void summarizeCapacity(List<Shared_Solar_System__c> sssList){
        List <String> sssIdList = new List <String> ();
        List<Utility_Account_Subscription__c> reservedCapacityList = new List <Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> committedCapacityList = new List <Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> anchorCapacityList = new List <Utility_Account_Subscription__c>();
        Decimal summarizedReservedCapacity = 0;
        Decimal summarizedCommittedCapacity = 0;
        Decimal summarizedAnchorCapacity = 0;

        for (Shared_Solar_System__c sss: sssList){
                String sssId = sss.Id;
                String subID = sssId.substring(0,15);
                sssIdList.add(subID);
        }

        List <Utility_Account_Subscription__c> relatedUAS = [ SELECT Id, Opportunity_Stage__c, Customer_Group__c,
                                                                Opportunity__c, Next_Schedule_Z_Status__c, SSS_Id__c,
                                                                Customer_Subscription_KW_DC__c
                                                                FROM Utility_Account_Subscription__c
                                                                WHERE SSS_Id__c IN :sssIdList
        ];

        for (Utility_Account_Subscription__c uas: relatedUAS) {
            if ((uas.Customer_Group__c != 'Anchor' &&
                uas.Customer_Group__c != 'Public Offtake')
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription'
                && (uas.Opportunity_Stage__c == 'Pending BlueWave Signature'
                || uas.Opportunity_Stage__c == 'QC in Process'
                || uas.Opportunity_Stage__c == 'Pending Quality Control Signature')) {
                reservedCapacityList.add(uas);
            }

            if ((uas.Customer_Group__c != 'Anchor' &&
                uas.Customer_Group__c != 'Public Offtake')
                && uas.Opportunity_Stage__c == 'Complete'
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription') {
                committedCapacityList.add(uas);
            }

            if ((uas.Customer_Group__c == 'Anchor' ||
                uas.Customer_Group__c == 'Public Offtake')
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription') {
                anchorCapacityList.add(uas);
            }
        }

        for (Shared_Solar_System__c sssSummary : sssList) {
            summarizedReservedCapacity = 0;
            summarizedCommittedCapacity = 0;
            summarizedAnchorCapacity = 0;
            if (reservedCapacityList.size() > 0){
                for (Utility_Account_Subscription__c res: reservedCapacityList){
                    if (res.SSS_Id__c == sssSummary.Id
                        && res.Customer_Subscription_KW_DC__c  != null){
                            summarizedReservedCapacity = res.Customer_Subscription_KW_DC__c + summarizedReservedCapacity;
                    }
                }
            }
            if (committedCapacityList.size() > 0){
                for (Utility_Account_Subscription__c comm: committedCapacityList){
                    if (comm.SSS_Id__c == sssSummary.Id
                        && comm.Customer_Subscription_KW_DC__c != null){
                            summarizedCommittedCapacity = comm.Customer_Subscription_KW_DC__c + summarizedCommittedCapacity;
                    }
                }
            }
           if (anchorCapacityList.size() > 0) {
                for (Utility_Account_Subscription__c anchor : anchorCapacityList){
                    if (anchor.SSS_Id__c == sssSummary.Id
                        && anchor.Customer_Subscription_KW_DC__c != null){
                        summarizedAnchorCapacity = anchor.Customer_Subscription_KW_DC__c + summarizedAnchorCapacity;
                    }
                }
            }
            sssSummary.Reserved_capacity_kW_DC__c = String.valueOf(summarizedReservedCapacity);
            sssSummary.Capacity_committed_kW_DC__c = summarizedCommittedCapacity;
            sssSummary.Anchor_capacity_reserved__c = summarizedAnchorCapacity;
        }
    }
}