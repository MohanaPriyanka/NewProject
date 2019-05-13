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
    private Map<Id, List<Product_Tariff__c>> tariffsByProduct;


    public CSSubscriptionEnroller(List<Lead> leads) {
        this.leads = leads;

        List<Id> leadIds = new List<Id>();
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
        }
        ualList = [
            SELECT Id, Name, Annual_Cost_of_Electricity__c, Name_on_Account__c, Lead__c, Utility__c,
                Annual_kWh__c, Proposed_kWh__c, Lead__r.Product__r.Customer_Subscription_Type__c,
                Utility_NMC_Tariff__c
            FROM Utility_Account_Log__c
            WHERE Lead__c IN :leadIds
            ORDER BY Annual_Cost_of_Electricity__c DESC
        ];

        sssList = [
            SELECT Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Maximum_Subscription_Capacity_kW_DC__c,
                Product__c, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, Service_Territories__c,
                Reserved_Capacity_kW_DC__c, Service_Territory__c, Utility__c, Expected_Yield_kWh_kW__c,
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
                (SELECT Id, Name, Size_Ratio__c, Utility_NMC_Tariff__r.Customer_Type__c,
                    Utility_NMC_Tariff__r.Minimum_kWh__c, Utility_NMC_Tariff__r.Maximum_kWh__c,
                    Utility_NMC_Tariff__r.Utility_Relationship__c, Utility_NMC_Tariff__c
                FROM Product_Tariffs__r)
            FROM Product2
            WHERE Product_Type__c = 'Community Solar'
        ];

        productsMap = new Map<Id, Product2>();
        tariffsByProduct = new Map<Id, List<Product_Tariff__c>>();
        for (Product2 product : products) {
            productsMap.put(product.Id, product);
            tariffsByProduct.put(product.Id, product.Product_Tariffs__r);
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
            calculateProposedkWh(lead);
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
            if (lead.Zuora_Payment_Ref_Id__c != null) {
                System.enqueueJob(new ZuoraAccountAsyncService(lead.Id));
            }
        }
        insertUASes();
        updateChargentOrders();
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
            if (sss.Utility__c == lead.Utility_Relationship__c &&
                (sss.Service_Territories__c != null &&
                    sss.Service_Territories__c.contains(lead.LoadZone__c)) &&
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
            totalAnnualCostOfElectricity -= Util.nullToZero(ual.Subscribed_Annual_Cost_of_Electricity__c);
            totalAnnualkWhElectricity += Util.nullToZero(ual.Proposed_kWh__c);
            totalAnnualkWhElectricity -= Util.nullToZero(ual.Subscribed_Annual_kWhs__c);
        }
        return new AnnualEnergyTotal(totalAnnualCostOfElectricity, totalAnnualkWhElectricity);
    }

    public void createOpportunity(Lead lead) {
        AnnualEnergyTotal annualTotals = getAnnualTotals(lead);
        List<Shared_Solar_System__c> availableSSS = getSortedSharedSolarSystems(lead);
        ChargentOrders__ChargentOrder__c baseChargentOrder = chOrdersByLeadId.get(lead.Id);

        List<Opportunity> oppListToCreate = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, baseChargentOrder, annualTotals, lead.ConvertedAccountId);

        leadOppsMap.put(lead.Id, oppListToCreate);
    }

    public void insertOpps() {
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for (List<Opportunity> opps : leadOppsMap.values()) {
            oppsToInsert.addAll(opps);
        }
        insert oppsToInsert;

        for (Opportunity opp : oppsToInsert) {
            oppIdList.add(opp.Id);
        }
    }

    public void createUAS(Lead lead) {
        List<Shared_Solar_System__c> sharedSolarSystems = getSortedSharedSolarSystems(lead);
        List<Opportunity> opportunities = leadOppsMap.get(lead.Id);
        List<Utility_Account_Log__c> uals = ualsByLeadId.get(lead.Id);

        uasList.addAll(CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities));
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

    public void calculateProposedkWh(Lead lead) {
        List<Utility_Account_Log__c> uals = getUALList(lead);
        Product2 product = productsMap.get(lead.Product__c);
        for (Utility_Account_Log__c ual : uals) {
            List<Product_Tariff__c> productTariffs = tariffsByProduct.get(lead.Product__c);
            Product_Tariff__c tariff = assignUtilityTariff(ual, lead, productTariffs);
            if (tariff != null && product != null && ual.Annual_kWh__c != null) {
                ual.Utility_NMC_Tariff__c = tariff.Utility_NMC_Tariff__c;
                ual.Product_Tariff__c = tariff.Id;
                // Currently, we only need to have a sizing ratio for SMART
                Decimal sizeRatio;
                if (tariff.Size_Ratio__c != null) {
                    sizeRatio = tariff.Size_Ratio__c;
                } else {
                    sizeRatio = 1.0;
                }
                ual.Proposed_kWh__c = ual.Annual_kWh__c * sizeRatio;
            } else {
                ual.Proposed_kWh__c = ual.Annual_kWh__c;
            }
            ualsToUpdateMap.put(ual.Id, ual);
        }
        ualsByLeadId.put(lead.Id, uals);
    }

    public static Product_Tariff__c assignUtilityTariff(Utility_Account_Log__c ual, Lead lead, List<Product_Tariff__c> tariffs) {
        Product_Tariff__c assignedTariff;
        if (tariffs == null) {
            return assignedTariff;
        }
        for (Product_Tariff__c tariff : tariffs) {
            if (lead.Customer_type__c == tariff.Utility_NMC_Tariff__r.Customer_type__c
                && lead.Utility_relationship__c == tariff.Utility_NMC_Tariff__r.Utility_Relationship__c
                && (tariff.Utility_NMC_Tariff__r.Maximum_kWh__c == null || ual.Annual_kWh__c < tariff.Utility_NMC_Tariff__r.Maximum_kWh__c)
                && (tariff.Utility_NMC_Tariff__r.Minimum_kWh__c == null || ual.Annual_kWh__c >= tariff.Utility_NMC_Tariff__r.Minimum_kWh__c)) {
                if (assignedTariff == null) {
                    assignedTariff = tariff;
                } else {
                    String message = 'Lead ' + lead.Id + ' meets the criteria for multiple tariffs.';
                    message += ' Assigned Tariff: ' + assignedTariff;
                    message += ' Other Qualified Tariff: ' + tariff;
                    Logger.logLater('CSSubscriptionEnroller', 'assignUtilityTariff', message);
                }
            }
        }
        Logger.flushLogs();
        return assignedTariff;
    }

    public void updateUALs() {
        update ualsToUpdateMap.values();
    }

    public class AnnualEnergyTotal {
        public Decimal cost;
        public Decimal kWh;

        public AnnualEnergyTotal(Decimal cost, Decimal kWh) {
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