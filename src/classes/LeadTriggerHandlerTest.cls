@isTest
private class LeadTriggerHandlerTest {
    
    @isTest static void customerSubscriptionProcessTest() {

        Utility_NMC_Tariff__c nmcRate =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                                                    Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                                                                                                    Sizing_Rate__c = true,
                                                                                                                    Date__c = Date.today()));
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
                              Family = 'Community Solar',
                              Product_Type__c = 'Community Solar',
                              State__c = 'MA',
                              ProductCode = 'CS - BlueWave - 10%',
                              IsActive = True,
                              Lender_of_Record__c = 'BlueWave',
                              NMC_Discount__c = 10,
                              Annual_kWh_Maximum__c = 100000000,
                              NM_Rate_Floor__c = 0,
                              Monthly_Late_Fee__c = 1);
        insert csProduct;

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                                Service_Territories__c = 'WCMA; SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'National Grid',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = nmcRate.Id,
                                                                                                                                Product__c = csProduct.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,  
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

        
        sss1.Sales_Partners__c = 'Barbara Cerullo; Boston Solar'; 
        insert sss1;
        
        Partner__c Partner = new Partner__c(Name = 'Boston Solar');
        insert Partner;
        
        BSST__c newSalesTeam = new BSST__c (Name = 'Partner',
                                            Partner__c = Partner.Id,
                                            Custom_ID__c = 'partner');
                                            
        insert newSalesTeam;
        
        Lead lead = (Lead)TestFactory.createSObject(new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Electricity_Provider__c = 'National Grid',
                                                             Utility_1__c = 'National Grid',
                                                             Load_Zone__c = 'WCMA',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Product_Line__c = 'Community Solar',
                                                             Product__c = csProduct.Id,
                                                             Custom_ID__c = 'partner',
                                                             System_Assignment__c = 'Automatic - Assignment Order'));
        insert lead;
        
        Lead lead2 = new Lead (LastName = 'Jordan',
                                     FirstName = 'Pentaleri',
                                     Email = 'test@email.com',
                                     Electricity_Provider__c = 'National Grid',
                                     Utility_1__c = 'National Grid',
                                     Load_Zone__c = 'WCMA',
                                     Company = 'Cloud Jedi',
                                     Status = 'Qualified',
                                     Product_Line__c = 'Community Solar',
                                     Product__c = csProduct.Id,
                                     System_Assignment__c = 'Automatic - Assignment Order');
        insert lead2;

        LASERCA__Personal_Credit_Report__c pcr = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'), true);
                                                                                        
        LASERCA__Personal_Credit_Report__c pcr2 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = lead2.Id,
                                                                                       LASERCA__Credit_Score_TransUnion__c = '700'), true);
        lead.Personal_Credit_Report__c = pcr.Id;
        lead2.Personal_Credit_Report__c = pcr2.Id;
        lead.Status = 'Qualified';
        lead2.Status = 'Qualified';
        update lead;



        Utility_Account_Log__c ual = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Lead__c = lead.Id,
                                                                                                                  Annual_Cost_of_Electricity__c = 10000,
                                                                                                                  Name_on_Account__c = 'Joey Chan'));
        insert ual;
        
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(Lead__c = lead2.Id,
                                                                 Annual_Cost_of_Electricity__c = 10000,
                                                                 Name_on_Account__c = 'Joey Chan');
        insert ual2;


        Test.startTest();
        Database.leadConvert lc = new Database.leadConvert();
        lc.setLeadId(lead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Database.leadConvert ld = new Database.leadConvert();
        ld.setLeadId(lead2.id);
        LeadStatus convertStatus2 = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        ld.setConvertedStatus(convertStatus2.MasterLabel);
        ld.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult ldr = Database.convertLead(ld);
       
        List<Opportunity> oppList = [Select Id, Name, AccountId, Shared_Solar_System__c, Shared_Solar_System__r.Name From Opportunity ];

        System.assertEquals(1, oppList.size());
        Test.stopTest();
    } 

    @isTest static void testCaseandContactConversion() {
        Map<Id,Id> leadContactIdMap = new Map<Id,Id>();
        Map<Id,Id> leadAccountIdMap = new Map<Id,Id>();
        List<Id> accountIdList = new List<Id>();

        Account accountA = new Account (Name = 'Parent AccountA') ;

        insert accountA;

        Contact contactA = new Contact (FirstName = 'ParentA',
                                        LastName = 'Last',
                                        AccountId = accountA.Id,
                                        Email = 'jpentaleri@bluewavesolar.com');
        insert contactA;

        Lead leadOne = new Lead (   FirstName = 'leadOne',
                                    LastName = 'Test',
                                    Company = 'CompanyCo',
                                    Email = 'EmailOne@bluewavesolar.com',
                                    Parent_Account__c = accountA.Id,
                                    Product_Line__c = 'Community Solar',
                                    Contacted__c = true,
                                    Status = 'Qualified');

        // NOT COMMUNITY SOLAR, DO NOT DELETE CONTACT
        Lead leadTwo = new Lead (   FirstName = 'leadTwo',
                                    LastName = 'Test',
                                    Company = 'CompanyOther',
                                    Email = 'EmailTwo@bluewavesolar.com',
                                    Contacted__c = true,
                                    Status = 'Qualified');
        List<Lead> leadList = new List<Lead>{leadOne, leadTwo};
        insert leadList;

        leadOne.Status = 'Qualified';
        leadTwo.Status = 'Qualified';
        update leadList;

        Case caseOne = new Case (
            Subject = 'Test Case One', 
            Lead_Lookup__c = leadOne.Id);

        Case caseTwo = new Case (
            Subject = 'Test Case Two',
            Lead_Lookup__c = leadTwo.id);

        Case caseThree = new Case (
            Subject = 'Test Case Three' );

        insert new List<Case>{caseOne, caseTwo, caseThree}; 
        Test.startTest();    

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=true LIMIT 1];

        for (Lead l : leadList){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc, false);
            System.assert(lcr.isSuccess());
        }   

        Test.stopTest();

        for (Lead convertedLead : [SELECT Id, ConvertedAccountId, ConvertedContactId, isConverted
                                    FROM Lead] ) {
            leadContactIdMap.put(convertedLead.Id, convertedLead.ConvertedContactId);
            leadAccountIdMap.put(convertedLead.Id, convertedLead.ConvertedAccountId);
        }        

        Boolean accountInserted = false;
        for (Account relatedAccount : [SELECT Id, Name, Send_Bills_Contact__c
                                        FROM Account]){
            if (relatedAccount.Name == 'CompanyCo'){
                System.assertEquals(contactA.Id, relatedAccount.Send_Bills_Contact__c);
                accountInserted = true;
            } else {
                System.assertEquals(null, relatedAccount.Send_Bills_Contact__c);
            }
        }
        System.assertEquals(accountInserted, true);

        List<Contact> relatedContacts = [SELECT Id, FirstName, AccountId
                                        FROM Contact
                                        ORDER BY FirstName];
        System.assertEquals(2, relatedContacts.size());
        System.assertEquals(accountA.Id, relatedContacts[1].AccountId);
        System.assertNotEquals(accountA.Id, relatedContacts[0].AccountId);

        List<Case> casesList =  [SELECT Id, Lead_Lookup__r.ConvertedAccountId, Lead_Lookup__r.ConvertedContactId, 
                                    Lead_Lookup__r.isConverted, AccountId, ContactId
                                FROM Case
                                WHERE Lead_Lookup__r.isConverted = true];
        System.assertEquals(casesList[0].AccountId, leadAccountIdMap.get(casesList[0].Lead_Lookup__c));
        System.assertEquals(casesList[1].ContactId, leadContactIdMap.get(casesList[1].Lead_Lookup__c));

        // OpportunityTriggerHandler should set Lead lookup
        List<Opportunity> opps = [SELECT Id, Lead_ID__c, Lead__c FROM Opportunity];
        System.assertEquals(leadList.size(), opps.size());
        for (Opportunity opp : opps) {
            System.assertEquals(opp.Lead_ID__c, opp.Lead__c);
        }
    }

    @IsTest static void testLeadUpdateAfterConversion() {
        LoanTestRecordWarehouse.partnerSetup();
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Company = 'Testtest',
            Loan_Amount__c = 30000,
            Requested_Loan_Amount__c = 30000,
            Email = 'test@test.com',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA'
        ));
        leads.add(new Lead(
            FirstName = 'Tester',
            LastName = 'Testcase',
            Company = 'Testtest',
            Loan_Amount__c = 30000,
            Requested_Loan_Amount__c = 30000,
            Email = 'tester@test.com',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA'
        ));
        insert leads;
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead l :leads){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Interested');
            leadConverts.add(lc);
        }
        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        Set<Id> oppIds = new Set<Id>();
        for (Database.LeadConvertResult lcr : lcrs)  {
            System.assert(lcr.isSuccess());
            oppIds.add(lcr.getOpportunityId());
        }

        Account coApplicantAccount = new Account( Name = 'CoapplicantAccount');
        insert coApplicantAccount;

        Contact coApplicantContact = new Contact(
            FirstName = 'Cole',
            LastName = 'Swain',
            AccountId = coApplicantAccount.Id,
            Lead__c = leads[0].Id,
            Income__c = 2000,
            LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;
        leads[0].Co_Applicant_First_Name__c = coApplicantContact.FirstName;
        leads[0].Co_Applicant_Last_Name__c = coApplicantContact.LastName;
        leads[0].Co_Applicant_Income__c = coApplicantContact.Income__c;
        leads[0].LASERCA__Co_Applicant_Social_Security_Number__c = coApplicantContact.LASERCA__Social_Security_Number__c;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '710',
            LASERCA__Lead__c = leads[1].Id);
        leads[1].System_Cost__c = 32000;

        update leads;
        Map<Id, Lead> leadMap = new Map<Id, Lead>(leads);

        List<Opportunity> opps = [
            SELECT Id, Personal_Credit_Report2__c, Loan_Principle__c,
                Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Income__c,
                Co_Applicant_Social_Security__c, Lead__c
            FROM Opportunity
            WHERE Id = :oppIds];
        for (Opportunity opp : opps) {
            System.assertEquals(leadMap.get(opp.Lead__c).Personal_Credit_Report__c, opp.Personal_Credit_Report2__c);
            System.assertEquals(leadMap.get(opp.Lead__c).System_Cost__c, opp.Loan_Principle__c);
            System.assertEquals(leadMap.get(opp.Lead__c).Co_Applicant_First_Name__c, opp.Co_Applicant_First_Name__c);
            System.assertEquals(leadMap.get(opp.Lead__c).Co_Applicant_Last_Name__c, opp.Co_Applicant_Last_Name__c);
        }
    }
}