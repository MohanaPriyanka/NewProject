Trigger mapDebtToIncome on Lead (before insert, before update) {

    /*set <string> leadIDs = new Set <string>( ); 

    for ( Lead l : trigger.new) {
    
        If ( l.Annual_income_currency__c != null) {
    
            leadIDs.add (l.lead_ID__c);}
    }

    if ( leadIDs.size( ) > 0 ) {
    
        map <string, LASERCA__Personal_Credit_Report__c> mapFICO = new map <string, LASERCA__Personal_Credit_Report__c> ( );
        
        for (LASERCA__Personal_Credit_Report__c obj : [SELECT Id, name, approval_status__c, PCR_Lead_ID__c  FROM LASERCA__Personal_Credit_Report__c WHERE PCR_Lead_ID__c IN : leadIDs] ) {

            mapFICO.put (obj.PCR_Lead_ID__c, obj); 
        }

    for ( Lead l : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate || trigger.oldMap.get(l.Id). lead_ID__c != l.lead_ID__C){
         
            if(mapFICO.containsKey (l.lead_ID__c)){

                l.debt_income_status__c = mapFICO.get (l.lead_ID__c).Approval_Status__c;
            
            }
        }

        else if(trigger.oldMap.get(l.iD).lead_ID__c != l.lead_ID__c && !mapFICO.containsKey(l.lead_ID__c)) {

            l.debt_income_status__c = null;
    }
}
}*/
}