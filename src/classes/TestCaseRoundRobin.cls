@isTest
private class TestCaseRoundRobin {
    
    @testSetup static void setupData(){
        Case_Round_Robin_Queue__c rrq = new Case_Round_Robin_Queue__c();
        rrq.Name = 'Test';
        rrq.Standard_Queue_Id__c = [Select QueueId
                                              From QueueSobject q
                                              where sobjecttype = 'Case'
                                              limit 1].QueueId; 
        rrq.Next_Position__c = 1;
        insert rrq;
    }

    @isTest static void testWeightedRoundRobin() {
        Case_Round_Robin_Queue__c rrq = [SELECT Id FROM Case_Round_Robin_Queue__c LIMIT 1];

        Case_Round_Robin_Queue_Member__c rrm = new Case_Round_Robin_Queue_Member__c();
        rrm.Case_Round_Robin_Queue__c = rrq.id;
        rrm.Member__c = [select id from user where isActive = true limit 1].id;
        rrm.Position__c = 1;
        insert rrm;

        Case l = new Case(Subject='testLast');
        
        l.OwnerId = [Select Case_Round_Robin_Queue__r.Standard_Queue_Id__c From Case_Round_Robin_Queue_Member__c where Case_Round_Robin_Queue__r.Is_Active__c = true limit 1].Case_Round_Robin_Queue__r.Standard_Queue_Id__c ;

        try{
            insert l;
        }catch (Exception e){

        }

        Case_RR_Queue_Member_Assignment__c ll = new Case_RR_Queue_Member_Assignment__c();
        ll.Weight__c = 4;
        ll.Member__c = [select id from user where isActive = true limit 1].id;
        ll.Case_Round_Robin_Queue__c = rrq.id;
        insert ll;

        Case_RR_Queue_Member_Assignment__c ll2 = new Case_RR_Queue_Member_Assignment__c();
        ll2.Weight__c = 3;
        ll2.Member__c = [select id from user where isActive = true and id != :rrm.Member__c limit 1].id;
        ll2.Case_Round_Robin_Queue__c = rrq.id;
        insert ll2;

        RoundRobinDistribution.loadDistribution('Case',rrq.Id);
    }
    
}