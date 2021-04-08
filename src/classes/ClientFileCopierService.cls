// Tested by ClientFileCopierServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ClientFileCopierService {
    @TestVisible
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    @TestVisible
    private static ContractSelector contractSelector = new ContractSelector();
    @TestVisible
    private static UASSelector uasSelector = new UASSelector();
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static ContentVersionSelector contentVersionSelector = new ContentVersionSelector();

    public fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            ContentDocumentLink.SObjectType
        }
    );

    private static final String CUSTOMER_AGREEMENT = 'Customer Agreement';
    private static final String DISCLOSURE = 'Customer Disclosure Form';
    private static final String CREDIT_REPORT = 'Customer Credit Report';
    private static final String ADDENDUM = 'Customer Addendum';

    private void checkInputType(String typeAsString){
        if (typeAsString != CUSTOMER_AGREEMENT && typeAsString != DISCLOSURE && typeAsString != CREDIT_REPORT && typeAsString != ADDENDUM){
            throw new Util.BWException('Unsupported Document Type: ' + typeAsString);
        }
    }


    @InvocableMethod(
        Label='InvocableClientFileCopier'
        Description='Takes list of 2 strings as parameters: AssignmentAgreementId and String ("Customer Agreement", "Customer Disclosure Form", "Addendum", or "Customer Credit Report")'
    )
    public static List<Id> invocableFindAndCloneDocuments (List<CloneInputs> parameters){
        ClientFileCopierService service = new ClientFileCopierService();
        String contractId = parameters[0].contractId;
        String fileType = parameters[0].documentType;
        service.checkInputType(fileType);
        Id batchJobId = service.findAndCloneDocuments((Id) contractId, fileType);
        return new List<Id>{batchJobId};
    }


    public Id findAndCloneDocuments(Id assignmentAgreementId, String docType){
        Id folderId = createSupportingDocumentsFolder(assignmentAgreementId, docType);
        Map<Id,Id> versionIdToLinkedEntityId = getDocumentIds(assignmentAgreementId, docType);
        MultiMap linkedEntityIdToFileNames = getFileNames(assignmentAgreementId, docType);
        return startBatchCloneJob(versionIdToLinkedEntityId,folderId,linkedEntityIdToFileNames);
    }

    private MultiMap getFileNames(Id assignmentAgreementId, String docTypeAsString){
        MultiMap parentIdToFileNames = MultiMap.newListInstance();
        List<Utility_Account_Subscription__c> uases = uasSelector.getUASesForAssignmentAgreement(assignmentAgreementId);
        for (Utility_Account_Subscription__c uas : uases){
            String fileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - '
                + docTypeAsString + ' - '
                + uas.Opportunity__r.Name + ' - '
                + uas.Utility_Account_Log__r.Name;

            //Customer Agreement is grabbed from Parent Contract when record exists, otherwise files grabbed from Opp.Contract
            Id contractId;
            if (docTypeAsString == 'Customer Agreement') {
                contractId = uas.Opportunity__r.Contract.Parent_Contract__c != null ? uas.Opportunity__r.Contract.Parent_Contract__c : uas.Opportunity__r.ContractId;
            } else {
                contractId = uas.Opportunity__r.ContractId;
            }
            parentIdToFileNames.putValue(contractId, fileName);
            parentIdToFileNames.putValue(uas.Opportunity__r.Personal_Credit_Report2__c, fileName);
        }
        return parentIdToFileNames;
    }

    /**
     * @description Grabs attachments from appropriate parent record. For Customer Agreements, the file
     * may live on the Parent Contract (if exists), otherwise, lives on the Opp.Contract
     * @param assignmentAgreementId Id for Assignment Agreement Contract
     * @param docType Type of document being queried
     * @return Map of <Content Document Id, Linked Entity Id>
     */
    private Map<Id,Id> getDocumentIds(Id assignmentAgreementId, String docType){
        Set<Id> parentRecordIds = new Set<Id>();
        List<ContentDocumentLink> docLinks;
        switch on docType {
            when 'Customer Agreement' {
                List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(assignmentAgreementId);
                for (Contract contract : contracts) {
                    Id parentRecordId = contract.Parent_Contract__c != null ? contract.Parent_Contract__c : contract.Id;
                    parentRecordIds.add(parentRecordId);
                }
            } when 'Customer Addendum', 'Customer Disclosure Form' {
                List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(assignmentAgreementId);
                for (Contract contract : contracts) {
                    parentRecordIds.add(contract.Id);
                }
            } when 'Customer Credit Report' {
                List<Opportunity> oppList = oppSelector.getCustomerOpportunitiesByAssignmentAgreement(assignmentAgreementId);
                for (Opportunity opp : oppList) {
                    if (opp.Personal_Credit_Report2__c != null) {
                        parentRecordIds.add(opp.Personal_Credit_Report2__c);
                    }
                }
            }
        }

        docLinks = contentDocumentSelector.selectByLinkedEntitiesWithoutData(parentRecordIds);
        return compareFileNameAndType(docLinks,docType);
    }

    private Map<Id,Id> compareFileNameAndType(List<ContentDocumentLink> docLinks, String docType) {
        Map<Id,Id> versionIdToLinkedEntityId = new Map<Id,Id>();
        for (ContentDocumentLink link : docLinks) {
            Boolean customerAgreement = docType == CUSTOMER_AGREEMENT  && link.ContentDocument.LatestPublishedVersion.Title.contains('Agreement');
            Boolean disclosure = docType == DISCLOSURE && link.ContentDocument.LatestPublishedVersion.Title.contains('Disclosure');
            Boolean creditReport = docType == CREDIT_REPORT;
            Boolean addendum = docType == ADDENDUM && link.ContentDocument.LatestPublishedVersion.Title.contains('Addendum');
            Boolean countersigned = link.ContentDocument.LatestPublishedVersion.Signing_Status__c == 'Countersigned';
            if ((countersigned && (customerAgreement || disclosure)) || creditReport || addendum) {
                versionIdToLinkedEntityId.put(link.ContentDocument.LatestPublishedVersionId, link.LinkedEntityId);
            }
        }
        return versionIdToLinkedEntityId;
    }

    private Id createSupportingDocumentsFolder(Id assignmentAgreementId, String docType){
        Supporting_Document_Folder__c folder = new Supporting_Document_Folder__c(
            Type__c = docType + 's',
            Name = docType + 's',
            Assignment_Agreement__c = assignmentAgreementId
        );
        insert folder;
        return folder.Id;
    }

    private Id startBatchCloneJob(Map<Id,Id> versionIdToLinkedEntityId, Id newFolderId, MultiMap linkedEntityIdToFileNames){
        BatchClientFileCopierService batchJob =
            new BatchClientFileCopierService(versionIdToLinkedEntityId, newFolderId, linkedEntityIdToFileNames);
        if (Test.isRunningTest()){
            // Don't have to worry about data storage of big files during tests, but only want to call it once:
            return Database.executeBatch(batchJob,200);
        } else {
            return Database.executeBatch(batchJob,1);
        }
    }

    /**
     * @param versionIds List of Content Version Ids (scoped to avoid heap limits)
     * @param versionIdToLinkedEntityId Map of all Content Version Ids to their corresponding Linked Entity Id
     * @param linkedEntityIdToFormattedFileNames Map of all Linked Entity Ids to a filename in the format:
     *  SSS Name - Document Type - Customer Name - Utility Account Number
     *
     * @return List of cloned ContentVersion
     */
    public List<ContentVersion> cloneFiles(List<Id> versionIds, Map<Id,Id> versionIdToLinkedEntityId, MultiMap linkedEntityIdToFormattedFileNames){
        Map<Id,ContentVersion> filesWithData = contentVersionSelector.selectByIdWithData(new Set<Id>(versionIds));
        List<ContentVersion> clonedFilesToInsert = new List<ContentVersion>();

        // parentId is a PCR or Contract Id, depending on the document type.
        // fileNames is the list of file names to create, generated from a list of UASes. 1 fileName per UAS
        for (Id versionId : versionIds){
            Id parentId = versionIdToLinkedEntityId.get(versionId);
            List<Object> fileNames = linkedEntityIdToFormattedFileNames.getValues(parentId);
            ContentVersion file = filesWithData.get(versionId);
            if (fileNames != null && file != null){
                for (Object value : fileNames){
                    String fileName = (String) value;
                    clonedFilesToInsert.add(cloneContentVersion(file, fileName));
                }
            }
        }
        return clonedFilesToInsert;
    }

    private ContentVersion cloneContentVersion(ContentVersion oldFile, String fileName){
        ContentVersion newFile = new ContentVersion(
            ContentLocation = 'S',
            VersionData = oldFile.VersionData,
            Title = fileName,
            PathOnClient = '/' + fileName + '.pdf'
        );
        return newFile;
    }

    public void linkNewFilesToFolder(List<ContentVersion> clonedFiles, Id newFolderId){
        Set<Id> versionIds = new Set<Id>();
        for (ContentVersion version : clonedFiles){
            versionIds.add(version.Id);
        }
        // Query for newly inserted ContentVersions to get ContentDocumentId:
        clonedFiles = contentVersionSelector.selectById(versionIds).values();
        for (ContentVersion content : clonedFiles){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = newFolderId;
            cdl.Visibility = 'InternalUsers';
            cdl.ShareType = 'V';
            cdl.ContentDocumentId = content.ContentDocumentId;
            uow.registerNew(cdl);
        }
    }

    public class CloneInputs {
        @InvocableVariable
        public Id contractId;

        @InvocableVariable(Description='"Customer Agreement", "Customer Disclosure Form", or "Customer Credit Report"')
        public String documentType;

    }
}