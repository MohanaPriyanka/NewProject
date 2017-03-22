/*************************************************************************************
 * Created By:  Peter Yao
 * 
 * Description: 
 * 
 Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPDashboardStageChartHandler {
    public class StageChartResult {
        @AuraEnabled
            public String[] labels {get;set;}

        @AuraEnabled
            public Integer[] counts {get;set;}
    }

    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    @AuraEnabled
    public static StageChartResult getAll() {
        StageChartResult scr = new StageChartResult();
        scr.labels = new String[]{};
        scr.counts = new Integer[]{};

        AggregateResult[] stageAr = [SELECT Name, count(Id) recordCount 
                                     FROM Partner_Task__c 
                                     WHERE Partner__r.Id = : profile.partnerId
                                     AND Sales_Representative__r.Id = : profile.salesRepId
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