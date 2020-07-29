@isTest
public class ClientInvoicingFeeWaiveServiceTest {
    @IsTest
    private static void testSetSubscriptionOrderAcquisitionFee() {
        ClientInvoicingFeeWaiveService service = new ClientInvoicingFeeWaiveService(null);
        useMocks();
        List<Subscription_Order__c> orders = getSubscriptionOrderMocks();
        System.assertEquals(13,orders.size());

        service.uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Client_Invoicing_Memo__c.SObjectType});
        service.setFeesToWaive(orders);

        List<Client_Invoicing_Memo__c> memosToInsert = (List<Client_Invoicing_Memo__c>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'Client_Invoicing_Memo__c');

        for (Client_Invoicing_Memo__c memo : memosToInsert) {
            String subOrderIdAsString = memo.Subscription_Order__c;

            // All subscription orders are 12 kW with a $0.10/W, so expect $-120 for a fully waived fee

            switch on subOrderIdAsString {
                when 'a9W3F000000A1P6UAK' {
                    System.assertEquals(-1200,memo.Amount__c,'Expected this fee to be waived with a COD Date Filter');
                }
                when 'a9W3F000000A1P7UAK' {
                    System.assert(false,'Did not expect this fee to be waived with a COD Date Filter');
                }
                when 'a9W3F000000A2P7UAK' {
                    System.assertEquals(-1200,memo.Amount__c,'Expected this fee to be waived with a PTO Date Filter');
                }
                when 'a9W3F000000A2P6UAK' {
                    System.assert(false,'Did not expect this fee to be waived with a PTO Date Filter');
                }
                when 'a9W3F000000A1P8UAK' {
                    System.assertEquals(-1200,memo.Amount__c,'Expected this fee to be waived with a First Bill Date Filter');
                }
                when 'a9W3F000000A1P9UAK' {
                    System.assert(false,'Did not expect this fee to be waived with a First Bill Date Filter');
                }
                when 'a9W3F000000A1Q9UAK' {
                    System.assert(false,'Did not expect this fee to be waived with a Contract Effective Date Filter');
                }
                when 'a9W3F000000A1R9UAK' {
                    System.assertEquals(-1200,memo.Amount__c,'Expected this fee to be waived with a Contract Effective Date Filter');
                }
                when 'a9W3F000000A1S9UAK' {
                    System.assertEquals(-1200,memo.Amount__c,'Expected this fee to be waived because it is under the 5% project max');
                }
                when 'a9W3F000000A1T9UAK' {
                    // Only 9.24 kW left before hitting 5% cap, so only partially waived:
                    System.assertEquals(-923.57,memo.Amount__c, 'Expected this fee to be waived because it is under the 5% project max');
                }
                when 'a9W3F000000A1U7UAK' {
                    System.assert(false,'Did not expect this fee to be waived because it is over the 5% project max');
                }
                when 'a9W3F000000A2U7UAK' {
                    System.assert(false,'Did not expect this fee to be waived because it is over the 5% project max');
                }
                when 'a9W3F000000A1P8NNN' {
                    // 18kW Assigned to Client Agreement with $0.09/W Fee = $162
                    System.assertEquals(-1620,memo.Amount__c,'Expected this fee to be waived with a Customer Assignment Date Filter');
                }
            }
        }
        System.assertEquals(7,memosToInsert.size());
    }

    private static void useMocks() {
        ClientInvoicingFeeWaiveService.assignmentService = (ClientInvoicingFeeAssignmentService) Test.createStub(ClientInvoicingFeeAssignmentService.class, new MockFeeAssignment());
        ClientInvoicingFeeWaiveService.clientInvoicingMemoSelector = (ClientInvoicingMemoSelector) Test.createStub(ClientInvoicingMemoSelector.class, new MockClientInvoicingMemoSelector());
        ClientInvoicingFeeWaiveService.subscriptionOrderSelector = (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
    }

    public class MockClientInvoicingMemoSelector extends MockProvider {
        public MockClientInvoicingMemoSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String queryData = '{"a1J3F00000122b7UAA":39.76434,"a1J3F00000122b8UAA":101.788544}';

            Map<Id,Decimal> sssToWaivedAmountMap = (Map<Id,Decimal>) JSON.deserialize(queryData, Map<Id,Decimal>.class);

            switch on methodCall.stubbedMethodName {
                when 'getWaivedFeesBySSS' {
                    return sssToWaivedAmountMap;
                }
            }
            return null;
        }
    }

    public class MockSubscriptionOrderSelector extends MockProvider {
        public MockSubscriptionOrderSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String queryData = '{"a1d3F0000017AA1QAM":18,"a1d3F0000014EV1QAM":5.345}';

            Map<Id,Decimal> uasToAssignedCapacityMap = (Map<Id,Decimal>) JSON.deserialize(queryData, Map<Id,Decimal>.class);

            switch on methodCall.stubbedMethodName {
                when 'getSubscriptionOrdersAssignedToClient' {
                    return uasToAssignedCapacityMap;
                }
            }
            return null;
        }
    }

    public class MockFeeAssignment extends MockProvider {
        public MockFeeAssignment() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getCancellationFee' {
                    return 0.09;
                }
            }
            return null;
        }
    }

    public static List<Subscription_Order__c> getSubscriptionOrderMocks(){
        Date today = System.Today();
        Date sixMonthsAgo = today.addMonths(-6);
        Date fourMonthsAgo = today.addMonths(-4);
        Date monthFromToday = today.addMonths(1);

        String queryData = '[' +
            '{"Id":"a9W3F000000A1P6UAK","Effective_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Utility_Account_Subscription__c":"a1d3F0000013EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":8,"Waive_Reacquisition_Fee_Project_Date__c":"Project: COD","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000013EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO8EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"'+ String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO8EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000014EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":2,"Waive_Reacquisition_Fee_Project_Date__c":"Project: COD","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000014EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2P6UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000013EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":2,"Waive_Reacquisition_Fee_Project_Date__c":"Project: PTO","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000013EV1QAM",' +
            '"Opportunity__c":"0063F00000AAO8EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000AAO8EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2P7UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000014EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":8,"Waive_Reacquisition_Fee_Project_Date__c":"Project: PTO","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000014EV1QAM",' +
            '"Opportunity__c":"0063F00000MVO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P8UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000015EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":6,"Waive_Reacquisition_Fee_Project_Date__c":"Project: First Customer Bill Date","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000015EV1QAM",' +
            '"Opportunity__c":"0063F00000MXO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MXO9EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":0,"Waive_Reacquisition_Fee_Project_Date__c":"Project: First Customer Bill Date","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KHH9QAO","Client_Management_Contract__c":"8003F000000KHH9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1Q9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"'+ String.valueOf(fourMonthsAgo) + '"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":1,"Waive_Reacquisition_Fee_Project_Date__c":"Contract: Effective Date","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KHH9QAO","Client_Management_Contract__c":"8003F000000KHH9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Non-Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1R9UAK","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000016EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"'+ String.valueOf(fourMonthsAgo) + '"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":7,"Waive_Reacquisition_Fee_Project_Date__c":"Contract: Effective Date","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Non-Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1S9UAK","Effective_Date__c":"'+ String.valueOf(today) + '","Utility_Account_Subscription__c":"a1d3F0000017EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":null,"Waive_Reacquisition_Fee_Project_Date__c":null,"Waive_Reacquisition_Fee_Max_Project__c":5},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000017EV1QAM",' +
            '"Opportunity__c":"0063F00000NWO9EQAX","Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Non-Residential","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1T9UAK","Effective_Date__c":"'+ String.valueOf(today) +  '","Utility_Account_Subscription__c":"a1d3F0000018EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":null,"Waive_Reacquisition_Fee_Project_Date__c":null,"Waive_Reacquisition_Fee_Max_Project__c":5},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000018EV1QAM",' +
            '"Opportunity__c":"0063F00000XQO9EQAX","Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000NWO9EQAX","Customer_Group__c":"Anchor","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000xxIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y7WrnQAF","RecordType":{"Name":"Client Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1U7UAK","Effective_Date__c":"'+ String.valueOf(today) + '","Utility_Account_Subscription__c":"a1d3F0000019EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":null,"Waive_Reacquisition_Fee_Project_Date__c":null,"Waive_Reacquisition_Fee_Max_Project__c":5},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000019EV1QAM",' +
            '"Opportunity__c":"0063F00000XQO9EAAA","Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MVO9EQAX","Customer_Group__c":"Anchor","Customer_Sub_Group__c":"Public Offtake","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A1P8NNN","Effective_Date__c":"'+ String.valueOf(today) +'","Utility_Account_Subscription__c":"a1d3F0000017AA1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":0,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":12,"Waive_Reacquisition_Fee_Project_Date__c":"Customer: Assignment Date","Waive_Reacquisition_Fee_Max_Project__c":null},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000016EV1QAM",' +
            '"Opportunity__c":"0063F00000MWO9EQAX","Shared_Solar_System__c":"a1J3F00000122b8UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KHH9QAO","Client_Management_Contract__c":"8003F000000KHH9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":null},' +
            '"Opportunity__r":{"Id":"0063F00000MWO9EQAX","Customer_Group__c":"Residential","Assignment_Agreement__r":{"CustomerSignedDate":"' + String.valueOf(sixMonthsAgo) +'"},' +
            '"Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}},' +
            '{"Id":"a9W3F000000A2U7UAK","Effective_Date__c":"'+ String.valueOf(today) + '","Utility_Account_Subscription__c":"a1d3F0000019EV1QAM",' +
            '"Approved_Change_in_Subscription__c":12.00,"System_Change_kW_DC_Rounded__c":25,"Contract_Fee_Detail__r":{"Fee__c":0.10,"Contract__r":{"StartDate":"2020-05-01"},' +
            '"Acquisition_Type_Reacquisition__c":true, "Waive_Reacquisition_Fee_Number_Months__c":null,"Waive_Reacquisition_Fee_Project_Date__c":null,"Waive_Reacquisition_Fee_Max_Project__c":5},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3F0000025EV1QAM",' +
            '"Opportunity__c":"0063F00000ZZO9EAAA","Shared_Solar_System__c":"a1J3F00000122b7UAA",' +
            '"Shared_Solar_System__r":{"Client_Acquisition_Contract__c":"8003F000000KMD9QAO","Client_Management_Contract__c":"8003F000000KNC9QAO",' +
            '"Total_System_Size_kWh_DC__c":1220,' +
            '"Actual_COD_Date__c":"'+ String.valueOf(sixMonthsAgo) +'","Actual_PTO_Date_MANUAL__c":"' + String.valueOf(sixMonthsAgo) + '","First_Bill_Date__c":"'+ String.valueOf(fourMonthsAgo) + '",' +
            '"Reacquisition_Start_Date__c":"' + String.valueOf(monthFromToday) + '"},' +
            '"Opportunity__r":{"Id":"0063F00000ZZO9EAAA","Customer_Group__c":"Anchor","Customer_Sub_Group__c":"Public Offtake","Partner_tag_lookup__c":"a0s3F000000thIBQAY","Partner_tag_lookup__r":{"Id":"a0s3F000000thIBQAY", ' +
            '"Account__r":{"Id":"0013F00000Y6WrnQAF","RecordType":{"Name":"Partner Account"}}}' +
            '}}}'+
            ']';
        return (List<Subscription_Order__c>) JSON.deserialize(queryData, List<Subscription_Order__c>.class);
    }
}