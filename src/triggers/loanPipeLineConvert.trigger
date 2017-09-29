trigger loanPipeLineConvert on Lead (before update){

Map<Id, Id> feedback2OppId = new Map<Id, Id>();
Map<Id, Id> opportunityMap = new Map<Id, Id>();

//instantiate the maps to bulkify the trigger. 

For (Lead l : Trigger.new)
       {
             if (l.isConverted && l.convertedOpportunityId != null)
             {
//If the lead is converted and an opportunity is generated as a result of this convert continue

                      feedback2OppId.put(l.Id, l.convertedOpportunityId);
                      opportunityMap.put(l.convertedOpportunityId,l.convertedOpportunityId);}}

//Add the ID of the lead being converted to the feedback2OppId map's key value. Add the converted opportunity's ID to the map's content.
//Add the converted opportunities to both the key and content of the opportunityMap.     

     List<MCEC_Report_Data__c> pipeLineList = [SELECT lead__c, opportunity__c FROM MCEC_Report_Data__c WHERE lead__c IN :feedback2OppId.keySet()];

//Perform a SQL query on the PipeLine Report finding the lead it was related to along with the Opportunity. 
//The SQL query filters the leads for leads in which the lead ID is in the feedback2OppId map's key values.
     
     for (MCEC_Report_Data__c u : pipeLineList)
     {
            u.opportunity__c = feedback2OppId.get(u.lead__c);

//perform a loop which updates all of the PipeLine reports in the queried list and changes their opportunity relationship to the new converted opportunity.

     }
 
     update pipeLineList;}

//Update this list with the changes made.