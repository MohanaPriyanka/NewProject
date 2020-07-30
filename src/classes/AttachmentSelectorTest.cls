@IsTest
public with sharing class AttachmentSelectorTest {
    @TestSetup
    public static void testSetup() {
        Account acct = new Account(Name = 'Account One');
        insert acct;

        Attachment attachOne = new Attachment(
            Name = 'FileOne',
            Body = Blob.valueOf('This is the file body'),
            ParentId = acct.Id,
            Description = 'Descirption'
        );
        insert attachOne;
        Attachment attachTwo = new Attachment(
            Name = 'OtherFileName',
            Body = Blob.valueOf('This is the file body'),
            ParentId = acct.Id,
            Description = 'Descirption'
        );
        insert attachTwo;
    }

    @IsTest
    public static void testGetAttachmentsByParentIdAndName() {
        Map<Id, Account> acctMap = new Map<Id, Account>([
            SELECT Id
            FROM Account
        ]);

        AttachmentSelector selector = new AttachmentSelector();
        List<Attachment> attachList = selector.getAttachmentsByParentIdAndName(acctMap.keySet(),'FileOne');
        System.assertEquals(1,attachList.size());
    }
}