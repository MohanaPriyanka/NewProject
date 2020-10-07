@IsTest
public class ClientInvoicingFeeAssignmentServiceTest {
    @IsTest
    private static void testCFDsSpecificToSSSes() {
        ClientInvoicingFeeAssignmentService assignmentService = new ClientInvoicingFeeAssignmentService();

        Contract_Fee_Detail__c defaultSSS = new Contract_Fee_Detail__c(
            Id = Util.getFakeId(Contract_Fee_Detail__c.SObjectType),
            Contract__c = Util.getFakeId(Contract.SObjectType),
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Fee__c = 0.10
        );
        Contract_Fee_Detail__c sssSpecific = new Contract_Fee_Detail__c(
            Id = Util.incrementFakeId(defaultSSS.Id),
            Contract__c = Util.getFakeId(Contract.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Fee__c = 10
        );
        Contract_Fee_Detail__c duplicateSSSSpecific = new Contract_Fee_Detail__c(
            Id = Util.incrementFakeId(defaultSSS.Id),
            Contract__c = Util.getFakeId(Contract.SObjectType),
            Shared_Solar_System__c = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Fee__c = 10
        );
        Contract_Fee_Detail__c otherSSSSpecific = new Contract_Fee_Detail__c(
            Id = Util.incrementFakeId(sssSpecific.Id),
            Contract__c = Util.getFakeId(Contract.SObjectType),
            Shared_Solar_System__c = Util.incrementFakeId(sssSpecific.Shared_Solar_System__c),
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Fee__c = 10
        );

        ClientInvoicingFeeAssignmentService.SubscriptionOrder subscriptionOrder =
            new ClientInvoicingFeeAssignmentService.SubscriptionOrder(getSubscriptionOrder());
        Subscription_Order__c subscriptionOrderWithCFD;

        MultiMap nullSSSFeeDetailMap =
            assignmentService.convertContractFeeListToFeeDetailMap(new List<Contract_Fee_Detail__c>{defaultSSS});
        subscriptionOrderWithCFD =
            assignmentService.matchSubscriptionOrderToFee(subscriptionOrder, nullSSSFeeDetailMap);
        System.assertEquals(defaultSSS.Id, subscriptionOrderWithCFD.Contract_Fee_Detail__c,
            'Since there are no system specific CFDs, we expect the SO to match the non-system specific one'
        );

        MultiMap nullSSSAndMatchingSSSFeeDetailMap =
            assignmentService.convertContractFeeListToFeeDetailMap(new List<Contract_Fee_Detail__c>{defaultSSS, sssSpecific});
        System.assertEquals(sssSpecific.Shared_Solar_System__c, subscriptionOrder.sharedSolarSystemId,
            'The test setup should have a SSS-specific CFD and a SO specifying that system');
        subscriptionOrderWithCFD =
            assignmentService.matchSubscriptionOrderToFee(subscriptionOrder, nullSSSAndMatchingSSSFeeDetailMap);
        System.assertEquals(sssSpecific.Id, subscriptionOrderWithCFD.Contract_Fee_Detail__c,
            'Expected to get an SO to update with the SSS-Specific CFD'
        );

        MultiMap nullSSSAndOtherSSSFeeDetailMap =
            assignmentService.convertContractFeeListToFeeDetailMap(new List<Contract_Fee_Detail__c>{defaultSSS, otherSSSSpecific});
        subscriptionOrderWithCFD =
            assignmentService.matchSubscriptionOrderToFee(subscriptionOrder, nullSSSAndOtherSSSFeeDetailMap);
        System.assertEquals(defaultSSS.Id, subscriptionOrderWithCFD.Contract_Fee_Detail__c,
            'There is another SSS-specific CFD, but not the SSS that is on the SO, so the match should use the default CFD'
        );

        System.assertEquals(null, Logger.logs, 'There should be no logs before matching with duplicates');
        MultiMap allCFDsIncludingDuplicatesMap =
            assignmentService.convertContractFeeListToFeeDetailMap(
                new List<Contract_Fee_Detail__c>{defaultSSS, sssSpecific, otherSSSSpecific, duplicateSSSSpecific}
            );
        subscriptionOrderWithCFD =
            assignmentService.matchSubscriptionOrderToFee(subscriptionOrder, allCFDsIncludingDuplicatesMap);
        System.assert(
            sssSpecific.Id == subscriptionOrderWithCFD.Contract_Fee_Detail__c ||
                duplicateSSSSpecific.Id == subscriptionOrderWithCFD.Contract_Fee_Detail__c,
            'We should have selected one of the SSS specific CFDs for this SO'
        );
        System.assertEquals(1, Logger.logs.size(), 'There should be a single list of messages for matchSubscriptionOrderToFee');
        System.assertEquals(1, Logger.logs.values()[0].size(), 'There should just be one log later message for duplicate CFDs found');
        System.assert(Logger.logs.values()[0][0].message.contains('Multiple CFDs found for SO'), Logger.logs.values()[0][0].message);
    }

    @IsTest
    private static void testSetSubscriptionOrderAcquisitionFee() {
        useMocks();
        List<Subscription_Order__c> ordersToRun = getSubscriptionOrderMocks();
        System.assertEquals(14,ordersToRun.size());
        ClientInvoicingFeeAssignmentService service = new ClientInvoicingFeeAssignmentService();
        service.setSubscriptionOrderAcquisitionFee(ordersToRun);
        List<Subscription_Order__c> ordersToUpdate = (List<Subscription_Order__c>)
            FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(service.uow, 'Subscription_Order__c');
        for (Subscription_Order__c order : ordersToUpdate){
            String subOrderIdAsString = order.Id;
            String feeDetailIdAsString = order.Contract_Fee_Detail__c;
            String message = 'Could not match contract fee detail to SO where: ';
            switch on subOrderIdAsString {
                when 'a9W3F000000A1P6UAK' {
                    System.assertEquals(
                        'a123F000001VLE7AAA',
                        feeDetailIdAsString,
                        message + 'bcs acquired, residential, upsizing, reacq start date is in future'
                    );
                }
                when 'a9W3F000000A1P7UAK' {
                    System.assertEquals(
                        'a123F000001VLE7BBB',
                        feeDetailIdAsString,
                        message + 'not bcs acquired, residential, upsizing, reacq start date is in future'
                    );
                }
                when 'a9W3F000000A2P6UAK' {
                    System.assertEquals(
                        'a123F000001VLE7EEE',
                        feeDetailIdAsString,
                        message + 'bcs acquired, residential, upsizing, reacq start date is in past'
                    );
                }
                when 'a9W3F000000A2P7UAK' {
                    System.assertEquals(
                        'a123F000001VLE7BBB',
                        feeDetailIdAsString,
                        message + 'not bcs acquired, residential, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1P8UAK' {
                    System.assertEquals(
                        'a123F000001VLE7AAA',
                        feeDetailIdAsString,
                        message + 'bcs acquired, residential, downsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1P9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7HHH',
                        feeDetailIdAsString,
                        message + 'bcs acquired, residential, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1Q9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7HHH',
                        feeDetailIdAsString,
                        message + 'bcs acquired, non-residential, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1R9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7AAA',
                        feeDetailIdAsString,
                        message + 'bcs acquired, non-residential, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1S9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7BBB',
                        feeDetailIdAsString,
                        message + 'not bcs acquired, non-residential, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1T9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7CCC',
                        feeDetailIdAsString,
                        message + 'not bcs acquired, anchor, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A1U7UAK' {
                    System.assertEquals(
                        'a123F000001VLE7CCC',
                        feeDetailIdAsString,
                        message + 'bcs acquired, anchor, public offtake, upsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A2U7UAK' {
                    System.assertEquals(
                        'a123F000001VLE7DDD',
                        feeDetailIdAsString,
                        message + 'bcs acquired, public offtake, upsizing, reacq start date is in past'
                    );
                }
                when 'a9W3F000000A1V9UAK' {
                    System.assertEquals(
                        'a123F000001VLE7GGG',
                        feeDetailIdAsString,
                        message + 'bcs acquired, non-investment grade anchor, downsizing, reacq start date is null'
                    );
                }
                when 'a9W3F000000A5P7UAK' {
                    System.assertEquals(
                        'a123F000001VLE7III',
                        feeDetailIdAsString,
                        message + 'client acquired, bcs closed'
                    );
                }
                when else {
                    System.assert(false,'Did not expect this Sub. Order ID' + subOrderIdAsString);
                }
            }
        }
        System.assertEquals(14,ordersToUpdate.size());
    }
    @IsTest
    private static void testGetCancellationRate (){
        useMocks();
        List<Subscription_Order__c> ordersToRun = getSubscriptionOrderMocks();
        System.assertEquals(14, ordersToRun.size());
        ClientInvoicingFeeAssignmentService service = new ClientInvoicingFeeAssignmentService();
        service.setSubscriptionOrderAcquisitionFee(ordersToRun);
        System.assertEquals(0.14,service.getCancellationFee(ordersToRun[0]), 'Expected upsizing reacq rate for BCS Acquired Small Offtake');
        System.assertEquals(0.15,service.getCancellationFee(ordersToRun[1]), 'Expected upsizing reacq rate for NON-BCS Acquired Small Offtake');
        System.assertEquals(0.14,service.getCancellationFee(ordersToRun[2]), 'Expected upsizing reacq rate for BCS Acquired Small Offtake');
        System.assertEquals(0.15,service.getCancellationFee(ordersToRun[3]), 'Expected upsizing reacq rate for NON-BCS Acquired Small Offtake');
        System.assertEquals(0.14,service.getCancellationFee(ordersToRun[4]), 'Expected upsizing reacq rate for BCS Acquired Small Offtake');
    }
    private static void useMocks() {
        ClientInvoicingFeeAssignmentService.contractFeeDetailSelector = (ContractFeeDetailSelector) Test.createStub(ContractFeeDetailSelector.class, new MockFeeDetailSelector());
        ClientInvoicingFeeAssignmentService.subscripOrderSelector = (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
    }
    public class MockFeeDetailSelector extends MockProvider {
        public MockFeeDetailSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            Contract_Fee_Detail__c acqBcsAcquiredNonAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7AAA',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = false,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = false,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = false,
                Fee__c = 0.10
            );
            Contract_Fee_Detail__c acqNonBcsAcquiredNonAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7BBB',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = false,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = false,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = false,
                Fee__c = 0.11
            );
            Contract_Fee_Detail__c acqAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7CCC',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = false,
                Acquisition_Cust_Group_Non_Residential__c = false,
                Acq_Anchor_Qualif_Investment_Grade__c = true,
                Acq_Anchor_Qualif_Not_Investment_Grade__c = false,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = false,
                Fee__c = 0.12
            );
            Contract_Fee_Detail__c reacqAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7DDD',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = false,
                Acquisition_Cust_Group_Non_Residential__c = false,
                Acq_Anchor_Qualif_Investment_Grade__c = true,
                Acq_Anchor_Qualif_Not_Investment_Grade__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = false,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.13
            );
            Contract_Fee_Detail__c reacqBcsAcquiredNonAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7EEE',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = false,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = false,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = false,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.14
            );
            Contract_Fee_Detail__c reacqNonBcsAcquiredNonAnchor = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7FFF',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = false,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = false,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = false,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.15
            );
             Contract_Fee_Detail__c anchorDownsizing = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7GGG',
                Contract__c = '8003F000000KNC9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = false,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = false,
                Acquisition_Cust_Group_Non_Residential__c = false,
                Acq_Anchor_Qualif_Investment_Grade__c = false,
                Acq_Anchor_Qualif_Not_Investment_Grade__c = true,
                Acquisition_Sizing_Type_Downsizing__c = true,
                Acquisition_Sizing_Type_Upsizing__c = false,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = false,
                Fee__c = 0.16
            );
             Contract_Fee_Detail__c sameRateForAll = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7HHH',
                Contract__c = '8003F000000KHH9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = false,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acq_Anchor_Qualif_Investment_Grade__c = true,
                Acq_Anchor_Qualif_Not_Investment_Grade__c = true,
                Acquisition_Sizing_Type_Downsizing__c = true,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.17
            );
            Contract_Fee_Detail__c acqClientClosedBCS = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7III',
                Contract__c = '8003F000000KMD9QAO',
                Acquisition_Channels_BCS_Acquired__c = false,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Channels_Closed_by_BCS__c = true,
                Acquisition_Cust_Group_Anchor__c = false,
                Acquisition_Cust_Group_Public_Offtake__c = false,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = false,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = false,
                Fee__c = 0.09
            );
            List<Contract_Fee_Detail__c> cfdList = new List<Contract_Fee_Detail__c>{
                acqBcsAcquiredNonAnchor, acqNonBcsAcquiredNonAnchor, acqClientClosedBCS, acqAnchor,
                reacqBcsAcquiredNonAnchor, reacqNonBcsAcquiredNonAnchor, reacqAnchor,
                anchorDownsizing, sameRateForAll
            };
            switch on methodCall.stubbedMethodName {
                when 'getContractDetailFromContract' {
                    return cfdList;
                }
            }
            return null;
        }
    }
    public class MockSubscriptionOrderSelector extends MockProvider {
        public MockSubscriptionOrderSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectByIds' {
                    return getSubscriptionOrderMocks();
                }
            }
            return null;
        }
    }
    public static List<Subscription_Order__c> getSubscriptionOrderMocks(){
        Date today = System.Today();
        Date monthFromToday = today.addMonths(1);
        Date monthAgo = today.addMonths(-1);
        String queryData = '[' +
            '{"Id":"a9W3F000000A1P6UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000013EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000013EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO8EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO8EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000014EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000014EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2P6UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000013EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000013EV1QAM",' +
            '"Opportunity__c":"0063F00000AAO8EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthAgo) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000AAO8EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2P7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000014EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000014EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P8UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000015EV1QAM",' +
            '"Approved_Change_in_Subscription__c":-12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000015EV1QAM",' +
            '"Opportunity__c":"0063F00000MXO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MXO9EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KHH9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KHH9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1Q9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KHH9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KHH9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Non-Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1R9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Non-Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1S9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000017EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000017EV1QAM",' +
            '"Opportunity__c":"0063F00000NWO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Non-Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1T9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000018EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000018EV1QAM",' +
            '"Opportunity__c":"0063F00000XQO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +

            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Anchor","Underwriting_Criteria__c":"Investment-Grade",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1U7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000019EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000019EV1QAM",' +
            '"Opportunity__c":"0063F00000XQO9EAAA",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +

            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Anchor","Customer_Sub_Group__c":"Public Offtake",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Underwriting_Criteria__c" : "Investment-Grade",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2U7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000019EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000025EV1QAM",' +
            '"Opportunity__c":"0063F00000ZZO9EAAA",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthAgo) + '"},' +

            '"Opportunity__r":{"Id":"0063F00000ZZO9EAAA","Customer_Group__c":"Anchor","Customer_Sub_Group__c":"Public Offtake",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A5P7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000021EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000021EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO6EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO6EQAX",' +
            '"Customer_Group__c":"Residential",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "true",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1V9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000020EV1QAM",' +
            '"Approved_Change_in_Subscription__c":-12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000020EV1QAM",' +
            '"Opportunity__c":"0063F00000ZQO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +

            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Anchor","Underwriting_Criteria__c":"Financial Review",' +
            '"Acquired_By_Client_Closed_By_BlueWave__c" : "false",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}}' +
            ']';
        return (List<Subscription_Order__c>) JSON.deserialize(queryData, List<Subscription_Order__c>.class);
    }

    private static Subscription_Order__c getSubscriptionOrder() {
        Date today = System.today();
        Map<SObjectField, Object> subscriptionOrderValues = new Map<SObjectField, Object> {
            Subscription_Order__c.Id => Util.getFakeId(Subscription_Order__c.SObjectType),
            Subscription_Order__c.Effective_Date__c => today,
            Subscription_Order__c.Utility_Account_Subscription__c => Util.getFakeId(Utility_Account_Subscription__c.SObjectType),
            Subscription_Order__c.Approved_Change_in_Subscription__c => 12,
            Subscription_Order__c.System_Change_kW_DC_Rounded__c => 25
        };
        sfab_FabricatedSObject fabbedSO = new sfab_FabricatedSObject(Subscription_Order__c.class, subscriptionOrderValues);
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
}