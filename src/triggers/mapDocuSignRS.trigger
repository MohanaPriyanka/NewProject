Trigger mapDocuSignRS on Opportunity (before insert, before update) {

    set <string> oppIds = new Set <string>( ); 

    for ( opportunity l : trigger.new) {
    
        If ( l.email__c != null) {
    
            oppIds.add (l.email__c);}
    }

    if ( oppIds.size( ) > 0 ) {
    
        map <string, dsfs__DocuSign_Recipient_Status__c > mapDocRS = new map <string, dsfs__DocuSign_Recipient_Status__c > ( );
        
        for (dsfs__DocuSign_Recipient_Status__c obj : [SELECT Id, name, dsfs__Parent_Status_Record__c   , dsfs__Recipient_Status__c, dsfs__DocuSign_Recipient_Email__c  FROM dsfs__DocuSign_Recipient_Status__c WHERE dsfs__DocuSign_Recipient_Email__c IN : oppIds] ) {

            mapDocRS.put (obj.dsfs__DocuSign_Recipient_Email__c, obj); 
        }

    for ( Opportunity l : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate || trigger.oldMap.get(l.Id). email__c != l.email__C){
         
            if(mapDocRS.containsKey (l.email__c)){

               l.DocuSign_Recipient__c = mapDocRS.get (l.email__c).id;
            
            }
        }

        else if(trigger.oldMap.get(l.iD).email__c != l.email__c && !mapDocRS.containsKey(l.email__c)) {

            l.DocuSign_Recipient__c = null;
    }
}
}
}