@isTest
public without sharing class SLPQuickSalesSheetTest{
  @isTest static void createQssAndLink() {
    Account accountOne = new Account(Name = 'Account One');
    insert accountOne;
                            
    Contact con = new Contact(FirstName = 'First',
                                    Email = 'user@bluewave-capital.com',
                                    LastName = 'Last',
                                    AccountId = accountOne.Id, 
                                    Active_Communities_User__c = true);
    insert con;
      
    Profile partnerProfile = 
              [SELECT Id from Profile WHERE Name = 'Partner Community User (Custom)'];
                                    
    User communityUser = new User ( ProfileId = partnerProfile.Id,
                                   FirstName = 'Test',
                                   LastName = 'BFG_User',
                                   Username = 'communityuser@test.com',
                                   Email = 'communityuser@test.com',
                                   Alias = 'bfg_usr',
                                   ContactId = con.Id,
                                   CommunityNickname = 'bfg_usr',
                                   TimeZoneSidKey = 'America/New_York',
                                   LocaleSidKey = 'en_US',
                                   EmailEncodingKey = 'ISO-8859-1',
                                   LanguageLocaleKey = 'en_US');
    insert communityUser;
       
    Product2 productRecord = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                  Family = 'Solar Loan',
                                                  Product_Type__c = 'Residential Loan',
                                                  State__c = 'MA',
                                                  Loan_Interest_Rate__c = 5.99,
                                                  Loan_Term__c = 120,
                                                  Loan_Interest_Only_Period__c = 12,
                                                  Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                  Technology_Platform_Fee__c = 7,
                                                  Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                  ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                  Loan_base_rate__c = .0625,
                                                  Loan_Internal_Lender_rate__c = .0499,
                                                  Credit_Maximum__c = '999',
                                                  Credit_Minimum__c = '750',
                                                  Loan_Tranche_Type__c = 'Standard',
                                                  Program__c = 'BlueWave Solar Loan',
                                                  isActive = TRUE);
    insert productRecord;
                                   
    Test.startTest();          
      // Community User makes the QSS
      System.runAs(communityUser){
        SLPQuickSalesSheetHandler.getActiveProducts();
        Quick_Sales_Sheet__c qssnew = new Quick_Sales_Sheet__c (Loan_Principal__c = 40000,
                                                                Product__c = productRecord.Id);
        SLPQuickSalesSheetHandler.addNewQSS(qssnew);
      }

      // Conga runs as a System Admin
      ContentVersion salesDocCV = new ContentVersion (Title ='Quick Sales Sheet',
                                                      PathOnClient='/Quick Sales Sheet.pdf' );
      salesDocCV.VersionData = Blob.valueOf('This is the body of the pdf');
      insert salesDocCV;
      ContentVersion testContent = [SELECT ContentDocumentId FROM ContentVersion where Id = :salesDocCV.Id]; 
      Quick_Sales_Sheet__c qssInserted = [SELECT Id, Loan_Principal__c, Finance_Charge__c FROM Quick_Sales_Sheet__c];
      ContentDocumentLink newLink = new ContentDocumentLink ( ContentDocumentId = testContent.ContentDocumentId,
                                                              LinkedEntityId = qssInserted.Id,
                                                              ShareType = 'V' );
      insert newLink;
      List<ContentDistribution> distList = [SELECT Name, ContentVersionId
                                            FROM ContentDistribution];
      Quick_Sales_Sheet__c qssUpdated = [SELECT Id, Link_to_File__c, Loan_Principal__c, Finance_Charge__c FROM Quick_Sales_Sheet__c];
      system.AssertNotEquals('notgenerated', qssUpdated.Link_to_File__c);
      system.AssertNotEquals(0, distList.size());

      // Community User finds the link
      System.runAs(communityUser){
        SLPQuickSalesSheetHandler.getQuickSalesSheet(qssUpdated.Id);
      }
      Test.stopTest();  
  }
}