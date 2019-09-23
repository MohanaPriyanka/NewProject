@isTest
public class ZuoraBillEmailHandlerTest {
    @TestSetup public static void setupTestData() {
        Account propertyAccountA = new Account(
            Name = 'Property Account A',
            Bill_Delivery_Preference__c = 'Email and Paper'
        );
        Account propertyAccountB = new Account(
            Name = 'Property Account B',
            Bill_Delivery_Preference__c = 'Email and Paper'
        );
        Account propertyAccountC = new Account(
            Name = 'Property Account C',
            Bill_Delivery_Preference__c = 'Email and Paper'
        );
        Account propertyAccountD = new Account(
            Name = 'Property Account D',
            Bill_Delivery_Preference__c = 'Email and Paper'
        );
        Account propertyAccountE = new Account(
            Name = 'Property Account E',
            Bill_Delivery_Preference__c = 'Email and Paper'
        );
        List<Account> properties = new List<Account>{
            propertyAccountA,
            propertyAccountB,
            propertyAccountC,
            propertyAccountD,
            propertyAccountE
        };
        insert properties;

        Contact contactA = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            Email = 'jpentaleri@bluewavesolar.com',
            AccountId = propertyAccountA.Id
        );
        Contact contactB = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            // Blank Email
            AccountId = propertyAccountB.Id
        );
        Contact contactC = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            Email = 'jpentaleri@bluewavesolar.com',
            AccountId = propertyAccountC.Id
        );
        Contact contactD = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            Email = 'jpentaleri@bluewavesolar.com',
            AccountId = propertyAccountD.Id
        );
        insert new List<Contact>{
            contactA, contactB, contactC, contactD
        };

        propertyAccountA.Send_Bills_Contact__c = contactA.Id;
        propertyAccountB.Send_Bills_Contact__c = contactB.Id;
        propertyAccountC.Send_Bills_Contact__c = contactC.Id;
        propertyAccountD.Send_Bills_Contact__c = contactD.Id;
        propertyAccountD.Additional_Contact__c = contactA.Id;
        // propertyAccountE does not have a Send Bills Contact
        update properties;

        Zuora__CustomerAccount__c acctA = new Zuora__CustomerAccount__c(
            Name = 'Billing Account A',
            Zuora__Account__c = propertyAccountA.Id
        );
        Zuora__CustomerAccount__c acctB = new Zuora__CustomerAccount__c(
            Name = 'Billing Account B',
            Zuora__Account__c = propertyAccountB.Id
        );
        Zuora__CustomerAccount__c acctC = new Zuora__CustomerAccount__c(
            Name = 'Billing Account C',
            Zuora__Account__c = propertyAccountC.Id
        );
        Zuora__CustomerAccount__c acctD = new Zuora__CustomerAccount__c(
            Name = 'Billing Account D',
            Zuora__Account__c = propertyAccountD.Id
        );
        Zuora__CustomerAccount__c acctE = new Zuora__CustomerAccount__c(
            Name = 'Billing Account E',
            Zuora__Account__c = propertyAccountE.Id
        );
        insert new List<Zuora__CustomerAccount__c>{
            acctA,
            acctB,
            acctC,
            acctD,
            acctE
        };

        Zuora__ZInvoice__c invoiceAA = new Zuora__ZInvoice__c(
            Name = 'INV-AA',
            Zuora__BillingAccount__c = acctA.Id,
            Ready_For_Email_Send__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Document_Content_Version_ID__c = null
        );
        Zuora__ZInvoice__c invoiceAB = new Zuora__ZInvoice__c(
            Name = 'INV-AB',
            Zuora__BillingAccount__c = acctA.Id,
            Ready_For_Email_Send__c = false,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceBA = new Zuora__ZInvoice__c(
            Name = 'INV-BA',
            Zuora__BillingAccount__c = acctB.Id,
            Ready_For_Email_Send__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceBB = new Zuora__ZInvoice__c(
            Name = 'INV-BB',
            Zuora__BillingAccount__c = acctB.Id,
            Ready_For_Email_Send__c = false,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceCA = new Zuora__ZInvoice__c(
            Name = 'INV-CA',
            Zuora__BillingAccount__c = acctC.Id,
            Ready_For_Email_Send__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceCB = new Zuora__ZInvoice__c(
            Name = 'INV-CB',
            Zuora__BillingAccount__c = acctC.Id,
            Ready_For_Email_Send__c = false,
            Ready_For_Paper_Bill_Queue__c = false,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceDA = new Zuora__ZInvoice__c(
            Name = 'INV-DA',
            Zuora__BillingAccount__c = acctD.Id,
            Ready_For_Email_Send__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        Zuora__ZInvoice__c invoiceEA = new Zuora__ZInvoice__c(
            Name = 'INV-EA',
            Zuora__BillingAccount__c = acctE.Id,
            Ready_For_Email_Send__c = true,
            Ready_For_Paper_Bill_Queue__c = true,
            Bill_Document_Content_Version_ID__c = 'file.Id'
        );
        insert new List<Zuora__ZInvoice__c>{
            invoiceAA,
            invoiceAB,
            invoiceBA,
            invoiceBB,
            invoiceCA,
            invoiceCB,
            invoiceDA,
            invoiceEA
        };
    }

    @isTest public static void testSendEmails() {
        List<Zuora__ZInvoice__c> invoicesToSend = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = true
        ];
        System.assertEquals(5,invoicesToSend.size());

        List<Zuora__ZInvoice__c> doNotSend = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = false
        ];
        System.assertEquals(3,doNotSend.size());

        Test.startTest();
        ZuoraBillEmailHandler billEmailer = new ZuoraBillEmailHandler();
        billEmailer.executeBatch();
        Test.stopTest();

        System.assertEquals(2, MessagingService.emailsSent.size());

        List<Case> casesCreated = [
            SELECT Id, Description, Subject, Account.Name
            FROM Case
        ];
        System.assertEquals(3, casesCreated.size());

        for (Case caseRecord : casesCreated){
            if (caseRecord.Account.Name == 'Property Account B'){
                System.assert(caseRecord.Subject.contains('no email was found on the Send Bills Contact'));
            } else if (caseRecord.Account.Name == 'Property Account E'){
                System.assert(caseRecord.Subject.contains('no email was found on the Send Bills Contact'));
            } else if (caseRecord.Account.Name == 'Property Account A'){
                System.assert(caseRecord.Subject.contains('because there was no pdf file'));
            } else {
                System.assert(false);
            }
        }

        List<Task> tasksCreated = [
            SELECT Id, Description
            FROM Task
        ];
        System.assertEquals(5, tasksCreated.size());

        List<Zuora__ZInvoice__c> updatedInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = false
        ];
        System.assertEquals(8,updatedInvoices.size());

        List<Zuora__ZInvoice__c> sentInvoices = [
            SELECT Id
            FROM Zuora__ZInvoice__c
            WHERE Email_Sent__c = true
        ];
        System.assertEquals(2,sentInvoices.size());
    }
}