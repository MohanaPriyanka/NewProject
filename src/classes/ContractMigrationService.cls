// Tested by ContractMigrationServiceTest

public without sharing class ContractMigrationService {
    @TestVisible
    private static DocuSignSelector docuSignSelector = new DocuSignSelector();
    @TestVisible
    private static AttachmentSelector attachSelector = new AttachmentSelector();
    @TestVisible
    private static ContentVersionSelector contentVersionSelector = new ContentVersionSelector();

    @TestVisible
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            ContentDocumentLink.SObjectType,
            Opportunity.SObjectType
        }
    );

    public Map<Id,Contract> oppToContractMap = new Map<Id,Contract>();
    private Map<Id,ContentVersion> fileToContractMap = new Map<Id,ContentVersion>();

    public void executeForOpps(List<Opportunity> oppList){
        convertOpportunityToContract(oppList);
        cloneDocuSignAttachmentsToContract(oppList, 'Agreement');
        cloneDocuSignAttachmentsToContract(oppList, 'Disclosure');
        Logger.flushLogs();
        uow.commitWork();
    }

    public void convertOpportunityToContract(List<Opportunity> oppList) {
        Id customerRecordType = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Customer Contract').getRecordTypeId();
        for (Opportunity opp : oppList){
            Contract newContract = new Contract(
                AccountId = opp.AccountId,
                Product__c = opp.Product__c,
                RecordTypeId = customerRecordType,
                Contract_Type__c = 'Project Specific',
                Assignment_Agreement__c = opp.Assignment_Agreement__c
            );
            oppToContractMap.put(opp.Id,newContract);
        }
        insert oppToContractMap.values();
        for (Opportunity opp : oppList){
            Contract cntrt = oppToContractMap.get(opp.Id);
            opp.ContractId = cntrt.Id;
            uow.registerDirty(opp);
        }
    }

    public void cloneDocuSignAttachmentsToContract(List<Opportunity> oppList, String documentNameContains) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> oppToDSMap = new Map<Id, Id>();
        Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();
        Map<Id, dsfs__DocuSign_Status__c> docuStatusMap;
        List<Attachment> attachmentList;
        fileToContractMap = new Map<Id,ContentVersion>();

        for (Opportunity opp : oppList){
            oppIds.add(opp.Id);
        }
        docuStatusMap = docuSignSelector.getDocusignStatuses(oppIds);
        for (dsfs__DocuSign_Status__c docSignStatus : docuStatusMap.values()){
            oppToDSMap.put(docSignStatus.dsfs__Opportunity__c,docSignStatus.Id);
        }
        attachmentList = attachSelector.getAttachmentsByParentIdAndName(docuStatusMap.keySet(), documentNameContains);
        for (Attachment attach : attachmentList){
            // We expect to see duplicates of the same file so don't log an error if >1 match, just pick one
            attachmentMap.put(attach.ParentId,attach);
        }
        for (Id oppId : oppIds){
            Id dsStatusId = oppToDSMap.get(oppId);
            if (dsStatusId == null){
                Logger.logLater('ContractMigrationService','No DocuSign for Opportunity',oppId);
            } else {
                Attachment fileAttach = attachmentMap.get(dsStatusId);
                if (fileAttach == null){
                    Logger.logLater('ContractMigrationService','No Attachment for DocuSign',dsStatusId);
                } else {
                    convertAttachmentToFile(fileAttach, oppId);
                }
            }
        }
        insert fileToContractMap.values();
        createContentDocumentLinks();
    }

    private void convertAttachmentToFile(Attachment fileAttach, Id opportunityId) {
        Contract newContract = oppToContractMap.get(opportunityId);
        if (newContract == null){
            Logger.logLater('ContractMigrationService','No Contract Record for opp',opportunityId);
            return;
        }
        ContentVersion version = new ContentVersion(
            ContentLocation = 'S',
            VersionData = fileAttach.Body,
            Title = fileAttach.Name,
            PathOnClient = '/' + fileAttach.Name
        );
        fileToContractMap.put(newContract.Id, version);
    }

    private void createContentDocumentLinks(){
        Set<Id> contentVersionIds = new Set<Id>();

        for (ContentVersion version : fileToContractMap.values()){
            contentVersionIds.add(version.Id);
        }

        Map<Id, ContentVersion> versionmap = contentVersionSelector.selectById(contentVersionIds);

        for (Contract contract : oppToContractMap.values()){
            ContentVersion version = fileToContractMap.get(contract.Id);
            if (version != null){
                ContentVersion file = versionmap.get(version.Id);
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = contract.Id;
                cdl.Visibility = 'InternalUsers';
                cdl.ShareType = 'V';
                cdl.ContentDocumentId = file.ContentDocumentId;
                uow.registerNew(cdl);
            }
        }
    }
}