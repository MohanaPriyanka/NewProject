public class RoundRobinHandler {
	
    public String objType;
    public List<SObject> records;
    public Map<Id,SObject> oldMap;
    public List<SObject> queueIdsCustomSettings;

    public RoundRobinHandler(List <SObject> records, Map<Id, SObject> oldMap, String objType, List<SObject> queueIdsCustomSettings){
        this.records = records;
        this.oldMap = oldMap;
        this.objType = objType;
        this.queueIdsCustomSettings = queueIdsCustomSettings;
    }

    //Handles setting standard id assignments for object queues
    public static void setStandardQueueIds(List<SObject> records){
        Id sID;

        for(SObject rec : records) {
           sID = (Id)rec.get('Standard_Queue_Id__c');
           rec.put('Standard_Queue_Id__c',String.valueOf(sID));
        }
    }

    public void handleRoundRobinAssignments (){
        Boolean isInsert = (oldMap == null);
        Set<String> eligibleQueues = new Set<String>();

        for(SObject q : queueIdsCustomSettings){
            String qName = (String)q.get('Name');
            eligibleQueues.add(qName);
            system.debug('###eligible Queue='+qName); 
        }   
       
        if(eligibleQueues.size() == 0){
            system.debug('###returning because of no queue ids in custom setting');
            return;
        }
                 
        Set <Id> queueIds = new Set <Id>();   
        Set <Id> recIds = new Set <Id>();    

        for(SObject rec : records){
            // if the record is now assigned to an eligible queue
            
            Id recId = (Id)rec.get('Id');
            Id ownerId = (Id)rec.get('OwnerId');
            if(eligibleQueues.contains(ownerId)
                && (Boolean)rec.get('Skip_Round_Robin__c')==false
                && ((isInsert == true ) 
                    || (isInsert == false && (Id)oldMap.get(recId).get('OwnerId') != ownerId))) {
                queueIds.add(ownerId);
                recIds.add(recId);
                system.debug('###eligible Queue=' + ownerId);     
            } 
        }
        
        if(recIds.size() == 0){
            system.debug('###returning because record did not meet criteria');
            return;
        }

        // Build Maps of the Eligible Queues   
        Map <String,Id> qMembers = new Map <String,Id>();
        Map <Id, Integer> qMemberCount = new Map <Id, Integer>();
        Map <String, SObject> qNext = new Map <String, SObject>();

        Integer cnt;

        for(SObject q: RoundRobinUtils.getEligibleQueues(objType,queueIds)){
            String standardQueueId = (String)q.get('Standard_Queue_Id__c');
            cnt = 0;
        
            for(SObject qm : q.getSObjects(RoundRobinUtils.getQueueMemberChildObjType(objType))){
                cnt++; 
                qMembers.put(standardQueueId + '-' + cnt, (Id)qm.get('Member__c')); 
            }
      
            qMemberCount.put(standardQueueId, cnt);
            qNext.put(standardQueueId, q);
         
        }
      
        if(qMembers.size() == 0)
        {
            return;
        }

        // find the inactive users
        // this will get rid of groups
        Set <Id> activeUsers = new Set <Id>();
   
        //treat pause round robin the same as inactive, skip
        for(User u : [SELECT Id 
                      FROM user 
                      WHERE Id in :qMembers.values() 
                      AND IsActive = true 
                      AND Pause_Round_Robin__c = false]){
            activeUsers.add(u.id);
        }
      
        Integer nxtRep;
        Id nxtRepId;
   
        List <SObject> recsToUpdate = new List <SObject>();
    
        for(SObject rec : RoundRobinUtils.getRecsToUpdate(objType, eligibleQueues, recIds)){
            String ownerId = (String)rec.get('OwnerId');
            if(qNext.containsKey(ownerId)){
                Decimal nxtRepDec = (Decimal)qNext.get(ownerId).get('Next_position__c');
                nxtRep = nxtRepDec.intValue();
            
                // if for some reason a member is deleted from the queue and 
                //the next rep is greater than the member count
                // need to check and if not there, go back to number 1
                if(nxtRep > qMemberCount.get(ownerId)){
                    nxtRep = 1;
                }         
         
                //if missing from the middle because inactive
                boolean activeFound = false;   
         
                do{
                        
                    if(activeUsers.contains(qMembers.get(ownerId + '-' + nxtRep))){
                        activeFound = true;
                    }
                    else {
                        nxtRep++;
                        if(nxtRep > qMemberCount.get(ownerId)){
                            nxtRep = 1;
                        }
                    }    
            
                } while (activeFound == false);   
            
                // get the user id for the rep found
                nxtRepId = qMembers.get(ownerId + '-' + nxtRep);
         
                //debugging
                rec.put('Round_Robin_Queue__c',ownerId);
                rec.put('Round_Robin_Queue_Position__c',String.valueof(nxtRep));
                
          
                //set the next rep
                if(nxtRep + 1 <= qMemberCount.get(ownerId)){
                    nxtRep++;
                }else{
                    nxtrep = 1;
                }
            
                SObject x = qNext.get(ownerId);
                x.put('Next_position__c',nxtRep);
                qNext.put(ownerId, x);
          
            } 
            rec.put('OwnerId',nxtRepId);   
            recsToUpdate.add(rec);
        }

        if(!recsToUpdate.isEmpty()){
            update recsToUpdate;
        }

        // Update the Queues
        List <SObject> roundRobinQueuesToUpdate = new List <SObject>();
   
        for(SObject rrq : qNext.values()){
            roundRobinQueuesToUpdate.add(rrq);
        }    
        update roundRobinQueuesToUpdate;
    }
    
}