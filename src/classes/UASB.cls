/**
 * @description Created by jeff parlin on 3/1/21.
 *
 * Tested By: TransferSheetBillingTest
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public virtual class UASB {

    @TestVisible protected final System.RoundingMode DEFAULT_ROUND = RoundingMode.HALF_UP;
    protected Integer productionDecimalRounding;
    protected Schedule_Z_Subscription__c szs;
    protected Transfer__c transfer;
    protected UASB__c uasb = new UASB__c();
    private Decimal subscriptionProduction;
    private String billingMethod;
    private Decimal nmcDiscountOverride;
    private Decimal solarElectricityRateOverride;

    /**
     * @description No-arg default constructor
     */
    public UASB(){
    }

    /**
     * @description Class constructor for Standard UASB
     * @param szs Schedule Z Subscription, or Allocation Schedule record
     * @param transfer Transfer record
     * @param productEscalatorMap Map of Product Escalators to Apply to UASB, if needed
     */
    public UASB(
        Schedule_Z_Subscription__c szs,
        Transfer__c transfer,
        Map<Id,List<Product_Escalator__c>> productEscalatorMap)
    {
        this.szs = szs;
        this.transfer = transfer;
        this.billingMethod = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c;
        this.productionDecimalRounding =(Integer) szs.Schedule_Z__r.Shared_Solar_System__r.Utility__r.UASB_Number_of_Decimals__c;
        this.subscriptionProduction = getSubscriptionProduction();
        setEscalatorOverrides(productEscalatorMap);
    }

    /**
     * @description Returns the appropriate UASB record for the given inputs and situation
     * @return UASB__c record corresponding to inputs
     */
    public UASB__c getSObject() {
        try {
            createSObject();
        } catch (Exception e) {
            String err = 'Failed to generate UASB for Subscription ' + szs.Id + '. Reason: \n' +
                e.getMessage() + '\n' + e.getStackTraceString();
            throw new Util.BWException(err);
        }
        return uasb;
    }

    /**
     * @description Creates the appropriate UASB record for the given inputs and situation
     */
    public virtual void createSObject() {
        setCommonFields();
        setSpecificFields();
    }

    /**
     * @description Sets fields which are common to all UASBs, regardless of type
     */
    private void setCommonFields() {
        uasb.Account__c = szs.Utility_Account_Subscription__r.Opportunity__r.AccountId;
        uasb.Opportunity__c = szs.Utility_Account_Subscription__r.Opportunity__c;
        uasb.Transfer__c = transfer.Id;
        uasb.Utility_Account_Subscription__c = szs.Utility_Account_Subscription__c;
        uasb.Date__c = transfer.Bill_Period__r.Bill_Date__c;
        uasb.Schedule_Z_Subscription__c = szs.Id;
        uasb.Billing_Period_Start_Date__c = transfer.Date_of_Transfer__c;
        uasb.Billing_Period_End_Date__c = transfer.Date_of_Transfer__c.addMonths(1);
        uasb.PreGen_IsPreGen__c = szs.Utility_Account_Subscription__r.Finaled__c;
        uasb.Shared_Solar_System__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c;
        uasb.Externally_Serviced__c = szs.Utility_Account_Subscription__r.Externally_Serviced__c;
        uasb.PreGen_Name_on_Account__c = getCustomerName();
        uasb.PreGen_Utility_Acct__c = getUtilityAccountNumber();
    }

    /**
     * @description Sets fields which are specific to this type of UASB. In this case, this is a "Standard UASB"
     */
    public virtual void setSpecificFields() {
        uasb.Total_System_NMCs__c = transfer.Attempted_Transfer__c;
        uasb.Total_System_Production_kWh__c = transfer.Attempted_kWh_Transfer__c;
        uasb.Subscription_Production_kWh_Static__c = subscriptionProduction;
        uasb.NMC_Rate__c = transfer.Default_Credit_Value__c;
        uasb.Share_of_System__c = szs.Percent_Share__c;
        uasb.Credits_Allocated__c = getSubscriptionNMCs();
        uasb.Customer_Subscription_KW_DC__c = szs.Customer_Subscription_kW_DC__c;
        uasb.NMC_Discount__c = getNMCDiscount();
        uasb.Total_System_Size_kW_DC__c = szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
        uasb.NM_Rate_Floor__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c;
        uasb.Pricing_Structure__c = szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c;
        uasb.Solar_Electricity_Rate__c = getSolarElectricityRate();
        uasb.Size_off_NMCs__c = billingMethod == 'NMC' ? true : false;
    }

    private String getCustomerName() {
        String customerName = szs.Utility_Account_Subscription__r.Name_on_Account_From_Log__c;
        customerName = customerName != null ? customerName.substring(0,Math.min(customerName.length(),49)) : customerName;
        return customerName;
    }

    private String getUtilityAccountNumber() {
        String ualNumber = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
        String premiseNumber = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c;
        if (premiseNumber != null && premiseNumber.length() > 1) {
            return premiseNumber;
        }
        return ualNumber;
    }

    // Calculate Credits Allocated to Customer, either as % of kWh or % of $
    private Decimal getSubscriptionNMCs() {
        Decimal netMeteringCredits = 0;
        String creditsRoundMethod = szs.Schedule_Z__r.Shared_Solar_System__r.Utility__r.Credits_Allocated_Rounding_Method__c;
        switch on billingMethod {
            when 'NMC' {
                // Xcel Applies rate in 2 stages:
                netMeteringCredits = (szs.Percent_Share__c / 100) * transfer.Attempted_Transfer__c;
                netMeteringCredits = Util.roundValue(netMeteringCredits, 2, creditsRoundMethod);
            }
            when 'kWh' {
                netMeteringCredits = (
                    (transfer.Default_Credit_Value__c - 0.02) * subscriptionProduction).setScale(2, DEFAULT_ROUND)
                    + ((0.02) * subscriptionProduction).setScale(2, DEFAULT_ROUND);
            }
        }
        return netMeteringCredits;
    }

    private Decimal getNMCDiscount() {
        if (nmcDiscountOverride != null) {
            return nmcDiscountOverride;
        }
        return szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c;
    }

    private Decimal getSolarElectricityRate() {
        if (solarElectricityRateOverride != null) {
            return solarElectricityRateOverride;
        }
        return szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c;
    }

    private void setEscalatorOverrides(Map<Id,List<Product_Escalator__c>> productEscalatorMap) {
        Product_Escalator__c productEscalator = getProductEscalator(productEscalatorMap);
        if (productEscalator != null) {
            nmcDiscountOverride = productEscalator.New_NMC_Discount__c;
            solarElectricityRateOverride = productEscalator.New_Solar_Electricity_Rate__c;
        }
    }

    private Product_Escalator__c getProductEscalator(Map<Id,List<Product_Escalator__c>> productEscalatorMap) {
        Product_Escalator__c escalatorForThisTransfer;
        String mapKeyScheduleId = szs.Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c;
        if (mapKeyScheduleId != null) {
            Integer productionCount =
                (Integer) szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Number_of_Billed_Production_Periods__c;
            escalatorForThisTransfer = getActiveEscalator(
                productEscalatorMap, productionCount + 1, mapKeyScheduleId);
        }
        return escalatorForThisTransfer;
    }

    @TestVisible
    private Product_Escalator__c getActiveEscalator(
        Map<Id,List<Product_Escalator__c>> escalatorMap, Integer productionCount, String mapKeyScheduleId)
    {
        Product_Escalator__c activeEscalator = null;
        List<Product_Escalator__c> escalators = escalatorMap.get(mapKeyScheduleId);
        if (escalators == null) {
            return null;
        }
        for (Product_Escalator__c escalator : escalators) {
            if (escalator.Starting_Credit_Transfer__c <= productionCount) {
                activeEscalator = escalator;
                break;
            }
        }
        return activeEscalator;
    }

    // Calculate % Share of Production (kWh)
    private Decimal getSubscriptionProduction() {
        Decimal production = ((szs.Percent_Share__c / 100) * transfer.Attempted_kWh_Transfer__c)
            .setScale(productionDecimalRounding, DEFAULT_ROUND);
        return production;
    }
}