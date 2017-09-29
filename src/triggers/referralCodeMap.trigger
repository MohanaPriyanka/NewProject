Trigger referralCodeMap on Lead (before insert, before update) {

set <string> customIds = new Set <string>( ); 

//instantiate the variables.

for ( lead l : trigger.new) {
    
    If ( l.custom_id__C != null) {
        
        customIds.add (l.custom_id__C);}}
        
//If the custom ID field holds a value continue.
//Add the lead's custom ID to the to the customIDs to the customId set.      
            
    if ( customIds.size( ) > 0 ) {
    
       map <string, contact> contactReferralMap = new map <string, contact> ( );
       
       try{
             
       FOR(contact obj : [
        
            SELECT id, referral_code__c, email 
            FROM contact
            WHERE referral_code__c
            IN : customIds]){

        contactReferralMap.put (obj.referral_code__c, obj);}}
        
        Catch(System.queryException e){
        
            return;}
        
//If the customerId set holds a value continue.
//Instantiate the salesIdMap, which holds the sales team object.
//Querty the sales team for the record that holds the custom ID in the lead.   
//Put the queried record into the salesIdMap and set the customer ID as the key.      
       
for ( lead l : trigger.new) {

    if ( trigger.isInsert || trigger.isUpdate) {
        
        try{
            
            l.customer_referral__c = contactReferralMap.get (l.custom_id__C).id;
            l.referral_email__c = contactReferralMap.get(l.custom_id__c).email;}

        Catch(System.NullPointerException e){
        
            return;}
            
//try to set the Sales Rep Relationship to the tuple's ID within the map found with the custom ID key. Also set the partner's email to the tuple's email.
//If there is a system null pointer exception end the code.           
        
            l.customer_referral__c = contactReferralMap.get (l.custom_id__C).id;
            l.referral_email__c = contactReferralMap.get(l.custom_id__c).email;}
        
//If the Try works, set the fields to the instructed values above.        

        else {
       
            l.customer_referral__c = null;
            l.referral_email__c = null;}}}}

//If the lead is not inserted/updated set the fields to null.