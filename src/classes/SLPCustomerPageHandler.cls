public class SLPCustomerPageHandler {                                     

    @AuraEnabled
    public static List<Loan__c> getLoanCustomers() {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Loan__c> loanList = [SELECT Id, Name, Sales_Agent__r.Name, Product__r.ProductCode, System_Costt__c, 
                         Total_Funds_Disbursed__c, Opportunity__r.StageName, Status__c
                                  FROM Loan__c WHERE Partner__c = : u.Partner_ID__c];
        return loanList;
    }
   
   @AuraEnabled
    public static List<Loan__c> getLoanCustomerWindow(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Loan__c> loanList = [SELECT Id, Name, Sales_Agent__r.Name, Product__r.ProductCode, System_Costt__c, 
                         Total_Funds_Disbursed__c, Opportunity__r.StageName, Status__c
                                  FROM Loan__c WHERE Id = : loanId];
    System.debug('Loan List is ' + loanList);                                  
        return loanList;
    }
   
   @AuraEnabled
    public static List<Task> getLoanCustomerTasks(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Task> taskList = [SELECT Id, Subject, Actual_Complete_Date__c, Status, Loan__r.Id, Loan__c, Loan_Partner_Sequence__c
                                  FROM Task WHERE Loan__c = : loanId 
                                  ORDER BY Loan_Partner_Sequence__c ASC];                               
        return taskList;
    }

   @AuraEnabled
    public static String getLoanCustomerCompletedTasks(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Task> completedTaskList = [SELECT Id, Subject, Actual_Complete_Date__c, Status, Loan__r.Id, Loan__c
                                  FROM Task WHERE Loan__c = : loanId 
                                  AND Status = 'Completed' 
                                  ORDER BY Actual_Complete_Date__c, Loan_Partner_Sequence__c DESC];  
    System.debug('The subject is ' + completedTaskList.get(0).Subject);                                                               
        return completedTaskList.get(0).Subject;
    } 
   
   @AuraEnabled
    public static List<Disbursal__c> getLoanDisbursals(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Disbursal__c> disbursalList = [SELECT Id, Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c WHERE Loan__c = : loanId 
                                  ORDER BY Disbursal_Sequence__c ASC];                               
        return disbursalList;
    }
   @AuraEnabled
    public static List<Residential_Equipment__c> getResidentialEquipment(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Residential_Equipment__c> relList = [SELECT Id, Name, CEC_Production_Tracking_System_ID_Number__c, Commonwealth_Solar_Rebate_Program__c,
                                    Contract_Execution_Date__c, Estimated_On_Site_Behind_the_Meter_Load__c, Generator_Energized_Online_Date__c,
                                    Generator_Installation_Date__c, Generator_Interconnection_Date__c, Generator_Nameplate_Capacity__c, 
                                    Generator_Type__c, Initial_Solar_Meter_Reading__c, Initial_Solar_Meter_Reading_Date__c, Interconnected__c,
                                    Interconnection_Date__c, Inverter_Manufacturer__c, Inverter_Model_Number__c, MA_Facility_Sector__c, MA_Facility_Type__c,
                                    Mechanical_Installation_Date__c, Mechanically_Installed__c,  Module_Array_Azimuth__c, Module_Array_Mounting_Type__c, Module_Array_Tilt__c,
                                    Module_Manufacturer__c, Module_Model_Number__c, Module_Mounting_Location__c, Module_Power_Rating__c,
                                    Number_of_Inverters__c, Number_of_Meters__c, Number_of_Modules__c, Percentage_of_System_Shaded__c, 
                                    PowerClerk_Application_ID__c, Remote_Monitorin_Systegm_Identifier__c, Remote_Monitoring_System_Vendor__c,
                                    Solar_Meter_Manufacturer__c,Solar_Meter_Model__c, Solar_Meter_Serial_Number__c, SREC_Opt_In_Calendar_Quarter__c, 
									Type_of_Module__c, Utility_Company__c        
                                  FROM Residential_Equipment__c WHERE Loan__c = : loanId];                               
        return relList;
    }    

}