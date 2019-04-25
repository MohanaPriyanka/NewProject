/**
 * Created by mstackhouse on 12/14/2018.
 * Description: Used by the CSSubscriptionEnroller to create CS opportunities for a lead from the required input components
 *
 * Test: LeadTriggerHandlerTest (Integration), CSOpportunityFactoryTest
 */


public without sharing class CSOpportunityFactory {
    public static List<Opportunity> generateCSOpportunities(
        Lead lead,
        List<Shared_Solar_System__c> availableSSS,
        ChargentOrders__ChargentOrder__c baseChargentOrder,
        CSSubscriptionEnroller.AnnualEnergyTotal annualTotals,
        Id propertyAccountId
    ) {
        Decimal remainingAccountCostToAllocate = annualTotals.cost;
        Decimal remainingAccountkWhToAllocate = annualTotals.kWh;
        List<Opportunity> oppListToCreate = new List<Opportunity>();
        Integer oppCounter = 1;

        for (Shared_Solar_System__c sss : availableSSS) {
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
                Opportunity opp = new Opportunity(
                    AccountId = propertyAccountId,
                    Shared_Solar_System__c = sss.Id,
                    Reserved_System_Capacity_kW_DC2__c = sss.Reserved_Capacity_kW_DC__c,
                    Available_System_Capacity_kW_DC__c = sss.Project_Capacity_Available_kW_DC__c,
                    Product__c = sss.Product__c,
                    System_Assigned__c = true,
                    NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
                    StageName = 'Contract Pending',
                    CloseDate = Date.today(),
                    UAS_Created__c = true,
                    Annual_Electricity_Cost__c = annualElectricityCostAssigned,
                    Annual_Electricity_Cost2__c = annualElectricityCostAssigned,
                    Annual_Consumption_kWh__c = annualElectricitykWhAssigned,
                    Opportunity_Order__c = oppCounter
                );
                opp = setDefaultOppFields(lead, opp);
                if (baseChargentOrder != null) {
                    opp = addPaymentInfoToOpp(opp, baseChargentOrder);
                }
                if (lead.Loan_System_Information__c != null) {
                    opp = addPaymentInfoToOpp(opp, lead.Loan_System_Information__c);
                }
                oppListToCreate.add(opp);
                oppCounter++;
            }
        }
        return oppListToCreate;
    }

    @TestVisible
    private static Opportunity addPaymentInfoToOpp(Opportunity opp, ChargentOrders__ChargentOrder__c chOrder) {
        if (chOrder.ChargentOrders__Payment_Method__c == 'Check') {
            opp.ACH_Bank_Name__c = chOrder.ChargentOrders__Bank_Name__c;
            opp.ACH_Bank_Routing_Number__c = Util.obscureText(chOrder.ChargentOrders__Bank_Routing_Number__c, 4);
            opp.ACH_Account_Type__c = chOrder.ChargentOrders__Bank_Account_Type__c;
            opp.ACH_Account_Number__c = Util.obscureText(chOrder.ChargentOrders__Bank_Account_Number__c, 4);
            opp.ACH_Name_on_Account__c = chOrder.ChargentOrders__Bank_Account_Name__c;
        } else if (chOrder.ChargentOrders__Payment_Method__c == 'Credit Card') {
            opp.CC_Card_Type__c = chOrder.ChargentOrders__Card_Type__c ;
            opp.CC_Account_Number__c = Util.obscureText(chOrder.ChargentOrders__Card_Number__c, 4);
            opp.CC_CardHolder_Name__c = chOrder.ChargentOrders__Billing_First_Name__c +' ' + chOrder.ChargentOrders__Billing_Last_Name__c;
            opp.CC_Expiration_Month__c = chOrder.ChargentOrders__Card_Expiration_Month__c;
            opp.CC_Expiration_Year__c = chOrder.ChargentOrders__Card_Expiration_Year__c;
        }
        return opp;
    }

    @TestVisible
    private static Opportunity addPaymentInfoToOpp(Opportunity opp, String paymentMethodJSON) {
        ZuoraAPI.PaymentMethod paymentMethod;
        try {
            paymentMethod = (ZuoraAPI.PaymentMethod) System.JSON.deserialize(paymentMethodJSON, ZuoraAPI.PaymentMethod.class);
        } catch (JSONException jse) {
            Logger.logLater('CSOpportunityFactory', 'addPaymentInfoToOpp', 'Couldn\'t parse json for opp: ' + opp.Id + '\n' +
                paymentMethodJSON);
            return opp;
        }
        if (paymentMethod.Type == 'ACH') {
            opp.ACH_Bank_Name__c = paymentMethod.AchBankName;
            opp.ACH_Bank_Routing_Number__c = paymentMethod.AchAbaCode;
            opp.ACH_Account_Type__c = paymentMethod.AchAccountType;
            opp.ACH_Account_Number__c = paymentMethod.AchAccountNumberMask;
            opp.ACH_Name_on_Account__c = paymentMethod.AchAccountName;
        } else if (paymentMethod.Type == 'CreditCard') {
            opp.CC_Card_Type__c = paymentMethod.CreditCardType;
            opp.CC_Account_Number__c = paymentMethod.CreditCardMaskNumber;
            opp.CC_CardHolder_Name__c = paymentMethod.CreditCardHolderName;
            opp.CC_Expiration_Month__c = String.valueOf(paymentMethod.CreditCardExpirationMonth);
            opp.CC_Expiration_Year__c = String.valueOf(paymentMethod.CreditCardExpirationYear);
        }
        return opp;
    }

    @TestVisible
    private static Opportunity setDefaultOppFields(Lead lead, Opportunity opp) {
        opp.Lead__c = lead.Id;
        opp.Application_Date__c = lead.Application__c;
        opp.Application_Type__c = lead.Application_Type__c;
        opp.Avidia_Checking_Account__c = lead.Avidia_Checking_Account__c;
        opp.Business_Title__c = lead.Business_Title__c;
        opp.Customer_Referral__c = lead.Customer_Referral__c;
        opp.Customer_type__c = lead.Customer_type__c;
        opp.Customer_Group__c = lead.Customer_Type_Formula__c;
        opp.Date_of_Application__c = lead.Date_of_Application__c;
        opp.DOER_Solar_Loan__c = lead.DOER_Solar_Loan__c;
        opp.Email__c = lead.Email_Re_Enter__c;
        opp.State_ab__c = lead.LASERCA__Home_State__c;
        opp.Is_Loan_Secured__c = lead.Is_Loan_Secured__c;
        opp.Lead_ID__c = lead.Lead_ID__c;
        opp.Loan_Program_Class__c = lead.Loan_Program_Class__c;
        opp.Maximum_Monthly_Disbursement__c = lead.Maximum_Monthly_Disbursement2__c;
        opp.Name = lead.Company;
        opp.Number_of_Years_at_Location__c = lead.Number_of_Years_at_Location__c;
        opp.Number_of_Years_in_Business__c = lead.Number_of_Years_in_Business__c;
        opp.Parcel_ZIp__c = lead.Parcel_Zip__c;
        opp.Partner_tag_lookup__c = lead.Partner_lookup__c;
        opp.Partner_Email__c = lead.Partner_Email__c;
        opp.Personal_Credit_Report2__c = lead.Personal_Credit_Report__c;
        opp.Customer_Phone__c = lead.Phone2__c;
        opp.Product_Line__c = lead.Product_Line__c;
        opp.Referral_Email__c = lead.Referral_Email__c;
        opp.BS_Sales_ID__c = lead.bs_Sales_ID__c;
        opp.Security_Type__c = lead.Security_Type__c;
        opp.LoadZone__c = lead.LoadZone__c;
        opp.Project_Assignment__c = lead.System_Assignment__c;
        opp.OwnerId = lead.OwnerId;
        return opp;
    }
}