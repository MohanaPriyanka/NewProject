/**
 * @description Created by SarahRenfro on 5/22/2019.
 */
@IsTest
public class CSQualificationTestclass {

    @TestSetup public static void setupTestData() {
        Id partnerAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId();
        Account partnerAccount = new Account(
            Name = 'Mass Renewables',
            State_Market__c = 'MA',
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP',
            RecordTypeId = partnerAccountRTID
        );
        insert partnerAccount;

        Partner__c partner = new Partner__c(
            Name = 'Mass Renewables',
            Email__c = 'massRenewables@test.com',
            Account__c = partnerAccount.Id
        );
        insert partner;

        partnerAccount.Partner__c = partner.Id;
        update partnerAccount;

        TestFactory.setDefaultCSPartner(partner.Id);

        BSST__c salesRep = new BSST__c(
            Name = 'Mr. Sales',
            Partner__c = partner.Id,
            Email__c = 'martz@testemail.com');
        insert salesRep;

        partner.Default_Sales_Rep__c = salesRep.Id;
        update partner;

        Product2 vderProduct = new Product2(
            Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1
        );
        insert vderProduct;

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '1234'
        );
        Utility__c central = new Utility__c(
            Name = 'Central Hudson Gas and Electric',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '5678'
        );
        Utility__c rge = new Utility__c(
            Name = 'Rochester Gas and Electric',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '2468'
        );
        insert new List<Utility__c>{
            nyseg, central, rge
        };

        Load_U__c loadZone = new Load_U__c (
            Name = '12345',
            LZ__c = 'Hudson Valley',
            Town__c = 'Albany'
        );
        Load_U__c loadZone2 = new Load_U__c(
            Name = '56789',
            LZ__c = 'Mohawk Valley'
        );
        Load_U__c loadZone3 = new Load_U__c(
            Name = '24680',
            LZ__c = 'Upstate'
        );
        insert new List<Load_U__c>{
            loadZone, loadZone2, loadZone3
        };

