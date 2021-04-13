@IsTest
public class GlyntMaineCMPProcessorTest {

    private static final System.RoundingMode ROUND = System.RoundingMode.HALF_UP;
    private static UALSelector ualSelector = new UALSelector();

    @IsTest
    public static void testSampleGlyntExtraction() {
        // Process Glynt JSON data into sObjects, then kick off Queueable job to process UAL sizing
        Test.startTest();
            List<GlyntAPI.ExtractionResponse> extractions = createSampleExtractions();
            GlyntMaineCMPProcessor processor = new GlyntMaineCMPProcessor();
            processor.processExtractions(extractions);
        Test.stopTest();

        // Verify that the correct annual sizing value is set on the UAL
        Utility_Account_Log__c ual = [SELECT Id,Annual_Cost_of_Electricity__c FROM Utility_Account_Log__c];
        System.assertEquals(45955.31, ual.Annual_Cost_of_Electricity__c, 'Invalid annual sizing on UAL');
    }

    @IsTest
    public static void testDataTranspositionAndSizingCalculations() {
        List<GlyntAPI.ExtractionResponse> extractions = createSampleExtractions();
        GlyntMaineCMPProcessor processor = new GlyntMaineCMPProcessor();
        processor.processExtractions(extractions);

        // Verify UDR information has been transposed from Glynt Extractions
        List<Utility_Data_Request__c> utilityDataRequests = [
            SELECT Id, Header_Status__c, Detail_Status__c, Request_Status_new__c, Customer_Name__c,
                Address_Line_1__c, Address_Line_2__c, Meter_Number__c, Glynt_Amount_Due__c, Glynt_Monthly_kWh_Usage__c,
                Glynt_Bill_Start_Date__c, Glynt_Bill_End_Date__c,
            (SELECT Id FROM Utility_Data_Request_Periods__r)
            FROM Utility_Data_Request__c
            WHERE Id IN : processor.udrsProcessedByGlynt
            ORDER BY Glynt_Bill_Start_Date__c ASC
        ];
        System.assertEquals(3, utilityDataRequests.size(), 'Incorrect number of extractions processed');
        for (Utility_Data_Request__c udr : utilityDataRequests) {
            System.assertEquals('Complete', udr.Header_Status__c, 'Header status should be "Complete"');
            System.assertEquals('Complete', udr.Detail_Status__c, 'Detail status should be "Complete"');
            System.assertEquals('Complete', udr.Request_Status_new__c, 'Request status should be "Complete"');
            System.assertNotEquals(null, udr.Address_Line_1__c, 'Address Line 1 should not be null');
            System.assertNotEquals(null, udr.Address_Line_2__c, 'Address Line 2 should not be null');
            System.assertNotEquals(null, udr.Meter_Number__c, 'Meter number should not be null');
            System.assertNotEquals(null, udr.Glynt_Amount_Due__c, 'Amount due should not be null');
            System.assertNotEquals(null, udr.Glynt_Monthly_kWh_Usage__c, 'Monthly kWh Usage should not be null');
            System.assertNotEquals(null, udr.Glynt_Bill_Start_Date__c, 'Bill start date should not be null');
            System.assertNotEquals(null, udr.Glynt_Bill_End_Date__c, 'Bill end date should not be null');
            System.assertEquals(GlyntMaineCMPProcessor.NUMBER_OF_PREVIOUS_USAGE_PERIODS_TO_CAPTURE + 1,
                udr.Utility_Data_Request_Periods__r.size(), 'Incorrect number of avg usage periods captured');
        }

        // Perform calculations to determine UAL annual cost sizing
        Test.startTest();
            processor = new GlyntMaineCMPProcessor(processor.udrsProcessedByGlynt);
            processor.uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{Utility_Account_Log__c.SObjectType});
            processor.setAnnualCostOnUtilityAccountLogs();
        Test.stopTest();

        // Verify that the annual sizing calculation is using the right values from Glynt Extractions
        // Refer to the sample Maine CMP Sizing .xlsx provided by Gina for calculating this data
        // NOTE: Excel may show rounded numbers in the sample document but uses non-rounded values in calculations!!
        GlyntMaineCMPProcessor.UtilityAccountSizing sizingObj = processor.sizingObjects[0];
        System.assertEquals(4107.75, utilityDataRequests[0].Glynt_Amount_Due__c, 'Incorrect amount due on UDR 1');
        System.assertEquals(4345.08, utilityDataRequests[1].Glynt_Amount_Due__c, 'Incorrect amount due on UDR 2');
        System.assertEquals(4513.82, utilityDataRequests[2].Glynt_Amount_Due__c, 'Incorrect amount due on UDR 3');

