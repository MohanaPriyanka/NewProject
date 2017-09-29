Trigger mapPCR on Lead (before insert, before update) {

  /*  set <string> leadIDs = new Set <string>( ); 

    for ( Lead l : trigger.new) {
    
        If ( trigger.isInsert || trigger.isUpdate) {
            leadIDs.add (l.lead_ID__c);}
    }

    if ( leadIDs.size( ) > 0 ) {
    
        map <string, LASERCA__Personal_Credit_Report__c> mapFICO = new map <string, LASERCA__Personal_Credit_Report__c> ( );
        
        for (LASERCA__Personal_Credit_Report__c obj : [SELECT Id, name, approval_status__c, PCR_Lead_ID__c,     
        Maximum_Disbursement_Monthly__c  FROM LASERCA__Personal_Credit_Report__c WHERE PCR_Lead_ID__c IN : leadIDs AND LASERCA__Contact__c=NULL] ) {

            mapFICO.put (obj.PCR_Lead_ID__c, obj); 
        }        

    for ( Lead l : trigger.new) {
    

        if ( trigger.isInsert || trigger.isUpdate || trigger.oldMap.get(l.Id). lead_ID__c != l.lead_ID__C){
         
            if(mapFICO.containsKey (l.lead_ID__c)){

                l.Personal_credit_report__c = mapFICO.get (l.lead_ID__c).id;
                l.Maximum_monthly_Disbursement__c = mapFICO.get (l.lead_ID__c).Maximum_Disbursement_Monthly__c;
            
            }
        }

        else if(trigger.oldMap.get(l.iD).lead_ID__c != l.lead_ID__c && !mapFICO.containsKey(l.lead_ID__c)) {

            l.Personal_credit_report__c = null;
    }
}
} 

*/
}