/**
 * @description Used by UtilityDataRequestService to calculate Annual kWh and Average Demand on a UDR
 * Tested By UtilityDataRequestServiceTest
 */
public with sharing class UDRPTotalCalculator {
    @TestVisible private static StateSelector stateSelector = new StateSelector();
    public Integer numberOfUDRPsUsedInCalc = 0;
    private Decimal days = 0;
    private Decimal quantity = 0;
    public Decimal kWh = 0;
    public Decimal avgDemand = 0;
    private fflib_SObjectUnitOfWork uow;

    public UDRPTotalCalculator(fflib_SObjectUnitOfWork uow) {
        this.uow = uow;
    }

    public void setAnnualkWh(Utility_Data_Request__c udr, List <Utility_Data_Request_Period__c> udrpList) {
        String customerType = udr.Utility_Account_Log__r.Lead__r.Customer_type__c;

        if (udrpList.size() == 0) {
            return;
        }

        for (Utility_Data_Request_Period__c udrp : udrpList){
            if (updateUDRPTotals(udrp, Schema.Utility_Data_Request_Period__c.Used_in_Annual_kWh_Calculation__c)) {
                break;
            }
        }
        updatekWh(customerType, udr);
    }

    public void setAverageDemand(List <Utility_Data_Request_Period__c> udrpList) {
        if (udrpList.size() == 0) {
            return;
        }

        for (Utility_Data_Request_Period__c udrp : udrpList) {
            if (updateUDRPTotals(udrp, Schema.Utility_Data_Request_Period__c.Used_in_Average_Demand_Calculation__c)) {
                break;
            }
        }
        avgDemand = (quantity/days)*30;
        avgDemand = avgDemand.setScale(2);
    }

    private void updatekWh(String customerType, Utility_Data_Request__c udr) {
        if (days>=120 || (customerType == 'Residential' && customerType!= null)) {
            kWh=(quantity/days)*365;
        } else if ((days > 0) && (customerType != 'Residential' && customerType != null)) {
            String sizingMethod = udr.Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c;
            if (sizingMethod == 'State Average Annual Usage') {
                State__c state = stateSelector.selectByName(udr.Utility_Account_Log__r.Service_State__c);
                kWh = state.Avg_Annual_Resi_kWh__c;
            }
            //additional sizingMethods will be added later
        }
        kWh = kWh.setScale(2);
    }

    private Boolean updateUDRPTotals(Utility_Data_Request_Period__c udrp, SObjectField fieldToUpdate) {
        Decimal potentialNumDaysWithUDRP = days + udrp.Num_Days__c;

        if (potentialNumDaysWithUDRP == 365) {
            includeUDRP(udrp, fieldToUpdate);
            return true;
        } else if (potentialNumDaysWithUDRP < 365) {
            includeUDRP(udrp, fieldToUpdate);
            return false;
        } else if (365 - days > potentialNumDaysWithUDRP - 365) {
            includeUDRP(udrp, fieldToUpdate);
            return true;
        } else if (365 - days < potentialNumDaysWithUDRP - 365) {
            return true;
        }
        return true;
    }

    private void includeUDRP(Utility_Data_Request_Period__c udrp, SObjectField fieldToUpdate) {
        udrp.put(fieldToUpdate, true);
        uow.registerDirty(udrp);
        numberOfUDRPsUsedInCalc++;
        days = days + udrp.Num_Days__c;
        quantity = quantity + udrp.Quantity__c;
    }
}