/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class creates a a public link when a Quick Sales Sheet file is inserted
 + *
 + * ContentVersion is child of ContentDocument (for every doc, multiple versions)
 + * ContentDistribution is child of ContentVersion and generates a public url (used in community)
 + * ContentDocumentLink is a child of ContentDocument and controls what records a doc is linked to (QSS Record)
 + * 
 + * Tested By: SLPQuickSalesSheetTestclass
 + *************************************************************************************/


public without sharing class FileDeliveryHandler {

  public static void createDistribution (List<ContentVersion> newContent) {
    List<ContentDistribution> distList = new List<ContentDistribution> ();
        
    Date todaysDate = System.Today();
    Date expyDate = todaysDate.addDays(15);

    for (ContentVersion cont : newContent){
      if (cont.Title == 'Loan Summary Sheet.pdf') {
        ContentDistribution cd = new ContentDistribution();
        cd.Name = cont.Title;
        cd.ContentVersionId = cont.id;
        cd.PreferencesAllowOriginalDownload = true;
        cd.PreferencesAllowViewInBrowser = true;
        cd.PreferencesAllowPdfDownload = true;
        cd.ExpiryDate = expydate;
        cd.PreferencesExpires = true; 
        distList.add(cd); 
      }
    }       
    insert distList;  
  }

  public static void findRelatedObject (List<ContentDocumentLink> newShare) {
    Map<Id, Id> qssToContentMap = new Map<Id, Id>();
    Map<Id, Quick_Sales_Sheet__c> qssMap = new Map<Id, Quick_Sales_Sheet__c>();
    List<Id> qssIdList = new List<Id>();

    for (ContentDocumentLink contentdoc : newShare) {
      qssToContentMap.put(contentdoc.ContentDocumentId, contentdoc.LinkedEntityId);
      qssIdList.add(contentdoc.LinkedEntityId);
    }  
    system.debug(qssIdList);
    system.debug(qssToContentMap);
    for (Quick_Sales_Sheet__c qss  : [  SELECT Name, Id, Link_to_File__c
                                        FROM Quick_Sales_Sheet__c
                                        WHERE Id IN : qssIdList ] ) {
      qssMap.put(qss.Id, qss);
    }
    if (qssMap.size() > 0) {
        system.debug(qssMap);
        for (ContentDistribution distList : [SELECT Name, Id, DistributionPublicUrl, ContentDocumentId
                                          FROM ContentDistribution
                                          WHERE ContentDocumentId IN : qssToContentMap.keySet()] ) {
          qssMap.get(qssToContentMap.get(distList.ContentDocumentId)).Link_to_File__c = distList.DistributionPublicUrl; 
        }
        system.debug(qssMap);
        update qssMap.values();
    }
  }
}