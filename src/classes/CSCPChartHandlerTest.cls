@isTest
public class CSCPChartHandlerTest {
    @testSetup static void setupTestData() {
		CommunitySolarCustomerPortalTest.setupTestData();
    }

	@isTest static void testGenerationSavingsData() {
		test.startTest();
	    	Date myDate = Date.newInstance(2015, 2, 17);	
			Energy_Usage_Update__c productionUpdate = new Energy_Usage_Update__c(
				Name = 'Test Production Update',
				Date__c = myDate,
				Product_LIne__c = 'Community Solar',
				Production__c = 150000,
				Shared_Solar_System__c = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Oxford Barrett St. P1'].Id
			);
			//insert productionUpdate;
		test.stopTest();		
			
		List<Account_Bill__c> accountBills = new List<Account_Bill__c>();
		for (Account_Bill__c accountBill : [SELECT Id, Date_Sent__c FROM Account_Bill__c]) {
			accountBill.Date_Sent__c = myDate;
			accountBills.add(accountBill);
		}
		update accountBills;

		User portalUser = [SELECT Id, Parent_Account_ID__c FROM User WHERE Username = 'communityuser@test.com'];		
		System.runAs (portalUser) {
			CSCPChartHandler.SolarGenerationSavingsResult result = CSCPChartHandler.getGenerationSavingsData();
			System.assertEquals(result.generation.get(0), 3750);
			System.assertEquals(result.savings.get(0), 1.5);
			System.assertEquals(result.yearMonth.get(0), '2 2015');
		}		
	}    
}