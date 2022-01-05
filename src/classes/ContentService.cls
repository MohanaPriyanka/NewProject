/*
Created By: Jordan Pentaleri 1/23/20
Service for ContentDocument, ContentVersion and ContentDocumentLink actions
Tested by ContentServiceTest
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ContentService {
    public static ContentDocumentSelector documentSelector = new ContentDocumentSelector();


    @AuraEnabled
    public static void setCategoryOnContentVersion(List<Id> documentIdList, String category){
        Set<Id> documentIdSet = new Set<Id>(documentIdList);
        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        List<ContentDocument> contentDocuments = documentSelector.selectById(documentIdSet);
        for (ContentDocument document : contentDocuments){
            ContentVersion versionToUpdate = new ContentVersion(
                Id = document.LatestPublishedVersionId,
                File_Category__c = category
            );
            versionsToUpdate.add(versionToUpdate);
        }
        update versionsToUpdate;
    }


    public ContentDocumentLink uploadFileToRecordAndShareInternally(String fileBody, Id recordId, String fileName){
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = Blob.valueOf(fileBody),
            Title = fileName,
            PathOnClient = '/' + fileName
        );
        insert cv;

        Id contentDocId = documentSelector.getDocumentIdFromVersionId(cv.Id);

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = recordId;
        cdl.Visibility = 'InternalUsers';
        cdl.ShareType = 'V';
        cdl.ContentDocumentId = contentDocId;
        insert cdl;

        return cdl;
    }


    public void makeContentDocLinksPrivate(List<ContentDocument> cdList) {
        List<ContentDocumentLink> linkList = new List<ContentDocumentLink>();
        for(ContentDocument cd : cdList) {
            for(ContentDocumentLink link : cd.ContentDocumentLinks) {
                link.Visibility = 'InternalUsers';
                linkList.add(link);
            }
        }

        Util.updateAndLog(linkList, 'ContentService', 'makeContentDocLinksPrivate');
    }

    public static void createDistribution (List<ContentVersion> newContent) {
        List<ContentDistribution> distList = new List<ContentDistribution> ();
        for (ContentVersion cont : newContent){
            if(cont.Title == 'Community Solar Agreement.pdf' || cont.Title == 'Solar Disclosure Form.pdf') {
              distList.add(new ContentDistribution(
                  Name = cont.Title,
                  ContentVersionId = cont.Id,
                  ExpiryDate = System.today().addDays(ContentDocLinkPrivacyScheduler.minDaysInPast),
                  PreferencesAllowOriginalDownload = false,
                  PreferencesAllowPDFDownload = false,
                  PreferencesAllowViewInBrowser = true,
                  PreferencesExpires = true,
                  PreferencesLinkLatestVersion = true
              ));
            }
        }

        Util.insertAndLog(distList, 'ContentService', 'createDistribution');
    }

    /**
     * @description Sets Ready for Paper Bill Queue to true for CVs inserted with a Mail Type, assuming Conga creates
     * the ContentVersions and can only set one custom field (Mail Type). Used to automate sending Collections Letters
     * via Account.Conga_Letterstream_Delinquency__c.
     * @param oldMap Trigger.oldMap
     * @param newContentVersions Trigger.new
     */
    public static void setReadyForPaperBillQueue(Map<Id, ContentVersion> oldMap, List<ContentVersion> newContentVersions) {
        List<ContentVersion> newContentWithMailTypeSet = (List<ContentVersion>)
            new SObjectFilter(oldMap, newContentVersions, ContentVersion.Mail_Type__c, null, SObjectFilter.ANY_VALUE)
                .addFilterCriteria(ContentVersion.Added_to_Paper_Bill_Queue__c, SObjectFilter.NOT_EQUAL_TO, true)
                .get(SObjectFilter.SOBJECT_LIST);
        CollectionUtil.setField(newContentWithMailTypeSet, ContentVersion.Ready_for_Paper_Bill_Queue__c, true);
    }
}