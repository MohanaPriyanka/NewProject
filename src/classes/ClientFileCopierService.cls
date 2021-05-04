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
    public List<FileToCopy> filesToCopy;
    public Map<Id,Integer> numberOfCopiesByLinkedEntity = new Map<Id,Integer>();
    public Map<Id,String> newFilenameByLinkedEntityMap = new Map<Id,String>();
    public SObjectType parentSobjectType;
    public String requestedDocumentType;

    @InvocableMethod(
        Label='InvocableClientFileCopier'
        Description='Copies client files related to specified record and attaches them to a new related Supporting Documents Folder')
    public static List<Id> invocableFindAndCloneDocuments (List<CloneInputs> parameters) {
        ClientFileCopierService service = new ClientFileCopierService();
        service.parentSobjectId = parameters[0].parentSobjectId;
        service.requestedDocumentType = parameters[0].documentType;
        service.deleteExistingFiles = parameters[0].deleteExisting != null ? parameters[0].deleteExisting : false;
        service.validateParentSobjectInput();
        service.validateRequestedDocumentType();
        service.deleteExistingFolderAndAttachments();
        service.createSupportingDocumentsFolder();
        service.retrieveFilesToCopy();
        service.buildNewFileMetadata();

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
        public Id originalLinkedEntityId;
        public Id supportingDocumentFolderId;
        public String newFileName;
        public Integer numberOfCopies;
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
            // If Ops is ever re-copying files because of changes to subscriptions, pruning the "old" copied files
            // might be a good idea to clean things up. It also will be better for the Mass File Downloader tool
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

    private void retrieveFilesToCopy() {
        Set<Id> relatedRecordIds = new Set<Id>();
        List<ContentDocumentLink> docLinks;
        if (parentSobjectType == Contract.SObjectType) {
            relatedRecordIds = getRecordsRelatedToAssignmentAgreement();
        } else {
            relatedRecordIds = getRecordsRelatedToAllocationSchedule();
        }

        try {
            docLinks = contentDocumentSelector.selectByLinkedEntitiesWithoutData(relatedRecordIds);
        } catch (QueryException e) {
            String errorMessage;
            if (e.getMessage().contains('Implementation restriction: ContentDocumentLink')) {
                errorMessage = 'Could not find any related records with attached client files!';
            }
            throw new Util.BWException(errorMessage != null ? errorMessage : e.getMessage());
        }
        filesToCopy = compileFilesToCopy(docLinks);
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

    private List<FileToCopy> compileFilesToCopy(List<ContentDocumentLink> docLinks) {
        List<FileToCopy> filesToCopy = new List<FileToCopy>();
        for (ContentDocumentLink link : docLinks) {
            String documentName = link.ContentDocument.LatestPublishedVersion.Title;
            Boolean countersigned = link.ContentDocument.LatestPublishedVersion.Signing_Status__c == 'Countersigned';
            Boolean customerAgreement = requestedDocumentType == CUSTOMER_AGREEMENT && documentName.contains('Agreement');
            Boolean disclosure = requestedDocumentType == DISCLOSURE && documentName.contains('Disclosure');
            Boolean creditReport = requestedDocumentType == CREDIT_REPORT;
            Boolean addendum = requestedDocumentType == ADDENDUM && documentName.contains('Addendum');

            if ((countersigned && (customerAgreement || disclosure)) || creditReport || addendum) {
                FileToCopy fileToCopy = new FileToCopy();
                fileToCopy.contentVersionId = link.ContentDocument.LatestPublishedVersionId;
                fileToCopy.originalLinkedEntityId = link.LinkedEntityId;
                fileToCopy.supportingDocumentFolderId = supportingDocumentFolderId;
                filesToCopy.add(fileToCopy);
            }
        }
        return filesToCopy;
    }

    private void buildNewFileMetadata() {
        mapSubscriptionMetadata();
        for (FileToCopy file : filesToCopy) {
            file.newFileName = newFilenameByLinkedEntityMap.get(file.originalLinkedEntityId);
            file.numberOfCopies = numberOfCopiesByLinkedEntity.get(file.originalLinkedEntityId);
        }
    }

    private void mapSubscriptionMetadata() {
        List<Utility_Account_Subscription__c> uases = retrieveSubscriptionData();
        for (Utility_Account_Subscription__c uas : uases) {
            Id contractId;
            String newFileName = constructNewFileName(uas);

            if (requestedDocumentType == 'Customer Agreement') {
                // Customer Agreement is grabbed from Parent Contract when record exists, otherwise files grabbed from Opp.Contract
                contractId = uas.Opportunity__r.Contract.Parent_Contract__c != null ? uas.Opportunity__r.Contract.Parent_Contract__c : uas.Opportunity__r.ContractId;
            } else {
                contractId = uas.Opportunity__r.ContractId;
            }

            // For Assignment Agreements (Contract), the file's linked entity is a LASERCA__Personal_Credit_Report__c or
            // a Contract, depending on the requested document type. Adding both options to the filename map for later use.
            newFilenameByLinkedEntityMap.put(contractId, newFileName);
            newFilenameByLinkedEntityMap.put(uas.Opportunity__r.Personal_Credit_Report2__c, newFileName);

            setNumberOfCopiesByLinkedEntity(new List<Id>{contractId, uas.Opportunity__r.Personal_Credit_Report2__c});
        }
    }

    private List<Utility_Account_Subscription__c> retrieveSubscriptionData() {
        List<Utility_Account_Subscription__c> subscriptions;
        if (parentSobjectType == Contract.SObjectType) {
            subscriptions = uasSelector.getUASesForAssignmentAgreement(parentSobjectId);
        } else {
            subscriptions = uasSelector.getNonAnchorUASesForAllocationSchedule(parentSobjectId);
        }
        return subscriptions;
    }

    private String constructNewFileName(Utility_Account_Subscription__c uas) {
        String newFileName;
        if (parentSobjectType == Contract.SObjectType) {
            newFileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - ' + requestedDocumentType + ' - ' +
                uas.Opportunity__r.Name + ' - ' + uas.Utility_Account_Log__r.Name;
        } else {
            newFileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - ' + 'Disclosure Form' + ' - ' +
                uas.Utility_Account_Log__r.Name_on_Account__c + ' - ' + uas.Opportunity__r.Account.Name + ' - ' +
                uas.Utility_Account_Log__r.Cleaned_Utility_Account_Number__c;
        }
        return newFileName;
    }

    /**
     * @description Per utility or gov't requirement, sometimes in the case of multiple subscriptions to the same SSS by
     * the same customer, there is a requirement for multiple of the same document present in our file uploads to them.
     * As such, here we track the number of duplicates we should create of each file for each linked entity Id.
     * @param entityIds List of linked entity Ids
     */
    private void setNumberOfCopiesByLinkedEntity(List<Id> entityIds) {
        for (Id entityId : entityIds) {
            Integer numberOfCopies = numberOfCopiesByLinkedEntity.get(entityId);
            if (numberOfCopies == null) {
                numberOfCopiesByLinkedEntity.put(entityId, 1);
            } else {
                numberOfCopiesByLinkedEntity.put(entityId, numberOfCopies + 1);
            }
        }
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