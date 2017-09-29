Trigger SharedSolarSystemAddReservations on shared_solar_system__c (before insert, before update){
/*
string capacityReserved;
decimal capacityCommitted;
decimal capacityAnchored;

set<string> systemNames = new set<string>();

for(shared_solar_system__c solarSystem : trigger.new){

    if(trigger.isInsert || trigger.isUpdate){
    
        systemNames.add(solarSystem.name);}}
       
if(systemNames.size() > 0) {

  Aggregateresult capReserved = [
  
  SELECT sum(cs_capacity_allocated__c)capReservations 
  FROM opportunity 
  WHERE shared_solar_system__r.name IN : systemNames AND product_line__c = 'Community Solar' AND customer_group__c != 'Anchor' AND (stageName = 'Contract Pending' OR stageName = 'Pending BlueWave Signature' OR stageName = 'QC In Process'OR stageName = 'Pending Quality Control Signature')];
  
  Aggregateresult capCommitted = [
  
  SELECT sum(cs_capacity_allocated__c)capCommitted 
  FROM opportunity 
  WHERE stageName = 'Complete' AND product_line__c = 'Community Solar' AND shared_solar_system__r.name IN : systemNames AND customer_group__c != 'Anchor'];
  
  Aggregateresult capAnchor = [
  
  SELECT sum(cs_capacity_allocated__c)capAnchor
  FROM opportunity 
  WHERE stageName = 'Complete' AND product_line__c = 'Community Solar' AND shared_solar_system__r.name IN : systemNames AND customer_group__c = 'Anchor'];
  
  capacityReserved = string.valueOf(capReserved.get('capReservations'));
  capacityCommitted = (decimal)capCommitted.get('CapCommitted');
  capacityAnchored = (decimal)capAnchor.get('CapAnchor');}
  
  
else{
  
  return;}
  
for(shared_solar_system__c solarSystem : trigger.new){
  
      if(trigger.isInsert || trigger.isUpdate){
      
          solarSystem.reserved_capacity_kW_DC__c = capacityReserved;
          solarSystem.capacity_committed_kW_DC__c = capacityCommitted;
          solarSystem.anchor_capacity_reserved__c = capacityAnchored;}
      
      else{
      
          solarSystem.reserved_capacity_kW_DC__c = null;
          solarSystem.capacity_committed_kW_DC__c = null;
          solarSystem.anchor_capacity_reserved__c = null;}}*/
          
          return;}