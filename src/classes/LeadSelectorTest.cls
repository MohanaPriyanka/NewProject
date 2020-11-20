/*************************************************************************************
 * Created By: peteryao on 2019-04-30  
   *************************************************************************************/
@IsTest
public with sharing class LeadSelectorTest {
    @IsTest
    public static void testSelectById() {
        Lead testLead = new Lead(
            FirstName = 'FirstName',
            LastName = 'LastName',
            Company = 'Company',
            Email = 'email@sample.com',
            Status = 'Qualified',
            Zuora_Payment_Ref_Id__c = '2c92c0f86a6e0622016a6fc7f32e010a'
        );
        insert testLead;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=TRUE LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.convertLead(lc);

        System.assertEquals(testLead.Zuora_Payment_Ref_Id__c, LeadSelector.selectConvertedByIds(new List<Id>{testLead.Id})[0].Zuora_Payment_Ref_Id__c);
    }

    @IsTest
    private static void testSelectOneWithPropertiesAndUtilities() {
        Lead testLead = new Lead(
            FirstName = 'FirstName',
            LastName = 'LastName',
            Company = 'Company',
            Email = 'email@sample.com',
            Status = 'Qualified'
        );
        insert testLead;

        Account a = new Account(
            Lead__c = testLead.Id,
            Name = 'Test Account', 
            BillingStreet = '123 Test St', 
            BillingCity = 'Testcity', 
            BillingStateCode = 'MA', 
            BillingPostalCode = '02633'
        );
        insert a;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = testLead.Id,
            Account__c = a.Id, 
            Name = '123456', 
            Name_on_Account__c = 'Firstname Lastname', 
            Service_Address__c = '123 Test St', 
            Service_City__c = 'Testcity', 
            Service_State__c = 'MA', 
            Service_Zip_Code__c = '02633' 
        );
        insert ual;

        LeadSelector selector = new LeadSelector();
        Lead l = selector.selectOneWithPropertiesAndUtilities(testLead.Id);
        System.assertNotEquals(null, l, 'Selector should have returned a lead record');
        System.assertEquals(1, l.Accounts__r.size(), 'Selector should have returned a child account with the lead record');
        System.assertEquals(1, l.Utility_Account_Logs__r.size(), 'Selector should have returned a child utility account log with the lead record');
    }

    @IsTest
    private static void testSelectOneIncompleteSSFLeadByEmail() {
        Lead matchingLead = new Lead(
            FirstName = 'Match',
            LastName = 'Testcase',
            Email = 'test@email.com',
            Company = 'Testcase',
            LeadSource = 'Switch',
            Continue_Application_Link__c = 'continueURL.com'
        );

        insert matchingLead;

        Lead checkLead = new LeadSelector().selectOneIncompleteSSFLeadByEmail('test@email.com');
        System.assertNotEquals(null, checkLead);
        Lead noMatchLead = new LeadSelector().selectOneIncompleteSSFLeadByEmail('nomatch@email.com');
        System.assertEquals(null, noMatchLead);
    }
}