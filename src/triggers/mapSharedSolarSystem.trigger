//commented out due to implementation of MapSharedSolarSystemHandler class. 

Trigger mapSharedSolarSystem on Opportunity (before update, before insert) {
/*
set <string> serviceTerritories = new Set <string>( ); 
set <string> utilityNames = new set <string>( );
set <string> systemListValues = new set <string>( );

list<id> sssList = new list<id>();
list<decimal> availableCapList = new list<decimal>();
list<string> reservedCapList = new list<string>();

for ( opportunity l : trigger.new) {

    if((l.project_assignment__c == 'Automatic' || l.project_assignment__c == null) && l.product_line__c == 'Community Solar'){   

//If Shared Solar System Assignment is equal to Automatic or null and the product line is equal to Community Solar continue.
//This runs the automated part of the code. If this is run, the Shared Solar System is automatically assigned. 

        If ( trigger.isInsert || trigger.isUpdate) {
    
            serviceTerritories.add (l.service_territory__c);
            utilityNames.add (l.UtilityMapper__c);}}   
            
//Add the opportunity's service territory and utility to their respective sets.                  

        if (serviceterritories.size( ) > 0 && utilityNames.size( ) > 0 ) {
       
        for(shared_solar_system__c obj : [
        
            SELECT Id, Project_Capacity_Available_kW_DC__c, Reserved_Capacity_kW_DC__c 
            FROM shared_solar_system__c 
            WHERE Project_Capacity_Available_kW_DC__c > 0 
            AND open__c = TRUE
            AND service_territory__c 
            IN : serviceterritories  
            AND System_Utility__c 
            IN : utilityNames 
            ORDER BY Estimated_COD_Date__c
            ASC]){

            sssList.add (obj.id); 
            availableCapList.add(obj.Project_Capacity_Available_kW_DC__c);
            reservedCapList.add(obj.Reserved_Capacity_kW_DC__c );}
            
//If the serviceTerritories and utilityNames sets hold values continue.
//Query Shared Solar Systems in the opportunitiy's service territory and utility. Order this query by Available Capacity to place the system with the most available capacity on top.
//Add the ids of all records queried to the sssList. These are now ordered in descending order of available capacity.
//Add the Capacity Available of all records queried to the availableCapList. These are now ordered in descending order of available capacity.
//Add the Reserved Capacity of all records queried to the reservedCapList. These are now ordered in descending order of available capacity.
      
for ( Opportunity l2 : trigger.new) {

    if (trigger.isInsert || trigger.isUpdate){
            
        if(sssList.size() == 0){
               
            l2.shared_solar_system__c = null;
            l2.waitlist__c = FALSE;}
            
//If the sssList does not hold a value, or there are no Shared Solar Systems with available capacity, set the Shared Solar System relationship on the opportunity to null and set the waitlist to TRUE.
//Waitlist is currently set to FALSE as we are still in the developmental phase.           
             
        else{
         
               l2.shared_solar_system__c = sssList.get(0);
               l2.Reserved_System_Capacity_kW_DC2__c= reservedCapList.get(0);
               l2.Available_System_Capacity_kW_DC__c = availableCapList.get(0);}}
               
//If sssList does hold a value, set the fields above to the first tuple of their respecitve lists.
//Because the lists are ordered by available capacity, the first tuple will automatically be the Shared Solar System with the most available capacity.               

        else {

            l2.shared_solar_system__c = null;}}}
            
//If the opportunity is not inserted/updated set the shared solar system to null.            

  if(l.project_assignment__c == 'Manual' && l.product_line__c == 'Community Solar'){
  
//If the System Assignment is set to Manual, the user then has the ability to select the Shared Solar System from the System List Picklist. This turns off the automatic assignment code.

    for ( opportunity l3 : trigger.new) {
    
        If ( trigger.isUpdate || trigger.isInsert) {
    
            systemListValues.add (l3.shared_solar_system_picklist__c);}}                       

    if ( systemListValues.size( ) > 0 ) {
    
        map <string, shared_solar_system__c> mapSSS= new map <string, shared_solar_system__c> ( );
        
        for( shared_solar_system__c obj : [
        
            SELECT Id, name, Project_Capacity_Available_kW_DC__c, Reserved_Capacity_kW_DC__c    
            FROM shared_solar_system__c 
            WHERE name 
            IN : systemListValues ]){

                mapSSS.put (obj.name, obj);}
            
//If the opportunity is updated or inserted add the value selected in the System List Picklist to the systemListValues list.
//If the serviceTerritories List holds a value continue.
//Instantiate the mapSSS map for the Shared Solar System.
//Query Shared Solar Systems for records in which name is in the systemValuesList.
//Put the queried result record into the mapSSS and set the key value to the Shared Solar System's name.
             
    for ( Opportunity l4 : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate){
         
            if(mapSSS.containsKey (l4.shared_solar_system_picklist__c)){

               l4.shared_solar_system__c = mapSSS.get (l4.shared_solar_system_picklist__c).id;
               l4.Reserved_System_Capacity_kW_DC2__c= mapSSS.get (l4.shared_solar_system_picklist__c).Reserved_Capacity_kW_DC__c;
               l4.Available_System_Capacity_kW_DC__c = mapSSS.get (l4.shared_solar_system_picklist__c).Project_Capacity_Available_kW_DC__c;
               l4.waitlist__c = FALSE;}}

//If the opportunity is updated or inserted continue.
//If the mapSSS list contains the the name of the value chosen in the System List within its key continue.
//Set the fields above of on the oppotunity to the resepective values found in the query.

        else {

            l.shared_solar_system__c = null;}}}}}
*/return;}
  
//If the opportunity is not inserted or updated set the Shared Solar System realtionship field to null.