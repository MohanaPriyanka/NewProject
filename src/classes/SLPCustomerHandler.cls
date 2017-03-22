
/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: The SLPCustomerHandler class services the SLP Customer tab and customer window. For the most part, it returns data for disply; 
 * however it also allows the user to update system information and loan information. It controls the customer window progress bar,               
 * returns disubrsal information, updates disbursals as confirmed and returns equipment information.
 * 
 Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPCustomerHandler {    

  public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
  static {
    profile = SLPUserHelper.getPartnerProfile();
  }

 //The getAllCustomers method returns a list of loans to the SLPCustomer lightning component to show up in the customers tab
  @AuraEnabled 
  public static List<Loan__c> getAllCustomers (String searchValue) {
    if(searchValue == null || searchValue == ''){
      List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, Acquisition_Status__c,
                    Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode, Partner__r.Name, Sales_Agent__r.Id,
                    (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = 'Pending'  LIMIT 1)  
                    FROM Loan__c 
                    WHERE Partner__r.Id = : profile.partnerId
                    AND Sales_Agent__r.Id = : profile.salesRepId
                    ORDER BY createdDate DESC];      
    return loanList;      
    }else {
      List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, Acquisition_Status__c,
                    Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode, Partner__r.Name, Sales_Agent__r.Id,
                    (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = 'Pending' LIMIT 1)  
                    FROM Loan__c 
                    WHERE Name LIKE : '%'+searchValue+'%'
                    AND Partner__r.Id = : profile.partnerId
                    AND Sales_Agent__r.Id = : profile.salesRepId
                    ORDER BY createdDate DESC];
    return loanList;                               
    }
  }

  //The getCustomerInformation method returns an equipment list to show system information, and other customer information on the customer window
  @AuraEnabled 
  public static Residential_Equipment__c getCustomerInformation (String loanId) {
    List<Residential_Equipment__c> equipmentList = [SELECT Id, Name, Loan__r.Name, Loan__r.Lead__r.Update_Dummy__c, 
                                                      Loan__r.Lead__r.Annual_Income_Currency__c, Loan__r.Lead__r.Id, 
                                                      Generator_Nameplate_Capacity__c,Number_of_Inverters__c, Number_of_Modules__c, 
                                                      Loan__r.Product__r.Name,Loan__r.System_Costt__c,  Loan__r.Commencement_Datee__c, 
                                                      Loan__r.Maturity_Datee__c,Interconnected__c, Mechanically_Installed__c,  
                                                      Mechanical_Installation_Date__c, Loan__r.Principall__c, Loan__r.Principal__c,
                                                      Module_Manufacturer__c, Module_Model_Number__c, Inverter_Manufacturer__c, Loan__r.Product__r.Program__c, 
                                                      Inverter_Model_Number__c, Loan__r.Id, Loan__r.DOER_Solar_Loann__c, Interconnection_date__c,
                                                      Loan__r.Total_Funds_Disbursed__c, Loan__r.Sales_Agent__r.Name, Loan__r.Product__r.ProductCode, Loan__r.Partner__r.Name
                                                    FROM Residential_Equipment__c
                                                    WHERE Loan__c = : loanId
                                                    AND Loan__r.Partner__r.Id = : profile.partnerId
                                                    AND Loan__r.Sales_Agent__r.Id = : profile.salesRepId 
                                                    LIMIT 1];
    if(!equipmentList.isEmpty()) {
      return equipmentList.get(0);         
    }else {
        return null;
    }
  }

  //the getProgressBarData returns the pending task for the SLP's customer window progress bar. It could be replaced with the getLoanCustomerTasks
  //method if the right logic is applied to the SLPCustomerController component
  @AuraEnabled 
  public static String getProgressBarData(String loanId) {
    String returnTaskName;
    List<Partner_Task__c> pendingTasks = [SELECT Id, Name, Status__c, Completion_Date__c, Task_Sequence__c, Loan__r.Name
                                               FROM Partner_Task__c
                                               WHERE Loan__c = : loanId
                                               AND Status__c = 'Pending'
                                               AND Parent__c = true
                                               AND Sub_Task_Type__c = null
                                               AND Parent_Task__c = null           
                                               AND Sales_Representative__r.Partner__r.Id = : profile.partnerId
                                               AND Sales_Representative__r.Id = : profile.salesRepId            
                                               ORDER BY Completion_Date__c, Task_Sequence__c DESC
                                               LIMIT 1];
    if(!pendingTasks.isEmpty()){
      for (Partner_Task__c task : pendingTasks){
        returnTaskName = task.Name;
      }       
    }                         
    return returnTaskName;          
  }
  
  //the getLoanCustomerTasks returns the list of tasks for the customer window 
  @AuraEnabled
  public static List<Partner_Task__c> getLoanCustomerTasks(String loanId) {
      List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Status__c, Loan__r.Id,
                                      Loan__c, Task_Sequence__c, Task_Type__c
                                      FROM Partner_Task__c 
                                      WHERE Loan__c = : loanId 
                                      AND Parent__c = true
                                      AND Sub_Task_Type__c = null
                                      AND Parent_Task__c = null   
                                      AND Sales_Representative__r.Partner__r.Id = : profile.partnerId
                                      AND Sales_Representative__r.Id = : profile.salesRepId                                                                           
                                      ORDER BY Task_Sequence__c ASC];                               
      return taskList;
  }

  //the getLoanParentSubTasks returns the list of subTasks for the selected grand-parent task on the customer window
  @AuraEnabled
  public static List<Partner_Task__c> getLoanParentSubTasks(String taskId) {
    List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Parent_Task__r.Name, 
                                      Status__c, Loan__r.Id, Loan__c, Task_Type__c, Task_Sequence__c
                                      FROM Partner_Task__c 
                                      WHERE Parent_Task__c = : taskId
                                      AND Sales_Representative__r.Partner__r.Id = : profile.partnerId
                                      AND Sales_Representative__r.Id = : profile.salesRepId                                                                              
                                      ORDER BY Task_Sequence__c ASC];                                    
    return taskList;
  }  
  
  //the getCompleteDisbursals method returns the completed disbursals for the disbursals tab and for the customer window, depending on the 
  // parameters provided by the lightning component
  @AuraEnabled
  public static List<Disbursal__c> getCompleteLoanDisbursals(String loanId, String searchValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, Disbursal_Percentage__c, Status__c, Amount__c, Type__c, Loan__r.Sales_Agent__r.Id ' ;
    disbursalQuery += ' FROM Disbursal__c' ;
    disbursalQuery += ' WHERE Status__c = \'' + 'Complete' + '\' ' ;

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search      
      disbursalQuery += ' AND Loan__c = \'' + loanId +  '\' ' ;
      disbursalQuery += ' ORDER BY Date_of_Disbursal__c, createdDate ASC' ;   
    } else if (loanId == null && (searchValue == null || searchValue == '')) {
      //query for the records on the all disbursal page with no search
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;
      disbursalQuery += ' ORDER BY Date_of_Disbursal__c, createdDate ASC' ;         
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;  
      disbursalQuery += ' AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;
      disbursalQuery += ' ORDER BY Date_of_Disbursal__c, createdDate ASC' ;  
    } else {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;  
      disbursalQuery += ' ORDER BY Date_of_Disbursal__c, createdDate ASC' ;  
    }
    System.debug('disbursalQuery Query ' + disbursalQuery);
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursalList.add(disbursal);
    }
    return disbursalList;
  }

  //the getIncompleteDisbursals method returns the incomplete disbursals for the disbursals tab and for the customer window, depending on the 
  // parameters provided by the lightning component. This could be blended with the above method by adding an incomplete/compelete parameter 
  @AuraEnabled
  public static List<Disbursal__c> getIncompleteLoanDisbursals(String loanId, String searchValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, Disbursal_Percentage__c, Status__c, Amount__c, Type__c, Loan__r.Sales_Agent__r.Id ' ;
    disbursalQuery += ' FROM Disbursal__c' ;
    disbursalQuery += ' WHERE Status__c = \'' + 'Not yet disbursed' + '\' ' ;

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search      
      disbursalQuery += ' AND Loan__c = \'' + loanId +  '\' ' ;
      disbursalQuery += ' ORDER BY createdDate ASC' ;   
    } else if (loanId == null && (searchValue == null || searchValue == '')) {
      //query for the records on the all disbursal page with no search
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;
      disbursalQuery += ' ORDER BY createdDate ASC' ;         
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;  
      disbursalQuery += ' AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;
      disbursalQuery += ' ORDER BY createdDate ASC' ;  
    } else {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += ' AND Sales_Representative__r.Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                    
      disbursalQuery += ' AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;  
      disbursalQuery += ' ORDER BY createdDate ASC' ;  
    }
    System.debug('disbursalQuery Query ' + disbursalQuery);
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursalList.add(disbursal);
    }
    return disbursalList;
  }  

  //the updateDisbursals method updates the confirmation field on the disbursal on partner action within the SLP
  @AuraEnabled
  public static void updateDisbursals(String disbursalId, Boolean disbursalValue) {
    List<Disbursal__c> disbursalList = [SELECT Id, Name, Partner_Confirmation__c  
                                        FROM Disbursal__c  
                                        WHERE Id = : disbursalId 
                                        AND Sales_Representative__r.Partner__r.Id = : profile.partnerId
                                        AND Sales_Representative__r.Id = : profile.salesRepId                                         
                                        LIMIT 1];
    disbursalList.get(0).Partner_Confirmation__c = disbursalValue;
    update disbursalList;
  }    

  //the saveCustomerInformation method allows the user to enter in the customer's system information/commencement date to the SLP and save it to SF
  @AuraEnabled
  public static void saveCustomerInformation(Residential_Equipment__c equipment, String equipmentId, String loanId, Loan__c loan) {        
    String nameVar;

    Residential_Equipment__c equipmentRecord = [SELECT Id, Lead__r.Id, Loan__r.Name, Name, Generator_Nameplate_Capacity__c, 
                                                Type_of_Module__c, Number_of_Modules__c, Type_of_Inverter__c, 
                                                Number_of_Inverters__c, Mechanical_Installation_Date__c, Interconnection_date__c,
                                                Mechanically_Installed__c, Interconnected__c,  Module_Manufacturer__c, 
                                                Inverter_Manufacturer__c, Inverter_Model_Number__c, Loan__r.Sales_Agent__r.Partner__r.Id, 
                                                Loan__r.Sales_Agent__r.Id
                                                FROM Residential_Equipment__c
                                                WHERE Id = : equipmentId
                                                AND Loan__r.Sales_Agent__r.Partner__r.Id = : profile.partnerId
                                                AND Loan__r.Sales_Agent__r.Id = : profile.salesRepId];
    if(String.isNotBlank(equipment.Module_Manufacturer__c) 
      && String.isNotBlank(equipment.Inverter_Manufacturer__c)){
        nameVar = equipmentRecord.Loan__r.Name + ' ' + equipment.Module_Manufacturer__c + '/' + equipment.Inverter_Manufacturer__c;
        if (nameVar.length() >= 80) {
          nameVar = nameVar.subString(0,80);
        }
        equipmentRecord.Name = nameVar; 
        nameVar = null;
    }         
    //the null value approach below is because if the user clicks save on the SLP and a field is blank, it would overwrite
    //the SF field if it wasn't filtered out by the below if statements                          
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
                          WHERE Id = : loanId
                          AND Sales_Agent__r.Partner__r.Id = : profile.partnerId
                          AND Sales_Agent__r.Id = : profile.salesRepId];                          
    if(loan.Commencement_Datee__c  != null){
      loanRecord.Commencement_Datee__c   = loan.Commencement_Datee__c;      
    }
    if(loan.System_Costt__c  != null){
      loanRecord.System_Costt__c   = loan.System_Costt__c;      
    }        
    update loanRecord;

    //update the lead record update dummy to run the partner task validation to update the status of the customer's process.
    Lead leadRecord = [SELECT Id, Update_Dummy__c, System_Cost__c 
                       FROM Lead 
                       WHERE Id = : equipmentRecord.Lead__r.Id
                       AND Partner_Lookup__r.Id = : profile.partnerId
                       AND bs_Sales_ID__r.Id = : profile.salesRepId];
    if(leadRecord.Update_Dummy__c == true){
      leadRecord.Update_Dummy__c = false;
    }else{
      leadRecord.Update_Dummy__c = true;
    }
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