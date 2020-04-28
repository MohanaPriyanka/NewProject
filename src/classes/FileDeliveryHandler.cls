/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class creates a a public link when a Quick Sales Sheet file is inserted
 + *
 + * ContentVersion is child of ContentDocument (for every doc, multiple versions)
 + * ContentDistribution is child of ContentVersion and generates a public url (used in community)
 + * ContentDocumentLink is a child of ContentDocument and controls what records a doc is linked to (QSS Record)
 + * 
 + * Tested By: SLPQuickSalesSheetTest and BatchCSBillEmailHandlerTestclass and SimpleSignupFormControllerTest (lines 51-64)
 + *************************************************************************************/


public without sharing class FileDeliveryHandler {

  public static void createDistribution (List<ContentVersion> newContent) {
      List<ContentDistribution> distList = new List<ContentDistribution> ();
      List<ContentDocumentLink> linkToCommList = new List<ContentDocumentLink> ();

      Date todaysDate = System.today();
      Date expyDate = todaysDate.addDays(15);
      String communityID;

      for (ContentVersion cont : newContent) {
          if (cont.Title.contains('Community Solar Bill')) {
              try {
                  ConnectApi.CommunityPage comm = ConnectApi.Communities.getCommunities();
                  for (ConnectApi.Community community : comm.communities) {
                      if (community.name == 'BlueWave Member Portal') {
                          communityID = community.id;
                      }
                  }
              } catch (ConnectApi.ConnectApiException cae) {
                  Logger.logNow('FileDeliveryHandler', 'createDistribution',
                      cae.getMessage() + ' caught when inserting:' +
                      'Title: ' + cont.Title + ' FileType: ' + cont.FileType + ' Description: ' + cont.Description);
              }
              break;
          }
      }
      for (ContentVersion cont : newContent){
          if (cont.Title == 'Loan Summary Sheet.pdf') {
              ContentDistribution cd = new ContentDistribution();
              cd.Name = cont.Title;
              cd.ContentVersionId = cont.Id;
              cd.PreferencesAllowOriginalDownload = true;
              cd.PreferencesAllowViewInBrowser = true;
              cd.PreferencesAllowPDFDownload = true;
              cd.ExpiryDate = expyDate;
              cd.PreferencesExpires = true;
              distList.add(cd);
          } else if(cont.Title == 'Community Solar Agreement.pdf' || cont.Title == 'Solar Disclosure Form.pdf') {
            distList.add(new ContentDistribution(
                Name = cont.Title,
                ContentVersionId = cont.Id,
                ExpiryDate = System.today().addDays(10),
                PreferencesAllowOriginalDownload = false,
                PreferencesAllowPDFDownload = false,
                PreferencesAllowViewInBrowser = true,
                PreferencesExpires = true,
                PreferencesLinkLatestVersion = true,
                PreferencesNotifyOnVisit = false,
                PreferencesNotifyRndtnComplete = false,
                PreferencesPasswordRequired = false
            ));
          } else if (cont.Title.contains('Community Solar Bill')) {
              ContentDocumentLink cdl = new ContentDocumentLink();
              cdl.LinkedEntityId = communityID;
              cdl.Visibility = 'AllUsers';
              cdl.ShareType = 'V';
              cdl.ContentDocumentId = cont.ContentDocumentId;
              linkToCommList.add(cdl);
          }
      }
      if (distList.size() > 0) {
          insert distList;
      }
      if (linkToCommList.size() > 0) {
          insert linkToCommList;
      }
  }
  
  public static void findRelatedObject (List<ContentDocumentLink> newShare) {
        List<String> documentObjectList = new List<String>();
        Map<Id, Id> idToObjectMap = new Map<Id, Id>();
        Map<Id, ContentVersion> disABMap = new Map<Id, ContentVersion>(); // Account Bill Id, url to File
        Map<Id, String> disQSSMap = new Map<Id, String>();  // Sales Sheet Id, url to File

        for ( ContentDocumentLink link : newShare ){
            documentObjectList.add(link.ContentDocumentId);
            idToObjectMap.put(link.ContentDocumentId, link.LinkedEntityId); 
        }

        for (ContentVersion file : [  SELECT Title, Id, ContentDocumentId
                                        FROM ContentVersion
                                        WHERE ContentDocumentId IN : documentObjectList] ) {
            if (file.Title.contains('Community Solar Bill')) {
                disABMap.put(idToObjectMap.get(file.ContentDocumentId), file);
            }
        }

        for (ContentDistribution distribution : [  SELECT Name, Id, DistributionPublicUrl, ContentDocumentId
                                                    FROM ContentDistribution
                                                    WHERE ContentDocumentId IN : documentObjectList] ) {
            if (distribution.Name == 'Loan Summary Sheet.pdf') {
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

  public static void updateAccountBill (Map<Id, ContentVersion> disABMap){
        Map<Id, Account_Bill__c> accountBillMap = new Map<Id, Account_Bill__c>();
        for (Account_Bill__c accountBill : [SELECT Name, Id, Bill_Attach_Document__c,
                                            Bill_Attach_Version__c
                                            FROM Account_Bill__c
                                            WHERE Id IN : disABMap.keySet()] ) {
          accountBillMap.put(accountBill.Id, accountBill);
        }

        if (accountBillMap.size() > 0) {
            for (Id acctBillID : disABMap.keySet()) {
                accountBillMap.get(acctBillID).Bill_Attach_Version__c = disABMap.get(acctBillID).Id; 
                accountBillMap.get(acctBillID).Bill_Attach_Document__c = disABMap.get(acctBillID).ContentDocumentId; 
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