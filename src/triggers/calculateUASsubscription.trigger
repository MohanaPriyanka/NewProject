/*
    Developed by Cole Swain - colemswain@gmail.com 
    
    the calculateUASsubscription trigger established the sequencing order for each Utility Account Subscription 
    then calculates the calculated annual cost of electricity on the Utility Account Subscription record. This calculation takes into account
    already subscribed cost on previouse utility account subscriptions for the same utility account log.
*/
trigger calculateUASsubscription on Utility_Account_Subscription__c (before insert){ 

    //Decimal uasCostAggSubSum;
    //Decimal uasCostAggFullSum;  
    //Decimal uasCostAvg;
    //Decimal uasCost;
    //Decimal maxSub;
    //Set<String> uasList = new Set<String>();
    //List<String> leadIdList= new List<String>();
    //try{

    //    for(Utility_Account_Subscription__c uas : Trigger.new){
    //        if(Trigger.isInsert){
    //            //Add the utility account subscription's name that was just inserted to the uasList.
    //            uasList.add(uas.name);
    //        }
            
    //        //Run an Aggregation query that counts the amount of Utility Account Subscriptions in the system that exist with the same Utility Account Number (Name).
    //        Decimal uasCounter;
    //        for(Aggregateresult uasCount: [ SELECT count(id)idCount
    //                                        FROM Utility_Account_Subscription__c 
    //                                        WHERE name = : uas.name]){
    //            //Add 1 to the uasCounter because the triggered record will not be accounted for in the aggregation query because it is a before insert. 
    //            uasCounter = (Decimal)uasCount.get('idCount') + 1;
    //        }

    //        //Set the UAS_Number__c field to the uasCounter to represent the Utilit Account Subscription's sequencing order. 
    //        uas.uas_number__c = uasCounter;

    //        //if the Utility Account Subscription is the first created for an account execute the following:              
    //        if(uasCounter <= 1) {
    //             //Run an Aggregation query that averages out the annual cost of electricity for the Utility Account Log that shares the same Utility Account Number
    //             //The average of the annual cost of electricity will always be the same value as there will only be one Utility Account Log for each Utility Account Subscription.
    //             //This could be changed to be just a standard SOQL query for the annual cost of electricity of the UAL that is the parent of the UAS
    //            for(Aggregateresult uasAnnualCost : [   SELECT avg(annual_cost_of_electricity__c)avgLogCost
    //                                                    FROM Utility_Account_Log__c 
    //                                                    WHERE name IN : uasList]){
    //                //set the uasCost to the minimum of either the maximum annual cost of electricity (formula on the UAS record that gets its value from the Opportunity's shared solar system record)
    //                //or the total reported cost for the UAS's parent Utility Account Log.
    //                uasCost = math.min((Decimal)uasAnnualCost.get('avgLogCost'),uas.Maximum_Annual_Cost__c);
    //                //set the calculated annual cost of electricity to the minimum of these two values above.
    //                uas.calculated_annual_cost_of_electricity__c = uasCost;
    //            }
    //        } else{
    //            //if the UAS is not the first created for an account execute the following:
    //            //Run an Aggregation query that sums together all of the subscribed annual cost of electricity for any Utility Account Subscriptions that exist with the same Utility Account Number.
    //            //The subscribed annual cost of electricity is the value calculated after the diluteUAS trigger is fired for each record.
    //            //It also averages out the full annual cost of electricity for all of the queried UAS. All of these values are the same so the return value is always the same. 
    //            for(Aggregateresult uasSubscriber : [   SELECT sum(subscribed_annual_cost_of_electricity__c)subCostSum, avg(annual_cost_of_electricity__c)avgCost
    //                                                    FROM Utility_Account_Subscription__c 
    //                                                    WHERE uas_number__c < : uasCounter AND name = : uas.name]){
    //                uasCostAvg = (Decimal)uasSubscriber.get('avgCost');
    //                uasCostAggSubSum = (Decimal)uasSubscriber.get('subCostSum');
    //                //Set the calculated annual cost of electricity to the minimum value of either the maximum cost of electricity (formula field again) 
    //                //or the maximum cost of electricity - the already subscribed electricity
    //                uas.calculated_annual_cost_of_electricity__c = math.min(uasCostAvg - uasCostAggSubSum, uas.Maximum_Annual_Cost__c);
    //            }
    //        }
    //    }
    //}
    
    ////if the queries return a null value end the program.
    //catch(system.nullpointerexception e){
    //    return;
    //}
}