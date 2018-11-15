public without sharing class CSCLPController {
    private static Id clientId = setClientId();
   
    @AuraEnabled 
    public static Id setClientId() {
        if (clientId == null) {
            User u = [SELECT Id, Contact.AccountId 
                      FROM User 
                      WHERE Id = :UserInfo.getUserId()];
            if (u.Contact.AccountId != null) {
                return u.Contact.AccountId;
            } else {
                throw new Util.BWException('No Account ID found for Client.');
            }
        } else {
            return clientId;
        }
    }

    @AuraEnabled 
    public static Id getClientId() {
        return clientId;
    }

    public class ClientReportData {
        @AuraEnabled
        public Map<String, String> reports = new Map<String, String>();

        @AuraEnabled
        public List<Shared_Solar_System__c> sssList = new List<Shared_Solar_System__c>();
    }

    @AuraEnabled
    public static ClientReportData getClientReportData() {
        ClientReportData clientReportData = new ClientReportData();
        List<String> reportIds = getClientReportIds();
        List<String> reportNames = getClientReportNames();
        for (Integer i=0; i<reportIds.size(); i++) {
            clientReportData.reports.put(reportNames.get(i), reportIds.get(i));
        }
        clientReportData.sssList = getClientSharedSolarSystems();
        return clientReportData;
    }

    @AuraEnabled
    public static List<Shared_Solar_System__c> getClientSharedSolarSystems (){
        List<Shared_Solar_System__c> sssList = new List<Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : [SELECT Id, Name
                                           FROM Shared_Solar_System__c 
                                           WHERE Client_Account__r.Id = : clientId]) {
            sssList.add(sss);
        }
        return sssList;
    }

    @AuraEnabled
    public static List<String> getClientReportNames (){
        List<CSCLP_Settings__c> csclpSettings = CSCLP_Settings__c.getall().values();
        String reportNames = csclpSettings.get(0).Report_Names__c;
        return reportNames.split(',');
    }

    @AuraEnabled
    public static List<String> getClientReportIds (){
        List<CSCLP_Settings__c> csclpSettings = CSCLP_Settings__c.getall().values();
        String reportIds = csclpSettings.get(0).Report_IDs__c;
        return reportIds.split(',');
    }
}