        ZipCode_Utility_Junction__c junction1 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = loadZone.Id,
            Utility__c = nyseg.Id
        );
        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = loadZone2.Id,
            Utility__c = central.Id
        );
        ZipCode_Utility_Junction__c junction3 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = loadZone3.Id,
            Utility__c = rge.Id
        );

        insert new List<ZipCode_Utility_Junction__c>{
            junction1, junction2, junction3
        };

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Albany Post Rd',
            Service_Territory__c = 'Hudson Valley',
            Service_Territories__c = 'Hudson Valley',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nyseg.Id,
            Public__c = true,
            Stage__c = 'Acquisition',
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Product__c = vderProduct.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_FICO__c = true,
            Available_SMB_Underwriting_Method_Docs__c = true,
            RiskCalc_Minimum__c = 'C'
        );
        Shared_Solar_System__c sssWithLowCreditRequirement = sss1.clone();
        sssWithLowCreditRequirement.Credit_Score_Requirement__c = 100;
        sssWithLowCreditRequirement.Utility__c = central.Id;
        insert new List<Shared_Solar_System__c>{
            sss1, sssWithLowCreditRequirement
        };
        insert SharedSolarSystemsTest.getPartnerEligibilities(sss1, partnerAccount);

        Lead resiLead = new Lead(
            FirstName = 'Switch',
            LastName = 'Testcase',
            Email = 'test@email.com',
            MobilePhone = '1231231234',
            Company = 'Post Testcase',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_State__c = 'NY',
            LASERCA__Home_Zip__c = '12345',
            Street = '55 Boston St',
            City = 'Albany',
            State = BlueWaveParent.convertAbbreviationToState('NY'),
            PostalCode = '12345',
            Parcel_Zip__c = '12345',
            Application_Source_Phase_1__c = 'Switch without Partner',
            LeadSource = 'Switch',
            Product_line__c = 'Community Solar',
            Product__c = vderProduct.Id,
            LoadZone__c = loadZone.LZ__c,
            Utility_relationship__c = nyseg.Id,
            Phone = '1231231234',
            Customer_type__c = 'Residential',
            Status = 'Sales Qualified',
            Partner_Lookup__c = partner.Id,
            Moody_s_Risk_Calc__c = 'Baa1'
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        resiLead.setOptions(dmo);
        insert resiLead;
    }

    @IsTest
    public static void testCheckCSQualification() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        pullCreditForLead(lead.Id, 'High FICO');
        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Moody_s_Risk_Calc__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('Qualified', checkLead.Status, 'Lead status should be Qualified');
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c, 'Lead should have an attached personal credit report');
        System.assertEquals('700', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score__c, 'Credit score on lead personal credit report should be 700');
    }

    @IsTest
    public static void testUnqualifiedLead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Utility__c central = [SELECT Id FROM Utility__c WHERE Name = 'Rochester Gas and Electric' LIMIT 1];

        lead.Utility_relationship__c = central.Id;
        update lead;

        LASERCA__Credit_Report_Log__c crl = pullCreditForLead(lead.Id, 'High FICO');
        // LASERCA can do multiple updates to Credit Report Logs (Insert -> Update with a PCR -> Update to be Complete ->
        // post complete update), but we don't want to send multiple unqualified emails when that happens.
        update crl;

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Moody_s_Risk_Calc__c, Unqualified_due_to_FICO__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('Unqualified', checkLead.Status, 'Lead status should be unqualified');
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c, 'Lead should have an attached personal credit report');
        System.assertEquals('700', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score__c, 'Credit score on lead personal credit report should be 700');
        System.assertEquals(false, checkLead.Unqualified_due_to_FICO__c, 'Lead should not be unqualified due to FICO');
    }

    @IsTest
    public static void testUnqualifiedLeadDueToNoOpenSystems() {
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Open__c = TRUE
        ];
        // With all systems closed, leads should be be unqualified due to FICO
        for (Shared_Solar_System__c sharedSolarSystem : sharedSolarSystems) {
            sharedSolarSystem.Open__c = false;
        }
        update sharedSolarSystems;

        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Utility__c central = [SELECT Id FROM Utility__c WHERE Name = 'Central Hudson Gas and Electric' LIMIT 1];

        lead.Utility_relationship__c = central.Id;
        update lead;

        LASERCA__Credit_Report_Log__c crl = pullCreditForLead(lead.Id, 'High FICO');
        // LASERCA can do multiple updates to Credit Report Logs (Insert -> Update with a PCR -> Update to be Complete ->
        // post complete update), but we don't want to send multiple unqualified emails when that happens.
        update crl;

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Moody_s_Risk_Calc__c, Unqualified_due_to_FICO__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('Unqualified', checkLead.Status, 'Lead status should be unqualified');
        System.assertEquals(false, checkLead.Unqualified_due_to_FICO__c, 'Lead should not be unqualified due to FICO');
        System.assertEquals(1, MessagingService.emailsSent.size(),
            'Expected CSQualificationService to send one email that we were not able to approve the application');
    }

    @IsTest
    public static void testNoPCRMatchSwitchLead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        lead.Application_Complete_Date__c = System.today();
        update lead;

        Test.startTest();
        pullCreditForLead(lead.Id, 'No Match');
        Test.stopTest();

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Moody_s_Risk_Calc__c, (
                SELECT Id
                FROM LASERCA__Personal_Credit_Reports__r
            ), (
                SELECT Id, LASERCA__Personal_Credit_Report__c
                FROM LASERCA__Credit_Report_Logs__r
            )
            FROM Lead
            WHERE Id = :lead.Id
        ];

        System.assertEquals('Qualified', checkLead.Status, 'Lead status should be Qualified');
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c, 'Lead should have an attached personal credit report');
        System.assertEquals('9999', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score__c, 'Credit score on lead personal credit report should be 9999');
        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(lead).size(), 'QC for No Match PCRs should only be created for completed SSF leads');
        System.assertEquals(1, checkLead.LASERCA__Credit_Report_Logs__r.size(), 'There should only be one Credit Report Log after pulling credit');
        System.assertEquals(checkLead.Personal_Credit_Report__c, checkLead.LASERCA__Credit_Report_Logs__r[0].LASERCA__Personal_Credit_Report__c,
            'The CreditReportLog should have the No Match Credit Report attached to it that is found on the Lead');
        System.assertEquals(1, checkLead.LASERCA__Personal_Credit_Reports__r.size(),
            'Expected the CreditReportLogTrigger to create one No Match PCR if the CRL has an error status');
    }

    @IsTest
    public static void testLowFico() {
        Lead lead = [SELECT Id, Name FROM Lead LIMIT 1];

        Test.startTest();
        pullCreditForLead(lead.Id, 'Low FICO');
        Test.stopTest();

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c, Moody_s_Risk_Calc__c,
                Unqualified_due_to_FICO__c
            FROM Lead
            WHERE Id = :lead.Id
        ];

        System.assertEquals('Unqualified', checkLead.Status, 'Lead status should be Unqualified');
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c, 'Lead should have an attached personal credit report');
        System.assertEquals('200', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score__c, 'Credit score on lead personal credit report should be 200');
        System.assertEquals(true, checkLead.Unqualified_due_to_FICO__c, 'Lead should be flagged as Unqualified due to FICO');
        System.assertEquals(1, MessagingService.emailsSent.size(),
            'Expected CSQualificationService to send one email that we were not able to approve the application');
        Messaging.SingleEmailMessage sentEmail = (Messaging.SingleEmailMessage) MessagingService.emailsSent[0];
        System.assertNotEquals(null, sentEmail, 'ACN should be automatically sent to customer');
        System.assert(!sentEmail.htmlBody.contains('{!Lead.FirstName}'), 'Merge fields should be replaced with data from record');
    }

    @IsTest
    // Some reports like a0F5b00000dh0FuEAI don't get a FICO because of
    // SC3 - FILE NOT SCORED BECAUSE SUBJECT DOES NOT HAVE SUFFICIENT CREDIT
    // in which case they should be handled like a NO MATCH
    public static void testNoFico() {
        Lead lead = [SELECT Id, Name FROM Lead LIMIT 1];

        Test.startTest();
        pullCreditForLead(lead.Id, 'No FICO');
        Test.stopTest();

        Lead checkLead = [
            SELECT Id, Status, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Credit_Score__c,
                Moody_s_Risk_Calc__c, (
                SELECT Id
                FROM LASERCA__Personal_Credit_Reports__r
            ), (
                SELECT Id, LASERCA__Personal_Credit_Report__c
                FROM LASERCA__Credit_Report_Logs__r
            )
            FROM Lead
            WHERE Id = :lead.Id
        ];

        System.assertEquals('Qualified', checkLead.Status, 'Lead status should be Qualified');
        System.assertNotEquals(null, checkLead.Personal_Credit_Report__c, 'Lead should have an attached personal credit report');
        System.assertEquals('9999', checkLead.Personal_Credit_Report__r.LASERCA__Credit_Score__c, 'Credit score on lead personal credit report should be 9999');
        System.assertEquals(0, new CaseSelector().selectOpenNoMatchCasesFromLead(lead).size(), 'No Match cases should only be created for credit pulls that do not match, not credit pulls that could not be scored');
        System.assertEquals(1, checkLead.LASERCA__Credit_Report_Logs__r.size(), 'There should only be one Credit Report Log after pulling credit');
        System.assertEquals(checkLead.Personal_Credit_Report__c, checkLead.LASERCA__Credit_Report_Logs__r[0].LASERCA__Personal_Credit_Report__c,
            'The CreditReportLog should have the No Match Credit Report attached to it that is found on the Lead');
        System.assertEquals(1, checkLead.LASERCA__Personal_Credit_Reports__r.size(),
            'Expected the CreditReportLogTrigger to create one No Match PCR if the CRL has an error status');
    }

    private static LASERCA__Credit_Report_Log__c pullCreditForLead(Id leadId, String creditScoreType) {
        Map<String, String> leadTypeToCreditScore = new Map<String, String>{
            'High FICO' => '700',
            'Low FICO' => '200',
            'No FICO' => ''
        };
        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = leadId
        );
        if (creditScoreType == 'No Match') {
            crLog.LASERCA__Status__c = 'Error';
        }
        insert crLog;

        if (creditScoreType != 'No Match') {
            LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
                LASERCA__Lead__c = leadId,
                LASERCA__Date_of_Credit_Report__c = System.today(),
                LASERCA__Credit_Score__c = leadTypeToCreditScore.get(creditScoreType)
            );
            insert pcr;

            crLog.LASERCA__Personal_Credit_Report__c = pcr.Id;
            crLog.LASERCA__Status__c = 'Completed';
        }
        update crLog;

        Lead lead = new Lead(
            Id = leadId,
            Moody_s_Risk_Calc__c = 'Aaa'
        );
        update lead;
        return crLog;
    }

    @IsTest
    private static void testQualifyLead() {
        // Test Financial Review qualification without associated Fin Doc records
        Lead lead = [
            SELECT Id, Status, Utility_relationship__c, LoadZone__c, Partner_Lookup__r.Name, Product__c,
                Moody_s_Risk_Calc__c
            FROM Lead
            LIMIT 1
        ];
        lead.Underwriting_Criteria__c = 'Financial Review';
        update lead;

        CSQualificationService qualService = new CSQualificationService();
        qualService.qualifyLead(lead);
        System.assertEquals('Unqualified', lead.Status, 'The lead status should be Unqualified, as there are no ' +
            'Financial Underwriting Document records associated with the lead.');

        // Test Financial Review qualification with associated Fin Doc records, but no required file attachments
        Financial_Underwriting_Document__c fud = new Financial_Underwriting_Document__c(Lead__c = lead.Id);
        insert fud;
        lead = [
            SELECT Id, Status, Utility_relationship__c, LoadZone__c, Partner_Lookup__r.Name, Underwriting_Criteria__c,
                Moody_s_Risk_Calc__c, Product__c, (SELECT Id FROM Underwrite_Financial_Documents__r)
            FROM Lead
            WHERE Id = :lead.Id
        ];
        qualService.qualifyLead(lead);
        System.assertEquals('Unqualified', lead.Status, 'The lead status should be Unqualified, as the lead\'s child ' +
            'Financial Underwriting Document record has no files attached.');

        // Test Financial Review qualification with associated Fin Doc records and required attachments
        ContentVersion cvFinDoc = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('financial document'),
            Title = 'FinancialDocument.pdf',
            PathOnClient = '/FinancialDocument.pdf',
            File_Category__c = 'Financial Review Documents'
        );
        insert cvFinDoc;
        ContentDocumentSelector cds = new ContentDocumentSelector();
        Id contentDocIdFin = cds.getDocumentIdFromVersionId(cvFinDoc.Id);
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocIdFin,
            ShareType = 'V',
            Visibility = 'AllUsers',
            LinkedEntityId = fud.Id
        );
        insert cdl;
        lead = [
            SELECT Id, Status, Utility_relationship__c, LoadZone__c, Partner_Lookup__r.Name, Product__c,
                Moody_s_Risk_Calc__c, Underwriting_Criteria__c, No_Payment__c, (SELECT Id FROM Underwrite_Financial_Documents__r)
            FROM Lead
            WHERE Id = :lead.Id
        ];
        qualService.qualifyLead(lead);
        System.assertEquals('Qualified', lead.Status, 'The lead status should be Qualified, as the lead\'s child ' +
            'Financial Underwriting Document record has files attached and there is a matching SSS.');

        // Test 'None' underwriting criteria, but where there is also no matching SSS for qualification
        Utility__c newUtility = [SELECT Id FROM Utility__c WHERE Name = 'Rochester Gas and Electric' LIMIT 1];
        lead.Utility_relationship__c = newUtility.Id;
        update lead;
        lead = [
            SELECT Id, Status, Utility_relationship__c, LoadZone__c, Partner_Lookup__r.Name, Moody_s_Risk_Calc__c,
                Underwriting_Criteria__c,Product__c, No_Payment__c, Email, FirstName, (SELECT Id FROM Underwrite_Financial_Documents__r)
            FROM Lead
            LIMIT 1
        ];
        lead.Underwriting_Criteria__c = 'None';
        qualService.qualifyLead(lead);
        System.assertEquals('Unqualified', lead.Status, 'The lead status should be Unqualified, as there is no open ' +
            'SSS matching the lead\'s utility.');
    }

    @IsTest
    public static void testQualificationWidgetWithInputs() {
        List<CSQualificationService.QualificationMatch> allMatches = new List<CSQualificationService.QualificationMatch>();
        Lead switchLead = [
            SELECT Id, Product__c, Parcel_Zip__c, Moody_s_Risk_Calc__c
            FROM Lead
            LIMIT 1
        ];
        Partner__c partner = [
            SELECT Id
            FROM Partner__c
            LIMIT 1
        ];
        String productId = switchLead.Product__c;
        String partnerId = partner.Id;
        String zipCode = switchLead.Parcel_Zip__c;
        String underwriting = 'FICO';

        allMatches = CSQualificationService.getQualificationMatches(null, productId, partnerId, zipCode, underwriting);
        System.assertEquals(1, allMatches.size(), 'There should be one qualification match');
        System.assert(allMatches[0].completeMatch, 'The qualification match should be a complete match');
    }

    @IsTest
    public static void testQualificationWidgetHalfMatch() {
        // We expect to still see the SSS returned as a potential match but completeMatch is False
        // because the fico is not eligible for the project
        Partner__c partner = [
            SELECT Id
            FROM Partner__c
            LIMIT 1
        ];

        List<CSQualificationService.QualificationMatch> allMatches = new List<CSQualificationService.QualificationMatch>();
        Lead switchLead = [
            SELECT Id, Product__c, Parcel_Zip__c, Moody_s_Risk_Calc__c
            FROM Lead
            LIMIT 1
        ];
        pullCreditForLead(switchLead.Id, 'Low FICO');
        String productId = switchLead.Product__c;
        String partnerId = partner.Id;
        String zipCode = switchLead.Parcel_Zip__c;
        String underwriting = 'FICO';

        allMatches = CSQualificationService.getQualificationMatches(switchLead.Id, productId, partnerId, zipCode, underwriting);

        System.assertEquals(1, allMatches.size(), 'There should be one qualification match');
        System.assert(!allMatches[0].completeMatch, 'The qualification match should NOT be a complete match because the FICO score is too low');
        System.assert(allMatches[0].hasPartner, 'hasPartner should be true for the qualification match');
        System.assert(allMatches[0].isOpen, 'isOpen should be true for the qualification match');
        System.assert(allMatches[0].hasCapacity, 'hasCapacity should be true for the qualification match');
        System.assert(allMatches[0].hasLZ, 'hasLZ should be true for the qualification match');
    }

    @IsTest
    public static void testQualificationWidgetNoMatch() {
        List<CSQualificationService.QualificationMatch> allMatches = new List<CSQualificationService.QualificationMatch>();
        Lead switchLead = [
            SELECT Id, Product__c, Parcel_Zip__c, Moody_s_Risk_Calc__c
            FROM Lead
            LIMIT 1
        ];
        Partner__c partner = [
            SELECT Id
            FROM Partner__c
            LIMIT 1
        ];

        String productId = switchLead.Product__c;
        String partnerId = partner.Id;
        String zipCode = '24680';
        String underwriting = 'Financial Review';

        allMatches = CSQualificationService.getQualificationMatches(null, productId, partnerId, zipCode, underwriting);
        System.assertEquals(0, allMatches.size(), 'There should be no qualification matches');
    }

    @IsTest
    public static void closeReportMissingCasesTest() {
        Lead switchLead = [
            SELECT Id, Name, Parent_Account__c, Moody_s_Risk_Calc__c
            FROM Lead
            LIMIT 1
        ];

        System.assertEquals(0, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'There should be no open cases for ' +
            'this lead before enqueuing');
        Test.startTest();
        CaseFactory testCaseFactory = new CaseFactory();
        testCaseFactory.setLead(switchLead);
        testCaseFactory.setQueueType('No FICO Match');
        System.enqueueJob(testCaseFactory);
        Test.stopTest();
        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'If a case already ' +
            'exists another should not be created. There should only be 1 open case at a time.');
        CSQualificationService.closeReportMissingCases(switchLead);
        System.assertEquals(0, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'After open cases are closed' +
            'the case selector should not return anything.');
    }
}