@isTest
public class LightningReportsControllerTest {
    @isTest (SeeAllData='true') 
    public static void testSummaryReportResponse() {
		Account clientAccount = new Account(Name = 'Client Account');
		insert clientAccount;

		Contact clientContact = new Contact(FirstName = 'First',
											Email = 'clientContact@bluewave-capital.com',
											LastName = 'Last',
											AccountId = clientAccount.Id);
		insert clientContact;

		User clientUser = new User (ProfileId = [SELECT Id from Profile WHERE Name = 'CS Client Portal User'].Id,
									FirstName = 'Test',
									LastName = 'BFG_User',
									Username = 'communityuser@test.com',
									Email = 'communityuser@test.com',
									Alias = 'bfg_usr',
									ContactId = clientContact.Id,
									CommunityNickname = 'bfg_usr',
									TimeZoneSidKey = 'America/New_York',
									LocaleSidKey = 'en_US',
									EmailEncodingKey = 'ISO-8859-1',
									LanguageLocaleKey = 'en_US');
		Util.insertSObj(clientUser);

    	String reportId = [SELECT Id, DeveloperName 
    					   FROM Report 
    					   WHERE DeveloperName = 'LightningReportsTestReport'].get(0).Id;

    	Lead lead = new Lead(FirstName='Cole',
				    		 LastName='TestLightningReports',
				    		 Company='Cole Swain',
				    		 Annual_Income_Currency__c = 100000,
				    		 Parent_Account__c = clientAccount.Id);
        insert lead;
        
    	LightningReportsController.ReportResponse lightningReportResponse = LightningReportsController.getReportResponse(reportId, 'TestLightningReports');
    	System.assertEquals(lightningReportResponse.sumResp.groupList.get(0).fieldAggregateList.get(0).label, 'Annual Income');
    	System.assertEquals(lightningReportResponse.sumResp.groupList.get(0).fieldAggregateList.get(0).value, '$100,000.00');
    }
}