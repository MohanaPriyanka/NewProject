@IsTest
public without sharing class CEDLoanTest {
    @TestSetup static void setupTestData(){
        Loan_Data__c capitalPool = new Loan_Data__c(
            Name = 'Revolving Credit Line',
            Total_Capital__c = 10000000,
            Investor__c = 'The Bank',
            Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Account profitCenterOne = new Account(
            Name = 'Profit CenterOne',
            Type = 'Profit Center');

        Account profitCenterTwo = new Account(
            Name = 'Profit CenterOne',
            Type = 'Profit Center');

        insert new List<Account>{profitCenterOne, profitCenterTwo};

        Partner__c partnerWithAccess = new Partner__c(
            Name = 'Bluewave Inside Sales');
        insert partnerWithAccess;

        BSST__c salesRep = new BSST__c(
            Name = 'BlueWave User',
            Partner__c = partnerWithAccess.Id,
            Custom_ID__c = 'test',
            Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        BSST__c salesRepExec = new BSST__c(
            Name = 'BlueWave Executive',
            Partner__c = partnerWithAccess.Id,
            Custom_ID__c = 'exec',
            Email__c = 'executive@Sales.com');
        insert salesRepExec;

        String states = 'FL;MA;NC;NY;RI;SC';

        Account accountRecord = new Account(
            Name = 'BlueWave Customer Care',
            State_Market__c = states,
            Enable_CS_Application_in_Portal__c = true,
            Partner__c = partnerWithAccess.Id,
            Community_Solar_Application_Type__c = 'CSAP');
        insert accountRecord;

        Contact normalSalesRep = new Contact(
            FirstName = 'BlueWave',
            LastName = 'User',
            AccountId = accountRecord.Id,
            Partner_Lookup__c = partnerWithAccess.Id,
            Sales_Representative__c = salesRep.Id);
        insert normalSalesRep;

        Contact executiveSalesRep = new Contact(
            FirstName = 'BlueWave',
            LastName = 'Executive',
            AccountId = accountRecord.Id,
            Partner_Lookup__c = partnerWithAccess.Id,
            Sales_Representative__c = salesRepExec.Id);
        insert executiveSalesRep;

        Product2 cedProductMA = new Product2(
            Name = 'CED Solar Loan - MA - 10 Year - 12 Month I/O = 5.25%',
            ProductCode = 'CED - MA - 16',
            Description = 'Description',
            IsActive = true,
            Family = 'Solar Loan',
            Credit_Maximum__c = '1000',
            Credit_Minimum__c = '600',
            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
            Loan_Capital_Pool__c = capitalPool.Id,
            Loan_Financing_Fee_Terms__c = 'No Financing Fee',
            Loan_Interest_Only_Period__c = 12,
            Loan_Interest_Rate__c = 5.25,
            Loan_Term__c = 108,
            Loan_Tranche_Type__c = 'Standard',
            Product_Type__c = 'Residential Loan',
            Program__c = 'CED',
            State__c = 'MA',
            Technology_Platform_Fee__c = 0,
            Debt_To_Income_Maximum__c = 50,
            Lender_of_Record__c = 'Avidia',
            Hide_in_Requested_Product__c = False,
            Maximum_Loan_Size__c = 100000,
            Require_Junctions_to_Enable__c = true
        );
        insert cedProductMA;

        Product2 cedProductNY = new Product2(
            Name = 'CED Solar Loan - NY - 10 Year - 12 Month I/O = 5.25%',
            ProductCode = 'CED - NY - 16',
            Description = 'Description',
            IsActive = true,
            Family = 'Solar Loan',
            Credit_Maximum__c = '1000',
            Credit_Minimum__c = '600',
            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
            Loan_Capital_Pool__c = capitalPool.Id,
            Loan_Financing_Fee_Terms__c = 'No Financing Fee',
            Loan_Interest_Only_Period__c = 12,
            Loan_Interest_Rate__c = 5.25,
            Loan_Term__c = 108,
            Loan_Tranche_Type__c = 'Standard',
            Product_Type__c = 'Residential Loan',
            Program__c = 'CED',
            State__c = 'NY',
            Technology_Platform_Fee__c = 0,
            Debt_To_Income_Maximum__c = 50,
            Lender_of_Record__c = 'Avidia',
            Hide_in_Requested_Product__c = False,
            Maximum_Loan_Size__c = 100000,
            Require_Junctions_to_Enable__c = true
        );
        insert cedProductNY;

        Partner_Product_Junction__c junction = new Partner_Product_Junction__c(
            Active__c = true,
            Enabled_Product__c = cedProductMA.Id,
            Partner__c = partnerWithAccess.Id
        );
        insert junction;

        Partner_Product_Junction__c junctionTwo = new Partner_Product_Junction__c(
            Active__c = false,
            Enabled_Product__c = cedProductNY.Id,
            Partner__c = partnerWithAccess.Id
        );
        insert junctionTwo;
    }

    static Lead mockApplication(){
        // Mimics the steps of the CAP:

        Lead application = [
            SELECT Id, Name, Email, Application_Type__c, MobilePhone, Street , City, State, PostalCode,
                LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_Zip__c, Residence_Owner__c,
                Property_Type__c, State_of_Issuance__c,
                License_Number_Encrypted__c, Date_of_Issuance__c, Date_of_Expiration__c, LASERCA__SSN__c,
                LASERCA__Birthdate__c, Annual_Income_Currency__c, Monthly_Mortgage_Tax_and_Insurance__c
            FROM Lead
        ];

        Date dateOne = Date.newInstance(2019, 5, 1);
        Date dateTwo = Date.newInstance(1990, 5, 1);

        application.Application_Type__c = 'Individual';
        application.MobilePhone = '8644217874';
        CAPController.setAppType(application);

        application.Street = '200 Street';
        application.City = 'City';
        application.State = 'Massachusetts';
        application.PostalCode = '02114';
        application.LASERCA__Home_Address__c = '200 Street';
        application.LASERCA__Home_City__c = 'City';
        application.LASERCA__Home_Zip__c = '02114';
        application.Residence_Owner__c = 'true';
        application.Property_Type__c = 'Single Family Home (1-4 Units)';
        update application;

        application.State_of_Issuance__c = 'MA';
        application.License_Number_Encrypted__c = '123123123123123';
        application.Date_of_Issuance__c = dateTwo;
        application.Date_of_Expiration__c = dateOne;
        update application;

        application.LASERCA__SSN__c = '000000001';
        application.LASERCA__Birthdate__c = dateTwo;
        application.Annual_Income_Currency__c = 200000;
        application.Monthly_Mortgage_Tax_and_Insurance__c = 1200;
        application.Credit_Check_Acknowledged__c = true;
        application.Privacy_Policy_Acknowledged__c = true;
        application.Status = 'Ready for Credit Check';
        update application;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c (
            Name = 'PCR Approved',
            LASERCA__Code_2__c = '1',
            LASERCA__Code_3__c = '1',
            LASERCA__Code_4__c = '1',
            LASERCA__Code__c = '1',
            LASERCA__Credit_Score_TransUnion__c = '700',
            LASERCA__Lead__c = application.Id
        );
        insert pcr;

        LASERCA__Trade_Accounts__c tradeAccount = new LASERCA__Trade_Accounts__c(
            Name = 'Trade Acct 1',
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Account_Balance__c = 100,
            LASERCA__Monthly_Payment__c = 100,
            LASERCA__Name_of_the_Institution__c = 'Institution'
        );
        insert tradeAccount;

        LASERCA__Credit_Report_Log__c creport = new LASERCA__Credit_Report_Log__c(
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );

        insert creport;

        return application;
    }

    @isTest public static void testPartnerAccessToProduct(){
        // Tests the program picklist in portal. This list mocks what programs partners have access to:
        // Right now, the partner has access to the MA CED product, but not the NY CED product
        Map<String, List<Product2>> productMapMA = SLPAddCustomer.getProducts('MA');
        Map<String, List<Product2>> productMapNY = SLPAddCustomer.getProducts('NY');

        System.assertEquals(1,productMapMA.get('CED').size());
        System.assertEquals(false,productMapNY.containsKey('CED'));

        Partner_Product_Junction__c junctionTwo = [
            SELECT Id, Active__c
            FROM Partner_Product_Junction__c
            WHERE Active__c = FALSE];
        junctionTwo.Active__c = TRUE;
        update junctionTwo;

        // Now partner has now should have access to both CED products:
        Map<String, List<Product2>> updatedMA = SLPAddCustomer.getProducts('MA');
        Map<String, List<Product2>> updatedNY = SLPAddCustomer.getProducts('NY');

        System.assertEquals(1,updatedMA.get('CED').size());
        System.assertEquals(1,updatedNY.get('CED').size());
    }

    @isTest public static void testPartnerTasks() {
        Map<String, List<Product2>> productMapMA = SLPAddCustomer.getProducts('MA');
        List<Product2> productList = productMapMA.get('CED');

        String systemInfo = '{"Number_of_Modules__c":5,"Module_Manufacturer__c":"Sunviva",' +
            '"Module_Model_Number__c":"Type","Number_of_Inverters__c":1,"Inverter_Manufacturer__c":"SolarWorld",' +
            '"Inverter_Model_Number__c":"Type","Estimated_Completion_Date__c":"04/13/2019","Generator_Nameplate_Capacity__c":' +
            '12,"Storage_Grid_Hybrid__c":false,"Storage_Full_or_Partial_Home__c":"","Storage_Manufacturer__c":"",' +
            '"Storage_Model__c":"","Storage_Inverter_Manufacturer__c":"","Storage_Inverter_Model__c":""}';

        Lead newLead = new Lead(
            FirstName = 'Jordan',
            LastName = 'Testcase',
            LASERCA__Home_State__c = 'MA',
            Email = 'jpentaleri@bluewavesolar.com',
            Product_Program__c = 'CED',
            Requested_Loan_Amount__c = 34000,
            System_Cost__c = 34000,
            Product__c = productList[0].Id,
            DOER_Solar_Loan__c = false,
            Loan_System_Information__c = systemInfo,
            Contingent_Contract__c = true
        );

        SLPAddCustomer.addNewLeadRecord(newLead); // Mimics installer's actions in SLP
        Lead application = mockApplication(); // Mimics customer's actions in CAP up to pulling credit

        Test.startTest();
        CAPController.createLoanAndEquipment(application.Id, 'jpentaleri@bluewavesolar.com');
        CAPController.convertLead(application.Id, 'jpentaleri@bluewavesolar.com');
        Test.stopTest();

        Loan__c newLoan = [
            SELECT Id, Name, Profit_Center__c, Invoice_Amount__c
            FROM Loan__c
            WHERE Lead__r.Id = : application.Id LIMIT 1];

        List<Partner_Task__c> ptList = [
            SELECT Id, Status__c, Name
            FROM Partner_Task__c
            WHERE Loan__r.Id = : newLoan.Id
            AND Parent_Task__c = null
            ORDER BY Task_Sequence__c];

        System.assertEquals(9, ptList.size());
        System.assertEquals('Run Credit Check', ptList[0].Name);
        System.assertEquals('Provide All Customer Information', ptList[1].Name);
        System.assertEquals('Under BlueWave Review', ptList[2].Name);
        System.assertEquals('Obtain Contract Signature', ptList[3].Name);
        System.assertEquals('Provide Sales Agreement', ptList[4].Name);
        System.assertEquals('BlueWave Counter Signature', ptList[5].Name);
        System.assertEquals('Material Invoice', ptList[6].Name);
        System.assertEquals('Mechanical Installation', ptList[7].Name);
        System.assertEquals('Interconnection', ptList[8].Name);

        ptList[0].Status__c = 'Complete';
        ptList[1].Status__c = 'Complete';
        ptList[2].Status__c = 'Complete';
        ptList[3].Status__c = 'Complete';
        ptList[4].Status__c = 'Complete';
        ptList[5].Status__c = 'Complete';
        ptList[6].Status__c = 'Pending';
        update ptList;

        List<Account> profitCenterList = BlueWaveParent.getProfitCenters();
        System.assertEquals(2, profitCenterList.size());

        newLoan.Profit_Center__c = profitCenterList[0].Id;
        newLoan.Invoice_Amount__c = 10000;
        update newLoan;

        List<Partner_Task__c> updatedPartnerTaskList = [
            SELECT Id, Status__c, Name
            FROM Partner_Task__c
            WHERE Loan__r.Id = : newLoan.Id
            AND Parent_Task__c = null
            ORDER BY Task_Sequence__c];

        System.assertEquals('Material Invoice', updatedPartnerTaskList[6].Name);
        System.assertEquals('Complete',updatedPartnerTaskList[6].Status__c);
    }
}