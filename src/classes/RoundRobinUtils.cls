public class RoundRobinUtils {
	
    public static List<SObject> getEligibleQueues(String objType, Set<Id> queueIds){
        String query = 'SELECT Standard_Queue_Id__c, Next_Position__c, '
            + ' (SELECT Id, Member__c, Position__c '
            + ' FROM ' + getQueueMemberChildObjType(objType)
            + ' ORDER BY position__c ASC) '
            + ' FROM ' + getQueueObjName(objType) + ' WHERE Standard_Queue_Id__c IN :queueIds ';
        return Database.query(query);
    }

    public static String getQueueObjName(String objType){
        return objType + '_Round_Robin_Queue__c';
    }

    public static String getQueueMemberObjName(String objType){
        return objType + '_Round_Robin_Queue_Member__c';
    }

    public static String getQueueMemberAssignmentObjName(String objType){
        return objType + '_RR_Queue_Member_Assignment__c';
    }

    public static String getQueueMemberChildObjType(String objType){
        return objType + '_Round_Robin_Queue_Members__r';
    }

    public static String getCustomSettingObjName(String objType){
        return objType + '_Round_Robin_Queue_Ids__c';
    }

    

    public static List<SObject> getRecsToUpdate(String objType, Set<String> eligibleQueues, Set<Id> recIds){
        String query = ' SELECT Id,OwnerId FROM ' + objType
                    + ' WHERE Id IN :recIds '
                    + ' AND OwnerId IN :eligibleQueues';
        return Database.query(query);
    }

    //Set custom setting values
    public static void updateCustomSetting (String objType,List <SObject> records){
        // delete them all
        String delQuery = 'SELECT Id FROM ' + getCustomSettingObjName(objType);
        List <SObject> queuesToDelete = Database.query(delQuery);
        delete queuesToDelete;

        List <SObject> queuesToCreate = new List <SObject>();
        
        String queueQuery = 'SELECT Standard_Queue_Id__c '
                        +   ' FROM ' + getQueueObjName(objType)
                        +   ' WHERE Is_Active__c = true';
        for(SObject queue : Database.query(queueQuery)){
            SObject newQueueId = Schema.getGlobalDescribe().get(getCustomSettingObjName(objType)).newSObject();
            
            newQueueId.put('Name',(String)queue.get('Standard_queue_Id__c'));   
            queuesToCreate.add(newQueueId);
        }
        
        if(!queuesToCreate.isEmpty()){
            insert queuesToCreate;
        }
    }
}