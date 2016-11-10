trigger CoApplicantContactConvert on Lead (before update){

Map<Id, Id> feedback2OppId = new Map<Id, Id>();
Map<Id, Id> opportunityMap = new Map<Id, Id>();


For (Lead l : Trigger.new)
       {
             if (l.isConverted && l.convertedOpportunityId != null && l.product_line__c == 'Residential Loan' && l.application_type__c == 'Joint')
             {

                      feedback2OppId.put(l.Id, l.convertedOpportunityId);
                      opportunityMap.put(l.convertedOpportunityId,l.convertedOpportunityId);}}

     List<Contact> contactLIst = [SELECT lead__c, opportunity__c FROM Contact WHERE lead__c IN :feedback2OppId.keySet()];

     for (Contact u : contactList)
     {
            u.opportunity__c = feedback2OppId.get(u.lead__c);

     }
 
     update ContactList;}