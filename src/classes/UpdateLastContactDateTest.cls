@isTest
private class UpdateLastContactDateTest{

Static testMethod void UpdateLastContactDatetestmethod(){

integer j;

List <Profile> userProfile = new List <Profile>([SELECT Id FROM profile WHERE name='System Administrator' ]);

user newuser = new user(lastname = 'Jordan P',          
                        profileid = userProfile.get(0).id,
                        email = 'jpentaleri@bluewave-capital.com',
                        username = 'helloname@gmail.com',
                        languagelocalekey = 'en_US',
                        localesidkey = 'en_US',
                        timezonesidkey = 'America/New_York',
                        emailencodingkey = 'UTF-8',
                        alias = 'jpent'
                        );
insert newuser;

account newAccount = new account(name = 'Jordan Pentaleri');
insert newAccount;

contact newContact = new contact (  firstName = 'Jordan ', 
                                    lastName = 'Contact', 
                                    account = newAccount, 
                                    email = 'jordan@yahoo.com');
Insert newContact;

task newtaskone = new task (subject='test', 
                        ActivityDate=Date.Today(),
                        Status='Completed',
                        Priority='Normal',
                        //Owner = newuser,
                        WhoId = newContact.Id,
                        WhatID = newAccount.Id
                        );
insert newtaskone;

task newtask = new task (subject='test', 
                        ActivityDate=Date.Today(),
                        Status='New',
                        Priority='Normal',
                        //Owner = newuser,
                        WhoId = newContact.Id,
                        WhatID = newAccount.Id
                        );
insert newtask;
newtask.Status = 'Completed';
update newtask;

test.startTest();

List <Account> updatedaccount = [   SELECT id, Last_Contact_Date__c
                                    FROM Account
                                    WHERE name = 'Jordan Pentaleri'];

for(j = 0; j < updatedaccount.size(); j++){
system.debug(updatedaccount.get(j).Last_Contact_Date__c);
system.assert(updatedaccount.get(j).Last_Contact_Date__c != null);
}

test.stopTest();
 
}
}