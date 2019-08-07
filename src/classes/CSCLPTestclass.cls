@isTest
public class CSCLPTestclass {
	@isTest 
    public static void testClientReportData() {
		Account clientAccount = new Account(Name = 'Client Account');
		insert clientAccount;

		Contact clientContact = new Contact(FirstName = 'First',
											Email = 'clientContact@bluewave-capital.com',
											LastName = 'Last',
											AccountId = clientAccount.Id);
		insert clientContact;

		User clientUser = new User (ProfileId = [SELECT Id from Profile WHERE Name = 'CS Client Partner Login'].Id,
									FirstName = 'TEst67823323',
									LastName = 'Blue',
									Username = 'TEst67823323@bluewavesolar.com',
									Email = 'clientUser@test.com',
									Alias = 'TEst678',
									ContactId = clientContact.Id,
									CommunityNickname = 'TEst678',
									TimeZoneSidKey = 'America/New_York',
									LocaleSidKey = 'en_US',
									EmailEncodingKey = 'ISO-8859-1',
									LanguageLocaleKey = 'en_US');
		Util.insertSObj(clientUser);

        CSCLP_Settings__c csclpSettings = new CSCLP_Settings__c();
        csclpSettings.Name = 'Test';
        csclpSettings.Report_IDs__c = '000x';
        csclpSettings.Report_Names__c = 'Test';
        insert csclpSettings;

		System.runAs (clientUser) {
			CSCLPController.ClientReportData clientReportData = new CSCLPController.ClientReportData();
			clientReportData = CSCLPController.getClientReportData();
			System.debug(clientReportData);
			System.assertEquals(clientReportData.reports.get('Test'), '000x');
	    }
    }
}