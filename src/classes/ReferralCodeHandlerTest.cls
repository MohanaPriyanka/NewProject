@isTest
private class ReferralCodeHandlerTest {

    static testMethod void referralCodeMap() {
        Integer j;
        List<Lead> newLeadList = new List<Lead>();
        List<Lead> updatedLeads = new List<Lead>();

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{eversource, nationalGrid};

        Account newAccount = new Account(Name = 'Cole Swain');
        insert newAccount;

        Contact newContact = new Contact (FirstName = 'Unique', LastName = 'Lastunique', Account = newAccount,
                                          MailingPostalCode = '02052', Email = 'cole.swain@yahoo.com');
        insert newContact;

        Partner__c newPartner = new Partner__c(
            Name = 'Partner');
        insert newPartner;

        Bsst__c newBSST = new BSST__c (
            Name ='PartnerOne',
            Partner__c = newPartner.id,
            Email__c = 'jpentaleri@bluewave-capital.com',
            Custom_Id__c = 'Partner1');
        insert newBSST;

        Partner__c newPartnerPlaceholder = new Partner__c(
            Name = 'Holder',
            Email__c  ='holderpartner@test.com');
        insert newPartnerPlaceholder;

        TestFactory.setDefaultCSPartner(newPartnerPlaceholder.Id);

        Bsst__c newBSST2 = new BSST__c (
            Name ='Holder',
            Partner__c = newPartnerPlaceholder.Id,
            Email__c = 'holder@bluewave-capital.com',
            Custom_Id__c = 'holder');
        insert newBSST2;

        newPartnerPlaceholder.Default_Sales_Rep__c = newBSST2.Id;
        update newPartnerPlaceholder;

        Bsst__c newBSST3 = new BSST__c (
            Name ='Cole',
            Partner__c = newPartner.id,
            Email__c = 'cole@bluewave-capital.com',
            Custom_Id__c = 'cole');
        insert newBSST3;

        Load_U__c newLZU = new Load_U__c (
            Name = '02052',
            LZ__c = 'NEMA',
            Town__c= 'Medfield');
        insert newLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = newLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;

        //Community solar lead should be assigned using partnerId from application or Default to CS partner
        Lead csLead = new Lead(
            FirstName = 'Cole1',
            LastName = 'Swain',
            Company = 'BlueWave',
            LeadSource = 'Web',
            Product_Line__c = 'Community Solar',
            Status = 'New',
            Parcel_zip__c = '02052') ;
        newLeadList.add(csLead);

        Test.startTest();

        insert newLeadList;

        List <Lead> updatedLeadList = [SELECT Id, Referral_Email__c, Partner_Email__c, Partner_Lookup__c, FirstName, LastName
                                       FROM Lead];
        for (Lead leadRecord : updatedLeadList) {
            if (leadRecord.FirstName == 'Cole1') {
                //CS lead should get default (holder) partner
                System.assertNotEquals(null, leadRecord.Partner_Lookup__c);
                System.assertEquals('holderpartner@test.com', leadRecord.Partner_Email__c);
            }
        }

        Test.stopTest();
    }
}