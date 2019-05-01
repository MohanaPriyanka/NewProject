trigger ClientHealthReportTrigger on Client_Health_Report__c (before Update) {
    if(Trigger.isUpdate && Trigger.isBefore) {
        ClientReportingService.updateClientReports(Trigger.oldMap, Trigger.newMap);
    }
}