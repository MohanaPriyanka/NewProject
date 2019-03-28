public without sharing class ChargentOrderCreationhandler {

    public static void createChargentOrder(List<Opportunity> oppList, List<Opportunity> oldOppList){
        List<String> accountIds = new list<String> ();
        Map<Id, Opportunity> oldvaluesmap = new Map<Id, Opportunity> ();
        List<Opportunity> oppToUpdateList = new list<Opportunity> ();
        Set<Id> sssIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> leadsWithOrder = new Set<Id>();
        List<ChargentOrders__ChargentOrder__c> ordersToInsert = new List<ChargentOrders__ChargentOrder__c>();

        for(Opportunity oppOld : oldOppList){
            oldvaluesmap.put(oppOld.id, oppOld);
        }

        for(Opportunity opp: oppList){
            String newACH = opp.ACH_Name_on_Account__c;
            String newvalueID = opp.Id;
            String oldACH = oldvaluesmap.get(newvalueID).ACH_Name_on_Account__c;
            if (opp.Product_Line__c != 'Community Solar') {
                continue;
            }
            if (newACH != null && oldACH == null){
                oppToUpdateList.add(opp);
                sssIds.add(opp.Shared_Solar_System__c);
            } else if (opp.CC_Account_Number__c != null && oldvaluesmap.get(newvalueID).CC_Account_Number__c == null){
                oppToUpdateList.add(opp);
                sssIds.add(opp.Shared_Solar_System__c);
            }
            leadIds.add(opp.Lead__c);
        }

        if (leadIds.isEmpty()) {
            return;
        }

        // We now collect payment info in CSAP, so we might already have orders.
        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT Id, Lead__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Lead__c =:leadIds AND Lead__c != null
        ];


        for (ChargentOrders__ChargentOrder__c chOrder : chargentOrders) {
            leadsWithOrder.add(chOrder.Lead__c);
        }

        if (oppToUpdateList.size() > 0) {
            List<Shared_Solar_System__c> sharedSolarSystems = [
                SELECT Id, BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c
                FROM Shared_Solar_System__c
                WHERE Id IN : sssIds
            ];

            Map<Id, Shared_Solar_System__c> sharedSolarSystemMap = new Map<Id, Shared_Solar_System__c>();
            for (Shared_Solar_System__c sss : sharedSolarSystems) {
                sharedSolarSystemMap.put(sss.Id, sss);
            }

            Entity__c defaultEntity = [
                SELECT Id, Gateway__c
                FROM Entity__c
                WHERE Name = 'BWC Holdings, LLC'
            ];

            for(Opportunity opp : oppToUpdateList) {
                // if we already have an order for this account, we don't need to create a new one.
                if (!leadsWithOrder.contains(opp.Lead__c)) {
                    String paymentMethod;
                    if (opp.CC_Account_Number__c != null) {
                        paymentMethod = 'Credit Card';
                    } else {
                        paymentMethod = 'Check';
                    }
                    Shared_Solar_System__c sss = sharedSolarSystemMap.get(opp.Shared_Solar_System__c);
                    Id entityId;
                    Id gatewayId;
                    if (sss.BWC_Project_Entity_Manual__c == null) {
                        entityId = defaultEntity.Id;
                        gatewayId = defaultEntity.Gateway__c;
                    } else {
                        entityId = sss.BWC_Project_Entity_Manual__c;
                        gatewayId = sss.BWC_Project_Entity_Manual__r.Gateway__c;
                    }

                    ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
                        ChargentOrders__Account__c = opp.AccountId,
                        ChargentOrders__Gateway__c = gatewayId,
                        Entity__c = entityId,
                        ChargentOrders__Payment_Method__c = paymentMethod,
                        ChargentOrders__Bank_Name__c = opp.ACH_Bank_Name__c,
                        ChargentOrders__Bank_Routing_Number__c = opp.ACH_Bank_Routing_Number__c ,
                        ChargentOrders__Bank_Account_Type__c = opp.ACH_Account_Type__c,
                        ChargentOrders__Bank_Account_Number__c = opp.ACH_Account_Number__c,
                        ChargentOrders__Bank_Account_Name__c = opp.ACH_Name_on_Account__c,
                        ChargentOrders__Card_Type__c = opp.CC_Card_Type__c,
                        ChargentOrders__Card_Number__c = opp.CC_Account_Number__c,
                        ChargentOrders__Billing_Last_Name__c = opp.CC_CardHolder_Name__c,
                        ChargentOrders__Card_Expiration_Month__c = opp.CC_Expiration_Month__c,
                        ChargentOrders__Card_Expiration_Year__c = opp.CC_Expiration_Year__c );
                    ordersToInsert.add(orderA);
                    Logger.logLater('ChargentOrderCreationhandler', 'createChargentOrder', 'Method used to create chargent orders for opp: ' + opp.Id, 'Info');
                }
                accountids.add(opp.AccountId);
                // we still need to blank out the payment info from the opportunity after we used it for docusign
                opp.ACH_Bank_Name__c = 'removed';
                opp.ACH_Bank_Routing_Number__c = 'removed';
                opp.ACH_Account_Type__c = 'removed';
                opp.ACH_Account_Number__c = 'removed';
                opp.ACH_Name_on_Account__c = 'removed';
                opp.CC_Card_Type__c = 'removed';
                opp.CC_Account_Number__c = 'removed';
                opp.CC_CardHolder_Name__c = 'removed';
                opp.CC_Expiration_Month__c = 'rd';
                opp.CC_Expiration_Year__c = 'rmvd';
            }

            Logger.flushLogs();

            List<Account> accountList = [SELECT Name, Id, Recurring_Billing__c
                                  FROM Account
                                  WHERE Id IN : accountIds];   

            if(accountList.size() > 0) {
                for(Account acc : accountList){
                    acc.Recurring_Billing__c = true;
                }
            }
            update accountList;

            if (!ordersToInsert.isEmpty()) {
                insert ordersToInsert;
            }
        }
    }
}