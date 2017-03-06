public without sharing class SLPDashboardStageChartHandler {
	public class StageChartResult {
		@AuraEnabled
		public String units {get;set;}

		@AuraEnabled
		public Stages[] results {get;set;}		 
	}

	public class Stages {
		@AuraEnabled
		public String unit {get;set;}

		@AuraEnabled
		public Integer recordCount {get;set;}		
	}

    @AuraEnabled
    public static StageChartResult getAll() {
        return getAllStages();
    }

	private static StageChartResult getAllStages() {
		System.debug('Begin getAllStages method');
	    String partnerId = SLPUserHelper.getPartnerId(); 
	    Partner__c partnerRecord;

	    if (partnerId == null || partnerId == '') {
	      partnerId = SLPUserHelper.getBWCCId();
	    }

		StageChartResult scr = new StageChartResult();
		scr.units = 'Stage';
		scr.results = new Stages[0];
		Map<String, Integer> stageCountMap = new Map<String, Integer>();
		Set<String> keys = new Set<String>();
		User u = [SELECT Id, AccountId, Parent_Account_ID__c, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
			try {
				AggregateResult[] stageAr = [SELECT Name, count(Id)recordCount 
											FROM Partner_Task__c 
											WHERE Partner__r.Id = : partnerId
											AND Status__c = 'Pending'
											AND Parent_Task__c = null
											AND Sub_Task_Type__c = null
											GROUP BY Name];
				for (AggregateResult ar : stageAr) {
					stageCountMap.put(String.valueOf(ar.get('Name')), (Integer)ar.get('recordCount'));
				}
				System.debug('The stageCountMap is ' + stageCountMap);
				for(Partner_Task__c taskRecord : [SELECT Id, Name, Loan__r.Id, Lead__r.Id, Loan__c, Lead__c, Status__c, 
													Partner__r.Id, Partner__c, Task_Type__c, Task_Sequence__c
												  FROM Partner_Task__c
												  WHERE Partner__r.Id = : partnerId
												  AND Status__c = 'Pending'
												  AND Parent_Task__c = null
												  AND Sub_Task_Type__c = null												  
												  AND (Lead__r.Status = 'Qualified' 
							                          OR Lead__r.Status = 'Ready for Credit Check'
							                          OR Lead__r.Status = 'Pending Information' 
							                          OR Lead__r.Status = 'Pre-Qualified'
							                          OR Lead__r.Status = 'Unfinished')
												  ORDER BY Task_Sequence__c ASC]){
					keys.add(taskRecord.Name);
				}
				System.debug('The key list is ' + keys);
			}
			catch (Exception stageAggEx){

			}
			for(String s : keys) {
				Stages uTemp = new Stages();
				uTemp.unit = s;
				uTemp.recordCount = stageCountMap.get(s);
				scr.results.add(uTemp);  
				System.debug('The uTemp is ' + uTemp);
			}
		
		System.debug('The SCR is ' + scr);
		return scr;				
	}
}