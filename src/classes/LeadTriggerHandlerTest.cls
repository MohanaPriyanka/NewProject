@isTest
public class LeadTriggerHandlerTest {
    @isTest static void customerSubscriptionProcessTest() {
        System_Properties__c sysProp = new System_Properties__c(
            Name = 'System',
            DocuSign_API_Account_ID__c = '123',
            DocuSign_Customer_Care_User__c = '123@123.com',
            DocuSign_Guest_User__c = '123@345.com',
            DocuSign_Guest_User_Credential__c = '234234',
            DocuSign_Integrator_Key__c = '123123-123123'
        );
        insert sysProp;

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Utility_NMC_Tariff__c nmcRate =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                                                    Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                                                                                                    Sizing_Rate__c = true,
                                                                                                                    Date__c = Date.today()));
        insert nmcRate;

        Product2 csProduct = new Product2(
            Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            NM_Rate_Floor__c = 0,
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
                                                                                                                                Utility__c = nationalgrid.Id,
            Credit_Score_Requirement__c = 200,
            Assignment_order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25
        );

        
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
                                                             Utility_relationship__c = nationalGrid.Id,
                                                             LoadZone__c = 'WCMA',
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
                                     Utility_relationship__c = nationalGrid.Id,
                                     LoadZone__c = 'WCMA',
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



        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = lead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Joey Chan'
        );
        insert ual;
        
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Lead__c = lead2.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Joey Chan'
        );
        insert ual2;


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

        for (Opportunity opp : [SELECT Id FROM Opportunity]){

            dsfs__DocuSign_Status__c newDocStat = new dsfs__DocuSign_Status__c(
                dsfs__Opportunity__c = opp.Id,
                dsfs__Envelope_Status__c = 'Sent',
                dsfs__DocuSign_Envelope_ID__c = 'testEnvelopeId'
            );
            insert newDocStat;

            dsfs__DocuSign_Recipient_Status__c newDRS = new dsfs__DocuSign_Recipient_Status__c(
                Name = 'TestCase',
                dsfs__Parent_Status_Record__c =newDocStat.Id,
                dsfs__DocuSign_Recipient_Id__c = 'D50030',
                dsfs__DocuSign_Recipient_Email__c = 'nobody@bluewavesolar.com',
                dsfs__Recipient_Status__c = 'Sent'
            );
            insert newDRS;
        }

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        List<Id> idList = new List<Id>();
        List<Opportunity> oppList = [SELECT Id, Name, Parent_Account_Name__c, Salesperson_Email__c,
            Sales_tag__c, Application_Type__c,
            Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c,
            Docusign_Template__c, Shared_Solar_System__r.Name,
            AccountId, Shared_Solar_System__c
        FROM Opportunity];
        System.assertEquals(1, oppList.size());
        idList.add(oppList[0].Id);

        DocuSignHelper.sendCSPackage(oppList[0],1,1);
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id, Method__c, Message__c FROM Error_Log__c];
        // We log the opps for which we're sending contracts: "Sending contracts for these opportunities..."
        System.assertEquals(1, errorLogs.size());

        Opportunity opp = [
            SELECT Id, Name, Parent_Account_Name__c, Salesperson_Email__c, Sales_tag__c, Application_Type__c,
                Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c, Docusign_Template__c,
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
        ];
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
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

    @IsTest static void testMultipleSubscriptions() {
        System_Properties__c sysProp = new System_Properties__c(
            Name = 'System',
            DocuSign_API_Account_ID__c = '123',
            DocuSign_Customer_Care_User__c = '123@123.com',
            DocuSign_Guest_User__c = '123@345.com',
            DocuSign_Guest_User_Credential__c = '234234',
            DocuSign_Integrator_Key__c = '123123-123123'
        );
        insert sysProp;

        ChargentBase__Gateway__c chGateway  =
            new ChargentBase__Gateway__c(   Name = 'Chargent Gateway',
                ChargentBase__Available_Payment_Methods__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                ChargentBase__Active__c = True);
        insert chGateway;

        Entity__c defaultEntity = new Entity__c(
            Name = 'BWC Holdings, LLC',
            Gateway__c = chGateway.Id
        );
        insert defaultEntity;

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        Shared_Solar_System__c sss1 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P1');
        Shared_Solar_System__c sss2 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P2');
        Shared_Solar_System__c sss3 = getSharedSolarSystem(nmcRate, csProduct, nationalGrid, 'National Grid P1');
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3};

        Shared_Solar_System__c sssCheck = [
            SELECT Maximum_Subscription_Cost__c, Maximum_Subscription_Capacity_kW_DC__c
            FROM Shared_Solar_System__c
            WHERE Id = :sss1.Id
        ];
        System.assertEquals(25, sssCheck.Maximum_Subscription_Capacity_kW_DC__c);
        System.assertEquals(6006, sssCheck.Maximum_Subscription_Cost__c);

        Partner__c partner = new Partner__c(Name = 'BlueWave Customer Care');
        insert partner;
        BSST__c salesTeam = new BSST__c (Name = 'Partner',
            Partner__c = partner.Id,
            Custom_ID__c = 'partner'
        );
        insert salesTeam;

        Account parentAccount = new Account(Name = 'Parent');
        insert parentAccount;

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Testcase',
            AccountId = parentAccount.Id
        );

        Lead primaryProperty = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
            Utility_relationship__c = eversource.Id,
            LoadZone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id
        );
        Lead additionalProperty = primaryProperty.clone();
        additionalProperty.Utility_relationship__c = nationalGrid.Id;
        additionalProperty.Electricity_Provider__c = 'National Grid';
        insert new List<Lead>{primaryProperty, additionalProperty};

        ChargentOrders__ChargentOrder__c newACHOrder1 = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'Check',
            ChargentOrders__Bank_Name__c = 'primary bank',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Bank_Account_Number__c = '1234567890',
            ChargentOrders__Bank_Account_Name__c = 'primary',
            ChargentOrders__Billing_Email__c = 'primary@bluewavesolar.com',
            Entity__c = defaultEntity.Id,
            ChargentOrders__Gateway__c = defaultEntity.Gateway__c,
            Lead__c = primaryProperty.Id,
            Autopay_Only__c = true
        );

        ChargentOrders__ChargentOrder__c newACHOrder2 = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Billing_Email__c = 'additional@bluewavesolar.com',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Number__c = '1234123412341234',
            ChargentOrders__Card_Expiration_Month__c = '01',
            ChargentOrders__Card_Expiration_Year__c = '12',
            ChargentOrders__Billing_Zip_Postal__c = '12345',
            ChargentOrders__Billing_First_Name__c = 'Testy',
            ChargentOrders__Billing_Last_Name__c = 'McTesterson',
            Entity__c = defaultEntity.Id,
            ChargentOrders__Gateway__c = defaultEntity.Gateway__c,
            Lead__c = additionalProperty.Id,
            Autopay_Only__c = true
        );

        insert new List<ChargentOrders__ChargentOrder__c>{newACHOrder1, newACHOrder2};

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = primaryProperty.Id,
            LASERCA__Credit_Score_TransUnion__c = '720'
        );
        insert pcr;
        primaryProperty.Personal_Credit_Report__c = pcr.Id;
        additionalProperty.Personal_Credit_Report__c = pcr.Id;
        update new List<Lead>{primaryProperty, additionalProperty};

        // kW DC = Annual Cost / NMC Rate / Yield
        Utility_Account_Log__c ual1 = new Utility_Account_Log__c(
            Lead__c = primaryProperty.Id,
            Annual_Cost_of_Electricity__c = 7207, // should result in 30 kW DC
            Name_on_Account__c = 'Primary 1'
        );
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Lead__c = primaryProperty.Id,
            Annual_Cost_of_Electricity__c = 1201, // should result in 5 kW DC
            Name_on_Account__c = 'Primary 2'
        );
        Utility_Account_Log__c ual3 = new Utility_Account_Log__c(
            Lead__c = additionalProperty.Id,
            Annual_Cost_of_Electricity__c = 7207, // should result in 30 kW DC
            Name_on_Account__c = 'Additional 1'
        );
        insert new List<Utility_Account_Log__c>{ual1, ual2, ual3};

        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<Utility_Account_Subscription__c> uases = [SELECT Id FROM Utility_Account_Subscription__c];
        // There should be no opps or uases to start
        System.assertEquals(0, opps.size());
        System.assertEquals(0, uases.size());

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        // Since there are contracts to send here, we will run into "You have uncommitted work pending"
        // because of the DML in convertCSLead. The customerSubscriptionProcessTest method tests
        // the sendCSPackage method (which convertCSLead and sendContracts wraps) explicitly.
        LeadTriggerHandler.skipContractSend = true;
        CSAPController.convertCSLead(primaryProperty.Id, primaryProperty.Email);
        Test.stopTest();

        List<Lead> eversourceLeads = [SELECT Id, ConvertedAccountId FROM Lead WHERE Utility_relationship__r.Name = 'Eversource'];
        System.assertEquals(1, eversourceLeads.size());

        // 2 opps for the Eversource lead (one for each SSS)
        opps = [
            SELECT Id, Name, Shared_Solar_System__c, AccountId, ACH_Bank_Name__c, ACH_Bank_Routing_Number__c,
                CC_Account_Number__c, ACH_Account_Number__c, CC_Card_Type__c
            FROM Opportunity
            WHERE Shared_Solar_System__r.Utility__r.Name = 'Eversource'
            AND AccountId =: eversourceLeads[0].ConvertedAccountId
        ];
        System.assertEquals(2, opps.size());

        for (Opportunity opp : opps) {
            if (opp.ACH_Bank_Name__c != null) {
                //from ACHOrder1
                System.assertEquals('*****6789', opp.ACH_Bank_Routing_Number__c);
                System.assertEquals('******7890', opp.ACH_Account_Number__c);
            } else if (opp.CC_Card_Type__c != null) {
                //from ACHOrder2
                System.assertEquals('************1234', opp.CC_Account_Number__c);
            }
        }

        List<AggregateResult> uasAggregate = [
            SELECT Opportunity__r.AccountId, COUNT(Id) num, SUM(Customer_Subscription_KW_DC__c) total,
                MIN(Customer_Subscription_KW_DC__c) minimum, MAX(Customer_Subscription_KW_DC__c) maximum
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.AccountId =: eversourceLeads[0].ConvertedAccountId
            GROUP BY Opportunity__r.AccountId
        ];
        // Should be a 25kW, 10kW and 5kW UAS, for a total of 35
        System.assertEquals(3, uasAggregate[0].get('num'));
        System.assertEquals(35, ((Decimal) uasAggregate[0].get('total')).setScale(0));
        System.assertEquals(25, uasAggregate[0].get('maximum'));
        System.assertEquals(5, ((Decimal) uasAggregate[0].get('minimum')).setScale(0));

        List<ChargentOrders__ChargentOrder__c> primaryPropOrders = [
            SELECT Id, ChargentOrders__Billing_Email__c, ChargentOrders__Bank_Name__c,
                ChargentOrders__Bank_Account_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Account__c = : eversourceLeads[0].ConvertedAccountId
        ];
        System.assertEquals(1, primaryPropOrders.size());
        for (ChargentOrders__ChargentOrder__c chOrder : primaryPropOrders) {
            System.assertEquals(newACHOrder1.ChargentOrders__Billing_Email__c, chOrder.ChargentOrders__Billing_Email__c);
            System.assertEquals(newACHOrder1.ChargentOrders__Bank_Name__c, chOrder.ChargentOrders__Bank_Name__c);
            System.assertEquals(newACHOrder1.ChargentOrders__Bank_Account_Name__c, chOrder.ChargentOrders__Bank_Account_Name__c);
        }

        List<Lead> ngridLeads = [SELECT Id, ConvertedAccountId FROM Lead WHERE Utility_relationship__r.Name = 'National Grid'];
        System.assertEquals(1, ngridLeads.size());

        // Just 1 opp for NGrid since there's only one system
        opps = [
            SELECT Id, Name, Shared_Solar_System__c, AccountId, ACH_Bank_Name__c
            FROM Opportunity
            WHERE Shared_Solar_System__r.Utility__r.Name = 'National Grid'
            AND AccountId =: ngridLeads[0].ConvertedAccountId
        ];
        System.assertEquals(1, opps.size());

        uasAggregate = [
            SELECT Opportunity__r.AccountId, COUNT(Id) num, SUM(Customer_Subscription_KW_DC__c) total,
                MIN(Customer_Subscription_KW_DC__c) minimum, MAX(Customer_Subscription_KW_DC__c) maximum
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.AccountId =: ngridLeads[0].ConvertedAccountId
            GROUP BY Opportunity__r.AccountId
        ];
        // Just one 25kW UAS
        System.assertEquals(1, uasAggregate[0].get('num'));
        System.assertEquals(25, ((Decimal) uasAggregate[0].get('total')).setScale(0));
        System.assertEquals(25, uasAggregate[0].get('maximum'));
        System.assertEquals(25, ((Decimal) uasAggregate[0].get('minimum')).setScale(0));

        List<ChargentOrders__ChargentOrder__c> additionalPropOrders = [
            SELECT Id, ChargentOrders__Billing_Email__c, ChargentOrders__Bank_Name__c,
                ChargentOrders__Bank_Account_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Account__c = : ngridLeads[0].ConvertedAccountId
        ];

        System.assertEquals(1, additionalPropOrders.size());
        for (ChargentOrders__ChargentOrder__c chOrder : additionalPropOrders) {
            System.assertEquals(newACHOrder2.ChargentOrders__Billing_Email__c, chOrder.ChargentOrders__Billing_Email__c);
            System.assertEquals(newACHOrder2.ChargentOrders__Bank_Name__c, chOrder.ChargentOrders__Bank_Name__c);
            System.assertEquals(newACHOrder2.ChargentOrders__Bank_Account_Name__c, chOrder.ChargentOrders__Bank_Account_Name__c);
        }
    }

    @IsTest static void testMultipleSubscriptionsBykWh() {
        System_Properties__c sysProp = new System_Properties__c(
            Name = 'System',
            DocuSign_API_Account_ID__c = '123',
            DocuSign_Customer_Care_User__c = '123@123.com',
            DocuSign_Guest_User__c = '123@345.com',
            DocuSign_Guest_User_Credential__c = '234234',
            DocuSign_Integrator_Key__c = '123123-123123'
        );
        insert sysProp;
        
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};
        
        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .1848,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;
        Product2 csProduct = new Product2( Name = 'Community Solar - SMART 18-02',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SMART - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Customer_Subscription_Type__c = 'kWh',
            Monthly_Late_Fee__c = 1);
        insert csProduct;

        PostSandboxRefresher.SolarSystemHelper helper = new PostSandboxRefresher.SolarSystemHelper(null);
        helper.insertTariffsForProduct(csProduct.Id, eversource.Id, nationalGrid.Id);

        Shared_Solar_System__c sss1 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P1');
        Shared_Solar_System__c sss2 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P2');
        Shared_Solar_System__c sss4 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P3');
        Shared_Solar_System__c sss5 = getSharedSolarSystem(nmcRate, csProduct, eversource, 'Eversource P4');
        Shared_Solar_System__c sss3 = getSharedSolarSystem(nmcRate, csProduct, nationalGrid, 'National Grid P1');
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5};
        Shared_Solar_System__c sssCheck = [
            SELECT Maximum_Subscription_Cost__c, Maximum_Subscription_Capacity_kW_DC__c
            FROM Shared_Solar_System__c
            WHERE Id = :sss1.Id
        ];
        System.assertEquals(25, sssCheck.Maximum_Subscription_Capacity_kW_DC__c);
        System.assertEquals(6006, sssCheck.Maximum_Subscription_Cost__c);
        Partner__c partner = new Partner__c(Name = 'BlueWave Customer Care');
        insert partner;
        BSST__c salesTeam = new BSST__c (Name = 'Partner',
            Partner__c = partner.Id,
            Custom_ID__c = 'partner'
        );
        insert salesTeam;
        Account parentAccount = new Account(Name = 'Parent');
        insert parentAccount;
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Testcase',
            AccountId = parentAccount.Id
        );
        Lead primaryProperty = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Email = 'test@test.com',
            Electricity_Provider__c = 'Eversource',
			Utility_relationship__c = eversource.Id,
            LoadZone__c = 'WCMA',
            Company = 'Test',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Customer_type__c = 'Residential',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id
        );
        Lead additionalProperty = primaryProperty.clone();
        additionalProperty.Utility_relationship__c = nationalGrid.Id;
        additionalProperty.Electricity_Provider__c = 'National Grid';
        additionalProperty.Customer_type__c = 'Non-Residential';
        insert new List<Lead>{primaryProperty, additionalProperty};
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = primaryProperty.Id,
            LASERCA__Credit_Score_TransUnion__c = '720'
        );
        insert pcr;
        primaryProperty.Personal_Credit_Report__c = pcr.Id;
        additionalProperty.Personal_Credit_Report__c = pcr.Id;
        update new List<Lead>{primaryProperty, additionalProperty};
        // kW DC = Annual Cost / NMC Rate / Yield
        Utility_Account_Log__c ual1 = new Utility_Account_Log__c(
            Lead__c = primaryProperty.Id,
            Annual_kWh__c = (1300 * 20), // sss yield 1300 kWh/kW * 30 kW subscription
            Name_on_Account__c = 'Primary 1'
        );
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Lead__c = primaryProperty.Id,
            Annual_kWh__c = (1300 * 5 / 1.5).setScale(2), // sss yield 1300 kWh/kW * 5 kW subscription / 1.5 for Eversource R1
            Name_on_Account__c = 'Primary 2'
        );
        Utility_Account_Log__c ual3 = new Utility_Account_Log__c(
            Lead__c = additionalProperty.Id,
            Annual_kWh__c = (1300 * 25 / 1.45), // sss yield 1300 kWh/kW * 25 kW subscription / 1.45 for NG G2
            Name_on_Account__c = 'Additional 1'
        );
        insert new List<Utility_Account_Log__c>{ual1, ual2, ual3};
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<Utility_Account_Subscription__c> uases = [SELECT Id FROM Utility_Account_Subscription__c];
        // There should be no opps or uases to start
        System.assertEquals(0, opps.size());
        System.assertEquals(0, uases.size());
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        // Since there are contracts to send here, we will run into "You have uncommitted work pending"
        // because of the DML in convertCSLead. The customerSubscriptionProcessTest method tests
        // the sendCSPackage method (which convertCSLead and sendContracts wraps) explicitly.
        LeadTriggerHandler.skipContractSend = true;
        CSAPController.convertCSLead(primaryProperty.Id, primaryProperty.Email);
        Test.stopTest();
        List<Lead> eversourceLeads = [SELECT Id, ConvertedAccountId FROM Lead WHERE Utility_Relationship__r.Name = 'Eversource'];
        System.assertEquals(1, eversourceLeads.size());
        // 2 opps for the Eversource lead (one for each SSS)
        opps = [
            SELECT Id, Name, Shared_Solar_System__c, AccountId, ACH_Bank_Name__c, ACH_Bank_Routing_Number__c,
                CC_Account_Number__c, ACH_Account_Number__c
            FROM Opportunity
            WHERE Shared_Solar_System__r.Utility__r.Name = 'Eversource'
            AND AccountId =: eversourceLeads[0].ConvertedAccountId
        ];
        System.assertEquals(2, opps.size());
        List<AggregateResult> uasAggregate = [
            SELECT Opportunity__r.AccountId, COUNT(Id) num, SUM(Customer_Subscription_KW_DC__c) total,
                MIN(Customer_Subscription_KW_DC__c) minimum, MAX(Customer_Subscription_KW_DC__c) maximum
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.AccountId =: eversourceLeads[0].ConvertedAccountId
            GROUP BY Opportunity__r.AccountId
        ];
        // Should be a 25kW, 10kW and 5kW UAS, for a total of 35
        System.assertEquals(3, uasAggregate[0].get('num'));
        System.assertEquals(35, ((Decimal) uasAggregate[0].get('total')).setScale(0));
        System.assertEquals(25, uasAggregate[0].get('maximum'));
        System.assertEquals(5, ((Decimal) uasAggregate[0].get('minimum')).setScale(0));
        List<Lead> ngridLeads = [SELECT Id, ConvertedAccountId FROM Lead WHERE Utility_Relationship__r.Name  = 'National Grid'];
        System.assertEquals(1, ngridLeads.size());
        // Just 1 opp for NGrid since there's only one system
        opps = [
            SELECT Id, Name, Shared_Solar_System__c, AccountId
            FROM Opportunity
            WHERE Shared_Solar_System__r.Utility__r.Name = 'National Grid'
            AND AccountId =: ngridLeads[0].ConvertedAccountId
        ];
        System.assertEquals(1, opps.size());
        uasAggregate = [
            SELECT Opportunity__r.AccountId, COUNT(Id) num, SUM(Customer_Subscription_KW_DC__c) total,
                MIN(Customer_Subscription_KW_DC__c) minimum, MAX(Customer_Subscription_KW_DC__c) maximum
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.AccountId =: ngridLeads[0].ConvertedAccountId
            GROUP BY Opportunity__r.AccountId
        ];
        // Just one 25kW UAS
        System.assertEquals(1, uasAggregate[0].get('num'));
        System.assertEquals(25, ((Decimal) uasAggregate[0].get('total')).setScale(0));
        System.assertEquals(25, uasAggregate[0].get('maximum'));
        System.assertEquals(25, ((Decimal) uasAggregate[0].get('minimum')).setScale(0));
    }

    public static Shared_Solar_System__c getSharedSolarSystem(Utility_NMC_Tariff__c nmcRate, Product2 csProduct,
        Utility__c utility, String name) {
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = name,
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = utility.Id,
            Credit_Score_Requirement__c = 700,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25,
            Sales_Partners__c = 'All'
        );
        return sss1;
    }
}