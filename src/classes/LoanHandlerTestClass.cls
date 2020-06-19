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

    public static void changeLeadUpdateDummy(List<Lead> leadList) {
      for (Lead leadRecord : leadList) {
          leadRecord.Update_Dummy__c = !leadRecord.Update_Dummy__c;
      }
      update leadList;
    }    
    public static void changeLeadUpdateDummyMSLP(List<Lead> leadList) {
        List<Lead> leadListToUpdate = new List<Lead>();
        for (Lead leadRecord : leadList) {
            if(leadRecord.Update_Dummy__c == true) {
                leadRecord.Update_Dummy__c = false;
            }else {
                leadRecord.Update_Dummy__c = true;
            }
            leadListToUpdate.add(leadRecord);
        }
        update leadListToUpdate;
    }

 
    private static Attachment getAttachment(Id parentId, String description) {
        Attachment attachment = new Attachment();
        attachment.Name = 'test.txt';
        attachment.Body = Blob.valueOf('Unit Test Attachment Body');
        attachment.ParentId = parentId;
        attachment.Description = description;
        return attachment;
    }

    @IsTest static void testDaysPastDue() {
        List<Loan__c> loans = [SELECT Id, Days_Past_Due__c, Number_of_Days_Past_Due__c FROM Loan__c];
        System.assertEquals(5, loans.size());

        Map<Integer, String> expectedDPD = new Map<Integer, String>();
        expectedDPD.put(null, null);
        expectedDPD.put(0, null);
        expectedDPD.put(1, '1-30');
        expectedDPD.put(30, '1-30');
        expectedDPD.put(31, '31-60');
        expectedDPD.put(60, '31-60');
        expectedDPD.put(61, '61-90');
        expectedDPD.put(90, '61-90');
        expectedDPD.put(91, '91+');
        expectedDPD.put(101, '91+');

        Integer loanIndex = 0, loansChecked = 0;
        for (Integer nDPD : expectedDPD.keySet()) {
            if (loanIndex < loans.size()) {
                loans[loanIndex].Number_of_Days_Past_Due__c = nDPD;
                loanIndex++;
            } else {
                LoanHandler.resetTriggerContext();
                update loans;
                checkDaysPastDue(expectedDPD);
                loanIndex = 0;
                loansChecked += loans.size();
            }
        }
        LoanHandler.resetTriggerContext();
        update loans;
        checkDaysPastDue(expectedDPD);
        loansChecked += loans.size();
        System.assert(loansChecked >= expectedDPD.keySet().size(), 'We should check ' + expectedDPD.keySet().size() + ' + Days Past Due combinations, but only checked ' + loansChecked);
    }

    private static void checkDaysPastDue(Map<Integer, String> expectedDPD) {
        List<Loan__c> loans = [SELECT Id, Days_Past_Due__c, Number_of_Days_Past_Due__c FROM Loan__c];
        for (Loan__c loan : loans) {
            System.assertEquals(expectedDPD.get((Integer) loan.Number_of_Days_Past_Due__c), loan.Days_Past_Due__c);
        }
    }
}