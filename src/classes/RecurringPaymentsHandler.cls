public with sharing class RecurringPaymentsHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public RecurringPaymentsHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(UASB__c[] newUtilityAccountBillSubscriptionUpdates){
        updateRecurringCharge(newUtilityAccountBillSubscriptionUpdates);
    }

    private void updateRecurringCharge(List <UASB__c> utilityAccountBillSubscriptionList){
    List <string> abfromuasb = new list <string> ();
    List <string> sbfromuasb = new list <string> ();
    List <ChargentOrders__ChargentOrder__c> updatelist = new list <ChargentOrders__ChargentOrder__c> ();

        for(UASB__c uasb : utilityAccountBillSubscriptionList){
            abfromuasb.add(uasb.Account_Bill_ID__c);
        }

        List <Account_Bill__c> aBlist =   [  SELECT Id, Name, Bill_Number__c, Total_Due__c, Property_Account_ID__c 
                                            FROM Account_Bill__C
                                            WHERE Id in : abfromuasb] ;

        List <ChargentOrders__ChargentOrder__c> orders = [  SELECT Id, Unique_ID__c, Account_Bill__c, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                                                                ChargentOrders__Payment_Start_Date__c, Property_Account_ID__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Gateway__r.Entity__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                            FROM ChargentOrders__ChargentOrder__c 
                                                            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
                                                            ORDER BY System_Bill__r.Bill_Number__c];
        if(!orders.isEmpty()){
            for (Account_Bill__c ab : aBlist){
                    string matchid = ab.Property_Account_ID__c;
                    decimal currentbill = ab.Bill_Number__c;

                    for (ChargentOrders__ChargentOrder__c ch: orders){
                        if (ch.account_Bill__r.Bill_Number__c < currentbill && ch.Property_Account_ID__c == matchid){
                                ch.Account_Bill__c = ab.Id;
                                updatelist.add(ch);
                            }
                    }

                matchid = ' ';
                currentbill = 0;
            }

        }

    update updatelist;

    }
}