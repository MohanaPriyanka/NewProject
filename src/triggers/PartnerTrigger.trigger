trigger PartnerTrigger on partner__c(before Update, before Insert) {/*

set <string> partnerServiceTerritories = new set <string>();
set <string> partnerNames = new set<string>();
set <id> opId = new set <id>();
set <id> sssId = new set <id>();
set <id> leadId = new set <id>();
list<partner__c> utilityList = new List <partner__c>();
integer totalOpps;
decimal totalReservations;
integer totalCapacity;
integer totalSSS;
integer totalLeads;
integer totalSubs;
integer totalCancelledOpps;


for(partner__c partner : trigger.new) {

if(partner.service_territory__c == 'All') {
        
for(opportunity op : [SELECT id, name, CS_Capacity_Allocated__c
                      FROM opportunity WHERE service_territory__c != null AND Partner_tag_lookup__c = : partner.id]){

    opId.add(op.id);
    
    }
    
for(shared_solar_system__c sss : [SELECT id, name, service_territory__c, Total_System_Size_kWh_DC__c
                      FROM shared_solar_system__c WHERE service_territory__c != null AND partner__c INCLUDES (: partner.name) ]){

    sssId.add(sss.id);
    
    }    
            
    
for(lead l: [SELECT id
             FROM lead WHERE Partner_lookup__c = : partner.id]){

    leadId.add(l.id);
    
    }        
    
for(Aggregateresult ag0 : [SELECT COUNT(id) oppCount1
                          FROM opportunity WHERE id IN: opId ]){
                         
    totalOpps = integer.valueOf(ag0.get('oppCount1'));
     
    }   
    
for(Aggregateresult ag00 : [SELECT COUNT(id) oppCount2
                          FROM opportunity WHERE id IN: opId AND stageName = 'Cancelled']){
                         
    totalCancelledOpps = integer.valueOf(ag00.get('oppCount2'));
     
    }       
    
     
for(Aggregateresult ag : [SELECT COUNT(id) oppCount3, SUM(cs_capacity_allocated__c) reservationSum, SUM(shared_solar_system__r.Total_System_Size_kWh_DC__c) totalCapacity 
                          FROM opportunity WHERE id IN: opId AND stageName = 'Complete' AND waitlist__c = FALSE]){
                         
    totalSubs = integer.valueOf(ag.get('oppCount3'));
    totalReservations = (decimal) ag.get('reservationSum');
    
    
    }
    
for(Aggregateresult ag2 : [SELECT COUNT(id) sssCount, SUM(Total_System_Size_kWh_DC__c) totalCapacity 
                          FROM shared_solar_system__c WHERE id IN: sssId ]){
                         
    totalSSS = integer.valueOf(ag2.get('sssCount'));
    totalCapacity = integer.valueOf(ag2.get('totalCapacity'));
    
    }    
    
for(Aggregateresult ag3 : [SELECT COUNT(id) leadCount
                          FROM lead WHERE Partner_lookup__c = : partner.id]){
                         
    totalLeads = integer.valueOf(ag3.get('leadCount'));       
    }

for(partner__c partner2 : trigger.new){
    
    if ( trigger.isInsert || trigger.isUpdate)  {

            partner2.total_opportunities__c = totalSubs;
            partner2.total_capacity_kw__c = totalCapacity;
            partner2.total_reserved_capacity_kw__c = totalReservations;
            
            partner2.total_leads__c = totalLeads;
            partner2.Total_Opportunities2__c= totalOpps;
            partner2.total_cancellations__c = totalCancelledOpps;
            }
        

    else{
        
            partner2.total_opportunities__c = null;
            partner2.total_capacity_kw__c = null;
            partner2.total_reserved_capacity_kw__c = null;
            
            partner2.total_leads__c = null;
            partner2.Total_Opportunities2__c= null;
            partner2.total_cancellations__c = null;
    }

}
}





    if(partner.service_territory__c != 'All') {
    
        partnerServiceTerritories.add(partner.service_territory__c);
        partnerNames.add(partner.name);
        
        }
        
for(opportunity op2 : [SELECT id, name, CS_Capacity_Allocated__c
                      FROM opportunity WHERE Service_Territory__c IN : partnerServiceTerritories AND Partner_tag_lookup__c = : partner.id]){

    opId.add(op2.id);
    
    }
    
for(shared_solar_system__c sss : [SELECT id, name, service_territory__c, Total_System_Size_kWh_DC__c
                      FROM shared_solar_system__c WHERE service_territory__c = : partner.service_territory__c AND partner__c INCLUDES (: partner.name)  ]){

    sssId.add(sss.id);
    
    }   
    
for(lead l2: [SELECT id FROM lead WHERE Partner_lookup__c = : partner.id]){

    leadId.add(l2.id);
    
    }
    
for(Aggregateresult ag5 : [SELECT COUNT(id) oppCount4
                          FROM opportunity WHERE id IN: opId ]){
                         
    totalOpps = integer.valueOf(ag5.get('oppCount4'));
     
    }   
    
for(Aggregateresult ag6 : [SELECT COUNT(id) oppCount5
                          FROM opportunity WHERE id IN: opId AND stageName = 'Cancelled']){
                         
   totalCancelledOpps = integer.valueOf(ag6.get('oppCount5'));
     
    }              
    
for(Aggregateresult ag3 : [SELECT COUNT(id) oppCount6, SUM(cs_capacity_allocated__c) reservationSum, SUM(shared_solar_system__r.Total_System_Size_kWh_DC__c) totalCapacity 
                          FROM opportunity WHERE id IN: opId AND stageName = 'Complete' AND waitlist__c = FALSE]){
                         
    totalSubs = integer.valueOf(ag3.get('oppCount6'));
    totalReservations = (decimal)ag3.get('reservationSum');
    
    
    }
    
for(Aggregateresult ag4 : [SELECT COUNT(id) sssCount, SUM(Total_System_Size_kWh_DC__c) totalCapacity 
                          FROM shared_solar_system__c WHERE id IN: sssId]){
                         
    totalSSS = integer.valueOf(ag4.get('sssCount'));
    totalCapacity = integer.valueOf(ag4.get('totalCapacity'));
    
    }    
    
for(Aggregateresult ag5 : [SELECT COUNT(id) leadCount
                          FROM lead WHERE Partner_lookup__c = : partner.id]){
                         
    totalLeads = integer.valueOf(ag5.get('leadCount'));       
    }

for(partner__c partner3 : trigger.new){
    
    if ( trigger.isInsert || trigger.isUpdate)  {

            partner3.total_opportunities__c = totalSubs;
            partner3.total_capacity_kw__c = totalCapacity;
            partner3.total_reserved_capacity_kw__c = totalReservations;
            
            
            partner3.total_leads__c = totalLeads;
            partner3.Total_Opportunities2__c= totalOpps;
            partner3.total_cancellations__c = totalCancelledOpps;
            }
        

    else{
        
            partner3.total_opportunities__c = null;
            partner3.total_capacity_kw__c = null;
            partner3.total_reserved_capacity_kw__c = null;
           
            partner3.total_leads__c = null;
            partner3.Total_Opportunities2__c= null;
            partner3.total_cancellations__c = null;
    }

}
}*/
return;
}