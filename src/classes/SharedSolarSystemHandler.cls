/*
   Tested by: RecurringPaymentsHandlerTestClass
 */
public without sharing class SharedSolarSystemHandler {
    private Boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public SharedSolarSystemHandler(Boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeUpdate(Shared_Solar_System__c[] oldSSSList, Shared_Solar_System__c[] updatedSSSList){
        summarizeCapacity(updatedSSSList);
    }
    private void summarizeCapacity(List<Shared_Solar_System__c> sssList){ 
        List<String> sssidlist = new List<String>();
        List<Utility_Account_Subscription__c> reservedCapacityList = new List<Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> committedCapacityList = new List<Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> anchorCapacityList = new List<Utility_Account_Subscription__c>();
        Decimal summarizedReservedCapacity = 0;
        Decimal summarizedCommittedCapacity = 0;
        Decimal summarizedAnchorCapacity = 0;

        for(Shared_Solar_System__c sss: sssList){
                String sssid = sss.Id;
                String subid = sssid.substring(0,15);
                sssidlist.add(subid);
        }

        List <Utility_Account_Subscription__c> relateduas = [ SELECT Id, Opportunity_Stage__c, Customer_Group__c, 
                                                                Opportunity__c, Next_Schedule_Z_Status__c, SSS_Id__c, 
                                                                Customer_Subscription_KW_DC__c, Customer_Subscription_KW_DC_STATIC__c
                                                                FROM Utility_Account_Subscription__c
                                                                WHERE SSS_Id__c IN : sssidlist];

        for (Utility_Account_Subscription__c uas: relateduas){
            if (uas.Customer_Group__c != 'Anchor'
                && uas.Next_Schedule_Z_Status__c != 'Cancelled'
                && (uas.Opportunity_Stage__c == 'Pending BlueWave Signature'
                || uas.Opportunity_Stage__c == 'QC in Process'
                || uas.Opportunity_Stage__c == 'Pending Quality Control Signature')){
                    reservedCapacityList.add(uas);
            }

            if (uas.Opportunity_Stage__c == 'Complete' 
                && uas.Customer_Group__c != 'Anchor'
                && uas.Next_Schedule_Z_Status__c != 'Cancelled'){
                    committedCapacityList.add(uas);
            }

            if ( (uas.Customer_Group__c == 'Anchor' ||
                uas.Customer_Group__c == 'Public Offtake')
                && uas.Opportunity_Stage__c != 'new' 
                && uas.Opportunity_Stage__c != 'Dead'){
                    anchorCapacityList.add(uas);
            }
        }

        for (Shared_Solar_System__c sssSummary : sssList){

            summarizedReservedCapacity = 0;
            summarizedCommittedCapacity = 0;
            summarizedAnchorCapacity = 0;

            if (reservedCapacityList.size()>0){
                for (Utility_Account_Subscription__c res: reservedCapacityList){
                    if (res.SSS_Id__c == sssSummary.Id 
                        && res.Customer_Subscription_KW_DC__c != null){
                            summarizedReservedCapacity = res.Customer_Subscription_KW_DC__c + summarizedReservedCapacity;
                    }
                }
            }
            if (committedCapacityList.size()>0){
                for (Utility_Account_Subscription__c comm: committedCapacityList){
                    if (comm.SSS_Id__c == sssSummary.Id 
                        && comm.Customer_Subscription_KW_DC_STATIC__c != null){
                            summarizedCommittedCapacity = comm.Customer_Subscription_KW_DC_STATIC__c + summarizedCommittedCapacity;
                    }
                }
            }
           if (anchorCapacityList.size()>0){
                for (Utility_Account_Subscription__c anchor : anchorCapacityList){
                    if (anchor.SSS_Id__c == sssSummary.Id 
                        && anchor.Customer_Subscription_KW_DC_STATIC__c != null){    
                        summarizedAnchorCapacity = anchor.Customer_Subscription_KW_DC_STATIC__c + summarizedAnchorCapacity;
                    }
                }
            }
            
            sssSummary.Reserved_Capacity_kW_DC__c = String.valueOf(summarizedReservedCapacity);
            sssSummary.Capacity_Committed_kW_DC__c = summarizedCommittedCapacity;
            sssSummary.Anchor_Capacity_Reserved__c = summarizedAnchorCapacity;
        }

    }
}