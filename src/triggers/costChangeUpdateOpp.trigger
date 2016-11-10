Trigger costChangeUpdateOpp on utility_account_log__c (after insert, after update) {

string totalsum;
set <string> oppNames = new Set <string>( ); 
List <opportunity> opportunityUpdateList = new List <opportunity>( );

for (utility_account_log__c UAL: trigger.new) {

  If ((trigger.isInsert || trigger.isUpdate) && UAL.opportunity__c!= null) {
      oppNames.add (UAL.opportunity__c);}}
      
if(oppNames.size() > 0){

opportunity opp = [SELECT id FROM opportunity WHERE id  IN : oppNames];
    
    opportunityUpdateList.add(opp);

if(opportunityUpdateList != null){
     
    update opportunityUpdateList;}}
    
else{

return;}}