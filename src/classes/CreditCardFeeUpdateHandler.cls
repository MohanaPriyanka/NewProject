public with sharing class CreditCardFeeUpdateHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public CreditCardFeeUpdateHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    public void OnBeforeUpdate (ChargentOrders__ChargentOrder__c[] oldorders, ChargentOrders__ChargentOrder__c[] orders){
        CCfeeInsert (oldorders, orders);
    }

    public void OnAfterUpdate (ChargentOrders__ChargentOrder__c[] orders){
        CreditCardFeeUpdate (orders);
    }

    private void CCfeeInsert (List<ChargentOrders__ChargentOrder__c> oldorders, List<ChargentOrders__ChargentOrder__c> orders){
        Map <Id, ChargentOrders__ChargentOrder__c> oldmap = new Map <Id, ChargentOrders__ChargentOrder__c> (); 
        List <ChargentOrders__ChargentOrder__c> trigorders = new List <ChargentOrders__ChargentOrder__c> (); 
        Set <Id> dupset = new Set <Id> (); 
        List <ChargentOrders__ChargentOrder__c> insertlist = new List <ChargentOrders__ChargentOrder__c> (); 
        List <string> propaccids = new List <string> (); 

        for(ChargentOrders__ChargentOrder__c o: oldorders){
              oldmap.put(o.id, o);
        }

        for(ChargentOrders__ChargentOrder__c n: orders){
            string newvalueid = n.Id;
            system.debug(n.Order_Type__c);
            system.debug('new checkbox' + n.Create_Duplicate_CC_Fees_On_Insert__c);
            system.debug('old checkbox' + oldmap.get(newvalueid).Create_Duplicate_CC_Fees_On_Insert__c);
          
            if(n.Create_Duplicate_CC_Fees_On_Insert__c == TRUE 
                && oldmap.get(newvalueid).Create_Duplicate_CC_Fees_On_Insert__c == FALSE 
                && n.Order_Type__c == 'Credit Card Fee (3%)'){
                system.debug(n.Id);
                trigorders.add(n);
            }
        }

        system.debug('trigorders' + trigorders);
        if(trigorders.size()>0){
            // query for orders related to the parent account that are recurring and create a cc fee for each. Check that they do not already have a cc
            List <ChargentOrders__ChargentOrder__c> relatedorders = [SELECT Id, ChargentOrders__Payment_Status__c, Property_Account_ID__c, 
                                                                        ChargentOrders__Card_Type__c, ChargentOrders__Card_Number__c , ChargentOrders__Card_Security_Code__c, ChargentOrders__Card_Expiration_Month__c,
                                                                        Order_Type__c, ChargentOrders__Gateway__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_First_Name__c, ChargentOrders__Billing_Last_Name__c, 
                                                                        ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Subtotal__c, ChargentOrders__Payment_Method__c,                                                                                             
                                                                        ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Payment_Stop__c , ChargentOrders__Card_Last_4__c, 
                                                                        ChargentOrders__Payment_Frequency__c, Parent_Order__c, ChargentOrders__Shipping_Name__c, ChargentOrders__Charge_Date__c, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Charge_Amount__c  
                                                                    FROM ChargentOrders__ChargentOrder__c
                                                                    WHERE ChargentOrders__Payment_Status__c = 'Recurring']; 
            system.debug(relatedorders);

            for(ChargentOrders__ChargentOrder__c dup: relatedorders){
                if(dup.Parent_Order__c != null){
                    dupset.add(dup.Parent_Order__c);
                }
            }

            system.debug(dupset);

            for(ChargentOrders__ChargentOrder__c cc : trigorders){
                string accountid = cc.Property_Account_ID__c;
                    for(ChargentOrders__ChargentOrder__c ro : relatedorders){
                        string relatedparent = ro.Id;
                        string shortid = relatedparent.substring(0,15);
                        system.debug('shortid' + shortid);
                        system.debug('parentorderid' + cc.Parent_Order__c);

                        if(dupset.contains(ro.id)){
                            system.debug('there is already a recurring CC fee for this order');
                        }

                        else if(ro.Id == cc.Parent_Order__c){
                            system.debug('parentorder' + ro.Id);
                        }

                        else if(ro.Property_Account_ID__c == accountid 
                                && ro.Order_Type__c != 'Credit Card Fee (3%)' 
                                && ro.Property_Account_ID__c != null){
                            system.debug('not parent - samepropertyaccount' + ro.Id);
                            ChargentOrders__ChargentOrder__c order1  = new ChargentOrders__ChargentOrder__c(
                                                                        Parent_Order__c = ro.Id,
                                                                        Order_Type__c = 'Credit Card Fee (3%)',
                                                                        Create_Duplicate_CC_Fees_On_Insert__c = FALSE,
                                                                        ChargentOrders__Gateway__c = ro.ChargentOrders__Gateway__c,
                                                                        ChargentOrders__Billing_First_Name__c = ro.ChargentOrders__Billing_First_Name__c,
                                                                        ChargentOrders__Billing_Last_Name__c = ro.ChargentOrders__Billing_Last_Name__c,
                                                                        ChargentOrders__Shipping_Name__c = ro.ChargentOrders__Shipping_Name__c,
                                                                        ChargentOrders__Billing_Address__c = ro.ChargentOrders__Billing_Address__c,
                                                                        ChargentOrders__Billing_Zip_Postal__c = ro.ChargentOrders__Billing_Zip_Postal__c,                                                                                                    
                                                                        ChargentOrders__Subtotal__c = 0,
                                                                        ChargentOrders__Payment_Method__c = ro.ChargentOrders__Payment_Method__c,
                                                                        ChargentOrders__Card_Type__c = ro.ChargentOrders__Card_Type__c,
                                                                        ChargentOrders__Card_Number__c = ro.ChargentOrders__Card_Number__c,
                                                                        ChargentOrders__Card_Security_Code__c = ro.ChargentOrders__Card_Security_Code__c,
                                                                        ChargentOrders__Card_Expiration_Month__c = ro.ChargentOrders__Card_Expiration_Month__c,
                                                                        ChargentOrders__Card_Expiration_Year__c = ro.ChargentOrders__Card_Expiration_Year__c,
                                                                        ChargentOrders__Card_Last_4__c = ro.ChargentOrders__Card_Last_4__c,
                                                                        ChargentOrders__Payment_Status__c = ro.ChargentOrders__Payment_Status__c,
                                                                        ChargentOrders__Payment_Stop__c = ro.ChargentOrders__Payment_Stop__c,
                                                                        ChargentOrders__Payment_Frequency__c = ro.ChargentOrders__Payment_Frequency__c,  
                                                                        ChargentOrders__Charge_Date__c = ro.ChargentOrders__Charge_Date__c,
                                                                        ChargentOrders__Payment_Start_Date__c = ro.ChargentOrders__Payment_Start_Date__c,
                                                                        ChargentOrders__Payment_End_Date__c = ro.ChargentOrders__Payment_End_Date__c,
                                                                        ChargentOrders__Charge_Amount__c = ro.ChargentOrders__Charge_Amount__c
                                                                      );
                            insertlist.add(order1);
                        }
                    }
            } 

            insert insertlist; 
            system.debug(insertlist);
        }                                                 
    } 

    private void CreditCardFeeUpdate(List<ChargentOrders__ChargentOrder__c> orders){
        system.debug(orders);
        List <string> parentid = new List <string> (); 
        Map <Id, ChargentOrders__ChargentOrder__c> feemap = new Map<Id, ChargentOrders__ChargentOrder__c> ();
        List <ChargentOrders__ChargentOrder__c> updatelist = new List <ChargentOrders__ChargentOrder__c> ();
       
        for(ChargentOrders__ChargentOrder__c o: orders){
            if(o.Order_Type__c != 'Credit Card Fee (3%)' && o.ChargentOrders__Payment_Method__c == 'Credit Card'){
                    parentid.add(o.Id);
                    system.debug(parentid);
            }
            else if(o.Order_Type__c == 'Credit Card Fee (3%)'){
                    system.debug(o.Id);
            }
        }

        if(parentid.size() > 0){
            List <ChargentOrders__ChargentOrder__c> feeorders = [   SELECT Id, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                                                                    ChargentOrders__Payment_Start_Date__c, ChargentOrders__Shipping_Name__c, Parent_Order__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                                    FROM ChargentOrders__ChargentOrder__c
                                                                    WHERE Parent_Order__c IN : parentid ];

            system.debug(feeorders);

            if(feeorders.size() > 0){
                for(ChargentOrders__ChargentOrder__c f: feeorders){
                        feemap.put(f.Parent_Order__c, f);
                }
            }

            for(ChargentOrders__ChargentOrder__c n: orders){
                string pid = n.Id;
                // for the parent orders, if there is a related cc fee order:
                if(feemap.keyset().contains(pid) == true){
                    decimal newamount = n.ChargentOrders__Charge_Amount__c;
                    system.debug(newamount);
                    feemap.get(pid).ChargentOrders__Payment_Status__c = n.ChargentOrders__Payment_Status__c;
                    feemap.get(pid).ChargentOrders__Payment_Stop__c = n.ChargentOrders__Payment_Stop__c;
                    feemap.get(pid).ChargentOrders__Payment_Frequency__c = n.ChargentOrders__Payment_Frequency__c;  
                    feemap.get(pid).ChargentOrders__Charge_Date__c = n.ChargentOrders__Charge_Date__c;
                    feemap.get(pid).ChargentOrders__Payment_Start_Date__c = n.ChargentOrders__Payment_Start_Date__c;
                    feemap.get(pid).ChargentOrders__Payment_End_Date__c = n.ChargentOrders__Payment_End_Date__c;
                    feemap.get(pid).ChargentOrders__Charge_Amount__c = newamount * 0.03;
                    updatelist.add(feemap.get(pid));
                    system.debug(updatelist);
                }
            }

            update updatelist;
            system.debug(updatelist);
        }
        
        
    }
}