@IsTest
public class ClientInvoicingFeeWaiveServiceTest {
    @TestSetup
    public static void setupData() {
        SharedSolarSystemHandlerTest.setupData();
    }

    @IsTest
    private static void systemTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Contract' LIMIT 1];
        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = clientRT.Id,
            StartDate = System.today()
        );
        insert contractA;
        Contract_Fee_Detail__c cfd = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Fee__c = 0.10,
            Acquisition_Type_Reacquisition__c = true,
            Waive_Reacquisition_Fee_Project_Date__c = 'Contract: Effective Date',
            Waive_Reacquisition_Fee_Number_Months__c = 0,
            Waive_Reacq_Fee_After_Initial_Period__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true
        );
        insert cfd;

        Shared_Solar_System__c sss = [
            SELECT Id, (SELECT Id FROM Opportunities__r LIMIT 1)
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
            LIMIT 1
        ];
        sss.Client_Management_Contract__c = contractA.Id;
        sss.Client_Acquisition_Contract__c = contractA.Id;
        sss.Reacquisition_Start_Date__c = System.today().addYears(-1);
        update sss;

        Utility_Account_Subscription__c uas = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :sss.Opportunities__r[0].Id
            LIMIT 1
        ];

        Subscription_Order__c so = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Utility_Account_Subscription__c = uas.Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 4800,
            Previous_Annual_kwh__c = 0
        );
        Test.startTest();
        insert so;
        Test.stopTest();

        Client_Invoicing_Memo__c cim = [
            SELECT Id
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__c = :so.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, cim,
            'Expected to create a CIM since we are in the initial period. ' +
                'Contract Start Date: ' + contractA.StartDate + ' SO Effective Date: ' + so.Effective_Date__c);

        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c];
        System.assert(errorLogs.isEmpty(), errorLogs);
    }

    @IsTest
    private static void testWaiveForProjectDates() {
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(null);
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        Subscription_Order__c so = getSubscriptionOrder();
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = System.today();
        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Expected to get an Client Invoicing Memo for Project COD to be waived in the initial period');
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there is no cap');

        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = null;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did not expect to waive the SO because there is no COD Date');

        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: PTO';
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c = System.today();
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Expected to get an Client Invoicing Memo for Project PTO to be waived in the initial period');
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there is no cap');

        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c = null;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did no expect to get an Client Invoicing Memo for Project PTO to be waived in the initial period');

        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Contract: Effective Date';
        so.Contract_Fee_Detail__r.Contract__r.StartDate = System.today();
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Expected to get an Client Invoicing Memo for Contract Effective Date to be waived in the initial period');
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there is no cap');

        so.Contract_Fee_Detail__r.Contract__r.StartDate = null;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did not expect to get an Client Invoicing Memo for Contract Effective Date if the contract has no Start Date');

        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: First Customer Bill Date';
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.First_Bill_Date__c = System.today();
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Expected to get an Client Invoicing Memo for First Customer Bill Date to be waived in the initial period');
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there is no cap');

        so.Utility_Account_Subscription__r.Shared_Solar_System__r.First_Bill_Date__c = null;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did not expect to get an Client Invoicing Memo for First Customer Bill Date if first bill date is null');

        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Fee not Charged';
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did not expect to get an Client Invoicing Memo for Fee not Charged');

        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: First Customer Assignment Date';
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Did not expect to get an Client Invoicing Memo for First Customer Assignment Date ' +
                '(that is global picklist option used when setting the Revenue Start Date on a SSS)');
    }

    @IsTest
    private static void testWaiveForInitialPeriod() {
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(null);
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        Subscription_Order__c so = getSubscriptionOrder();
        so.Effective_Date__c = Date.newInstance(2020,10,1);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = Date.newInstance(2020,10,1);
        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);

        so.Approved_Change_in_Subscription__c = -12;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should not get a fee waive for reductions');

        so.Approved_Change_in_Subscription__c = 12;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = false;
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should not get a fee waive in the initial period if the CFD does not enable that option');

        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = Date.newInstance(2020,9,1);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should not get a fee waive because the SO is one day after the initial period. ' +
                'SSS COD: ' + so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c +
                'SO Effective: ' + so.Effective_Date__c);

        so.Effective_Date__c = Date.newInstance(2020,9,30);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should get a fee waive because the SO is at the end of the initial period. ' +
                'SSS COD: ' + so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c +
                'SO Effective: ' + so.Effective_Date__c);
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there is no cap');

    }

    @IsTest
    private static void testWaiveWithMaxProjectPercentCap() {
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(null);
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        Subscription_Order__c so = getSubscriptionOrder();
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = true;
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c = 5;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = DateUtil.convertGmtToDate(System.today());
        so.Effective_Date__c = DateUtil.convertGmtToDate(System.today().addMonths(1));
        Id sssId = Util.getFakeId(Shared_Solar_System__c.SObjectType);

        service.sssIdToTotalWaivedkWMap = MultiMap.newListInstance();
        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should get a fee waive because the SO is after the initial period. ' +
                'SSS COD: ' + so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c +
                'SO Effective: ' + so.Effective_Date__c);
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive the full amount of the SO change since there have not been any other fees waived yet');

        service.sssIdToTotalWaivedkWMap = MultiMap.newListInstance();
        ClientInvoicingMemo existingClientInvoicingMemoInThisAnnualPeriod = new ClientInvoicingMemo(
            sssId,
            so.Effective_Date__c,
            (so.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c * 5/100) - 1
        );
        service.sssIdToTotalWaivedkWMap.putValue(sssId, existingClientInvoicingMemoInThisAnnualPeriod);

        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(-1 * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive just 1 kW since that is what is left under the 5% cap');
        System.assert(so.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c * 5/100 > so.Approved_Change_in_Subscription__c,
            'The total system size capped at 5% is ' + so.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c * 5/100 +
                ' which is less than the change amount of ' + so.Approved_Change_in_Subscription__c);

        so.Effective_Date__c = so.Effective_Date__c.addYears(1);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(-so.Approved_Change_in_Subscription__c * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'A SO in the next annual period should get fully waived');
        System.assertEquals(3, service.sssIdToTotalWaivedkWMap.getValues(sssId).size(),
            'We expect to find the existingClientInvoicingMemoInThisAnnualPeriod, the one that is for 1 kW, and the fully waived one just created');
        System.assertEquals(so.Effective_Date__c.addYears(-1), ((ClientInvoicingMemo) service.sssIdToTotalWaivedkWMap.getValues(sssId)[1]).effectiveDate,
            'The previously created invoice memo should be from the previous year');

    }

    @IsTest
    private static void testWaiveByCustomerAssignment() {
        ClientInvoicingFeeAssignmentService assignmentService =
            (ClientInvoicingFeeAssignmentService) Test.createStub(ClientInvoicingFeeAssignmentService.class, new MockAssignmentService());

        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(assignmentService);
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        // Since System Change Rounded is not writable, we have to set it when creating the SO...
        Subscription_Order__c so = getSubscriptionOrderWithSystemChangeRounded(25);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = true;

        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should have not gotten an invoicing memo since the system change on the order is not 0');

        so = getSubscriptionOrderWithSystemChangeRounded(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Approved_Change_in_Subscription__c = -12;
        service.uasToAssignedCapacityMap = new Map<Id, Decimal>();
        Decimal subscriptionSizeAtTimeOfAssignment = -so.Approved_Change_in_Subscription__c * 2;
        service.uasToAssignedCapacityMap.put(Util.getFakeId(Utility_Account_Subscription__c.SObjectType), subscriptionSizeAtTimeOfAssignment);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should have gotten an invoicing memo since the system change on the order goes to 0');
        System.assertEquals(-subscriptionSizeAtTimeOfAssignment * .10 * 1000, cim.Amount__c,
            'Expected the invoicing memo to be based on the size at time of Assignment, not the latest Approved Change in Subscription');

        so = getSubscriptionOrderWithSystemChangeRounded(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = false;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = true;
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c = 5;
        so.Effective_Date__c = so.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r.CustomerSignedDate.addMonths(1);
        so.Approved_Change_in_Subscription__c = -12;

        Id sssId = Util.getFakeId(Shared_Solar_System__c.SObjectType);
        service.sssIdToTotalWaivedkWMap = MultiMap.newListInstance();
        ClientInvoicingMemo existingClientInvoicingMemoInThisAnnualPeriod = new ClientInvoicingMemo(
            sssId,
            so.Effective_Date__c,
            (so.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c * 5/100) - 1
        );
        service.sssIdToTotalWaivedkWMap.putValue(sssId, existingClientInvoicingMemoInThisAnnualPeriod);

        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(-1 * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected to waive just 1 kW since that is what is left under the 5% cap');
    }

    @IsTest
    private static void testWaiveForEstimatedCODOrCustomerAssignment() {
        ClientInvoicingFeeAssignmentService assignmentService =
            (ClientInvoicingFeeAssignmentService) Test.createStub(ClientInvoicingFeeAssignmentService.class, new MockAssignmentService());

        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(assignmentService);
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        // Since System Change Rounded is not writable, we have to set it when creating the SO...
        Subscription_Order__c so = getSubscriptionOrderWithSystemChangeRounded(25);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = false;

        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should have not gotten an invoicing memo since the system change on the order is not 0');

        so = getSubscriptionOrderWithSystemChangeRounded(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_Estimated_COD__c = System.today();
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Approved_Change_in_Subscription__c = -12;
        service.uasToAssignedCapacityMap = new Map<Id, Decimal>();
        Decimal subscriptionSizeAtTimeOfAssignment = -so.Approved_Change_in_Subscription__c * 2;
        service.uasToAssignedCapacityMap.put(Util.getFakeId(Utility_Account_Subscription__c.SObjectType), subscriptionSizeAtTimeOfAssignment);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should have gotten an invoicing memo since the system change on the order goes to 0 and the ' +
                'SO Effective date is today, and we waive fees for cancellations until 1 month after Estimated COD or Assignment');
        System.assertEquals(-subscriptionSizeAtTimeOfAssignment * so.Contract_Fee_Detail__r.Fee__c * 1000, cim.Amount__c,
            'Expected the invoicing memo to be based on the size at time of Assignment, not the latest Approved Change in Subscription');

        so = getSubscriptionOrderWithSystemChangeRounded(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_Estimated_COD__c = System.today().addMonths(-2);
        so.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r = null;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Approved_Change_in_Subscription__c = -12;
        service.uasToAssignedCapacityMap = new Map<Id, Decimal>();
        subscriptionSizeAtTimeOfAssignment = -so.Approved_Change_in_Subscription__c * 2;
        service.uasToAssignedCapacityMap.put(Util.getFakeId(Utility_Account_Subscription__c.SObjectType), subscriptionSizeAtTimeOfAssignment);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should not have gotten an invoicing memo to waive this fee, since the Estimated COD is two months ago, ' +
                'there is no Assignment Agreement, the SO Effective date is today, ' +
                'and we only waive fees for one month');

        so = getSubscriptionOrderWithSystemChangeRounded(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_Estimated_COD__c = System.today().addMonths(-2);
        so.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r.CustomerSignedDate = System.today().addMonths(-1).addDays(1);
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Approved_Change_in_Subscription__c = -12;
        service.uasToAssignedCapacityMap = new Map<Id, Decimal>();
        subscriptionSizeAtTimeOfAssignment = -so.Approved_Change_in_Subscription__c * 2;
        service.uasToAssignedCapacityMap.put(Util.getFakeId(Utility_Account_Subscription__c.SObjectType), subscriptionSizeAtTimeOfAssignment);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should have gotten an invoicing memo to waive this fee, since the customer cancelled within a month of being assigned');
    }

    private static Subscription_Order__c getSubscriptionOrder() {
        return getSubscriptionOrderWithSystemChangeRounded(25);
    }
    private static Subscription_Order__c getSubscriptionOrderWithSystemChangeRounded(Decimal systemChangeRounded) {
        Date today = System.today();
        Map<SObjectField, Object> subscriptionOrderValues = new Map<SObjectField, Object> {
            Subscription_Order__c.Id => Util.getFakeId(Subscription_Order__c.SObjectType),
            Subscription_Order__c.Effective_Date__c => today,
            Subscription_Order__c.Utility_Account_Subscription__c => Util.getFakeId(Utility_Account_Subscription__c.SObjectType),
            Subscription_Order__c.Approved_Change_in_Subscription__c => 12,
            Subscription_Order__c.System_Change_kW_DC_Rounded__c => systemChangeRounded
        };
        sfab_FabricatedSObject fabbedSO = new sfab_FabricatedSObject(Subscription_Order__c.class, subscriptionOrderValues);
        Map<SObjectField, Object> cfdValues = new Map<SObjectField, Object> {
            Contract_Fee_Detail__c.Fee__c => .10,
            Contract_Fee_Detail__c.Acquisition_Type_Acquisition__c => false,
            Contract_Fee_Detail__c.Acquisition_Type_Reacquisition__c => true,
            Contract_Fee_Detail__c.Waive_Reacquisition_Fee_Project_Date__c => 'Project: COD',
            Contract_Fee_Detail__c.Waive_Reacquisition_Fee_Number_Months__c => 2,
            Contract_Fee_Detail__c.Waive_Reacq_Fee_In_Initial_Period__c => true,
            Contract_Fee_Detail__c.Waive_Reacq_Fee_After_Initial_Period__c => false,
            Contract_Fee_Detail__c.Waive_Reacquisition_Fee_Max_Project__c => null
        };
        sfab_FabricatedSObject fabbedCFD = new sfab_FabricatedSObject(Contract_Fee_Detail__c.class, cfdValues);
        fabbedSO.setParent('Contract_Fee_Detail__r', fabbedCFD);
        Map<SObjectField, Object> contractValues = new Map<SObjectField, Object> {
            Contract.StartDate => Date.newInstance(2020,5,1)
        };
        sfab_FabricatedSObject fabbedContract = new sfab_FabricatedSObject(Contract.class, contractValues);
        fabbedCFD.setParent('Contract__r', fabbedContract);
        Map<SObjectField, Object> uasValues = new Map<SObjectField, Object> {
            Utility_Account_Subscription__c.Id => Util.getFakeId(Utility_Account_Subscription__c.SObjectType),
            Utility_Account_Subscription__c.Opportunity__c => Util.getFakeId(Opportunity.SObjectType),
            Utility_Account_Subscription__c.Shared_Solar_System__c => Util.getFakeId(Shared_Solar_System__c.SObjectType)
        };
        sfab_FabricatedSObject fabbedUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class, uasValues);
        fabbedSO.setParent('Utility_Account_Subscription__r', fabbedUAS);
        Map<SObjectField, Object> sssValues = new Map<SObjectField, Object> {
            Shared_Solar_System__c.Id => Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Shared_Solar_System__c.Client_Acquisition_Contract__c => Util.getFakeId(Contract.SObjectType),
            Shared_Solar_System__c.Client_Management_Contract__c => Util.incrementFakeId(Util.getFakeId(Contract.SObjectType)),
            Shared_Solar_System__c.Total_System_Size_kWh_DC__c => 1220
        };
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class, sssValues);
        fabbedUAS.setParent('Shared_Solar_System__r', fabbedSSS);
        Map<SObjectField, Object> opportunityValues = new Map<SObjectField, Object> {
            Opportunity.Id => Util.getFakeId(Opportunity.SObjectType),
            Opportunity.Customer_Group__c => 'Residential',
            Opportunity.Partner_tag_lookup__c => Util.getFakeId(Partner__c.SObjectType)
        };
        sfab_FabricatedSObject fabbedOpp = new sfab_FabricatedSObject(Opportunity.class, opportunityValues);
        Map<SObjectField, Object> customerContractValues = new Map<SObjectField, Object> {
            Contract.Id => Util.getFakeId(Contract.SObjectType)
        };
        sfab_FabricatedSObject fabbedCustomerContract = new sfab_FabricatedSObject(Contract.class, customerContractValues);
        fabbedOpp.setParent('Contract', fabbedCustomerContract);
        Map<SObjectField, Object> assignmentAgreementValues = new Map<SObjectField, Object> {
            Contract.Id => Util.getFakeId(Contract.SObjectType),
            Contract.CustomerSignedDate => today
        };
        sfab_FabricatedSObject fabbedAA = new sfab_FabricatedSObject(Contract.class, assignmentAgreementValues);
        fabbedCustomerContract.setParent('Assignment_Agreement__r', fabbedAA);
        fabbedUAS.setParent('Opportunity__r', fabbedOpp);
        Map<SObjectField, Object> partnerTagValues = new Map<SObjectField, Object> {
            Partner__c.Id => Util.getFakeId(Partner__c.SObjectType)
        };
        sfab_FabricatedSObject fabbedPartnerTag = new sfab_FabricatedSObject(Partner__c.class, partnerTagValues);
        fabbedOpp.setParent('Partner_tag_lookup__r', fabbedPartnerTag);
        Map<SObjectField, Object> accountValues = new Map<SObjectField, Object> {
            Account.Id => Util.getFakeId(Account.SObjectType)
        };
        sfab_FabricatedSObject fabbedAccount = new sfab_FabricatedSObject(Account.class, accountValues);
        fabbedPartnerTag.setParent('Account__r', fabbedAccount);
        Map<SObjectField, Object> recordTypeValues = new Map<SObjectField, Object> {
            RecordType.Name => 'Partner Account'
        };
        sfab_FabricatedSObject fabbedRecordType = new sfab_FabricatedSObject(RecordType.class, recordTypeValues);
        fabbedAccount.setParent('RecordType', fabbedRecordType);
        return (Subscription_Order__c) fabbedSO.toSObject();
    }

    public class MockAssignmentService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getCancellationFee' {
                    return .10;
                }
            }
            return null;
        }
    }

}