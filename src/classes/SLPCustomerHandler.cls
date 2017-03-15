public without sharing class SLPCustomerHandler {    

  @AuraEnabled 
  public static Loan__c getCustomerLoan (String loanId) {
    System.debug('the loanId is ' + loanId);
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '' ) {
      partnerId = SLPUserHelper.getBWCCId();
    }

    List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, 
                  Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode  , Partner__r.Name, DOER_Solar_Loann__c
                  FROM Loan__c 
                  WHERE Id = : loanId];
    System.debug('loanList is ' + loanList);
    return loanList.get(0);         
  }

  @AuraEnabled 
  public static List<Loan__c> getAllCustomers (String searchValue) {
    System.debug('Begin the getAllCustomers method');
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '') {
      partnerId = SLPUserHelper.getBWCCId();
    }

    if(searchValue == null || searchValue == ''){
      List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, Acquisition_Status__c,
                    Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode, Partner__r.Name, 
                    (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = 'Pending'  LIMIT 1)  
                    FROM Loan__c 
                    WHERE Partner__r.Id = : partnerId
                    ORDER BY createdDate DESC];      
    return loanList;      
    }else {
      List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, Acquisition_Status__c,
                    Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode, Partner__r.Name,
                    (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = 'Pending' LIMIT 1)  
                    FROM Loan__c 
                    WHERE Name LIKE : '%'+searchValue+'%'
                    AND Partner__r.Id = : partnerId
                    ORDER BY createdDate DESC];
    return loanList;                               
    }
  }

  @AuraEnabled 
  public static Residential_Equipment__c getCustomerInformation (String loanId) {
    System.debug('the loanId is ' + loanId);
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '') {
      partnerId = SLPUserHelper.getBWCCId();
    }

    List<Residential_Equipment__c> equipmentList = [SELECT Id, Name, Loan__r.Name, Loan__r.Lead__r.Update_Dummy__c, 
                                                      Loan__r.Lead__r.Annual_Income_Currency__c, Loan__r.Lead__r.Id, 
                                                      Generator_Nameplate_Capacity__c,Number_of_Inverters__c, Number_of_Modules__c, 
                                                      Loan__r.Product__r.Name,Loan__r.System_Costt__c,  Loan__r.Commencement_Datee__c, 
                                                      Loan__r.Maturity_Datee__c,Interconnected__c, Mechanically_Installed__c,  
                                                      Mechanical_Installation_Date__c, Loan__r.Principall__c, Loan__r.Principal__c,
                                                      Module_Manufacturer__c, Module_Model_Number__c, Inverter_Manufacturer__c, Loan__r.Product__r.Program__c, 
                                                      Inverter_Model_Number__c, Loan__r.Id, Loan__r.DOER_Solar_Loann__c, Interconnection_date__c 
                                                    FROM Residential_Equipment__c 
                                                    WHERE Loan__c = : loanId 
                                                    LIMIT 1];
    if(equipmentList.size() > 0 ) {
      return equipmentList.get(0);         
      }else {
        return null;
      }
  }


  @AuraEnabled 
  public static String getProgressBarData(String loanId) {
    System.debug('the loanId is ' + loanId);
    String returnTaskName;
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '') {
      partnerId = SLPUserHelper.getBWCCId();
    }


      List<Partner_Task__c> completedTaskList = [SELECT Id, Name, Status__c, Completion_Date__c, Task_Sequence__c, Loan__r.Name
                            FROM Partner_Task__c
                            WHERE Loan__c = : loanId
                            AND Status__c = 'Pending'
                                            AND Parent__c = true
                                            AND Sub_Task_Type__c = null
                                            AND Parent_Task__c = null                       
                            ORDER BY Completion_Date__c, Task_Sequence__c DESC
                            LIMIT 1];
    if(completedTaskList.size() > 0){
      for (Partner_Task__c task : completedTaskList){
        returnTaskName = task.Name;
      }       
    }                         
    //System.debug('the completedTaskList is ' + completedTaskList.get(0).Name);
    return returnTaskName;          
  }

   @AuraEnabled
    public static List<Partner_Task__c> getLoanCustomerTasks(String loanId) {
        String partnerId = SLPUserHelper.getPartnerId(); 
        Partner__c partnerRecord;

        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }


        List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Status__c, Loan__r.Id,
                                        Loan__c, Task_Sequence__c, Task_Type__c
                                        FROM Partner_Task__c 
                                        WHERE Loan__c = : loanId 
                                        AND Parent__c = true
                                        AND Sub_Task_Type__c = null
                                        AND Parent_Task__c = null                                       
                                        ORDER BY Task_Sequence__c ASC];                               
        return taskList;
    }

   @AuraEnabled
    public static List<Partner_Task__c> getLoanParentSubTasks(String taskId) {
      String partnerId = SLPUserHelper.getPartnerId(); 
      Partner__c partnerRecord;

      if (partnerId == null || partnerId == '') {
        partnerId = SLPUserHelper.getBWCCId();
      }


      List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Parent_Task__r.Name, 
                                        Status__c, Loan__r.Id, Loan__c, Task_Type__c, Task_Sequence__c
                                      FROM Partner_Task__c 
                                      WHERE Parent_Task__c = : taskId                                       
                                      ORDER BY Task_Sequence__c ASC];                               
      
      System.debug('task list is ' + taskList);
      return taskList;
    }  

   @AuraEnabled
    public static List<Disbursal__c> getCompleteLoanDisbursals(String loanId, String searchValue) {
      //change SOQL to one query with parameters in in using database.query and string value concatenated together. see Joey Chan strategy. 
      System.debug('begin the getCompleteLoanDisbursals method');
      String partnerId = SLPUserHelper.getPartnerId(); 
      Partner__c partnerRecord;

      if (partnerId == null || partnerId == '') {
        partnerId = SLPUserHelper.getBWCCId();
      }


      if(loanId != null && searchValue == null) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                    Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c 
                                  WHERE Loan__c = : loanId
                                  AND Status__c = 'Complete' 
                                  ORDER BY Date_of_Disbursal__c, createdDate];                               
        return disbursalList;
      }else if(loanId == null && (searchValue == null || searchValue == '')) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                      Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                    FROM Disbursal__c 
                                    WHERE Partner__r.Id = : partnerId
                                    AND Status__c = 'Complete'                                       
                                    ORDER BY Date_of_Disbursal__c, createdDate ASC];                               
        return disbursalList;          
      }else if(loanId == null && searchValue != null) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                    Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c 
                                  WHERE Partner__r.Id = : partnerId 
                                  AND Loan__r.Name LIKE : '%'+searchValue+'%'
                                  AND Status__c = 'Complete' 
                                  ORDER BY Date_of_Disbursal__c, createdDate ASC];                               
        return disbursalList;          
      }else {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                      Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                    FROM Disbursal__c 
                                    WHERE Partner__r.Id = : partnerId
                                    AND Status__c = 'Complete'                                       
                                    ORDER BY Date_of_Disbursal__c, createdDate ASC];                               
        return disbursalList;          
      }
    }

   @AuraEnabled
    public static List<Disbursal__c> getIncompleteLoanDisbursals(String loanId, String searchValue) {
     //change SOQL to one query with parameters in in using database.query and string value concatenated together. see Joey Chan strategy. 
      System.debug('begin the getIncompleteLoanDisbursals method');
      String partnerId = SLPUserHelper.getPartnerId(); 
      Partner__c partnerRecord;

      if (partnerId == null || partnerId == '') {
        partnerId = SLPUserHelper.getBWCCId();
      }

      if(loanId != null && searchValue == null) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                    Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c 
                                  WHERE Loan__c = : loanId
                                  AND Status__c = 'Not yet disbursed' 
                                  ORDER BY createdDate];                               
        return disbursalList;
      }else if(loanId == null && (searchValue == null || searchValue == '')) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                      Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                    FROM Disbursal__c 
                                    WHERE Partner__r.Id = : partnerId
                                    AND Status__c = 'Not yet disbursed'                                       
                                    ORDER BY createdDate ASC];                               
        return disbursalList;          
      }else if(loanId == null && searchValue != null) {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                    Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c 
                                  WHERE Partner__r.Id = : partnerId 
                                  AND Loan__r.Name LIKE : '%'+searchValue+'%'
                                  AND Status__c = 'Not yet disbursed' 
                                  ORDER BY createdDate ASC];                               
        return disbursalList;          
      }else {
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, 
                                      Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                    FROM Disbursal__c 
                                    WHERE Partner__r.Id = : partnerId
                                    AND Status__c = 'Not yet disbursed'                                       
                                    ORDER BY createdDate ASC];                               
        return disbursalList;          
      }
    }

   @AuraEnabled
    public static void updateDisbursals(String disbursalId, Boolean disbursalValue) {
      List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c  FROM Disbursal__c  WHERE Id = : disbursalId LIMIT 1];

      disbursalList.get(0).Partner_Confirmation__c = disbursalValue;
      update disbursalList;
    }    


   @AuraEnabled
    public static Map<String, List<Partner_Task__c>> getTaskMap (String loanId) {
        Map<String, List<Partner_Task__c>> taskMap = new Map<String, List<Partner_Task__c>>();
        String partnerId = SLPUserHelper.getPartnerId(); 
        Partner__c partnerRecord;

        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }

        for (Partner_Task__c partnerTask : [SELECT Id, Name, Completion_Date__c, Parent_Task__r.Name, 
                                                 Status__c, Loan__r.Id, Loan__c, Task_Sequence__c,
                                                (SELECT Id, Name, Status__c, Completion_Date__c FROM
                                                subTasks__r)
                                            FROM Partner_Task__c 
                                            WHERE Parent__c = true
                                            AND Sub_Task_Type__c = null
                                            AND Parent_Task__c = null 
                                            AND Loan__c = : loanId                                                                            
                                            ORDER BY Task_Sequence__c ASC]){
          taskMap.put(partnerTask.Name, partnerTask.subTasks__r);
        }                              
        
        System.debug('taskMap is ' + taskMap);
        return taskMap;
    } 

   @AuraEnabled
    public static void saveCustomerInformation(Residential_Equipment__c equipment, String equipmentId, String loanId, Loan__c loan) {
        System.debug('begin the saveEquipmentInformation method');
        String partnerId = SLPUserHelper.getPartnerId(); 
        Partner__c partnerRecord;
        String nameVar;

        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }

        //update the equipment information
        Residential_Equipment__c equipmentRecord = [SELECT Id, Lead__r.Id, Name, Generator_Nameplate_Capacity__c, Type_of_Module__c, Number_of_Modules__c,
                                                           Type_of_Inverter__c, Number_of_Inverters__c, Mechanical_Installation_Date__c, Interconnection_date__c,
                                                           Mechanically_Installed__c, Interconnected__c,  Module_Manufacturer__c, Inverter_Manufacturer__c, Inverter_Model_Number__c
                                                    FROM Residential_Equipment__c
                                                    WHERE Id = : equipmentId];
        if(String.isNotBlank(equipment.Module_Manufacturer__c) 
          && String.isNotBlank(equipment.Inverter_Manufacturer__c)){
            nameVar = equipmentRecord.Name + ' ' + equipment.Module_Manufacturer__c + '/' + equipment.Inverter_Manufacturer__c;
            if (nameVar.length() >= 80) {
              nameVar = nameVar.subString(0,80);
            }
            equipmentRecord.Name = nameVar; 
            nameVar = null;
        }                                   
        if(equipment.Generator_NamePlate_Capacity__c != null){
          equipmentRecord.Generator_Nameplate_Capacity__c = equipment.Generator_NamePlate_Capacity__c;
        }
        if(String.isNotBlank(equipment.Module_Model_Number__c)){
          equipmentRecord.Module_Model_Number__c = equipment.Module_Model_Number__c;
        }  
        if(String.isNotBlank(equipment.Module_Manufacturer__c)){
          equipmentRecord.Module_Manufacturer__c = equipment.Module_Manufacturer__c;
        }    
        if(String.isNotBlank(equipment.Inverter_Manufacturer__c)){
          equipmentRecord.Inverter_Manufacturer__c = equipment.Inverter_Manufacturer__c;
        }  
        if(String.isNotBlank(equipment.Inverter_Model_Number__c)){
          equipmentRecord.Inverter_Model_Number__c = equipment.Inverter_Model_Number__c;
        }                                  
        if(equipment.Number_of_Modules__c != null){
          equipmentRecord.Number_of_Modules__c = equipment.Number_of_Modules__c;
        }
        if(String.isNotBlank(equipment.Type_of_Inverter__c)){
          equipmentRecord.Type_of_Inverter__c = equipment.Type_of_Inverter__c;
        }    
        if(equipment.Number_of_Inverters__c != null){
          equipmentRecord.Number_of_Inverters__c = equipment.Number_of_Inverters__c;
        }          
        if(equipment.Mechanical_Installation_Date__c != null){
          equipmentRecord.Mechanical_Installation_Date__c = equipment.Mechanical_Installation_Date__c;
        }     
        if(equipment.Interconnection_Date__c != null){
          equipmentRecord.Interconnection_Date__c = equipment.Interconnection_Date__c;
        }
        if(equipment.Mechanically_Installed__c != equipmentRecord.Mechanically_Installed__c){
          equipmentRecord.Mechanically_Installed__c = equipment.Mechanically_Installed__c;
        }
        if(equipment.Interconnected__c != equipmentRecord.Interconnected__c){
          equipmentRecord.Interconnected__c = equipment.Interconnected__c;
        }                                                                                                    

        update equipmentRecord;

        //update the loan information  
        Loan__c loanRecord = [SELECT Id, Name, Commencement_Datee__c, System_Costt__c  
                              FROM Loan__c
                              WHERE Id = : loanId];
        if(loan.Commencement_Datee__c  != null){
          loanRecord.Commencement_Datee__c   = loan.Commencement_Datee__c;      
        }
        if(loan.System_Costt__c  != null){
          loanRecord.System_Costt__c   = loan.System_Costt__c;      
        }        
        update loanRecord;
        Lead leadRecord = [SELECT Id, Update_Dummy__c, System_Cost__c FROM Lead WHERE Id = : equipmentRecord.Lead__r.Id];
        if(leadRecord.Update_Dummy__c == true){
          leadRecord.Update_Dummy__c = false;
        }else{
          leadRecord.Update_Dummy__c = true;
        }
        leadRecord.System_Cost__c = loan.System_Costt__c;
        update leadRecord;
    }

  //@AuraEnabled 
  //public static String getFormAssemblyIds (String productProgram, String formType) {
  //  System.debug('Begin the getFormAssemblyIds method');
  //  List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
  //  Map<String, String> formIdsMap = new Map<String, String>();
  //  String formMapKey = productProgram + ' ' + formType;
  //  if (systemProperties.size() > 0) {
  //    if (systemProperties[0].SLP_Continue_Application_Standard__c != null) {
  //        formIdsMap.put('BlueWave Solar Loan Income Documentation', systemProperties[0].SLP_Continue_Application_Standard__c);
  //    }   
  //    if (systemProperties[0].SLP_Continue_Application_MSLP__c != null) {
  //        formIdsMap.put('MSLP Income Documentation', systemProperties[0].SLP_Income_Documentation_MSLP__c  );
  //    }           
  //  }  
  //  System.debug('The FormIds are ' + formIdsMap);
  //  System.debug('The result is ' + formIdsMap.get(formMapKey));
  //  return formIdsMap.get(formMapKey);    
  //}    
}