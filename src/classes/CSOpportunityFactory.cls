/**
 * @description: Created by mstackhouse on 12/14/2018.
 * Used by the CSSubscriptionEnroller to create CS opportunities for a lead from the required input components
 * Tested By: CSOpportunityFactoryTest
 */
public without sharing class CSOpportunityFactory {

    public static List<Opportunity> generateCSOpportunities(Lead lead, List<Shared_Solar_System__c> availableSSS,
        CSSubscriptionEnroller.AnnualEnergyTotal annualTotals, Id propertyAccountId)
    {
        Decimal remainingAccountCostToAllocate = annualTotals.cost;
        Decimal remainingAccountkWhToAllocate = annualTotals.kWh;
        List<Opportunity> oppListToCreate = new List<Opportunity>();
        Integer oppCounter = 1;
		
        for (Shared_Solar_System__c sss : availableSSS) {
            if (remainingAccountCostToAllocate > 0 || remainingAccountkWhToAllocate > 0) {
                Decimal annualElectricityCostAssigned = Math.min(remainingAccountCostToAllocate, sss.Maximum_Subscription_Cost__c);
                if (remainingAccountCostToAllocate > 0) {
                    remainingAccountCostToAllocate -= annualElectricityCostAssigned;
                }
                Decimal annualElectricitykWhAssigned = Math.min(remainingAccountkWhToAllocate, SharedSolarSystems.calculateMaximumkWh(sss));
                if (remainingAccountkWhToAllocate > 0) {
                    remainingAccountkWhToAllocate -= annualElectricitykWhAssigned;
                }
                Opportunity opp = new Opportunity(
                    AccountId = propertyAccountId,
                    Shared_Solar_System__c = sss.Id,
                    Product__c = sss.Product__c,
                    System_Assigned__c = true,
                    NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
                    CloseDate = Date.today(),
                    UAS_Created__c = true,
                    Annual_Electricity_Cost__c = annualElectricityCostAssigned,
                    Annual_Electricity_Cost2__c = annualElectricityCostAssigned,
                    Annual_Consumption_kWh__c = annualElectricitykWhAssigned,
                    Opportunity_Order__c = oppCounter
                );
                opp = setOpportunityStage(lead, opp);
                opp = setDefaultOppFields(lead, opp);
                oppListToCreate.add(opp);
                oppCounter++;
            }
        }
        return oppListToCreate;
    }

    @TestVisible
    private static Opportunity setOpportunityStage(Lead lead, Opportunity opp) {
        if (lead.LeadSource == 'Switch' || lead.LeadSource == 'Third-Party') {
            opp.StageName = 'QC in Process';
        } else {
            opp.StageName = 'Contract Pending';
        }
        return opp;
    }

    @TestVisible
    private static Opportunity setDefaultOppFields(Lead lead, Opportunity opp) {
        opp.Lead__c = lead.Id;
        opp.Acquired_By_Client_Closed_By_BlueWave__c = lead.Acquired_By_Client_Closed_By_BlueWave__c;
        opp.Application_Date__c = lead.Application__c;
        opp.Application_Type__c = lead.Application_Type__c;
        opp.BS_Sales_ID__c = lead.bs_Sales_ID__c;
        opp.Business_Title__c = lead.Business_Title__c;
        opp.Customer_Group__c = lead.Customer_Type_Formula__c;
        opp.Customer_Phone__c = lead.Phone2__c;
        opp.Customer_Referral__c = lead.Customer_Referral__c;
        opp.Customer_Type__c = lead.Customer_type__c;
        opp.Date_of_Application__c = lead.Date_of_Application__c;
        opp.Lead_ID__c = lead.Lead_ID__c;
        opp.LoadZone__c = lead.LoadZone__c;
        opp.Name = lead.Company;
        opp.OwnerId = lead.OwnerId;
        opp.Parcel_ZIp__c = lead.Parcel_Zip__c;
        opp.Partner_Email__c = lead.Partner_Email__c;
        opp.Partner_tag_lookup__c = lead.Partner_Lookup__c;
        opp.Partner_Account__c = lead.Partner_Account__c;
        opp.Partner_Contact__c = lead.Partner_Contact__c;
        opp.Personal_Credit_Report2__c = lead.Personal_Credit_Report__c;
        opp.Product_Line__c = lead.Product_line__c;
        opp.Project_Assignment__c = lead.System_Assignment__c;
        opp.Referral_Email__c = lead.Referral_Email__c;
        opp.State_ab__c = lead.LASERCA__Home_State__c;
        opp.Underwriting_Criteria__c = lead.Underwriting_Criteria__c;
        return opp;
    }
}