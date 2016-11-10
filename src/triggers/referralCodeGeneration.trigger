trigger referralCodeGeneration on Contact (before insert) {

string referralCode;
list <string> referralList = new list <string>();
integer i = 0;

 for ( contact c : trigger.new) {
    
        If ( trigger.isInsert ) {
                    
        referralCode = 'bluewave' + c.firstName.left(1) + c.lastName;
        
string firstNameLetter = c.firstName.left(1);
        
        for(Aggregateresult obj : [SELECT count(custom_id__c)cntID FROM contact WHERE First_Letter_First_Name__c = : firstNameLetter AND lastName = : c.lastName]){
        
            If(integer.valueOf(obj.get('cntID')) < 1){
            
                c.custom_id__c = referralCode;}
                
            else{
                           
                referralCode = referralCode + obj.get('cntID');
                
                c.custom_id__c = referralCode;}}}}    
       

}