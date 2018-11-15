@isTest
private class ReferralCodeHandlerTest {

    static testMethod void referralCodeMap() {
        Integer j;
        List<Lead> newLeadList = new List<Lead>();
        List<Lead> updatedLeads = new List<Lead>();

        Account newAccount = new Account(Name = 'Cole Swain');
        insert newAccount;

        Contact newContact = new Contact (FirstName = 'Unique', LastName = 'Lastunique', Account = newAccount,
                                          MailingPostalCode = '02052', Email = 'cole.swain@yahoo.com');
        insert newContact;

        Partner__c newPartner = new Partner__c(Name = 'Partner');
        insert newPartner;

        Bsst__c newBSST = new BSST__c (Name ='PartnerOne', Partner__c = newPartner.id,
                                       Email__c = 'jpentaleri@bluewave-capital.com', Custom_Id__c = 'Partner1');
        insert newBSST;

        Partner__c newPartnerPlaceholder = new Partner__c(Name = 'Holder');
        insert newPartnerPlaceholder;

        Bsst__c newBSST2 = new BSST__c ( Name ='Holder', Partner__c = newPartnerPlaceholder.Id,
                                         Email__c = 'holder@bluewave-capital.com', Custom_Id__c = 'holder');
        insert newBSST2;

        Bsst__c newBSST3 = new BSST__c (Name ='Cole', Partner__c = newPartner.id,
                                        Email__c = 'cole@bluewave-capital.com', Custom_Id__c = 'cole');
        insert newBSST3;

        Load_U__c newLZU = new Load_U__c ( Name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA',
                                           Utility__C = 'Eversource', Town__c= 'Medfield');
        insert newLZU;

        Lead newCommunitySolarLead = new Lead(FirstName = 'Cole1', LastName = 'Swain', Company = 'BlueWave',
                                              Product_Line__c = 'Community Solar', Status = 'contacted',
                                              Custom_Id__c = 'Partner1', Parcel_zip__c = '02052') ;
        newLeadList.add(newCommunitySolarLead);

        Lead newLoanLead = new Lead(FirstName = 'Cole2', LastName = 'Swain', Company = 'BlueWave',
                                    Product_Line__c = 'Community Solar', Status = 'contacted',
                                    Custom_Id__c = ((String) newBSST3.Id).left(15), Parcel_zip__c = '02052') ;
        newLeadList.add(newLoanLead);

        Lead newLoanLead2 = new Lead(FirstName = 'Matthew', LastName = 'Swain', Company = 'BlueWave',
                                     Product_Line__c = 'Community Solar', Status = 'contacted',
                                     Custom_Id__c = null, Parcel_zip__c = '02052') ;
        newLeadList.add(newLoanLead2);

        Test.startTest();

        insert newLeadList;

        List <Lead> updatedLeadList = [SELECT Id, Referral_Email__c, Partner_Email__c, FirstName, LastName
                                       FROM Lead];
        for (Lead leadRecord : updatedLeadList) {
            if (leadRecord.FirstName == 'Cole1') {
                System.assertEquals('jpentaleri@bluewave-capital.com', leadRecord.Partner_email__c);
            } else if (leadRecord.FirstName == 'Cole2') {
                System.assertEquals('cole@bluewave-capital.com', leadRecord.Partner_email__c);
            } else if (leadRecord.FirstName == 'Matthew') {
                System.assertEquals('holder@bluewave-capital.com', leadRecord.Partner_email__c);
            }
        }

        newCommunitySolarLead.Custom_Id__c = 'cole';
        updatedLeads.add(newCommunitySolarLead);

        newLoanLead2.Custom_Id__c = 'Partner1';
        updatedLeads.add(newLoanLead2);

        update updatedLeads;

        updatedLeadList = [SELECT Id, Referral_Email__c, Partner_Email__c, FirstName, LastName
                           FROM Lead];
        for (Lead leadRecord : updatedLeadList) {
            if (leadRecord.FirstName == 'Cole1') {
                System.assertEquals('cole@bluewave-capital.com', leadRecord.Partner_email__c);
            } else if (leadRecord.FirstName == 'Cole2') {
                System.assertEquals('cole@bluewave-capital.com', leadRecord.Partner_email__c);
            } else if (leadRecord.FirstName == 'Matthew') {
                System.assertEquals('jpentaleri@bluewave-capital.com', leadRecord.Partner_email__c);
            }
        }
        Test.stopTest();
    }
}