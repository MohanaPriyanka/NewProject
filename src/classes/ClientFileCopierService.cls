// Tested by ClientFileCopierServiceTest

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
    private static ContentVersionSelector mockedContentVersionSelector = new ContentVersionSelector();
    @TestVisible
    private static ContentVersionSelector contentVersionSelector = new ContentVersionSelector();

    public fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            ContentDocumentLink.SObjectType
        }
    );

    public enum FileType {
        CUSTOMERAGREEMENT,
        DISCLOSURE,
        CREDITREPORT
    }

    private String convertDocTypeToString(FileType docType){
        String typeAsString;
        switch on docType {
            when CUSTOMERAGREEMENT {
                typeAsString = 'Customer Agreement';
            }
            when DISCLOSURE {
                typeAsString = 'Customer Disclosure Form';
            }
            when CREDITREPORT {
                typeAsString = 'Customer Credit Report';
            }
        }
        return typeAsString;
    }

    private FileType convertStringToDocType(String typeAsString){
        FileType docType;
        switch on typeAsString {
            when 'CUSTOMERAGREEMENT' {
                docType = FileType.CUSTOMERAGREEMENT;
            }
            when 'DISCLOSURE' {
                docType = FileType.DISCLOSURE;
            }
            when 'CREDITREPORT' {
                docType = FileType.CREDITREPORT;
            }
            when else {
                throw new Util.BWException('Unsupported Document Type: ' + typeAsString);
            }
        }
        return docType;
    }

    @InvocableMethod(
        Label='InvocableClientFileCopier'
        Description='Takes list of 2 strings as parameters: AssignmentAgreementId and FileType (CUSTOMERAGREEMENT, DISCLOSURE, CREDITREPORT)'
    )
    public static List<Id> invocableFindAndCloneDocuments (List<List<String>> parameters){
        ClientFileCopierService service = new ClientFileCopierService();
        FileType docType = service.convertStringToDocType(parameters[0][1]);
        Id batchJobId = service.findAndCloneDocuments((Id)parameters[0][0],docType);
        return new List<Id>{batchJobId};
    }

    public Id findAndCloneDocuments(Id assignmentAgreementId, FileType docType){
        Id folderId = createSupportingDocumentsFolder(assignmentAgreementId, docType);
        Map<Id,Id> versionIdToParentId = getDocumentIds(assignmentAgreementId, docType);
        Map<Id,List<String>> parentIdToFileNames = getFileNames(assignmentAgreementId, docType);
        return startBatchCloneJob(versionIdToParentId,folderId,parentIdToFileNames);
    }

    private Map<Id,List<String>> getFileNames(Id assignmentAgreementId, FileType docType){
        Map<Id,List<String>> parentIdToFileNames = new Map<Id,List<String>>();
        List<Utility_Account_Subscription__c> uases = uasSelector.getUASesForAssignmentAgreement(assignmentAgreementId);
        String docTypeAsString = convertDocTypeToString(docType);

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

    private Map<Id,Id> getDocumentIds(Id assignmentAgreementId, FileType docType){
        Set<Id> parentRecordIds = new Set<Id>();
        List<ContentDocumentLink> docLinks;

        if (docType == FileType.CUSTOMERAGREEMENT || docType == FileType.DISCLOSURE){
            List<Contract> contracts = contractSelector.getCustomerContractsByAssignmentAgreement(assignmentAgreementId);
            for (Contract contract : contracts){
                parentRecordIds.add(contract.Id);
            }
        } else if (docType == FileType.CREDITREPORT) {
            List<Opportunity> oppList = oppSelector.getCustomerOpportunitiesByAssignmentAgreement(assignmentAgreementId);
            for (Opportunity opp : oppList) {
                parentRecordIds.add(opp.Personal_Credit_Report2__c);
            }
        }
        docLinks = contentDocumentSelector.selectByLinkedEntitiesWithoutData(parentRecordIds);
        return compareFileNameAndType(docLinks,docType);
    }

    private Map<Id,Id> compareFileNameAndType(List<ContentDocumentLink> docLinks, FileType docType){
        Map<Id,Id> versionIdToParentId = new Map<Id,Id>();
        for (ContentDocumentLink link : docLinks){
            Boolean customerAgreement = docType == FileType.CUSTOMERAGREEMENT && link.ContentDocument.LatestPublishedVersion.Title.contains('Agreement');
            Boolean disclosure = docType == FileType.DISCLOSURE && link.ContentDocument.LatestPublishedVersion.Title.contains('Disclosure');
            Boolean creditReport = docType == FileType.CREDITREPORT;
            if (customerAgreement || disclosure || creditReport){
                versionIdToParentId.put(link.ContentDocument.LatestPublishedVersionId, link.LinkedEntityId);
            }
        }
        return versionIdToParentId;
    }

    private Id createSupportingDocumentsFolder(Id assignmentAgreementId, FileType docType){
        String typeAsString = convertDocTypeToString(docType);
        Supporting_Document_Folder__c folder = new Supporting_Document_Folder__c(
            Type__c = typeAsString + 's',
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
        Map<Id,ContentVersion> filesWithData = mockedContentVersionSelector.selectByIdWithData(versionIdToParentId.keySet());
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
            PathOnClient = '/' + fileName
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
}