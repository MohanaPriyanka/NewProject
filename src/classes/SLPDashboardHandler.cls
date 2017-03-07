public without sharing class SLPDashboardHandler {

    @AuraEnabled
    public static List<Decimal> getTotalCostandDisbrsals() {    
        Decimal totalFundsDisbursed;
        Decimal totalFundsNotDisbursed;
        Decimal totalSystemCost;
        List<Decimal> dashboardFundsList = new List<Decimal>();        
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        

        Partner__c partner = [SELECT Id, Name, Total_Funds_Disbursed__c, Total_Funds_Not_Disbursed__c 
                                FROM Partner__c 
                                WHERE Id = : partnerId];        

        totalFundsDisbursed = partner.Total_Funds_Disbursed__c;
        totalFundsNotDisbursed = partner.Total_Funds_Not_Disbursed__c;
        totalSystemCost = totalFundsDisbursed + totalFundsNotDisbursed;
        
        dashboardFundsList.add(totalSystemCost);   
        dashboardFundsList.add(totalFundsDisbursed);    
        dashboardFundsList.add(totalFundsNotDisbursed);


        return dashboardFundsList;
    }   

	@AuraEnabled
	public static List<Partner_Task__c> getTasksByStage(String stageName) {
		String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
		if(stageName != 'All'){
            List<Partner_Task__c> taskList = [SELECT Id, Name, Status__c, Loan__r.Product__r.Name, Lead__r.Name, 
                                                Loan__r.Name, Task_Type__c
                                                FROM Partner_Task__c 
                                                WHERE  Name = : stageName 
                                                //AND Parent__c = true
                                                //AND Loan__c != null
                                                //AND Lead__c != null
                                                AND Sub_Task_Type__c = null
                                                AND Parent_Task__c = null                                                  
                                                AND Status__c = 'Pending' 
                                                AND Partner__r.Id = : partnerId];            
            return taskList;

        }else{
            List<Partner_Task__c> taskList = [SELECT Id, Name, Status__c, Loan__r.Product__r.Name, Lead__r.Name, Loan__r.Name, Task_Type__c
                                                FROM Partner_Task__c 
                                                WHERE Status__c = 'Pending' 
                                                //AND Parent__c = true
                                                //AND Loan__c != null
                                                //AND Lead__c != null
                                                AND Sub_Task_Type__c = null
                                                AND Parent_Task__c = null                                                  
                                                AND Partner__r.Id = : partnerId];                    
            return taskList;

       }
	}

    @AuraEnabled
    public static List<Partner_Alert__c> getPartnerAlerts() {
        System.debug('Begin the getPartnerAlerts method');
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        Date today = Date.today();
        for (Partner_Alert__c partnerAlert : [SELECT Id, Name, Body__c, Importance__c, Active__c, Date__c,
                                                (SELECT Id, Partner__r.Name, Partner__r.Id, Partner_Alert__r.Name
                                                 FROM Partner_Alert_Filters__r
                                                 WHERE Acknowledged__c != true
                                                 AND (Date_of_Reminder__c <= : today 
                                                 OR Date_of_Reminder__c = null))
                                               FROM Partner_Alert__c]){
            if(partnerAlert.Partner_Alert_Filters__r.size() > 0) {
                for (Partner_Alert_Filter__c partnerFilter : partnerAlert.Partner_Alert_Filters__r) {
                    if(partnerFilter.Partner__r.Id == partnerId) { //adjust to fit all partners
                        partnerAlertList.add(partnerAlert);
                    }
                }
            }
        }
        return partnerAlertList;
    }

    @AuraEnabled
    public static void acknowledgePartnerAlert(String partnerAlertId) {
        System.debug('Begin the acknowledgePartnerAlert method');
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();   
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if(partnerAlertFilter.Partner__r.Id == partnerId) {
                    partnerAlertFilter.Acknowledged__c = true;
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }

    @AuraEnabled
    public static void partnerAlertRemindLater(String partnerAlertId) {
        System.debug('Begin the partnerAlertRemindLater method');
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();   
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if(partnerAlertFilter.Partner__r.Id == partnerId) {
                    partnerAlertFilter.Remind_Later__c = Date.today();
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }         
}