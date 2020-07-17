@isTest
public class ClientInvoicingFeeAssignmentServiceTest {
    @IsTest
    private static void testSetSubscriptionOrderAcquisitionFee() {
        useMocks();
        List<Subscription_Order__c> ordersToRun = getSubscriptionOrderMocks();
        System.assertEquals(13,ordersToRun.size());

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
                        'a123F000001VLE7GGG',
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
                        message + 'bcs acquired, public offtake, upsizing, reacq start date is null'
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
                        message + 'bcs acquired, anchor, downsizing, reacq start date is null'
                    );
                }
                when else {
                    System.assert(false,'Did not expect this Sub. Order ID' + subOrderIdAsString);
                }
            }
        }

    }

    @IsTest
    private static void testGetCancellationRate (){
        useMocks();
        List<Subscription_Order__c> ordersToRun = getSubscriptionOrderMocks();
        System.assertEquals(13,ordersToRun.size());

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
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = false,
                Acquisition_Cust_Group_Non_Residential__c = false,
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
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = false,
                Acquisition_Cust_Group_Non_Residential__c = false,
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
            Contract_Fee_Detail__c downsizingAll = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7GGG',
                Contract__c = '8003F000000KNC9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = true,
                Acquisition_Sizing_Type_Upsizing__c = false,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.16
            );
            Contract_Fee_Detail__c sameRateForAll = new Contract_Fee_Detail__c(
                Id = 'a123F000001VLE7HHH',
                Contract__c = '8003F000000KHH9QAO',
                Acquisition_Channels_BCS_Acquired__c = true,
                Acquisition_Channels_Non_BCS_Acquired__c = true,
                Acquisition_Cust_Group_Anchor__c = true,
                Acquisition_Cust_Group_Public_Offtake__c = true,
                Acquisition_Cust_Group_Residential__c = true,
                Acquisition_Cust_Group_Non_Residential__c = true,
                Acquisition_Sizing_Type_Downsizing__c = true,
                Acquisition_Sizing_Type_Upsizing__c = true,
                Acquisition_Type_Acquisition__c = true,
                Acquisition_Type_Reacquisition__c = true,
                Fee__c = 0.17
            );

            List<Contract_Fee_Detail__c> cfdList = new List<Contract_Fee_Detail__c>{
                acqBcsAcquiredNonAnchor, acqNonBcsAcquiredNonAnchor, acqAnchor,
                reacqBcsAcquiredNonAnchor, reacqNonBcsAcquiredNonAnchor, reacqAnchor,
                downsizingAll, sameRateForAll
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
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO8EQAX","Customer_Group__c":"Residential",' +
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
            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Anchor",' +
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
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Public Offtake",' +
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
            '"Opportunity__r":{"Id":"0063F00000ZZO9EAAA","Customer_Group__c":"Public Offtake",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1V9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000020EV1QAM",' +
            '"Approved_Change_in_Subscription__c":-12.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000020EV1QAM",' +
            '"Opportunity__c":"0063F00000ZQO9EQAX",' +
            '"Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO",' +
            '"Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Anchor",' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}}' +
            ']';
        return (List<Subscription_Order__c>) JSON.deserialize(queryData, List<Subscription_Order__c>.class);
    }
}