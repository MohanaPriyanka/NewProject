Trigger SSSAddReservations on opportunity (after insert, after update) {

////include after insert and after update because we want to add in the new reservation to the total capacity reserved/committed

//string totalsum;
//set <string> projectNames = new Set <string>( ); 
//List <shared_solar_system__c > projectAllocations = new List <shared_solar_system__c >( );

////instantiate variables

//for (opportunity project: trigger.new) {

//  If ((trigger.isInsert || trigger.isUpdate) && project.shared_solar_system__c != null) {
//      projectNames.add (project.shared_solar_system__c);}}
      
////fire trigger on the insertion/update of an opportunity 
////add the id of the shared solar system to the projectNames set

//if(projectNames.size() > 0){

//shared_solar_system__c project = [SELECT id,Reserved_Capacity_kW_DC__c FROM shared_solar_system__c WHERE id  IN : projectNames];
    
//    projectAllocations.add(project);

//if(projectAllocations != null){
     
//    update projectAllocations;}}
    
////If the projectNames set holds a value then query for shared solar systems in which ID is in the projectNames set. This query finds the shared solar system attached to the opportnity firing the trigger.
////Line 23 Adds the queried record to the projectAllocations list. 
////If the projectAllocations list holds a value then update the list, which updates the record queried in the query on line 21.

//else{

//return;}

}

//this else statement is in place to avoid throwing an error statment if there is no shared solar system linked to the opportunity record.