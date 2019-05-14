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
}