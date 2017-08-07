/*
    Developed by Cole Swain - colemswain@gmail.com 
    
    the createUAS trigger finds all of the Utility Account Logs related to the newly converted opportunity and creates a Utility Account Subscription for every Log found.
*/

trigger createUAS on Opportunity (after insert){ 
    
    //Integer i = 0;
    //List<utility_account_subscription__c> uasList = new List<utility_account_subscription__c>(); 
    //List<id> ualListID = new List<id>(); 
    //List<String> ualListName = new List<String>(); 
    //List<String> ualListNameOnAccount = new List<String>(); 
    //List<Decimal> ualListAnnualCost = new List<Decimal>(); 
    //for(Opportunity o : Trigger.new){
    //    if(Trigger.isInsert){
    //        //Query the Utility Account Log records for all records where the lead ID is equal to the opportunity record's converted lead ID.
    //        //This should be changed to query for all Utility Account Log records that share the same Account ID as the opportunity Account ID.
    //        for(utility_account_log__c obj : [  SELECT id, name, name_on_account__c, annual_cost_of_electricity__c
    //                                            FROM utility_account_log__c 
    //                                            WHERE lead__c != null AND lead__r.id = : o.lead_id__c ORDER BY name]){
    //            //Add the query's returned values to the lists specified below
    //            ualListID.add(obj.id);
    //            ualListName.add(obj.name);
    //            ualListNameOnAccount.add(obj.name_on_account__c);
    //            ualListAnnualCost.add(obj.annual_cost_of_electricity__c);
    //        }
    //        //Instantiate a loop that runs until i is greater than or equal to the amount of Utility Account Logs returned in the above SOQL query.      
    //        for(i=0; i < ualListID.size(); i++){
    //          //Add a new Utility Account Subscription record to the uasList
    //            uasList.add(new utility_account_subscription__c(
    //               opportunity__c = o.id,
    //               name_on_account__c = ualListNameOnAccount.get(i), 
    //               name = ualListName.get(i),
    //               annual_cost_of_electricity__c = ualListAnnualCost.get(i), 
    //               utility_account_log__c = ualListID.get(i)));
    //        }
    //    }
    //}
    ////insert the list of newly created Utility Account Subscriptions.
    //insert uasList;
}