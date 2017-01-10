@isTest
private class referralCodeMapTestClass{

Static testMethod void referralCodeMap(){

integer j;
account newAccount = new account(name = 'Cole Swain');
insert newAccount;

contact newContact = new contact (  firstName = 'Unique', 
                                    lastName = 'Lastunique', 
                                    account = newAccount, 
                                    mailingPostalCode = '02052', 
                                    email = 'cole.swain@yahoo.com');
Insert newContact;

partner__c newPartner = new partner__c(name = 'Partner');
insert newPartner;

bsst__c newBSST = new BSST__c ( name ='PartnerOne', 
                                partner__c = newPartner.id,
                                email__c = 'jpentaleri@bluewave-capital.com', 
                                custom_id__c = 'Partner1');
Insert newBSST;

System.debug(newContact.custom_id__c);
System.debug(newContact.Referral_Code__c);

string stringID = newContact.id;
string mailingPostalCodes = newContact.MailingPostalCode;

Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__C = 'Eversource', town__c= 'Medfield');
insert newLZU;

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', custom_id__c = 'bluewaveULastunique', parcel_zip__c = '02052') ;
insert newLead;
newLead.custom_id__c = 'Partner1';
update newLead;

test.startTest();

List <Lead> updatedlead = [ SELECT id, referral_email__c, partner_email__c, lastName
                            FROM Lead
                            WHERE lastName = 'Swain'];

for(j = 0; j < updatedlead.size(); j++){
system.debug(updatedlead.get(j).partner_email__c);
system.assert(updatedlead.get(j).partner_email__c == 'jpentaleri@bluewave-capital.com');
}

test.stopTest();
 
}
}