@IsTest
public class ClientInvoicingFeeWaiveServiceTest {
    @TestSetup
    public static void setupData() {
        SharedSolarSystemHandlerTest.setupData();
    }

    @IsTest
    private static void systemTest() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Client Contract').getRecordTypeId(),
            StartDate = System.today().addYears(-1)
        );
        Contract clientAssignmentAgreement = new Contract(
            Name = 'Client Assignment Agreement',
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId(),
            StartDate = System.today().addYears(-1),
            CustomerSignedDate = System.today().addYears(-1)
        );
        insert new List<Contract>{contractA, clientAssignmentAgreement};
        Contract_Fee_Detail__c cfd = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Fee__c = 0.10,
            Fee_Unit__c = 'per W',
            Acquisition_Type_Reacquisition__c = true,
            Waive_Reacquisition_Fee_Project_Date__c = 'Project Contract: Effective Date',
            Waive_Reacquisition_Fee_Number_Months__c = 1,
            Waive_Reacq_Fee_In_Initial_Period__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true,
            Approval_Status__c = 'Approved'
        );
        insert cfd;

        Shared_Solar_System__c sss = [
            SELECT Id, (SELECT Id FROM Opportunities__r LIMIT 1)
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
            LIMIT 1
        ];

        Client_Contract__c clientContract = new Client_Contract__c(
            Shared_Solar_System__c = sss.Id,
            Contract__c = contractA.Id,
            CS_Services_Type__c = 'Acquisition & Management',
            Effective_Date__c = System.today(),
            End_Date__c = System.today().addYears(1)
        );
        insert clientContract;
        sss.Reacquisition_Start_Date__c = System.today().addYears(-1);
        update sss;

        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__c, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :sss.Opportunities__r[0].Id
            LIMIT 1
        ];

        Contract customerContract = new Contract(
            AccountId = uas.Opportunity__r.AccountId,
            Assignment_Agreement__c = clientAssignmentAgreement.Id
        );
        insert customerContract;

        Opportunity opportunity = new Opportunity(
            Id = uas.Opportunity__c,
            ContractId = customerContract.Id
        );
        update opportunity;

        Subscription_Order__c so = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Type__c = 'Initial',
            Utility_Account_Subscription__c = uas.Id,
            New_Annual_kWh__c = 4800,
            Previous_Annual_kwh__c = 0
        );
        // so2 should have a Client Invoicing Type of Transfer, which will make Client Invoicing Fee $0, which we should not waive
        Subscription_Order__c so2 = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Type__c = 'Transfer',
            Utility_Account_Subscription__c = uas.Id,
            New_Annual_kWh__c = 5000,
            Previous_Annual_kwh__c = 4800
        );
        Test.startTest();
        // This should test a new transaction, but the ContractRepository's static variables aren't reset here, so we
        // need to do so explicitly.
        ContractRepository.clientContracts = null;
        ContractRepository.contractToFeeDetailMap = null;
        insert so;
        insert so2;
        Test.stopTest();

        List<Client_Invoicing_Memo__c> cims = [
            SELECT Id
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__c = :so.Id
            OR Subscription_Order__c = :so2.Id
        ];
        System.assertEquals(1, cims.size(), 'Expected to create one CIM since we are in the initial period. ' +
                'Contract Start Date: ' + contractA.StartDate + ' SO Effective Date: ' + so.Effective_Date__c);

        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c];
        System.assert(errorLogs.isEmpty(), errorLogs);

        ClientInvoicingFeeAssignmentService assignmentService = new ClientInvoicingFeeAssignmentService(new Set<Id>{so.Id});
        assignmentService.setSubOrderContractFeeDetail();

        cims = [
            SELECT Id
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__c = :so.Id
        ];
        System.assertEquals(1, cims.size(), 'There should still just a single CIM after reassigning a SO with an uninvoiced CIM');

        Invoice__c invoice = new Invoice__c(
            Account__c = account.Id
        );
        insert invoice;
        InvocableClientInvoiceLineItemGenerator.LineItemRequest request = new InvocableClientInvoiceLineItemGenerator.LineItemRequest();
        request.soOrCIMId = cims[0].Id;
        request.invoiceId = invoice.Id;
        InvocableClientInvoiceLineItemGenerator.generateLineItem(new List<InvocableClientInvoiceLineItemGenerator.LineItemRequest>{request});

        assignmentService = new ClientInvoicingFeeAssignmentService(new Set<Id>{so.Id});
        assignmentService.setSubOrderContractFeeDetail();

        cims = [
            SELECT Id
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__c = :so.Id
        ];
        System.assertEquals(2, cims.size(), 'There should be two CIMs after reassigning a SO with an invoiced CIM');

        errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Method__c = 'deleteExistingCIMs'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected an error log for a potential duplicate CIM');
    }

    @IsTest
    private static void testWaiveForProjectDates() {
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
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
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        Subscription_Order__c so = getSubscriptionOrder(25, -100);
        so.Effective_Date__c = Date.newInstance(2020,10,1);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = Date.newInstance(2020,10,1);
        so.Approved_Change_in_Subscription__c = -12;
        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assert(cim != null && so.Client_Invoicing_Fee__c != null,
            'Should get a fee waive for reductions, as long as Client Invoicing Fee is set');

        so = getSubscriptionOrder(25, 0);
        so.Effective_Date__c = Date.newInstance(2020,10,1);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = Date.newInstance(2020,10,1);
        so.Approved_Change_in_Subscription__c = 0;
        cim = service.waiveFeeBasedOnDate(so);
        System.assert(cim == null && so.Client_Invoicing_Fee__c == 0,
            'Should not get a fee waive if there is no Client Invoicing Fee');

        so = getSubscriptionOrder(25, 100);
        so.Effective_Date__c = Date.newInstance(2020,10,1);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = false;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = Date.newInstance(2020,10,1);
        so.Approved_Change_in_Subscription__c = 12;
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
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
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
        ClientInvoicingFeeAssignmentServiceTest.useMocks();
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        mockCancellationCFD();
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        // Since System Change Rounded is not writable, we have to set it when creating the SO...
        Subscription_Order__c so = getSubscriptionOrder(25);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = true;

        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should have not gotten an invoicing memo since the system change on the order is not 0');

        so = getSubscriptionOrder(0);
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

        so = getSubscriptionOrder(0);
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
        ClientInvoicingFeeAssignmentServiceTest.useMocks();
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        mockCancellationCFD();

        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        // Since System Change Rounded is not writable, we have to set it when creating the SO...
        Subscription_Order__c so = getSubscriptionOrder(25);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c = false;

        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertEquals(null, cim,
            'Should have not gotten an invoicing memo since the system change on the order is not 0');

        so = getSubscriptionOrder(0);
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

        so = getSubscriptionOrder(0);
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

        so = getSubscriptionOrder(0);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: Estimated COD or Customer: Assignment Date';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_Estimated_COD__c = System.today().addMonths(-2);
        so.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r.CustomerSignedDate = System.today().addDays(-20);
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Approved_Change_in_Subscription__c = -12;
        service.uasToAssignedCapacityMap = new Map<Id, Decimal>();
        subscriptionSizeAtTimeOfAssignment = -so.Approved_Change_in_Subscription__c * 2;
        service.uasToAssignedCapacityMap.put(Util.getFakeId(Utility_Account_Subscription__c.SObjectType), subscriptionSizeAtTimeOfAssignment);
        cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Should have gotten an invoicing memo to waive this fee, since the customer cancelled 20 days after being assigned');
    }

    @IsTest
    private static void testCIMEffectiveSameAsSO() {
        ContractRepository.initFromSubscriptionOrders(new List<Subscription_Order__c>());
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService();
        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Client_Invoicing_Memo__c.SObjectType
        });
        Subscription_Order__c so = getSubscriptionOrder();
        so.Effective_Date__c = Datetime.newInstanceGmt(2020,1,1);
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c = 'Project: COD';
        so.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c = 1;
        so.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c = true;
        so.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c = System.today();
        Client_Invoicing_Memo__c cim = service.waiveFeeBasedOnDate(so);
        System.assertNotEquals(null, cim,
            'Expected to get an Client Invoicing Memo for Project COD to be waived in the initial period');
        System.assertEquals(DateUtil.convertGmtToDate(so.Effective_Date__c), cim.Effective_Date__c,
            'Expected the CIM Effective Date to be the same as the SO');
    }

    private static Subscription_Order__c getSubscriptionOrder() {
        return getSubscriptionOrder(25, 100);
    }
    private static Subscription_Order__c getSubscriptionOrder(Decimal systemChangeRounded) {
        return getSubscriptionOrder(systemChangeRounded, 100);
    }
    private static Subscription_Order__c getSubscriptionOrder(Decimal systemChangeRounded, Decimal clientInvoicingFee) {
        Date today = System.today();
        Map<SObjectField, Object> subscriptionOrderValues = new Map<SObjectField, Object> {
            Subscription_Order__c.Id => Util.getFakeId(Subscription_Order__c.SObjectType),
            Subscription_Order__c.Effective_Date__c => today,
            Subscription_Order__c.Utility_Account_Subscription__c => Util.getFakeId(Utility_Account_Subscription__c.SObjectType),
            Subscription_Order__c.Approved_Change_in_Subscription__c => 12,
            Subscription_Order__c.System_Change_kW_DC_Rounded__c => systemChangeRounded,
            Subscription_Order__c.Client_Invoicing_Fee__c => clientInvoicingFee
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
            Contract.Id => Util.getFakeId(Contract.SObjectType),
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
            Opportunity.Partner_tag_lookup__c => Util.getFakeId(Partner__c.SObjectType),
            Opportunity.Acquired_By_Client_Closed_By_BlueWave__c => true
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

    private static void mockCancellationCFD() {
        ContractRepository.contractToFeeDetailMap = MultiMap.newListInstance();
        ContractFeeDetail mockCancellationCFD = new ContractFeeDetail();
        mockCancellationCFD.upsizing = true;
        mockCancellationCFD.downsizing = false;
        mockCancellationCFD.acquisition = false;
        mockCancellationCFD.reacquisition = true;
        mockCancellationCFD.anchor = true;
        mockCancellationCFD.residential = true;
        mockCancellationCFD.customerSubGroupNotSpecified = true;
        mockCancellationCFD.bcsAcquired = true;
        mockCancellationCFD.closedByBCS = true;
        mockCancellationCFD.amount = .10;
        ContractRepository.contractToFeeDetailMap.putValue((Id) Util.getFakeId(Contract.SObjectType), mockCancellationCFD);
    }
}