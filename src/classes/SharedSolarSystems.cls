/**
 * Created by SarahRenfro on 7/6/2020.
 * Description: Domain class for SSS
 * Test: CSUtilityAccountSubscriptionFactoryTest, SharedSolarSystemsTest, LeadServiceTestclass
 */

public inherited sharing class SharedSolarSystems {

    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ProductSelector productSelector = new ProductSelector();
    @TestVisible private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private static final Boolean LOG_FINE_RESULTS = Logger.shouldLog(Logger.FINE);
    @TestVisible private static Boolean capacityCheckInstance = false;
    private static final List<String> ORDERED_MOODY_RISK_SCORES = new List<String>{
        'Aaa', 'Aa1', 'Aa2', 'Aa3', 'A1', 'A2', 'A3',
        'Baa1', 'Baa2', 'Baa3', 'Ba1', 'Ba2', 'Ba3', 'B1', 'B2', 'B3',
        'Caa1', 'Caa2', 'Ca', 'C'};
    private List<Shared_Solar_System__c> records;
    private Lead virtualLead;
    private Boolean unqualifiedFICO = true;

    /**
     * @description Default constructor used in most cases
     * @param records List of SSS to be used throughout this class
     */
    public SharedSolarSystems(List<Shared_Solar_System__c> records) {
        this.records = records;
    }

    /**
     * @description Constructor for running Capacity Checks through qualification logic in CapacityService{} to return
     *      rank-ordered SSS for a given ZIP code by Assignment Order.
     * <p></p>
     *     Creates a (virtual) lead to be used throughout this class instance to avoid necessity of method overloading
     * @param sharedSolarSystems List of Shared_Solar_System__c
     * @param utilityId Utility ID of Applicant
     * @param partnerId Partner lookup ID used for capacity check
     */
    public SharedSolarSystems(List<Shared_Solar_System__c> sharedSolarSystems, Id utilityId, String partnerId) {
        this.records = sharedSolarSystems;
        this.virtualLead = new Lead(
            Partner_Lookup__c = partnerId,
            System_Assignment__c = 'Automatic - Assignment Order',
            Utility_relationship__c = utilityId
        );
        capacityCheckInstance = true;
    }

    /**
     * @description Rank-orders SSSs found in Capacity Check by Assignment Order for use with
     *      CapacityService.setProductsAndSharedSolarSystems()
     * @return Rank-ordered SSS list by Automatic Assignment Order
     */
    public List<Shared_Solar_System__c> orderedSssForCapacityCheck() {
        return getQualifiedForLead(virtualLead);
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss){
        Decimal sssRemainingSubscriptionCapacity = sss.Maximum_Subscription_Capacity_kWDC__c * sss.Expected_Yield_kWh_kW__c;
        if (featureService.isEnabled('Sizing_Method') && sss.Product__r.Customer_Subscription_Type__c == 'kWh'
            && sss.Product__r.Sizing_Method__c == 'Project Ratio') {
            sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/sss.Utility_NMC_Tariff__r.Size_Ratio__c;
        }
        return sssRemainingSubscriptionCapacity.setScale(2, RoundingMode.HALF_DOWN);
    }

    public void calculateMaximumSubscriptionCapacityForSMART() {
        Set<Id> productIds = new Set<Id>();
        for (Shared_Solar_System__c sss : records) {
            productIds.add(sss.Product__c);
        }
        Map<Id, Product2> productsForConversionMap =
            new Map<Id, Product2>(productSelector.selectForACToDCConversion(productIds));
        if (productsForConversionMap.isEmpty()) {
            return;
        }
        for (Shared_Solar_System__c sss : records) {
            Product2 productForConversion = productsForConversionMap.get(sss.Product__c);
            if (productForConversion == null || sss.Total_System_Size_kWh_DC__c == null || sss.Total_System_Size_kW_AC__c == null) {
                continue;
            } else {
                sss.Maximum_Subscription_Capacity_kWDC__c =
                    productForConversion.Max_Subscription_kW_AC_for_DC_calc__c *
                        (sss.Total_System_Size_kWh_DC__c/sss.Total_System_Size_kW_AC__c);
            }
        }
    }

    public void updateManagementRevenueStartDateBeforeTrigger() {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Shared_Solar_System__c.SObjectType});
        updateManagementRevenueStartDate(uow);
    }

    public void updateManagementRevenueStartDate(fflib_SObjectUnitOfWork uow) {
        MultiMap contractsToCFDs = getContractsToCFDs();
        for (Shared_Solar_System__c sss : records) {
            List<Object> untypedCFDs = contractsToCFDs.getValues(sss.Client_Management_Contract__c);
            List<Contract_Fee_Detail__c> contractFeeDetails =
                (List<Contract_Fee_Detail__c>) CollectionUtil.toTypedList(untypedCFDs, new List<Contract_Fee_Detail__c>());
            Date managementRevenueStartDate = getRevenueStartDate(sss, contractFeeDetails);
            if (sss.Management_Revenue_Start_Date__c == null && managementRevenueStartDate != null) {
                sss.Management_Revenue_Start_Date__c = managementRevenueStartDate;
                uow.registerDirty(sss, new List<SObjectField>{Shared_Solar_System__c.Management_Revenue_Start_Date__c});
            }
        }
    }

    private Date getRevenueStartDate(Shared_Solar_System__c sss, List<Contract_Fee_Detail__c> contractFeeDetails) {
        if (contractFeeDetails == null || contractFeeDetails.size() == 0) {
            return null;
        }
        Date startDate;
        for (Contract_Fee_Detail__c cfd : contractFeeDetails) {
            if (cfd.Shared_Solar_System__c == null) {
                startDate = getStartDateForCFD(cfd, startDate, sss);
            } else if (cfd.Shared_Solar_System__c == sss.Id) {
                return getStartDateForCFD(cfd, null, sss);
            }
            // else: must be cfd.SSS != sss.Id, so we can skip it
        }
        return startDate;
    }

    private Date getStartDateForCFD(Contract_Fee_Detail__c cfd, Date startDate, Shared_Solar_System__c sss) {
        switch on cfd.Management_Fee_Trigger__c {
            when 'Project: PTO' {
                startDate = DateUtil.min(startDate, sss.Actual_PTO_Date_MANUAL__c);
            } when 'Project: COD' {
                startDate = DateUtil.min(startDate, sss.Actual_COD_Date__c);
            } when 'Project: First Customer Assignment Date' {
                startDate = DateUtil.min(startDate, sss.Customer_Assignment_Date__c);
            } when 'Project: First Customer Bill Date' {
                startDate = DateUtil.min(startDate, sss.First_Bill_Date__c);
            } when 'Contract: Effective Date' {
                startDate = DateUtil.min(startDate, cfd.Contract__r.StartDate);
            } when else {
                Logger.logLater(
                    'SharedSolarSystems',
                    'getRevenueStartDate',
                    'Management Fee Trigger for system ' + sss.Id + ' not handled: ' + cfd,
                    Logger.ERROR
                );
            }
        }
        return startDate;
    }

    private MultiMap getContractsToCFDs() {
        MultiMap contractsToCFDs = MultiMap.newSetInstance();
        Set<Id> contractIds = new Set<Id>();
        for (Shared_Solar_System__c sss : records) {
            contractIds.add(sss.Client_Management_Contract__c);
        }
        List<Contract_Fee_Detail__c> contractFeeDetails = contractFeeDetailSelector.getContractDetailFromContract(contractIds);
        for (Contract_Fee_Detail__c cfd : contractFeeDetails) {
            if (cfd.Management_Fee__c && cfd.Management_Fee_Type__c == 'Recurring') {
                contractsToCFDs.putValue(cfd.Contract__c, cfd);
            }
        }
        return contractsToCFDs;
    }



    /**
     * @description Gets the qualified systems for this lead, sorted by the lead's System Assignment setting
     * @param lead Lead being qualified
     * @return List of systems that qualify
     */
    public List<Shared_Solar_System__c> getQualifiedForLead(Lead lead) {
        List<SSSWrapper> sssWrappers = new List<SSSWrapper>();
        List<Shared_Solar_System__c> sortedSharedSolarSystems = new List<Shared_Solar_System__c>();

        if (lead.Selected_SSS_For_Conversion__c != null) {
            getPreSelectedSharedSolarSystems(lead);
        }

        for (Shared_Solar_System__c sss : records) {
            if (qualifiedForSystem(lead, sss, null)) {
                sssWrappers.add(new SSSWrapper(sss, lead.System_Assignment__c));
            }
        }
        sssWrappers.sort();
        for (Integer wrapperIndex = 0; wrapperIndex < sssWrappers.size(); wrapperIndex++) {
            sortedSharedSolarSystems.add(sssWrappers[wrapperIndex].sss);
        }
        Logger.flushLogs();
        return sortedSharedSolarSystems;
    }

    /**
     * @description Gets the lead's qualification based on Utility, Service Territory, Partner, Product, and Credit Score
     * @param lead The lead to check
     * @param creditScore The lead's credit score
     * @return Qualified or Unqualified
     */
    public String checkCSQualification(Lead lead, Decimal creditScore) {
        for (Shared_Solar_System__c sss : records) {
            if (qualifiedForSystem(lead, sss, creditScore)) {
                return 'Qualified';
            }
        }
        if (unqualifiedFICO) {
           CSQualificationService.handleLeadUnqualifiedDueToFICO(lead.Id);
        }
        return 'Unqualified';
    }

    /**
     * @description If the lead has had SSSes pre-selected for conversion, we need to query for just those projects
     * rather than all projects for qualification
     * @param lead Lead that is being considered for qualification or conversion
     */
    private void getPreSelectedSharedSolarSystems(Lead lead) {
        List<String> selectedSSSIds = lead.Selected_SSS_For_Conversion__c.split('/');
        this.records = sssSelector.selectAll(new Set<Id>((List<Id>) selectedSSSIds));
    }

    @TestVisible
    private Boolean qualifiedForSystem(Lead lead, Shared_Solar_System__c sss, Decimal creditScore) {
        Boolean utilityMatch = sss.Utility__c == lead.Utility_relationship__c;
        Boolean lzInServiceTerritory = SharedSolarSystems.loadZoneInServiceTerritory(lead.LoadZone__c, sss);
        Boolean isPartnerEligible = SharedSolarSystems.isPartnerEligible(lead.Partner_Lookup__c, sss);
        Boolean productMatch = matchesProduct(lead, sss);
        Boolean meetsUnderwritingCriteria = meetsUnderwritingCriteria(lead, sss, creditScore);
        Boolean paymentMatch = meetsPaymentCriteria(lead, sss);

        Boolean isQualified = utilityMatch
            && lzInServiceTerritory
            && isPartnerEligible
            && productMatch
            && meetsUnderwritingCriteria
            && paymentMatch;

        if (LOG_FINE_RESULTS) {
            String logMessage = '------\n' + 'Lead: ' + JSON.serialize(lead)
                + '\nShared Solar System: ' + JSON.serialize(sss)
                + '\nCredit Score: ' + creditScore
                + '\nutilityMatch: ' + String.valueOf(utilityMatch)
                + '\nlzInServiceTerritory: ' + String.valueOf(lzInServiceTerritory)
                + '\nisPartnerEligible: ' + String.valueOf(isPartnerEligible)
                + '\nproductMatch: ' + String.valueOf(productMatch)
                + '\nmeetsUnderwritingCriteria: ' + String.valueOf(meetsUnderwritingCriteria)
                + '\nmeetsPaymentCriteria: ' + String.valueOf(paymentMatch)
                + '\nLEAD QUALIFIED FOR SYSTEM?: ' + String.valueOf(isQualified);
            Logger.logLater('SharedSolarSystems','qualifiedForSystem',logMessage, 'FINE');
        }
        return isQualified;
    }

    private static Boolean matchesProduct(Lead lead, Shared_Solar_System__c sss) {
        Boolean matchesProduct = false;
        if (capacityCheckInstance) {
            matchesProduct = true;
        } else if (sss.Product__r.Parent_Product__c != null && sss.Product__r.Parent_Product__c == lead.Product__c){
            matchesProduct = true;
        } else if (sss.Product__c == lead.Product__c) {
            matchesProduct = true;
        }
        return matchesProduct;
    }

    public static Boolean meetsPaymentCriteria(Lead lead, Shared_Solar_System__c sss) {
        Boolean meetsCriteria = false;
        if (capacityCheckInstance) {
            meetsCriteria = true;
        } else if (lead.No_Payment__c == sss.Do_Not_Ask_for_Payment_Method__c) {
            meetsCriteria = true;
        }
        return meetsCriteria;
    }

    @TestVisible
    private Boolean meetsUnderwritingCriteria(Lead lead, Shared_Solar_System__c sss, Decimal creditScore) {
        Boolean meetsCriteria = false;
        Boolean sssDoesNotUnderwrite = sss.Do_Not_Underwrite__c;

        switch on (lead.Underwriting_Criteria__c) {
            when 'FICO' {
                meetsCriteria = meetsFICOUnderwriting(lead, sss, creditScore);
            } when 'Financial Review' {
                unqualifiedFICO = false;
                meetsCriteria = meetsFinancialReviewUnderwriting(lead, sss);
            } when else {
                unqualifiedFICO = false;
                meetsCriteria = true;
            }
        }

        // Last: check if SSS does not require underwriting. Overwrite previously-generated value if so.
        return sssDoesNotUnderwrite != null && sssDoesNotUnderwrite ? true : meetsCriteria;
    }

    private Boolean meetsFICOUnderwriting(Lead lead, Shared_Solar_System__c sss, Decimal creditScore) {
        if (!sss.Available_SMB_Underwriting_Method_FICO__c) {
            return false;
        }

        if (capacityCheckInstance) {
            creditScore = 999;
        } else if (creditScore == null && lead.Underwriting_Criteria__c == 'FICO') {
            creditScore = Decimal.valueOf(Util.nullToZero(lead.LASER_Credit_Score__c));
        }
        if (unqualifiedFICO) {
            unqualifiedFICO = creditScore < sss.Credit_Score_Requirement__c;
        }
        return creditScore >= sss.Credit_Score_Requirement__c;
    }

    private Boolean meetsFinancialReviewUnderwriting(Lead lead, Shared_Solar_System__c sss) {
        if (capacityCheckInstance) {
            // Default "virtual lead" for capacity checks to have lowest possible Moody's risk score
            lead.Moody_s_Risk_Calc__c = 'Aaa';
        }
        if (!sss.Available_SMB_Underwriting_Method_Docs__c || lead.Moody_s_Risk_Calc__c == null || sss.RiskCalc_Minimum__c == null) {
            return false;
        }

        Integer leadRiskScore = ORDERED_MOODY_RISK_SCORES.indexOf(lead.Moody_s_Risk_Calc__c);
        Integer sssRiskScore = ORDERED_MOODY_RISK_SCORES.indexOf(sss.RiskCalc_Minimum__c);
        return leadRiskScore != -1 && leadRiskScore <= sssRiskScore;
    }

    /**
     * @description Removes systems from the sssList that don't have a Partner_SSS_Eligibility__c for the given partner id
     * @param partnerId Partner with which to check eligibility
     * @param sssList List of Shared Solar Systems to be pruned
     */
    public static void pruneIneligiblePartners(Id partnerId, List<Shared_Solar_System__c> sssList) {
        for (Integer i = sssList.size()-1; i >= 0; i--) {
            if (!isPartnerEligible(partnerId, sssList[i])) {
                sssList.remove(i);
            }
        }
    }

    /**
     * @description True if the Partner has a corresponding Partner_Shared_Solar_System_Eligibility__c
     * @param partnerOrAccountId Partner Id to check
     * @param sss Shared Solar System with list of Partner_Shared_Solar_System_Accesses__r and Public
     * @return True if found
     */
    public static Boolean isPartnerEligible(Id partnerOrAccountId, Shared_Solar_System__c sss) {
        if (sss.Public__c) {
            return true;
        }
        for (Partner_Shared_Solar_System_Eligibility__c partnerEligibility : sss.Partner_Shared_Solar_System_Accesses__r) {
            if (partnerOrAccountId == partnerEligibility.Account__c || partnerOrAccountId == partnerEligibility.Account__r.Partner__c) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description True if the load zone is served by the shared solar system, or if the SSS ignores load zones for
     * qualification purposes (as specified by the the related Product)
     * @param loadZone The load zone (e.g. SEMA)
     * @param sss The Shared_Solar_System__c, selected with Product__r.Ignore_Load_Zones_When_Qualifying__c and Service_Territories
     * @return Boolean
     */
    public static Boolean loadZoneInServiceTerritory(String loadZone, Shared_Solar_System__c sss) {
        if (sss.Product__r.Ignore_Load_Zones_When_Qualifying__c || capacityCheckInstance) {
            return true;
        }
        return sss.Service_Territories__c != null && sss.Service_Territories__c.contains(loadZone);
    }

    /**
     * @description Used to sort systems based on either COD and Project Capacity, or Assignment Order
     */
    private class SSSWrapper implements Comparable {
        public Shared_Solar_System__c sss;
        public String systemAssignment;
        public SSSWrapper(Shared_Solar_System__c sss, String systemAssignment) {
            this.sss = sss;
            this.systemAssignment = systemAssignment;
        }
        public Integer compareTo(Object compareTo) {
            SSSWrapper compareToSSS = (SSSWrapper) compareTo;
            Integer returnValue = 0;
            if (systemAssignment == 'Automatic - COD Date/Available Capacity' || systemAssignment == null) {
                return compareByCOD(compareToSSS);
            } else if (systemAssignment == 'Automatic - Assignment Order') {
                return compareByAssignmentOrder(compareToSSS);
            }
            return returnValue;
        }

        private Integer compareByAssignmentOrder(SSSWrapper compareToSSS) {
            if (sss.Assignment_Order__c > compareToSSS.sss.Assignment_Order__c) {
                return 1;
            } else if (sss.Assignment_Order__c < compareToSSS.sss.Assignment_Order__c) {
                return -1;
            }
            return 0;
        }

        private Integer compareByCOD(SSSWrapper compareToSSS) {
            if (sss.Estimated_COD_Date_Manual__c > compareToSSS.sss.Estimated_COD_Date_Manual__c) {
                return 1;
            } else if (sss.Estimated_COD_Date_Manual__c < compareToSSS.sss.Estimated_COD_Date_Manual__c) {
                return -1;
            }
            if (sss.Project_Capacity_Available_kW_DC__c > compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                return 1;
            } else if (sss.Project_Capacity_Available_kW_DC__c < compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                return -1;
            }
            return 0;
        }
    }
}