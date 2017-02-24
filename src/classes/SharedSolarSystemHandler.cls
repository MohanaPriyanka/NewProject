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

        List <Utility_Account_Subscription__c> relateduas = [ SELECT Id, Opportunity_Stage__c, Customer_Group__c, 
                                                                Opportunity__c, Next_Schedule_Z_Status__c, SSS_Id__c, 
                                                                Customer_Subscription_KW_DC__c, Customer_Subscription_KW_DC_STATIC__c
                                                                FROM Utility_Account_Subscription__c
                                                                WHERE SSS_Id__c IN : sssidlist];

        List <Opportunity> relatedanchors = [ SELECT Id, StageName, Customer_Group__c, Shared_Solar_System__c, 
                                                Shared_Solar_System_Name__c, CS_Capacity_Allocated__c
                                                FROM Opportunity
                                                WHERE Customer_Group__c = 'Anchor'];
        system.debug(relateduas);
        system.debug(relatedanchors);

        for(Utility_Account_Subscription__c uas: relateduas){
            if(uas.Customer_Group__c != 'Anchor'
                && uas.Customer_Subscription_KW_DC__c <= 26 
                && uas.Next_Schedule_Z_Status__c != 'Cancelled'
                && (uas.Opportunity_Stage__c == 'Pending BlueWave Signature'
                || uas.Opportunity_Stage__c == 'QC in Process'
                || uas.Opportunity_Stage__c == 'Pending Quality Control Signature')){
                    reservedCapacityList.add(uas);
                    system.debug(uas);
            }
            if(uas.Opportunity_Stage__c == 'Complete' 
                && uas.Customer_Group__c != 'Anchor'
                && uas.Next_Schedule_Z_Status__c != 'Cancelled'
                && uas.Customer_Subscription_KW_DC_STATIC__c <= 26){
                    committedCapacityList.add(uas);
                    system.debug(uas);
            }
        }
    //    anchorCapacityList.add(uas);

        for(Shared_Solar_System__c sssSummary : sssList){
            if(reservedCapacityList.size()>0){
                for(Utility_Account_Subscription__c res: reservedCapacityList){
                    if(res.SSS_Id__c == sssSummary.Id 
                        && res.Customer_Subscription_KW_DC__c != null){
                            summarizedReservedCapacity = res.Customer_Subscription_KW_DC__c + summarizedReservedCapacity;
                            system.debug(summarizedReservedCapacity);
                    }
                }
            }
            if(committedCapacityList.size()>0){
                for(Utility_Account_Subscription__c comm: committedCapacityList){
                    if(comm.SSS_Id__c == sssSummary.Id 
                        && comm.Customer_Subscription_KW_DC_STATIC__c != null){
                            system.debug('Committed Capacity List Size - ' + committedCapacityList.size());
                            system.debug('Committed Capacity - ' + comm.Customer_Subscription_KW_DC_STATIC__c );
                            summarizedCommittedCapacity = comm.Customer_Subscription_KW_DC_STATIC__c + summarizedCommittedCapacity;
                    }
                }
            }
            if(relatedanchors.size()>0){
                for(Opportunity anc: relatedanchors){
                    system.debug(anc.Shared_Solar_System__c);
                    if (anc.Shared_Solar_System_Name__c == sssSummary.Name 
                        && anc.CS_Capacity_Allocated__c != null 
                        && anc.StageName != 'new' 
                        &&  anc.StageName != 'Dead') {
                            summarizedAnchorCapacity = anc.CS_Capacity_Allocated__c + summarizedAnchorCapacity;
                    }
                }
            }
            
            sssSummary.Reserved_capacity_kW_DC__c = string.valueOf(summarizedReservedCapacity);  
            sssSummary.Capacity_committed_kW_DC__c = summarizedCommittedCapacity; 
            sssSummary.Anchor_capacity_reserved__c = summarizedAnchorCapacity;   

            summarizedReservedCapacity = 0;
            summarizedCommittedCapacity = 0;
            summarizedAnchorCapacity = 0;
        }

    }
}