        System.assertEquals(38656, sizingObj.totalMonthlyUsageMap.get(1).round(ROUND), 'Invalid total monthly usage for January');
        System.assertEquals(38585, sizingObj.totalMonthlyUsageMap.get(2).round(ROUND), 'Invalid total monthly usage for February');
        System.assertEquals(35432, sizingObj.totalMonthlyUsageMap.get(3).round(ROUND), 'Invalid total monthly usage for March');
        System.assertEquals(44172, sizingObj.totalMonthlyUsageMap.get(4).round(ROUND), 'Invalid total monthly usage for April');
        System.assertEquals(41948, sizingObj.totalMonthlyUsageMap.get(5).round(ROUND), 'Invalid total monthly usage for May');
        System.assertEquals(45485, sizingObj.totalMonthlyUsageMap.get(6).round(ROUND), 'Invalid total monthly usage for June');
        System.assertEquals(44878, sizingObj.totalMonthlyUsageMap.get(7).round(ROUND), 'Invalid total monthly usage for July');
        System.assertEquals(45027, sizingObj.totalMonthlyUsageMap.get(8).round(ROUND), 'Invalid total monthly usage for August');
        System.assertEquals(42605, sizingObj.totalMonthlyUsageMap.get(9).round(ROUND), 'Invalid total monthly usage for September');
        System.assertEquals(41807, sizingObj.totalMonthlyUsageMap.get(10).round(ROUND), 'Invalid total monthly usage for October');
        System.assertEquals(42594, sizingObj.totalMonthlyUsageMap.get(11).round(ROUND), 'Invalid total monthly usage for November');
        System.assertEquals(40889, sizingObj.totalMonthlyUsageMap.get(12).round(ROUND), 'Invalid total monthly usage for December');

        System.assertEquals(502075, sizingObj.totalAnnualKwh.round(ROUND), 'Invalid total annual kwh calculated');
        System.assertEquals(51061.46, sizingObj.estimatedAnnualCost.setScale(2), 'Invalid estimated annual cost');
    }

    /**
     * @description Creates GlyntAPI.ExtractionResponse apex objects available to test with
     *              Test data is retrieved by Static Resource .txt files containing raw JSON e.g. 'GlyntCMPExtractSample1'
     * @return List<GlyntAPI.ExtractionResponse> for testing
     */
    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation, PMD.OperationWithLimitsInLoop')
    public static List<GlyntAPI.ExtractionResponse> createSampleExtractions() {
        List<GlyntAPI.ExtractionResponse> extractionResponses = new List<GlyntAPI.ExtractionResponse>();
        List<String> utilityDataRequestIds = buildUtilityDataRequests();
        Integer numberOfTestUtilityDataRequests = utilityDataRequestIds.size();

        // Loop through available UDR Id's and construct individual GlyntAPI.ExtractionResponse objects
        for (Integer i = 1; i <= numberOfTestUtilityDataRequests; i++) {
            String staticResourceName = 'GlyntCMPExtractSample'+i ; // Static resources named GlyntCMPExtractSample1, GlyntCMPExtractSample2, etc.
            String glyntJSON = [SELECT Body FROM StaticResource WHERE Name =: staticResourceName]?.Body.toString();
            System.assert(glyntJSON != null, 'Missing static resource sample JSON file for Glynt CMP, named ' + staticResourceName);
            GlyntAPI.ExtractionResponse extraction = (GlyntAPI.ExtractionResponse)
                JSON.deserialize(glyntJSON, GlyntAPI.ExtractionResponse.class);

            // Set TAGS field which Glynt will send back to us containing a STRING of the ID of the related UDR record
            extraction.tags = new List<String>{utilityDataRequestIds[i-1]};
            extractionResponses.add(extraction);
        }
        return extractionResponses;
    }

    /**
     * @description Constructs and inserts 3 Glynt UDRs on the specified UAL as will occur during intended app flow
     *              Ignores file uploads/document links for UDRs and just creates shell UDR objects for processing here
     * @return List of IDs of UDR records that are stored in the database successfully
     */
    public static List<String> buildUtilityDataRequests() {
        Utility__c utility = new Utility__c(
            Name = 'Utility',
            Utility_Data_Collection_Mechanism__c = 'File Upload',
            Use_Glynt__c = true,
            Utility_DUNS_Number__c = '2582105'
        );
        insert utility;
        Lead lead = new Lead(
            FirstName='Test',
            LastName='Lead',
            Email='test.lead@bluewavesolar.com',
            Company='Test Company'
        );
        insert lead;
        Account propertyAccount = new Account(
            Name = 'Test Property Account'
        );
        insert propertyAccount;
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = lead.Id,
            Account__c = propertyAccount.Id,
            Utility_lookup__c = utility.Id,
            Name = '350827350838',
            Premise_Number__c = '12345',
            QC_Status__c = 'Pending Utility Data'
        );
        insert ual;

        ual = ualSelector.selectUalsWithUdrs(new List<String>{lead.Id})[0];
        Utility_Data_Request__c udr1 = UtilityDataRequestBuilder.constructNewUDR(ual); // UDR for Bill #1
        Utility_Data_Request__c udr2 = UtilityDataRequestBuilder.constructNewUDR(ual); // UDR for Bill #2
        Utility_Data_Request__c udr3 = UtilityDataRequestBuilder.constructNewUDR(ual); // UDR for Bill #3
        insert new List<Utility_Data_Request__c>{udr1, udr2, udr3};
        return new List<String>{udr1.Id, udr2.Id, udr3.Id};
    }
}