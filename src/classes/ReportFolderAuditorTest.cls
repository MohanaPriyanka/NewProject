/**
 * Created by peteryao on 3/24/20.
 */
@IsTest
public with sharing class ReportFolderAuditorTest {
    private static ReportFolderAuditor auditor = new ReportFolderAuditor();

    @IsTest
    private static void testSchedule() {
        System_Settings__c systemSettings = new System_Settings__c(
            Reports_Shared_to_Portal__c = '{}'
        );
        insert systemSettings;
        Test.startTest();
        WebServiceMockImpl mockImpl = new WebServiceMockImpl();
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        MetadataService.ReportFolder reportFolder = new MetadataService.ReportFolder();
        reportFolder.fullName = 'Accounting';
        reportFolder.folderShares = new List<MetadataService.FolderShare>();
        MetadataService.FolderShare folderShare = new MetadataService.FolderShare();
        folderShare.sharedTo = 'AllPartnerUsers';
        folderShare.sharedToType = 'AllPrmUsers';
        reportFolder.folderShares.add(folderShare);
        reportFolders.add(reportFolder);
        mockImpl.setReportFolderResponse(reportFolders);
        Test.setMock(WebServiceMock.class, mockImpl);
        System.schedule('ReportFolderAuditor Apex Test','0 0 0 ? * * *',auditor);
        Test.stopTest();
        System.assert(true, 'Did not hit System.CalloutException: Callout from scheduled Apex not supported.');
    }

    @IsTest
    private static void testAlertReportShareChanges() {
        System_Settings__c systemSettings = new System_Settings__c(
            Reports_Shared_to_Portal__c = '{}'
        );
        insert systemSettings;

        Test.startTest();
        WebServiceMockImpl mockImpl = new WebServiceMockImpl();
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        MetadataService.ReportFolder reportFolder = new MetadataService.ReportFolder();
        reportFolder.fullName = 'Accounting';
        reportFolder.folderShares = new List<MetadataService.FolderShare>();
        MetadataService.FolderShare folderShare = new MetadataService.FolderShare();
        folderShare.sharedTo = 'AllPartnerUsers';
        folderShare.sharedToType = 'AllPrmUsers';
        reportFolder.folderShares.add(folderShare);
        reportFolders.add(reportFolder);
        mockImpl.setReportFolderResponse(reportFolders);
        Test.setMock(WebServiceMock.class, mockImpl);

        ReportFolderAuditor.alertReportShareChangesFuture();

        Test.stopTest();
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Accounting shared'));
        systemSettings = new SystemSettingsSelector().getSystemSettings();
        System.assertNotEquals('{}', systemSettings.Reports_Shared_to_Portal__c);
        Map<String, List<String>> reportsShared =
            (Map<String, List<String>>) JSON.deserialize(systemSettings.Reports_Shared_to_Portal__c, Map<String, List<String>>.class);
        System.assertEquals(1, reportsShared.size());
        System.assert(reportsShared.containsKey('Accounting'));
    }

    @IsTest
    private static void testGetReportFolderMetadata() {
        Test.startTest();
        WebServiceMockImpl mockImpl = new WebServiceMockImpl();
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        MetadataService.ReportFolder reportFolder = new MetadataService.ReportFolder();
        reportFolder.fullName = 'Accounting';
        reportFolder.folderShares = new List<MetadataService.FolderShare>();
        MetadataService.FolderShare folderShare = new MetadataService.FolderShare();
        folderShare.sharedTo = 'AllPartnerUsers';
        folderShare.sharedToType = 'AllPrmUsers';
        reportFolder.folderShares.add(folderShare);
        reportFolders.add(reportFolder);
        mockImpl.setReportFolderResponse(reportFolders);
        Test.setMock(WebServiceMock.class, mockImpl);

        auditor.createMetadataService();
        List<MetadataService.ReportFolder> reportFoldersResult = auditor.getReportFolderMetadata();
        System.assertEquals(reportFolders.size(), reportFoldersResult.size());
        System.assertEquals(reportFolders[0].folderShares.size(), reportFoldersResult[0].folderShares.size());
        System.assertEquals(reportFolders[0].folderShares[0].sharedTo, reportFoldersResult[0].folderShares[0].sharedTo);
        Test.stopTest();
    }

    @IsTest
    private static void testCurrentReportFolderSharedToAllPrmUsers() {
        Test.startTest();
        WebServiceMockImpl mockImpl = new WebServiceMockImpl();
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        MetadataService.ReportFolder reportFolder = new MetadataService.ReportFolder();
        reportFolder.fullName = 'Accounting';
        reportFolder.folderShares = new List<MetadataService.FolderShare>();
        MetadataService.FolderShare folderShare = new MetadataService.FolderShare();
        folderShare.sharedTo = 'AllPartnerUsers';
        folderShare.sharedToType = 'AllPrmUsers';
        reportFolder.folderShares.add(folderShare);
        reportFolders.add(reportFolder);
        mockImpl.setReportFolderResponse(reportFolders);
        Test.setMock(WebServiceMock.class, mockImpl);

        auditor.createMetadataService();
        MultiMap reportFoldersToReports = auditor.getCurrentReportFoldersShared();
        System.assert(reportFoldersToReports.containsKey('Accounting'));
        Test.stopTest();
    }

    @IsTest
    private static void testCurrentReportFolderNotShared() {
        Test.startTest();
        WebServiceMockImpl mockImpl = new WebServiceMockImpl();
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        MetadataService.ReportFolder reportFolder = new MetadataService.ReportFolder();
        reportFolder.fullName = 'Accounting';
        reportFolder.folderShares = new List<MetadataService.FolderShare>();
        MetadataService.FolderShare folderShare = new MetadataService.FolderShare();
        folderShare.sharedTo = 'user@bluewavesolar.com';
        folderShare.sharedToType = 'User';
        reportFolder.folderShares.add(folderShare);
        reportFolders.add(reportFolder);
        mockImpl.setReportFolderResponse(reportFolders);
        Test.setMock(WebServiceMock.class, mockImpl);

        auditor.createMetadataService();
        MultiMap reportFoldersToReports = auditor.getCurrentReportFoldersShared();
        System.assertEquals(0, reportFoldersToReports.size());
        Test.stopTest();
    }

    @IsTest
    private static void testGroupHasExternalUsers() {
        ReportFolderAuditor.systemSettingSelector = (SystemSettingsSelector) Test.createStub(SystemSettingsSelector.class, new MockSystemSettingsSelector());
        ReportFolderAuditor.userAndGroupSelector = (UserAndGroupSelector) Test.createStub(UserAndGroupSelector.class, new MockUserAndGroupSelector());
        auditor.init();
        System.assert(!auditor.groupIdsWithExternalUsers.contains('00G0a000002IfD3EAK'),
            'Groups that represent roles does not have group members, so it is not added to the groupIdsWithExternalUsers set');
        System.assert(auditor.groupHasExternalUsers('00G0a000002IfD3EAK'),
            'The groupHasExternalUsers method should account for Role groups with no group members');
        System.assert(auditor.groupHasExternalUsers('00G0a000002fuwA'),
            'Any parent group should be found to have external users if any child group below it has external users');
    }

    @IsTest
    private static void testCompareCurrentToPrevious() {
        MultiMap current = MultiMap.newListInstance();
        current.putValue('Folder A', 'Report 1');
        current.putValue('Folder A', 'Report 2');
        current.putValue('Folder A', 'Report 3');
        current.putValue('Folder B', 'Report 4');
        current.putValue('Folder D', 'Report 5');

        Map<String, List<String>> previous = new Map<String, List<String>>();
        previous.put('Folder A', new List<String>{'Report 1', 'Report 2'});
        previous.put('Folder C', null);
        previous.put('Folder D', new List<String>{'Report 6'});

        String result = auditor.compareCurrentToPreviousReportFolders(current, previous);
        System.assert(result.contains('Report 3 shared'));
        System.assert(result.contains('Folder B shared'));
        System.assert(result.contains('Report 5 shared'));
        System.assert(result.contains('Folder C removed'));
        System.assert(result.contains('Report 6 removed'));
    }

    /*************
    *** MOCKS ***
    *************/
    public class MockSystemSettingsSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSystemSettings' {
                    return new System_Settings__c(
                        Reports_Shared_to_Portal__c = '{}'
                    );
                }
            }
            return null;
        }
    }

    public class MockUserAndGroupSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            System.debug(LoggingLevel.ERROR, methodCall.stubbedMethodName);
            switch on methodCall.stubbedMethodName {
                when 'getAllGroupMap' {
                    String json = '{' +
                        '"00Gj0000000EC1dEAG":{"Id":"00Gj0000000EC1dEAG","DeveloperName":"AllCustomerPortalUsers","Type":"AllCustomerPortal"},' +
                        '"00Gj0000002GLdkEAG":{"Id":"00Gj0000002GLdkEAG","DeveloperName":"Founders","Type":"Regular"},' +
                        '"00G0a000002fuwvEAA":{"Id":"00G0a000002fuwvEAA","DeveloperName":"AMP","Type":"Regular"},' +
                        '"00G0a000002fuwA":{"Id":"00G0a000002fuwA","DeveloperName":"Grandparent","Type":"Regular"},' +
                        '"00G0a000002fuwB":{"Id":"00G0a000002fuwB","DeveloperName":"Parent","Type":"Regular"},' +
                        '"00G0a000002fuwC":{"Id":"00G0a000002fuwC","DeveloperName":"Child","Type":"Regular"},' +
                        '"00G0a000003DeFnEAK":{"Id":"00G0a000003DeFnEAK","DeveloperName":"AMPPartnerExecutive","Type":"Role","RelatedId":"00E0a000000aBq3EAE"},' +
                        '"00G0a000003DeFpEAK":{"Id":"00G0a000003DeFpEAK","DeveloperName":"AMPPartnerManager","Type":"Role","RelatedId":"00E0a000000aBq4EAE"},' +
                        '"00G0a000003DeFrEAK":{"Id":"00G0a000003DeFrEAK","DeveloperName":"AMPPartnerUser","Type":"Role","RelatedId":"00E0a000000aBq5EAE"},' +
                        '"00Gj0000000xPVLEA2":{"Id":"00Gj0000000xPVLEA2","DeveloperName":"AllInternalUsers","Type":"Organization"},' +
                        '"00Gj0000002IJSCEA4":{"Id":"00Gj0000002IJSCEA4","DeveloperName":"AllPartnerUsers","Type":"PRMOrganization"},' +
                        '"00G0a000002IgIOEA0":{"Id":"00G0a000002IgIOEA0","DeveloperName":"Founders","Type":"RoleAndSubordinatesInternal","RelatedId":"00E0a000000Nd2NEAS"},' +
                        '"00G0a000002IfD3EAK":{"Id":"00G0a000002IfD3EAK","DeveloperName":"SolarFivePartnerExecutive","Type":"RoleAndSubordinates","RelatedId":"00E0a000000NcspEAC"},' +
                        '"00Gj0000002IbsMEAS":{"Id":"00Gj0000002IbsMEAS","DeveloperName":"LucyFRTestCustomerUser","Type":"RoleAndSubordinates","RelatedId":"00Ej0000000Nc0xEAC"},' +
                        '"00G0a000002rbo7EAA":{"Id":"00G0a000002rbo7EAA","DeveloperName":"HigginsEnergyAlternativesPartnerExecutive","Type":"RoleAndSubordinates","RelatedId":"00E0a000000Jy9DEAS"},' +
                        '"00G0a000002IgINEA0":{"Id":"00G0a000002IgINEA0","DeveloperName":"Founders","Type":"RoleAndSubordinates","RelatedId":"00E0a000000Nd2NEAS"},' +
                        '"00G0a000002IfD2EAK":{"Id":"00G0a000002IfD2EAK","DeveloperName":"SolarFivePartnerExecutive","Type":"Role","RelatedId":"00E0a000000NcspEAC"},' +
                        '"00Gj0000002IbsLEAS":{"Id":"00Gj0000002IbsLEAS","DeveloperName":"LucyFRTestCustomerUser","Type":"Role","RelatedId":"00Ej0000000Nc0xEAC"},' +
                        '"00G0a000002rbo6EAA":{"Id":"00G0a000002rbo6EAA","DeveloperName":"HigginsEnergyAlternativesPartnerExecutive","Type":"Role","RelatedId":"00E0a000000Jy9DEAS"},' +
                        '"00G0a000002IgIMEA0":{"Id":"00G0a000002IgIMEA0","DeveloperName":"Founders","Type":"Role","RelatedId":"00E0a000000Nd2NEAS"}}';
                    return (Map<Id, Group>) System.JSON.deserialize(json, Map<Id, Group>.class);
                } when 'getAllGroupMembers' {
                    String json = '[' +
                        '{"Id":"0110a000000NuS4AAK","GroupId":"00G0a000002fuwvEAA","UserOrGroupId":"00G0a000003DeFnEAK","Group":{"Id":"00G0a000002fuwvEAA","DeveloperName":"AMP"}},' +
                        '{"Id":"0110a000000NuS5AAK","GroupId":"00G0a000002fuwvEAA","UserOrGroupId":"00G0a000003DeFpEAK","Group":{"Id":"00G0a000002fuwvEAA","DeveloperName":"AMP"}},' +
                        '{"Id":"0110a000000NuS6AAK","GroupId":"00G0a000002fuwvEAA","UserOrGroupId":"00G0a000003DeFrEAK","Group":{"Id":"00G0a000002fuwvEAA","DeveloperName":"AMP"}},' +
                        '{"Id":"011j0000000BEwkAAG","GroupId":"00Gj0000002GLdkEAG","UserOrGroupId":"005j000000BdzDUAAZ","Group":{"Id":"00Gj0000002GLdkEAG","DeveloperName":"Founders"}},' +
                        '{"Id":"011j0000000BEwjAAG","GroupId":"00Gj0000002GLdkEAG","UserOrGroupId":"005j000000BdzDVAAZ","Group":{"Id":"00Gj0000002GLdkEAG","DeveloperName":"Founders"}},' +
                        '{"Id":"011j0000000BEwlAAG","GroupId":"00Gj0000002GLdkEAG","UserOrGroupId":"005j000000BdzDWAAZ","Group":{"Id":"00Gj0000002GLdkEAG","DeveloperName":"Founders"}},' +
                        '{"Id":"011j0000000BEwA","GroupId":"00G0a000002fuwA","UserOrGroupId":"00G0a000002fuwB","Group":{"Id":"00G0a000002fuwA","DeveloperName":"Grandparent"}},' +
                        '{"Id":"011j0000000BEwB","GroupId":"00G0a000002fuwB","UserOrGroupId":"00G0a000002fuwC","Group":{"Id":"00G0a000002fuwB","DeveloperName":"Parent"}},' +
                        '{"Id":"011j0000000BEwC","GroupId":"00G0a000002fuwC","UserOrGroupId":"0053I000000ZHTJQA4","Group":{"Id":"00G0a000002fuwC","DeveloperName":"Child"}}]';
                    return (List<GroupMember>) System.JSON.deserialize(json, List<GroupMember>.class);
                } when 'getExternalUserMap' {
                    String json = '{' +
                        '"0053I000000ZHTJQA4":{"Id":"0053I000000ZHTJQA4","UserRoleId":"00E3I000000MOy7UAG"},' +
                        '"0053I000000ZHWrQAO":{"Id":"0053I000000ZHWrQAO","UserRoleId":"00E3I000000MOyAUAW"}}';
                    return (Map<Id, User>) System.JSON.deserialize(json, Map<Id, User>.class);
                } when 'getUserRoleMap' {
                    String json = '{' +
                        '"00Ej0000000Nc0xEAC":{"Id":"00Ej0000000Nc0xEAC","PortalType":"CustomerPortal"},' +
                        '"00E0a000000Nd2NEAS":{"Id":"00E0a000000Nd2NEAS","PortalType":"None"},' +
                        '"00E0a000000NcspEAC":{"Id":"00E0a000000NcspEAC","PortalType":"Partner"},' +
                        '"00E0a000000aBq3EAE":{"Id":"00E0a000000aBq3EAE","PortalType":"Partner"},' +
                        '"00E0a000000aBq4EAE":{"Id":"00E0a000000aBq4EAE","PortalType":"Partner"},' +
                        '"00E0a000000aBq5EAE":{"Id":"00E0a000000aBq5EAE","PortalType":"Partner"},' +
                        '"00E0a000000Jy9DEAS":{"Id":"00E0a000000Jy9DEAS","PortalType":"Partner"}}';
                    return (Map<Id, UserRole>) System.JSON.deserialize(json, Map<Id, UserRole>.class);
                }
            }
            return null;
        }
    }

    private class WebServiceMockImpl implements WebServiceMock
    {
        private List<MetadataService.ReportFolder> reportFolderResult;
        public void setReportFolderResponse(List<MetadataService.ReportFolder> reportFolderResult) {
            this.reportFolderResult = reportFolderResult;
        }

        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType)
        {
             if (request instanceof MetadataService.readMetadata_element) {
                 MetadataService.readReportFolderResponse_element reportFolderResponse =
                     new MetadataService.readReportFolderResponse_element();
                 reportFolderResponse.result = new MetadataService.ReadReportFolderResult();
                 reportFolderResponse.result.records = reportFolderResult;
                 response.put('response_x', reportFolderResponse);
             } else if (request instanceof MetadataService.listMetadata_element) {
                 MetadataService.listMetadata_element listMetadataRequest =
                     (MetadataService.listMetadata_element) request;
                 MetadataService.listMetadataResponse_element listMetadataResponse =
                     new MetadataService.listMetadataResponse_element();
                 listMetadataResponse.result = new List<MetadataService.FileProperties>();
                 if (listMetadataRequest.queries[0].type_x == 'ReportFolder') {
                     MetadataService.FileProperties fileProperties = new MetadataService.FileProperties();
                     fileProperties.fullName = 'Accounting';
                     fileProperties.fileName = 'reports/Accounting';
                     listMetadataResponse.result.add(fileProperties);
                 } else if (listMetadataRequest.queries[0].type_x == 'Report') {
                     MetadataService.FileProperties fileProperties = new MetadataService.FileProperties();
                     fileProperties.fullName = 'Accounting/2020_Invoices';
                     listMetadataResponse.result.add(fileProperties);
                 }
                 response.put('response_x', listMetadataResponse);
             }
            return;
        }
    }
}