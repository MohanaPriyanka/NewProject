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

        List<ChargentOrders__ChargentOrder__c> ordersList = [
            SELECT Id, ChargentOrders__Account__c,
                ChargentOrders__Billing_First_Name__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c,
                ChargentOrders__Account__r.Total_Billed__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Account__c IN :firstABMap.keySet() ];

        if(!ordersList.isEmpty()) {
            for(ChargentOrders__ChargentOrder__c firstOrder : ordersList){
                String billID = firstABMap.get(firstOrder.ChargentOrders__Account__c);

                /*  We want this to run when the first bill has been inserted, but not yet published.
                    Total_Billed__c will be > 0 (it includes unpublished bills)
                    Max_Account_Bill_Number__c will 1 once the bill is published, but no sooner
                    This would not work if the first bill was for $0, which we do not expect to happen
                */
                if (firstOrder.ChargentOrders__Account__r.Max_Account_Bill_Number__c == null
                    && firstOrder.ChargentOrders__Account__r.Total_Billed__c > 0) {
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
                    if (!entities.contains(firstChargentOrder.Entity__c) && systemBillByAB.containsKey(firstBill.Id)) {
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

    public static void setClientBrandKey (List<Account_Bill__c> accountBillList) {
        // The Client Brand Key on the property is used for bill template branding
        // on the parent account, it is used for portal branding

        Map<Id, Account> accountMap = new Map<Id, Account>();

        List<System_Bill__c> sbList = [
            SELECT Id, Name, Account_Bill__r.Parent_Account__r.Id,
                Account_Bill__r.Parent_Account__r.Parent_Account__c,
                Account_Bill__r.Parent_Account__r.Parent_Account__r.Id,
                Shared_Solar_System__r.Client_Brand_Key__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c
            FROM System_Bill__c
            WHERE Account_Bill__c IN : accountBillList
            AND Account_Bill__r.Parent_Account__r.Parent_Account__c != null];

        for (System_Bill__c systemBill : sbList){
            String brandKey;
            String sssKey = systemBill.Shared_Solar_System__r.Client_Brand_Key__c;
            String entityKey = systembill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Client_Brand_Key__c;
            Account propAccount = new Account(Id = systembill.Account_Bill__r.Parent_Account__r.Id);
            propAccount.Parent_Account__c = systembill.Account_Bill__r.Parent_Account__r.Parent_Account__r.Id;

            if (sssKey != null){
                brandKey = sssKey;
            } else if (entityKey != null) {
                brandKey = entityKey;
            } else {
                brandKey = 'BluewaveLogo';
            }

            // If SBs under the same Property have conflicting branding, set Property to BlueWave branding:
            accountMap = checkBrandConflicts(accountMap, propAccount, brandKey);
        }

        if (accountMap.values().size() > 0){
            for (Account propAccount : accountMap.values()) {
                String brandKeyProperty = propAccount.Client_Brand_Key__c;
                Account parentAccount = new Account (Id = propAccount.Parent_Account__c);

                // If Properties under the same Parent have conflicting branding, set Parent to BlueWave branding:
                accountMap = checkBrandConflicts(accountMap, parentAccount, brandKeyProperty);
            }
            checkForChangedValues(accountMap);
        }
    }

    public static void checkForChangedValues(Map<Id, Account> accountMap){
        List<Account> accountsWithChangedValues = new List<Account>();
        List<Account> accountsBeforeUpdate = [
            SELECT Id, Client_Brand_Key__c
            FROM Account
            WHERE Id IN : accountMap.keySet()
        ];
        for (Account oldValue : accountsBeforeUpdate){
            if(oldValue.Client_Brand_Key__c != accountMap.get(oldValue.Id).Client_Brand_Key__c){
                accountsWithChangedValues.add(accountMap.get(oldValue.Id));
            }
        }

        if (accountsWithChangedValues.size() > 0){
            update accountsWithChangedValues;
        }
    }

    public static Map<Id, Account> checkBrandConflicts (Map<Id, Account> accountMap, Account account, String brandKey) {
        account.Client_Brand_Key__c = brandKey;
        if (accountMap.containsKey(account.Id) && brandKey != accountMap.get(account.Id).Client_Brand_Key__c){
            account.Client_Brand_Key__c = 'BluewaveLogo';
        }
        accountMap.put(account.Id, account);
        return accountMap;
    }
}