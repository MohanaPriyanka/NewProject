/*************************************************************************************
 + * Created By: Cole Swain
 + * 
 + * JP Update: When a Chargent Order comes in with an entity id in the "Shipping Last Name" field
 + * update the gateway field to be the gateway that is linked to that entity
 + *            REQUIRED: Only one gateway in SF per Entity *** 
 + *  
 + * Tested By: PaymentGatewayAssignmentHandlerTestclass
 + *************************************************************************************/

public with sharing class PaymentGatewayAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public PaymentGatewayAssignmentHandler(boolean isExecuting, Integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(ChargentOrders__ChargentOrder__c[] newChargentOrders) {
        assignNewGateway(newChargentOrders);
    }
    private void assignNewGateway(List<ChargentOrders__ChargentOrder__c> chOrderList) {

        List <ChargentOrders__ChargentOrder__c> chOrderUpdateList = new List <ChargentOrders__ChargentOrder__c>();
        List <ChargentOrders__ChargentOrder__c> chargentOrderIdList = new List <ChargentOrders__ChargentOrder__c>();
        List <ChargentOrders__ChargentOrder__c> chargentOrderAssignmentList = new List <ChargentOrders__ChargentOrder__c>();
        system.debug(chOrderList);
        Set<Id> entityIds = new Set<Id>();
       
        for (ChargentOrders__ChargentOrder__c chargentOrderVar : chOrderList) {
           if (chargentOrderVar.Entity__c != null
               && chargentOrderVar.ChargentOrders__Shipping_Name__c != null
               && chargentOrderVar.ChargentOrders__Shipping_Name__c != 'CCfee') {
            chargentOrderIdList.add(chargentOrderVar);
           }
        }
        for (ChargentOrders__ChargentOrder__c chargentOrder : [SELECT Id, Name, Entity__c, ChargentOrders__Shipping_Name__c
                                                              FROM ChargentOrders__ChargentOrder__c 
                                                              WHERE Id IN : chargentOrderIdList]) {
            chargentOrderAssignmentList.add(chargentOrder);
            entityIds.add(chargentOrder.Entity__c);
        }

        Map <Id,Entity__c> entitiesByIds = new Map <Id, Entity__c>([
            SELECT Id, Name, Gateway__c
            FROM Entity__c
            WHERE Id IN : entityIds
        ]);

        if (entitiesByIds.size()>0) {
            for (ChargentOrders__ChargentOrder__c chOrder : chargentOrderAssignmentList) {
                //Shipping Last name is used because the FormAssembly connectors will only allow fields like these to map SSS ID and System Bill gets updated out of sequence.
                // should be Entity.ChargentBase__Gateway__c
                chOrder.ChargentOrders__Gateway__c = entitiesByIds.get(chOrder.Entity__c).Gateway__c;
                chOrderUpdateList.add(chOrder);
            }
            update chOrderUpdateList;           
        }
    }
}