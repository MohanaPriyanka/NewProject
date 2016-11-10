Trigger mapToPipelineReport on Loan__c (after insert) {

map<id, loan__c> loanOppIDs = new map<id, loan__c>();
list<MCEC_Report_Data__c > pipeLineList = new list<MCEC_Report_Data__c >();

for(loan__c loan : trigger.new){

    if(trigger.isInsert){

       loanOppIds.put(loan.opportunity__c, loan);

    }
}

try{

for(MCEC_Report_Data__c pipeLineQuery : [ 
        
            SELECT id, opportunity__c, loan__c
            FROM MCEC_Report_Data__c 
            WHERE opportunity__c IN : loanOppIds.keySet() AND opportunity__c != null]){

    pipeLineQuery.loan__c = loanOppIds.get(pipeLineQuery.opportunity__c).id;

    pipeLineList.add(pipeLineQuery);}}

Catch(system.listException e){ 

return;}  

    update pipeLineList; }