/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - If a one time payment is made online, 1 CCfee order will also be made (nothing to do)
 + *   If someone is on recurring, however, they need 1 CCfee order for each order they 
 + *   have that is recurring. duplicateCCFeeForRecurring handles this
 + *
 + * - Additionally, when the parent order is updated (ie for Recurring the charge amount changes) 
 + *   the child CC fee record will also change
 + * 
 + * Tested By: CreditCardFeeUpdateHandlerTest
 + *************************************************************************************/

public without sharing class CreditCardFeeUpdateHandler {

    public void OnBeforeUpdate (ChargentOrders__ChargentOrder__c[] oldorders, ChargentOrders__ChargentOrder__c[] orders){
        duplicateCCFeeForRecurring(oldorders, orders);
    }

    public void OnAfterUpdate (ChargentOrders__ChargentOrder__c[] orders){
        updateCreditCardFee(orders);
    }

    private void duplicateCCFeeForRecurring (List<ChargentOrders__ChargentOrder__c> oldorders, List<ChargentOrders__ChargentOrder__c> orders){
        Map<Id, ChargentOrders__ChargentOrder__c> oldOrderMap = new Map<Id, ChargentOrders__ChargentOrder__c> (); 
        List<ChargentOrders__ChargentOrder__c> triggeredOrders = new List<ChargentOrders__ChargentOrder__c> (); 
        Set<Id> duplicateSet = new Set<Id> (); 
        List<ChargentOrders__ChargentOrder__c> insertList = new List<ChargentOrders__ChargentOrder__c> (); 

        for(ChargentOrders__ChargentOrder__c old : oldorders){
            oldOrderMap.put(old.id, old);
        }

        for(ChargentOrders__ChargentOrder__c newOrder : orders){
            if(newOrder.Create_Duplicate_CC_Fees_On_Insert__c
                && !oldOrderMap.get(newOrder.Id).Create_Duplicate_CC_Fees_On_Insert__c
                && newOrder.Order_Type__c == 'Credit Card Fee (3%)'){
                triggeredOrders.add(newOrder);
            }
        }

        if (triggeredOrders.size()>0){
            List<ChargentOrders__ChargentOrder__c> allRecurringOrders = [
                SELECT Id, ChargentOrders__Payment_Status__c, Property_Account_ID__c,
                    ChargentOrders__Card_Type__c, ChargentOrders__Card_Number__c ,
                    ChargentOrders__Card_Security_Code__c, ChargentOrders__Card_Expiration_Month__c,
                    Order_Type__c, ChargentOrders__Gateway__c, ChargentOrders__Billing_Address__c,
                    ChargentOrders__Billing_First_Name__c, ChargentOrders__Billing_Last_Name__c,
                    ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Subtotal__c,
                    ChargentOrders__Payment_Method__c,
                    ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Payment_Stop__c ,
                    ChargentOrders__Card_Last_4__c,
                    ChargentOrders__Payment_Frequency__c, Parent_Order__c,
                    Entity__c, ChargentOrders__Shipping_Name__c, ChargentOrders__Charge_Date__c,
                    ChargentOrders__Payment_Start_Date__c, ChargentOrders__Payment_End_Date__c,
                    ChargentOrders__Charge_Amount__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            ];

            // If there is already a CC fee created, it will be set as Recurring and have a Parent Order. 
            // That Parent Order doesn't need any more ccFees
            for(ChargentOrders__ChargentOrder__c recurringOrder : allRecurringOrders){
                if (recurringOrder.Parent_Order__c != null){
                    duplicateSet.add(recurringOrder.Parent_Order__c);
                }
            }

            for(ChargentOrders__ChargentOrder__c newlyCreatedOrder : triggeredOrders){                
                for(ChargentOrders__ChargentOrder__c orderToCheck : allRecurringOrders){
                    String relatedparent = orderToCheck.Id;
                    String shortid = relatedparent.substring(0,15);
                    if (orderToCheck.Property_Account_ID__c != null
                        && orderToCheck.Property_Account_ID__c == newlyCreatedOrder.Property_Account_ID__c 
                        && orderToCheck.Order_Type__c != 'Credit Card Fee (3%)' 
                        && !duplicateSet.contains(orderToCheck.Id) ){
                            ChargentOrders__ChargentOrder__c order1  = new ChargentOrders__ChargentOrder__c(
                                Parent_Order__c = orderToCheck.Id,
                                Order_Type__c = 'Credit Card Fee (3%)',
                                Create_Duplicate_CC_Fees_On_Insert__c = FALSE,
                                ChargentOrders__Gateway__c = orderToCheck.ChargentOrders__Gateway__c,
                                ChargentOrders__Billing_First_Name__c = orderToCheck.ChargentOrders__Billing_First_Name__c,
                                ChargentOrders__Billing_Last_Name__c = orderToCheck.ChargentOrders__Billing_Last_Name__c,
                                ChargentOrders__Shipping_Name__c = orderToCheck.ChargentOrders__Shipping_Name__c,
                                Entity__c = orderToCheck.Entity__c,
                                ChargentOrders__Billing_Address__c = orderToCheck.ChargentOrders__Billing_Address__c,
                                ChargentOrders__Billing_Zip_Postal__c = orderToCheck.ChargentOrders__Billing_Zip_Postal__c,
                                ChargentOrders__Subtotal__c = 0,
                                ChargentOrders__Payment_Method__c = orderToCheck.ChargentOrders__Payment_Method__c,
                                ChargentOrders__Card_Type__c = orderToCheck.ChargentOrders__Card_Type__c,
                                ChargentOrders__Card_Number__c = orderToCheck.ChargentOrders__Card_Number__c,
                                ChargentOrders__Card_Security_Code__c = orderToCheck.ChargentOrders__Card_Security_Code__c,
                                ChargentOrders__Card_Expiration_Month__c = orderToCheck.ChargentOrders__Card_Expiration_Month__c,
                                ChargentOrders__Card_Expiration_Year__c = orderToCheck.ChargentOrders__Card_Expiration_Year__c,
                                ChargentOrders__Card_Last_4__c = orderToCheck.ChargentOrders__Card_Last_4__c,
                                ChargentOrders__Payment_Status__c = orderToCheck.ChargentOrders__Payment_Status__c,
                                ChargentOrders__Payment_Stop__c = orderToCheck.ChargentOrders__Payment_Stop__c,
                                ChargentOrders__Payment_Frequency__c = orderToCheck.ChargentOrders__Payment_Frequency__c,
                                ChargentOrders__Charge_Date__c = orderToCheck.ChargentOrders__Charge_Date__c,
                                ChargentOrders__Payment_Start_Date__c = orderToCheck.ChargentOrders__Payment_Start_Date__c,
                                ChargentOrders__Payment_End_Date__c = orderToCheck.ChargentOrders__Payment_End_Date__c,
                                ChargentOrders__Charge_Amount__c = orderToCheck.ChargentOrders__Charge_Amount__c
                            );
                            insertList.add(order1);
                    }
                }
            } 
            insert insertList; 
        }                                                 
    } 

    private void updateCreditCardFee(List<ChargentOrders__ChargentOrder__c> orders){
        List<string> parentIdList = new List<string> (); 
        Map<Id, ChargentOrders__ChargentOrder__c> feemap = new Map<Id, ChargentOrders__ChargentOrder__c> ();
        List<ChargentOrders__ChargentOrder__c> updatelist = new List<ChargentOrders__ChargentOrder__c> ();
       
        for(ChargentOrders__ChargentOrder__c choOrder : orders){
            if (choOrder.Order_Type__c != 'Credit Card Fee (3%)' 
                && choOrder.ChargentOrders__Payment_Method__c == 'Credit Card'){
                    parentIdList.add(choOrder.Id);
            }
        }

        if (parentIdList.size() > 0){
            List<ChargentOrders__ChargentOrder__c> feeorders = [
                SELECT Id, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c,
                    ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                    ChargentOrders__Payment_Start_Date__c, Entity__c, ChargentOrders__Shipping_Name__c,
                    Parent_Order__c, ChargentOrders__Payment_End_Date__c,
                    ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE Parent_Order__c IN : parentIdList
            ];
            if (feeorders.size() > 0){
                for(ChargentOrders__ChargentOrder__c ccOrder : feeorders){
                        feemap.put(ccOrder.Parent_Order__c, ccOrder);
                }
            }

            for(ChargentOrders__ChargentOrder__c parent : orders){
                String parentOrderId = parent.Id;
                if (feemap.keyset().contains(parentOrderId)){
                    Decimal newChargeAmount = parent.ChargentOrders__Charge_Amount__c;
                    feemap.get(parentOrderId).ChargentOrders__Payment_Status__c = parent.ChargentOrders__Payment_Status__c;
                    feemap.get(parentOrderId).ChargentOrders__Payment_Stop__c = parent.ChargentOrders__Payment_Stop__c;
                    feemap.get(parentOrderId).ChargentOrders__Payment_Frequency__c = parent.ChargentOrders__Payment_Frequency__c;  
                    feemap.get(parentOrderId).ChargentOrders__Charge_Date__c = parent.ChargentOrders__Charge_Date__c;
                    feemap.get(parentOrderId).ChargentOrders__Payment_Start_Date__c = parent.ChargentOrders__Payment_Start_Date__c;
                    feemap.get(parentOrderId).ChargentOrders__Payment_End_Date__c = parent.ChargentOrders__Payment_End_Date__c;
                    feemap.get(parentOrderId).ChargentOrders__Charge_Amount__c = (newChargeAmount * 0.03).setScale(2);
                    updatelist.add(feemap.get(parentOrderId));
                }
            }
            update updatelist;
        }
        
        
    }
}