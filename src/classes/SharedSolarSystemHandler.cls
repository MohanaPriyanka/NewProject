public with sharing class SharedSolarSystemHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public SharedSolarSystemHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeUpdate(Shared_Solar_System__c[] oldSSSList, Shared_Solar_System__c[] updatedSSSList){
        summarizeCapacity(updatedSSSList);
    }
    private void summarizeCapacity(List<Shared_Solar_System__c> sssList){ 
        List <string> sssidlist = new list <string> ();
        list<Utility_Account_Subscription__c> reservedCapacityList = new list <Utility_Account_Subscription__c>();
        list<Utility_Account_Subscription__c> committedCapacityList = new list <Utility_Account_Subscription__c>();
        list<Utility_Account_Subscription__c> anchorCapacityList = new list <Utility_Account_Subscription__c>();
        decimal summarizedReservedCapacity = 0;
        decimal summarizedCommittedCapacity = 0;
        decimal summarizedAnchorCapacity = 0;

        for(Shared_Solar_System__c sss: sssList){
                string sssid = sss.Id;
                string subid = sssid.substring(0,15);
                sssidlist.add(subid);
                system.debug(sssidlist);
        }

        List <Utility_Account_Subscription__c> relateduas = [ SELECT Id, Opportunity_Stage__c, Customer_Group__c, Opportunity__c, SSS_Id__c, Customer_Subscription_KW_DC_STATIC__c
                                                              FROM Utility_Account_Subscription__c
                                                              WHERE SSS_Id__c IN : sssidlist];
        system.debug(relateduas);

        for(Utility_Account_Subscription__c uas: relateduas){
            if(uas.Customer_Group__c != 'Anchor' 
                && (uas.Opportunity_Stage__c == 'Pending BlueWave Signature'
                || uas.Opportunity_Stage__c == 'QC in Process'
                || uas.Opportunity_Stage__c == 'Pending Quality Control Signature')){
                    reservedCapacityList.add(uas);
                    system.debug(uas);
            }
            if(uas.Opportunity_Stage__c == 'Complete' && uas.Customer_Group__c != 'Anchor'){
                    committedCapacityList.add(uas);
                    system.debug(uas);
            }
            if(uas.Customer_Group__c == 'Anchor' 
                && (uas.Opportunity_Stage__c != 'New'
                || uas.Opportunity_Stage__c != 'Dead')){
                    anchorCapacityList.add(uas);
                    system.debug(uas);
            }
        }

        for(Shared_Solar_System__c sssSummary : sssList){
            if(reservedCapacityList.size()>0){
                for(Utility_Account_Subscription__c res: reservedCapacityList){
                    if(res.SSS_Id__c == sssSummary.Id && res.Customer_Subscription_KW_DC_STATIC__c != null){
                            summarizedReservedCapacity = res.Customer_Subscription_KW_DC_STATIC__c + summarizedReservedCapacity;
                            system.debug(summarizedReservedCapacity);
                    }
                }
            }
            if(committedCapacityList.size()>0){
                for(Utility_Account_Subscription__c comm: committedCapacityList){
                    if(comm.SSS_Id__c == sssSummary.Id && comm.Customer_Subscription_KW_DC_STATIC__c != null){
                            system.debug('Committed Capacity List Size - ' + committedCapacityList.size());
                            system.debug('Committed Capacity - ' + comm.Customer_Subscription_KW_DC_STATIC__c );
                            summarizedCommittedCapacity = comm.Customer_Subscription_KW_DC_STATIC__c + summarizedCommittedCapacity;
                    }
                }
            }
            if(anchorCapacityList.size()>0){
                for(Utility_Account_Subscription__c anc: anchorCapacityList){
                    if(anc.SSS_Id__c == sssSummary.Id && anc.Customer_Subscription_KW_DC_STATIC__c != null){
                            summarizedAnchorCapacity = anc.Customer_Subscription_KW_DC_STATIC__c + summarizedAnchorCapacity;
                    }
                }
            }
            
            sssSummary.Reserved_capacity_kW_DC__c = string.valueOf(summarizedReservedCapacity);  
            sssSummary.Capacity_committed_kW_DC__c = summarizedCommittedCapacity; 
            sssSummary.Anchor_capacity_reserved__c = summarizedAnchorCapacity;     
        }

    }
}