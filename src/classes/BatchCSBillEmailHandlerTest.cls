@isTest
private class BatchCSBillEmailHandlerTest {

    @testSetup public static void setupTestData(){
        Integer i;
        List<Account_Bill__c> abList = new List<Account_Bill__c>();
        
        Account parentAccount = new Account ( Name = 'Parent Account');
        insert parentAccount;

        Account propertyAccount = new Account ( Name = 'Property Account',
                                                Parent_Account__c = parentAccount.Id);
        insert propertyAccount;

        Contact contactOne = new Contact (  FirstName = 'First',
                                            LastName = 'Last',
                                            AccountId = parentAccount.Id,
                                            Email = 'jpentaleri@bluewavesolar.com');
        insert contactOne;

        propertyAccount.Send_Bills_Contact__c = contactOne.Id;
        update propertyAccount;
        
        for (i=0;i<50;i++) {
            Account_Bill__c abOne = new Account_Bill__c (   
                                        Name = 'Bill' + i,
                                        Parent_Account__c = propertyAccount.Id,
                                        Ready_for_Email_Send__c = true,
                                        Link_to_File__c = 'https://bluewavesolar.com',
                                        Published__c = false);
            abList.add(abOne);
        }
        insert abList;  
    }

    static testMethod void testSendEmails () {
        Test.StartTest();
            BatchCSBillEmailHandler uca = new BatchCSBillEmailHandler ();
            Id batchId = Database.executeBatch(uca, 50);
        Test.StopTest();

        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = : batchId];

        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals('Completed', job.Status);
        System.assertEquals(1, job.TotalJobItems);
    }

    static testMethod void testCreateLink () {
        Test.StartTest();
        ContentVersion csBillCV = new ContentVersion (Title ='Community Solar Bill.pdf',
                                                      PathOnClient='/Community Solar Bill.pdf' );
        csBillCV.VersionData = Blob.valueOf('This is the body of the pdf');
        insert csBillCV;
        ContentVersion testContent = [  SELECT ContentDocumentId 
                                        FROM ContentVersion 
                                        WHERE Id = : csBillCV.Id]; 

        Account_Bill__c accountBill = [  SELECT Id, Name, Link_to_File__c
                                          FROM Account_Bill__c LIMIT 1];

        ContentDocumentLink newLink = new ContentDocumentLink ( ContentDocumentId = testContent.ContentDocumentId,
                                                                LinkedEntityId = accountBill.Id,
                                                                ShareType = 'V' );
        insert newLink;
        Test.StopTest();

        List<ContentDistribution> distList = [  SELECT Name, ContentVersionId
                                                FROM ContentDistribution];

        Account_Bill__c abUpdated = [   SELECT Id, Link_to_File__c 
                                        FROM Account_Bill__c 
                                        WHERE Id = : accountBill.Id];
        system.AssertNotEquals('', abUpdated.Link_to_File__c);
        system.AssertNotEquals(0, distList.size());
    }
}