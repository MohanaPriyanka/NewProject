@isTest
public with sharing class CAPControllerTest {
    @testSetup static void setupTestData(){
        Test.loadData(System_Properties__c.SObjectType, 'TestRLSystemProperties');
        Util.disableTrigger('Disable_LoanTrancheTrigger__c');
        Util.disableTrigger('Disable_LeadTrigger__c');
        Util.disableTrigger('Disable_ContactTrigger__c');

        Test.loadData(Partner__c.SObjectType, 'TestRLPartner');
        Test.loadData(BSST__c.SObjectType, 'TestRLBSST');
        Test.loadData(Loan_Data__c.SObjectType, 'TestRLLoanData');
        Test.loadData(Loan_Traunch__c.SObjectType, 'TestRLLoanTraunch');
        Test.loadData(Product2.SObjectType, 'TestRLProduct');
        Test.loadData(Lead.SObjectType, 'TestRLLead');
        Test.loadData(Account.SObjectType, 'TestRLAccount');
        Test.loadData(Contact.SObjectType, 'TestRLContact');
        // We can't load in Leads and Contacts with PCR fields populated since PCRs don't exist yet, so we'll do that below
        Test.loadData(LASERCA__Personal_Credit_Report__c.SObjectType, 'TestRLPCR');
        Test.loadData(LASERCA__Trade_Accounts__c.SObjectType, 'TestRLTradeAccounts');

        // This simulates creating CRLs as Complete. We don't actually insert them because this would run the trigger
        // unnecessarily
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap = new Map<Id, LASERCA__Credit_Report_Log__c>();
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id FROM LASERCA__Personal_Credit_Report__c];
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            LASERCA__Credit_Report_Log__c crl = new LASERCA__Credit_Report_Log__c(
                LASERCA__Personal_Credit_Report__c = pcr.Id,
                LASERCA__Status__c = 'Completed'
            );
            triggerNewMap.put(pcr.Id, crl);
        }
        MapPCRtoLeadHandler.mapPCRtoLead(triggerNewMap, null);

        Util.enableTrigger('Disable_LoanTrancheTrigger__c');
        Util.enableTrigger('Disable_LeadTrigger__c');
        Util.enableTrigger('Disable_ContactTrigger__c');
    }

    @isTest static void testAddNewLeadRecord() {
        Product2 p = [SELECT Id FROM Product2 WHERE IsActive = TRUE LIMIT 1];
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User' LIMIT 1];
        RecordType loanRT = [
                SELECT Id
                FROM RecordType
                WHERE DeveloperName = 'BFG_Solar_Loan'
                AND SobjectType = 'Lead'
                LIMIT 1
        ];
        Lead l = new Lead(
                FirstName = 'Tester',
                LastName = 'Testcase',
                Company = 'Test',
                Product__c = p.Id,
                Email = 'test@tester.com',
                LASERCA__Home_Address__c = '55 Boston St.',
                LASERCA__Home_City__c = 'Boston',
                LASERCA__Home_State__c = 'MA',
                LASERCA__Home_Zip__c = '02052',
                LASERCA__Social_Security_Number__c = '000000001',
                Requested_Loan_Amount__c = 35000,
                Annual_Income_Currency__c = 15000,
                Co_Applicant_Income__c = 10,
                Partner_Lookup__c = partner.Id,
                Product_Program__c = 'BlueWave Solar Loan',
                Bs_Sales_ID__c = salesRep.Id,
                Status = 'Ready for Credit Check',
                Product_Line__c = 'Residential Loan',
                RecordTypeId = loanRT.Id);
        insert l;
        Test.startTest();
        System.assertEquals(CAPController.getCreditCheckTimeout(), 60000);
        Boolean caughtException = false;
        try {
            CAPController.getLead(l.id, 'foo');
        } catch (AuraHandledException ahe) {
            caughtException = true;
        }
        System.assertEquals(true, caughtException);
        System.assertEquals('Tester', CAPController.getLead(l.id, 'test@tester.com').FirstName);
        System.assertEquals(null, CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);
        Lead leadClone = l.clone(true,false,false,false);
        leadClone.email = 'foo';
        leadClone.Application_Type__c = 'Joint';
        caughtException = false;
        try {
            CAPController.setAppType(leadClone);
        } catch (AuraHandledException ahe) {
            caughtException = true;
        }
        System.assertEquals(true, caughtException);
        System.assertEquals(null, CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);
        l.Application_Type__c = 'Individual';
        CAPController.setAppType(l);
        l.Application_Type__c = 'Joint';
        CAPController.setAppType(l);
        System.assertEquals('Joint', CAPController.getLead(l.id, l.email).Application_Type__c);
        System.assertEquals('Co-Applicant', CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);

        Account coApplicantAccount = new Account( Name = 'CoapplicantAccount');
        insert coApplicantAccount;
        Contact coApplicantContact = new Contact(
            FirstName = 'Cole',
            LastName = 'Swain',
            AccountId = coApplicantAccount.Id,
            Lead__c = l.Id,
            Income__c = 10,
            LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;
        l.CoApplicant_Contact__c = coApplicantContact.Id;
        update l;

        CAPController.pullCreditStatus(l);
        // Laser Credit Access trigger should unset the pull credit report checkbox
        l = [SELECT Id, LASERCA__Pull_Credit_Report__c
             FROM Lead
             WHERE Id = : l.id];
        System.assertEquals(false, l.LASERCA__Pull_Credit_Report__c);
        Test.stopTest();

        // LCA should set pull credit once the future method fires
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id
                                                         FROM LASERCA__Personal_Credit_Report__c
                                                         WHERE LASERCA__Lead__c = :l.Id];
        System.assertEquals(2, pcrs.size());

        System.assertEquals('Pending Credit Review', CAPController.checkCreditStatus(l));
    }

    @isTest static void creditCheckTimeout() {
        System.assertEquals(CAPController.getCreditCheckTimeout(), 60000);
        System_Properties__c systemProperties = System_Properties__c.getall().values()[0];
        systemProperties.Credit_Check_Timeout__c = 30000;
        update systemProperties;
        System.assertEquals(CAPController.getCreditCheckTimeout(), 30000);
    }

    @isTest static void pullCreditstatus() {
        Test.startTest();
        RecordType loanRT = [
                SELECT Id
                FROM RecordType
                WHERE DeveloperName = 'BFG_Solar_Loan'
                AND SobjectType = 'Lead'
                LIMIT 1
        ];
        Lead newLead = new Lead(
                FirstName = 'Cole',
                LastName = 'Swain',
                Company = 'Test',
                LASERCA__Home_Address__c = '55 Boston St.',
                LASERCA__Home_City__c = 'Boston',
                LASERCA__Home_State__c = 'MA',
                LASERCA__Home_Zip__c = '02052',
                Email = 'colemswain@gmail.com',
                LASERCA__Social_Security_Number__c = '000000001',
                Requested_Loan_Amount__c = 25000,
                Annual_Income_Currency__c = 150000,
                Credit_Check_Acknowledged__c = true,
                Privacy_Policy_Acknowledged__c = true,
                Automatic_Product_Assignment__c = true,
                Product_Program__c = 'BlueWave Solar Loan',
                Unfinished_Lead__c = true,
                Utility_Bill_Access_Acknowledged__c = true,
                Status = 'Ready for Credit Check',
                Product_Line__c = 'Residential Loan',
                RecordTypeId = loanRT.Id);
        insert newLead;

        CAPController.pullCreditStatus(newLead);

        Test.stopTest();

        // Laser Credit Access trigger should unset the pull credit report checkbox
        List<Lead> leadList = [
            SELECT Id, LASERCA__Pull_Credit_Report__c, Personal_Credit_Report__c,
            Date_of_Application_2__c
            FROM Lead
            WHERE LastName = 'Swain'];
        System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);
        System.assertEquals(System.now().format('YYYY-MM-dd'), leadList[0].Date_of_Application_2__c);

        // LCA should set pull credit once the future method fires
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id
                                                         FROM LASERCA__Personal_Credit_Report__c
                                                         WHERE LASERCA__Lead__c = :leadList[0].Id];
        System.assertEquals(pcrs.size(), 1);

        List<LASERCA__Credit_Report_Log__c> pcls = [SELECT Id
                                                         FROM LASERCA__Credit_Report_Log__c
                                                         WHERE LASERCA__Lead__c = :leadList[0].Id];
        System.assertEquals(pcls.size(), 1);

        System.assertEquals('Pending Credit Review', CAPController.checkCreditStatus(leadList[0]));

        System.assertEquals(null, CAPController.getLead(newLead.id, newLead.email).Joint_Applicant_Type__c);
        newLead.Application_Type__c = 'Joint';
        CAPController.setAppType(newLead);
        System.assertEquals('Joint', CAPController.getLead(newLead.id, newLead.email).Application_Type__c);
        System.assertEquals('Co-Signer', CAPController.getLead(newLead.id, newLead.email).Joint_Applicant_Type__c);
    }

    @isTest static void testErrorParsing() {
        System.assertEquals('CreditBureau - Invalid borrower first name',
                            CAPController.parseError('ERROR: E999 - CreditBureau - Invalid borrower first name'));

        System.assertEquals('SomethingElse - Invalid borrower first name',
                            CAPController.parseError('ERROR: A103 - SomethingElse - Invalid borrower first name'));

        System.assertEquals('WARN: ABC - Not Handled',
                            CAPController.parseError('WARN: ABC - Not Handled'));
    }

    @isTest static void testGetCustomerProducts() {
        List<Product2> productReturnList = new List<Product2>();
        Map<String, Lead> leadMap = new Map<String, Lead>();

        for (Lead lead : [SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, Personal_Credit_Report__c,
                          (SELECT Id, Adjusted_Income__c, Adjusted_DTI__c, LASERCA__Contact__c FROM LASERCA__Personal_Credit_Reports__r)
                          FROM Lead
                          WHERE FirstName = 'leadMALoanTerm10Rate699' OR FirstName = 'coApplicantLead' LIMIT 2]) {
            leadMap.put(lead.FirstName, lead);
        }
        System.assertEquals('710', leadMap.get('leadMALoanTerm10Rate699').LASER_Credit_Score__c);

        Test.startTest();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('leadMALoanTerm10Rate699').Id);
        System.assertEquals(2, productReturnList.size());

        productReturnList.clear();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('coApplicantLead').Id);
        System.assertEquals(0, productReturnList.size());

        List<LASERCA__Personal_Credit_Report__c> creditReportList = leadMap.get('coApplicantLead').LASERCA__Personal_Credit_Reports__r;
        LASERCA__Personal_Credit_Report__c primaryPCR = new LASERCA__Personal_Credit_Report__c();
        primaryPCR.Id = leadMap.get('coApplicantLead').Personal_Credit_Report__c;
        primaryPCR.Adjusted_Income__c = 500000;
        update primaryPCR;

        productReturnList.clear();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('coApplicantLead').Id);
        System.assertEquals(2, productReturnList.size());

        for (LASERCA__Personal_Credit_Report__c creditReport : creditReportList) {
            if (creditReport.LASERCA__Contact__c == null) {
                creditReport.Adjusted_DTI__c = 20;
            }
        }
        creditReportList[0].Adjusted_Income__c = 0;
        update creditReportList;

        productReturnList.clear();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('coApplicantLead').Id);
        System.assertEquals(2, productReturnList.size());
        Test.stopTest();
    }

    @IsTest static void testGetProducts() {
        List<Product2> products = [SELECT Id FROM Product2 WHERE IsActive = TRUE AND Product_Type__c = 'Residential Loan' AND Require_Junctions_to_Enable__c = FALSE];
        System.assertEquals(11, products.size());

        products = CAPController.getProducts('MA', 'Residential Loan');
        System.assertEquals(8, products.size());
    }

    @IsTest static void rejectAndApproveChange() {
        Lead lead = [
            SELECT Id, Email, Unfinished_Lead__c, Status, System_Cost__c, Requested_Loan_Amount__c,
                Product_line__c, Product__r.Loan_Interest_Rate__c, bs_Sales_ID__c, Loan_Financing_Fee__c,
                Partner_Lookup__c, LASERCA__Home_State__c, Product__c, DOER_Solar_Loan__c, Loan_Fee_1__c,
                Product__r.Loan_Interest_Only_Period__c, Loan_System_Information__c, FirstName, LastName,
                ConvertedOpportunityId
            FROM Lead
            WHERE Requested_Loan_Amount__c = 35000
            AND System_Cost__c = NULL
            LIMIT 1
        ];
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);

        Residential_Equipment__c re = [
            SELECT Id, Generator_Nameplate_Capacity__c, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,
                Inverter_Manufacturer__c, Inverter_Model_Number__c, Number_of_Inverters__c,  Storage_Grid_Hybrid__c,
                Storage_Capacity__c, Storage_Full_or_Partial_Home__c, Storage_Inverter_Manufacturer__c,
                Storage_Inverter_Model__c, Storage_Manufacturer__c, Loan__r.Lead__r.Storage__c, Storage_Model__c
            FROM Residential_Equipment__c
            WHERE Loan__r.Lead__c = :lead.Id
        ];
        System.assertEquals(null, re.Generator_Nameplate_Capacity__c);
        System.assertEquals(null, re.Module_Manufacturer__c);
        System.assertEquals(null, re.Module_Model_Number__c);
        System.assertEquals(null, re.Number_of_Modules__c);
        System.assertEquals(null, re.Inverter_Manufacturer__c);
        System.assertEquals(null, re.Inverter_Model_Number__c);
        System.assertEquals(null, re.Number_of_Inverters__c);
        System.assertEquals(null, re.Storage_Capacity__c);
        System.assertEquals(false, re.Storage_Grid_Hybrid__c);
        System.assertEquals(null, re.Storage_Full_or_Partial_Home__c);
        System.assertEquals(null, re.Storage_Inverter_Manufacturer__c);
        System.assertEquals(null, re.Storage_Manufacturer__c);
        System.assertEquals(null, re.Storage_Inverter_Model__c);
        System.assertEquals(null, re.Storage_Model__c);

        Loan__c loan = [
            SELECT Id, Commencement_Datee__c
            FROM Loan__c
            WHERE Lead__c = :lead.Id
        ];
        System.assertEquals(null, loan.Commencement_Datee__c);
        lead = [
            SELECT Id, Email, Unfinished_Lead__c, Status, System_Cost__c, Requested_Loan_Amount__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals(35000, lead.Requested_Loan_Amount__c);
        System.assertEquals(null, lead.System_Cost__c);
        System.assertEquals('Ready for Credit Check', lead.Status);
        lead.Loan_System_Information__c =
            '{' +
                '\"generator_nameplate_capacity__c\" : null,' +
                '\"commencement_datee__c\" : \"\",' +
                '\"inverter_model_number__c\" : \"\",' +
                '\"inverter_manufacturer__c\" : \"\",' +
                '\"number_of_inverters__c\" : \"\",' +
                '\"module_model_number__c\" : \"\",' +
                '\"module_manufacturer__c\" : \"\",' +
                '\"number_of_modules__c\" : \"\",' +
                '\"Storage_Grid_Hybrid__c\" : false,' +
                '\"Storage_Capacity__c\" : \"\",' +
                '\"Storage_Full_or_Partial_Home__c\" : \"\",' +
                '\"Storage_Inverter_Manufacturer__c\" : \"\",' +
                '\"Storage_Inverter_Model__c\" : \"\",' +
                '\"Storage_Manufacturer__c\" : \"\",' +
                '\"Storage_Model__c\" : \"\",' +
                '\"System_Cost__change\" : 3000,' +
                '\"Requested_Loan_Amount__change\" : 2112,' +
                '\"Estimated_Completion_Date__change\" : \"06/01/2018\",' +
                '\"Generator_Nameplate_Capacity__change\" : 10.08,' +
                '\"Module_Manufacturer__change\" : \"SolarModules\",' +
                '\"Module_Model_Number__change\" : \"MM\",' +
                '\"Number_of_Modules__change\" : 27,' +
                '\"Inverter_Manufacturer__change\" : \"SolarInverters\",' +
                '\"Inverter_Model_Number__change\" : \"EN\",' +
                '\"Number_of_Inverters__change\" : 2,' +
                '\"Storage__change\" : true,' +
                '\"Storage_Grid_Hybrid__change\" : \"Yes\",' +
                '\"Storage_Capacity__change\" : 10,' +
                '\"Storage_Full_or_Partial_Home__change\" : \"Full home backup\",' +
                '\"Storage_Inverter_Manufacturer__change\" : \"SolarEdge\",' +
                '\"Storage_Inverter_Model__change\" : \"StorEdge 10kw\",' +
                '\"Storage_Manufacturer__change\" : \"Tesla\",' +
                '\"Storage_Model__change\" : \"Powerwall\",' +
                '\"Down_Payment__change\" : 888,' +
                '\"Reject_Reason\" : \"Need more panels\",' +
                '\"RequestedBy__change\" : \"Rob Meyers\",' +
                '\"RequestedDate__change\" : \"04/17/2018 14:19\"' +
                '}';
        update lead;

        Test.startTest();
        CAPController.setRejectedChangeOrder(lead.Id, lead.Email, lead.Loan_System_Information__c);
        lead = [
            SELECT Id, Email, Unfinished_Lead__c, Status, System_Cost__c, Requested_Loan_Amount__c, Change_Order_Status__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('Customer Rejected', lead.Change_Order_Status__c);

        CAPController.setApprovedChangeOrder(lead.Id, lead.Email);

        Test.stopTest();

        re = [
            SELECT Id, Generator_Nameplate_Capacity__c, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,
                Inverter_Manufacturer__c, Inverter_Model_Number__c, Number_of_Inverters__c, Loan__r.DOER_Solar_Loann__c,
                Storage_Capacity__c, Storage_Full_or_Partial_Home__c, Storage_Inverter_Manufacturer__c, Storage_Model__c,
                Storage_Inverter_Model__c, Storage_Manufacturer__c, Loan__r.Lead__r.Storage__c, Storage_Grid_Hybrid__c
            FROM Residential_Equipment__c
            WHERE Loan__r.Lead__c = :lead.Id
        ];
        System.assertEquals(10.08, re.Generator_Nameplate_Capacity__c);
        System.assertEquals('SolarModules', re.Module_Manufacturer__c);
        System.assertEquals('MM', re.Module_Model_Number__c);
        System.assertEquals(27, re.Number_of_Modules__c);
        System.assertEquals('SolarInverters', re.Inverter_Manufacturer__c);
        System.assertEquals('EN', re.Inverter_Model_Number__c);
        System.assertEquals(2, re.Number_of_Inverters__c);
        System.assertEquals(10, re.Storage_Capacity__c);
        System.assertEquals(true, re.Storage_Grid_Hybrid__c);
        System.assertEquals('Full home backup', re.Storage_Full_or_Partial_Home__c);
        System.assertEquals('SolarEdge', re.Storage_Inverter_Manufacturer__c);
        System.assertEquals('Tesla', re.Storage_Manufacturer__c);
        System.assertEquals('StorEdge 10kw', re.Storage_Inverter_Model__c);
        System.assertEquals('Powerwall', re.Storage_Model__c);

        loan = [
            SELECT Id, Commencement_Datee__c, Requested_Loan_Amount__c, Loan_Term__c,
            (SELECT Id, Amort_Starting_Principal__c FROM Loan_Payments__r ORDER BY Period__c)
            FROM Loan__c
            WHERE Lead__c = :lead.Id
        ];
        System.assertEquals(Date.newInstance(2018,6,1) + (re.Loan__r.DOER_Solar_Loann__c?45:30), loan.Commencement_Datee__c);
        lead = [
            SELECT Id, Email, Unfinished_Lead__c, Status, System_Cost__c, Requested_Loan_Amount__c, Change_Order_Status__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals(3000, lead.System_Cost__c);
        System.assertEquals(2112, lead.Requested_Loan_Amount__c);
        System.assertEquals(2112, loan.Requested_Loan_Amount__c);
        System.assertEquals(2112, loan.Loan_Payments__r[12].Amort_Starting_Principal__c);
        System.assertEquals('Customer Authorized', lead.Change_Order_Status__c);
        System.assertEquals('Under BlueWave Review', lead.Status);

    }

    @IsTest static void testLoanCreation() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        System.assertEquals(0, lead.Loans__r.size());
        System.assertEquals(0, lead.Residential_Equipment__r.size());
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.convertLead(lead.Id, lead.Email);
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        // Shouldn't send docs since the equipment isn't populated
        CAPController.sendLoanDocs(lead.Id, lead.Email);
        Test.stopTest();
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted, ConvertedOpportunityId, Status,
            (SELECT Id, Opportunity__c FROM Loans__r),
            (SELECT Id, Opportunity__c FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        System.assertEquals(1, lead.Loans__r.size());
        System.assertEquals(lead.ConvertedOpportunityId, lead.Loans__r[0].Opportunity__c);
        System.assertEquals(1, lead.Residential_Equipment__r.size());
        System.assertEquals(lead.ConvertedOpportunityId, lead.Residential_Equipment__r[0].Opportunity__c);
        System.assertEquals('Interested', lead.Status);
        System.assertEquals(true, lead.IsConverted);
    }

    @IsTest static void testLoanDocSend() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        System.assertEquals(0, lead.Loans__r.size());
        System.assertEquals(0, lead.Residential_Equipment__r.size());
        lead.Loan_System_Information__c = '{' +
            '"number_of_modules__c":21,"module_manufacturer__c":"foo","module_model_number__c":"bar",' +
            '"number_of_inverters__c":22,"inverter_manufacturer__c":"baz","inverter_model_number__c":"biz",' +
            '"commencement_datee__c":"06/01/2018","generator_nameplate_capacity__c":10.2,"provideSystemInfo":true}';
        update lead;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.convertLead(lead.Id, lead.Email);
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        CAPController.sendLoanDocs(lead.Id, lead.Email);
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        Partner_Task__c pt = [
            SELECT Id, Status__c
            FROM Partner_Task__c
            WHERE Name = 'Provide all System Information'
            AND Loan__c = :lead.Loans__r[0].Id
        ];
        System.assertEquals('Complete', pt.Status__c);
        Test.stopTest();
    }

    @IsTest static void testPartnerTaskUpsert() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        CAPController.convertLead(lead.Id, lead.Email);
        Test.startTest();
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        Partner_Task__c task = [
            SELECT Id, Name,
            (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Provide Income Documentation'
        ];
        System.assertEquals(0, task.SubTasks__r.size());
        task = [
            SELECT Id, Name, Status__c, Completion_Date__c,
            (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Obtain Contract Signature'
        ];
        task.Status__c = 'Complete';
        Date today = Date.today();
        task.Completion_Date__c = today;
        update task;

        lead.Employed__c = true;
        update lead;
        CAPController.insertPartnerTasks(lead.Id, lead.Email);
        task = [
            SELECT Id, Name,
            (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Provide Income Documentation'
        ];
        System.debug(LoggingLevel.ERROR, task);
        System.assertEquals(1, task.SubTasks__r.size());
        task = [
            SELECT Id, Name, Status__c, Completion_Date__c,
                (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Obtain Contract Signature'
        ];
        System.assertEquals('Complete', task.Status__c);
        System.assertEquals(today, task.Completion_Date__c);
        Test.stopTest();
    }

    @IsTest static void testNoDoubleSend() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        lead.Loan_System_Information__c = '{' +
            '"number_of_modules__c":21,"module_manufacturer__c":"foo","module_model_number__c":"bar",' +
            '"number_of_inverters__c":22,"inverter_manufacturer__c":"baz","inverter_model_number__c":"biz",' +
            '"commencement_datee__c":"06/01/2018","generator_nameplate_capacity__c":10.2,"provideSystemInfo":true}';
        update lead;
        Test.startTest();
        CAPController.convertLead(lead.Id, lead.Email);
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted, ConvertedOpportunityId,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r),
            (SELECT Id, Status__c FROM Partner_Tasks__r WHERE Name = 'Obtain Contract Signature')
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        lead.Partner_Tasks__r[0].Status__c = 'Pending';
        update lead.Partner_Tasks__r;
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.sendLoanDocs(lead.Id, lead.Email);
        Test.stopTest();
        System.assertEquals(null, DocuSignHelper.oppLoansSent);
    }

    @IsTest static void testContractSendIfAbsent() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted, (SELECT Id FROM Loans__r), (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699'
            LIMIT 1
        ];
        CAPController.convertLead(lead.Id, lead.Email);
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);

        lead.Loan_System_Information__c = '{' +
            '\"System_Cost__change\" : 3000,' +
            '\"Requested_Loan_Amount__change\" : 2112,' +
            '\"Estimated_Completion_Date__change\" : \"06/01/2018\",' +
            '\"Generator_Nameplate_Capacity__change\" : 10.08,' +
            '\"Module_Manufacturer__change\" : \"SolarModules\",' +
            '\"Module_Model_Number__change\" : \"MM\",' +
            '\"Number_of_Modules__change\" : 27,' +
            '\"Inverter_Manufacturer__change\" : \"SolarInverters\",' +
            '\"Inverter_Model_Number__change\" : \"EN\",' +
            '\"Number_of_Inverters__change\" : 2,' +
            '\"Storage__change\" : true,' +
            '\"Storage_Grid_Hybrid__change\" : \"Yes\",' +
            '\"Storage_Capacity__change\" : 10,' +
            '\"Storage_Full_or_Partial_Home__change\" : \"Full home backup\",' +
            '\"Storage_Inverter_Manufacturer__change\" : \"SolarEdge\",' +
            '\"Storage_Inverter_Model__change\" : \"StorEdge 10kw\",' +
            '\"Storage_Manufacturer__change\" : \"Tesla\",' +
            '\"Storage_Model__change\" : \"Powerwall\",' +
            '\"Down_Payment__change\" : 888,' +
            '\"Reject_Reason\" : \"Need more panels\",' +
            '\"RequestedBy__change\" : \"Rob Meyers\",' +
            '\"RequestedDate__change\" : \"04/17/2018 14:19\"' +
            '}';
        update lead;

        // Asserts that the task for obtaining the contract signature has not been updated to 'Pending' yet.
        Partner_Task__c preApprovalContractTask = [
            SELECT Id, Name, Status__c, Completion_Date__c,
            (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Obtain Contract Signature'
            AND Lead__c = :lead.Id
        ];
        System.assertEquals('Incomplete', preApprovalContractTask.Status__c);

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.setApprovedChangeOrder(lead.Id, lead.Email);
        Test.stopTest();

        Partner_Task__c pt = [
            SELECT Id, Name, Status__c, Completion_Date__c,
            (SELECT Id, Name FROM SubTasks__r)
            FROM Partner_Task__c
            WHERE Name = 'Obtain Contract Signature'
            AND Lead__c = :lead.Id
        ];
        System.assertEquals('Pending', pt.Status__c);
    }

    @IsTest static void testDocRequest() {
        Lead lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted,
            (SELECT Id FROM Loans__r),
            (SELECT Id FROM Residential_Equipment__r)
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.convertLead(lead.Id, lead.Email);
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        CAPController.sendLoanDocs(lead.Id, lead.Email);
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted, ConvertedOpportunityId,
                Status, Name, Docs_Requested__c, Sales_Person_Name__c
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        lead.CAP_Stage__c = 'NAV_Income_Doc';
        List<String> docs = new String[]{'Pay Stub','SSN Letter'};
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        LoanUnderwriting.updateLeadAndRequestDocument(lead, docs);

        Test.stopTest();
        // We're asserting that the NAV_Stage and Status changes are in accordance with the Lead Updates in updateLeadAndRequestDocument
        System.assertEquals('Awaiting Info Requested From Customer', lead.Status);
        System.assertEquals('NAV_Complete', lead.CAP_Stage__c);
        System.assertEquals(true, lead.Docs_Requested__c);

        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        CAPController.finishDocRequestAndNotifyOps(lead.Id);
        lead = [
            SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c, IsConverted, ConvertedOpportunityId,
                Status, Name, Docs_Requested__c, CAP_Stage__c
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];

//         Here we're asserting that the lead is back in Avidia's queue for review and that the customer no longer
//         has access to the file upload page.
        System.assertEquals('Under BlueWave Review', lead.Status);
        System.assertEquals('NAV_Complete', lead.CAP_Stage__c);
        System.assertEquals(false, lead.Docs_Requested__c);
    }
}