/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class creates a a public link when a Quick Sales Sheet file is inserted
 + *
 + * ContentVersion is child of ContentDocument (for every doc, multiple versions)
 + * ContentDistribution is child of ContentVersion and generates a public url (used in community)
 + * ContentDocumentLink is a child of ContentDocument and controls what records a doc is linked to (QSS Record)
 + * 
 + * Tested By: SLPQuickSalesSheetTestclass and BatchCSBillEmailHandlerTestclass
 + *************************************************************************************/


public without sharing class FileDeliveryHandler {

    public static void createDistribution (List<ContentVersion> newContent) {
        List<ContentDistribution> distList = new List<ContentDistribution> ();
            
        Date todaysDate = System.Today();
        Date expyDate = todaysDate.addDays(15);

        for (ContentVersion cont : newContent){
          if (cont.Title == 'Loan Summary Sheet.pdf') {
            ContentDistribution cd = new ContentDistribution();
            cd.Name = 'Loan Summary Sheet.pdf';
            cd.ContentVersionId = cont.id;
            cd.PreferencesAllowOriginalDownload = true;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesAllowPdfDownload = true;
            cd.ExpiryDate = expydate;
            cd.PreferencesExpires = true; 
            distList.add(cd); 
          } else if (cont.Title == 'Community Solar Bill.pdf') {
            ContentDistribution cd = new ContentDistribution();
            cd.Name = 'Community Solar Bill';
            cd.ContentVersionId = cont.id;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesAllowPdfDownload = true;
            cd.PreferencesExpires = false; 
            distList.add(cd); 
          }
        }       
        insert distList;  
    }

    public static void findRelatedObject (List<ContentDocumentLink> newShare) {
        List<String> documentObjectList = new List<String>();
        Map<Id, Id> idToObjectMap = new Map<Id, Id>();
        Map<Id, String> disABMap = new Map<Id, String>(); // Account Bill Id, url to File
        Map<Id, String> disQSSMap = new Map<Id, String>();  // Sales Sheet Id, url to File

        for ( ContentDocumentLink link : newShare ){
            documentObjectList.add(link.ContentDocumentId);
            idToObjectMap.put(link.ContentDocumentId, link.LinkedEntityId); 
        }

        for ( ContentDistribution distribution : [  SELECT Name, Id, DistributionPublicUrl, ContentDocumentId
                                                    FROM ContentDistribution
                                                    WHERE ContentDocumentId IN : documentObjectList] ) {
            if (distribution.Name == 'Community Solar Bill') {
                disABMap.put(idToObjectMap.get(distribution.ContentDocumentId), distribution.DistributionPublicUrl);
            } else if (distribution.Name == 'Loan Summary Sheet.pdf') {
                disQSSMap.put(idToObjectMap.get(distribution.ContentDocumentId), distribution.DistributionPublicUrl);
            }
        }
        if (disABMap.size() > 0) {
            updateAccountBill(disABMap);
        } 
        if (disQSSMap.size() > 0){
            updateQuickSalesSheet(disQSSMap);
        }
    }

    public static void updateAccountBill (Map<Id, String> disABMap){
        Map<Id, Account_Bill__c> accountBillMap = new Map<Id, Account_Bill__c>();
        for (Account_Bill__c accountBill : [SELECT Name, Id, Link_to_File__c
                                            FROM Account_Bill__c
                                            WHERE Id IN : disABMap.keySet()] ) {
          accountBillMap.put(accountBill.Id, accountBill);
        }

        if (accountBillMap.size() > 0) {
            for (Id acctBillID : disABMap.keySet()) {
                accountBillMap.get(acctBillID).Link_to_File__c = disABMap.get(acctBillID); 
            }
            update accountBillMap.values();
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