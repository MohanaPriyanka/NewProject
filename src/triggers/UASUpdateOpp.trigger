/*
    Developed by Cole Swain - colemswain@gmail.com 
    
    the UASUpdateOpp updates the Opportunity when the UAS is inserted/updated to trigger the addUtilityLogCost trigger to roll up the subscription values. 
*/

trigger UASUpdateOpp on utility_account_subscription__c (after insert, after update) {
    //String totalsum;
    //Set<Id> oppIdSet = new Set<Id>(); 
    //List<Opportunity> opportunityUpdateList = new List<Opportunity>();

    //for (utility_account_subscription__c uas: trigger.new) {
    //    //if the UAS record's UAS Number holds a value and it is related to an opportnity add the Opportunity to the oppIdSet List.
    //    if(uas.UAS_number__c != null && uas.Opportunity__c != null) {
    //        oppIdSet.add(uas.Opportunity__c);
    //    }
    //}

    //if(oppIdSet.size() > 0){
    //    //Query the Opportunity records for the Opportunity in which the UAS is related to.
    //    Opportunity opp = [SELECT id, uas_created__c FROM Opportunity WHERE id  IN : oppIdSet];
    //    //Set the UAS Created field to true and add it to the opportuntyUpdateList
    //    opp.uas_created__c = true;
    //    opportunityUpdateList.add(opp);

    //    if(opportunityUpdateList != null){
    //        //Update the opportunityUpdateList
    //        update opportunityUpdateList;
    //    }
    //}
}