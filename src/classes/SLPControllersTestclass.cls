@isTest
public without sharing class SLPControllersTestclass {
    @testSetup public static void setupTestData(){
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        Account accountRecord = new Account(
            Name = 'BlueWave Customer Care',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord;

        List<String> partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

        RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE Name = 'Partner Contact'];
        Contact contactRecord = new Contact(
            FirstName = 'User',
            LastName = 'Swain',
            AccountId = accountRecord.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(1));
        Insert contactRecord;

        Account accountRecordExec = new Account(Name = 'BlueWave Customer Care');
        insert accountRecordExec;

        Contact contactRecordExec = new Contact(
            FirstName = 'Executive',
            LastName = 'Swain',
            AccountId = accountRecordExec.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(2));
        Insert contactRecordExec;

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
            ContactId = contactRecord.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='tropicole34@aol.com');

        User executiveRecord = new User(
            FirstName = 'Executive',
            Lastname ='Testing',
            Alias = 'cmswain',
            Email = 'colematthewswain@gmail.com',
            Emailencodingkey ='UTF-8',
            PortalRole = 'Executive',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactRecordExec.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='colematthewswain@gmail.com');
        Util.insertSobjs(new List<User>{userRecord, executiveRecord});

        LoanTestRecordWarehouse.getLoanHandlerLeadRecords();

        System_Properties__c sysProp = new System_Properties__c(
            Name = 'System',
            DocuSign_API_Account_ID__c = '123',
            DocuSign_Customer_Care_User__c = '123@123.com',
            DocuSign_Guest_User__c = '123@345.com',
            DocuSign_Guest_User_Credential__c = '234234',
            DocuSign_Integrator_Key__c = '123123-123123'
        );
        insert sysProp;
    }

    @isTest static void testAddNewLeadRecord() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
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
            Status = 'Ready for Credit Check',
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true
        );
        List<Lead> leadList;

        System.assertEquals(SLPAddCustomer.getCreditCheckTimeout(), 60000);
        System.runAs(partnerUser) {
            SLPAddCustomer.addNewLeadRecord(newLead);
        }

        leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
        FROM Lead
        WHERE LastName = 'Swain'];

        System.assertEquals(leadList.size(), 1);
        System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);

        System.runAs(partnerUser) {
            SLPAddCustomer.pullCreditStatus(leadList[0]);
        }
            // Laser Credit Access trigger should unset the pull credit report checkbox
            leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
            FROM Lead
            WHERE LastName = 'Swain'];
            System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);

        Test.stopTest();

        // LCA should set pull credit once the future method fires
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id
        FROM LASERCA__Personal_Credit_Report__c
        WHERE LASERCA__Lead__c = :leadList[0].Id];
        System.assertEquals(pcrs.size(), 1);

        System.assertEquals(SLPAddCustomer.checkCreditStatus(leadList[0]), 'Pending Credit Review');
    }

    @isTest static void testAlertsHandler() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];
        BSST__c execRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        Partner_Alert__c partnerAlertRecord;
        String partnerId;
        String alertId;

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Active__c = true,
            Alert_Body__c = 'Test',
            Audience__c = 'Managers',
            Importance__c = '1');
        Partner_Alert__c execAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Active__c = true,
            Alert_Body__c = 'Test',
            Audience__c = 'Executives',
            Importance__c = '1');
        insert new List<Partner_Alert__c>{partnerAlert, execAlert};

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name
        FROM Partner_Alert_Filter__c
        WHERE Partner_Alert__r.Name = 'Test Alert'];

        List<User> managerList = new List<User>();
        List<User> executiveList = new List<User>();
        List<User> activeUsers = [
            SELECT Id, UserRole.Name, Contact.Sales_Representative__r.Id, Contact.Sales_Representative__r.Name
            FROM User
            WHERE Profile.Name IN ('Partner Community User (Custom)', 'Partner Community Login User (Custom)')
            AND IsActive = TRUE
            AND UserRoleId != NULL
        ];
        for (User user : activeUsers) {
            if (user.UserRole.Name.Contains('Manager')) {
                managerList.add(user);
            } else if (user.UserRole.Name.Contains('Executive')) {
                executiveList.add(user);
            }
        }
        System.assertEquals(managerList.size()+executiveList.size(), partnerAlertFilterList.size());

        System.runAs(partnerUser) {
            partnerAlertList = SLPAlertsHandler.getPartnerAlerts(partnerRecord.Id);
            System.assertEquals(1, partnerAlertList.size());
            alertId = String.valueOf(partnerAlertList.get(0).Id);
            partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
        }
        System.runAs(execUser) {
            alertId = String.valueOf(partnerAlertList.get(0).Id);
            partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
        }
        Test.stopTest();
    }

    @isTest static void testGetCustomerProducts() {
        List<Product2> productReturnList = new List<Product2>();
        Map<String, Lead> leadMap = new Map<String, Lead>();

        Test.startTest();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        for (Lead lead : [SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c,
        (SELECT Id, Adjusted_Income__c, Adjusted_DTI__c, LASERCA__Contact__c FROM LASERCA__Personal_Credit_Reports__r)
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm10Rate699' OR FirstName = 'coApplicantLead' LIMIT 2]) {
            leadMap.put(lead.FirstName, lead);
        }
        System.assertEquals('710', leadMap.get('leadMALoanTerm10Rate699').LASER_Credit_Score__c);

        System.runAs(partnerUser) {
            productReturnList = SLPCreditStatus.getCustomerProducts(leadMap.get('leadMALoanTerm10Rate699').Id);
            System.assertEquals(2, productReturnList.size());
            Product2 prod = SLPCreditStatus.getSelectedProduct(productReturnList[0].Id);
            System.assertEquals(prod.Name, 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%');

            Lead leadRecord = leadMap.get('leadMALoanTerm10Rate699');

            productReturnList.clear();
            productReturnList = SLPCreditStatus.getCustomerProducts(leadMap.get('coApplicantLead').Id);
            System.assertEquals(0, productReturnList.size());
        }
        List<LASERCA__Personal_Credit_Report__c> creditReportList = leadMap.get('coApplicantLead').LASERCA__Personal_Credit_Reports__r;
        creditReportList[0].Adjusted_Income__c = 500000;
        update creditReportList[0];

        System.runAs(partnerUser) {
            productReturnList.clear();
            productReturnList = SLPCreditStatus.getCustomerProducts(leadMap.get('coApplicantLead').Id);
            System.assertEquals(3, productReturnList.size());
        }

        for(LASERCA__Personal_Credit_Report__c creditReport : creditReportList) {
            if(creditReport.LASERCA__Contact__c == null) {
                creditReport.Adjusted_DTI__c = 20;
            }
        }
        creditReportList[0].Adjusted_Income__c = 0;
        update creditReportList;
        
        System.runAs(partnerUser) {
            productReturnList.clear();
            productReturnList = SLPCreditStatus.getCustomerProducts(leadMap.get('coApplicantLead').Id);
            System.assertEquals(3, productReturnList.size());
        }
        Test.stopTest();
    }

    @isTest static void testCreditStatus2() {
        Test.startTest();
        String partnerId;

        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
            Company = 'Cole Swain',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,
            LASERCA__Social_Security_Number__c = '000000001',
            Requested_Loan_Amount__c = 25000,
            Annual_Income_Currency__c = 150000,
            Credit_Check_Acknowledged__c = true,
            Privacy_Policy_Acknowledged__c = true,
            Automatic_Product_Assignment__c = true,
            Product_Program__c = 'BlueWave Solar Loan',
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true
        );
        insert newLead;

        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            SLPCreditStatus.searchLeads(null, newLead.Id);
            SLPCreditStatus.searchLeads('Test', newLead.Id);
        }
        Test.stopTest();
    }

    @isTest static void testCreditStatus() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
            Company = 'Cole Swain',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,
            LASERCA__Social_Security_Number__c = '000000001',
            Requested_Loan_Amount__c = 25000,
            Annual_Income_Currency__c = 150000,
            Credit_Check_Acknowledged__c = true,
            Privacy_Policy_Acknowledged__c = true,
            Automatic_Product_Assignment__c = true,
            Product_Program__c = 'BlueWave Solar Loan',
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true
        );
        insert newLead;

        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        System.runAs(partnerUser) {
            SLPCreditStatus.getLeads(null, partnerRecord.Id);
            SLPCreditStatus.getLeads(null, null);
            SLPCreditStatus.getCustomerProducts(lead.Id);
            SLPCreditStatus.searchLeads(null, newLead.Id);
            SLPCreditStatus.searchLeads('Test', newLead.Id);
        }
        Test.stopTest();
    }



    @isTest static void testCustomerHandlerPartThree() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Lead> leadList = new List<Lead>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        Test.startTest();

        leadList = getLeads();
        LoanHandler.createResidentialEquipment(leadList);
        LoanHandler.createLoan(leadList);

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];

        System.runAs(partnerUser) {
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loan.Id, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loan.Id, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(null, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(null, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(null, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loan.Id, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loan.Id, 'Test');
        }
        System.runAs(execUser) {
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loan.Id, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loan.Id, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(null, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(null, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(null, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loan.Id, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loan.Id, 'Test');
        }
        Test.stopTest();
    }

    @isTest static void testSaveCustomerInformationMethod() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Lead> leadList = new List<Lead>();

        String loanId;
        String equipmentId;

        leadList = getLeads();
        LoanHandler.createResidentialEquipment(leadList);
        LoanHandler.createLoan(leadList);

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        List<Loan__c> loanList = [SELECT Id, Name, Commencement_Datee__c, Estimated_Completion_Date__c, Requested_Loan_Amount__c  FROM Loan__c];

        List<Residential_Equipment__c> equipmentList = [SELECT Id, Lead__r.Id, Name, Generator_Nameplate_Capacity__c, Type_of_Module__c, Number_of_Modules__c,
            Type_of_Inverter__c, Number_of_Inverters__c, Mechanical_Installation_Date__c, Interconnection_date__c,
            Mechanically_Installed__c, Interconnected__c, Module_Model_Number__c, Module_Manufacturer__c,
            Inverter_Manufacturer__c, Inverter_Model_Number__c
        FROM Residential_Equipment__c];
        //Set the equipment name to a value greater than 80 characters for code coverage
        equipmentList.get(0).Module_Manufacturer__c = 'SolarEdgeSolarEdgeSolarEdgeSolarEdgeSolarEdge';
        equipmentList.get(0).Inverter_Manufacturer__c = 'SolarWorldSolarWorldSolarWorld';
        update equipmentList.get(0);

        loanId = String.valueOf(loanList.get(0).Id);
        equipmentId = String.valueOf(equipmentList.get(0).Id);
        Test.startTest();
        System.runAs(partnerUser) {
            SLPCustomerHandler.saveCustomerInformation(equipmentList.get(0), equipmentId, loanId, loanList.get(0));
        }
        System.runAs(execUser) {
            SLPCustomerHandler.saveCustomerInformation(equipmentList.get(0), equipmentId, loanId, loanList.get(0));
        }
        Test.stopTest();
    }

    @isTest static void testUserHelper() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPUserHelper.getPartnerId();
            SLPUserHelper.getPartnerLogo();
            SLPUserHelper.getBWCCId();
        }
        System.runAs(execUser) {
            SLPUserHelper.getPartnerId();
            SLPUserHelper.getPartnerLogo();
            SLPUserHelper.getBWCCId();
        }
        Test.stopTest();
    }

 

    @isTest static void testViewPreQualifiedRecords() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        System.runAs(execUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        Test.stopTest();
    }

    @isTest static void testSLPFileHandler() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

        SLPortal_Settings__c portalSetting = new SLPortal_Settings__c(  Name='SLPortal Settings',
            SREC_Opt_In_Quarters__c= 'Q1 2017,Q2 2017,Q3 2017,Q4 2017,Q1 2018,Q2 2018',
            Types_of_Documents_Available_for_Upload__c='Paystub, Tax Return (2015), MCEC Technical Confirmation, Home Owners Insurance');
        insert portalSetting;

        Residential_Equipment__c equipment = new Residential_Equipment__c(Name = 'testEquipment', OwnerId = partnerUser.Id);
        insert equipment;

        Attachment attach=new Attachment();
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.Body=bodyBlob;
        attach.ParentId=equipment.id;
        attach.Description = 'PTO Documentation';
        attach.OwnerId = partnerUser.Id;

        Test.startTest();

        
    }

  
    @isTest static void testErrorParsing() {
        System.assertEquals('CreditBureau - Invalid borrower first name',
            SLPAddCustomer.parseError('ERROR: E999 - CreditBureau - Invalid borrower first name'));

        System.assertEquals('SomethingElse - Invalid borrower first name',
            SLPAddCustomer.parseError('ERROR: A103 - SomethingElse - Invalid borrower first name'));

        System.assertEquals('WARN: ABC - Not Handled',
            SLPAddCustomer.parseError('WARN: ABC - Not Handled'));
    }

    @isTest static void testOrigination() {
        Test.startTest();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        List<Product2> products = [SELECT Id FROM Product2 WHERE IsActive = true AND Product_Type__c = 'Residential Loan' AND Require_Junctions_to_Enable__c = false];
        System.assertEquals(12, products.size());

        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        System.runAs(partnerUser) {
            System.assertEquals(new List<String>{'MA'}, SLPAddCustomer.getActiveStates());
            System.assertEquals('AvidiaBlueWave', SLPAddCustomer.getLenderOfRecord('MA'));
        }

        products = SLPAddCustomer.getProducts('MA');
        System.assertEquals(9, products.size());
        Test.stopTest();
    }

    @isTest static void testSendCommunitySolarApplication() {
        List<String> emailList = new List<String>();
        emailList.add('cswain@bluewavesolar.com');
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        System.runAs(partnerUser) {
            SLPCustomerHandler.sendCommunitySolarApplication(emailList);
            System.assertEquals(1, MessagingService.emailsSent.size());
        }
    }

    @isTest static void testGetCommunitySolarApplicationURL() {
        User partnerUser = [SELECT Id, Contact.Partner_Lookup__r.Id, Contact.Sales_Representative__r.Id FROM User WHERE Email = 'tropicole34@aol.com'];
        System.runAs(partnerUser) {
            SLPCustomerHandler.getCommunitySolarApplicationURL();
        }
    }

    @isTest static void testSaveAndWithdrawChange() {
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Lead lead = getLeads()[0];
        LoanHandler.createResidentialEquipment(new List<Lead>{lead});
        LoanHandler.createLoan(new List<Lead>{lead});

        Loan__c loan = [SELECT Id FROM Loan__c WHERE Lead__c = :lead.Id];
        System.runAs(execUser) {
            Residential_Equipment__c updatedRE = SLPCustomerHandler.saveChangeOrder(loan.Id,
                '{"number_of_modules__c":"24","module_manufacturer__c":"LG","module_model_number__c":"LG335",' +
                    '"number_of_inverters__c":"24","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"IQ6Plus",' +
                    '"commencement_datee__c":"04/30/2018","generator_nameplate_capacity__c":"8.04",' +
                    '"System_Cost__change":20000,' +
                    '"Number_of_Modules__change":"2","Module_Manufacturer__change":"LG","Module_Model_Number__change":"LG335",' +
                    '"Number_of_Inverters__change":"24","inverter_Manufacturer__change":"Enphase","Inverter_Model_Number__change":"IQ6Plus",' +
                    '"Commencement_Datee__change":"04/30/2018","Generator_Nameplate_Capacity__change":"8.04","Storage__change":true,' +
                    '"Storage_Grid_Hybrid__change":"Yes","Storage_Capacity__change":10,"Storage_Full_or_Partial_Home__change":"Full home backup",' +
                    '"Storage_Inverter_Manufacturer__change":"SolarEdge","Storage_Inverter_Model__change":"StorEdge 10kw",' +
                    '"Storage_Manufacturer__change":"Tesla","Storage_Model__change":"Powerwall"}');
            System.assertEquals('Requested', updatedRE.Loan__r.Lead__r.Change_Order_Status__c);
            Residential_Equipment__c withdrawnRE = SLPCustomerHandler.withdrawChangeOrder(loan.Id);
            System.assertEquals('Installer Withdrawn', withdrawnRE.Loan__r.Lead__r.Change_Order_Status__c);
        }
    }

    @isTest static void testSaveNoChangeRequired() {
        Test.startTest();
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];

        Lead lead;
        for (Lead l : getLeads()) {
            if (l.FirstName == 'NY') {
                lead = l;
                break;
            }
        }
        lead.CAP_Stage__c = 'NAV_Confirmations';
        Util.disableTrigger('Disable_LeadTrigger__c');
        update lead;
        Util.enableTrigger('Disable_LeadTrigger__c');

        System.assertEquals(lead.LastName, 'Test');
  
        LoanHandler.createResidentialEquipment(new List<Lead>{lead});
        LoanHandler.resetTriggerContext();
        LoanHandler.createLoan(new List<Lead>{lead});
        Loan__c loan = [SELECT Id FROM Loan__c WHERE Lead__c = :lead.Id];
        Util.printSOQLLimit('1');
        System.runAs(execUser) {
            Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
            Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

            Residential_Equipment__c re = SLPCustomerHandler.getCustomerInformation(loan.Id);
            System.assertEquals(null, re.Module_Manufacturer__c);

            Residential_Equipment__c updatedRE = SLPCustomerHandler.saveChangeOrder(loan.Id,
                '{"number_of_modules__c":"24","module_manufacturer__c":"LG","module_model_number__c":"LG335",' +
                    '"number_of_inverters__c":"24","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"IQ6Plus",' +
                    '"Estimated_Completion_Date__c":"04/30/2018","generator_nameplate_capacity__c":"8.04",' +
                    '"System_Cost__change":' + lead.Requested_Loan_Amount__c + ',' +
                    '"Number_of_Modules__change":2,"Module_Manufacturer__change":"LG","Module_Model_Number__change":"LG335",' +
                    '"Number_of_Inverters__change":24,"Inverter_Manufacturer__change":"Enphase","Inverter_Model_Number__change":"IQ6Plus",' +
                    '"Estimated_Completion_Date__change":"04/30/2018","Generator_Nameplate_Capacity__change":8.04,"Storage__change":true,' +
                    '"Storage_Grid_Hybrid__change":"Yes","Storage_Capacity__change":10,"Storage_Full_or_Partial_Home__change":"Full home backup",' +
                    '"Storage_Inverter_Manufacturer__change":"SolarEdge","Storage_Inverter_Model__change":"StorEdge 10kw",' +
                    '"Storage_Manufacturer__change":"Tesla","Storage_Model__change":"Powerwall"}');
            System.assertEquals(null, updatedRE.Loan__r.Lead__r.Change_Order_Status__c);
            re = SLPCustomerHandler.getCustomerInformation(loan.Id);
            System.assertEquals('LG', re.Module_Manufacturer__c);
            System.assertEquals('LG335', re.Module_Model_Number__c);
            System.assertEquals(2, re.Number_of_Modules__c);
            System.assertEquals('Enphase', re.Inverter_Manufacturer__c);
            System.assertEquals('IQ6Plus', re.Inverter_Model_Number__c);
            System.assertEquals(24, re.Number_of_Inverters__c);
            System.assertEquals(8.04, re.Generator_Nameplate_Capacity__c);
            System.assertEquals(10, re.Storage_Capacity__c);
            System.assertEquals(true, re.Storage_Grid_Hybrid__c);
            System.assertEquals('Full home backup', re.Storage_Full_or_Partial_Home__c);
            System.assertEquals('SolarEdge', re.Storage_Inverter_Manufacturer__c);
            System.assertEquals('Tesla', re.Storage_Manufacturer__c);
            System.assertEquals('StorEdge 10kw', re.Storage_Inverter_Model__c);
            System.assertEquals('Powerwall', re.Storage_Model__c);
        }
        Test.stopTest();
    }

    @isTest static void testMaxLoanAmount() {
        LASERCA__Personal_Credit_Report__c pcr = [
            SELECT Id, LASERCA__Lead__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__r.FirstName = 'NY'
            AND LASERCA__Lead__r.Requested_Loan_Amount__c = 25000
            AND LASERCA__Credit_Score_TransUnion__c = '790'
            AND Adjusted_Monthly_Personal_Debt__c = 100
            AND LASERCA__Lead__r.Annual_Income_Currency__c = 150000
        ];
        Lead lead;
        for (Lead l : getLeads()) {
            if (l.Id == pcr.LASERCA__Lead__c) {
                lead = l;
                break;
            }
        }
        LoanHandler.createLoan(new List<Lead>{lead});
        Loan__c loan = [SELECT Id FROM Loan__c WHERE Lead__c = :lead.Id];
        Decimal maxLoanAmount = SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2);
        System.assertEquals(73310.65, maxLoanAmount);
        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount - 1;
        update lead;
        Test.startTest();
        PCRApprovalHandler.noDelay = true;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pre-Qualified', lead.Status);

        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount + 10;
        update lead;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pending Credit Review', lead.Status);
    }

    @isTest static void testMaxLoanAmountFlexRate() {
        LASERCA__Personal_Credit_Report__c pcr = [
            SELECT Id, LASERCA__Lead__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__r.FirstName = 'NY'
            AND LASERCA__Lead__r.Requested_Loan_Amount__c = 25000
            AND LASERCA__Credit_Score_TransUnion__c = '790'
            AND Adjusted_Monthly_Personal_Debt__c = 100
            AND LASERCA__Lead__r.Annual_Income_Currency__c = 150000
        ];
        Product2 flexRate = LoanTestRecordWarehouse.getDefaultProduct('NY', 5.99, 10, 7, '750', '999', null);
        flexRate.First_Adjustment__c = 61;
        flexRate.Floor_Rate__c = 1;
        flexRate.Ceiling_Rate__c = 10;
        flexRate.Index_Rate_for_Adjustment__c = 'WSJ Prime Rate';
        flexRate.Margin_Over_Index_Rate__c = .5;
        flexRate.Maximum_Adjustment__c = 1;
        flexRate.Months_Between_Adjustment__c = 12;
        flexRate.DTI_After_Rate_Gross_Up__c = 2;
        insert flexRate;
        Index_Rate__c ir = new Index_Rate__c(
            Index_Rate_Type__c = 'WSJ Prime Rate',
            Index_Rate__c = 8
        );
        insert ir;

        Lead lead;
        for (Lead l : getLeads()) {
            if (l.Id == pcr.LASERCA__Lead__c) {
                lead = l;
                lead.Product__c = flexRate.Id;
                update lead;
                break;
            }
        }
        LoanHandler.createLoan(new List<Lead>{lead});
        Loan__c loan = [SELECT Id FROM Loan__c WHERE Lead__c = :lead.Id];
        Decimal maxLoanAmount = SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2);
        System.assertEquals(507112.94, maxLoanAmount);
        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount - 1;
        update lead;
        Test.startTest();
        PCRApprovalHandler.noDelay = true;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pre-Qualified', lead.Status);

        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount + 100;
        update lead;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pending Credit Review', lead.Status);

        flexRate.Maximum_Loan_Size__c = 60000;
        update flexRate;
        System.assertEquals(60000, SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2));
    }

    @isTest static void testMaxLoanAmountMSLP() {
        LASERCA__Personal_Credit_Report__c pcr = [
            SELECT Id, LASERCA__Lead__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__r.FirstName = 'DOER'
            AND LASERCA__Lead__r.Requested_Loan_Amount__c = 25000
            AND LASERCA__Credit_Score_TransUnion__c = '790'
            AND Adjusted_Monthly_Personal_Debt__c = 100
            AND LASERCA__Lead__r.Annual_Income_Currency__c = 150000
        ];

        Lead lead;
        for (Lead l : getLeads()) {
            if (l.Id == pcr.LASERCA__Lead__c) {
                lead = l;
                break;
            }
        }
        LoanHandler.createLoan(new List<Lead>{lead});
        Loan__c loan = [SELECT Id FROM Loan__c WHERE Lead__c = :lead.Id];
        Decimal maxLoanAmount = SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2);
        System.assertEquals(554202.39, maxLoanAmount);
        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount - 1;
        update lead;
        Test.startTest();
        PCRApprovalHandler.noDelay = true;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pre-Qualified', lead.Status);

        lead.Status = 'Ready for Credit Check';
        lead.Requested_Loan_Amount__c = maxLoanAmount + 100;
        update lead;
        update pcr;
        lead = [SELECT Id, Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Pending Credit Review', lead.Status);

        pcr.LASERCA__Credit_Score_TransUnion__c = '695';
        update pcr;
        System.assertEquals(497881.01, SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2));
        pcr.LASERCA__Credit_Score_TransUnion__c = '685';
        update pcr;
        System.assertEquals(441559.62, SLPCustomerHandler.getMaximumLoanAmount(loan.Id).setScale(2));

    }

    private static List<Lead> getLeads() {
        return [
            SELECT Id, Unfinished_Lead__c, Status, bs_Sales_ID__c,
                Product_line__c, FirstName, LastName, ConvertedOpportunityId, DOER_Solar_Loan__c, Loan_System_Information__c,
                Product__r.Loan_Interest_Rate__c, Loan_Financing_Fee__c, Requested_Loan_Amount__c, System_Cost__c,
                Partner_Lookup__c, LASERCA__Home_State__c, Product__c, Loan_Fee_1__c, Product__r.Loan_Interest_Only_Period__c
            FROM Lead
        ];
    }
}