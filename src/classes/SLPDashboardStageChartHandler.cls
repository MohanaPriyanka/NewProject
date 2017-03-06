public without sharing class SLPDashboardStageChartHandler {
    public class StageChartResult {
        @AuraEnabled
            public String[] labels {get;set;}

        @AuraEnabled
            public Integer[] counts {get;set;}
    }

    @AuraEnabled
    public static StageChartResult getAll() {
        String partnerId = SLPUserHelper.getPartnerId(); 
        Partner__c partnerRecord;

        if (partnerId == null || partnerId == '') {
            partnerId = SLPUserHelper.getBWCCId();
        }

        StageChartResult scr = new StageChartResult();
        scr.labels = new String[]{};
        scr.counts = new Integer[]{};

        AggregateResult[] stageAr = [SELECT Name, count(Id) recordCount 
                                     FROM Partner_Task__c 
                                     WHERE Partner__r.Id = : partnerId
                                     // Just the pending ones, should be one for each customer
                                     AND Status__c = 'Pending'
                                     AND Parent_Task__c = null
                                     AND Sub_Task_Type__c = null
                                     GROUP BY Name];
        for (AggregateResult ar : stageAr) {
            scr.labels.add(String.valueOf(ar.get('Name')));
            scr.counts.add(Integer.valueOf(ar.get('recordCount')));
        }
		
        return scr;				
    }
}