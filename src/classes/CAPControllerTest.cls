@isTest
public with sharing class CAPControllerTest {
    @testSetup static void setupTestData(){
        LoanTestRecordWarehouse.partnerSetup();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
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
                Partner_Lookup__c = partner.Id,
                Product_Program__c = 'BlueWave Solar Loan',
                Bs_Sales_ID__c = salesRep.Id,
                Status = 'Ready for Credit Check',
                RecordTypeId = loanRT.Id);
        insert l;
        Test.startTest();
        System.assertEquals(CAPController.getCreditCheckTimeout(), 60000);
        System.assertEquals(null, CAPController.getLead(l.id, 'foo'));
        System.assertEquals('Tester', CAPController.getLead(l.id, 'test@tester.com').FirstName);
        System.assertEquals(null, CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);
        Lead leadClone = l.clone(true,false,false,false);
        leadClone.email = 'foo';
        leadClone.Application_Type__c = 'Joint';
        Boolean caughtException = false;
        try {
            CAPController.setAppType(leadClone);
        } catch (Util.BWException bwe) {
            caughtException = true;
        }
        System.assertEquals(true, caughtException);
        System.assertEquals(null, CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);
        l.Application_Type__c = 'Joint';
        CAPController.setAppType(l);
        System.assertEquals('Joint', CAPController.getLead(l.id, l.email).Application_Type__c);
        System.assertEquals('Co-Applicant', CAPController.getLead(l.id, l.email).Joint_Applicant_Type__c);

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
        System.assertEquals(pcrs.size(), 1);

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
                Loan_Term__c = 120,
                Product_Program__c = 'BlueWave Solar Loan',
                Pre_Approval_Form__c = true,
                Unfinished_Lead__c = true,
                Utility_Bill_Access_Acknowledged__c = true,
                Status = 'Ready for Credit Check',
                RecordTypeId = loanRT.Id);
        insert newLead;

        CAPController.pullCreditStatus(newLead);

        Test.stopTest();

        // Laser Credit Access trigger should unset the pull credit report checkbox
        List<Lead> leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c, Personal_Credit_Report__c
                               FROM Lead
                               WHERE LastName = 'Swain'];
        System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);

        // LCA should set pull credit once the future method fires
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id
                                                         FROM LASERCA__Personal_Credit_Report__c
                                                         WHERE LASERCA__Lead__c = :leadList[0].Id];
        System.assertEquals(pcrs.size(), 1);

        System.assertEquals(CAPController.checkCreditStatus(leadList[0]), 'Pending Credit Review');

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

        for (Lead lead : [SELECT Id, LASER_Credit_Score__c, Email, FirstName, Product__c,
                          (SELECT Id, Adjusted_Income__c, Adjusted_DTI__c, LASERCA__Contact__c FROM LASERCA__Personal_Credit_Reports__r)
                          FROM Lead
                          WHERE FirstName = 'leadMALoanTerm10Rate699' OR FirstName = 'coApplicantLead' LIMIT 2]) {
            leadMap.put(lead.FirstName, lead);
        }
        System.assertEquals('710', leadMap.get('leadMALoanTerm10Rate699').LASER_Credit_Score__c);

        Test.startTest();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('leadMALoanTerm10Rate699').Id);
        System.debug(LoggingLevel.ERROR, productReturnList);
        System.assertEquals(2, productReturnList.size());

        productReturnList.clear();
        productReturnList = CAPController.getCustomerProducts(leadMap.get('coApplicantLead').Id);
        System.assertEquals(0, productReturnList.size());

        List<LASERCA__Personal_Credit_Report__c> creditReportList = leadMap.get('coApplicantLead').LASERCA__Personal_Credit_Reports__r;
        creditReportList[0].Adjusted_Income__c = 500000;
        update creditReportList[0];

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
}
