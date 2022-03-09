/**
 * @description : Responsible for qualifying Leads, and handling actions when they are not qualified
 * Tested By: SharedSolarSystemsTest, CSQualificationTestclass, LeadServiceTestclass
 */
public without sharing class SharedSolarSystemQualifier {

    @TestVisible private static final Boolean LOG_FINE_RESULTS = Logger.shouldLog(Logger.FINE);
    private static final String QUALIFIED = 'Qualified';
    private static final String UNQUALIFIED = 'Unqualified';
    private static final String SALES_QUALIFIED = 'Sales Qualified';
    private static final List<String> ORDERED_MOODY_RISK_SCORES = new List<String>{
        'Aaa', 'Aa1', 'Aa2', 'Aa3', 'A1', 'A2', 'A3',
        'Baa1', 'Baa2', 'Baa3', 'Ba1', 'Ba2', 'Ba3', 'B1', 'B2', 'B3',
        'Caa1', 'Caa2', 'Ca', 'C'
    };
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private static Boolean capacityCheckInstance = false;
    private static Boolean ignoreLoadZones = false;

    /**
     * @description Instructs this class to run qualification logic based on if this is for a new or existing lead
     * @param capacityCheck Sets whether the incoming qualification check comes from a capacity check, not a real lead check
     */
    public static void setCapacityCheck(Boolean capacityCheck) {
        capacityCheckInstance = capacityCheck;
    }

    /**
     * @description Ignores Load Zone comparisons when assessing qualified systems. Was implemented in W-023648 to prevent
     *      split load-zone scenarios from automatically unqualifying leads at the completion of the application
     */
    public static void ignoreLoadZones() {
        ignoreLoadZones = true;
    }

    /**
     * @description Gets the lead's qualification based on Utility, Service Territory, Partner, Product, and Credit Score.
     * If the lead does not meet any of the project's credit requirement, the lead is "Unqualified"
     * @param lead The lead to check
     * @param creditScore The lead's credit score
     * @param records Shared Solar Systems
     * @return Qualified or Unqualified
     */
    public String checkCSQualification(Lead lead, String creditScore, List<Shared_Solar_System__c> records) {
        for (Shared_Solar_System__c sss : records) {
            if (qualifiedForSystem(lead, sss, creditScore)) {
                return QUALIFIED;
            }
        }

        // If the lead qualifies for any system, ignoring FICO, then they must have been unqualified due to FICO or
        // have a NO MATCH PCR. If no systems qualify ignoring FICO, the Lead must be unqualified for a different reason
        Boolean creditScoreOnFile = lead.LASER_Credit_Score__c != null;
        for (Shared_Solar_System__c sss : records) {
            Boolean isFicoSystem = sss.Available_SMB_Underwriting_Method_FICO__c;
            Boolean isQualifiedWithoutFICO = qualifiedForSystemIgnoringFICO(lead, sss, creditScore);
            if (isFicoSystem && isQualifiedWithoutFICO && creditScoreOnFile) {
                CSQualificationService.handleLeadUnqualifiedDueToFICO(lead);
                return UNQUALIFIED;
            } else if (isFicoSystem && isQualifiedWithoutFICO && !creditScoreOnFile) {
                // Indicates likely there is a NO MATCH credit report on file, do not send adverse credit notice and
                // do not qualify or unqualify the Lead. Keep in 'Sales Qualified' pending further action by Sales Ops.
                return SALES_QUALIFIED;
            }
        }

        // We only want to send the unqualified email if we haven't already sent it, which we would have done if the
        // lead.Status is already Unqualified.
        if (lead.Status != UNQUALIFIED) {
            CSQualificationService.sendGenericUnqualifiedNotice(lead);
        }
        return UNQUALIFIED;
    }

    /**
     * @description Gets the qualified systems for this lead, sorted by the lead's System Assignment setting
     * @param lead Lead being qualified
     * @param records Shared Solar Systems
     * @return List of systems that qualify
     */
    public List<Shared_Solar_System__c> getQualifiedForLead(Lead lead, List<Shared_Solar_System__c> records) {
        List<SortedSystem> sortedSystems = new List<SortedSystem>();
        List<Shared_Solar_System__c> sortedSharedSolarSystems = new List<Shared_Solar_System__c>();

        if (lead.Selected_SSS_For_Conversion__c != null) {
            records = sssSelector.selectAll(CollectionUtil.toIds(lead.Selected_SSS_For_Conversion__c.split('/')));
        }
        for (Shared_Solar_System__c sss : records) {
            if (qualifiedForSystem(lead, sss, lead.LASER_Credit_Score__c)) {
                sortedSystems.add(new SortedSystem(sss, lead.System_Assignment__c));
            }
        }
        sortedSystems.sort();
        for (Integer wrapperIndex = 0; wrapperIndex < sortedSystems.size(); wrapperIndex++) {
            sortedSharedSolarSystems.add(sortedSystems[wrapperIndex].sss);
        }

        Logger.flushLogs();
        return sortedSharedSolarSystems;
    }

    @TestVisible
    private Boolean qualifiedForSystem(Lead lead, Shared_Solar_System__c sss, String creditScore) {
        return qualifiedForSystem(lead, sss, creditScore, false);
    }

    private Boolean qualifiedForSystemIgnoringFICO(Lead lead, Shared_Solar_System__c sss, String creditScore) {
        return qualifiedForSystem(lead, sss, creditScore, true);
    }

    private Boolean qualifiedForSystem(Lead lead, Shared_Solar_System__c sss, String creditScore, Boolean skipFICOCheck) {
        Boolean utilityMatch = sss.Utility__c == lead.Utility_relationship__c;
        Boolean lzInServiceTerritory = loadZoneInServiceTerritory(lead.LoadZone__c, sss);
        Boolean isPartnerEligible = isPartnerEligible(lead.Partner_Lookup__c, sss);
        Boolean productMatch = matchesProduct(lead, sss);
        Boolean meetsUnderwritingCriteria;
        if (skipFICOCheck && lead.Underwriting_Criteria__c == 'FICO') {
            meetsUnderwritingCriteria = true;
        } else {
            meetsUnderwritingCriteria = meetsUnderwritingCriteria(lead, sss, creditScore);
        }
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
            Logger.logLater('SharedSolarSystems', 'qualifiedForSystem', logMessage, 'FINE');
        }
        return isQualified;
    }

    private static Boolean matchesProduct(Lead lead, Shared_Solar_System__c sss) {
        Boolean productMatch = sss.Product__c == lead.Product__c;
        Boolean parentProductMatch = sss.Product__r.Parent_Product__c != null &&
            sss.Product__r.Parent_Product__c == lead.Product__c;
        return capacityCheckInstance || productMatch || parentProductMatch;
    }

    public static Boolean meetsPaymentCriteria(Lead lead, Shared_Solar_System__c sss) {
        Boolean paymentMatch = lead.No_Payment__c == sss.Do_Not_Ask_for_Payment_Method__c;
        return capacityCheckInstance || paymentMatch;
    }

    @TestVisible
    private Boolean meetsUnderwritingCriteria(Lead lead, Shared_Solar_System__c sss, String creditScore) {
        Boolean meetsCriteria = true;
        Boolean sssDoesNotUnderwrite = sss.Do_Not_Underwrite__c;

        switch on (lead.Underwriting_Criteria__c) {
            when 'FICO' {
                meetsCriteria = meetsFICOUnderwriting(sss, creditScore);
            } when 'Financial Review' {
                meetsCriteria = meetsFinancialReviewUnderwriting(lead, sss);
            }
        }

        // Last: check if SSS does not require underwriting. Overwrite previously-generated value if so.
        return sssDoesNotUnderwrite != null && sssDoesNotUnderwrite ? true : meetsCriteria;
    }

    private Boolean meetsFICOUnderwriting(Shared_Solar_System__c sss, String creditScore) {
        if (!sss.Available_SMB_Underwriting_Method_FICO__c) {
            return false;
        }
        if (capacityCheckInstance) {
            return true;
        }
        Decimal creditScoreValue = Decimal.valueOf(Util.nullToZero(creditScore));
        return creditScoreValue >= sss.Credit_Score_Requirement__c;
    }

    private Boolean meetsFinancialReviewUnderwriting(Lead lead, Shared_Solar_System__c sss) {
        if (capacityCheckInstance) {
            // Default "virtual lead" for capacity checks to have lowest possible Moody's risk score
            lead.Moody_s_Risk_Calc__c = 'Aaa';
        }
        if (!sss.Available_SMB_Underwriting_Method_Docs__c || lead.Moody_s_Risk_Calc__c == null ||
            sss.RiskCalc_Minimum__c == null) {
            return false;
        }
        Integer leadRiskScore = ORDERED_MOODY_RISK_SCORES.indexOf(lead.Moody_s_Risk_Calc__c);
        Integer sssRiskScore = ORDERED_MOODY_RISK_SCORES.indexOf(sss.RiskCalc_Minimum__c);
        return leadRiskScore != -1 && leadRiskScore <= sssRiskScore;
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
            if (partnerOrAccountId == partnerEligibility.Account__c ||
                partnerOrAccountId == partnerEligibility.Account__r.Partner__c) {
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
        if (ignoreLoadZones || sss.Product__r.Ignore_Load_Zones_When_Qualifying__c || capacityCheckInstance) {
            return true;
        }
        return sss.Service_Territories__c != null && sss.Service_Territories__c.contains(loadZone);
    }

    /**
     * @description Used to sort systems based on either COD and Project Capacity, or Assignment Order
     */
    @TestVisible
    private class SortedSystem implements Comparable {
        public Shared_Solar_System__c sss;
        public String systemAssignment;

        public SortedSystem(Shared_Solar_System__c sss, String systemAssignment) {
            this.sss = sss;
            this.systemAssignment = systemAssignment;
        }

        public Integer compareTo(Object compareTo) {
            SortedSystem compareToSSS = (SortedSystem) compareTo;
            Integer returnValue = 0;
            if (systemAssignment == 'Automatic - COD Date/Available Capacity' || systemAssignment == null) {
                return compareByCOD(compareToSSS);
            } else if (systemAssignment == 'Automatic - Assignment Order') {
                return compareByAssignmentOrder(compareToSSS);
            }
            return returnValue;
        }

        private Integer compareByAssignmentOrder(SortedSystem compareToSSS) {
            if (sss.Assignment_Order__c > compareToSSS.sss.Assignment_Order__c) {
                return 1;
            } else if (sss.Assignment_Order__c < compareToSSS.sss.Assignment_Order__c) {
                return -1;
            }
            return 0;
        }

        private Integer compareByCOD(SortedSystem compareToSSS) {
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