/**
 * Created by peteryao on 3/20/20.
 * Tested By: ReportFolderAuditorTest
 */

public without sharing class ReportFolderAuditor implements Schedulable {
    @TestVisible
    private static UserAndGroupSelector userAndGroupSelector = new UserAndGroupSelector();
    @TestVisible
    private static MetadataService.MetadataPort service;
    @TestVisible
    private static SystemSettingsSelector systemSettingSelector = new SystemSettingsSelector();
    private System_Settings__c systemSettings;
    @TestVisible
    private Set<String> groupsWithExternalUsers;
    @TestVisible
    private Set<Id> groupIdsWithExternalUsers;
    private Map<Id, Group> groupsByGroupId;
    private List<GroupMember> allGroupMembers;
    private MultiMap groupMembersByGroupId;
    private Map<Id, UserRole> userRolesByRoleId;
    private Map<Id, User> portalUsersByUserId;
    private List<String> reportFoldersSharedToExternalUsers;

    public void execute(SchedulableContext context) {
        alertReportShareChangesFuture();
    }

    @Future(Callout=true)
    public static void alertReportShareChangesFuture() {
        try {
            ReportFolderAuditor auditor = new ReportFolderAuditor();
            auditor.init();
            auditor.alertReportShareChanges();
        } catch (Exception e) {
            Logger.logLater('ReportFolderAuditor', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    public void init() {
        createMetadataService();
        getAllGroupsUsersAndRoles();
        getGroupsWithExternalUsers();
        systemSettings = systemSettingSelector.getSystemSettings();
    }

    @TestVisible
    private void createMetadataService() {
        service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void alertReportShareChanges() {
        MultiMap currentReportFoldersToReports = getCurrentReportFoldersShared();
        Map<String, List<String>> previousReportFoldersToReports =
            (Map<String, List<String>>) JSON.deserialize(systemSettings.Reports_Shared_to_Portal__c, Map<String, List<String>>.class);
        String resultString = compareCurrentToPreviousReportFolders(currentReportFoldersToReports, previousReportFoldersToReports);
        if (resultString != '') {
            Logger.logLater(
                'ReportFolderAuditor',
                'alertReportShareChanges',
                'Email client ops (at this time, Cara and Walt) that we found these report folder and/or report differences ' +
                    'from the last time we checked:\n' + resultString,
                Logger.ERROR
            );
            systemSettings.Reports_Shared_to_Portal__c = currentReportFoldersToReports.toJSON();
            update systemSettings;
        }
    }

    // Unfortunately, a MultiMap can't be deserialized because we can't easily deserialize Object. So we need to treat
    // the current shares (a MultiMap) and the previous shares (deserialized Map<String, List<String>>) differently.
    @TestVisible
    private String compareCurrentToPreviousReportFolders(MultiMap currentShares, Map<String, List<String>> previousShares) {
        String result = '';
        for (Object currentReportFolder : currentShares.keySet()) {
            if (previousShares.containsKey((String) currentReportFolder)) {
                List<String> previousReports = previousShares.get((String) currentReportFolder);
                for (Object currentReport : currentShares.getValues(currentReportFolder)) {
                    if (!previousReports.contains((String) currentReport)) {
                        result += 'Report ' + currentReport + ' shared\n';
                    }
                }
            } else {
                result += 'Folder ' + currentReportFolder + ' shared with all of the reports in it\n';
            }
        }
        for (String previousReportFolder : previousShares.keySet()) {
            if (currentShares.containsKey(previousReportFolder)) {
                List<Object> currentReports = currentShares.getValues(previousReportFolder);
                for (String previousReport : previousShares.get(previousReportFolder)) {
                    if (!currentReports.contains(previousReport)) {
                        result += 'Report ' + previousReport + ' removed\n';
                    }
                }
            } else {
                result += 'Folder ' + previousReportFolder + ' removed\n';
            }
        }
        return result;
    }

    public MultiMap getCurrentReportFoldersShared() {
        MultiMap reportFoldersToReports = MultiMap.newListInstance();

        for (MetadataService.ReportFolder reportFolder : getReportFolderMetadata()) {
            if (reportFolder.folderShares == null) {
                continue;
            }
            for (MetadataService.FolderShare folderShare : reportFolder.folderShares) {
                if (folderShare.sharedToType == 'AllPrmUsers' ||
                    folderShare.sharedToType == 'AllCspUsers' ||
                    folderShare.sharedToType == 'PartnerUser' ||
                    folderShare.sharedToType == 'CustomerPortalUser' ||
                    folderShare.sharedToType == 'PortalRole' ||
                    folderShare.sharedToType == 'PortalRoleAndSubordinates' ||
                    (folderShare.sharedToType == 'Group' && groupsWithExternalUsers.contains(folderShare.sharedTo))) {
                    getReportsInFolder(reportFolder.fullName, reportFoldersToReports, reportFolder);
                    break;
                }
            }
        }
        return reportFoldersToReports;
    }

    private void getReportsInFolder(String folderName, MultiMap reportFoldersToReports, MetadataService.ReportFolder reportFolder) {
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        MetadataService.ListMetadataQuery queryReport = new MetadataService.ListMetadataQuery();
        queryReport.type_x = 'Report';
        queryReport.folder = folderName;
        queries.add(queryReport);
        List<MetadataService.FileProperties> fpList = service.listMetadata(queries, 40);
        if (fpList == null) {
            reportFoldersToReports.putValues(reportFolder.fullName, new List<String>());
            return;
        }
        for (MetadataService.FileProperties fileProperties : fpList) {
            reportFoldersToReports.putValue(reportFolder.fullName, fileProperties.fullName);
        }
    }

    @TestVisible
    private List<MetadataService.ReportFolder> getReportFolderMetadata() {
        MetadataService.FileProperties[] fileProperties;
        List<MetadataService.ReportFolder> reportFolders;
        fileProperties = getAllReportFolderNames();
        reportFolders = getAllReportFolderMetadata(fileProperties);
        return reportFolders;
    }

    private MetadataService.FileProperties[] getAllReportFolderNames() {
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        MetadataService.ListMetadataQuery queryReportFolder = new MetadataService.ListMetadataQuery();
        queryReportFolder.type_x = 'ReportFolder';
        queries.add(queryReportFolder);
        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 42);
        return fileProperties;
    }

    private List<MetadataService.ReportFolder> getAllReportFolderMetadata(MetadataService.FileProperties[] fileProperties) {
        List<MetadataService.ReportFolder> reportFolders = new List<MetadataService.ReportFolder>();
        List<String> folderNames = new List<String>();
        for (MetadataService.FileProperties fileProperty : fileProperties) {
            // Since unfiled$public results in a SOAP exception, and we can't change sharing for it anyways
            if (fileProperty.fileName.contains('unfiled$public')) {
                continue;
            }
            folderNames.add(fileProperty.fileName.replace('reports/', ''));
            // Since the SOAP API only allows querying 10 folders at a time
            if (folderNames.size() == 10) {
                getReportFolderMetadata(reportFolders, folderNames);
            }
        }
        if (!folderNames.isEmpty()) {
            getReportFolderMetadata(reportFolders, folderNames);
        }
        return reportFolders;
    }

    private void getReportFolderMetadata(List<MetadataService.ReportFolder> reportFolders, List<String> folderNames) {
        try {
            reportFolders.addAll((List<MetadataService.ReportFolder>) service.readMetadata('ReportFolder', folderNames).getRecords());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            Logger.logLater('ReportFolderAuditor', 'getReportFolderMetadata', 'Could not query ' + folderNames, Logger.ERROR);
        }
        folderNames.clear();
    }

    private void getAllGroupsUsersAndRoles() {
        reportFoldersSharedToExternalUsers = new List<String>();
        groupsByGroupId = userAndGroupSelector.getAllGroupMap();
        allGroupMembers = userAndGroupSelector.getAllGroupMembers();
        groupMembersByGroupId = MultiMap.newListInstance();
        userRolesByRoleId = userAndGroupSelector.getUserRoleMap();
        portalUsersByUserId = userAndGroupSelector.getExternalUserMap();
        for (GroupMember groupMember : allGroupMembers) {
            if (groupMember.UserOrGroupId.getSobjectType() == Group.SObjectType) {
                groupMembersByGroupId.putValue(groupMember.GroupId, groupMember.UserOrGroupId);
            }
        }
    }

    private void getGroupsWithExternalUsers() {
        groupIdsWithExternalUsers = new Set<Id>();
        for (GroupMember groupMember : allGroupMembers) {
            if (groupMember.UserOrGroupId.getSobjectType() == User.SObjectType &&
                portalUsersByUserId.containsKey(groupMember.UserOrGroupId)) {
                groupIdsWithExternalUsers.add(groupMember.GroupId);
            } else if (groupMember.UserOrGroupId.getSobjectType() == Group.SObjectType &&
                groupHasExternalUsers(groupMember.UserOrGroupId)) {
                groupIdsWithExternalUsers.add(groupMember.GroupId);
            }
        }

        groupsWithExternalUsers = new Set<String>();
        for (Id groupId : new List<Id>(groupIdsWithExternalUsers)) {
            groupsWithExternalUsers.add(groupsByGroupId.get(groupId).DeveloperName);
        }
    }

    @TestVisible
    private Boolean groupHasExternalUsers(Id groupId) {
        if (groupIdsWithExternalUsers.contains(groupId)) {
            return true;
        }
        // Role and special groups (AllCustomerPortal and PRMOrganization) don't have group members
        Group groupInfo = groupsByGroupId.get(groupId);
        if (groupInfo.Type == 'Role' || groupInfo.Type == 'RoleAndSubordinates') {
            String portalType = userRolesByRoleId.get(groupInfo.RelatedId).PortalType;
            return (portalType == 'CustomerPortal' || portalType == 'Partner');
        } else if (groupInfo.Type == 'AllCustomerPortal' || groupInfo.Type == 'PRMOrganization') {
            return true;
        }
        // This could be "Regular" group, so we need to check group members
        for (Object childGroupId : groupMembersByGroupId.getValues(groupId)) {
            Group childGroup = groupsByGroupId.get((Id) childGroupId);
            if (childGroup == null) {
                continue;
            }
            switch on childGroup.Type {
                when 'Regular' {
                    if (groupHasExternalUsers((Id) childGroupId)) {
                        return true;
                    }
                } when 'Role' {
                    String portalType = userRolesByRoleId.get(childGroup.RelatedId).PortalType;
                    if (portalType == 'CustomerPortal' || portalType == 'Partner') {
                        return true;
                    }
                } when 'AllCustomerPortal' {
                    return true;
                } when 'PRMOrganization' {
                    return true;
                }
            }
        }
        return false;
    }

}