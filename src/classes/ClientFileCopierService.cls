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

    private void checkInputType(String typeAsString){
        if (typeAsString != CUSTOMER_AGREEMENT && typeAsString != DISCLOSURE && typeAsString != CREDIT_REPORT){
            throw new Util.BWException('Unsupported Document Type: ' + typeAsString);
        }
    }


    @InvocableMethod(
        Label='InvocableClientFileCopier'
        Description='Takes list of 2 strings as parameters: AssignmentAgreementId and String ("Customer Agreement", "Customer Disclosure Form", or "Customer Credit Report")'
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
        Map<Id,Id> versionIdToParentId = getDocumentIds(assignmentAgreementId, docType);
        Map<Id,List<String>> parentIdToFileNames = getFileNames(assignmentAgreementId, docType);
        return startBatchCloneJob(versionIdToParentId,folderId,parentIdToFileNames);
    }

    private Map<Id,List<String>> getFileNames(Id assignmentAgreementId, String docTypeAsString){
        Map<Id,List<String>> parentIdToFileNames = new Map<Id,List<String>>();
        List<Utility_Account_Subscription__c> uases = uasSelector.getUASesForAssignmentAgreement(assignmentAgreementId);

        for (Utility_Account_Subscription__c uas : uases){
            String fileName = uas.Opportunity__r.Shared_Solar_System__r.Name + ' - '
                + docTypeAsString + ' - '
                + uas.Opportunity__r.Name + ' - '
                + uas.Utility_Account_Log__r.Name;
            if (parentIdToFileNames.containsKey(uas.Opportunity__r.Personal_Credit_Report2__c)){
                parentIdToFileNames.get(uas.Opportunity__r.Personal_Credit_Report2__c).add(fileName);
            } else {
                parentIdToFileNames.put(uas.Opportunity__r.Personal_Credit_Report2__c,new List<String>{fileName});
            }
            if (parentIdToFileNames.containsKey(uas.Opportunity__r.ContractId)){
                parentIdToFileNames.get(uas.Opportunity__r.ContractId).add(fileName);
            } else {
                parentIdToFileNames.put(uas.Opportunity__r.ContractId,new List<String>{fileName});
            }
        }
        return parentIdToFileNames;
    }

    private Map<Id,Id> getDocumentIds(Id assignmentAgreementId, String docType){
        Set<Id> parentRecordIds = new Set<Id>();
        List<ContentDocumentLink> docLinks;
        Map<Id,Id> versionIdToParentId = new Map<Id, Id>();

        if (docType == CUSTOMER_AGREEMENT || docType == DISCLOSURE){
            List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(assignmentAgreementId);
            for (Contract contract : contracts){
                parentRecordIds.add(contract.Id);
            }
        } else if (docType == CREDIT_REPORT) {
            List<Opportunity> oppList = oppSelector.getCustomerOpportunitiesByAssignmentAgreement(assignmentAgreementId);
            for (Opportunity opp : oppList) {
                if (opp.Personal_Credit_Report2__c != null) {
                    parentRecordIds.add(opp.Personal_Credit_Report2__c);
                }
            }
        }
        if (parentRecordIds.size() > 0) {
            docLinks = contentDocumentSelector.selectByLinkedEntitiesWithoutData(parentRecordIds);
            versionIdToParentId = compareFileNameAndType(docLinks,docType);
            checkForMissingFiles(parentRecordIds, versionIdToParentId);
        }
        return versionIdToParentId;
    }

    private Map<Id,Id> compareFileNameAndType(List<ContentDocumentLink> docLinks, String docType){
        Map<Id,Id> versionIdToParentId = new Map<Id,Id>();
        for (ContentDocumentLink link : docLinks){
            Boolean customerAgreement = docType == CUSTOMER_AGREEMENT  && link.ContentDocument.LatestPublishedVersion.Title.contains('Agreement');
            Boolean disclosure = docType == DISCLOSURE && link.ContentDocument.LatestPublishedVersion.Title.contains('Disclosure');
            Boolean creditReport = docType == CREDIT_REPORT;
            if (customerAgreement || disclosure || creditReport){
                versionIdToParentId.put(link.ContentDocument.LatestPublishedVersionId, link.LinkedEntityId);
            }
        }
        return versionIdToParentId;
    }

    private void checkForMissingFiles(Set<Id> parentRecordIds, Map<Id,Id> versionIdToParentId){
        Set<Id> parentIdsWithFiles = new Set<Id>();
        Set<Id> parentIdsWithoutFiles = new Set<Id>();

        for (Id linkedRecord : versionIdToParentId.values()){
            parentIdsWithFiles.add(linkedRecord);
        }
        for (Id parentRecordId : parentRecordIds){
            if (!parentIdsWithFiles.contains(parentRecordId)){
                parentIdsWithoutFiles.add(parentRecordId);
            }
        }
        Logger.logNow(
            'ClientFileCopierService',
            'checkForMissingFiles',
            'No File Found For Opportunity or Contracts: ' + JSON.serialize(parentIdsWithoutFiles)
        );
    }

    private Id createSupportingDocumentsFolder(Id assignmentAgreementId, String docType){
        Supporting_Document_Folder__c folder = new Supporting_Document_Folder__c(
            Type__c = docType + 's',
            Assignment_Agreement__c = assignmentAgreementId
        );
        insert folder;
        return folder.Id;
    }

    private Id startBatchCloneJob(Map<Id,Id> versionIdToParentId, Id newFolderId, Map<Id,List<String>> parentIdToFileNames){
        BatchClientFileCopierService batchJob = new BatchClientFileCopierService(versionIdToParentId,newFolderId, parentIdToFileNames);
        if (Test.isRunningTest()){
            // Don't have to worry about data storage of big files during tests, but only want to call it once:
            return Database.executeBatch(batchJob,200);
        } else {
            return Database.executeBatch(batchJob,1);
        }
    }

    public List<ContentVersion> cloneFiles(List<Id> scopeIds, Map<Id,Id> versionIdToParentId, Map<Id,List<String>> parentIdToFileNames){
        Map<Id,ContentVersion> filesWithData = contentVersionSelector.selectByIdWithData(versionIdToParentId.keySet());
        List<ContentVersion> clonedFilesToInsert = new List<ContentVersion>();

        // parentId is a PCR or Contract Id, depending on the document type.
        // fileNames is the list of file names to create, generated from a list of UASes. 1 fileName per UAS
        for (Id versionId : scopeIds){
            Id parentId = versionIdToParentId.get(versionId);
            List<String> fileNames = parentIdToFileNames.get(parentId);
            ContentVersion file = filesWithData.get(versionId);
            if (fileNames != null && file != null){
                for (String fileName : fileNames){
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