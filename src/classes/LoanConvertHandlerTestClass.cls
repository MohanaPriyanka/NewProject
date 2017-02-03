@isTest
public class LoanConvertHandlerTestClass {
    @testSetup public static void setupTestData(){

        List<Product2> productList = new List<Product2>(LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms());
        insert productList;
        System.debug(productList);

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms());
        //insert leadList;
        System.debug(leadList);     

    }
       @isTest static void testLoanConversion() {
 
        Test.startTest();

        boolean nullFail = false;
        List<Lead> qualifiedLeadList = new list<Lead>();
        List<String> leadIds = new List<String>();
        List<String> convertedOppIds = new List<String>();
        List<Loan__c> convertedLoanList = new List<Loan__c>();
        Map<String, lead> qualifiedLeadMap = new Map<String,Lead>();            
        Map<String, lead> updatedLeadMap = new Map<String,Lead>();    
        Map<String, Loan__c> loanMap = new Map<String, Loan__c>();
        List<String> loanIdList = new List<String>();
        List<String> oppIds = new List<String>();  
        String leadIdString;
        Integer loanCount;
        Integer leadCount = 0;

        for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id FROM Lead]){
            leadCount = leadCount + 1;
            leadRecord.Status = 'Qualified';
            leadRecord.Technical_Approval_Verified__c = true;
            leadRecord.Income_Verified__c = true;
            leadRecord.Is_there_a_Partner_Record__c = true;
            qualifiedLeadMap.put(leadRecord.FirstName, leadRecord);
        }

        update qualifiedLeadMap.values();

        System.debug('The Updated QualifiedLeadMap is ' + qualifiedLeadMap.values());

        for (Lead l : qualifiedLeadMap.values()){
            leadIdString = String.ValueOf(l.Id).SubString(0,15);
            leadIds.add(leadIdString);

            database.leadConvert lc = new database.leadConvert();
            lc.setLeadId(l.Id);

            leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());

            convertedOppIds.add(l.ConvertedOpportunityId);
        }
        System.assert(convertedOppIds.size() > 0);

        List<Opportunity> convertedOppList = new List<Opportunity>();
        for (Opportunity convertedOpp : [SELECT Id, Name, StageName, Lead_Id__c,
                                                (SELECT Id FROM Loans__r)
                                                FROM Opportunity 
                                                WHERE Lead_Id__c IN : leadIds]){
            if (convertedOpp.Loans__r.size() > 0){
                convertedOpp.StageName = 'Complete';
                convertedLoanList.add(convertedOpp.Loans__r);
                convertedOppList.add(convertedOpp);
                oppIds.add(convertedOpp.Id);
            }
        }
        update convertedOppList;

        List<Opportunity> oppUpdateList = new List<Opportunity>();
        System.debug('The convertedOppList size is ' + convertedOppList.size());
        System.debug('The convertedLoanList size is ' + convertedLoanList.size());
        System.assert(convertedOppList.size() > 0);
        System.assert(convertedLoanList.size() > 0);
        System.assert(convertedOppList.size() == convertedLoanList.size());

        //List<Disbursal__c> disbursalList = [SELECT Id, Name FROM Disbursal__c];

        //System.assert(disbursalList.size() == 11);      

        Test.stopTest();

    }
}

 
        //Test.startTest();
        //boolean nullFail = false;
        //List<Lead> qualifiedLeadList = new list<Lead>();
        //Map<String, lead> qualifiedLeadMap = new Map<String,Lead>();        
        //for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id FROM Lead]){
        //    leadRecord.Status = 'Qualified';
        //    System.debug('The Product ID is ' + leadRecord.Product__r.Id);
        //    qualifiedLeadMap.put(leadRecord.FirstName, leadRecord);
        //}
        //update qualifiedLeadMap.values();
        //System.debug('The updated qualifiedLeadMap is' + qualifiedLeadMap.values());