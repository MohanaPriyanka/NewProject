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
    private List<String> foldersSharedToExternalUsers;

    public void execute(SchedulableContext context) {
        alertReportAndDashboardShareChangesFuture();
    }

    @Future(Callout=true)
    public static void alertReportAndDashboardShareChangesFuture() {
        try {
            ReportFolderAuditor auditor = new ReportFolderAuditor();
            auditor.init();
            auditor.alertReportAndDashboardShareChanges();
        } catch (Exception e) {
            Logger.logLater(
                'ReportFolderAuditor',
                'alertReportAndDashboardShareChangesFuture',
                e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
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
    public void alertReportAndDashboardShareChanges() {
        MultiMap currentFoldersToItems = getCurrentFoldersShared();
        Map<String, List<String>> previousFoldersToItems =
            (Map<String, List<String>>) JSON.deserialize(systemSettings.Reports_Shared_to_Portal__c, Map<String, List<String>>.class);
        String resultString = compareCurrentToPreviousFolders(currentFoldersToItems, previousFoldersToItems);
        if (resultString != '') {
            Logger.logLater(
                'ReportFolderAuditor',
                'alertReportAndDashboardShareChanges',
                'Email client ops and sales ops that we found these report folder and/or report differences ' +
                    'from the last time we checked:\n' + resultString,
                Logger.ERROR
            );
            systemSettings.Reports_Shared_to_Portal__c = currentFoldersToItems.toJSON();
            update systemSettings;
        }
    }

    // Unfortunately, a MultiMap can't be deserialized because we can't easily deserialize Object. So we need to treat
    // the current shares (a MultiMap) and the previous shares (deserialized Map<String, List<String>>) differently.
    @TestVisible
    private String compareCurrentToPreviousFolders(MultiMap currentShares, Map<String, List<String>> previousShares) {
        String result = '';
        for (Object currentFolder : currentShares.keySet()) {
            if (previousShares.containsKey((String) currentFolder)) {
                List<String> previousItems = previousShares.get((String) currentFolder);
                for (Object currentItem : currentShares.getValues(currentFolder)) {
                    if (!previousItems.contains((String) currentItem)) {
                        result += 'Report or dashboard shared: ' + currentItem + '\n';
                    }
                }
            } else {
                result += 'Folder ' + currentFolder + ' shared with all of the reports/dashboards in it\n';
            }
        }
        for (String previousFolder : previousShares.keySet()) {
            if (currentShares.containsKey(previousFolder)) {
                List<Object> currentItem = currentShares.getValues(previousFolder);
                for (String previousItem : previousShares.get(previousFolder)) {
                    if (!currentItem.contains(previousItem)) {
                        result += 'Report or dashboard removed: ' + previousItem + '\n';
                    }
                }
            } else {
                result += 'Folder ' + previousFolder + ' removed\n';
            }
        }
        return result;
    }

    public MultiMap getCurrentFoldersShared() {
        MultiMap foldersToItems = MultiMap.newListInstance();

        for (MetadataService.Folder folder : getFolderMetadata()) {
            List<MetadataService.FolderShare> folderShares = getFolderShares(folder);
            if (folderShares == null) {
                continue;
            }
            for (MetadataService.FolderShare folderShare : folderShares) {
                if (folderShare.sharedToType == 'AllPrmUsers' ||
                    folderShare.sharedToType == 'AllCspUsers' ||
                    folderShare.sharedToType == 'PartnerUser' ||
                    folderShare.sharedToType == 'CustomerPortalUser' ||
                    folderShare.sharedToType == 'PortalRole' ||
                    folderShare.sharedToType == 'PortalRoleAndSubordinates' ||
                    (folderShare.sharedToType == 'Group' && groupsWithExternalUsers.contains(folderShare.sharedTo))) {
                    getItemsInFolder(foldersToItems, folder);
                    break;
                }
            }
        }
        return foldersToItems;
    }

    private List<MetadataService.FolderShare> getFolderShares(MetadataService.Folder folder) {
        try {
            MetadataService.ReportFolder reportFolder = (MetadataService.ReportFolder) folder;
            return reportFolder.folderShares;
        } catch (TypeException te) {
            MetadataService.DashboardFolder dashboardFolder = (MetadataService.DashboardFolder) folder;
            return dashboardFolder.folderShares;
        }
    }

    private String getFolderFullName(MetadataService.Folder folder) {
        try {
            MetadataService.ReportFolder reportFolder = (MetadataService.ReportFolder) folder;
            return reportFolder.fullName;
        } catch (TypeException te) {
            MetadataService.DashboardFolder dashboardFolder = (MetadataService.DashboardFolder) folder;
            return dashboardFolder.fullName;
        }
    }

    private void getItemsInFolder(MultiMap foldersToReportsAndDashboards, MetadataService.Folder folder) {
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        MetadataService.ListMetadataQuery queryReport = new MetadataService.ListMetadataQuery();
        try {
            MetadataService.ReportFolder reportFolder = (MetadataService.ReportFolder) folder;
            queryReport.type_x = 'Report';
        } catch (TypeException te) {
            queryReport.type_x = 'Dashboard';
        }
        queryReport.folder = getFolderFullName(folder);
        queries.add(queryReport);
        List<MetadataService.FileProperties> fpList = service.listMetadata(queries, 40);
        if (fpList == null) {
            foldersToReportsAndDashboards.putValues(getFolderFullName(folder), new List<String>());
            return;
        }
        for (MetadataService.FileProperties fileProperties : fpList) {
            foldersToReportsAndDashboards.putValue(getFolderFullName(folder), fileProperties.fullName);
        }
    }

    @TestVisible
    private List<MetadataService.Folder> getFolderMetadata() {
        MetadataService.FileProperties[] fileProperties;
        List<MetadataService.Folder> reportFolders;
        fileProperties = getAllFolderNames('ReportFolder');
        reportFolders = getAllFolderMetadata(fileProperties, 'ReportFolder');
        fileProperties = getAllFolderNames('DashboardFolder');
        reportFolders.addAll(getAllFolderMetadata(fileProperties, 'DashboardFolder'));
        return reportFolders;
    }

    private MetadataService.FileProperties[] getAllFolderNames(String type_x) {
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        MetadataService.ListMetadataQuery queryFolder = new MetadataService.ListMetadataQuery();
        queryFolder.type_x = type_x;
        queries.add(queryFolder);
        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 42);
        return fileProperties;
    }

    private List<MetadataService.Folder> getAllFolderMetadata(MetadataService.FileProperties[] fileProperties, String type_x) {
        List<MetadataService.Folder> folders = new List<MetadataService.Folder>();
        List<String> folderNames = new List<String>();
        for (MetadataService.FileProperties fileProperty : fileProperties) {
            // Since unfiled$public results in a SOAP exception, and we can't change sharing for it anyways
            if (fileProperty.fileName.contains('unfiled$public')) {
                continue;
            }
            folderNames.add(fileProperty.fileName.replace('reports/', '').replace('dashboards/', ''));
            // Since the SOAP API only allows querying 10 folders at a time
            if (folderNames.size() == 10) {
                getFolderMetadata(folders, folderNames, type_x);
            }
        }
        if (!folderNames.isEmpty()) {
            getFolderMetadata(folders, folderNames, type_x);
        }
        return folders;
    }

    private void getFolderMetadata(List<MetadataService.Folder> folders, List<String> folderNames, String type_x) {
        try {
            folders.addAll((List<MetadataService.Folder>) service.readMetadata(type_x, folderNames).getRecords());
        } catch (Exception e) {
            Logger.logLater(
                'ReportFolderAuditor',
                'getFolderMetadata',
                'Could not query ' + folderNames + '\n' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        }
        folderNames.clear();
    }

    private void getAllGroupsUsersAndRoles() {
        foldersSharedToExternalUsers = new List<String>();
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