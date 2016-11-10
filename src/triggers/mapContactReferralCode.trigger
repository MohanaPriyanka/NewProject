Trigger mapContactReferralCode on Opportunity (before insert, before update) {

set <string> emailList = new Set <string>( ); 
set <string> parentAccountIds = new Set <string>( ); 

//instantiate the variables.

for (Opportunity l : trigger.new) {
    
    If (l.product_line__c == 'Community Solar') {
    
        emailList.add(l.email__c);
        parentAccountIds.add(l.Parent_account_id__c);}}

    if (parentAccountIds.size( ) > 0 ) {
    
        map <string, contact> contactMap = new map <string, contact> ( );
        
        try{
        
        for(contact obj : [SELECT referral_code__c, email, name, account_id__c FROM contact WHERE account_id__c IN : parentAccountIds AND email IN : emailList]){

            contactMap.put (obj.account_id__c, obj);}}
            
         Catch(System.queryException e){
        
            return;}           
        
for ( Opportunity l : trigger.new) {

    If (l.product_line__c == 'Community Solar') {

        try{
        
        l.referral_code__c = contactMap.get(l.parent_account_id__c).referral_code__c;}
        
       Catch(System.nullpointerexception e){
        
            return;}}        
            
    else (
                
        l.referral_code__c = null);}}}