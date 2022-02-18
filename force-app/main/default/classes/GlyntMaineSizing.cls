/**
 * @description: Utility class for Glynt extracts which caches utility bill information and correctly sizes customer
 * Tested By: GlyntMaineCMPProcessorTest
 */
public without sharing class GlyntMaineSizing {
    /* CONSTANTS */
    private static final Map<Integer,Decimal> MONTH_AVG_DAYS_IN_BILL_PERIOD = new Map<Integer,Decimal>{
        1 => 31.275, 2 => 30.55, 3 => 28.3, 4 => 30.675, 5 => 30.375, 6 => 30.65, 7 => 30.675, 8 => 30.925, 9 => 31.35,
        10 => 29.65, 11 => 29.6, 12 => 31.55};

    /* STATIC VARS */
    @TestVisible private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();

    /* INSTANCE VARS*/
    public Id utilityAccountLogId;
    public Id mostRecentUtilityDataRequest;
    public Decimal averageBlendedRate;
    public Decimal estimatedAnnualCost;
    public Decimal totalAnnualKwh;
    public List<Utility_Data_Request__c> utilityDataRequests;
    public List<Utility_Data_Request_Period__c> avgUsagePeriods;
    public Boolean tooFewUsagePeriods = false;
    public Map<Integer,Decimal> totalMonthlyUsageMap = new Map<Integer,Decimal>();
    public Integer miniumumNumberOfPreviousUsagePeriods;

    public GlyntMaineSizing(Id ualId, List<Utility_Data_Request__c> udrs, Integer minUsagePeriods) {
        utilityAccountLogId = ualId;
        utilityDataRequests = udrs;
        miniumumNumberOfPreviousUsagePeriods = minUsagePeriods;
        setMostRecentUtilityDataRequest();
        calcAvgBlendedRate();
        getAvgUsagePeriods();
        generateTotalMonthlyUsageMap();
        calcTotalAnnualKwh();
        calcEstimatedAnnualCost();
    }

    public void setMostRecentUtilityDataRequest() {
        // UDR list retrieved from UALSelector in GlyntMaineCMPProcessor.determineUalsToSetAnnualCost() is sorted by
        // Glynt_Bill_Start_Date__c DESC, so the first UDR in the list SHOULD have the most up-to-date usage info in the
        // form of child UDRP records
        mostRecentUtilityDataRequest = utilityDataRequests[0].Id;
    }

    public void calcAvgBlendedRate() {
        Decimal sumOfBlendedRates = 0;
        for (Utility_Data_Request__c udr : utilityDataRequests) {
            sumOfBlendedRates += udr.Glynt_Blended_Rate__c;
        }
        averageBlendedRate = (sumOfBlendedRates / utilityDataRequests.size()).setScale(15);
    }

    public void getAvgUsagePeriods() {
        avgUsagePeriods = udrpSelector.selectAvgUsagePeriodsByUDR(mostRecentUtilityDataRequest);
        if (avgUsagePeriods.size() < miniumumNumberOfPreviousUsagePeriods) {
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
            totalAnnualKwh = totalAnnualKwh / totalMonthlyUsageMap.size() * 12;
        }
    }

    public void calcEstimatedAnnualCost() {
        Decimal cost = averageBlendedRate * totalAnnualKwh;
        estimatedAnnualCost = cost.setScale(2);
    }
}