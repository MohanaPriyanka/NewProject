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
    List <string> sbfromuasb = new list <string> ();
    List <ChargentOrders__ChargentOrder__c> updatelist = new list <ChargentOrders__ChargentOrder__c> ();

        for(UASB__c uasb : utilityAccountBillSubscriptionList){
            sbfromuasb.add(uasb.System_Bill__c);
        }

        List <System_Bill__c> sBlist =   [  SELECT Id, Name, Bill_Number__c, Total_Due__c, Recurring_Billing__c, Recurring_Payment_Id__c, Property_Account__r.Id, Unique_Id__c, Opportunity__r.Id 
                                            FROM System_Bill__C
                                            WHERE Id in : sbfromuasb] ;       
        system.debug('sBlist '+ sBlist);

        List <ChargentOrders__ChargentOrder__c> orders = [ SELECT Id, Unique_ID__c, System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                                                                ChargentOrders__Payment_Start_Date__c, System_Bill__r.Bill_Number__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                            FROM ChargentOrders__ChargentOrder__c 
                                                            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
                                                            ORDER BY System_Bill__r.Bill_Number__c];
        system.debug('orderlist '+ orders);

        for(System_Bill__c sb : sBlist){
            if(sb.Recurring_Billing__c == TRUE && sb.Total_Due__c != null && sb.Recurring_Payment_Id__c != null){
                string matchid = sb.Recurring_Payment_Id__c;
                decimal currentbill = sb.Bill_Number__c;
                decimal currentdue = sb.Total_Due__c;
                system.debug('matchidis ' + matchid);
                system.debug('currentbillis ' + currentbill);
                system.debug('currentdueis ' + currentdue);
                for(ChargentOrders__ChargentOrder__c ch: orders){
                    system.debug(ch.system_Bill__r.Bill_Number__c);
                    if(ch.system_Bill__r.Bill_Number__c < currentbill && ch.Unique_ID__c == matchid){
                            ch.System_Bill__c = sb.Id;
                            ch.ChargentOrders__Charge_Amount__c = currentdue;
                            updatelist.add(ch);
                    }
                }
            matchid = ' ';
            currentbill = 0;
            currentdue = 0;
            }
        }

    update updatelist;

    }
}