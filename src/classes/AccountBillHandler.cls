/*************************************************************************************
 + * Created By: Cole Swain
 + *
+ * Tested By: RecurringPaymentsHandlerTestClass
 + *************************************************************************************/

public without sharing class AccountBillHandler{
    public static void handleAccountBill(List<Account_Bill__c> accountBillList) {
        List<String> propertyaccountIds = new List<String>();
        List<Account_Bill__c> firstAccountBillList = new List<Account_Bill__c>();
        Map<Id, Id> firstABMap = new Map<Id, Id>();
        Map<String, Account_Bill__c> abMap = new Map<String, Account_Bill__c>();
        //Map Account Bills and Chargent Orders in 1:1 Map: ordersByABMap
        //KEY: String of Account Bill; OBJECT: Chargent Order
        Map<Id, ChargentOrders__ChargentOrder__c> ordersByABMap = new Map<Id, ChargentOrders__ChargentOrder__c>();


        for (Account_Bill__c abill : accountBillList) {
            propertyaccountIds.add(abill.Property_Account_ID__c);
            if( abill.Bill_Number__c == 1) {
                firstABMap.put(abill.Parent_Account__c, abill.Id);
                firstAccountBillList.add(abill);
            }
        }

        List<ChargentOrders__ChargentOrder__c> ordersList = [ SELECT Id, ChargentOrders__Account__c, ChargentOrders__Billing_First_Name__c, ChargentOrders__Account__r.Max_Account_Bill_Number__c
                                                                FROM ChargentOrders__ChargentOrder__c
                                                                WHERE ChargentOrders__Account__c IN :firstABMap.keySet() ];

        if(!ordersList.isEmpty()) {
            for(ChargentOrders__ChargentOrder__c firstOrder : ordersList){
                String billID = firstABMap.get(firstOrder.ChargentOrders__Account__c);
                if (firstOrder.ChargentOrders__Account__r.Max_Account_Bill_Number__c <= 1) {
                    ordersByABMap.put(billID, firstOrder );
                }
            }
            retrieveFirstChargentOrder(firstAccountBillList, ordersByABMap);
        }

        for(Account_Bill__c relatedBill : [ SELECT Id, Property_Account_ID__c, Bill_Number__c, Total_Due__c, Total_Payments_This_Month__c
                                            FROM Account_Bill__c
                                            WHERE Property_Account_ID__c 
                                            IN : propertyaccountIds ] ) {
            abMap.put(relatedBill.Property_Account_ID__c+'_'+relatedBill.Bill_Number__c, relatedBill);
        }

        for (Account_Bill__c trigAB : accountBillList) {
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

    public static void retrieveFirstChargentOrder( List<Account_Bill__c> firstAccountBillList, Map<Id, ChargentOrders__ChargentOrder__c> ordersByABMap ){
        List<ChargentOrders__ChargentOrder__c> ordersToUpdate = new List<ChargentOrders__ChargentOrder__c>();

        Set<Id> firstBillIds = new Set<Id>();
        for (Account_Bill__c accountBill : firstAccountBillList) {
            firstBillIds.add(accountBill.Id);
        }

        List<System_Bill__c> systemBills = [
            SELECT Id, Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                    Shared_Solar_System__r.BWC_Project_Entity_Manual__c
            FROM System_Bill__c
            WHERE Account_Bill__c IN : firstBillIds
        ];

        Set<Id> entities = new Set<Id>();

        Map<Id, System_Bill__c> systemBillByAB = new Map<Id, System_Bill__c>();
        for (System_Bill__c systemBill : systemBills) {
            systemBillByAB.put(systemBill.Account_Bill__c, systemBill);
            entities.add(systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__c);
        }

        if(!firstAccountBillList.isEmpty()){
            for(Account_Bill__c firstBill : firstAccountBillList) {
                if (ordersByABMap.containsKey(firstBill.Id)) {
                    ChargentOrders__ChargentOrder__c firstChargentOrder = ordersByABMap.get(firstBill.Id);

                    firstChargentOrder.ChargentOrders__Payment_Frequency__c = 'Monthly';
                    firstChargentOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                    firstChargentOrder.ChargentOrders__Payment_Stop__c = 'Unending';
                    firstChargentOrder.ChargentOrders__Charge_Date__c = '01';
                    firstChargentOrder.Reason_for_Recurring_Stop__c = '';
                    firstChargentOrder.ChargentOrders__Payment_Start_Date__c = Date.today().addDays(-1);

                    //Move Chargent Order to the Account Bill
                    firstChargentOrder.Account_Bill__c = firstBill.Id;

                    //Remove the Chargent Order from the Property Account
                    firstChargentOrder.Property_Account__c = null;
                    firstChargentOrder.ChargentOrders__Account__c = null;

                    // Waitlist entities should not have a system bill, so we should update to an entity that has a bill
                    if (!entities.contains(firstChargentOrder.Entity__c)) {
                        System_Bill__c systemBill = systemBillByAB.get(firstBill.Id);
                        Id gatewayId = systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c;
                        firstChargentOrder.ChargentOrders__Gateway__c = gatewayId;
                        firstChargentOrder.Entity__c = systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
                    }


                    //Add Chargent Order to list for update
                    ordersToUpdate.add(firstChargentOrder);
                }
            }

        update ordersToUpdate;
        }
    }

    public static void updateCheckAddressFromAccountBill (List<Account_Bill__c> accountBillList) {
    // if Triggered by AB, find other ABs get the max one and pass that through
        Map<Id, Id> accountToABMap = new Map<Id, Id>();
        List<String> accountIdList = new List<String>();
        List<Id> propertyIdList = new List<Id>();        
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, String> acctToFieldMap = new Map<Id, String>();
        Map<Id, String> checkAddressOverrideMap = new Map<Id, String>();
        Map<Id, String> clientLogoOverrideMap = new Map<Id, String>();
        Map<Id, Entity__c> entityMap = new Map<Id, Entity__c>();
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

        for (Entity__c entity : [ SELECT Id, Name, Send_Checks_Address__c, Client_Account__r.Client_Brand_Key__c
                                    FROM Entity__c ] ) {
            entityMap.put(entity.Id, entity);
        }

        List<AggregateResult> checkAddress = [  SELECT Account_Bill__r.Id abID, 
                                                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id ProjectCompanyId, 
                                                MAX(Account_Bill__r.Parent_Account__r.Account_Number__c)AcctNum,
                                                SUM(Total_Due__c)TotalDue
                                                FROM System_Bill__c 
                                                WHERE Account_Bill__c IN : accountToABMap.keySet()
                                                GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id, 
                                                Account_Bill__r.Id
                                                ORDER BY SUM(Total_Due__c) DESC];

        List<BW_Address__c> bwAddress = BW_Address__c.getall().values();
        String defaultAddress = 'BlueWave ' + bwAddress[0].Address_Line_One__c;
        defaultAddress += (', '+ bwAddress[0].Address_Line_Two__c);
        defaultAddress += (' '+ bwAddress[0].City__c + ',');
        defaultAddress += (' '+ bwAddress[0].State__c);
        defaultAddress += (' '+ bwAddress[0].Zip_Code__c);

        for (AggregateResult lineItem : checkAddress)  {
            checkLine = '';
            if (accountToABMap.containsKey((String)lineItem.get('abID'))) {
                String accountId = accountToABMap.get((String)lineItem.get('abID'));
                Decimal lineItemDue = ((Decimal)lineItem.get('TotalDue')).setScale(2);
                String projectCoName = entityMap.get((String)lineItem.get('ProjectCompanyId')).Name;

                Id projectCoId = entityMap.get((Id)lineItem.get('ProjectCompanyId')).Id;
                if (entityMap.containsKey(projectCoId)) {
                    if ( !checkAddressOverrideMap.containsKey(accountId) && entityMap.get(projectCoId).Send_Checks_Address__c != null ){
                        checkAddressOverrideMap.put(accountId, entityMap.get(projectCoId).Send_Checks_Address__c);
                    } else if (checkAddressOverrideMap.containsKey(accountId)){
                        if (checkAddressOverrideMap.get(accountId) != entityMap.get(projectCoId).Send_Checks_Address__c) {
                            checkAddressOverrideMap.put(accountId, defaultAddress);
                        }
                    }
                    if ( !clientLogoOverrideMap.containsKey(accountId) && entityMap.get(projectCoId).Client_Account__r.Client_Brand_Key__c != null){
                        clientLogoOverrideMap.put(accountId, entityMap.get(projectCoId).Client_Account__r.Client_Brand_Key__c);
                    } else if (clientLogoOverrideMap.containsKey(accountId)){
                        if (clientLogoOverrideMap.get(accountId) != entityMap.get(projectCoId).Client_Account__r.Client_Brand_Key__c 
                            && entityMap.get(projectCoId).Client_Account__r.Client_Brand_Key__c != null) {
                            clientLogoOverrideMap.put(accountId, 'BluewaveLogo');
                        }
                    }
                }
                if ( !acctToFieldMap.containsKey(accountId)) {
                    if (lineItemDue < 0.01) {
                        checkLine = 'No Payment Due';
                        acctToFieldMap.put(accountId , checkLine);
                    } else {
                        checkLine = 'Make one check out to ' + projectCoName + ' for $' + lineItemDue;
                        acctToFieldMap.put(accountId , checkLine);
                    }
                } else {
                    if (lineItemDue < 0.01) {
                        checkLine = acctToFieldMap.get(accountId) + ' ';
                        acctToFieldMap.put(accountId , checkLine);
                    } else {
                        checkLine = acctToFieldMap.get(accountId) + ', make one check out to ' + projectCoName + ' for $' + lineItemDue;
                        acctToFieldMap.put(accountId , checkLine); 
                    }
                }
            }
        }

        for (Id acctId : acctToFieldMap.keySet()) {
            if( acctToFieldMap.get(acctId).length() < 255) {
                accountMap.get(acctId).Directions_to_Write_Paper_Check__c = acctToFieldMap.get(acctId);
            } else {
                accountMap.get(acctId).Directions_to_Write_Paper_Check__c = 'ERROR';
            }
            if(checkAddressOverrideMap.containsKey(acctId)) {
                accountMap.get(acctId).Send_Checks_Address__c = checkAddressOverrideMap.get(acctId);
            } else {
                accountMap.get(acctId).Send_Checks_Address__c = defaultAddress;
            }
            if(clientLogoOverrideMap.containsKey(acctId)) {
                accountMap.get(acctId).Client_Brand_Key__c = clientLogoOverrideMap.get(acctId);
            } else {
                accountMap.get(acctId).Client_Brand_Key__c = 'BluewaveLogo';
            }
        }

        update accountMap.Values();
    }
}
