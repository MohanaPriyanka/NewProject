/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Marks SRECs as being ready for credit and updates the credit amount
 + * 
 + * Tested By: RecurringSRECHandlerTest
 + *************************************************************************************/

public without sharing class RecurringSRECHandler {
    public static void findChargentOrders(List<SREC__c> srecList) {
        List<Id> srecIdList = new List<Id>();
        Map<Id, SREC__c> chOrderMap = new Map<Id, SREC__c>();

        for (SREC__c triggeredSREC : srecList){
            srecIdList.add(triggeredSREC.Id);
        }

        for (SREC__c queriedSREC : [SELECT Id, Name,
                                    Residential_Equipment__r.Loan__r.SREC_Direct_Deposit_Order__c,
                                    Value_to_Customer__c
                                    FROM SREC__c
                                    WHERE Id IN : srecIdList]){
            chOrderMap.put(queriedSREC.Residential_Equipment__r.Loan__r.SREC_Direct_Deposit_Order__c, queriedSREC);
        }
        setOrdersToCredit(chOrderMap);
    }

    public static void setOrdersToCredit(Map<Id, SREC__c> chOrderMap) {
        List<ChargentOrders__ChargentOrder__c> cOrdersToUpdate = new List<ChargentOrders__ChargentOrder__c>();

        for (ChargentOrders__ChargentOrder__c cOrder : [SELECT Id, Name,  
                                                        ChargentOrders__Credit_Amount__c, 
                                                        SREC_Status__c,
                                                        Related_SREC__c,
                                                        Loan__c
                                                        FROM ChargentOrders__ChargentOrder__c
                                                        WHERE Id IN : chOrderMap.keySet() ]){
            if (chOrderMap.get(cOrder.Id).Value_to_Customer__c > 0.01){
                cOrder.ChargentOrders__Credit_Amount__c = chOrderMap.get(cOrder.Id).Value_to_Customer__c;
                cOrder.SREC_Status__c = 'Ready';
                cOrder.Related_SREC__c = chOrderMap.get(cOrder.Id).Id;
                cOrdersToUpdate.add(cOrder);
            }
        }
        update cOrdersToUpdate;
    }
}