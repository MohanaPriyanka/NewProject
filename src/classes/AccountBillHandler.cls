public with sharing class AccountBillHandler{
    public static void handleAccountBill(List<Account_Bill__c> accountBillList) {
        List<String> propertyaccountIds = new List<String>();
        Map<String, Account_Bill__c> abMap = new Map<String, Account_Bill__c>();

        for (Account_Bill__c abill : accountBillList) {
            propertyaccountIds.add(abill.Property_Account_ID__c);
        }      

        for(Account_Bill__c relatedBill : [ SELECT Id, Property_Account_ID__c, Bill_Number__c,
                                            Total_Due__c, Total_Payments_This_Month__c
                                            FROM Account_Bill__c
                                            WHERE Property_Account_ID__c 
                                            IN : propertyaccountIds ] ) {
            abMap.put(relatedBill.Property_Account_ID__c+'_'+relatedBill.Bill_Number__c, relatedBill);
        }

        for (Account_Bill__c trigAB : accountBillList) {
            if (trigAB.Overpayment_Amount__c == NULL) {
                trigAB.Overpayment_Amount__c = 0;
            }
            String abKey = trigAB.Property_Account_ID__c+'_'+(trigAB.Bill_Number__c -1);
            if ( abMap.containsKey(abKey) ) {
                trigAB.Past_Bill__c = abMap.get(abKey).Total_Due__c;
                trigAB.Past_Payment__c =  abMap.get(abKey).Total_Payments_This_Month__c;
            } else {
                trigAB.Past_Bill__c = 0;
                trigAB.Past_Payment__c = 0;
            }
        }
    }

    public static void updateCheckAddressFromAccountBill (List<Account_Bill__c> accountBillList) {
    // if Triggered by AB, find other ABs get the max one and pass that through
        Map<Id, Id> accountToABMap = new Map<Id, Id>();
        List<String> accountIdList = new List<String>();
        List<Id> propertyIdList = new List<Id>();        
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, String> acctToFieldMap = new Map<Id, String>();
        String checkLine;


        for (Account_Bill__c trigAcctBill : accountBillList) {
            propertyIdList.add(trigAcctBill.Property_Account_ID__c);
        }

        for (Account_Bill__c acctBill : [SELECT Id, Name, Bill_Number__c,
                                            Property_Account_ID__c, Parent_Account__r.Max_Account_Bill_Number__c
                                            FROM Account_Bill__c 
                                            WHERE Parent_Account__r.Id IN : propertyIdList
                                            ORDER BY Bill_Number__c DESC ]) {
            if (acctBill.Parent_Account__r.Max_Account_Bill_Number__c == acctBill.Bill_Number__c){
                accountIdList.add(acctBill.Property_Account_ID__c);
                accountToABMap.put(acctBill.Id, acctBill.Property_Account_ID__c);
            }
        }

        for (Account accountList : [   SELECT Id, Name, Max_Account_Bill_Number__c,
                                        Directions_to_Write_Paper_Check__c,
                                        Send_Checks_Address__c
                                        FROM Account 
                                        WHERE Id IN : accountIdList ] ) {
            accountMap.put(accountList.Id, accountList);
        }

        List<AggregateResult> checkAddress = [  SELECT Account_Bill__r.Id abID, 
                                                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Name ProjectCompany, 
                                                MAX(Account_Bill__r.Parent_Account__r.Account_Number__c)AcctNum,
                                                SUM(Total_Due__c)TotalDue
                                                FROM System_Bill__c 
                                                WHERE Account_Bill__c IN : accountToABMap.keySet()
                                                GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Name, 
                                                Account_Bill__r.Id
                                                ORDER BY SUM(Total_Due__c) DESC];

        for (AggregateResult lineItem : checkAddress)  {
            checkLine = '';
            if (accountToABMap.containsKey((Id)lineItem.get('abID'))) {
                Id accountId = accountToABMap.get((Id)lineItem.get('abID'));
                Decimal lineItemDue = ((Decimal)lineItem.get('TotalDue')).setScale(2);

                if ( !acctToFieldMap.containsKey(accountId)) {
                    if (lineItemDue < 0.01) {
                        checkLine = 'No Payment Due';
                        acctToFieldMap.put(accountId , checkLine);
                    } else {
                        checkLine = 'Make one check out to ' + (String)lineItem.get('ProjectCompany') + ' for $' + lineItemDue;
                        acctToFieldMap.put(accountId , checkLine);
                    }
                } else {
                    if (lineItemDue < 0.01) {
                        checkLine = acctToFieldMap.get(accountId) + ' ';
                        acctToFieldMap.put(accountId , checkLine);
                    } else {
                        checkLine = acctToFieldMap.get(accountId) + ', make one check out to ' + (String)lineItem.get('ProjectCompany') + ' for $' + lineItemDue;
                        acctToFieldMap.put(accountId , checkLine); 
                    }
                }
            }
        }

        List<BW_Address__c> bwAddress = BW_Address__c.getall().values();
        String defaultAddress = 'BlueWave ' + bwAddress[0].Address_Line_One__c +' '+ bwAddress[0].Address_Line_Two__c; 

        for (Id acctId : acctToFieldMap.keySet()) {
            if( acctToFieldMap.get(acctId).length() < 255) {
                accountMap.get(acctId).Directions_to_Write_Paper_Check__c = acctToFieldMap.get(acctId);
            } else {
                accountMap.get(acctId).Directions_to_Write_Paper_Check__c = 'ERROR';
            }
            if(accountMap.get(acctId).Send_Checks_Address__c == null) {
                accountMap.get(acctId).Send_Checks_Address__c = defaultAddress;
            } 
        }

        update accountMap.Values();
    }
}