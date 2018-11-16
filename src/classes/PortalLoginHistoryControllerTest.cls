@isTest(SeeAllData=true)
public with sharing class PortalLoginHistoryControllerTest {
    public static testMethod void testController() {
        PageReference portalLoginHistory = Page.PortalLoginHistory;
        Test.setCurrentPage(portalLoginHistory);
        ApexPages.currentPage().getParameters().put('isTest', 'TRUE');
        ApexPages.currentPage().getParameters().put('dayRange', '7');

        PortalLoginHistoryController plhc = new PortalLoginHistoryController();

        plhc.getUsers();
        plhc.getUsersAsJSON();
    }
}