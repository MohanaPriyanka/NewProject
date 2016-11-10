/*
    Developed by Cole Swain - colemswain@gmail.com 
    
    the diluteUASSubscription trigger weights each Utility Account Subscription relative to the overal cost need for the various Utility Account Logs under the application and dividees the 
    cost for each UAS so that they sum to be equal to or less than the maximum subscription for the Shared Solar System being assigned to.
*/

Trigger diluteUASSubscription on Utility_Account_Subscription__c (before update){ 

    //Decimal uasCostAggSubSum;
    //Decimal uasCostAggFullSum;  
    //Decimal uasCostAvg;
    //Decimal uasMaxCost;
    //Decimal uasCostDifference;
    //Decimal uasCostDeduction;
    //Decimal uasWeightedCostDeduction;
    //Decimal uasCostWeight;
    //Decimal uasCostSum;
    //Decimal uasCalcCostSum;
    //Decimal uasCount;
    //Decimal uasCost;
    //Decimal maxSub;
    
    //Set<String> uasOppIDs = new Set<String>();
    //Set<Decimal> uasNumbers = new Set<Decimal>();
    //List<String> leadIdList= new List<String>();
    //try{
    //    for(Utility_Account_Subscription__c uas : Trigger.new){
    //        //if the utility account subscription is updated add its opportunity ID to the uasOppIDs list as well as its UAS Number (Counter)
    //        if(Trigger.isUpdate){
    //            uasOppIDs.add(uas.Opportunity__c);
    //            uasNumbers.add(uas.UAS_Number__c);
    //        }
    //        //run an aggregation query to count the amount of Utility Account Subscriptions under the parent opportunity record that are in the same counter sequence.
    //        //Also sum their subscribed cost of electricity as well as their calculated cost of electricy and grab the maximum cost (average will always be the same value).                                            
    //        Aggregateresult uasAggregates = [   SELECT count(id)idCount, 
    //                                                   sum(subscribed_annual_cost_of_electricity__c)costSum, 
    //                                                   sum(calculated_annual_cost_of_electricity__c)calcCostSum, 
    //                                                   avg(Maximum_Annual_Cost__c)maxCost
    //                                            FROM Utility_Account_Subscription__c 
    //                                            WHERE  Opportunity__c != null AND Opportunity__c IN : uasOppIDs AND UAS_Number__c IN : uasNumbers];
    //        uasMaxCost = (Decimal)uasAggregates.get('maxCost');
    //        uasCount = (Decimal)uasAggregates.get('idCount');
    //        uasCostSum = (Decimal)uasAggregates.get('costSum');
    //        uasCalcCostSum = (Decimal)uasAggregates.get('calcCostSum');

    //        //if the sum of the subscribed cost of electiricy is greater than or equal to the maximum annual cost execute the following - e.g. if all of the UAS added together is over the 
    //        //maximum subscription amount for one system then execute the following so that they can be weighted and divided relative to each other.  
    //        if(uasCostSum >= uasMaxCost){
    //            //Subtract the maximum cost of electricity from the total calculated cost of electricity. This is equal to the amount the UAS cost has gone over the maximum cost by.
    //            uasCostDeduction = uasCalcCostSum - uasMaxCost ;
    //            //Divide the triggered utility account subscription's calculated cost of electricity by the total calculated cost of electricity to arrive at its weight.
    //            uasCostWeight = uas.calculated_annual_cost_of_electricity__c / uasCalcCostSum ;
    //            //Multiply the weights by the amount total cost has gone over the maximum by to arrive at how much cost needs to be deducted from each UAS.
    //            uasWeightedCostDeduction = uasCostDeduction * uasCostWeight;
    //            //set the subscribed annual cost of electricity to the calculated cost minus the calculted weighted deduction above.
    //            uas.subscribed_annual_cost_of_electricity__c = uas.calculated_annual_cost_of_electricity__c - uasWeightedCostDeduction ; 
    //            uas.trigger_tester__c = uasCostWeight;
    //        }else{
    //            //if all of the UAS added together is not over the maximum subscription amount for one system then set the subscribed annual cost equal to the calculated annual cost.  
    //            uas.subscribed_annual_cost_of_electricity__c =  uas.calculated_annual_cost_of_electricity__c;
    //        }
    //    }
    //}catch(system.nullpointerexception e){ 
    //    return;
    //}
}