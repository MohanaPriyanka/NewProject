/**
 * @description Created by SarahRenfro on 6/4/2019.
 */
@SuppressWarnings('PMD.AvoidHardcodingId')
@IsTest
public class LeadServiceTestclass {

    @TestSetup
    public static void setupTestData() {
        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{
            nyseg, nationalGrid
        };

        Load_U__c nysegLZU = new Load_U__c(
            Name = '12345',
            LZ__c = 'Hudson Valley'
        );
        Load_U__c natgridLZU = new Load_U__c(
            Name = '98765',
            LZ__c = 'WCMA'
        );
        insert new List<Load_U__c>{
            nysegLZU, natgridLZU
        };

        ZipCode_Utility_Junction__c junction1 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = nysegLZU.Id,
            Utility__c = nyseg.Id
        );
        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = natgridLZU.Id,
            Utility__c = nationalGrid.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{
            junction1, junction2
        };

        Utility_NMC_Tariff__c nmcRate = (Utility_NMC_Tariff__c) TestFactory.createSObject(
            new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = 1,
                Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                Sizing_Rate__c = true,
                Date__c = Date.today()
            )
        );
        Utility_NMC_Tariff__c kwhRate = new Utility_NMC_Tariff__c(
            Name = 'National Grid R1',
            Size_Ratio__c = 1.0,
            Date__c = Date.today()
        );
        insert new List<Utility_NMC_Tariff__c>{
            nmcRate, kwhRate
        };

        Product2 csProduct = new Product2(
            Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            Sizing_Method__c = 'Project Ratio',
            State__c = 'NY',
            IsActive = true,
            Customer_Subscription_Type__c = 'kWh');
         insert csProduct;

        Product2 csProduct2 = new Product2(
            Name = 'Community Solar - SREC 16-01',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            Sizing_Method__c = 'Project Ratio',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,




            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            NM_Rate_Floor__c = 0);
        insert csProduct2;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Albany Post Rd Solar Farm',
            Service_Territories__c = 'Hudson Valley; Central',
            Open__c = true,
            Pending_Small_CS_Capacity__c = 0,
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Perch_Acq_Reserved_Small_CS_Capacity__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nyseg.Id,
            Utility_NMC_Tariff__c = kwhRate.Id,
            Credit_Score_Requirement__c = 500,
            Assignment_Order__c = '1',
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Billing_Method__c = 'kWh',
            Available_SMB_Underwriting_Method_Docs__c = true,
            Available_SMB_Underwriting_Method_FICO__c = true
        );
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Pending_Small_CS_Capacity__c = 0,
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Perch_Acq_Reserved_Small_CS_Capacity__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct2.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Billing_Method__c = 'NMC',
            Available_SMB_Underwriting_Method_Docs__c = true,
            Available_SMB_Underwriting_Method_FICO__c = true
        );
        insert new List<Shared_Solar_System__c>{
            sss1, sss2
        };

        Account partnerAccount1 = new Account(
            Name = 'BlueWave Test Partner',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
       Account partnerAccount2 = new Account(
            Name = 'BlueWave Test Partner2',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        
        insert new List<Account>{
            partnerAccount1, partnerAccount2
        };        
        Partner__c partner1 = new Partner__c (
            Name = 'BlueWave Test Partner',
            Email__c = 'bwtest@email.com',
            Account__c = partnerAccount1.Id
        );
        Partner__c partner2 = new Partner__c(
            Name = 'Other Test Partner',
            Email__c = 'otherTest@email.com',
            Account__c = partnerAccount2.Id
        );
        insert new List<Partner__c>{
            partner1, partner2
        };
        partnerAccount1.Partner__c = partner1.Id;
        partnerAccount2.Partner__c = partner2.Id;
        update new List<Account>{
            partnerAccount1, partnerAccount2
        };
        TestFactory.setDefaultCSPartner(partner1.Id);

        List<Partner_Shared_Solar_System_Eligibility__c> partnerEligibilities = SharedSolarSystemsTest.getPartnerEligibilities(
            new List<Shared_Solar_System__c>{
                sss1, sss2
            }, new List<Account>{                              
                partnerAccount2
            }
        );
        partnerEligibilities.add(new Partner_Shared_Solar_System_Eligibility__c(
            Shared_Solar_System__c = sss1.Id,
            Account__c = partnerAccount1.Id,
            Start_Date__c = Date.newInstance(2020, 1, 1)
        ));
        insert partnerEligibilities;

        BSST__c salesRep1 = new BSST__c(
            Name = 'BW Sales Rep',
            Partner__c = partner1.Id
        );

        BSST__c salesRep2 = new BSST__c(
            Name = 'Other Sales Rep',
            Partner__c = partner2.Id
        );
        insert new List<BSST__c>{
            salesRep1, salesRep2
        };

        partner1.Default_Sales_Rep__c = salesRep1.Id;
        partner2.Default_Sales_Rep__c = salesRep2.Id;
        update new List<Partner__c>{
            partner1, partner2
        };

        Lead switchLead = (Lead) TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'Switch',
            Email = 'switch@email.com',
            Utility_relationship__c = nyseg.Id,
            LASERCA__Home_Address__c = '123 Street',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_Zip__c = '12345',
            LASERCA__Home_State__c = 'NY',
            LoadZone__c = 'Hudson Valley',
            LeadSource = 'Switch',
            Company = 'Switch Comp',
            Status = 'Sales Qualified',
            Partner_Lookup__c = partner1.Id,
            Partner_Account__c = partnerAccount1.Id,
            Product_line__c = 'Community Solar',
            Product__c = csProduct.Id,
            Parcel_Zip__c = '12345',
            Customer_type__c = 'Non-Residential',
            Application_Type__c = 'Non-Residential',
            System_Assignment__c = 'Automatic - Assignment Order'));
        insert switchLead;

        CSLeadsRESTControllerV2.setContinueApplicationLinks(switchLead, null);
        update switchLead;
    }


    @IsTest
    static void testCompleteLeadConversionWithSubscriptionOrders() {
        useMocks(true);
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        ual.Annual_kWh__c = 9000;
        insert ual;

        switchLead.Status = 'Qualified';
        update switchLead;

        pullCreditForLead(switchLead.Id);

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(switchLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);

        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        System.assert(lcr.isSuccess(), lcr.getErrors());

        Lead convertedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, IsConverted, Personal_Credit_Report__c
            FROM Lead
            WHERE IsConverted = TRUE
            LIMIT 1
        ];
        System.assertNotEquals(null, convertedLead, 'Lead should have been converted');
        System.assertNotEquals(null, convertedLead.ConvertedAccountId, 'Converted lead should have a ConvertedAccountId'); 

        Account convertedAccount = [
            SELECT Id, Owner.Name, RecordType.Name
            FROM Account
            WHERE Id = :convertedLead.ConvertedAccountId
            LIMIT 1
        ];
        Account propAcct = [
            SELECT Id, Send_Bills_Contact__c, RecordType.Name, Parent_Account__c
            FROM Account
            WHERE Lead__c = :convertedLead.Id AND RecordType.Name = 'Property'
            LIMIT 1
        ];
        Contact contact = [
            SELECT Id, Product_Line__c,Contact.RecordType.Name
            FROM Contact
            WHERE Id = :convertedLead.ConvertedContactId
            LIMIT 1
        ];
        List<Opportunity> oppList = [
            SELECT Id, Shared_Solar_System__r.Name, StageName, Personal_Credit_Report2__c, (SELECT Id FROM OpportunityContactRoles)
            FROM Opportunity
            WHERE Lead__c = :convertedLead.Id
        ];
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Utility_Account_Log__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN :oppList
        ];
        List<Subscription_Order__c> subscriptionOrders = [
            SELECT Id, Utility_Account_Subscription__c, Approved_Change_in_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN :uasList
        ];
        System.assertEquals('API', convertedAccount.Owner.Name, 'Converted account should be owned by API user');

        //Test property's parent account
        System.assertEquals(convertedAccount.Id, propAcct.Parent_Account__c, 'Property account should be the converted account');
        System.assertEquals(contact.Id, propAcct.Send_Bills_Contact__c, 'Property account Send Bills Contact should be the converted contact');
        System.assertEquals('Community Solar', contact.Product_Line__c, 'Converted contact should be assigned to the Community Solar product line');
        System.assertEquals('Customer Contact', contact.RecordType.Name, 'Converted contact should be assigned to the Customer Contact record type');
        System.assertEquals('Parent Account', convertedAccount.RecordType.Name, 'Converted Account should have a record type of Parent Account');

        System.assertEquals(1, oppList.size(), 'Lead conversion should have produced a single opportunity');
        System.assertEquals('Albany Post Rd Solar Farm', oppList[0].Shared_Solar_System__r.Name, 'Opportunity should be assigned an SSS with the same utility as the converted lead');
        System.assertEquals(convertedLead.Personal_Credit_Report__c, oppList[0].Personal_Credit_Report2__c, 'Opportunity should be assigned the same personal credit report as the converted lead');
        System.assert(oppList[0].OpportunityContactRoles.size() > 0, 'Verify if the Opportunity Contact Roles got created.');
        System.assertEquals('QC In Process', oppList[0].StageName, 'Opportunity stage name should be QC In Progress');

        //test uas creation
        System.assertNotEquals(null, uasList, 'UAS should have been created on lead conversion');
        System.assertEquals(1, uasList.size(), 'One UAS should have been created on lead conversion');
        System.assertEquals(ual.Id, uasList[0].Utility_Account_Log__c, 'UAS should be assigned the Utility Account Log of the converted lead');

        //test susbscription order creation
        System.assertNotEquals(null, subscriptionOrders, 'Subscription orders should have been created on lead conversion');
        System.assertEquals(1, subscriptionOrders.size(), 'One subscription order should have been created on lead conversion');
        System.assertEquals(uasList[0].Id, subscriptionOrders[0].Utility_Account_Subscription__c, 'Subscription order should be assigned the UAS of the new opportunity');
        System.assertNotEquals(null, subscriptionOrders[0].Approved_Change_in_Subscription__c, 'Subscription order\'s Approved_Change_in_Subscription__c should not be null');
    }

    @IsTest
    static void testCSAPLeadWithCompletedUAL() {
        useMocks(true);
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead LIMIT 1];
            
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        ual.Annual_kWh__c = 9000;
        insert ual;

        switchLead.LeadSource = 'CSAP';
        switchLead.Status = 'Qualified';        
        update switchLead;        
        
       
        pullCreditForLead(switchLead.Id);

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(switchLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        System.assert(lcr.isSuccess(), lcr.getErrors());

        Lead convertedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, IsConverted, Personal_Credit_Report__c
            FROM Lead
            WHERE IsConverted = TRUE
            LIMIT 1
        ];
       
        Contact contact = [
            SELECT Id, Product_Line__c
            FROM Contact
            WHERE Id = :convertedLead.ConvertedContactId
            LIMIT 1
        ];
        // CSAP deleted the converted contact because the contact was created separately
        delete contact; 
    
        CSLeadsConverter.batchSize = 1;
        CSLeadsConverter converter = new CSLeadsConverter(new Set<Id>{convertedLead.Id});
        converter.execute(null);
       
        Test.getEventBus().deliver();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(0, errorLogs.size(), errorLogs);
    } 

    @IsTest
    static void testFailedEnrollment() {
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];
        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        insert ual;

        switchLead.Status = 'Qualified';
        update switchLead;

        pullCreditForLead(switchLead.Id);

        try {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(switchLead.Id);
            lc.setConvertedStatus('Qualified');
            lc.setDoNotCreateOpportunity(true);
            Database.convertLead(lc, false);
        } catch (Exception e) {
            Boolean expectedException = e.getMessage().contains('No Annual Usage populated on UALs. Please enter usage before converting') ? true : false;
            System.assert(expectedException, 'Expected the lead conversion to fail due to missing Annual Usage on UALs');
        }

        Lead failedLead = [
            SELECT Id, ConvertedAccountId, ConvertedContactId, IsConverted, Personal_Credit_Report__c
            FROM Lead
            WHERE Id = :switchLead.Id
            LIMIT 1
        ];
        System.assertEquals(false, failedLead.IsConverted, 'Expected the lead conversion to fail due to missing Annual Usage on UALs, but lead was converted');
        System.assertEquals(null, failedLead.ConvertedAccountId, 'Expected the lead conversion to fail due to missing Annual Usage on UALs, but lead was converted and ConvertedAccountId was populated');

        List<Opportunity> oppList = [
            SELECT Id, Shared_Solar_System__r.Name, StageName, Personal_Credit_Report2__c
            FROM Opportunity
            WHERE Lead__c = :failedLead.Id
        ];
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Utility_Account_Log__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c IN :oppList
            LIMIT 1
        ];
        System.assertEquals(0, oppList.size(), 'Expected the lead conversion to fail due to missing Annual Usage on UALs, but opportunity was created');
        System.assertEquals(0, uasList.size(), 'Expected the lead conversion to fail due to missing Annual Usage on UALs, but UASes were created');
    }

    @IsTest
    static void testProductChange() {
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        Product2 newProduct = [SELECT Id FROM Product2 WHERE Id != :lead.Product__c LIMIT 1];
        Account a = new Account(
            Lead__c = lead.Id,
            Name = 'test property account',
            BillingStreet = 'test street',
            BillingCity = 'test city',
            BillingStateCode = 'MA',
            BillingPostalCode = '02633'
        );
        insert a;
        Contract contract = new Contract(
            Lead__c = lead.Id,
            Product__c = lead.Product__c,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(),
            AccountId = a.Id
        );
        insert contract;

        Test.startTest();
        lead.Product__c = newProduct.Id;       
        update lead;        
       
        Test.stopTest();
        
        System.assertEquals(newProduct.Id, [SELECT Product__c FROM Contract WHERE Id = :contract.Id LIMIT 1].Product__c,
            'New product on Lead should be reflected by new product on Contract'
        );
    }

    @IsTest
    private static void testGenericCustomerContractProductChange() {
        Lead lead = [SELECT Id, Product__c, (SELECT Id FROM Accounts__r) FROM Lead LIMIT 1];
        Product2 leadGenericProduct = [SELECT Id FROM Product2 WHERE Id = :lead.Product__c LIMIT 1];
        Product2 projectSpecificProduct = new Product2(
            Name = 'Project Specific Product',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            Sizing_Method__c = 'Project Ratio',
            State__c = 'NY',
            IsActive = true,


            Customer_Subscription_Type__c = 'kWh',
            Parent_Product__c = leadGenericProduct.Id);
        insert projectSpecificProduct;

        Account a = new Account(
            Lead__c = lead.Id,
            Name = 'test property account',
            BillingStreet = 'test street',
            BillingCity = 'test city',
            BillingStateCode = 'MA',
            BillingPostalCode = '02633'
        );
        insert a;
        Contract contract = new Contract(
            Lead__c = lead.Id,
            Product__c = lead.Product__c,
            Contract_Type__c = 'Generic',
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(),
            AccountId = a.Id
        );
        insert contract;

        Test.startTest();
        lead.Product__c = projectSpecificProduct.Id;
        update lead;
        Test.stopTest();

        System.assertEquals(leadGenericProduct.Id, [SELECT Product__c FROM Contract WHERE Id = :contract.Id LIMIT 1].Product__c,
            'Product should stay the same on the "Generic" Customer Contract when the Leads product changes from Generic to Project Specific');
    }

    public static void pullCreditForLead(Id leadId) {
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Credit_Score__c = '700'
        );
        insert pcr;
        LASERCA__Trade_Accounts__c tradeAccounts = new LASERCA__Trade_Accounts__c(
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Monthly_Payment__c = 339
        );
        insert tradeAccounts;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;
    }

    @IsTest
    private static void testGetSortedSharedSolarSystems() {
        SharedSolarSystems sssList = new SharedSolarSystems(new List<Shared_Solar_System__c>{
            getMockSSS(true, 'SEMA', false)
        });
        System.assertEquals(1, sssList.getQualifiedForLead(getMockLead('NEMA')).size(),
            'Should have found a qualifying system if ignoring load zones:\n' +
                JSON.serializePretty(sssList) + '\n' + JSON.serializePretty(getMockLead('NEMA')));

        sssList = new SharedSolarSystems(new List<Shared_Solar_System__c>{
            getMockSSS(false, 'SEMA', false)
        });
        System.assertEquals(0, sssList.getQualifiedForLead(getMockLead('NEMA')).size(),
            'Should not have found a qualifying system if ignoring load zones:\n' +
                JSON.serializePretty(sssList) + '\n' + JSON.serializePretty(getMockLead('NEMA')));

        sssList = new SharedSolarSystems(new List<Shared_Solar_System__c>{
            getMockSSS(false, 'SEMA', false)
        });
        System.assertEquals(1, sssList.getQualifiedForLead(getMockLead('SEMA')).size(),
            'Should have found a qualifying system if not ignoring load zones but getting a lead that matches:\n' +
                JSON.serializePretty(sssList) + '\n' + JSON.serializePretty(getMockLead('SEMA')));
    }

    @IsTest
    private static void testSelectedSSSForQualification() {
        useMocks(false);
        List<Shared_Solar_System__c> mockedSSSList = getListofMockedSSS();

        System.assertEquals(5, mockedSSSList.size(), 'Should be 5 Shared Solar Systems ready for Enrollment');
        SharedSolarSystems sssService = new SharedSolarSystems(mockedSSSList);
        Lead preSelectedLead = getMockLead('SEMA');

        System.assertEquals(3, sssService.getQualifiedForLead(preSelectedLead).size(), 'Lead should qualify for 3 out of 5 projects when no "Pre-Selected SSS"');

        //Even though we are pre-selecting 2 SSS, lead only qualifies for the SEMA project
        preSelectedLead.Selected_SSS_For_Conversion__c = mockedSSSList[1].Id + '/' + mockedSSSList[2].Id;
        System.assertEquals(1, sssService.getQualifiedForLead(preSelectedLead).size(),
            'Only pre-selected SSSes should be considered for qualification and conversion when populated');
    }

    @IsTest
    private static void testGenericProductSSSQualification() {
        Lead hybridLead = getMockLead('NEMA');
        hybridLead.Product__c = '00Q0U00000617VTUAY';

        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        sfab_FabricatedSObject fabbedProduct = new sfab_FabricatedSObject(Product2.class);
        fabbedProduct.setField(Product2.Ignore_Load_Zones_When_Qualifying__c, false);
        fabbedProduct.setField(Product2.Parent_Product__c, '00Q0U00000617VTUAY');
        fabbedSSS.setParent('Product__r', fabbedProduct);
        fabbedSSS.setField(Shared_Solar_System__c.Id, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Product__c, Util.getFakeId(Product2.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Service_Territories__c, 'NEMA');
        fabbedSSS.setField(Shared_Solar_System__c.Utility__c, Util.getFakeId(Utility__c.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Available_SMB_Underwriting_Method_FICO__c, true);
        fabbedSSS.setField(Shared_Solar_System__c.Credit_Score_Requirement__c, 200);
        fabbedSSS.setField(Shared_Solar_System__c.Do_Not_Ask_for_Payment_Method__c, false);
        fabbedSSS.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        sfab_FabricatedSObject fabbedPartnerEligibility = new sfab_FabricatedSObject(Partner_Shared_Solar_System_Eligibility__c.class);
        sfab_FabricatedSObject fabbedPartnerAccount = new sfab_FabricatedSObject(Account.class);
        fabbedPartnerAccount.setField(Account.Partner__c, Util.getFakeId(Partner__c.SObjectType));
        fabbedPartnerEligibility.setParent('Account__r', fabbedPartnerAccount);
        fabbedSSS.setChildren('Partner_Shared_Solar_System_Accesses__r', new List<sfab_FabricatedSObject>{
            fabbedPartnerEligibility
        });
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS.toSObject();

        SharedSolarSystems sssService = new SharedSolarSystems(new List<Shared_Solar_System__c>{
            sss
        });

        System.assertEquals(1, sssService.getQualifiedForLead(hybridLead).size(),
            'Lead should qualify for SSS that has Product with Parent Product that matches the Lead\'s Hybrid/Generic Product');
    }

    @IsTest
    private static void testRemoveUnqualifiedSystems() {
        List<Shared_Solar_System__c> qualifiedSSSes = new List<Shared_Solar_System__c>();
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Perch_Acq_Available_LMI_Capacity__c, 100);
        fabbedSSS.setField(Shared_Solar_System__c.LMI__c, true);
        qualifiedSSSes.add((Shared_Solar_System__c) fabbedSSS.toSObject());

        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(qualifiedSSSes);
        sharedSolarSystems.removeUnqualifiedSystemsForCustomerType('LMI', qualifiedSSSes);
        System.assertEquals(1, qualifiedSSSes.size(), 'Should be one qualified system that has LMI capacity for an LMI lead');
        sharedSolarSystems.removeUnqualifiedSystemsForCustomerType('Residential', qualifiedSSSes);
        System.assertEquals(0, qualifiedSSSes.size(), 'Should be no qualified systems with capacity for a small CS lead');

        fabbedSSS.setField(Shared_Solar_System__c.LMI__c, false);
        fabbedSSS.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        qualifiedSSSes.add((Shared_Solar_System__c) fabbedSSS.toSObject());
        sharedSolarSystems = new SharedSolarSystems(qualifiedSSSes);
        sharedSolarSystems.removeUnqualifiedSystemsForCustomerType('Non-Residential', qualifiedSSSes);
        System.assertEquals(1, qualifiedSSSes.size(), 'Should be one qualified system that has small cs capacity for an small cs lead');
        sharedSolarSystems.removeUnqualifiedSystemsForCustomerType('LMI', qualifiedSSSes);
        System.assertEquals(0, qualifiedSSSes.size(), 'Should be no qualified systems with capacity for an LMI lead');
    }

    @IsTest
    private static void testPaymentDetailQualification() {
        useMocks(false);
        List<Shared_Solar_System__c> mockedSSSList = getListofMockedSSS();

        System.assertEquals(5, mockedSSSList.size(), 'Should be 5 Shared Solar Systems ready for Enrollment');
        SharedSolarSystems sssService = new SharedSolarSystems(mockedSSSList);
        Lead preSelectedLead = getMockLead('SEMA');
        preSelectedLead.No_Payment__c = true;
        System.assertEquals(1, sssService.getQualifiedForLead(preSelectedLead).size(), 'Lead should qualify for 1 out of 5 projects when "No Payment"');
    }

    @IsTest
    private static void testInvocableQualifiedSSSSelector() {
        useMocks(false);
        Lead lead = getMockLead('SEMA');
        System.assertEquals(1, InvocableQualifiedSSSSelector.invokeGetQualifiedForLead(new List<Lead>{
            lead
        }).size(),
            'Invocable Method should return list of qualified Shared Solar Systems');
    }

    @IsTest
    private static void testCloseQCCasesForUnqualifiedLeads() {
        Lead lead = [SELECT Id,Name FROM Lead LIMIT 1];
        Case newQCCase = new Case(
            Lead_Lookup__c = lead.Id,
            QC_Case_Subject__c = 'No Credit Match - Provide Additional Background on Guarantor (New Address or DOB)',
            Product_Line__c = 'Community Solar',
            Category__c = 'QC',
            Case_Type__c = '3rd Party',
            Sale_Status__c = 'Pre-Sale',
            Subject = 'No Match Credit Report',
            Priority = 'Medium',
            Origin = 'Other',
            RecordTypeId =  [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'].Id
        );
        insert newQCCase;

        Test.startTest();
        lead.Status = 'Unqualified';
        update lead;
        Test.stopTest();

        String caseStatus = [SELECT Status FROM Case WHERE Id =: newQCCase.Id].Status;
        System.assertEquals('Closed', caseStatus, 'Invalid QC case status after lead marked Unqualified');
    }

    private static Lead getMockLead(String loadZone) {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Utility_relationship__c, Util.getFakeId(Utility__c.SObjectType));
        fabbedLead.setField(Lead.LoadZone__c, loadZone);
        fabbedLead.setField(Lead.Partner_Lookup__c, Util.getFakeId(Partner__c.SObjectType));
        fabbedLead.setField(Lead.Product__c, Util.getFakeId(Product2.SObjectType));
        fabbedLead.setField(Lead.Underwriting_Criteria__c, 'FICO');
        fabbedLead.setField(Lead.LASER_Credit_Score__c, '800');
        fabbedLead.setField(Lead.No_Payment__c, false);
        return (Lead) fabbedLead.toSObject();
    }

    private static Shared_Solar_System__c getMockSSS(Boolean ignoreLoadZones, String serviceTerritories, Boolean ignorePaymentDetails) {
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        sfab_FabricatedSObject fabbedProduct = new sfab_FabricatedSObject(Product2.class);
        fabbedProduct.setField(Product2.Ignore_Load_Zones_When_Qualifying__c, ignoreLoadZones);
        fabbedSSS.setParent('Product__r', fabbedProduct);
        fabbedSSS.setField(Shared_Solar_System__c.Id, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Product__c, Util.getFakeId(Product2.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Service_Territories__c, serviceTerritories);
        fabbedSSS.setField(Shared_Solar_System__c.Utility__c, Util.getFakeId(Utility__c.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Available_SMB_Underwriting_Method_FICO__c, true);
        fabbedSSS.setField(Shared_Solar_System__c.Credit_Score_Requirement__c, 200);
        fabbedSSS.setField(Shared_Solar_System__c.Do_Not_Ask_for_Payment_Method__c, ignorePaymentDetails);
        fabbedSSS.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        sfab_FabricatedSObject fabbedPartnerEligibility = new sfab_FabricatedSObject(Partner_Shared_Solar_System_Eligibility__c.class);
        sfab_FabricatedSObject fabbedPartnerAccount = new sfab_FabricatedSObject(Account.class);
        fabbedPartnerAccount.setField(Account.Partner__c, Util.getFakeId(Partner__c.SObjectType));
        fabbedPartnerEligibility.setParent('Account__r', fabbedPartnerAccount);
        fabbedSSS.setChildren('Partner_Shared_Solar_System_Accesses__r', new List<sfab_FabricatedSObject>{
            fabbedPartnerEligibility
        });
        return (Shared_Solar_System__c) fabbedSSS.toSObject();
    }

    private static List<Shared_Solar_System__c> getListofMockedSSS() {
        return new List<Shared_Solar_System__c>{
            getMockSSS(false, 'SEMA', false),
            getMockSSS(false, 'SEMA', false),
            getMockSSS(true, 'SEMA', false),
            getMockSSS(false, 'NEMA', false),
            getMockSSS(false, 'SEMA', true)
        };
    }

    private static void useMocks(Boolean featureOn) {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(featureOn));
        SharedSolarSystemQualifier.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSharedSolarSystems());
        InvocableQualifiedSSSSelector.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSharedSolarSystems());
    }

    public class MockSharedSolarSystems extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectAll' {
                    return new List<Shared_Solar_System__c>{
                        getMockSSS(false, 'SEMA', false),
                        getMockSSS(false, 'NEMA', false)
                    };
                } when 'getSharedSolarSystemsForEnrollment' {
                    return getListofMockedSSS();
                }
            }
            return null;
        }
    }

    @IsTest
    private static void testUpdateContApplicationLink() {
        Lead switchLead = [
            SELECT Id, Email, Continue_Application_Link__c, Contract_eSign_Link__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];

        System.assert(!(switchLead.Continue_Application_Link__c.contains('updated%40email.com')), 'Confirm continue application link does not contain updated email.');
        System.assert(!(switchLead.Contract_eSign_Link__c.contains('updated%40email.com')), 'Confirm eSign link does not contain updated email.');

        switchLead.Email = 'updated@email.com';

        Test.startTest();
        update switchLead;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, Email, Continue_Application_Link__c, Contract_eSign_Link__c
            FROM Lead
            WHERE Id = :switchLead.Id
            LIMIT 1
        ];

        System.assertEquals('updated@email.com', updatedLead.Email, 'Confirm email has been updated on lead');
        System.assert(updatedLead.Continue_Application_Link__c.contains('updated%40email.com'), 'Continue_Application_Link should get updated after a lead email is updated so the customer/partner does not experience an error when trying continue their application');
        System.assert(updatedLead.Contract_eSign_Link__c.contains('updated%40email.com'), 'Contract_eSign_Link__c should get updated after a lead email is updated so the customer/partner does not experience an error when trying to re-sign their contract.');
    }

    @IsTest
    private static void testAttachLeadsToCampaign() {
        LeadTriggerHandler.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                CampaignMember.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );
        List<Lead> newLeads = new List<Lead>();
        newLeads.add(new Lead(
            Id = Util.getFakeId(Lead.SObjectType)
        ));
        new LeadTriggerHandler(null, null).attachLeadsToCampaign(newLeads);
        System.assertEquals(0, FFLibHelperTest.getRegisterNewListFromUnitOfWork(LeadTriggerHandler.uow, 'CampaignMember').size(),
            'There should be no CampaignMembers created if a lead is inserted without a Manual Campaign Id');

        newLeads.add(new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            Manual_Campaign_ID__c = Util.getFakeId(Campaign.SObjectType)
        ));
        new LeadTriggerHandler(null, null).attachLeadsToCampaign(newLeads);

        System.assertEquals(1, FFLibHelperTest.getRegisterNewListFromUnitOfWork(LeadTriggerHandler.uow, 'CampaignMember').size(),
            'There is one Lead that came from an Unbounce landing page with a Manual Campaign Id that should have been related to a Campaign');

        newLeads.add(new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            Manual_Campaign_ID__c = 'invalidId'
        ));
        new LeadTriggerHandler(null, null).attachLeadsToCampaign(newLeads);
        List<Error_Log__c> errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Method__c = 'attachLeadsToCampaign'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(),
            'Expected one error log about not being able to attach a lead to a campaign, but got this: ' + errorLogs);
    }

    @IsTest
    private static void testCreditReportLogTriggerFailure() {
        MapPCRtoLeadHandler.throwException = true;
        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected CreditReportLogTrigger to log an error after insert from a forced exception but got: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains('to test error handling'), errorLogs[0].Message__c);

        update crLog;
        errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Id != :errorLogs[0].Id
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected CreditReportLogTrigger to log an error after update from a forced exception but got: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains('to test error handling'), errorLogs[0].Message__c);
    }
}