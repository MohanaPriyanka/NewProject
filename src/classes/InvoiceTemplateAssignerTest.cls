@isTest
public class InvoiceTemplateAssignerTest {
    public static final String NON_AUTOPAY_MESSAGE = 'Non-Autopay Message';
    public static final String AUTOPAY_MESSAGE = 'Autopay Message';

    @testSetup static void setupTestData() {
        zqu__InvoiceTemplate__c anchorTemplate = new zqu__InvoiceTemplate__c(
            Active__c = true,
            Autopay__c = false,
            Anchor__c = true,
            Brand_Key__c = 'BluewaveLogo',
            zqu__ZuoraId__c = 'anchorTemplate'
        );

        zqu__InvoiceTemplate__c inactiveTemplate = new zqu__InvoiceTemplate__c(
            Active__c = false,
            Autopay__c = false,
            Anchor__c = true,
            Brand_Key__c = 'BluewaveLogo',
            zqu__ZuoraId__c = 'inactiveTemplate'
        );

        zqu__InvoiceTemplate__c bwNonAnchor = new zqu__InvoiceTemplate__c(
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Brand_Key__c = 'BluewaveLogo',
            zqu__ZuoraId__c = 'bwNonAnchor'
        );

        zqu__InvoiceTemplate__c ampNonAnchor = new zqu__InvoiceTemplate__c(
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Brand_Key__c = 'AmpRed',
            zqu__ZuoraId__c = 'ampNonAnchor'
        );

        zqu__InvoiceTemplate__c bwAutopay = new zqu__InvoiceTemplate__c(
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Brand_Key__c = 'BluewaveLogo',
            zqu__ZuoraId__c = 'bwAutopay'
        );

        zqu__InvoiceTemplate__c ampAutopay = new zqu__InvoiceTemplate__c(
            Active__c = true,
            Autopay__c = true,
            Anchor__c = true,
            Brand_Key__c = 'AmpRed',
            zqu__ZuoraId__c = 'ampAutopay'
        );

        // Missing: AMP Short Autopay to test error handling
        insert new List<zqu__InvoiceTemplate__c>{
            anchorTemplate, inactiveTemplate, bwNonAnchor,
            ampNonAnchor, bwAutopay, ampAutopay
        };

        Account accountParent = new Account(
            Name = 'Amp ParentAccount',
            Client_Brand_Key__c = 'AmpRed');
        Account accountParent2 = new Account(
            Name = 'BlueWave ParentAccount',
            Client_Brand_Key__c = 'BluewaveLogo');
        insert new List<Account>{accountParent,accountParent2};

        Account accountA = new Account(
            Name = 'Anchor Property',
            Recurring_Billing__c = true,
            Zuora_Id__c = 'AnchorAutopay',
            Zuora_Invoice_Message_1_of_2__c = 'Custom Message One',
            Zuora_Invoice_Message_2_of_2__c = 'Custom Message Two',
            Parent_Account__c = accountParent.Id);
        Account accountB = new Account(
            Name = 'Smallofftake Property',
            Recurring_Billing__c = false,
            Zuora_Id__c = 'SmallNonAutopay',
            Parent_Account__c = accountParent2.Id);
        insert new List<Account>{accountA, accountB};

        Opportunity opportunityone =
            new Opportunity(Name = 'Anchor Opp',
                AccountId = accountA.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Anchor',
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'Resi One',
                AccountId = accountB.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Residential',
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'PublicOfftake Two',
                AccountId = accountA.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Public Offtake',
                CloseDate = System.today());
        insert new List<Opportunity>{
            opportunityone, opportunitytwo, opportunitythree
        };

        CS_Bill_Setting__c csBillSetting = new CS_Bill_Setting__c(
            Default_Bill_Message_for_Autopay__c = AUTOPAY_MESSAGE,
            Default_Bill_Message_for_Non_Autopay__c = NON_AUTOPAY_MESSAGE
        );
        insert csBillSetting;
    }

    @isTest public static void testBatchRun(){
        List<Error_Log__c> oldLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        System.assertEquals(0,oldLogs.size());

        Test.startTest();
        InvoiceTemplateAssigner assigner = new InvoiceTemplateAssigner();
        assigner.executeBatch();
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        System.assertEquals(1,logs.size());
    }

    @isTest public static void testAutopay() {
        List<Account> acctList = [
            SELECT Id, Name, Zuora_Id__c,
                Parent_Account__r.Client_Brand_Key__c,
                Recurring_Billing__c, Count_of_Large_Offtake_Opps__c,
                Zuora_Invoice_Message_1_of_2__c, Zuora_Invoice_Message_2_of_2__c
            FROM Account
            WHERE Zuora_Id__c != null ];

        InvoiceTemplateAssigner assigner = new InvoiceTemplateAssigner();
        List<zqu__InvoiceTemplate__c> templates = assigner.getTemplateList();
        List<ZuoraAPI.ZuoraAccount> zuoraAccount = assigner.assignTemplates(acctList,templates);

        // 6 templates exist, only 5 are active:
        System.assertEquals(5, templates.size());
        System.assertEquals(2, zuoraAccount.size());

        for (ZuoraAPI.ZuoraAccount account : zuoraAccount){
            if (account.Id == 'AnchorAutopay'){
                System.assertEquals('ampAutopay', account.InvoiceTemplateId);
                System.assertEquals('Custom Message One', account.Notes);
                System.assertEquals('Custom Message Two', account.BillMessage_Zcustom);
            } else {
                System.assertEquals('bwNonAnchor', account.InvoiceTemplateId);
                System.assertEquals(NON_AUTOPAY_MESSAGE, account.Notes);
            }
        }
    }

    @isTest public static void testHTMLTags(){
        List<CS_Bill_Setting__c> billSetting = [
            SELECT Id, Default_Bill_Message_for_Non_Autopay__c
            FROM CS_Bill_Setting__c
        ];

        billSetting[0].Default_Bill_Message_for_Non_Autopay__c = 'This message has <b> some html </b> tags';

        update billSetting[0];

        Test.startTest();
        InvoiceTemplateAssigner assigner = new InvoiceTemplateAssigner();
        assigner.executeBatch();
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id, Message__c, Method__c
            FROM Error_Log__c
            WHERE Method__c = 'Bill Message contains hmtl tag'
        ];
        System.assertEquals(1,logs.size());
    }
}