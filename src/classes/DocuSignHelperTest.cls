@IsTest
public with sharing class DocuSignHelperTest {

    @TestSetup public static void setupTestData() {
        Test.loadData(System_Properties__c.SObjectType, 'TestRLSystemProperties');
        Util.disableTrigger('Disable_LoanTrancheTrigger__c');
        Util.disableTrigger('Disable_LeadTrigger__c');
        Util.disableTrigger('Disable_ContactTrigger__c');
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Util.disableTrigger('Disable_LoanTrigger__c');

        Test.loadData(Partner__c.SObjectType, 'TestRLPartner');
        Test.loadData(BSST__c.SObjectType, 'TestRLBSST');
        Test.loadData(Loan_Data__c.SObjectType, 'TestRLLoanData');
        Test.loadData(Loan_Traunch__c.SObjectType, 'TestRLLoanTraunch');
        Test.loadData(Product2.SObjectType, 'TestRLProduct');
        Test.loadData(Account.SObjectType, 'TestRLAccount');
        Test.loadData(Contact.SObjectType, 'TestRLContact');
        List<Opportunity> opportunities =
            Test.loadData(Opportunity.SObjectType, 'TestRLOpportunity');
        List<Lead> leads =
            Test.loadData(Lead.SObjectType, 'TestRLLead');
        List<LASERCA__Personal_Credit_Report__c> pcrs =
            Test.loadData(LASERCA__Personal_Credit_Report__c.SObjectType, 'TestRLPCR');
        Test.loadData(LASERCA__Trade_Accounts__c.SObjectType, 'TestRLTradeAccounts');
        Test.loadData(Loan__c.SObjectType, 'TestRLLoan');
        Test.loadData(Residential_Equipment__c.SObjectType, 'TestRLResidentialEquipment');
        List<Partner_Task__c> partnerTasks =
            Test.loadData(Partner_Task__c.SObjectType, 'TestRLPartnerTask');
        Test.loadData(dsfs__DocuSign_Status__c.SObjectType, 'TestRLDocuSignStatus');
        Test.loadData(dsfs__DocuSign_Recipient_Status__c.SObjectType, 'TestRLDocuSignRecipient');

        mapPCRtoLead(pcrs);
        mapPCRAndLeadToOpp(leads, pcrs, opportunities);
        setPartnerTaskParentAndUniqueId(partnerTasks);

        Util.enableTrigger('Disable_LoanTrancheTrigger__c');
        Util.enableTrigger('Disable_LeadTrigger__c');
        Util.enableTrigger('Disable_ContactTrigger__c');
        Util.enableTrigger('Disable_OpportunityTrigger__c');
        Util.enableTrigger('Disable_LoanTrigger__c');
    }

    private static void mapPCRAndLeadToOpp(List<Lead> leads, List<LASERCA__Personal_Credit_Report__c> pcrs, List<Opportunity> opportunities) {
        Map<Id, Lead> oppIdToLeadMap = new Map<Id, Lead>();
        for (Lead lead : leads) {
            if (lead.ConvertedOpportunityId != null) {
                oppIdToLeadMap.put(lead.ConvertedOpportunityId, lead);
            }
        }
        Map<Id, LASERCA__Personal_Credit_Report__c> leadToPCRMap = new Map<Id, LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            leadToPCRMap.put(pcr.LASERCA__Lead__c, pcr);
        }
        for (Opportunity opp : opportunities) {
            opp.Lead__c = oppIdToLeadMap.get(opp.Id).Id;
            if (opp.Lead__c != null) {
                opp.Lead_ID__c = ((String) opp.Lead__c).left(15);
            }
            opp.Personal_Credit_Report2__c = leadToPCRMap.get(opp.Lead__c).Id;
        }
        update opportunities;
    }

    private static void setPartnerTaskParentAndUniqueId(List<Partner_Task__c> partnerTasks) {
        Map<Id, Partner_Task__c> partnerTaskMap = new Map<Id, Partner_Task__c>();
        for (Partner_Task__c task : partnerTasks) {
            partnerTaskMap.put(task.Progress_Bar_Name__c, task);
        }
        for (Partner_Task__c task : partnerTasks) {
            Id leadId = task.Lead__c;
            if (leadId == null) {
                leadId = getParentTaskLead(task, partnerTaskMap);
            }
            task.Unique_ID__c = task.Unique_ID__c.replace('LeadId', leadId);
            if (task.Comments__c != null) {
                task.Parent_Task__c = partnerTaskMap.get(task.Comments__c).Id;
            }
        }
        update partnerTasks;
    }

    private static Id getParentTaskLead(Partner_Task__c task, Map<Id, Partner_Task__c> partnerTaskMap) {
        System.assertNotEquals(null, task.Comments__c,
            'A task with no lead is a subtask, which should have a parent task Id in the Comments__c field for loading');
        Partner_Task__c parentTask = partnerTaskMap.get(task.Comments__c);
        if (parentTask.Lead__c != null) {
            return parentTask.Lead__c;
        } else {
            return getParentTaskLead(parentTask, partnerTaskMap);
        }
    }

    private static void mapPCRtoLead(List<LASERCA__Personal_Credit_Report__c> pcrs) {
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap = new Map<Id, LASERCA__Credit_Report_Log__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            LASERCA__Credit_Report_Log__c crl = new LASERCA__Credit_Report_Log__c(
                LASERCA__Personal_Credit_Report__c = pcr.Id,
                LASERCA__Status__c = 'Completed'
            );
            triggerNewMap.put(pcr.Id, crl);
        }
        MapPCRtoLeadHandler.mapPCRtoLead(triggerNewMap, null);
    }

    @IsTest
    static void testLoanCreationAndUpdate() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        Lead lead = new Lead(
            Id = opp.Lead__c,
            Change_Order_Status__c = 'Customer Authorized'
        );
        update lead;
        // This should void the existing package and create a new one
        Test.stopTest();
        // We can't check DocuSign_Status__c results here, because DocuSign might not have written back to Salesforce
        // yet. So Partner Task assertions is the best we can do.
        System.assertEquals(1, DocuSignHelper.oppsToResend.size());
        System.assertEquals(1, DocuSignHelper.envelopesToVoid.size());
        System.assertEquals(1, DocuSignHelper.oppLoansSent.size());

        opp = [
            SELECT Id, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r),
            (SELECT Id, Status__c, Completion_Date__c FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement'))
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals('Sent', opp.Contract_Status__c);
        System.assertEquals(null, opp.Partner_Sales_Agreement_Status__c);
        System.assertEquals(2, opp.Partner_Tasks__r.size());
        System.assertEquals('Pending', opp.Partner_Tasks__r[0].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[0].Completion_Date__c);
        System.assertEquals('Pending', opp.Partner_Tasks__r[1].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[1].Completion_Date__c);
    }

    @IsTest
    static void testVoidFromProcessBuilder() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        // There shouldn't be any errors when starting
        System.assertEquals(0, errors.size());
        DocuSignVoid_Invocable.VoidRequest voidRequest = new DocuSignVoid_Invocable.VoidRequest();
        voidRequest.envelopeId = opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c;
        voidRequest.reason = 'Test void reason';
        DocuSignVoid_Invocable.voidPackages(new List<DocuSignVoid_Invocable.VoidRequest>{voidRequest});
        Test.stopTest();

        // Make sure voidPackages() didn't run into any errors. Because DocuSign logs back into the instance to update
        // the void status, and that doesn't happen since it's mocked, and simulating it in the mock would be misleading
        // since the update happens in a separate transaction at a later point in time, we don't check anything else
        // except that the call was made successfully.
        errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errors.size());
    }

    @IsTest
    static void testVoidCalloutException() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        DocuSignVoid_Invocable.VoidRequest voidRequest = new DocuSignVoid_Invocable.VoidRequest();
        voidRequest.envelopeId = opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c;
        voidRequest.reason = 'CalloutException';
        DocuSignVoid_Invocable.voidPackages(new List<DocuSignVoid_Invocable.VoidRequest>{voidRequest});
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Method__c, Message__c FROM Error_Log__c];
        // There should be one error since the future method catches CalloutException
        System.assertEquals(1, errors.size());
        // And it should be the CalloutExcpetion message
        System.assertEquals('Callout Exception caught voiding envelope', errors[0].Message__c.left(41));
    }

    @IsTest
    static void testVoidChildren() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];

        dsfs__DocuSign_Status__c envelopeStatus = [
            SELECT Id, dsfs__Envelope_Status__c
            FROM dsfs__DocuSign_Status__c
            WHERE dsfs__DocuSign_Envelope_ID__c = : opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c
            LIMIT 1
        ];

        System.assertNotEquals('Voided', envelopeStatus.dsfs__Envelope_Status__c);

        List<dsfs__DocuSign_Recipient_Status__c> recipientStatuses = [
            SELECT Id, dsfs__Recipient_Status__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__Parent_Status_Record__c = : envelopeStatus.Id
        ];

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : recipientStatuses) {
            System.assertNotEquals('Voided', recipientStatus.dsfs__Recipient_Status__c);
        }

        Test.startTest();
        envelopeStatus.dsfs__Envelope_Status__c = 'Voided';

        // DocuSign void transactions look like:
        // 10/12/2018 | 9:10:11 am
        // Salesforce attempt update ID: a0S210000007EnVEAU, table: dsfs__DocuSign_Status__c, fields:
        // 10/12/2018 | 9:10:14 am
        // Salesforce query: "select Id from dsfs__DocuSign_Recipient_Status__c where dsfs__DocuSign_Recipient_Id__c=
        // 10/12/2018 | 9:10:14 am
        // Salesforce attempt update ID: a0Q21000001YKHoEAO, table: dsfs__DocuSign_Recipient_Status__c, fields:
        update envelopeStatus;
        update recipientStatuses;

        Test.stopTest();

        recipientStatuses = [
            SELECT Id, dsfs__Recipient_Status__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__Parent_Status_Record__c = : envelopeStatus.Id
        ];

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : recipientStatuses) {
            System.assertEquals('Voided', recipientStatus.dsfs__Recipient_Status__c);
        }
    }

    @IsTest
    static void testResendSubscriptionContracts() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();

        System_Properties__c sysProp = systemProperties[0];
        sysProp.DocuSign_API_Account_ID__c = '123';
        sysProp.DocuSign_Customer_Care_User__c = '123@123.com';
        sysProp.DocuSign_Guest_User__c = '123@345.com';
        sysProp.DocuSign_Guest_User_Credential__c = '234234';
        sysProp.DocuSign_Integrator_Key__c = '123123-123123';
        update sysProp;

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{nationalGrid};

        Utility_NMC_Tariff__c nmcRate =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = 1,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2(
            Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Monthly_Late_Fee__c = 1
        );
        insert csProduct;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = nationalGrid.Id,
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

        Lead lead = new Lead(
            LastName = 'Chan',
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
            System_Assignment__c = 'Automatic - Assignment Order'
        );
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
            System_Assignment__c = 'Automatic - Assignment Order'
        );
        insert lead2;

        LASERCA__Personal_Credit_Report__c pcr = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(
            new LASERCA__Personal_Credit_Report__c(
                LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700'
            ),
            true
        );

        LASERCA__Personal_Credit_Report__c pcr2 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(
            new LASERCA__Personal_Credit_Report__c(
                LASERCA__Lead__c = lead2.Id,
                LASERCA__Credit_Score_TransUnion__c = '700'
            ),
            true
        );
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
        Test.setMock(WebServiceMock.class, new DocuSignHelperTest.DocuSignTimeoutMock());
        Test.setMock(HttpCalloutMock.class, new DocuSignHelperTest.DocuSignTimeoutMock());

        List<Id> idList = new List<Id>();
        List<Opportunity> oppList = [
            SELECT Id, Name, Parent_Account_Name__c, Salesperson_Email__c,
                Sales_tag__c, Application_Type__c,
                Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c,
                Docusign_Template__c, Shared_Solar_System__r.Name,
                AccountId, Shared_Solar_System__c
            FROM Opportunity
            WHERE Lead__c = :lead.Id
        ];
        System.assertEquals(1, oppList.size());
        idList.add(oppList[0].Id);

        List<AsyncApexJob> queuedJobsBefore = [
            SELECT Id, Status, NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
        ];

        DocuSignHelper.sendCSPackage(oppList[0],1,1);
        Test.stopTest();

        List<AsyncApexJob> queuedJobsAfter = [
            SELECT Id, Status, NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
        ];

        // We'll retry sending a contract up to 3 times before stopping
        System.assertNotEquals(queuedJobsBefore.size(), queuedJobsAfter.size());
        System.assertEquals(0, queuedJobsBefore.size());
        System.assertNotEquals(0, queuedJobsAfter.size());
        // This should be the queued job from DocuSignHelper.sendCSPackage. As of inline Docusign support in the CSAP,
        // Lead conversion no longer sends contracts automatically
        System.assert(queuedJobsAfter.size() == 1, 'Should have queued jobs to send');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
        ];

        System.assert(errorLogs.size() == 1, 'We should have 1 message that logs that the Opp is sending, plus AutoRetry messages');
        // the first error log is from DocuSignHelper.sendCSPackageFuture
        System.assertEquals('DocuSignHelper', errorLogs[0].Class__c);
        System.assertEquals('AutoRetryContractSend', errorLogs[0].Method__c);
    }

    @IsTest
    static void testEmbeddedContractSend() {
        Lead lead = setupTestLead('complete');

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        String callbackURL = CSAPController.sendEmbeddedContract(lead);
        System.assert(callbackURL.contains('success'));
        Test.stopTest();
    }

    @IsTest
    static void testEmbeddedContractException() {
        Lead lead = setupTestLead('timeout');

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        String callbackURL = CSAPController.sendEmbeddedContract(lead);
        // If we hit an exception, we expect it to be handled and for the callback URL to be the exception one
        System.assert(callbackURL.contains('exception'));
        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Exceeded maximum time allotted for callout'));
        Test.stopTest();
    }

    private static Lead setupTestLead(String email) {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();

        System_Properties__c sysProp = systemProperties[0];
        sysProp.DocuSign_API_Account_ID__c = '123';
        sysProp.DocuSign_Customer_Care_User__c = '123@123.com';
        sysProp.DocuSign_Guest_User__c = '123@345.com';
        sysProp.DocuSign_Guest_User_Credential__c = '234234';
        sysProp.DocuSign_Integrator_Key__c = '123123-123123';
        update sysProp;

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            nationalGrid
        };

        Utility_NMC_Tariff__c nmcRate = new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = 1,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()
        );
        insert nmcRate;

        Product2 csProduct = new Product2(
            Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Monthly_Late_Fee__c = 1
        );
        insert csProduct;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
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

        Account parentAccount = new Account(Name = 'Parent Account', Client_Brand_Key__c = 'BluewaveLogo');
        insert parentAccount;

        Lead lead = new Lead(
            LastName = 'Chan',
            FirstName = 'Joey',
            Email = email + '@email.com',
            Electricity_Provider__c = 'National Grid',
            Utility_relationship__c = nationalGrid.Id,
            LoadZone__c = 'WCMA',
            Company = 'Cloud Jedi',
            Status = 'Qualified',
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Custom_ID__c = 'partner',
            System_Assignment__c = 'Automatic - Assignment Order',
            Parent_Account__c = parentAccount.Id
        );
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = (LASERCA__Personal_Credit_Report__c) TestFactory.createSObject(
            new LASERCA__Personal_Credit_Report__c(
                LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700'
            ),
            true
        );

        lead.Personal_Credit_Report__c = pcr.Id;
        lead.Status = 'Qualified';
        update lead;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = lead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Joey Chan'
        );
        insert ual;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        return lead;
    }

    public class DocuSignTimeoutMock implements WebServiceMock, HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Exceeded maximum time allotted for callout');
            String endpoint = req.getEndpoint();

            // Create a fake response
            if (endpoint.contains('error')) {
                return DocuSignAPIMockImpl.handleError();
            } else if (endpoint.contains('signing_groups')) {
                return DocuSignAPIMockImpl.handleGetSigningGroup();
            } else if (endpoint.contains('')) {
                return DocuSignAPIMockImpl.handleLogin();
            } else {
                return null;
            }
        }

        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Exceeded maximum time allotted for callout');
            if(request instanceOf DocuSignAPI.AcknowledgeAuthoritativeCopyExport_element) {
                response.put( 'response_x', new DocuSignAPI.AcknowledgeAuthoritativeCopyExportResponse_element());
            }
            else if(request instanceOf DocuSignAPI.CreateEnvelopeFromTemplatesAndForms_element) {
                DocuSignAPI.CreateEnvelopeFromTemplatesAndFormsResponse_element responseX =
                    new DocuSignAPI.CreateEnvelopeFromTemplatesAndFormsResponse_element();
                responseX.CreateEnvelopeFromTemplatesAndFormsResult = new DocuSignAPI.EnvelopeStatus();
                responseX.CreateEnvelopeFromTemplatesAndFormsResult.Status = 'Created';
                responseX.CreateEnvelopeFromTemplatesAndFormsResult.EnvelopeID = 'DummyID';
                response.put( 'response_x', responseX);
                throw e;
            }
            else if(request instanceOf DocuSignAPI.RequestTemplateWithDocumentFields_element) {
                DocuSignAPI.RequestTemplateWithDocumentFieldsResponse_element templateResponse =
                    new DocuSignAPI.RequestTemplateWithDocumentFieldsResponse_element();
                templateResponse.RequestTemplateWithDocumentFieldsResult =
                    new DocuSignAPI.EnvelopeTemplate();
                templateResponse.RequestTemplateWithDocumentFieldsResult.Envelope =
                    new DocuSignAPI.Envelope();
                templateResponse.RequestTemplateWithDocumentFieldsResult.Envelope.Recipients =
                    new DocuSignAPI.ArrayOfRecipient();
                templateResponse.RequestTemplateWithDocumentFieldsResult.Envelope.Recipients.Recipient =
                    new List<DocuSignAPI.Recipient>();
                DocuSignAPI.Recipient recipient = new DocuSignAPI.Recipient();
                recipient.RoleName = 'Signer 1';
                templateResponse.RequestTemplateWithDocumentFieldsResult.Envelope.Recipients.Recipient.add(recipient);
                response.put( 'response_x', templateResponse);
            }
        }
    }
}