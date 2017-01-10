public with sharing class PaymentGatewayAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public PaymentGatewayAssignmentHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(ChargentOrders__ChargentOrder__c[] newChargentOrders){
        assignNewGateway(newChargentOrders);
    }
    private void assignNewGateway(List<ChargentOrders__ChargentOrder__c> chOrderList){
        Map<Id,ChargentBase__Gateway__c> gatewayMap = new Map<Id,ChargentBase__Gateway__c>();
        List<ChargentOrders__ChargentOrder__c> chOrderUpdateList = new List<ChargentOrders__ChargentOrder__c>();
        List<ChargentOrders__ChargentOrder__c> chargentOrderIdList = new List<ChargentOrders__ChargentOrder__c>();
        List<ChargentOrders__ChargentOrder__c> chargentOrderAssignmentList = new List<ChargentOrders__ChargentOrder__c>();
        system.debug(chOrderList);
        for(ChargentOrders__ChargentOrder__c chargentOrderVar : chOrderList){
            chargentOrderIdList.add(chargentOrderVar);
        }
        for(ChargentOrders__ChargentOrder__c chargentOrder : [SELECT Id, Name, System_Bill__r.Shared_Solar_System__r.Id, ChargentOrders__Shipping_Name__c
                                                              FROM ChargentOrders__ChargentOrder__c 
                                                              WHERE Id IN : chargentOrderIdList]){
            chargentOrderAssignmentList.add(chargentOrder);
        }
        for(ChargentBase__Gateway__c gatewayVar : [SELECT Id, Name, Shared_Solar_System__r.Id
                                                   FROM ChargentBase__Gateway__c 
                                                   WHERE Shared_Solar_System__c != null]){
            gatewayMap.put(gatewayVar.Shared_Solar_System__r.Id, gatewayVar);
            system.debug(gatewayMap);
        }
        system.debug(gatewayMap.size());
        if(gatewayMap.size()>0){
            for(ChargentOrders__ChargentOrder__c chOrder : chargentOrderAssignmentList){
                //Shipping Last name is used because the FormAssembly connectors will only allow fields like these to map SSS ID and System Bill gets updated out of sequence.
                chOrder.ChargentOrders__Gateway__c = gatewayMap.get(chOrder.ChargentOrders__Shipping_Name__c).Id;
                chOrderUpdateList.add(chOrder);
                chOrder.ChargentOrders__Shipping_Name__c = null;
            }
            update chOrderUpdateList;           
        }


    }
}