/**
 * @description: Processes Maine CMP data extracts from Glynt
 * Tested By: GlyntMaineCMPProcessorTest
 */
public without sharing class GlyntMaineCMPProcessor implements GlyntExtractionService.Processor {

    /* CONSTANTS */
    private static final Integer NUMBER_OF_BILLS_REQUIRED = 3;
    private static final Map<String,Integer> MONTH_STRING_MAP = new Map<String,Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9,
        'Oct' => 10, 'Nov' => 11, 'Dec' => 12};
    @TestVisible private static final Integer NUMBER_OF_PREVIOUS_USAGE_PERIODS_TO_CAPTURE = 12;
    private static final Integer MINIMUM_NUMBER_OF_PREVIOUS_USAGE_PERIODS = 3;
    private static final Id UDRP_RECORD_TYPE_ID =
        Schema.SObjectType.Utility_Data_Request_Period__c.getRecordTypeInfosByName().get('Glynt').recordTypeId;
    private static final Decimal DEFAULT_SIZING_RATIO = 0.9;

    /* STATIC VARS */
    @TestVisible private static UALSelector ualSelector = new UALSelector();

    /* INSTANCE VARS */
    private List<Utility_Account_Log__c> ualsToSetAnnualCost = new List<Utility_Account_Log__c>();
    @TestVisible private List<Id> udrsProcessedByGlynt = new List<Id>();
    @TestVisible private List<GlyntMaineSizing> sizingObjects = new List<GlyntMaineSizing>();
    private String currentUtilityDataRequestId;
    private Boolean processorErrorEncountered = false;
    @TestVisible private fflib_SObjectUnitOfWork uow;

    /**
     * @description Default constructor called from GlyntExtractionService to handle Maine CMP extractions
     *              Referenced dynamically by GlyntExtractionService.handleExtractionResponses()
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public GlyntMaineCMPProcessor() {
    }

    /**
     * @description Processes GlyntAPI.ExtractionResponse into desired Salesforce data structure
     *              Enqueues a job at the end to process average calculations on Utility_Data_Request__c and Utility_Account_Log__c
     * @param extractionResponses GlyntAPI.ExtractionResponse objects containing data from Glynt
     */
    public void processExtractions(List<GlyntAPI.ExtractionResponse> extractionResponses) {
        uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
            Utility_Data_Request__c.SObjectType, Utility_Data_Request_Period__c.SObjectType
        });
        try {
            for (GlyntAPI.ExtractionResponse extraction : extractionResponses) {
                // Verify we received a UDR Id back from Glynt, otherwise we cannot process the current extraction properly
                currentUtilityDataRequestId = !extraction.tags.isEmpty() ? extraction.tags[0] : null;
                if (currentUtilityDataRequestId == null) {
                    Logger.logLater('GlyntMaineCMPProcessor', 'processExtractions',
                        'No UDR Id found in extraction data from Glynt for document id: ' + extraction.id, Logger.ERROR);
                    continue;
                }
                buildUdrpsFromExtraction(extraction.results);
                buildUdrFromExtraction(extraction.results);
                udrsProcessedByGlynt.add(currentUtilityDataRequestId);
            }
            uow.commitWork();
        } catch (Exception e) {
            String message = 'Failed to process Glynt Extractions for Glynt IDs: ';
            for (GlyntAPI.ExtractionResponse extraction : extractionResponses) {
                message += extraction.id + ' ';
            }
            Logger.logLater('GlyntMaineCMPProcessor', 'processExtractions',
                message + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString(), Logger.ERROR);
            processorErrorEncountered = true;
        }

        if (udrsProcessedByGlynt != null && !processorErrorEncountered) {
            setAnnualCostOnUtilityAccountLogs();
        }
        Logger.flushLogs();
    }

    /**
     * @description Calculates annual cost for a Maine CMP customer's account based on Glynt-extracted data
     *              (Method is publicly-exposed in the event of logic needing to be re-run for UALs via anon execute)
     */
    public void setAnnualCostOnUtilityAccountLogs() {
        // Processing from this point on no longer handles database changes to UDRs or UDRPs, and we are now ONLY
        // concerned with changes to the UAL. Instancing new UnitOfWOrk here as a result.
        uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{Utility_Account_Log__c.SObjectType});
        try {
            determineUalsToSetAnnualCost();
            if (ualsToSetAnnualCost.size() != 0) {
                buildSizingObjects();
                updateUALWithSizing();
            }
            uow.commitWork();
        } catch (Exception e) {
            String message = e.getMessage() + ' ' + e.getStackTraceString() + '\n\n' + 'UDRs processed in transaction: ' +
                udrsProcessedByGlynt;
            Logger.logLater('GlyntMaineCMPProcessor', 'setAnnualCostOnUtilityAccountLogs', message, Logger.ERROR);
        }
    }

    /**
     * @description Determine which UALs contain enough data to process account sizing / estimated annual costs
     */
    private void determineUalsToSetAnnualCost() {
        List<Utility_Account_Log__c> uals = ualSelector.selectUalsWithChildUdrs(udrsProcessedByGlynt);
        for (Utility_Account_Log__c ual : uals) {
            Boolean readyToCalcAnnualCost = true;
            if (ual.Utility_Data_Requests__r.size() != NUMBER_OF_BILLS_REQUIRED) {
                String message = 'Invalid number of UDRs (' + ual.Utility_Data_Requests__r.size() + ') on UAL ' + ual.Id +
                    ' for Glynt Maine CMP extraction processing. Please ensure that ' + NUMBER_OF_BILLS_REQUIRED +
                    ' Glynt UDRs exist on this UAL, each representing a single utility bill.';
                Logger.logLater('GlyntMaineCMPProcessor', 'determineUalsToSetAnnualCost', message, Logger.ERROR);
                continue;
            }
            for (Utility_Data_Request__c udr : ual.Utility_Data_Requests__r) {
                if (udr.Request_Status_new__c != 'Complete') {
                    readyToCalcAnnualCost = false;
                }
            }
            if (readyToCalcAnnualCost) {
                ualsToSetAnnualCost.add(ual);
            }
        }
    }

    /**
     * @description Cache utility account information in structured object to assist annual sizing calculations
     */
    private void buildSizingObjects() {
        for (Utility_Account_Log__c ual : ualsToSetAnnualCost) {
            GlyntMaineSizing sizingObj = new GlyntMaineSizing(
                ual.Id, ual.Utility_Data_Requests__r, MINIMUM_NUMBER_OF_PREVIOUS_USAGE_PERIODS
            );
            sizingObjects.add(sizingObj);
        }
    }

    private void updateUALWithSizing() {
        for (GlyntMaineSizing sizingObj : sizingObjects) {
            if (sizingObj.tooFewUsagePeriods) {
                String message = 'Not enough average usage periods (UDRPs) to size customer for UAL ' +
                    sizingObj.utilityAccountLogId + '. Need at least ' + sizingObj.miniumumNumberOfPreviousUsagePeriods +
                    + ', found ' + sizingObj.avgUsagePeriods.size();
                Logger.logLater('GlyntMaineCMPProcessor', 'updateUALWithSizing', message, Logger.ERROR);
                continue;
            }
            Utility_Account_Log__c ual = new Utility_Account_Log__c(
                Id = sizingObj.utilityAccountLogId,
                Annual_Cost_of_Electricity__c = (sizingObj.estimatedAnnualCost * DEFAULT_SIZING_RATIO).setScale(2),
                QC_Status__c = 'Complete'
            );
            uow.registerDirty(ual);
        }
    }

    /**
     * @description Constructs Utility_Data_Request_Period__c (UDRP) records corresponding to Glynt Extraction data
     *              Uses some dynamic apex syntactic sugar to locate and map fields from GlyntAPI.ExtractionResponse,
     *              e.g. E_PreviousUsage1, E_PreviousUsagekWh1 => data translated to fields on UDRP #1
     *                   E_PreviousUsageN, E_PreviousUsagekWhN => data translated to fields on UDRP #N ...
     * @param data GlyntAPI.ExtractionResult for specific extracted document
     */
    private void buildUdrpsFromExtraction(GlyntAPI.ExtractionResult data) {
        // Construct UDRP for the current bill actuals (not averages)
        Utility_Data_Request_Period__c actualsUdrp = new Utility_Data_Request_Period__c(
            RecordTypeId = UDRP_RECORD_TYPE_ID,
            Utility_Data_Request__c = currentUtilityDataRequestId,
            Service_Start_Date__c = parseBillDate(data.E_StartDate.content),
            Service_End_Date__c = parseBillDate(data.E_EndDate.content),
            Measurement_Value__c = Decimal.valueOf(data.E_Usage.content),
            Measurement_Unit__c = 'KH'
        );
        uow.registerNew(actualsUdrp);

        // Construct the UDRPs for the previous usage periods (daily averages data)
        for (Integer i = 1; i <= NUMBER_OF_PREVIOUS_USAGE_PERIODS_TO_CAPTURE; i++) {
            String periodDateString = getDataString('E_PreviousUsage' + i, data);
            String periodAvgDailyUsageString = getDataString('E_PreviousUsagekWh' + i, data);
            if (periodDateString == null || periodAvgDailyUsageString == null) {
                // Glynt may not provide data for these fields, OR we are missing data on the utility bill
                // We do not want to insert partial UDRPs for these usage periods.
                continue;
            }

            Utility_Data_Request_Period__c previousUsageUdrp = new Utility_Data_Request_Period__c(
                RecordTypeId = UDRP_RECORD_TYPE_ID,
                Utility_Data_Request__c = currentUtilityDataRequestId,
                Service_Start_Date__c = parsePreviousUsageDate(periodDateString),
                Measurement_Value__c = Decimal.valueOf(periodAvgDailyUsageString),
                Measurement_Unit__c = 'KH',
                Glynt_Average_Daily_Usage__c = true
            );
            previousUsageUdrp.Service_End_Date__c = previousUsageUdrp.Service_Start_Date__c.addMonths(1).addDays(-1);
            uow.registerNew(previousUsageUdrp);
        }
    }

    private void buildUdrFromExtraction(GlyntAPI.ExtractionResult data) {
        Utility_Data_Request__c utilityDataRequest = new Utility_Data_Request__c(
            Id = currentUtilityDataRequestId,
            Header_Status__c = 'Complete',
            Detail_Status__c = 'Complete',
            Customer_Name__c = data.CustomerName.content,
            Address_Line_1__c = data.ServiceAddressL1.content,
            Address_Line_2__c = data.ServiceAddressL2.content,
            Meter_Number__c = data.E_MeterNumber.content,
            Glynt_Monthly_kWh_Usage__c = data.E_Usage?.content != null ? Decimal.valueOf(data.E_Usage.content) : null,
            Glynt_Bill_Start_Date__c = parseBillDate(data.E_StartDate?.content),
            Glynt_Bill_End_Date__c = parseBillDate(data.E_EndDate?.content)
        );
        if (data.E_TotalDeliveryCharge.content != null && data.E_TotalSupplyCharge.content != null) {
            utilityDataRequest.Glynt_Amount_Due__c = Decimal.valueOf(data.E_TotalDeliveryCharge.content) +
                Decimal.valueOf(data.E_TotalSupplyCharge.content);
        }
        uow.registerDirty(utilityDataRequest);
    }

    private String getDataString(String fieldName, GlyntAPI.ExtractionResult extractionResult) {
        Map<String, Object> extractedDataAsMap = (Map<String, Object>) extractionResult.getParamByString(fieldName);
        return (String) extractedDataAsMap.get('content');
    }

    /**
     * @description Parses Glynt previous usage date string in format '2020 Sep' into Date instance
     * @param glyntUsageDateString Date string provided by Glynt
     * @return Date object representing date string
     */
    private Date parsePreviousUsageDate(String glyntUsageDateString) {
        Integer year = Integer.valueOf(glyntUsageDateString.left(4));
        Integer month = MONTH_STRING_MAP.get(glyntUsageDateString.substringAfter(' '));
        Integer day = 1;
        return Date.newInstance(year, month, day);
    }

    /**
     * @description Parses Glynt date string in format 2020-01-30 to Date instance
     * @param glyntBillDateString Date string provided by Glynt
     * @return Date object representing date string
     */
    private Date parseBillDate(String glyntBillDateString) {
        List<String> dateComponents = glyntBillDateString?.split('-');
        return dateComponents.size() != 3 ? null : Date.newInstance(
            Integer.valueOf(dateComponents[0]),
            Integer.valueOf(dateComponents[1]),
            Integer.valueOf(dateComponents[2])
        );
    }
}