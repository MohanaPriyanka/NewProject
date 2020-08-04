@IsTest
public with sharing class ContentVersionSelectorTest {
    @TestSetup
    public static void testSetup() {
        ContentVersion cvOne = new ContentVersion(
            ContentLocation = 'S',
            VersionData = Blob.valueOf('This is the body of the file'),
            Title = 'FileOne',
            PathOnClient = '/FileOne'
        );
        insert cvOne;
        ContentVersion cvTwo = new ContentVersion(
            ContentLocation = 'S',
            VersionData = Blob.valueOf('This is the body of the file'),
            Title = 'FileTwo',
            PathOnClient = '/fileTwo'
        );
        insert cvTwo;
    }

    @IsTest
    public static void testSelectById() {
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([
            SELECT Id
            FROM ContentVersion
        ]);

        System.assertEquals(2,versionMap.values().size());

        ContentVersionSelector selector = new ContentVersionSelector();
        Map<Id, ContentVersion> contentMap = selector.selectById(versionMap.keySet());

        System.assertEquals(2,contentMap.values().size());
    }
}