public with sharing class SLPDashboardHandler {

    @AuraEnabled
    public static List<Decimal> getTotalCostandDisbrsals() {    
        Decimal totalFundsDisbursed;
        Decimal totalFundsNotDisbursed;
        Decimal totalSystemCost;
        List<Decimal> dashboardFundsList = new List<Decimal>();

        User u = [Select Id, Partner_ID__c from User where Id = :UserInfo.getUserId()];

// _____________ACTIVATE THE SOQL BELOW WHEN THE PARTNER COMMUNITIES LICENSE IS READY FOR TESTING_____________

        //Partner__c partner = [SELECT Id, Name, Total_Funds_Disbursed__c, Total_Funds_Not_Disbursed__c 
        //                        FROM Partner__c 
        //                        WHERE Id = : u.Partner_ID__c];
//____________________________________________________________________________________________________________

        Partner__c partner = [SELECT Id, Name, Total_Funds_Disbursed__c, Total_Funds_Not_Disbursed__c 
                                FROM Partner__c 
                                WHERE Name = : 'BlueWave Customer Care'];        

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
		User u = [Select Id, Partner_ID__c from User where Id = :UserInfo.getUserId()];
		if(stageName != 'All'){
            List<Partner_Task__c> taskList = [SELECT Id, Name, Status__c, Loan__r.Product__r.Name, Lead__r.Name, 
                                                Loan__r.Name, Task_Type__c
                                                FROM Partner_Task__c 
                                                WHERE  Name = : stageName 
                                                AND Parent__c = true
                                                AND Sub_Task_Type__c = null
                                                AND Parent_Task__c = null                                                  
                                                AND Status__c = 'Pending' 
                                                AND Partner__r.Name = 'BlueWave Customer Care'];            
            return taskList;

        }else{
            List<Partner_Task__c> taskList = [SELECT Id, Name, Status__c, Loan__r.Product__r.Name, Lead__r.Name, Loan__r.Name, Task_Type__c
                                                FROM Partner_Task__c 
                                                WHERE Status__c = 'Pending' 
                                                AND Parent__c = true
                                                AND Sub_Task_Type__c = null
                                                AND Parent_Task__c = null                                                  
                                                AND Partner__r.Name = 'BlueWave Customer Care'];                    
            return taskList;

       }
	}
}