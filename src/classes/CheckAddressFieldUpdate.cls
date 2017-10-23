/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class updates the fields on the account that are pulled into print and 
 + * email bills whenever the Account Bill is updated (System Bill is child object
 + * and when it updates, it triggers an update of the Account Bill as well)
 + * 
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/

public class CheckAddressFieldUpdate {
    public void updateCheckAddressFromAccountBill (List<Account_Bill__c> accountBillList) {
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
                                                Account_Bill__r.Id];

        for (AggregateResult lineItem : checkAddress)  {
            checkLine = '';
            if (accountToABMap.containsKey((Id)lineItem.get('abID'))) {
                Id accountId = accountToABMap.get((Id)lineItem.get('abID'));
                if ( !acctToFieldMap.containsKey(accountId)) {
                    checkLine = 'If you would like to pay by check, please make one check out to ' + (String)lineItem.get('ProjectCompany') + ' for $' +  ((Decimal)lineItem.get('TotalDue')).setScale(2);
                    acctToFieldMap.put(accountId , checkLine );
                } else {
                    checkLine = 'You are receiving credits from multiple projects. ' + acctToFieldMap.get(accountId) + ' and make one check out to ' + (String)lineItem.get('ProjectCompany') + ' for $' + ((Decimal)lineItem.get('TotalDue')).setScale(2);
                    acctToFieldMap.put(accountId , checkLine); 
                }
            }
        }

        List<BW_Address__c> bwAddress = BW_Address__c.getall().values();
        String defaultAddress = 'BlueWave ' + bwAddress[0].Address_Line_One__c +' '+ bwAddress[0].Address_Line_Two__c; 

        for (Id acctId : acctToFieldMap.keySet()) {
            accountMap.get(acctId).Directions_to_Write_Paper_Check__c = acctToFieldMap.get(acctId);
            if(accountMap.get(acctId).Send_Checks_Address__c == null) {
                accountMap.get(acctId).Send_Checks_Address__c = defaultAddress;
            } 
        }

        update accountMap.Values();
    }
}