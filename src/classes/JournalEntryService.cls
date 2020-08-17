// Tested By: JournalEntryServiceTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class JournalEntryService {
    public static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    public static AccountsSelector accountSelector = new AccountsSelector();
    private Map<String, Shared_Solar_System__c> uniqueIdToSSSMap = new Map<String, Shared_Solar_System__c>();
    private Map<String, Account> bwNumberToAccountMap = new Map<String, Account>();

    public void markReadyForProductionDetail(List<Journal_Entry__c> entries) {
        for (Journal_Entry__c entry : entries) {
            entry.Ready_for_Production_Detail__c = true;
        }
    }

    public List<Journal_Entry__c> populateLookups(List<Journal_Entry__c> entries){
        setAccountAndSSSMaps(entries);
        for (Journal_Entry__c entry : entries){
            if (hasBlankValues(entry)){
                entry = setProject(entry);
                entry = setClient(entry);
                entry = setCustomer(entry);
            }
        }
        Logger.flushLogs();
        return entries;
    }

    private void setAccountAndSSSMaps(List<Journal_Entry__c> entries){
        Set<String> sssUniqueIds = new Set<String>();
        Set<String> accountBWIds = new Set<String>();
        for (Journal_Entry__c entry : entries){
            sssUniqueIds.add(entry.Project__c);
            accountBWIds.add(entry.Customer_Account__c);
            accountBWIds.add(entry.Client__c);
        }
        uniqueIdToSSSMap = sssSelector.getSSSByUniqueId(sssUniqueIds);
        bwNumberToAccountMap = accountSelector.selectByBlueWaveId(accountBWIds);
    }

    private Boolean hasBlankValues(Journal_Entry__c entry){
        return (
            entry.Project_Lookup__c == null ||
            entry.Customer_Lookup__c == null ||
            entry.Client_Lookup__c == null
        );
    }

    private Journal_Entry__c setProject(Journal_Entry__c entry) {
        Shared_Solar_System__c sss = uniqueIdToSSSMap.get(entry.Project__c);
        if (sss != null) {
            entry.Project_Lookup__c = sss.Id;
        } else {
            Logger.logLater('JournalEntryService','setProject',
                'Could not find SSS with unique Id: ' + entry.Project__c + ' for Journal Entry: ' +  entry.Id );
        }
        return entry;
    }

    private Journal_Entry__c setClient(Journal_Entry__c entry) {
        Account clientAccount = bwNumberToAccountMap.get(entry.Client__c);
        if (clientAccount != null) {
            entry.Client_Lookup__c = clientAccount.Id;
        } else {
            Logger.logLater('JournalEntryService','setClient',
            'Could not find account with bw Id: ' + entry.Client__c + ' for Journal Entry: ' +  entry.Id );
        }
        return entry;
    }

    private Journal_Entry__c setCustomer(Journal_Entry__c entry) {
        Account customerAccount = bwNumberToAccountMap.get(entry.Customer_Account__c);
        if (customerAccount != null) {
            entry.Customer_Lookup__c = customerAccount.Id;
        } else {
            Logger.logLater('JournalEntryService','setCustomer',
            'Could not find account with bw Id: ' + entry.Customer_Account__c + ' for Journal Entry: ' +  entry.Id );
        }
        return entry;
    }
}