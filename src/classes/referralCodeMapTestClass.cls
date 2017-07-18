@isTest
private class referralCodeMapTestClass{

Static testMethod void referralCodeMap(){
    Integer j;
    List<Lead> newLeadList = new List<Lead>();
    List<Lead> updatedLeads = new List<Lead>();

    Account newAccount = new Account(Name = 'Cole Swain');
    Insert newAccount;

    Contact newContact = new Contact (FirstName = 'Unique', LastName = 'Lastunique', Account = newAccount, MailingPostalCode = '02052', Email = 'cole.swain@yahoo.com');
    Insert newContact;

    Partner__c newPartner = new Partner__c(Name = 'Partner');
    Insert newPartner;

    Bsst__c newBSST = new BSST__c (Name ='PartnerOne', Partner__c = newPartner.id, Email__c = 'jpentaleri@bluewave-capital.com', Custom_Id__c = 'Partner1');
    Insert newBSST;

    Partner__c newPartnerPlaceholde = new Partner__c(Name = 'Holder');
    Insert newPartnerPlaceholde ;

    Bsst__c newBSST2 = new BSST__c ( Name ='Holder', Partner__c = newPartnerPlaceholde.Id, Email__c = 'holder@bluewave-capital.com', Custom_Id__c = 'holder');
    Insert newBSST2;

    Bsst__c newBSST3 = new BSST__c (Name ='Cole', Partner__c = newPartner.id, Email__c = 'jpentaleri@bluewave-capital.com', Custom_Id__c = 'cole');
    Insert newBSST3;

    Load_U__c newLZU = new Load_U__c ( Name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__C = 'Eversource', Town__c= 'Medfield');
    Insert newLZU;

    Lead newCommunitySolarLead = new lead(FirstName = 'Cole', LastName = 'Swain', Company = 'BlueWave', Product_Line__c = 'Community Solar', Status = 'contacted', Custom_Id__c = 'bluewaveULastunique', Parcel_zip__c = '02052') ;
    newLeadList.add(newCommunitySolarLead);

    Lead newLoanLead = new lead(FirstName = 'Cole', LastName = 'Swain', Company = 'BlueWave', Product_Line__c = 'Residential Loan', Status = 'contacted', Custom_Id__c = null, Parcel_zip__c = '02052') ;
    newLeadList.add(newLoanLead);

    Lead newLoanLead2 = new lead(FirstName = 'Matthew', LastName = 'Swain', Company = 'BlueWave', Product_Line__c = 'Residential Loan', Product_Line__c = 'Community Solar', Status = 'contacted', Custom_Id__c = 'swain', Parcel_zip__c = '02052') ;
    newLeadList.add(newLoanLead2);    

    Insert newLeadList;

    newCommunitySolarLead.Custom_Id__c = 'Partner1';
    updatedLeads.add(newCommunitySolarLead);

    newLoanLead.Custom_Id__c = 'Partner1';
    updatedLeads.add(newLoanLead);

    Update updatedLeads;

    Test.startTest();
        List <Lead> updatedLeadList = [ SELECT Id, Referral_Email__c, Partner_Email__c, FirstName, LastName
                                    FROM Lead
                                    WHERE LastName = 'Swain'];
        for(Lead leadRecord : updatedLeadList){
            if (leadRecord.FirstName == 'Cole') {
                System.assert(leadRecord.Partner_email__c == 'jpentaleri@bluewave-capital.com');                
            } else {
                System.assert(leadRecord.Partner_email__c == null);
            }
        }                                        
    Test.stopTest();
    }
}