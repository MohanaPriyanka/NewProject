@isTest
public with sharing class CSAPControllerTest {
    @testSetup static void setupTestData(){
        List<String> partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='API Only'];

        User apiUser = new User(
            FirstName = 'API',
            LastName = 'API',
            ProfileId = profileRecord.Id,
            Alias = '123api',
            Email = 'api@bluewavesolar.com',
            Emailencodingkey ='UTF-8',
            PortalRole = 'Manager',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Country ='United States',
            IsActive = true,
            Timezonesidkey='America/Los_Angeles',
            Username='api123@bluewavesolar.com');
        Util.insertSObj(apiUser);

        RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE Name = 'Partner Contact'];

        Account accountRecord = new Account(
            Name = 'BlueWave Customer Care',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain',
            AccountId = accountRecord.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(1));
        insert contactRecord;

        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];

        Load_U__c everLZU = new Load_U__c (Name = '02052',
                                           Load_zone__c = 'SEMA Eversource',
                                           LZ__c = 'SEMA',
                                           Town__c= 'Medfield');
        insert everLZU;

        Product2 srecProduct = new Product2( Name = 'SREC Community Solar',
                                                  Family = 'Community Solar',
                                                  Product_Type__c = 'Community Solar',
                                                  Program__c = 'SREC - Community Solar',
                                                  State__c = 'MA',
                                                  ProductCode = 'CS - BlueWave - 10%',
                                                  IsActive = True,
                                                  Lender_of_Record__c = 'BlueWave',
                                                  NMC_Discount__c = 10,
                                                  Annual_kWh_Maximum__c = 100000000,
                                                  NM_Rate_Floor__c = 0,
                                                  Days_In_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 1);

        Product2 smartProduct = new Product2(  Name = 'SMART Community Solar',
                                                  Family = 'Community Solar',
                                                  Product_Type__c = 'Community Solar',
                                                  Program__c = 'SMART - Community Solar',
                                                  State__c = 'MA',
                                                  ProductCode = 'CS - Bluewave - Public CS - 20%',
                                                  IsActive = True,
                                                  Lender_of_Record__c = 'BlueWave',
                                                  NMC_Discount__c = 20,
                                                  Annual_kWh_Maximum__c = 63000,
                                                  NM_Rate_Floor__c = 0.09,
                                                  Days_In_Bill_Period__c = 30,
                                                  Monthly_Late_Fee__c = 0.8333);
        insert new List<Product2>{srecProduct, smartProduct};

        Lead lead = new Lead(FirstName = 'Tester',
                            LastName = 'Testcase',
                            Company = 'Test',
                            Email = 'testymctesterson@tester.com',
                            LASERCA__Home_Address__c = '55 Boston St.',
                            LASERCA__Home_City__c = 'Boston',
                            LASERCA__Home_State__c = 'MA',
                            LASERCA__Home_Zip__c = '02052',
                            Parcel_Zip__c = '02052',
                            LASERCA__Social_Security_Number__c = '000000001',
                            Requested_Loan_Amount__c = 35000,
                            Annual_Income_Currency__c = 15000,
                            Partner_Lookup__c = partner.Id,
                            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
                            Status = 'Ready for Credit Check',
                            Utility_1__c = 'Eversource',
                            Electricity_Provider__c = 'Eversource');
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score__c = '200'
        );

        insert pcr;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
                                                                    Service_Territory__c = 'NEMA',
                                                                    Open__c = true,
                                                                    Reserved_Capacity_kW_DC__c = '10',
                                                                    Capacity_Committed_kW_DC__c = 0,
                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                    System_Utility__c = 'Eversource',
                                                                    Credit_Score_Requirement__c = 300,
                                                                    Assignment_order__c = '1',
                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                    Assemblage_Count__c = 1,
                                                                    Sales_Partners__c = 'All',
                                                                    Product__c = smartProduct.Id,
                                                                    Maximum_Subscription_Assemblage__c = 25);
        insert sss1;

    }

    @isTest static void testEmailCSAPApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        User userRecord = new User(
            FirstName = 'User',
            Lastname ='Testing',
            Alias = 'cswain',
            Email = 'tropicole34@aol.com',
            Emailencodingkey ='UTF-8',
            PortalRole = 'Manager',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactPartner.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='tropicole34@aol.com');

        Lead leadToInsert = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c, 
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE email = 'testymctesterson@tester.com'];
        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.id];
        Product2 smartProduct = [SELECT Id FROM Product2 WHERE name = 'SMART Community Solar'];

        Test.startTest();
        System.runAs(userRecord) {
            CSAPController.upsertCSAPRecords(leadToInsert, partner.id, salesRep.id);
        }

        Lead lead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c, 
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE email = 'testymctesterson@tester.com'];

        //Check upserted Lead, Contact and Account records
        System.assertEquals(lead.Id, CSAPController.getLead(lead.Id, lead.Email).Id);
        System.assertEquals(partner.Id, CSAPController.getLead(lead.Id, lead.Email).Partner_Lookup__c);
        System.assertEquals(salesRep.Id, CSAPController.getLead(lead.Id, lead.Email).bs_Sales_ID__c);
        System.assert(CSAPController.getContact(lead.Id, lead.Email).Id != null);
        System.assert(CSAPController.getAccount(lead.Id, lead.Email).Id != null);

        System.assert(true, CSAPController.hasAvailableCapacity(lead.Id));

        //Try pulling credit report
        CSAPController.pullCreditStatus(lead);
        //Check not qualified since Credit Score is only 200
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);

        //Check for qualified
        pcr.LASERCA__Credit_Score__c = '800';
        update pcr;
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);
        System.assertEquals(null, CSAPController.checkLeadCreditIfQualified(lead.Id).srecProduct);
        System.assertEquals(smartProduct.Id, CSAPController.checkLeadCreditIfQualified(lead.Id).smartProduct.Id);

        System.assertEquals('API', lead.Parent_Account__r.Owner.Name);
        System.assertNotEquals('User Testing', lead.Parent_Account__r.Owner.Name);

        Test.stopTest();
    }

    @isTest static void testSLPortalCSAPApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];
        Contact contactPartner = [SELECT Id FROM Contact LIMIT 1];
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        User otherUser = new User(
            FirstName = 'User',
            Lastname ='Jordan',
            Alias = 'jUser132',
            Email = 'jpentaleri@aol.com',
            Emailencodingkey ='UTF-8',
            PortalRole = 'Manager',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactPartner.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='jUser132@aol.com');

        Lead leadToInsert = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE email = 'testymctesterson@tester.com'];
        LASERCA__Personal_Credit_Report__c pcr = [SELECT LASERCA__Credit_Score__c FROM LASERCA__Personal_Credit_Report__c WHERE LASERCA__Lead__c = :leadToInsert.id];
        Product2 smartProduct = [SELECT Id FROM Product2 WHERE name = 'SMART Community Solar'];

        Test.startTest();
        System.runAs(otherUser) {
            CSAPController.upsertCSAPRecords(leadToInsert, '', '');
        }

        Lead lead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE email = 'testymctesterson@tester.com'];
        //Check upserted Lead, Contact and Account records
        System.assertEquals(lead.Id, CSAPController.getLead(lead.Id, lead.Email).Id);
        System.assertEquals(partner.Id, CSAPController.getLead(lead.Id, lead.Email).Partner_Lookup__c);
        System.assert(CSAPController.getContact(lead.Id, lead.Email).Id != null);
        System.assert(CSAPController.getAccount(lead.Id, lead.Email).Id != null);

        System.assert(true, CSAPController.hasAvailableCapacity(lead.Id));

        //Try pulling credit report
        CSAPController.pullCreditStatus(lead);
        //Check not qualified since Credit Score is only 200
        System.assertEquals('Unqualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);

        //Check for qualified
        pcr.LASERCA__Credit_Score__c = '800';
        update pcr;
        System.assertEquals('Qualified', CSAPController.checkLeadCreditIfQualified(lead.Id).sssCreditQualification);
        System.assertEquals(null, CSAPController.checkLeadCreditIfQualified(lead.Id).srecProduct);
        System.assertEquals(smartProduct.Id, CSAPController.checkLeadCreditIfQualified(lead.Id).smartProduct.Id);

        Test.stopTest();
    }

    @isTest static void creditCheckTimeout() {
        System.assertEquals(60000, CSAPController.getCreditCheckTimeout());
        System_Properties__c systemProperties = System_Properties__c.getall().values()[0];
        systemProperties.Credit_Check_Timeout__c = 30000;
        update systemProperties;
        System.assertEquals(30000, CSAPController.getCreditCheckTimeout());
    }

    @IsTest
    static void testConversion() {
        Lead lead = [SELECT Id, Email, IsConverted FROM Lead WHERE Email = 'testymctesterson@tester.com'];
        lead.Status = 'Qualified';
        update lead;
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        System.debug(LoggingLevel.ERROR, opps);
        System.assertEquals(0, opps.size());
        CSAPController.convertCSLead(lead.Id, lead.Email);
        lead = [SELECT Id, Email, IsConverted FROM Lead WHERE Email = 'testymctesterson@tester.com'];
        System.assertEquals(true, lead.IsConverted);
        opps = [SELECT Id, Name FROM Opportunity];
        System.assertEquals(0, opps.size());
    }
}
