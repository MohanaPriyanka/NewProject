/**
 * @description: Processes Maine CMP data extracts from Glynt
 * Tested By: GlyntMaineCMPProcessorTest
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class GlyntMaineCMPProcessor implements GlyntExtractionService.Processor {

    /* CONSTANTS */
    private static final Integer NUMBER_OF_BILLS_REQUIRED = 3;
    private static final Map<String,Integer> MONTH_STRING_MAP = new Map<String,Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9,
        'Oct' => 10, 'Nov' => 11, 'Dec' => 12};
    private static final Map<Integer,Decimal> MONTH_AVG_DAYS_IN_BILL_PERIOD = new Map<Integer,Decimal>{
        1 => 31.275, 2 => 30.55, 3 => 28.3, 4 => 30.675, 5 => 30.375, 6 => 30.65, 7 => 30.675, 8 => 30.925, 9 => 31.35,
        10 => 29.65, 11 => 29.6, 12 => 31.55};
    @TestVisible private static final Integer NUMBER_OF_PREVIOUS_USAGE_PERIODS_TO_CAPTURE = 12;
    private static final Integer MINIMUM_NUMBER_OF_PREVIOUS_USAGE_PERIODS = 3;

    /* STATIC VARS */
    @TestVisible private static UALSelector ualSelector = new UALSelector();
    @TestVisible private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    private static final Id udrpRecordTypeId =
        Schema.SObjectType.Utility_Data_Request_Period__c.getRecordTypeInfosByName().get('Glynt').recordTypeId;

    /* INSTANCE VARS */
    private List<Utility_Account_Log__c> ualsToSetAnnualCost = new List<Utility_Account_Log__c>();
    @TestVisible private List<Id> udrsProcessedByGlynt = new List<Id>();
    @TestVisible private List<UtilityAccountSizing> sizingObjects = new List<UtilityAccountSizing>();
    private String currentUtilityDataRequestId;
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
                currentUtilityDataRequestId = getUtilityDataRequestId(extraction);
                if (currentUtilityDataRequestId == null) {
                    Logger.logLater('GlyntMaineCMPProcessor', 'processExtractions',
                        'No UDR Id found in extraction data from Glynt for document id: ' + extraction.id, 'ERROR');
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
                message += extraction.id = ' ';
            }
            Logger.logLater('GlyntMaineCMPProcessor', 'processExtractions',
                message + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString(), 'ERROR');
        }

        // Kick off the job to calculate average demand for CMP customers and insert data on UAL
        if (udrsProcessedByGlynt != null) {
            setAnnualCostOnUtilityAccountLogs();
        }
        Logger.flushLogs();
    }

    /**
     * @description Calculates annual cost for a Maine CMP customer's account based on Glynt-extracted data
     *              (Method is publicly-exposed in the event of logic needing to be re-run for UALs via anon execute)
     */
    public void setAnnualCostOnUtilityAccountLogs() {
        uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{Utility_Account_Log__c.SObjectType});
        try {
            if (udrsProcessedByGlynt.size() != 0) {
                determineUalsToSetAnnualCost();
            }
            if (ualsToSetAnnualCost.size() != 0) {
                buildSizingObjects();
                updateUALWithSizing();
            }
        } catch (Exception e) {
            String message = e.getMessage() + ' ' + e.getStackTraceString() + '\n\n' + 'UDRs processed in transaction: ' +
                udrsProcessedByGlynt;
            Logger.logLater('GlyntMaineCMPProcessor', 'setAnnualCostOnUtilityAccountLogs', message, 'Error');
        }
        uow.commitWork();
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
                Logger.logLater('GlyntMaineCMPProcessor', 'determineUalsToSetAnnualCost', message, 'Error');
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
            UtilityAccountSizing sizingObj = new UtilityAccountSizing(ual.Id, ual.Utility_Data_Requests__r);
            sizingObjects.add(sizingObj);
        }
        ualsToSetAnnualCost = null; // Var no longer needed
    }

    private void updateUALWithSizing() {
        for (UtilityAccountSizing sizingObj : sizingObjects) {
            if (sizingObj.tooFewUsagePeriods) {
                String message = 'Not enough average usage periods (UDRPs) to size customer for UAL ' +
                    sizingObj.utilityAccountLogId + '. Need at least ' + MINIMUM_NUMBER_OF_PREVIOUS_USAGE_PERIODS +
                    + ', found ' + sizingObj.avgUsagePeriods.size();
                Logger.logLater('GlyntMaineCMPProcessor', 'updateUALWithSizing', message, 'ERROR');
                continue;
            }
            Utility_Account_Log__c ual = new Utility_Account_Log__c(
                Id = sizingObj.utilityAccountLogId,
                Annual_Cost_of_Electricity__c = (sizingObj.estimatedAnnualCost * 0.9).setScale(2) // 90% is the default sizing
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
        List<Utility_Data_Request_Period__c> udrps = new List<Utility_Data_Request_Period__c>();

        // Construct UDRP for the current bill actuals (not averages)
        Utility_Data_Request_Period__c actualsUdrp = new Utility_Data_Request_Period__c(
            RecordTypeId = udrpRecordTypeId,
            Utility_Data_Request__c = currentUtilityDataRequestId,
            Service_Start_Date__c = parseBillDate(data.E_StartDate.content),
            Service_End_Date__c = parseBillDate(data.E_EndDate.content),
            Measurement_Value__c = Decimal.valueOf(data.E_Usage.content),
            Measurement_Unit__c = 'KH'
        );
        udrps.add(actualsUdrp);

        // Construct the UDRPs for the previous usage periods (daily averages data)
        for (Integer i = 1; i <= NUMBER_OF_PREVIOUS_USAGE_PERIODS_TO_CAPTURE; i++) {
            String periodDateString = getDataString('E_PreviousUsage' + i, data);
            String periodAvgDailyUsageString = getDataString('E_PreviousUsagekWh' + i, data);
            if (periodDateString == null || periodAvgDailyUsageString == null) {
                continue; // Don't attempt to insert data we don't have in the extract
            }

            Utility_Data_Request_Period__c previousUsageUdrp = new Utility_Data_Request_Period__c(
                RecordTypeId = udrpRecordTypeId,
                Utility_Data_Request__c = currentUtilityDataRequestId,
                Service_Start_Date__c = parsePreviousUsageDate(periodDateString),
                Measurement_Value__c = periodAvgDailyUsageString != null ? Decimal.valueOf(periodAvgDailyUsageString) : null,
                Measurement_Unit__c = 'KH',
                Glynt_Average_Daily_Usage__c = true
            );
            previousUsageUdrp.Service_End_Date__c = previousUsageUdrp.Service_Start_Date__c.addMonths(1).addDays(-1);
            udrps.add(previousUsageUdrp);
        }

        uow.registerNew(udrps);
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

    private String getUtilityDataRequestId(GlyntAPI.ExtractionResponse extraction) {
        return !extraction.tags.isEmpty() ? extraction.tags[0] : null;
    }

    private String getDataString(String fieldName, GlyntAPI.ExtractionResult extractionResult) {
        String serializedData = JSON.serialize(extractionResult.getParamByString(fieldName));
        GlyntAPI.ExtractedData data = (GlyntAPI.ExtractedData) JSON.deserialize(serializedData, GlyntAPI.ExtractedData.class);
        return data?.content != null ? data.content : null;
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
        return dateComponents == null ? null : Date.newInstance(
            Integer.valueOf(dateComponents[0]),
            Integer.valueOf(dateComponents[1]),
            Integer.valueOf(dateComponents[2])
        );
    }

    /**
     * @description Apex object used to cache account information related to sizing, to make actual sizing calculation
     *              easier when necessary
     */
    public class UtilityAccountSizing {
        public Id utilityAccountLogId;
        public Id mostRecentUtilityDataRequest;
        public Decimal averageBlendedRate;
        public Decimal estimatedAnnualCost;
        public Decimal totalAnnualKwh;
        public List<Utility_Data_Request__c> utilityDataRequests;
        public List<Utility_Data_Request_Period__c> avgUsagePeriods;
        public Boolean tooFewUsagePeriods = false;
        public Map<Integer,Decimal> totalMonthlyUsageMap = new Map<Integer,Decimal>();

        public UtilityAccountSizing(Id ualId, List<Utility_Data_Request__c> udrs) {
            utilityAccountLogId = ualId;
            utilityDataRequests = udrs;
            setMostRecentUtilityDataRequest();
            calcAvgBlendedRate();
            getAvgUsagePeriods();
            generateTotalMonthlyUsageMap();
            calcTotalAnnualKwh();
            calcEstimatedAnnualCost();
        }

        public void calcAvgBlendedRate() {
            Decimal sumOfBlendedRates = 0;
            for (Utility_Data_Request__c udr : utilityDataRequests) {
                sumOfBlendedRates += udr.Glynt_Blended_Rate__c;
            }
            averageBlendedRate = (sumOfBlendedRates / utilityDataRequests.size()).setScale(15);
        }

        public void setMostRecentUtilityDataRequest() {
            // UDR list retrieved from UALSelector in determineUalsToSetAnnualCost() is sorted by Glynt_Bill_Start_Date__c DESC,
            // so the first UDR in the list SHOULD have the most up-to-date usage info in the form of child UDRP records
            mostRecentUtilityDataRequest = utilityDataRequests[0].Id;
        }

        public void getAvgUsagePeriods() {
            avgUsagePeriods = udrpSelector.selectAvgUsagePeriodsByUDR(mostRecentUtilityDataRequest);
            if (avgUsagePeriods.size() < MINIMUM_NUMBER_OF_PREVIOUS_USAGE_PERIODS) {
                tooFewUsagePeriods = true;
            }
        }

        public void generateTotalMonthlyUsageMap() {
            for (Utility_Data_Request_Period__c avgUsageUdrp : avgUsagePeriods) {
                Integer monthNumber = avgUsageUdrp.Service_Start_Date__c.month();
                Decimal avgDaysInMonth = MONTH_AVG_DAYS_IN_BILL_PERIOD.get(monthNumber);
                Decimal averageDailyUsage = avgUsageUdrp.Measurement_Value__c;
                totalMonthlyUsageMap.put(monthNumber, averageDailyUsage * avgDaysInMonth);
            }
        }

        public void calcTotalAnnualKwh() {
            totalAnnualKwh = 0;
            for (Decimal totalMonthlyUsage : totalMonthlyUsageMap.values()) {
                totalAnnualKwh += totalMonthlyUsage;
            }
            if (totalMonthlyUsageMap.size() < 12) {
                // Calculation is different if we have fewer than 12 months of avg usage data, use average and multiply by 12
                totalAnnualKwh = Math.round(totalAnnualKwh / totalMonthlyUsageMap.size() * 12);
            }
        }

        public void calcEstimatedAnnualCost() {
            Decimal cost = averageBlendedRate * totalAnnualKwh;
            estimatedAnnualCost = cost.setScale(2);
        }
    }
}