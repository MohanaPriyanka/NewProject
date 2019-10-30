@isTest
public without sharing class SLPQuickSalesSheetTest{
    @IsTest(SeeAllData=true)
    static void createQssAndLink() {
    Partner__c partnerOne = new Partner__c(Name = 'Account One',
                                          Logo__c = 'PartnerFile');
    insert partnerOne;  

    BSST__c salesRep = new BSST__c(Name = 'Salesguy', 
                                    Partner__c = partnerOne.Id, 
                                    Custom_ID__c = 'test', 
                                    Email__c = 'salesguy@Sales.com');
    insert salesRep;                           

    Account accountOne = new Account(Name = 'Account One',
                                    State_Market__c = 'NC;SC');
    insert accountOne;
                            
    Contact con = new Contact(FirstName = 'First',
                                    Email = 'bw421356@test.com',
                                    LastName = 'Last',
                                    AccountId = accountOne.Id, 
                                    Partner_Lookup__c = partnerOne.id,
                                    Sales_Representative__c = salesRep.id,
                                    Active_Communities_User__c = true);
    insert con;
      
    Profile partnerProfile = 
              [SELECT Id from Profile WHERE Name = 'Partner Community User (Custom)'];
                                    
    User communityUser = new User ( ProfileId = partnerProfile.Id,
                                   FirstName = 'Test',
                                   LastName = 'SLPQuickSalesSheet',
                                   Username = 'bw421356@test.com',
                                   Email = 'bw421356@test.com',
                                   Alias = 'bfg_usr',
                                   ContactId = con.Id,
                                   CommunityNickname = 'SLPQuickSalesSheet',
                                   TimeZoneSidKey = 'America/New_York',
                                   LocaleSidKey = 'en_US',
                                   EmailEncodingKey = 'ISO-8859-1',
                                   LanguageLocaleKey = 'en_US');
    Util.insertSObj(communityUser);
       
    Product2 productRecord = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                  Family = 'Solar Loan',
                                                  Product_Type__c = 'Residential Loan',
                                                  State__c = 'NC',
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
        Quick_Sales_Sheet__c qssLoanTable = new Quick_Sales_Sheet__c (System_Cost__c = 40000,
                                                                      Down_Payment__c = 3000,
                                                                      Product__c = productRecord.Id);
        Boolean generateDoc = false;
        SLPQuickSalesSheetHandler.addNewQSS(qssLoanTable, generateDoc);
        SLPQuickSalesSheetHandler.updateQSS(qssLoanTable, true, false);

        SLPQuickSalesSheetHandler.getActiveProducts();
        generateDoc = true;
        Quick_Sales_Sheet__c qssnew = new Quick_Sales_Sheet__c (System_Cost__c = 40000,
                                                                Down_Payment__c = 2000,
                                                                Product__c = productRecord.Id);
        SLPQuickSalesSheetHandler.addNewQSS(qssnew, generateDoc);
      }

      // Conga runs as a System Admin
      ContentVersion salesDocCV = new ContentVersion (Title ='Loan Summary Sheet.pdf',
                                                      PathOnClient='/Loan Summary Sheet.pdf' );
      salesDocCV.VersionData = Blob.valueOf('This is the body of the pdf');
      Util.insertSObj(salesDocCV);
      ContentVersion testContent = [SELECT ContentDocumentId 
                                    FROM ContentVersion 
                                    WHERE Id = :salesDocCV.Id]; 

      Quick_Sales_Sheet__c qssInserted = [SELECT Id, Loan_Amount__c, Finance_Charge__c 
                                          FROM Quick_Sales_Sheet__c 
                                          WHERE Down_Payment__c = 2000
                                          AND Product__c = : productRecord.Id];

      ContentDocumentLink newLink = new ContentDocumentLink ( ContentDocumentId = testContent.ContentDocumentId,
                                                              LinkedEntityId = qssInserted.Id,
                                                              ShareType = 'V' );
      insert newLink;
      List<ContentDistribution> distList = [SELECT Name, ContentVersionId
                                            FROM ContentDistribution];

      Quick_Sales_Sheet__c qssUpdated = [SELECT Id, Link_to_File__c, Partner_Logo_File_Name__c, Loan_Amount__c, Finance_Charge__c 
                                          FROM Quick_Sales_Sheet__c 
                                          WHERE Id = : qssInserted.Id];

      system.AssertNotEquals('notgenerated', qssUpdated.Link_to_File__c);
      system.AssertNotEquals(0, distList.size());
      system.AssertEquals('PartnerFile', qssUpdated.Partner_Logo_File_Name__c);

      // Community User finds the link
      System.runAs(communityUser){
        SLPQuickSalesSheetHandler.getQuickSalesSheet(qssUpdated.Id);
      }
      Test.stopTest();  
  }
}