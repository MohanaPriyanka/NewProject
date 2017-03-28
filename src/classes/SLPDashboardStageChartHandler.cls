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
        String chartQuery = 'SELECT Name, count(Id) recordCount';
        chartQuery += '      FROM Partner_Task__c' ;
        chartQuery += '      WHERE Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
        chartQuery += '      AND Status__c = \'' + 'Pending' + '\' ';
        chartQuery += '      AND Parent_Task__c = null ';
        chartQuery += '      AND Sub_Task_Type__c = null ';

        if (profile.LicenseType != 'Executive') {
            chartQuery += '  AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';      
        }
        chartQuery += '      GROUP BY Name ';

        AggregateResult[] stageAr = Database.query(chartQuery);

        for (AggregateResult ar : stageAr) {
            scr.labels.add(String.valueOf(ar.get('Name')));
            scr.counts.add(Integer.valueOf(ar.get('recordCount')));
        }
        return scr;				
    }
}


