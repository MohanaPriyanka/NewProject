@isTest
public without sharing class SLPControllersTestclass {
    @testSetup public static void setupTestData(){
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        Account accountRecord = new Account(Name = 'BlueWave Customer Care');
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
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true
            );
        List<Lead> leadList;

        System.assertEquals(SLPAddCustomer.getCreditCheckTimeout(), 60000);
        System.runAs(partnerUser) {
            SLPAddCustomer.addNewLeadRecord(newLead);

            leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
                        FROM Lead
                        WHERE LastName = 'Swain'];
            System.assertEquals(leadList.size(), 1);
            System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);

            SLPAddCustomer.pullCreditStatus(leadList[0]);

            // Laser Credit Access trigger should unset the pull credit report checkbox
            leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
                        FROM Lead
                        WHERE LastName = 'Swain'];
            System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);
        }
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
        for (User user : [SELECT Id, UserRole.Name, Contact.Sales_Representative__r.Id, Contact.Sales_Representative__r.Name
                          FROM User
                          WHERE Profile.Name IN ('Partner Community User (Custom)', 'Partner Community Login User (Custom)')
                          AND IsActive = true]) {
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
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];

        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();

        for (Lead lead : [SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c,
                          (SELECT Id, Adjusted_Income__c, Adjusted_DTI__c, LASERCA__Contact__c FROM LASERCA__Personal_Credit_Reports__r)
                          FROM Lead
                          WHERE FirstName = 'leadMALoanTerm10Rate699' OR FirstName = 'coApplicantLead' LIMIT 2]) {
            leadMap.put(lead.FirstName, lead);
        }
        System.assertEquals('710', leadMap.get('leadMALoanTerm10Rate699').LASER_Credit_Score__c);

        Test.startTest();
        System.runAs(partnerUser) {         
            productReturnList = SLPCreditStatus.getCustomerProducts(leadMap.get('leadMALoanTerm10Rate699').Id);
            System.assertEquals(2, productReturnList.size());
            Product2 prod = SLPCreditStatus.getSelectedProduct(productReturnList[0].Id);
            System.assertEquals(prod.Name, 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%');
        
            Lead leadRecord = leadMap.get('leadMALoanTerm10Rate699');            

            SLPCreditStatus.sendApplication(leadRecord.Id, 12);
            System.assertEquals(1, MessagingService.emailsSent.size());

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
            System.assertEquals(2, productReturnList.size());
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
            System.assertEquals(2, productReturnList.size());
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
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
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
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
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

    @isTest static void testCustomerHandlerUser() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'tropicole34@aol.com'];
        List<Lead> leadList = new List<Lead>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
        Residential_Equipment__c equipmentRecord;

        Test.startTest();

        leadList = [SELECT Id, Unfinished_Lead__c, Status, Bs_Sales_ID__c FROM Lead];
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id, Partner__c, Sales_Agent__c, 
                                  (SELECT Id, Name, Owner__c FROM Partner_Tasks__r WHERE Status__c = 'Pending' LIMIT 1) FROM Loan__c];
        update loanList;
        System.runAs(partnerUser) {
            SLPAllCustomersHandler.LoanRecords loanRecords = SLPAllCustomersHandler.getAllCustomers();
            System.assertEquals(3, loanRecords.completedLoans.size() + loanRecords.loansInProcess.size());
            SLPAllCustomersHandler.LeadRecords leadRecords = SLPAllCustomersHandler.getLeads();
            System.assertEquals(3, leadRecords.declinedApplicants.size() + leadRecords.pendingApplications.size());
            equipmentRecord = SLPCustomerHandler.getCustomerInformation(loanList[0].Id);
        }

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        System.runAs(partnerUser) {
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loanList[0].Id);
        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerExec() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'colematthewswain@gmail.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();

        leadList = [SELECT Id, Unfinished_Lead__c, Status FROM Lead];
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];
        System.runAs(partnerUser) {
            SLPAllCustomersHandler.LoanRecords loanRecords = SLPAllCustomersHandler.getAllCustomers();
            System.assertEquals(3, loanRecords.completedLoans.size() + loanRecords.loansInProcess.size());
            SLPAllCustomersHandler.LeadRecords leadRecords = SLPAllCustomersHandler.getLeads();
            System.assertEquals(3, leadRecords.declinedApplicants.size() + leadRecords.pendingApplications.size());
            equipmentRecord = SLPCustomerHandler.getCustomerInformation(loan.Id);
        }

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        System.runAs(partnerUser) {
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loan.Id);
        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerPartThree() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        User execUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();

        String loanId;

        Test.startTest();

        leadList = [SELECT Id, Unfinished_Lead__c, Status FROM Lead];

        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

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
        List<Product2> productList = new List<Product2>();

        String loanId;
        String equipmentId;
        Residential_Equipment__c equipment;

        leadList = [SELECT Id, Unfinished_Lead__c, Status FROM Lead];
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        List<Loan__c> loanList = [SELECT Id, Name, Commencement_Datee__c, Requested_Loan_Amount__c  FROM Loan__c];

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

    @isTest static void testSLPSendApplicationEmail() {
        if (SLPortal_Settings__c.getall().isEmpty()) {
            insert new SLPortal_Settings__c(Name = 'System',
                                            Require_IBLS_for_MSL_Loans__c = true);
        }
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        String emailTest;
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
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true
            );

        Test.startTest();

        System.runAs(partnerUser) {
            SLPAddCustomer.sendApplication(newLead, 25000);
        }
        SLPortal_Settings__c slportalSettings = SLPortal_Settings__c.getall().values()[0];
        slportalSettings.Require_IBLS_for_MSL_Loans__c = false;
        update slportalSettings;
        SLPAddCustomer.sendApplication(newLead, 25000);
        Test.stopTest();
        System.assertEquals(1, MessagingService.emailsSent.size());
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

        System.runAs(partnerUser) {
            List<SLPortal_Settings__c> customSetting = BlueWaveParent.getSLPortalCustomSetting();
            Id newFileId = BlueWaveParent.saveTheChunkWithDescription((String)equipment.Id, attach.Name, 'base64', '.png', 'PTO Documentation', '');
            BlueWaveParent.saveTheChunkWithDescription((String)equipment.Id, attach.Name, 'base64', '.png', 'PTO Documentation', newFileId);

            List<Attachment> attachList = [SELECT Id, Body
                                            FROM Attachment
                                            WHERE Id = : newFileId];

            System.Assert(attachList.size()>0);
            System.AssertEquals(customSetting.size(), 1);
        }
    }

    @isTest static void testSLPAddCoApplicant() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        String checkForCoAppsTest;
        String getCoAppLinkTest;
        String sendCoAppEmailTest;
        Contact checkaddCoApp;
        String leadId;
        String leadName;
        Integer i;
        Integer j;
        Date dob = date.newInstance(1990, 05, 13);

        Account coAppPlaceholder = new Account (Name = 'Co-Applicant Placeholder');
        insert coAppPlaceholder;

        Contact coAppInfo = new Contact(FirstName = 'Jordan',
                                        LastName = 'CoApplicant',
                                        Email = 'jpentaleri@bluewavesolar.com');
        Contact preExisting = new Contact(FirstName = 'Jordan',
                                          LastName = 'PreExist',
                                          Email = 'jpentaleri@bluewavesolar.com');
        insert preExisting;

        Contact newCoApp = new Contact(FirstName = 'Jordan',
                                       LastName = 'PreExist',
                                       Email = 'jpentaleri@bluewavesolar.com',
                                       LASERCA__Home_Address__c = '200 Street',
                                       LASERCA__Home_State__c = 'MA',
                                       LASERCA__Home_City__c = 'Boston',
                                       LASERCA__Home_Zip__c = '02114',
                                       Income__c = 40000,
                                       LASERCA__Co_Applicant_DOB__c = dob,
                                       LASERCA__Social_Security_Number__c = '000000001',
                                       Credit_Check_Acknowledged__c = TRUE,
                                       Privacy_Policy_Acknowledged__c = TRUE,
                                       LASERCA__Co_Applicant_Social_Security_Number__c  = '000000001');


        Test.startTest();
        List<Lead> leadList = [SELECT Id, Unfinished_Lead__c, Status FROM Lead];
        for (i=0 ; i < leadList.size(); i++) {
            leadList.get(i).Status = 'Unqualified';
            if ( i == 1 ) {
                leadList.get(i).CoApplicant_Contact__c = preExisting.Id;
            } else if ( i == 2 ) {
                leadList.get(i).Partner_Sent_Co_Signer_Link__c = TRUE;
            }
        }
        update leadList;
        for (j = 0; j < leadList.size(); j++) {
            leadId = leadList.get(j).Id;
            System.runAs(partnerUser) {
                if ( j == 1) {
                    checkForCoAppsTest = SLPAddCoApplicant.checkForCoApps(leadId);
                    System.assertEquals(checkForCoAppsTest, 'hasCoApp');
                    getCoAppLinkTest = SLPAddCoApplicant.getCoAppLink(coAppInfo, leadId);
                    System.assertNotEquals(checkForCoAppsTest, '');
                    sendCoAppEmailTest = SLPAddCoApplicant.sendCoAppEmail(newCoApp, leadList.get(j));
                    System.assertEquals(sendCoAppEmailTest, 'success');
                } else if ( j == 2) {
                    checkForCoAppsTest = SLPAddCoApplicant.checkForCoApps(leadId);
                    System.assertEquals(checkForCoAppsTest, 'sentEmail');
                    getCoAppLinkTest = SLPAddCoApplicant.getCoAppLink(coAppInfo, leadId);
                    System.assertNotEquals(checkForCoAppsTest, '');
                    checkaddCoApp = SLPAddCoApplicant.addNewCoApplicant(newCoApp, leadList.get(j));
                    System.assertNotEquals(checkaddCoApp.Lead__c, '');
                }
            }
        }
        Test.stopTest();
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
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        List<Product2> products = [SELECT Id FROM Product2 WHERE IsActive = true AND Require_Junctions_to_Enable__c = false];
        System.assertEquals(10, products.size());

        System.assertEquals(new List<String>{'MA', 'RI'}, SLPAddCustomer.getActiveStates());
        System.assertEquals('AvidiaBlueWave', SLPAddCustomer.getLenderOfRecord('MA'));

        products = SLPAddCustomer.getProducts('MA');
        System.assertEquals(9, products.size());
    }
}