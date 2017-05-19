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
  
  @AuraEnabled
  public static String getLicenseType() {
      return profile.LicenseType;
  }  

 //The getAllCustomers method returns a list of loans to the SLPCustomer lightning component to show up in the customers tab
  @AuraEnabled 
  public static List<Loan__c> getAllCustomers (String searchValue) {
    List<Loan__c> loanList = new List<Loan__c>();
    String loanQuery = 'SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, Acquisition_Status__c, Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode, Partner__r.Name, Sales_Agent__r.Id, (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = \'' + 'Pending' + '\' LIMIT 1)  ' ;
    loanQuery += '      FROM Loan__c' ; 
    loanQuery += '      WHERE Partner__r.Id  =  \'' + profile.partnerId +  '\' ';   
    if (profile.LicenseType != 'Executive') {
      loanQuery += '    AND Sales_Agent__r.Id  =  \'' + profile.salesRepId +  '\' ';      
    } 
    if (searchValue != null) {
      loanQuery += '    AND Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;          
    }             
    loanQuery += '      ORDER BY createdDate DESC'; 
    for(Loan__c loanRecord : Database.query(loanQuery)){
      loanList.add(loanRecord);
    }    
    return loanList;
  }

  //The getCustomerInformation method returns an equipment list to show system information, and other customer information on the customer window
  @AuraEnabled 
  public static Residential_Equipment__c getCustomerInformation (String loanId) {
    List<Residential_Equipment__c> equipmentList = new List<Residential_Equipment__c>();
    String equipQuery = 'SELECT Id, Name, Loan__r.Name, Opportunity__r.Lead_Id__c, Opportunity__r.Id, Loan__r.Lead__r.Update_Dummy__c, Annual_Production_kWh_kW__c, Loan__r.Lead__r.Annual_Income_Currency__c, Loan__r.Lead__r.Id, Loan__r.Product__r.Name,Loan__r.System_Costt__c,  Loan__r.Commencement_Datee__c, Loan__r.Maturity_Datee__c, Loan__r.Principall__c, Loan__r.Principal__c, Loan__r.Product__r.Program__c, Loan__r.Id, Loan__r.DOER_Solar_Loann__c,Loan__r.Total_Funds_Disbursed__c, Loan__r.Sales_Agent__r.Name, Loan__r.Product__r.ProductCode, Loan__r.Partner__r.Name, Billing_City__c, Billing_Zip__c, CEC_Production_Tracking_System_ID_Number__c, Commonwealth_Solar_Rebate_Program__c, Concatenated_Inverter_Type__c, Concatenated_Module_Type__c, Contract_Execution_Date__c, DOER_Solar_Loan__c, Estimated_On_Site_Behind_the_Meter_Load__c, Generator_Energized_Online_Date__c, Generator_Installation_Date__c, Generator_Interconnection_Date__c, Generator_Nameplate_Capacity__c, Generator_Type__c, Initial_Solar_Meter_Reading__c, Initial_Solar_Meter_Reading_Date__c, Interconnected__c, Interconnection_Date__c, Inverter_Manufacturer__c, Inverter_Model_Number__c, Lead__c, Loan__c, MA_Facility_Sector__c, MA_Facility_Type__c, Mechanical_Installation_Date__c, Mechanically_Installed__c, Module_Array_Azimuth__c, Module_Array_Mounting_Type__c, Module_Array_Tilt__c, Module_Manufacturer__c, Module_Model_Number__c, Module_Mounting_Location__c, Module_Power_Rating__c, Number_of_Inverters__c, Number_of_Meters__c, Number_of_Modules__c, Opportunity__c, Opportunity_Custom_ID__c, Opportunity_Name__c, Percentage_of_System_Shaded__c, PowerClerk_Application_ID__c, Remote_Monitorin_Systegm_Identifier__c, Remote_Monitoring_System_Vendor__c, Solar_Meter_Manufacturer__c, Solar_Meter_Model__c, Solar_Meter_Serial_Number__c, SREC_Opt_In_Calendar_Quarter__c, System_Size_from_Opp__c, System_Size_Differs__c, Type_of_Inverter__c, Type_of_Module__c, Unique_ID__c        ' ;
    equipQuery += '      FROM Residential_Equipment__c' ;
    equipQuery += '      WHERE Loan__r.Id  =  \'' + loanId +  '\' ';
    equipQuery += '      AND Loan__r.Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
    if (profile.LicenseType != 'Executive') {
      equipQuery += '    AND Loan__r.Sales_Agent__r.Id  =  \'' + profile.salesRepId +  '\' ';      
    }
    equipQuery += '      LIMIT 1 ';
    for(Residential_Equipment__c equipmentRecord : Database.query(equipQuery)){
      equipmentList.add(equipmentRecord);
    }    
      return equipmentList.get(0);         
  }

  public class ProgressBarData {      
      @AuraEnabled 
      public String pendingTaskName;
      @AuraEnabled 
      public String program;      
      @AuraEnabled 
      public Integer pendingTaskSequence;     
  }

  //the getProgressBarData returns the pending task for the SLP's customer window progress bar. It could be replaced with the getLoanCustomerTasks
  //method if the right logic is applied to the SLPCustomerController component
  @AuraEnabled 
  public static ProgressBarData getProgressBarData(String loanId) {
    ProgressBarData pbData = new ProgressBarData();
    String progressBarTaskName;
    String pendingQuery = 'SELECT Id, Name, Status__c, Completion_Date__c, Task_Sequence__c, Loan__r.Name ' ;
    pendingQuery += '      FROM Partner_Task__c' ;
    pendingQuery += '      WHERE Loan__c  =  \'' + loanId +  '\' ';
    pendingQuery += '      AND Status__c = \'' + 'Pending' + '\' ';
    pendingQuery += '      AND Parent__c = true ';
    pendingQuery += '      AND Sub_Task_Type__c = null ';
    pendingQuery += '      AND Parent_Task__c = null ';
    pendingQuery += '      AND Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
    if (profile.LicenseType != 'Executive') {
      pendingQuery += '    AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';      
    }
    pendingQuery += '      ORDER BY Completion_Date__c, Task_Sequence__c DESC'; 
    pendingQuery += '      LIMIT 1 ';
    for(Partner_Task__c taskRecord : Database.query(pendingQuery)){
      pbData.pendingTaskName = taskRecord.Name;
      pbData.pendingTaskSequence = (Integer)taskRecord.Task_Sequence__c;
    }
    String completedTaskQuery = 'SELECT Id, (SELECT Id, Name, Task_Sequence__c, Loan__r.DOER_Solar_Loann__c FROM Partner_Tasks__r WHERE Parent__c = true AND Sub_Task_Type__c = null AND Parent_Task__c = null)'; 
    completedTaskQuery += '      FROM Loan__c' ;
    completedTaskQuery += '      WHERE Id  =  \'' + loanId +  '\' ';
    for(Loan__c loan : Database.query(completedTaskQuery)){
      for (Partner_Task__c taskRecord : loan.Partner_Tasks__r) {
        progressBarTaskName = taskRecord.Name + 'ProgressBar';             
        if (taskRecord.Loan__r.DOER_Solar_Loann__c) {
          pbData.program = 'MSLP';               
        } else {
          pbData.program = 'BWSL';   
        }      
      }
    }
    System.debug('chck ' + pbData);
    return pbData;  
  }

  //the getLoanCustomerTasks returns the list of tasks for the customer window 
  @AuraEnabled
  public static List<Partner_Task__c> getLoanCustomerTasks(String loanId) {
    List<Partner_Task__c>  taskList = new List<Partner_Task__c>();
    String taskQuery = 'SELECT Id, Name, Completion_Date__c, SubTasks__c, Status__c, Loan__r.Id, Loan__c, Task_Sequence__c, Task_Type__c, Progress_Bar_Id__c, Progress_Bar_Name__c ' ;
    taskQuery += '      FROM Partner_Task__c' ;
    taskQuery += '      WHERE Loan__c  =  \'' + loanId +  '\' ';
    taskQuery += '      AND Parent__c = true ';
    taskQuery += '      AND Sub_Task_Type__c = null ';
    taskQuery += '      AND Parent_Task__c = null ';
    taskQuery += '      AND Partner__r.Id  =  \'' + profile.partnerId +  '\' ';  
    if (profile.LicenseType != 'Executive') {
      taskQuery += '    AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';      
    }
    taskQuery += '      ORDER BY Task_Sequence__c ASC'; 
    for(Partner_Task__c taskRecord : Database.query(taskQuery)){
      taskList.add(taskRecord);
    }        
    return taskList;
  }      

  //the getLoanParentSubTasks returns the list of subTasks for the selected grand-parent task on the customer window
  @AuraEnabled
  public static List<Partner_Task__c> getLoanParentSubTasks(String taskId) {
    List<Partner_Task__c>  taskList = new List<Partner_Task__c>();
    String taskQuery = 'SELECT Id, Name, Completion_Date__c, SubTasks__c, Parent_Task__r.Name, Status__c, Loan__r.Id, Loan__c, Task_Type__c, Task_Sequence__c ' ;
    taskQuery += '      FROM Partner_Task__c' ;
    taskQuery += '      WHERE Parent_Task__c  =  \'' + taskId +  '\' ';
    taskQuery += '      AND Partner__r.Id  =  \'' + profile.partnerId +  '\' ';  
    if (profile.LicenseType != 'Executive') {
      taskQuery += '    AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';      
    }
    taskQuery += '      ORDER BY Task_Sequence__c ASC'; 
    for(Partner_Task__c taskRecord : Database.query(taskQuery)){
      taskList.add(taskRecord);
    }        
    return taskList;
  }    
  
  //the getCompleteDisbursals method returns the completed disbursals for the disbursals tab and for the customer window, depending on the 
  // parameters provided by the lightning component
  @AuraEnabled
  public static List<Disbursal__c> getCompleteLoanDisbursals(String loanId, String searchValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c, Date_of_Disbursal__c, Loan__r.Name, Disbursal_Percentage__c, Status__c, Amount__c, Type__c, Loan__r.Sales_Agent__r.Id ' ;
    disbursalQuery += '      FROM Disbursal__c' ;
    disbursalQuery += '      WHERE Status__c = \'' + 'Complete' + '\' ' ;
    disbursalQuery += '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                                         

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search      
      disbursalQuery += '    AND Loan__c = \'' + loanId +  '\' ' ;         
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += '    AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;        
    } 
    disbursalQuery += '      ORDER BY createdDate ASC' ;   
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
    disbursalQuery += '      FROM Disbursal__c' ;
    disbursalQuery += '      WHERE Status__c = \'' + 'Not yet disbursed' + '\' ' ;
    disbursalQuery += '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;                                                         

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search      
      disbursalQuery += '    AND Loan__c = \'' + loanId +  '\' ' ;         
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += '    AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;        
    } 
    disbursalQuery += '      ORDER BY createdDate ASC' ;   
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursalList.add(disbursal);
    }
    return disbursalList;
  }  

  //the updateDisbursals method updates the confirmation field on the disbursal on partner action within the SLP
  @AuraEnabled
  public static void updateDisbursals(String disbursalId, Boolean disbursalValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c  ' ;    
    disbursalQuery += '      FROM Disbursal__c' ;
    disbursalQuery += '      WHERE Id =  \'' + disbursalId +  '\' ' ; 
    disbursalQuery += '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;     
    if (profile.LicenseType != 'Executive') {
      disbursalQuery += '    AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;     
    }
    disbursalQuery += '      LIMIT 1' ;
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursal.Partner_Confirmation__c = disbursalValue;
      disbursalList.add(disbursal);
    }
    update disbursalList;
  }    

  //the saveCustomerInformation method allows the user to enter in the customer's system information/commencement date to the SLP and save it to SF
  @AuraEnabled
  public static void saveCustomerInformation(Residential_Equipment__c equipmentFromComponent, String equipmentId, String loanId, Loan__c loan) {        
    String nameVar;
    Integer i;
    String fieldType;
    List<String> equipmentFields = new List<String>();

    Residential_Equipment__c equipmentRecord = [SELECT Id, Lead__r.Id, Loan__r.Name, Name, Loan__r.Sales_Agent__r.Partner__r.Id, 
                                                    Loan__r.Sales_Agent__r.Id, Loan__r.Sales_Agent__r.Name, Billing_City__c, Billing_Zip__c, CEC_Production_Tracking_System_ID_Number__c, Commonwealth_Solar_Rebate_Program__c, Concatenated_Inverter_Type__c, Concatenated_Module_Type__c, Contract_Execution_Date__c, DOER_Solar_Loan__c, Estimated_On_Site_Behind_the_Meter_Load__c, Generator_Energized_Online_Date__c, Generator_Installation_Date__c, Generator_Interconnection_Date__c, Generator_Nameplate_Capacity__c, Generator_Type__c, Initial_Solar_Meter_Reading__c, Annual_Production_kWh_kW__c, Initial_Solar_Meter_Reading_Date__c, Interconnected__c, Interconnection_Date__c, Inverter_Manufacturer__c, Inverter_Model_Number__c, Lead__c, Loan__c, MA_Facility_Sector__c, MA_Facility_Type__c, Mechanical_Installation_Date__c, Mechanically_Installed__c, Module_Array_Azimuth__c, Module_Array_Mounting_Type__c, Module_Array_Tilt__c, Module_Manufacturer__c, Module_Model_Number__c, Module_Mounting_Location__c, Module_Power_Rating__c, Number_of_Inverters__c, Number_of_Meters__c, Number_of_Modules__c, Opportunity__c, Opportunity_Custom_ID__c, Opportunity_Name__c, Percentage_of_System_Shaded__c, PowerClerk_Application_ID__c, Remote_Monitorin_Systegm_Identifier__c, Remote_Monitoring_System_Vendor__c, Solar_Meter_Manufacturer__c, Solar_Meter_Model__c, Solar_Meter_Serial_Number__c, SREC_Opt_In_Calendar_Quarter__c, System_Size_from_Opp__c, System_Size_Differs__c, Type_of_Inverter__c, Type_of_Module__c, Unique_ID__c       
                                                FROM Residential_Equipment__c
                                                WHERE Id = : equipmentId];
    if(String.isNotBlank(equipmentFromComponent.Module_Manufacturer__c) 
      && String.isNotBlank(equipmentFromComponent.Inverter_Manufacturer__c)){
        nameVar = equipmentRecord.Loan__r.Name + ' ' + equipmentFromComponent.Module_Manufacturer__c + '/' + equipmentFromComponent.Inverter_Manufacturer__c;
        if (nameVar.length() >= 80) {
          nameVar = nameVar.subString(0,80);
        }
        equipmentRecord.Name = nameVar; 
        nameVar = null;
    }         
    updateEquipmentFieldFromInput(equipmentFromComponent, equipmentRecord);        

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

    //update the lead record update dummy to run the partner task validation to update the status of the customer's process.
    Lead leadRecord = [SELECT Id, Update_Dummy__c, System_Cost__c 
                       FROM Lead 
                       WHERE Id = : equipmentRecord.Lead__r.Id];
    if(leadRecord.Update_Dummy__c == true){
      leadRecord.Update_Dummy__c = false;
    }else{
      leadRecord.Update_Dummy__c = true;
    }
    update leadRecord;
  }

  @AuraEnabled
  public static void updateEquipmentFieldFromInput(Residential_Equipment__c equipmentFromInput, Residential_Equipment__c equipmentToBeUpdated) {
    Map<String, Object> equipmentFieldMap = new Map<String,Object>(equipmentFromInput.getPopulatedFieldsAsMap());
    for (String fieldName : equipmentFieldMap.keySet()) {
      if (equipmentFieldMap.get(fieldName) instanceof Integer || equipmentFieldMap.get(fieldName) instanceof Double) {
        if (equipmentFieldMap.get(fieldName) != null) {
          equipmentToBeUpdated.put(fieldName, equipmentFromInput.get(fieldName));                       
        }
      } else if (equipmentFieldMap.get(fieldName) instanceof String) {
          if (String.isNotBlank((String)equipmentFieldMap.get(fieldName))) {
            equipmentToBeUpdated.put(fieldName, equipmentFromInput.get(fieldName));
          }
      } else if (equipmentFieldMap.get(fieldName) instanceof Boolean) {
        equipmentToBeUpdated.put(fieldName, equipmentFromInput.get(fieldName));
      }
    }
    update equipmentToBeUpdated;
  }  

  @AuraEnabled 
  public static Boolean getAnyUnseenLeads () {
    List<Lead> leadsNotViewedByAdminList = new List<Lead>();
    List<Lead> leadsNotViewedByAgentList = new List<Lead>();

    String leadQuery = 'SELECT Id, Viewed_by_Partner_Admin__c, Viewed_by_Partner_Agent__c' ;
    leadQuery += '   FROM Lead' ;    
    leadQuery += '   WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';
    leadQuery += '   AND Product_Line__c = \'' + 'Residential Loan' + '\' ';

    if (profile.LicenseType != 'Executive') {
      leadQuery += '    AND bs_Sales_ID__r.Id  =  \'' + profile.salesRepId +  '\' ';            
    }
    for(Lead leadRecord : Database.query(leadQuery)){
      if (!leadRecord.Viewed_by_Partner_Admin__c) {
        leadsNotViewedByAdminList.add(leadRecord);
      } 
      if (!leadRecord.Viewed_by_Partner_Agent__c) {
        leadsNotViewedByAgentList.add(leadRecord);
      }       
    } 
    if (profile.LicenseType == 'Executive') {
      if (!leadsNotViewedByAdminList.isEmpty()) {
        return true;
      } else {
        return false;
      }
    } else if (profile.LicenseType == 'User') {
        if (!leadsNotViewedByAgentList.isEmpty()) {
          return true;
        } else {
          return false;
        }
    } else {
      return false;
    }              
  }   
}