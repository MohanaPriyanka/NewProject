@isTest
private class testReferralCode {

Static testMethod void contactReferralCode(){

Account parentAccount= new Account(name = 'Test');
insert parentAccount;

Account myAccount = new Account(name = 'Test Account', parent_account__c = parentAccount.id);
insert myAccount;

contact myContact = new Contact(firstname = 'Cole', lastName = 'Swain', email = 'cswain@bluewave-capital.com', account = parentAccount);
insert myContact;

Date myDate = Date.newInstance(2015, 2, 17);

Opportunity newOpportunity = new Opportunity(name = 'Cole Swain', product_line__c = 'Community Solar', account = myAccount, type = 'New Business', stageName = 'Complete', closeDate = myDate, email__c = 'cswain@bluewave-capital.com' ); 

test.startTest();

insert newOpportunity;

test.stopTest();
 
}
}