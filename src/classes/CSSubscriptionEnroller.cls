/**
 * Created by mstackhouse on 12/12/2018.
 * Description: Moving Logic for CS Subscriptions out of LeadTriggerHandler.
 * Dependencies: Leads, SharedSolarSystems, ChargentOrders (on leads)
 *
 * Outputs: Opportunities for leads, Utility Account Subscriptions for leads
 * Test: LeadTriggerHandlerTest
 */


public without sharing class CSSubscriptionEnroller {
    private List<Utility_Account_Log__c> ualList;
    private Map<Id, List<Utility_Account_Log__c>> ualsByLeadId;
    private Map<Id, Utility_Account_Log__c> ualsToUpdateMap;
    private Map<Id, Product2> productsMap;
    private List<Shared_Solar_System__c> sssList;
    private Map<Id, Shared_Solar_System__c> sssByIds;
    private Map<Id, List<Opportunity>> leadOppsMap;
    private List<Utility_Account_Subscription__c> uasList;
    private List<ChargentOrders__ChargentOrder__c> chargentOrdersToUpdate;
    private Map<Id, ChargentOrders__ChargentOrder__c> chOrdersByLeadId;
    private List<Id> oppIdList;
    private List<Lead> leads;
    private Boolean skipContractSend = false;
    private Map<Id, Map<String, Utility_NMC_Tariff__c>> tariffsByProductIdAndTariffName;


    public CSSubscriptionEnroller(List<Lead> leads, Boolean skipContractSend) {
        this.skipContractSend = skipContractSend;
        this.leads = leads;

        List<Id> leadIds = new List<Id>();
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
        }
        ualList = [
            SELECT Id, Name, Annual_Cost_of_Electricity__c, Name_on_Account__c, Lead__c, Utility__c,
                Annual_kWh__c, Proposed_kWh__c, Lead__r.Product__r.Customer_Subscription_Type__c
            FROM Utility_Account_Log__c
            WHERE Lead__c IN :leadIds
            ORDER BY Annual_Cost_of_Electricity__c DESC
        ];

        sssList = [
            SELECT Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Maximum_Subscription_Capacity_kW_DC__c,
                Product__c, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, Service_Territories__c,
                Reserved_Capacity_kW_DC__c, Service_Territory__c, System_Utility__c, Expected_Yield_kWh_kW__c,
                Utility_NMC_Tariff__c, Credit_Score_Requirement__c, Assignment_Order__c, Estimated_COD_Date_QC__c,
                BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c
            FROM Shared_Solar_System__c
            WHERE Open__c = TRUE
            AND Capacity_Available_to_be_Reserved__c > 0
        ];
        sssByIds = new Map<Id, Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : sssList) {
            sssByIds.put(sss.Id, sss);
        }
        // Catching here to allow legacy leads & tests to work
        List<ChargentOrders__ChargentOrder__c> chOrders = new List<ChargentOrders__ChargentOrder__c>();
        chOrders = [
            SELECT Id, Lead__c, ChargentOrders__Payment_Method__c, ChargentOrders__Bank_Name__c,
                ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Account_Type__c,
                ChargentOrders__Bank_Account_Number__c, ChargentOrders__Bank_Account_Name__c,
                ChargentOrders__Billing_Email__c, ChargentOrders__Card_Type__c,
                ChargentOrders__Card_Number__c, ChargentOrders__Card_Expiration_Month__c,
                ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Billing_Address__c,
                ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c,
                ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Billing_First_Name__c,
                ChargentOrders__Billing_Last_Name__c, Autopay_Only__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Lead__c IN : leadIds
        ];

        chOrdersByLeadId = new Map<Id, ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c chOrder : chOrders) {
            chOrdersByLeadId.put(chOrder.Lead__c, chOrder);
        }

        List<Product2> products = [
            SELECT Id, Program__c,
            (SELECT Id, Name, Size_Ratio__c FROM Utility_NMC_Tariffs__r)
            FROM Product2
            WHERE Product_Type__c = 'Community Solar'
        ];

        productsMap = new Map<Id, Product2>();
        tariffsByProductIdAndTariffName = new Map<Id, Map<String, Utility_NMC_Tariff__c>>();
        for (Product2 product : products) {
            productsMap.put(product.Id, product);
            Map<String, Utility_NMC_Tariff__c> productTariffsByName = new Map<String, Utility_NMC_Tariff__c>();
            if (product.Utility_NMC_Tariffs__r.size() > 0) {
                for (Utility_NMC_Tariff__c tariff : product.Utility_NMC_Tariffs__r) {
                    productTariffsByName.put(tariff.Name, tariff);
                }
            }
            tariffsByProductIdAndTariffName.put(product.Id, productTariffsByName);
        }

        leadOppsMap = new Map<Id, List<Opportunity>>();
        uasList = new List<Utility_Account_Subscription__c>();
        oppIdList = new List<Id>();
        chargentOrdersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
        ualsToUpdateMap = new Map<Id, Utility_Account_Log__c>();
        ualsByLeadId = new Map<Id, List<Utility_Account_Log__c>>();
    }

    public void enroll() {
        for (Lead lead : leads) {
            assignApplicableRateClass(lead);
        }
        updateUALs();
        for (Integer leadIndex = 0; leadIndex < leads.size(); leadIndex++) {
            AnnualEnergyTotal annualTotals = getAnnualTotals(leads[leadIndex]);
            if (annualTotals.cost == 0 && annualTotals.kWh == 0) {
                leads.remove(leadIndex);
            }
        }
        for (Lead lead : leads) {
            createOpportunity(lead);
        }
        insertOpps();
        for (Lead lead : leads) {
            createUAS(lead);
            moveChOrderToAccount(lead);
        }
        insertUASes();
        updateChargentOrders();
        if (!skipContractSend) {
            sendContracts();
        }
    }

    public List<Utility_Account_Log__c> getUALList(Lead lead) {
        List<Utility_Account_Log__c> ualListForLead = ualsByLeadId.get(lead.Id);
        if (ualListForLead == null) {
            ualListForLead = new List<Utility_Account_Log__c>();
        } else {
            return ualListForLead;
        }

        for (Utility_Account_Log__c ual : ualList) {
            if (ual.Lead__c == lead.Id) {
                ualListForLead.add(ual);
            }
        }
        ualsByLeadId.put(lead.Id, ualListForLead);
        return ualListForLead;
    }

    public List<Shared_Solar_System__c> getSortedSharedSolarSystems(Lead lead) {
        List<SSSWrapper> sssWrappers = new List<SSSWrapper>();
        List<Shared_Solar_System__c> sortedSharedSolarSystems = new List<Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : sssList) {
            if (sss.System_Utility__c == lead.Utility__c &&
                (sss.Service_Territories__c != null &&
                    sss.Service_Territories__c.contains(lead.Load_Zone__c)) &&
                (sss.Sales_Partners__c != null &&
                    (sss.Sales_Partners__c.contains('All') ||
                        sss.Sales_Partners__c.contains(lead.Partner_Name__c))) &&
                (lead.Product__c == null ||
                    sss.Product__c == lead.Product__c)) {
                sssWrappers.add(new SSSWrapper(sss, lead.System_Assignment__c));
            }
        }
        sssWrappers.sort();
        for (Integer wrapperIndex = 0; wrapperIndex < sssWrappers.size(); wrapperIndex++) {
            sortedSharedSolarSystems.add(sssWrappers[wrapperIndex].sss);
        }
        return sortedSharedSolarSystems;
    }

    public AnnualEnergyTotal getAnnualTotals(Lead lead) {
        Decimal totalAnnualCostOfElectricity = 0;
        Decimal totalAnnualkWhElectricity = 0;
        for (Utility_Account_Log__c ual : getUALList(lead)) {
            totalAnnualCostOfElectricity += Util.nullToZero(ual.Annual_Cost_of_Electricity__c);
            totalAnnualkWhElectricity += Util.nullToZero(ual.Proposed_kWh__c);
        }
        return new AnnualEnergyTotal(totalAnnualCostOfElectricity, totalAnnualkWhElectricity);
    }

    public void createOpportunity(Lead lead) {
        AnnualEnergyTotal annualTotals = getAnnualTotals(lead);
        Decimal remainingAccountCostToAllocate = annualTotals.cost;
        Decimal remainingAccountkWhToAllocate = annualTotals.kWh;
        List<Opportunity> oppListToCreate = new List<Opportunity>();
        Integer oppCounter = 1;
        for (Shared_Solar_System__c sss : getSortedSharedSolarSystems(lead)) {
            if (Integer.valueOf(lead.LASER_Credit_Score__c) >= sss.Credit_Score_Requirement__c &&
                (remainingAccountCostToAllocate > 0 || remainingAccountkWhToAllocate > 0)) {
                Decimal annualElectricityCostAssigned = Math.min(remainingAccountCostToAllocate, sss.Maximum_Subscription_Cost__c);
                if (remainingAccountCostToAllocate > 0) {
                    remainingAccountCostToAllocate -= annualElectricityCostAssigned;
                }
                Decimal annualElectricitykWhAssigned = Math.min(remainingAccountkWhToAllocate, sss.Maximum_Subscription_Capacity_kW_DC__c * sss.Expected_Yield_kWh_kW__c);
                if (remainingAccountkWhToAllocate > 0) {
                    remainingAccountkWhToAllocate -= annualElectricitykWhAssigned;
                }
                ChargentOrders__ChargentOrder__c baseChargentOrder = chOrdersByLeadId.get(lead.Id);
                Opportunity opp = new Opportunity(
                    AccountId = lead.ConvertedAccountId,
                    Shared_Solar_System__c = sss.Id,
                    Reserved_System_Capacity_kW_DC2__c = sss.Reserved_Capacity_kW_DC__c,
                    Available_System_Capacity_kW_DC__c = sss.Project_Capacity_Available_kW_DC__c,
                    Product__c = sss.Product__c,
                    System_Assigned__c = true,
                    NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
                    Name = lead.FirstName + ' ' + lead.LastName,
                    StageName = 'New',
                    CloseDate = Date.today(),
                    UAS_Created__c = true,
                    Annual_Electricity_Cost__c = annualElectricityCostAssigned,
                    Annual_Electricity_Cost2__c = annualElectricityCostAssigned,
                    Annual_Consumption_kWh__c = annualElectricitykWhAssigned,
                    Opportunity_Order__c = oppCounter,
                    Lead__c = lead.Id
                );
                opp = setDefaultOppFields(lead, opp);
                System.debug('creating ch order');
                System.debug(baseChargentOrder);
                if (baseChargentOrder != null) {
                    opp = addPaymentInfoToOpp(opp, baseChargentOrder);
                }
                oppListToCreate.add(opp);
                oppCounter++;
            }
        }
        leadOppsMap.put(lead.Id, oppListToCreate);
    }

    public void insertOpps() {
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for (List<Opportunity> opps : leadOppsMap.values()) {
            oppsToInsert.addAll(opps);
        }
        insert oppsToInsert;
    }

    public void createUAS(Lead lead) {
        Map<Id, Decimal> sssRemainingSubscriptionCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap = new Map<Id, Decimal>();

        for (Shared_Solar_System__c sss : getSortedSharedSolarSystems(lead)) {
            sssRemainingSubscriptionCostMap.put(sss.Id, sss.Maximum_Subscription_Cost__c);
            Decimal maximumSubscriptionkWh = sss.Maximum_Subscription_Capacity_kW_DC__c * sss.Expected_Yield_kWh_kW__c;
            sssRemainingSubscriptionCapacityMap.put(sss.Id, maximumSubscriptionkWh);
        }

        for (Utility_Account_Log__c ual : getUALList(lead)) {
            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
                createUASbyCapacity(lead, ual, sssRemainingSubscriptionCapacityMap);
            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
                createUASbyCost(lead, ual, sssRemainingSubscriptionCostMap);
            }
        }
    }

    public void createUASbyCapacity(Lead lead, Utility_Account_Log__c ual, Map<Id, Decimal> sssRemainingSubscriptionCapacityMap) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCapacityToAllocate = ual.Proposed_kWh__c;

        for (Opportunity opp : leadOppsMap.get(lead.Id)) {
            if (sssRemainingSubscriptionCapacityMap.containsKey(opp.Shared_Solar_System__c)){
                Decimal sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacityMap.get(opp.Shared_Solar_System__c);
                Decimal annualElectricityCapacityAssigned = Math.min(remainingUALCapacityToAllocate, sssRemainingSubscriptionCapacity);
                if (annualElectricityCapacityAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCapacity -= annualElectricityCapacityAssigned;
                    sssRemainingSubscriptionCapacityMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCapacity);

                    remainingUALCapacityToAllocate -= annualElectricityCapacityAssigned;
                    uasList.add(new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        Annual_kwh_subscription_future__c = annualElectricityCapacityAssigned
                    ));
                    uasNumberCounter++;
                    oppIdList.add(opp.Id);
                }
            }
        }
    }

    public void createUASbyCost(Lead lead, Utility_Account_Log__c ual, Map<Id, Decimal> sssRemainingSubscriptionCostMap) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;

        for (Opportunity opp : leadOppsMap.get(lead.Id)) {
            if (sssRemainingSubscriptionCostMap.containsKey(opp.Shared_Solar_System__c)){
                Decimal sssRemainingSubscriptionCost = sssRemainingSubscriptionCostMap.get(opp.Shared_Solar_System__c);
                Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
                if (annualElectricityCostAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
                    sssRemainingSubscriptionCostMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCost);

                    remainingUALCostToAllocate = remainingUALCostToAllocate - annualElectricityCostAssigned;
                    uasList.add(new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        calculated_annual_cost_of_electricity__c = annualElectricityCostAssigned,
                        Subscribed_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned
                    ));
                    uasNumberCounter++;
                    oppIdList.add(opp.Id);
                }
            }
        }
    }

    public void insertUASes() {
        insert uasList;
    }

    public void moveChOrderToAccount(Lead lead) {
        ChargentOrders__ChargentOrder__c baseChargentOrder = chOrdersByLeadId.get(lead.Id);
        if (baseChargentOrder == null) return;
        baseChargentOrder.ChargentOrders__Account__c = lead.ConvertedAccountId;
        chargentOrdersToUpdate.add(baseChargentOrder);
    }

    public void updateChargentOrders() {
        if (!chargentOrdersToUpdate.isEmpty()) {
            update chargentOrdersToUpdate;
        }
    }

    public void sendContracts() {
        DocuSignHelper.sendCSPackageFuture(oppIdList);
    }

    public Opportunity addPaymentInfoToOpp(Opportunity opp, ChargentOrders__ChargentOrder__c chOrder) {
        if (chOrder.ChargentOrders__Payment_Method__c == 'Check') {
            opp.ACH_Bank_Name__c = chOrder.ChargentOrders__Bank_Name__c;
            opp.ACH_Bank_Routing_Number__c = Util.obscureText(chOrder.ChargentOrders__Bank_Routing_Number__c, 4);
            opp.ACH_Account_Type__c = chOrder.ChargentOrders__Bank_Account_Type__c;
            opp.ACH_Account_Number__c = Util.obscureText(chOrder.ChargentOrders__Bank_Account_Number__c, 4);
            opp.ACH_Name_on_Account__c = chOrder.ChargentOrders__Bank_Account_Name__c;
        } else if (chOrder.ChargentOrders__Payment_Method__c == 'Credit Card') {
            opp.CC_Card_Type__c = chOrder.ChargentOrders__Card_Type__c ;
            opp.CC_Account_Number__c = Util.obscureText(chOrder.ChargentOrders__Card_Number__c, 4);
            opp.CC_CardHolder_Name__c = chOrder.ChargentOrders__Billing_Last_Name__c;
            opp.CC_Expiration_Month__c = chOrder.ChargentOrders__Card_Expiration_Month__c;
            opp.CC_Expiration_Year__c = chOrder.ChargentOrders__Card_Expiration_Year__c;
        }
        return opp;
    }

    public void assignApplicableRateClass(Lead lead) {
        List<Utility_Account_Log__c> uals = getUALList(lead);
        Product2 product = productsMap.get(lead.Product__c);
        for (Utility_Account_Log__c ual : uals) {
            Map<String, Utility_NMC_Tariff__c> possibleTariffsByName = tariffsByProductIdAndTariffName.get(lead.Product__c);
            String tariffName = getUtilityTariffName(ual, lead);
            Utility_NMC_Tariff__c tariff = possibleTariffsByName.get(tariffName);
            System.debug(tariff);
            System.debug(tariffName);
            if (tariff != null && product != null && product.Program__c.contains('SMART')) {
                ual.Utility_NMC_Tariff__c = tariff.Id;
                // Currently, we only need to have a sizing ration for SMART
                ual.Proposed_kWh__c = ual.Annual_kWh__c * tariff.Size_Ratio__c;
            } else {
                ual.Proposed_kWh__c = ual.Annual_kWh__c;
            }
            ualsToUpdateMap.put(ual.Id, ual);
        }
        System.debug(uals);
        ualsByLeadId.put(lead.Id, uals);
    }

    public static String getUtilityTariffName(Utility_Account_Log__c ual, Lead lead) {
        String tariffName = '';
        tariffName += ual.Utility__c;
        if (lead.Customer_type__c == 'Non-Residential' && ual.Annual_kWh__c >= 10000) {
            tariffName += ' G2';
        } else if (lead.Customer_type__c == 'Non-Residential' && ual.Annual_kWh__c < 10000) {
            tariffName += ' G1';
        } else if (lead.Customer_type__c == 'Residential') {
            tariffName += ' R1';
        }
        return tariffName;
    }

    public void updateUALs() {
        update ualsToUpdateMap.values();
    }

    private static Opportunity setDefaultOppFields(Lead lead, Opportunity opp){
        opp.AccountId = lead.convertedAccountId;
        opp.Assessors_Parcel_Number__c = lead.Accessor_s_Parcel_Number__c;
        opp.Annual_Independent_Income__c = lead.Annual_Income_Currency__c;
        opp.Application_Date__c = lead.Application__c;
        opp.Application_Type__c = lead.Application_Type__c;
        opp.Avidia_Checking_Account__c = lead.Avidia_Checking_Account__c;
        opp.Business_Title__c = lead.Business_Title__c;
        opp.Co_Applicant_Date_of_Birth__c = lead.Co_Applicant_Date_of_Birth__c;
        opp.Co_Applicant_Email__c = lead.Co_Applicant_Email__c;
        opp.Co_Applicant_First_Name__c = lead.Co_Applicant_First_Name__c;
        opp.Co_Applicant_Income__c = lead.Co_Applicant_Income__c;
        opp.Co_Applicant_Last_Name__c = lead.Co_Applicant_Last_Name__c;
        opp.Co_Applicant_Phone__c = lead.Co_Applicant_Phone__c;
        opp.Commencement_Date__c = lead.Commencement_Date__c;
        opp.Cumulative_Loan_to_Value__c = lead.Cumulative_Loan_to_Value_if_Applicable__c;
        opp.Customer_Referral__c = lead.Customer_Referral__c;
        opp.Customer_type__c = lead.Customer_type__c;
        opp.Customer_Group__c = lead.Customer_Type_Formula__c;
        opp.Custom_ID__c = lead.Custom_ID__c;
        opp.Date_of_Application__c = lead.Date_of_Application__c;
        opp.Date_of_Expiration__c = lead.Date_of_Expiration__c;
        opp.Date_of_Issuance__c = lead.Date_of_Issuance__c;
        opp.Direct_Disbursal_to_Installer_Authorized__c = lead.Direct_Disbursal_to_Installer_Authorized__c;
        opp.DOER_Solar_Loan__c = lead.DOER_Solar_Loan__c;
        opp.Utility_Account__c = lead.Electric_Account_Number__c;
        opp.Electronic_Disbursal_Authorized__c = lead.Electronic_Disbursal_Authorized__c;
        opp.Email__c = lead.Email_Re_Enter__c;
        opp.Employed_for_more_than_one_year__c = lead.Employed_for_more_than_one_year__c;
        opp.Employed_for_more_than_six_months__c = lead.Employed_for_more_than_six_months__c;
        opp.External_System_Lead_ID__c = lead.External_System_Lead_ID__c;
        opp.Form_Completion_Time__c = lead.Form_Completion_Time__c;
        opp.State_ab__c = lead.LASERCA__Home_State__c;
        opp.Income_Type__c = lead.Income_Type__c;
        opp.Income_Type_2__c = lead.Income_Type_2__c;
        opp.Is_Loan_Secured__c = lead.Is_Loan_Secured__c;
        opp.Lead_ID__c = lead.Lead_ID__c;
        opp.Lived_at_residence_more_than_six_months__c = lead.Lived_Residence_Six_Months__c;
        opp.Loan_Program_Class__c = lead.Loan_Program_Class__c;
        opp.Loan_Principle__c  = lead.System_Cost__c;
        opp.Requested_Loan_Amount__c  = lead.Requested_Loan_Amount__c;
        opp.Maximum_Loan__c = lead.Maximum_Loan__c;
        opp.Maximum_Monthly_Disbursement__c = lead.Maximum_Monthly_Disbursement2__c;
        opp.Monthly_Income__c = lead.Monthly_Income__c;
        opp.Monthly_Income_2__c = lead.Monthly_Income_2__c;
        opp.Monthly_Income_Details__c = lead.Monthly_Income_Details__c;
        opp.Monthly_Income_Details_2__c = lead.Monthly_Income_Details_2__c;
        opp.More_than_five_years_industry_experience__c = lead.More_than_five_years_industry_experience__c;
        opp.Name = lead.Company;
        opp.Number_of_Years_at_Location__c = lead.Number_of_Years_at_Location__c;
        opp.Number_of_Years_in_Business__c = lead.Number_of_Years_in_Business__c;
        opp.Parcel_ZIp__c = lead.Parcel_Zip__c;
        opp.Partner_tag_lookup__c = lead.Partner_lookup__c;
        opp.Partner_Email__c = lead.Partner_Email__c;
        opp.Partner_Tag__c = lead.Partner_Tag__c;
        opp.Personal_Credit_Report2__c = lead.Personal_Credit_Report__c;
        opp.Personal_Credit_Report_Co_Applicant__c = lead.Personal_Credit_Report_Co_Applicant__c;
        opp.Customer_Phone__c = lead.Phone2__c;
        opp.Product_Line__c = lead.Product_Line__c;
        opp.Project_Identification_Number__c = lead.Project_Identification_Number__c;
        opp.Referral_Email__c = lead.Referral_Email__c;
        opp.Residence_Owner__c = lead.Residence_Owner__c;
        opp.BS_Sales_ID__c = lead.bs_Sales_ID__c;
        opp.Sales_Person_Tag__c = lead.Sales_Person__c;
        opp.Security_Type__c = lead.Security_Type__c;
        opp.Service_Territory__c = lead.Load_Zone__c;
        opp.Subscription__c = lead.Solar_Coverage__c;
        opp.State_of_Issuance__c = lead.State_of_Issuance__c;
        opp.Project_Assignment__c = lead.System_Assignment__c;
        opp.Annual_Consumption_kWh__c = lead.Total_Annual_Consumption_kWh__c;
        opp.Annual_Electricity_Cost__c = lead.Total_Annual_Electricity_Cost__c;
        opp.UtilityMapper__c = lead.Utility__c;
        opp.Utility_Account_Holder_Name__c = lead.Utility_Account_Holder__c;
        opp.Utility_Account_Holder_Business__c = lead.Utility_Account_Holder_Business__c;
        opp.Utility_Password__c = lead.Utility_Account_Password__c;
        opp.Username__c = lead.Utility_Account_Username__c;
        opp.Utility_Relationship__c = lead.Utility_Relationship__c;
        opp.OwnerId = lead.OwnerId;
        return opp;
    }

    @TestVisible
    private class AnnualEnergyTotal {
        public Decimal cost;
        public Decimal kWh;

        AnnualEnergyTotal(Decimal cost, Decimal kWh) {
            this.cost = cost.setScale(0);
            this.kWh = kWh.setScale(0);
        }
    }

    public class SSSWrapper implements Comparable {
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
                if (sss.Estimated_COD_Date_QC__c > compareToSSS.sss.Estimated_COD_Date_QC__c) {
                    returnValue = 1;
                } else if (sss.Estimated_COD_Date_QC__c < compareToSSS.sss.Estimated_COD_Date_QC__c) {
                    returnValue = -1;
                } else {
                    if (sss.Project_Capacity_Available_kW_DC__c > compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = 1;
                    } else if (sss.Project_Capacity_Available_kW_DC__c < compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = -1;
                    }
                }
            } else if (systemAssignment == 'Automatic - Assignment Order') {
                if (sss.Assignment_Order__c > compareToSSS.sss.Assignment_Order__c) {
                    return 1;
                } else if (sss.Assignment_Order__c < compareToSSS.sss.Assignment_Order__c) {
                    return -1;
                }
            }
            return returnValue;
        }
    }
}