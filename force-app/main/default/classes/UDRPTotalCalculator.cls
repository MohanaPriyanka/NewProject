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
    MultiMap udrpsUsedInCalcByField = MultiMap.newListInstance();

    public UDRPTotalCalculator(fflib_SObjectUnitOfWork uow) {
        this.uow = uow;
    }

    public void setAnnualkWh(Utility_Data_Request__c udr, List <Utility_Data_Request_Period__c> udrpList) {
        String customerType = udr.Utility_Account_Log__r.Lead__r.Customer_type__c;

        if (udrpList.size() == 0) {
            return;
        }

        for (Utility_Data_Request_Period__c udrp : udrpList) {
            updateUDRPTotals(udrp, Schema.Utility_Data_Request_Period__c.Used_in_Annual_kWh_Calculation__c);
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
        avgDemand = (quantity / days) * 30;
        avgDemand = avgDemand.setScale(2);
    }

    private void updatekWh(String customerType, Utility_Data_Request__c udr) {
        if (days >= 120 || (customerType == 'Residential' && customerType != null)) {
            kWh = (quantity / days) * 365;
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
        Decimal numDaysInNewPeriod = getNumDaysInNewPeriod(udrp, fieldToUpdate);
        Decimal potentialNumDaysWithUDRP = days + numDaysInNewPeriod;

        if (potentialNumDaysWithUDRP == 365) {
            includeUDRP(udrp, fieldToUpdate, numDaysInNewPeriod);
            return true;
        } else if (potentialNumDaysWithUDRP < 365) {
            includeUDRP(udrp, fieldToUpdate, numDaysInNewPeriod);
            return false;
        } else if (365 - days > potentialNumDaysWithUDRP - 365) {
            includeUDRP(udrp, fieldToUpdate, numDaysInNewPeriod);
            return true;
        } else if (365 - days < potentialNumDaysWithUDRP - 365) {
            return true;
        }
        return true;
    }

    private void includeUDRP(Utility_Data_Request_Period__c udrp, SObjectField fieldToUpdate, Decimal numDaysInNewPeriod) {
        udrpsUsedInCalcByField.putValue(fieldToUpdate, udrp);
        udrp.put(fieldToUpdate, true);
        uow.registerDirty(udrp);
        numberOfUDRPsUsedInCalc++;
        days = days + numDaysInNewPeriod;
        quantity = quantity + udrp.Quantity__c;
    }

    /**
     * @description Some UDRs (e.g. a115b00000BYOCJAA5) will have multiple UDRPs for the same period to because of different
      * Measurement Significance Codes (On Peak, Off Peak Shoulder). This will return udrp.Num_Days__c if it's the first
      * UDRP for that period used in the calculation, and otherwise 0 (since it would have already returned Num Days previously)
     * @param udrp The UDRP being evaluated
     * @param fieldToUpdate Either Used_in_Annual_kWh_Calculation__c or Used_in_Average_Demand_Calculation__c
     * @return Num_Days__c (or 0)
     */
    private Decimal getNumDaysInNewPeriod(Utility_Data_Request_Period__c udrp, SObjectField fieldToUpdate) {
        List<Utility_Data_Request_Period__c> udrpsUsedInCalc = new List<Utility_Data_Request_Period__c>();
        CollectionUtil.toTypedList(udrpsUsedInCalcByField.getValues(fieldToUpdate), udrpsUsedInCalc);
        for (Utility_Data_Request_Period__c udrpUsedInCalc : udrpsUsedInCalc) {
            if (udrp.Service_Start_Date__c == udrpUsedInCalc.Service_Start_Date__c &&
                udrp.Service_End_Date__c == udrpUsedInCalc.Service_End_Date__c) {
                return 0;
            }
        }
        return udrp.Num_Days__c;
    }
}