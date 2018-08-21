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
  public static List<Schedule_Z__c> getScheduleZs (Id productionUpdateId) {
      Energy_Usage_Update__c productionUpdate = [
          SELECT Id, Shared_Solar_System__c
          FROM Energy_Usage_Update__c
          WHERE Id = : productionUpdateId
          LIMIT 1
      ];
      List<Schedule_Z__c> scheduleZList = [
          SELECT Id, Name, Status__c
          FROM Schedule_Z__c
          WHERE Shared_Solar_System__c = : productionUpdate.Shared_Solar_System__c
          AND (Status__c = 'Enacted By Utility' OR Status__c = 'Billing')
      ];
      return scheduleZList;
  }

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
  public static List<UASB__c> getUASes (String parentId, Boolean isProdUpdate, String scheduleZId) {
    List<UASB__c> newBillList = new List<UASB__c> ();
    if (isProdUpdate) {
      Energy_Usage_Update__c production = [SELECT Name, Id, Shared_Solar_System__c, Schedule_Z__c,
                                          YearDate__c, Credits_on_Bill_Period__c,
                                          MonthDate__c, Total_System_NMCs__c, Production__c, 
                                          Generate_Bills__c, Total_System_NMCs_2_of_4__c, 
                                          Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c, 
                                          Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, 
                                          Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                                          Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                                          Billing_Period_End_Date__c,
                                          Net_Metering_Rate_Applied_2_of_4__c,
                                          Net_Metering_Rate_Applied_3_of_4__c,
                                          Net_Metering_Rate_Applied_4_of_4__c
                                          FROM Energy_Usage_Update__c
                                          WHERE Id = : parentId];
        Schedule_Z__c scheduleZ = [
          SELECT Id, Shared_Solar_System__r.Billing_Anchors__c
          FROM Schedule_Z__c
          WHERE Id = : scheduleZId
          AND Shared_Solar_System__c = : production.Shared_Solar_System__c
          LIMIT 1
        ];

      List<Schedule_Z_Subscription__c> szsList = [
          SELECT  Name, Customer_Subscription_KW_DC__c, Utility_Account_Subscription__c, Percent_Share__c, System_Size_kW_DC__c,
              Utility_Account_Subscription__r.Name,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c,
              Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
              Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
              Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c,
              Utility_Account_Subscription__r.Opportunity_Stage__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
              Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c,
              Utility_Account_Subscription__r.Utility_Account_Log__r.Name,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c = : scheduleZ.Id
            AND (Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c != 'RadianGen'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Residential'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Non-Residential' )
            ORDER BY Utility_Account_Subscription__r.Name_on_Account_From_Log__c
      ];
      for (Schedule_Z_Subscription__c szs: szsList) {
        if (szs.Customer_Subscription_kW_DC__c != NULL) {
          UASB__c newBill = getUASB(szs, production, production.Total_System_NMCs__c, production.Production__c, production.Net_Metering_Rate_Applied__c);
          newBillList.add(newBill);
          if (production.Total_System_NMCs_2_of_4__c > 0) {
            UASB__c uasbTwo  = getUASB(szs, production, production.Total_System_NMCs_2_of_4__c, production.Production_kWh_2_of_4__c, production.Net_Metering_Rate_Applied_2_of_4__c);
            uasbTwo.PreGen_Production_Update__c = uasbTwo.PreGen_Production_Update__c + ' (2)';
            newBillList.add(uasbTwo);
            if (production.Total_System_NMCs_3_of_4__c > 0) {
              UASB__c uasbThree = getUASB(szs, production, production.Total_System_NMCs_3_of_4__c, production.Production_kWh_3_of_4__c, production.Net_Metering_Rate_Applied_3_of_4__c);
              uasbThree.PreGen_Production_Update__c = uasbThree.PreGen_Production_Update__c + ' (3)';
              newBillList.add(uasbThree);
              if (production.Total_System_NMCs_4_of_4__c > 0) {
                UASB__c uasbFour = getUASB(szs, production, production.Total_System_NMCs_4_of_4__c, production.Production_kWh_4_of_4__c, production.Net_Metering_Rate_Applied_4_of_4__c);
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
      List<Schedule_Z_Subscription__c> szsListFromAcct = [
          SELECT Name, Customer_Subscription_KW_DC__c, Utility_Account_Subscription__c, Percent_Share__c, System_Size_kW_DC__c,
              Utility_Account_Subscription__r.Name,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c,
              Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
              Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
              Utility_Account_Subscription__r.Opportunity_Stage__c,
              Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,
              Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c,
              Utility_Account_Subscription__r.Utility_Account_Log__r.Name,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Id,
              Utility_Account_Subscription__r.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
              Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,
              Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c
            FROM Schedule_Z_Subscription__c
            WHERE Utility_Account_Subscription__r.Utility_Account_Log__r.Account__r.Id = : parentId
            AND (Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c = 'Bluewave'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Residential'
            OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c = 'Non-Residential' )
            ORDER BY Name
      ];
      for (Schedule_Z_Subscription__c szs : szsListFromAcct) {
        sssList.add(szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c);
      }
      List<Energy_Usage_Update__c> productionList = [SELECT Name, Id, Shared_Solar_System__c, 
                                                    Shared_Solar_System__r.Id,
                                                    Schedule_Z__c,
                                                    YearDate__c, Credits_on_Bill_Period__c,
                                                    MonthDate__c, Total_System_NMCs__c, Production__c, 
                                                    Generate_Bills__c, Total_System_NMCs_2_of_4__c, 
                                                    Total_System_NMCs_3_of_4__c, Production_kWh_2_of_4__c, 
                                                    Production_kWh_3_of_4__c, Total_System_NMCs_4_of_4__c, 
                                                    Production_kWh_4_of_4__c, Net_Metering_Rate_Applied__c,
                                                    Billing_Method__c, Date__c, Billing_Period_Start_Date__c,
                                                    Billing_Period_End_Date__c,
                                                    Net_Metering_Rate_Applied_2_of_4__c,
                                                    Net_Metering_Rate_Applied_3_of_4__c,
                                                    Net_Metering_Rate_Applied_4_of_4__c
                                                    FROM Energy_Usage_Update__c
                                                    WHERE Shared_Solar_System__r.Id IN : sssList
                                                    AND Total_System_NMCs__c != null
                                                    ORDER BY Date__c ];
      for (Schedule_Z_Subscription__c szs : szsListFromAcct) {
        for (Energy_Usage_Update__c productionUpdate : productionList) {
          if (szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Id == productionUpdate.Shared_Solar_System__r.Id
          && !productionUpdate.Generate_Bills__c) {   
            UASB__c newBill = getUASB(szs, productionUpdate, productionUpdate.Total_System_NMCs__c, productionUpdate.Production__c, productionUpdate.Net_Metering_Rate_Applied__c);
            newBill.PreGen_Production_Update__c =  productionUpdate.Name;
            newBillList.add(newBill);
            if (productionUpdate.Total_System_NMCs_2_of_4__c > 0) {
              UASB__c uasbTwo  = getUASB(szs, productionUpdate, productionUpdate.Total_System_NMCs_2_of_4__c, productionUpdate.Production_kWh_2_of_4__c, productionUpdate.Net_Metering_Rate_Applied_2_of_4__c);
              uasbTwo.PreGen_Production_Update__c =  productionUpdate.Name + ' (1)';
              newBillList.add(uasbTwo);
              if (productionUpdate.Total_System_NMCs_3_of_4__c > 0) {
                UASB__c uasbThree = getUASB(szs, productionUpdate, productionUpdate.Total_System_NMCs_3_of_4__c, productionUpdate.Production_kWh_3_of_4__c, productionUpdate.Net_Metering_Rate_Applied_3_of_4__c);
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
                                  Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
                                  Subscription_Production_kWh__c
                                  FROM UASB__c
                                  WHERE System_Bill__r.Property_Account_ID__c = : parentId
                                  ORDER BY Date__c DESC];

      for (UASB__c oldBill : uasbList) {
        UASB__c modifiedBill = new UASB__c (    
          Name = 'Old Bill',
          PreGen_IsPreGen__c = True, 
          PreGen_Discounted_Bill__c = oldBill.Discounted_Bill__c,
          PreGen_NMCs_Allocated__c = oldBill.Net_Metering_Credits_Allocated__c,
            PreGen_Subscription_Production__c = oldBill.Subscription_Production_kWh__c,
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

  public static UASB__c getUASB(Schedule_Z_Subscription__c szs, Energy_Usage_Update__c production, Decimal totalNMCs, Decimal totalProduction, Decimal nmcRate){
    UASB__c billFields = UtilityAccountBillTriggerHandler.setUASBFields(production, szs, nmcRate, totalProduction, totalNMCs);

    Decimal discountedBill = 0;
      if (szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c == 'Use Solar Electric Rate'){
        discountedBill = (szs.Percent_Share__c.setScale(4)/100 * totalProduction)*szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c;
    } else {
        discountedBill = (szs.Percent_Share__c.setScale(4)/100 * totalNMCs)*(1-(szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c/100));
    }
    UASB__c newBill = new UASB__c ( 
        Name = 'PreGenerated Bill',
        PreGen_IsPreGen__c = production.Generate_Bills__c,
        PreGen_Discounted_Bill__c = discountedBill.setScale(2),
        PreGen_Subscription_Production__c = billFields.Subscription_Production_kWh_Static__c,
        PreGen_NMCs_Allocated__c = billFields.Credits_Allocated__c,
        Utility_Account_Subscription__c = szs.Id,
        PreGen_Name_on_Account__c = szs.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
        PreGen_Production_Update__c = (production.MonthDate__c + ' '+ production.YearDate__c),
        PreGen_Schedule_Z_Status__c = szs.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
        PreGen_CreditOnBillPeriod__c = production.Credits_on_Bill_Period__c, 
        PreGen_System_Share__c = billFields.Share_of_System__c,
        PreGen_Utility_Acct__c = szs.Utility_Account_Subscription__r.Name
    );
    if (szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c != null) {
        newBill.PreGen_Additional_Id__c = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c;
    }
    return newBill;
  }

    @AuraEnabled
    public static void saveSchedZToProdUpdate(Id scheduleZId, String prodUpdateId) {
        Energy_Usage_Update__c prodUpdate= [
            SELECT Id, Schedule_Z__c, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
            WHERE Id = : prodUpdateId
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = [
            SELECT Id, Status__c
            FROM Schedule_Z__c
            WHERE Id = : scheduleZId
            AND Shared_Solar_System__c = : prodUpdate.Shared_Solar_System__c
            LIMIT 1
        ];

        if (scheduleZ != null) {
            prodUpdate.Schedule_Z__c = scheduleZ.Id;

            update prodUpdate;

            if (scheduleZ.Status__c != 'Billing') {
                List<Schedule_Z__c> scheduleZs = [
                    SELECT Id, Status__c
                    FROM Schedule_Z__c
                    WHERE Shared_Solar_System__c = : prodUpdate.Shared_Solar_System__c
                    AND Id != : scheduleZ.Id
                    AND Status__c = 'Billing'
                ];
                for (Schedule_Z__c schedZ : scheduleZs) {
                    schedZ.Status__c = 'Replaced with newly Enacted Schedule Z';
                }
                scheduleZ.Status__c = 'Billing';
                scheduleZs.add(scheduleZ);
                update scheduleZs;
            }
        }
    }
}