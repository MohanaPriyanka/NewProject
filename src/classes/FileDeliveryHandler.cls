/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class creates a a public link when a Quick Sales Sheet file is inserted
 + *
 + * ContentVersion is child of ContentDocument (for every doc, multiple versions)
 + * ContentDistribution is child of ContentVersion and generates a public url (used in community)
 + * ContentDocumentLink is a child of ContentDocument and controls what records a doc is linked to (QSS Record)
 + * 
 + * Tested By: SLPQuickSalesSheetTest
 + *************************************************************************************/

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class FileDeliveryHandler {
  
  public static void findRelatedObject (List<ContentDocumentLink> newShare) {
        List<String> documentObjectList = new List<String>();
        Map<Id, Id> idToObjectMap = new Map<Id, Id>();
        Map<Id, String> disQSSMap = new Map<Id, String>();  // Sales Sheet Id, url to File

        for ( ContentDocumentLink link : newShare ){
            documentObjectList.add(link.ContentDocumentId);
            idToObjectMap.put(link.ContentDocumentId, link.LinkedEntityId); 
        }

        for (ContentDistribution distribution : [  SELECT Name, Id, DistributionPublicUrl, ContentDocumentId
                                                    FROM ContentDistribution
                                                    WHERE ContentDocumentId IN : documentObjectList] ) {
            if (distribution.Name == 'Loan Summary Sheet.pdf') {
                disQSSMap.put(idToObjectMap.get(distribution.ContentDocumentId), distribution.DistributionPublicUrl);
            }
        }
        
        if (disQSSMap.size() > 0){
            updateQuickSalesSheet(disQSSMap);
        }
    }

    public static void updateQuickSalesSheet (Map<Id, String> disQSSMap) {
        Map<Id, Quick_Sales_Sheet__c> salesSheetMap = new Map<Id, Quick_Sales_Sheet__c>();
        for (Quick_Sales_Sheet__c salesSheet : [SELECT Name, Id, Link_to_File__c
                                                FROM Quick_Sales_Sheet__c
                                                WHERE Id IN : disQSSMap.keySet()] ) {
          salesSheetMap.put(salesSheet.Id, salesSheet);
        }

        if (salesSheetMap.size() > 0) {
            for (Id qssId : disQSSMap.keySet()) {
                salesSheetMap.get(qssId).Link_to_File__c = disQSSMap.get(qssId); 
            }
            update salesSheetMap.values();
        }
    }
}