@isTest(SeeAllData=true)
public with sharing class PortalLoginHistoryControllerTest {
    public static testMethod void testController() {
        PageReference portalLoginHistory = Page.PortalLoginHistory;
        Test.setCurrentPage(portalLoginHistory);
        ApexPages.currentPage().getParameters().put('isTest', 'TRUE');

        PortalLoginHistoryController plhc = new PortalLoginHistoryController();

        plhc.getUsers();
        plhc.getUsersAsJSON();
    }
}
