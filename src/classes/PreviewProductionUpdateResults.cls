/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is used with the ProductionUpdateHelper lightning component (used on the VF page ShowUASes)
 + * When the "Preview Bills" button is hit on a Production Update, this finds all related UASes and 
 + * calculates what their bill will be (NMCs allocated and then with 10% discount)
 + * 
 + * Tested By: TestBillCreationandPayment
 + *************************************************************************************/


public without sharing class PreviewProductionUpdateResults{
  @AuraEnabled
  public static List<Account> getProperties (String parentAcctId, Boolean isParentAcct) {
    if ( isParentAcct ) {
      List<Account> accountList = [ SELECT Id, Name
                                    FROM Account
                                    WHERE Parent_Account_ID__c = : parentAcctId];
      return accountList;
    } else {
      List<Account> accountList = [ SELECT Id, Name
                                    FROM Account
                                    WHERE Id = : parentAcctId];
      return accountList;
    }
  }

  @AuraEnabled
  public static List<UASB__c> getUASes (String parentId, Boolean isProdUpdate) {
    List<UASB__c> newBillList = new List<UASB__c> ();
    if (isProdUpdate) {
      Energy_Usage_Update__c production = [SELECT Name, Id, Shared_Solar_System__c, 
                                          YearDate__c, Credits_on_Bill_Period__c,
                                          MonthDate__c, Total_System_NMCs__c, Production__c, 
                                          Generate_Bills__c, Total_System_NMCs_2_of_4__c, 
                                          Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c, 
                                          Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, 
                                          Production_kWh_4_of_4__c
                                          FROM Energy_Usage_Update__c
                                          WHERE Id = : parentId];
      List<Utility_Account_Subscription__c> uasList = [ SELECT  Name, Customer_Subscription_KW_DC_STATIC__c, 
                                                        Opportunity__r.Shared_Solar_System__c,
                                                        Name_on_Account_From_Log__c, Share_of_System__c, 
                                                        Next_Schedule_Z_Status__c, Opportunity_Stage__c,
                                                        Opportunity__r.Product__r.Solar_Electricity_Rate__c, 
                                                        Opportunity__r.Product__r.NMC_Discount__c,
                                                        Opportunity__r.Product__r.Pricing_Structure__c
                                                        FROM Utility_Account_Subscription__c
                                                        WHERE Utility_Account_Log__c != null
                                                        AND Opportunity__c != null 
                                                        AND Opportunity_Stage__c = 'Complete'
                                                        AND Next_Schedule_Z_Status__c != 'Cancelled'
                                                        AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
                                                        AND Opportunity__r.Shared_Solar_System__c = : production.Shared_Solar_System__c 
                                                        ORDER BY Name_on_Account_From_Log__c];
      for (Utility_Account_Subscription__c uas : uasList) {
        if (uas.Customer_Subscription_KW_DC_STATIC__c != NULL) {
          UASB__c newBill = getUASB(uas, production, production.Total_System_NMCs__c, production.Production__c);
          newBillList.add(newBill);
          if (production.Total_System_NMCs_2_of_4__c > 0) {
            UASB__c uasbTwo  = getUASB(uas, production, production.Total_System_NMCs_2_of_4__c, production.Production_kWh_2_of_4__c);
            uasbTwo.PreGen_Production_Update__c = uasbTwo.PreGen_Production_Update__c + ' (2)';
            newBillList.add(uasbTwo);
            if (production.Total_System_NMCs_3_of_4__c > 0) {
              UASB__c uasbThree = getUASB(uas, production, production.Total_System_NMCs_3_of_4__c, production.Production_kWh_3_of_4__c);
              uasbThree.PreGen_Production_Update__c = uasbThree.PreGen_Production_Update__c + ' (3)';
              newBillList.add(uasbThree);
              if (production.Total_System_NMCs_4_of_4__c > 0) {
                UASB__c uasbFour = getUASB(uas, production, production.Total_System_NMCs_4_of_4__c, production.Production_kWh_4_of_4__c);
                uasbFour.PreGen_Production_Update__c = uasbFour.PreGen_Production_Update__c + ' (4)';
                newBillList.add(uasbFour);
              }
            }
          }
        }
      }
      return newBillList;
    } else {
      List<Id> sssList = new List<Id> ();
      List<Utility_Account_Subscription__c> uasListFromAcct = [ SELECT Name, Customer_Subscription_KW_DC_STATIC__c, 
                                                                Opportunity__r.Shared_Solar_System__r.Id,
                                                                Name_on_Account_From_Log__c, Share_of_System__c, 
                                                                Next_Schedule_Z_Status__c, Opportunity_Stage__c,
                                                                Opportunity__r.Product__r.Solar_Electricity_Rate__c, 
                                                                Opportunity__r.Product__r.NMC_Discount__c,
                                                                Opportunity__r.Product__r.Pricing_Structure__c
                                                                FROM Utility_Account_Subscription__c
                                                                WHERE Utility_Account_Log__c != null
                                                                AND Opportunity__c != null 
                                                                AND Opportunity_Stage__c = 'Complete'
                                                                AND Next_Schedule_Z_Status__c != 'Cancelled'
                                                                AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
                                                                AND Utility_Account_Log__r.Account__r.Id = : parentId
                                                                ORDER BY Name];
      for (Utility_Account_Subscription__c uasOne : uasListFromAcct) {
        sssList.add(uasOne.Opportunity__r.Shared_Solar_System__c); 
      }
      List<Energy_Usage_Update__c> productionList = [SELECT Name, Id, Shared_Solar_System__c, 
                                                    YearDate__c, Generate_Bills__c,
                                                    Credits_on_Bill_Period__c, Shared_Solar_System__r.Id,
                                                    MonthDate__c, Total_System_NMCs__c, Production__c,  
                                                    Total_System_NMCs_2_of_4__c, Total_System_NMCs_3_of_4__c,
                                                    Production_kWh_2_of_4__c, Production_kWh_3_of_4__c
                                                    FROM Energy_Usage_Update__c
                                                    WHERE Shared_Solar_System__r.Id IN : sssList
                                                    AND Total_System_NMCs__c != null
                                                    ORDER BY Date__c ];
      for (Utility_Account_Subscription__c subscription : uasListFromAcct) {
        for (Energy_Usage_Update__c productionUpdate : productionList) {
          if (subscription.Opportunity__r.Shared_Solar_System__r.Id == productionUpdate.Shared_Solar_System__r.Id
          && !productionUpdate.Generate_Bills__c) {   
            UASB__c newBill = getUASB(subscription, productionUpdate, productionUpdate.Total_System_NMCs__c, productionUpdate.Production__c);
            newBill.PreGen_Production_Update__c =  productionUpdate.Name;
            newBillList.add(newBill);
            if (productionUpdate.Total_System_NMCs_2_of_4__c > 0) {
              UASB__c uasbTwo  = getUASB(subscription, productionUpdate, productionUpdate.Total_System_NMCs_2_of_4__c, productionUpdate.Production_kWh_2_of_4__c);
              uasbTwo.PreGen_Production_Update__c =  productionUpdate.Name + ' (1)';
              newBillList.add(uasbTwo);
              if (productionUpdate.Total_System_NMCs_3_of_4__c > 0) {
                UASB__c uasbThree = getUASB(subscription, productionUpdate, productionUpdate.Total_System_NMCs_3_of_4__c, productionUpdate.Production_kWh_3_of_4__c);
                uasbThree.PreGen_Production_Update__c =  productionUpdate.Name + ' (2)';
                newBillList.add(uasbThree);
              }
            }   
          }
        }
      }
      List<UASB__c> oldBillList = new List<UASB__c> ();
      List<UASB__C> uasbList = [  SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
                                  Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                                  Utility_Account_Subscription__r.Share_of_System__c, 
                                  Production_Update__r.Name, Credits_on_Bill_Period__c,
                                  Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                                  Net_Metering_Credits_Allocated__c, Discounted_Bill__c
                                  FROM UASB__c
                                  WHERE System_Bill__r.Property_Account_ID__c = : parentId
                                  ORDER BY Date__c DESC];

      for (UASB__c oldBill : uasbList) {
        UASB__c modifiedBill = new UASB__c (    
          Name = 'Old Bill',
          PreGen_IsPreGen__c = True, 
          PreGen_Discounted_Bill__c = oldBill.Discounted_Bill__c,
          PreGen_NMCs_Allocated__c = oldBill.Net_Metering_Credits_Allocated__c,
          PreGen_Name_on_Account__c = oldBill.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
          PreGen_Production_Update__c = oldBill.Production_Update__r.Name ,
          Utility_Account_Subscription__c = oldBill.Id,
          PreGen_CreditOnBillPeriod__c = oldBill.Credits_on_Bill_Period__c,
          PreGen_Schedule_Z_Status__c = oldBill.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
          PreGen_System_Share__c =  oldBill.Utility_Account_Subscription__r.Share_of_System__c.setScale(4), 
          PreGen_Utility_Acct__c = oldBill.Utility_Account_Subscription__r.Name
        );
        newBillList.add(modifiedBill);
      }
      return newBillList;
    }
  }

  @AuraEnabled
  public static List<ChargentOrders__Transaction__c> getTransactions (List<Account> accountLookup) {
    List<String> idList = new List<String>();
    String stringId;
    for (Account acc : accountLookup){
      stringId = acc.Id;
      idList.add(stringId.substring(0,15));
    }
    List<ChargentOrders__Transaction__c> transactionList = [SELECT Name, Id, ChargentOrders__Gateway_Date__c, 
                                                            ChargentOrders__Amount__c,
                                                            ChargentOrders__Response_Status__c, 
                                                            ChargentOrders__Gateway__r.Name, 
                                                            ChargentOrders__Order__r.ChargentOrders__Payment_Status__c
                                                            FROM ChargentOrders__Transaction__c
                                                            WHERE Property_Account_ID__c IN : idList 
                                                            ORDER BY  ChargentOrders__Gateway_Date__c DESC];
    return transactionList;
  }

  public static UASB__c getUASB(Utility_Account_Subscription__c uas, Energy_Usage_Update__c production, Decimal totalNMCs, Decimal totalProduction){
    Decimal discountedBill = 0;
    if (uas.Opportunity__r.Product__r.Pricing_Structure__c == 'Use Solar Electric Rate'){
        discountedBill = (uas.Share_of_System__c.setScale(4)/100 * totalProduction)*uas.Opportunity__r.Product__r.Solar_Electricity_Rate__c;
    } else {
        discountedBill = (uas.Share_of_System__c.setScale(4)/100 * totalNMCs)*(1-(uas.Opportunity__r.Product__r.NMC_Discount__c/100));
    }
    UASB__c newBill = new UASB__c ( 
        Name = 'PreGenerated Bill',
        PreGen_IsPreGen__c = production.Generate_Bills__c, 
        PreGen_Discounted_Bill__c = discountedBill.setScale(2),
        PreGen_NMCs_Allocated__c = (uas.Share_of_System__c.setScale(4)/100 * totalNMCs).setScale(2),
        Utility_Account_Subscription__c = uas.Id,
        PreGen_Name_on_Account__c = uas.Name_on_Account_From_Log__c,
        PreGen_Production_Update__c = production.MonthDate__c + ' '+ production.YearDate__c,
        PreGen_Schedule_Z_Status__c = uas.Next_Schedule_Z_Status__c,
        PreGen_CreditOnBillPeriod__c = production.Credits_on_Bill_Period__c, 
        PreGen_System_Share__c = uas.Share_of_System__c.setScale(4),
        PreGen_Utility_Acct__c = uas.Name
    );
    return newBill;
  }
}