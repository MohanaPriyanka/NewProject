@isTest
public without sharing class SLPControllersTestclass {
    @testSetup public static void setupTestUser(){
        Test.startTest();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community Login User (Custom)'];

        Account accountRecord = new Account(Name = 'BlueWave Customer Care');
        insert accountRecord;

        List<String> partnerSetUpIds = new List<String>();
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

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
        Test.stopTest();
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

    @isTest static void testAlertsHandlerUser() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        Partner_Alert__c partnerAlertRecord;
        String partnerId;
        String alertId;

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Active__c = true,
            Body__c = 'Test',
            Audience__c = 'Managers',
            Importance__c = '1');
        insert partnerAlert;

        Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
            Name = 'BlueWave Customer Care',
            Partner__c = partnerRecord.Id,
            Sales_Representative__c = salesRepRecord.Id,
            Partner_Alert__c = partnerAlert.Id);
        insert partnerAlertFilter;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            partnerAlertList = SLPAlertsHandler.getPartnerAlerts(partnerId);

            alertId = String.valueOf(partnerAlertList.get(0).Id);
            partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
        }
        Test.stopTest();
    }

    @isTest static void testAlertsHandlerExecutive() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        Partner_Alert__c partnerAlertRecord;
        String partnerId;
        String alertId;

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Active__c = true,
            Body__c = 'Test',
            Audience__c = 'Executives',
            Importance__c = '1');
        insert partnerAlert;

        Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
            Name = 'BlueWave Customer Care',
            Partner__c = partnerRecord.Id,
            Sales_Representative__c = salesRepRecord.Id,
            Partner_Alert__c = partnerAlert.Id);
        insert partnerAlertFilter;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            partnerAlertList = SLPAlertsHandler.getPartnerAlerts(partnerId);

            alertId = String.valueOf(partnerAlertList.get(0).Id);
            partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
        }
        Test.stopTest();
    }

    @isTest static void testGetCustomerProducts() {
        List<Product2> productReturnList = new List<Product2>();
        Map<String, Lead> leadMap = new Map<String, Lead>();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];

        List<Product2> productList = LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
        insert productList;

        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();

        for (Lead lead : [SELECT Id, LASER_Credit_Score__c, Email, FirstName,
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
            SLPCreditStatus.sendApplication(leadMap.get('leadMALoanTerm10Rate699').Id, prod, 12);
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
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

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

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            leadList = SLPCreditStatus.searchLeads(searchValue, newLead.Id);
            leadList.clear();
            leadList = SLPCreditStatus.searchLeads('Test', newLead.Id);
            leadList.clear();

        }
        Test.stopTest();
    }

    @isTest static void testCreditStatus1Exec() {
        Test.startTest();
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

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

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            LeadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            leadList = SLPCreditStatus.getLeads(searchValue, partnerId);
            leadList.clear();
            partnerId = null;
            leadList = SLPCreditStatus.getLeads(searchValue, partnerId);
            leadList.clear();

            leadId = String.valueOf(leadReturnList[0].Id);
            productReturnList = SLPCreditStatus.getCustomerProducts(leadId);

        }
        Test.stopTest();
    }

    @isTest static void testCreditStatus2Exec() {
        Test.startTest();
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

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

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            leadList = SLPCreditStatus.searchLeads(searchValue, newLead.Id);
            leadList.clear();
            leadList = SLPCreditStatus.searchLeads('Test', newLead.Id);
            leadList.clear();

        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerPartOne() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'tropicole34@aol.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;
        System.runAs(partnerUser) {
            SLPAllCustomersHandler.LoanRecords loanRecords = SLPAllCustomersHandler.getAllCustomers();
            System.assertEquals(3, loanRecords.completedLoans.size() + loanRecords.loansInProcess.size());
            SLPAllCustomersHandler.LeadRecords leadRecords = SLPAllCustomersHandler.getLeads();
            System.assertEquals(3, leadRecords.declinedApplicants.size() + leadRecords.pendingApplications.size());
            equipmentRecord = SLPCustomerHandler.getCustomerInformation(loanId);
        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerPartTwo() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'tropicole34@aol.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;
        System.runAs(partnerUser) {
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loanId);
        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerPartOneExec() {
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
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;
        System.runAs(partnerUser) {
            SLPAllCustomersHandler.LoanRecords loanRecords = SLPAllCustomersHandler.getAllCustomers();
            System.assertEquals(3, loanRecords.completedLoans.size() + loanRecords.loansInProcess.size());
            SLPAllCustomersHandler.LeadRecords leadRecords = SLPAllCustomersHandler.getLeads();
            System.assertEquals(3, leadRecords.declinedApplicants.size() + leadRecords.pendingApplications.size());
            equipmentRecord = SLPCustomerHandler.getCustomerInformation(loanId);
        }
        Test.stopTest();
    }
    @isTest static void testCustomerHandlerPartTwoExec() {
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
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;

        System.runAs(partnerUser) {
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loanId);
        }
        Test.stopTest();
    }

    @isTest static void testCustomerHandlerPartThree() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();

        String nullString = null;
        String loanId;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();

        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);


        System.runAs(partnerUser) {

            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(nullString, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, 'Test');

            List<Disbursal__c> disbursalUpdateList = [SELECT Id FROM Disbursal__c LIMIT 1];

            Test.stopTest();
        }
    }

    @isTest static void testCustomerHandlerPartThreeExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();

        String nullString = null;
        String loanId;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();

        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);

        System.runAs(partnerUser) {

            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(nullString, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, 'Test');

            List<Disbursal__c> disbursalUpdateList = [SELECT Id FROM Disbursal__c LIMIT 1];

            Test.stopTest();
        }
    }

    @isTest static void testSaveCustomerInformationMethod() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();

        String loanId;
        String equipmentId;
        Residential_Equipment__c equipment;

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
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
        Test.stopTest();
    }

    @isTest static void testSaveCustomerInformationMethodExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();

        String loanId;
        String equipmentId;
        Residential_Equipment__c equipment;


        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
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

        loanId = String.valueOf(loanList.get(0).Id);
        equipmentId = String.valueOf(equipmentList.get(0).Id);
        Test.startTest();
        System.runAs(partnerUser) {
            SLPCustomerHandler.saveCustomerInformation(equipmentList.get(0), equipmentId, loanId, loanList.get(0));
        }
        Test.stopTest();
    }

    @isTest static void testDashboardHandler() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        List<Decimal> dashboardWidgetsList = new List<Decimal>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c];
        String alertId;

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Audience__c = 'Users; Executives',
            Active__c = true,
            Body__c = 'Test',
            Importance__c = '1');
        insert partnerAlert;

        Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
            Name = 'BlueWave Customer Care',
            Partner__c = partnerRecord.Id,
            Partner_Alert__c = partnerAlert.Id);
        insert partnerAlertFilter;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

        Test.startTest();
        System.runAs(partnerUser) {
            SLPDashboardHandler.DashboardWidgets widgets = SLPDashboardHandler.getDashboardWidgets();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('All');
            partnerTaskList.clear();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('Provide All Customer Information');

            alertId = String.valueOf(partnerAlert.Id);
            SLPDashboardHandler.getPartnerAlerts();
            SLPDashboardHandler.acknowledgePartnerAlert(alertId);
            SLPDashboardHandler.partnerAlertRemindLater(alertId);
        }
        Test.stopTest();
    }

    @isTest static void testDashboardHandlerExec() {
        User partnerUser = [SELECT Id, Contact.Sales_Representative__r.Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Decimal> dashboardWidgetsList = new List<Decimal>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c];
        String alertId;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = 
            [SELECT Id, Name, Partner__r.Name 
             FROM Partner_Alert_Filter__c
             WHERE Sales_Representative__c = :partnerUser.Contact.Sales_Representative__r.Id];
        System.assertEquals(0, partnerAlertFilterList.size());

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert',
            Audience__c = 'Users; Executives',
            Active__c = true,
            Body__c = 'Test',
            Importance__c = '1');
        insert partnerAlert;

        partnerAlertFilterList = 
            [SELECT Id, Name, Partner__r.Name 
             FROM Partner_Alert_Filter__c
             WHERE Sales_Representative__c = :partnerUser.Contact.Sales_Representative__r.Id];

        System.assertEquals(1, partnerAlertFilterList.size());

        Test.startTest();
        System.runAs(partnerUser) {
            SLPDashboardHandler.DashboardWidgets widgets = SLPDashboardHandler.getDashboardWidgets();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('All');
            partnerTaskList.clear();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('Provide All Customer Information');

            alertId = String.valueOf(partnerAlert.Id);
            SLPDashboardHandler.getPartnerAlerts();
            SLPDashboardHandler.acknowledgePartnerAlert(alertId);
            SLPDashboardHandler.partnerAlertRemindLater(alertId);
        }
        Test.stopTest();
    }

    @isTest static void testDashboardStageChartHandler() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

        SLPDashboardStageChartHandler.StageChartResult result = new SLPDashboardStageChartHandler.StageChartResult();
        List<Product2> productList = new List<Product2>();
        List<Lead> leadList = new List<Lead>();
        List<Lead> leadUpdateList = new List<Lead>();

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        Partner_Task__c partnerTask = new Partner_Task__c(
            Name = 'Under BlueWave Review',
            Status__c = 'Pending',
            Lead__c = leadList.get(0).Id,
            Partner__c = partnerRecord.Id
            );
        insert partnerTask;

        System.runAs(partnerUser) {
            List<Partner_Task__c> partnerTaskList = [SELECT Id FROM Partner_Task__c];
            System.debug('partnerTaskListx' + partnerTaskList);
            result = SLPDashboardStageChartHandler.getAll();
        }
        Test.stopTest();
    }

    @isTest static void testDashboardStageChartHandlerExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

        SLPDashboardStageChartHandler.StageChartResult result = new SLPDashboardStageChartHandler.StageChartResult();
        List<Product2> productList = new List<Product2>();
        List<Lead> leadList = new List<Lead>();
        List<Lead> leadUpdateList = new List<Lead>();

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        Partner_Task__c partnerTask = new Partner_Task__c(
            Name = 'Under BlueWave Review',
            Status__c = 'Pending',
            Lead__c = leadList.get(0).Id,
            Partner__c = partnerRecord.Id
            );
        insert partnerTask;

        System.runAs(partnerUser) {
            List<Partner_Task__c> partnerTaskList = [SELECT Id FROM Partner_Task__c];
            System.debug('partnerTaskListx' + partnerTaskList);
            result = SLPDashboardStageChartHandler.getAll();
        }
        Test.stopTest();
    }

    @isTest static void testUserHelper() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        String testString;
        List<String> testStringList = new List<String>();
        Test.startTest();

        System.runAs(partnerUser) {
            testString = SLPUserHelper.getPartnerId();
            testStringList = SLPUserHelper.getPartnerLogo();
            testString = SLPUserHelper.getBWCCId();
        }
        Test.stopTest();
    }

    @isTest static void testUserHelperExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        String testString;
        List<String> testStringList = new List<String>();
        Test.startTest();

        System.runAs(partnerUser) {
            testString = SLPUserHelper.getPartnerId();
            testStringList = SLPUserHelper.getPartnerLogo();
            testString = SLPUserHelper.getBWCCId();
        }
        Test.stopTest();
    }

    @isTest static void testSLPSendApplicationEmail() {
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
        Test.stopTest();
    }

    @isTest static void testViewPreQualifiedRecordsExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        Test.stopTest();
    }

    @isTest static void testViewPreQualifiedRecordsUser() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        Test.stopTest();
    }

    @isTest static void testGetAnyUnseenRecordsExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPCustomerHandler.getAnyUnseenLeads();
        }
        Test.stopTest();
    }

    @isTest static void testGetAnyUnseenRecordsUser() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];
        Test.startTest();

        System.runAs(partnerUser) {
            SLPCustomerHandler.getAnyUnseenLeads();
        }
        Test.stopTest();
    }

    @isTest static void testSLPFileHandler() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

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
            SLPFileHandler.saveTheFile((String)equipment.Id, attach.Name, 'base64', '.png', 'PTO Documentation');
            SLPFileHandler.saveTheChunk((String)equipment.Id, attach.Name, 'base64', '.png', 'PTO Documentation', 'none');
            List<Attachment> describedFile = SLPFileHandler.getDescribedFile((String)equipment.Id, 'PTO Documentation');
            List<Attachment> recordedFile = SLPFileHandler.getRecordFiles(equipment.Id);
            SLPFileHandler.saveTheChunk((String)equipment.Id, attach.Name, 'base64', '.png', 'PTO Documentation', describedFile.get(0).Id);
            System.assertEquals(describedFile.get(0).Description, 'PTO Documentation');
            System.assertEquals(recordedFile.get(0).Description, 'PTO Documentation');
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
        List<Lead> leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
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
            system.debug(leadList.get(j));
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
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
        List<Product2> products = [SELECT Id FROM Product2 WHERE IsActive = true];
        System.assertEquals(7, products.size());

        System.assertEquals(new List<String>{'MA', 'RI'}, SLPAddCustomer.getActiveStates());
        System.assertEquals('AvidiaBlueWave', SLPAddCustomer.getLenderOfRecord('MA'));
    }
}
