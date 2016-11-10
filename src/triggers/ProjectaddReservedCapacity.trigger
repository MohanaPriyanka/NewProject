Trigger ProjectaddReservedCapacity on MPM4_BASE__Milestone1_Project__c (after insert, after update) {
if(helperclass.bool != false){

set <string> projectNames = new Set <string>( ); 
set<id> opId = new set<id>();
List <MPM4_BASE__Milestone1_Project__c > projectAllocations = new List <MPM4_BASE__Milestone1_Project__c >( );
decimal reservedCapacity = 0;
integer i = 0;
string totalsum;

for (MPM4_BASE__Milestone1_Project__c project: trigger.new) {

    If (project.name != null) {
        projectNames.add (project.id);
    }
}

for(opportunity op : [select id,cs_reserved_capacity__c ,cs_capacity_allocated__c, assigned_cs_project__c from opportunity where assigned_cs_project__c IN :projectNames])
{
    opId.add(op.id);
}

for(Aggregateresult ag : [select SUM(cs_capacity_allocated__c)sn from opportunity where id IN: opId]){
          totalsum = string.valueOf(ag.get('sn'));
}

for(MPM4_BASE__Milestone1_Project__c p : [SELECT id,cs_reserved_capacity__c FROM MPM4_BASE__Milestone1_Project__c WHERE id  IN :projectNames]){
    
    p.cs_reserved_capacity__c  = totalsum;
    projectAllocations.add(p);
}

if(projectAllocations != null){
    
    helperclass.bool = false; 
    update projectAllocations;
}
}
}