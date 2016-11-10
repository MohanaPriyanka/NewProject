@isTest
private class mapDocuSignRSTestClass {

Static testMethod void mapDocuSignRSTest(){

account newAccount = new Account(name = 'Testcase');
insert newAccount;

Date myDate = Date.newInstance(2015, 2, 17);

opportunity newOp = new opportunity(name ='Cole Swain', email__c ='cswain@bluewave-capital.com', account = newAccount, stageName = 'new', type = 'New Business', closeDate = myDate ) ;

dsfs__DocuSign_Status__c newDocStat = new dsfs__DocuSign_Status__c ();

insert newDocStat;

dsfs__DocuSign_Recipient_Status__c newDRS = new dsfs__DocuSign_Recipient_Status__c ( name = 'TestCase', dsfs__Parent_Status_Record__c = newDocStat.id, dsfs__DocuSign_Recipient_Id__c = 'D50030', dsfs__DocuSign_Recipient_Email__c = 'cswain@bluewave-capital.com');

Insert newDRS;

test.startTest();
 
insert newOp;
 
test.stopTest();
 
opportunity oppQuery = [SELECT DocuSign_Recipient__c FROM opportunity WHERE name = 'Cole Swain'];
dsfs__DocuSign_Recipient_Status__c DRSquery = [SELECT id FROM dsfs__DocuSign_Recipient_Status__c WHERE name = 'TestCase'];
 
system.assertEquals(DRSquery.id, oppQuery.DocuSign_Recipient__c);
 
 
}
}