/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: 
 * 
 * Tested By: SLPControllerTestclass
 *************************************************************************************/
public without sharing class SLPDashboardHandler {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    public class DashboardWidgets {      
        @AuraEnabled
        public Decimal totalSystemsContracted;
       
        @AuraEnabled
        public Decimal totalFundsDisbursed;
        
        @AuraEnabled
        public Decimal totalFundsPending;
    }

    @AuraEnabled
    public static String getLicenseType() {
        return profile.LicenseType;
    }

    //the getDashboardWidgets method returns the values for the SLP's dashboard widgets.
    @AuraEnabled
    public static DashboardWidgets getDashboardWidgets() { 
        DashboardWidgets widgets = new DashboardWidgets();    
        
        Partner__c partner = [SELECT Id, Name, Total_Funds_Disbursed__c, Total_Funds_Not_Disbursed__c 
                              FROM Partner__c 
                              WHERE Id = : profile.partnerId];  
        widgets.totalFundsDisbursed = partner.Total_Funds_Disbursed__c;
        widgets.totalFundsPending = partner.Total_Funds_Not_Disbursed__c;
        widgets.totalSystemsContracted = widgets.totalFundsDisbursed + widgets.totalFundsPending;
        return widgets;
    }   

    //the getsTasksByStage method returns the task list to be displayed on the dashboard of the SLP
    @AuraEnabled
    public static List<Partner_Task__c> getTasksByStage(String stageName) {    
        List<Partner_Task__c>  taskList = new List<Partner_Task__c>();
        String taskQuery = 'SELECT Id, Name, Status__c, Loan__r.Product__r.Name, Lead__r.Name, Loan__r.Name, Task_Type__c ' ;
        taskQuery += '      FROM Partner_Task__c' ;
        taskQuery += '      WHERE Status__c = \'' + 'Pending' + '\' ';
        taskQuery += '      AND Loan__c != null ';
        taskQuery += '      AND Lead__c != null ';
        taskQuery += '      AND Sub_Task_Type__c = null ';
        taskQuery += '      AND Parent_Task__c = null ';   
        taskQuery += '      AND Partner__r.Id  =  \'' + profile.partnerId +  '\' '; 
        if (profile.LicenseType != 'Executive') {
          taskQuery += '    AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';                  
        }
        if (stageName != 'All') {
            taskQuery += '  AND Name =  \'' + stageName +  '\' ';     
        }             
        for(Partner_Task__c taskRecord : Database.query(taskQuery)){
          taskList.add(taskRecord);
        }        
        return taskList;
    }              

    @AuraEnabled
    public static List<Partner_Alert__c> getPartnerAlerts() {
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        Date today = Date.today();
        for (Partner_Alert__c partnerAlert : [SELECT Id, Name, Importance__c, Active__c, Date__c, Alert_Body__c, 
                                                  (SELECT Id, Partner__r.Name, Partner__r.Id, Partner_Alert__r.Name, Sales_Representative__r.Id
                                                  FROM Partner_Alert_Filters__r
                                                  WHERE Acknowledged__c = false
                                              AND (Date_of_Reminder__c <= : today 
                                                OR Date_of_Reminder__c = null))
                                              FROM Partner_Alert__c
                                              WHERE Active__c = true]){
            for (Partner_Alert_Filter__c partnerFilter : partnerAlert.Partner_Alert_Filters__r) {
                if(partnerFilter.Sales_Representative__r.Id == profile.salesRepId) { 
                    partnerAlertList.add(partnerAlert);
                    
                }
            }            
        }
        return partnerAlertList;
    }

    @AuraEnabled
    public static void acknowledgePartnerAlert(String partnerAlertId) {
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();       
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name, Sales_Representative__r.Id FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if(partnerAlertFilter.Sales_Representative__r.Id == profile.salesRepId) {
                    partnerAlertFilter.Acknowledged__c = true;
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }

    @AuraEnabled
    public static void partnerAlertRemindLater(String partnerAlertId) {
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();     
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name, Sales_Representative__r.Id FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if(partnerAlertFilter.Sales_Representative__r.Id == profile.salesRepId) {
                    partnerAlertFilter.Remind_Later__c = Date.today();
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }         
}