/*
    Developed by Cole Swain - colemswain@gmail.com (Last Updated 08/04/2016)
    
    summarizeCapacity aggregates the customer subscriptions per system onto the system's layout for reporting and analytics.
    
    JP - added anchor statuses and removed "contract pending" from reserved capacity
*/

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
        //Instantiate the variables and lists
        list<opportunity> reservedCapacityList = new list<opportunity>();
        list<opportunity> committedCapacityList = new list<opportunity>();
        list<opportunity> anchorCapacityList = new list<opportunity>();
        integer i;
        decimal summarizedReservedCapacity = 0;
        decimal summarizedCommittedCapacity = 0;
        decimal summarizedAnchorCapacity = 0;
        if(sssList.size()>0){
            for(Opportunity oppList : [ SELECT CS_capacity_allocated__c, StageName, Product_line__c, 
                                               Customer_group__c, Shared_Solar_System__c, False_record__c
                                        FROM Opportunity
                                        WHERE Shared_Solar_System__c != null AND False_record__c = FALSE]){
                if(oppList.Product_line__c == 'Community Solar' && oppList.Customer_group__c != 'Anchor' 
                    && ( oppList.StageName == 'Pending BlueWave Signature' 
                        || oppList.StageName == 'QC in Process' 
                        || oppList.StageName == 'Pending Quality Control Signature')){
                    reservedCapacityList.add(oppList);
                }
                if(oppList.Product_line__c == 'Community Solar' && oppList.Customer_group__c != 'Anchor' && oppList.StageName == 'Complete'){
                    committedCapacityList.add(oppList);
                } 
                if(oppList.Product_line__c == 'Community Solar' && oppList.Customer_group__c == 'Anchor' && oppList.StageName != 'New' && oppList.StageName != 'Dead'){
                    anchorCapacityList.add(oppList);
                }                                                    
            }
            try{
                for(Shared_Solar_System__c sssSummary : sssList){
                    for(i=0;i<reservedCapacityList.size();i++){
                        if(reservedCapacityList.get(i).Shared_Solar_System__c == sssSummary.Id){
                            summarizedReservedCapacity = reservedCapacityList.get(i).CS_capacity_allocated__c + summarizedReservedCapacity;
                        }
                    }
                    for(i=0;i<committedCapacityList.size();i++){
                        if(committedCapacityList.get(i).Shared_Solar_System__c == sssSummary.Id){
                            system.debug('Committed Capacity List Size - ' + committedCapacityList.size());
                            system.debug('List Sequence - ' + i);
                            system.debug('Committed Capacity - ' + committedCapacityList.get(i).CS_capacity_allocated__c );
                            summarizedCommittedCapacity = committedCapacityList.get(i).CS_capacity_allocated__c + summarizedCommittedCapacity;
                        }
                    }
                    for(i=0;i<anchorCapacityList.size();i++){
                        if(anchorCapacityList.get(i).Shared_Solar_System__c == sssSummary.Id){
                            summarizedAnchorCapacity = anchorCapacityList.get(i).CS_capacity_allocated__c + summarizedAnchorCapacity;
                        }
                    }
                    sssSummary.Reserved_capacity_kW_DC__c = string.valueOf(summarizedReservedCapacity);  
                    sssSummary.Capacity_committed_kW_DC__c = summarizedCommittedCapacity; 
                    sssSummary.Anchor_capacity_reserved__c = summarizedAnchorCapacity;                               
                }
            }
            catch(system.nullpointerexception e){
                return;
            }
        }
    }
}