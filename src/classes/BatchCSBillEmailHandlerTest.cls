@isTest
private class BatchCSBillEmailHandlerTest {
    // Can't use @testSetup since we need to use SeeAllData=true to exercise CommunityAPI. Otherwise, we get:
    // System.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
    private static void setupTestData(){
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


        Contact contactTwo = new Contact (  FirstName = 'First',
                                            LastName = 'Second',
                                            AccountId = parentAccount.Id,
                                            Email = 'pentalerij@gmail.com');
        insert contactTwo;

        propertyAccount.Send_Bills_Contact__c = contactOne.Id;
        propertyAccount.Additional_Contact__c = contactTwo.Id;
        update propertyAccount;

        for (i=0;i<9;i++) {
            Account_Bill__c abOne = new Account_Bill__c (
                                        Name = 'Bill' + i,
                                        Bill_Number__c = i,
                                        Parent_Account__c = propertyAccount.Id,
                                        Ready_for_Email_Send__c = true,
                                        Published__c = false);
            abList.add(abOne);
        }
        insert abList;
    }

    @IsTest(SeeAllData=true)
    static void testSendEmails () {
        setupTestData();
        Test.StartTest();

        InvocableCSBillEmailBatchSend.sendEmails();

        Test.StopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id =: BatchCSBillEmailHandler.batchJobId
        ];

        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals('Completed', job.Status);
        System.assertEquals(1, job.TotalJobItems);
        // There might be more than 9 emails since SeeAllData is true
        System.assertEquals(true, MessagingService.emailsSent.size() >= 9);
    }

    @isTest
    static void testAccountBillsPublishedWithoutEmails() {
        List<Account_Bill__c> abList = new List<Account_Bill__c>();

        Account parentAccount = new Account ( Name = 'Parent Account');
        insert parentAccount;

        Account propertyAccount = new Account ( Name = 'Property Account',
            Parent_Account__c = parentAccount.Id);
        insert propertyAccount;

        Contact contactOne = new Contact (  FirstName = 'First',
            LastName = 'Last',
            AccountId = parentAccount.Id);
        insert contactOne;


        Contact contactTwo = new Contact (  FirstName = 'First',
            LastName = 'Second',
            AccountId = parentAccount.Id,
            Email = 'pentalerij@gmail.com');
        insert contactTwo;

        propertyAccount.Send_Bills_Contact__c = contactOne.Id;
        propertyAccount.Additional_Contact__c = contactTwo.Id;
        update propertyAccount;

        TestFactory.insertBWAddress();

        for (Integer i=0;i<9;i++) {
            Account_Bill__c abOne = new Account_Bill__c (
                Name = 'Bill' + i,
                Bill_Number__c = i,
                Parent_Account__c = propertyAccount.Id,
                Ready_for_Email_Send__c = true,
                Published__c = false);
            abList.add(abOne);
        }
        insert abList;
        Set<Id> abIds = new Set<Id>{};
        for (Account_Bill__c accountBill : abList) {
            abIds.add(accountBill.Id);
        }

        Test.StartTest();

        InvocableCSBillEmailBatchSend.sendEmails();

        Test.StopTest();

        List<Account_Bill__c> accountBills = [
            SELECT Id, Published__c, Ready_for_Email_Send__c
            FROM Account_Bill__c
            WHERE Id IN : abIds
        ];

        for (Account_Bill__c accountBill : accountBills) {
            System.assert(accountBill.Published__c);
        }
    }

    @IsTest(SeeAllData=true)
    static void testCreateLink() {
        setupTestData();
        Test.startTest();
        ContentVersion csBillCV = new ContentVersion (Title ='Cole\'s Coffee August 2017 Community Solar Bill.pdf',
                                                      PathOnClient='/Community Solar Bill.pdf' );
        csBillCV.VersionData = Blob.valueOf('This is the body of the pdf');
        Util.insertSObj(csBillCV);
        ContentVersion testContent = [  SELECT ContentDocumentId 
                                        FROM ContentVersion 
                                        WHERE Id = : csBillCV.Id]; 

        Account_Bill__c accountBill = [
            SELECT Id, Name
            FROM Account_Bill__c
            WHERE Bill_Number__c != NULL
            LIMIT 1
        ];

        ContentDocumentLink newLink = new ContentDocumentLink ( ContentDocumentId = testContent.ContentDocumentId,
                                                                LinkedEntityId = accountBill.Id,
                                                                ShareType = 'V' );
        insert newLink;
        Test.stopTest();

        Account_Bill__c abUpdated = [   SELECT Id, Bill_Attach_Version__c, Bill_Attach_Document__c
                                        FROM Account_Bill__c 
                                        WHERE Id = : accountBill.Id];
        System.assertNotEquals('', abUpdated.Bill_Attach_Version__c);
        System.assertNotEquals('', abUpdated.Bill_Attach_Document__c);
    }

}