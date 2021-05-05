/**
 * @description Copies client requested files into a new easy-to-download and accessible form for Mass File Downloader
 * - Constructs a 'Supporting Documents Folder' (SObject record) to house copied files which looks up to the parent record
 * - Majority of DML is handled in BatchClientFileCopierService due to file size / heap constraints
 * Tested by: ClientFileCopierServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ClientFileCopierService {

    /* CONSTANTS */
    private static final Set<SObjectType> SUPPORTED_PARENT_SOBJECT_TYPES = new Set<SObjectType>{
        Contract.SObjectType, Schedule_Z__c.SObjectType
    };
    private static final String CUSTOMER_AGREEMENT = 'Customer Agreement';
    private static final String DISCLOSURE = 'Customer Disclosure Form';
    private static final String CREDIT_REPORT = 'Customer Credit Report';
    private static final String ADDENDUM = 'Customer Addendum';
    private static final Set<String> SUPPORTED_DOCUMENT_TYPES = new Set<String>{
        CUSTOMER_AGREEMENT, DISCLOSURE, CREDIT_REPORT, ADDENDUM
    };

    /* STATIC PROPERTIES */
    @TestVisible private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    @TestVisible private static ContractSelector contractSelector = new ContractSelector();
    @TestVisible private static UASSelector uasSelector = new UASSelector();
    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private static ScheduleZSubscriptionSelector scheduleZSubSelector = new ScheduleZSubscriptionSelector();

    /* INSTANCE PROPERTIES */
    public Boolean deleteExistingFiles;
    public Id parentSobjectId;
    public Id supportingDocumentFolderId;
    public Map<Id,ContentDocumentLink> documentsByLinkedEntity = new Map<Id,ContentDocumentLink>();
    public List<FileToCopy> filesToCopy = new List<FileToCopy>();
    public List<Utility_Account_Subscription__c> subscriptions;
    public SObjectType parentSobjectType;
    public String requestedDocumentType;

    @InvocableMethod(
        Label='InvocableClientFileCopier'
        Description='Copies client files related to specified record and attaches them to a new related Supporting Documents Folder')
    public static List<Id> findAndCloneDocuments(List<CloneInputs> parameters) {
        ClientFileCopierService service = new ClientFileCopierService();
        service.parentSobjectId = parameters[0].parentSobjectId;
        service.requestedDocumentType = parameters[0].documentType;
        service.deleteExistingFiles = parameters[0].deleteExisting != null ? parameters[0].deleteExisting : false;

        service.validateParentSobjectInput();
        service.validateRequestedDocumentType();

        service.deleteExistingFolderAndAttachments();
        service.createSupportingDocumentsFolder();
        service.retrieveDocumentLinks();
        service.retrieveSubscriptionData();
        service.constructNewFileMetadata();

        Id batchJobId;
        batchJobId = service.startBatchCloneJob();
        return new List<Id>{batchJobId};
    }

    public class CloneInputs {
        @InvocableVariable(
            Description='Record to relate Supporting Documents Folder to. Supported objects: Contract, Allocation Schedule')
        public Id parentSobjectId;

        @InvocableVariable(
            Description='"Customer Agreement", "Customer Disclosure Form", or "Customer Credit Report"')
        public String documentType;

        @InvocableVariable(
            Description='Deletes any existing Supporting Documents Folder and attachments and starts with a clean slate')
        public Boolean deleteExisting;
    }

    public class FileToCopy {
        public Id contentVersionId;
        public Id supportingDocumentFolderId;
        public String newFileName;
    }

    private void validateParentSobjectInput() {
        try {
            parentSobjectType = parentSobjectId.getSobjectType();
        } catch (Exception e) {
            throw new Util.BWException('Invalid record Id: ' + parentSobjectId);
        }
        if (!SUPPORTED_PARENT_SOBJECT_TYPES.contains(parentSobjectType)) {
            throw new Util.BWException('Unsupported Parent SObject Type: ' + parentSobjectType.getDescribe().getName());
        }
    }

    private void validateRequestedDocumentType() {
        if (!SUPPORTED_DOCUMENT_TYPES.contains(requestedDocumentType)) {
            throw new Util.BWException('Unsupported Document Type: ' + requestedDocumentType);
        }
    }

    private void deleteExistingFolderAndAttachments() {
        if (deleteExistingFiles) {
            // TODO: Build this out if requested in the future
            throw new Util.BWException('Delete functionality not yet implemented.');
        }
    }

    private void createSupportingDocumentsFolder() {
        Supporting_Document_Folder__c folder = new Supporting_Document_Folder__c(
            Type__c = requestedDocumentType + 's',
            Name = requestedDocumentType + 's'
        );
        if (parentSobjectType == Contract.SObjectType) {
            folder.Assignment_Agreement__c = parentSobjectId;
        } else {
            folder.Allocation_Schedule__c = parentSobjectId;
        }
        insert folder;
        supportingDocumentFolderId = folder.Id;
    }

    private void retrieveDocumentLinks() {
        List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();
        Set<Id> relatedRecordIds = parentSobjectType == Contract.SObjectType ?
            getRecordsRelatedToAssignmentAgreement() :
            getRecordsRelatedToAllocationSchedule();

        try {
            docLinks = contentDocumentSelector.selectByLinkedEntitiesWithoutData(relatedRecordIds);
        } catch (QueryException e) {
            String errorMessage;
            if (e.getMessage().contains('Implementation restriction: ContentDocumentLink')) {
                errorMessage = 'Could not find any related records with attached client files!';
            }
            throw new Util.BWException(errorMessage != null ? errorMessage : e.getMessage());
        }

        for (ContentDocumentLink doc : docLinks) {
            String documentName = doc.ContentDocument.LatestPublishedVersion.Title;
            Boolean countersigned = doc.ContentDocument.LatestPublishedVersion.Signing_Status__c == 'Countersigned';
            Boolean customerAgreement = requestedDocumentType == CUSTOMER_AGREEMENT && documentName.contains('Agreement');
            Boolean disclosure = requestedDocumentType == DISCLOSURE && documentName.contains('Disclosure');
            Boolean creditReport = requestedDocumentType == CREDIT_REPORT;
            Boolean addendum = requestedDocumentType == ADDENDUM && documentName.contains('Addendum');

            if ((countersigned && (customerAgreement || disclosure)) || creditReport || addendum) {
                documentsByLinkedEntity.put(doc.LinkedEntityId, doc);
            }
        }
    }

    private void retrieveSubscriptionData() {
        subscriptions = parentSobjectType == Contract.SObjectType ?
            uasSelector.getUASesForAssignmentAgreement(parentSobjectId) :
            uasSelector.getNonAnchorUASesForAllocationSchedule(parentSobjectId);
    }

    private Set<Id> getRecordsRelatedToAssignmentAgreement() {
        Set<Id> relatedRecordIds = new Set<Id>();
        switch on requestedDocumentType {
            when 'Customer Agreement' {
                // The attachment needed may live on the Parent Contract (if exists), otherwise, lives on the Opp.Contract
                List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(parentSobjectId);
                for (Contract contract : contracts) {
                    Id parentRecordId = contract.Parent_Contract__c != null ? contract.Parent_Contract__c : contract.Id;
                    relatedRecordIds.add(parentRecordId);
                }
            } when 'Customer Addendum', 'Customer Disclosure Form' {
                List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(parentSobjectId);
                for (Contract contract : contracts) {
                    relatedRecordIds.add(contract.Id);
                }
            } when 'Customer Credit Report' {
                List<Opportunity> oppList = oppSelector.getCustomerOpportunitiesByAssignmentAgreement(parentSobjectId);
                for (Opportunity opp : oppList) {
                    if (opp.Personal_Credit_Report2__c != null) {
                        relatedRecordIds.add(opp.Personal_Credit_Report2__c);
                    }
                }
            }
        }
        return relatedRecordIds;
    }

    /**
     * @description Get record ids where files are stored for an ALS (Schedule_Z__c sObject type)
     * Relationship hierarchy: ALS -> ALSS -> UAS -> Opp -> Contract -> File.pdf
     * NOTE: Currently only supports Disclosure Forms in current iteration
     * @return Set of Ids corresponding to Contract records to which files needed for clone are attached
     */
    private Set<Id> getRecordsRelatedToAllocationSchedule() {
        Set<Id> relatedRecordIds = new Set<Id>();
        List<Schedule_Z_Subscription__c> subscriptions = scheduleZSubSelector.getALSSforClientFileDownload(parentSobjectId);
        for (Schedule_Z_Subscription__c subscription : subscriptions) {
            relatedRecordIds.add(subscription.Utility_Account_Subscription__r.Opportunity__r.ContractId);
        }
        return relatedRecordIds;
    }

    private void constructNewFileMetadata() {
        for (Utility_Account_Subscription__c uas : subscriptions) {
            Id relatedRecordWhereDocumentIsAttached;
            switch on requestedDocumentType {
                when 'Customer Agreement' {
                    // Customer Agreement is grabbed from Parent Contract when record exists, otherwise files grabbed from Opp.Contract
                    relatedRecordWhereDocumentIsAttached = uas.Opportunity__r.Contract.Parent_Contract__c != null ?
                        uas.Opportunity__r.Contract.Parent_Contract__c :
                        uas.Opportunity__r.ContractId;
                }
                when 'Customer Credit Report' {
                    relatedRecordWhereDocumentIsAttached = uas.Opportunity__r.Personal_Credit_Report2__c;
                }
                when else {
                    relatedRecordWhereDocumentIsAttached = uas.Opportunity__r.ContractId;
                }
            }

            ContentDocumentLink document = documentsByLinkedEntity.get(relatedRecordWhereDocumentIsAttached);
            if (document != null) {
                FileToCopy fileToCopy = new FileToCopy();
                fileToCopy.contentVersionId = document.ContentDocument.LatestPublishedVersionId;
                fileToCopy.supportingDocumentFolderId = supportingDocumentFolderId;
                fileToCopy.newFileName = buildNewFileName(uas);
                filesToCopy.add(fileToCopy);
            }
        }
    }

    private String buildNewFileName(Utility_Account_Subscription__c uas) {
        String newFileName;
        if (parentSobjectType == Contract.SObjectType) {
            newFileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - ' + requestedDocumentType + ' - ' +
                uas.Opportunity__r.Name + ' - ' + uas.Utility_Account_Log__r.Name;
        } else {
            newFileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - ' + 'Disclosure Form' + ' - ' +
                uas.Utility_Account_Log__r.Name_on_Account__c + ' - ' + uas.Opportunity__r.Account.Name + ' - ' +
                uas.Utility_Account_Log__r.Name;
        }
        return newFileName;
    }

    private Id startBatchCloneJob() {
        BatchClientFileCopierService batchJob = new BatchClientFileCopierService(filesToCopy);
        if (Test.isRunningTest()) {
            // Don't have to worry about data storage of big files during tests, but only want to call it once:
            return Database.executeBatch(batchJob,200);
        }
        return Database.executeBatch(batchJob,1);
    }
}