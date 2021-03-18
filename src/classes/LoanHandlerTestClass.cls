@isTest
public class LoanHandlerTestClass {
    @testSetup public static void setupTestData(){
        Test.startTest();
        List<String> partnerSetUpIds = new List<String>();  
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanHandlerLeadRecords());
        LoanHandler.createResidentialEquipment(leadList);
        LoanHandler.createLoan(leadList);
        Test.stopTest();
    }
 

    public static void convertLeads(List<Lead> leadList){
        convertLeads(leadList, 0);
    }

    public static void convertLeads(List<Lead> leadList, Integer counter) {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=true LIMIT 1];
        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead l :leadList){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);
        }
        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        for (Database.LeadConvertResult lcr : lcrs)  {
            if (!lcr.isSuccess() && counter < 3) {
                Lead failedLead = new Lead (id = lcr.getLeadId());
                convertLeads( new List<Lead>{failedLead}, counter+1);
            } else if (!lcr.isSuccess()) {
                System.assertEquals(null, System.JSON.serializePretty(lcr.getErrors()));
            }
        }
    }

}