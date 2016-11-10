@isTest
private class referralCodeMapTestClass{

Static testMethod void referralCodeMap(){

account newAccount = new account(name = 'Cole Swain');
insert newAccount;

contact newContact = new contact ( firstName = 'Cole', lastName = 'Swain', account = newAccount, mailingPostalCode = '02052', email = 'cole.swain@yahoo.com');
Insert newContact;

string stringID = newContact.id;
string mailingPostalCodes = newContact.MailingPostalCode;

string referralCode = stringID.left(1) + 'BW' + stringID.right(2) + mailingPostalCodes.right(1);

Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__C = 'Eversource', town__c= 'Medfield');
insert newLZU;

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', custom_id__c = '02052', parcel_zip__c = '02052') ;

partner__c newPartner = new partner__c(name = 'Partner');
insert newPartner;

test.startTest();
 
insert newLead;
 
test.stopTest();
 
}
}