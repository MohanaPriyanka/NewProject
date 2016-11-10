Trigger addReservedCapacity on opportunity (after insert, after update) {
if(helperclass.bool != false){

set <string> projectNames = new Set <string>( ); 
set<id> opId = new set<id>();
List <opportunity> projectAllocations = new List <opportunity>( );
decimal reservedCapacity = 0;
integer i = 0;
string totalsum;

for (opportunity opportunity: trigger.new) {

    If (opportunity.assigned_cs_project__c != null) {
        projectNames.add (opportunity.assigned_cs_project__c);
    }
}

for(opportunity op : [select id,cs_reserved_capacity__c ,cs_capacity_allocated__c, assigned_cs_project__c from opportunity where assigned_cs_project__c IN :projectNames])
{
    opId.add(op.id);
}

for(Aggregateresult ag : [select SUM(cs_capacity_allocated__c)sn from opportunity where id IN: opId]){
          totalsum = string.valueOf(ag.get('sn'));
}

for(opportunity o : [SELECT id,cs_reserved_capacity__c ,cs_capacity_allocated__c, assigned_cs_project__c FROM opportunity WHERE assigned_cs_project__c  IN :projectNames]){
    
    o.cs_reserved_capacity__c  = totalsum;
    projectAllocations.add(o);
}

if(projectAllocations != null){
    
    helperclass.bool = false; 
    update projectAllocations;
}
}
}