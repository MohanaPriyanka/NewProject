@isTest
private class createLoanTestClass{

    @testSetup public static void setupTestData(){

        //List<Product2> productList = new List<Product2>(LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms());
        //insert productList;
        //System.debug(productList);

        //List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms());
        ////insert leadList;
        //System.debug(leadList);     

    }
    @isTest static void testLoanProductAssignment() {
 
    //    Test.startTest();
    //    boolean nullFail = false;
    //    List<Lead> qualifiedLeadList = new list<Lead>();
    //    Map<String, lead> qualifiedLeadMap = new Map<String,Lead>();        
    //    for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id FROM Lead]){
    //        leadRecord.Status = 'Qualified';
    //        System.debug('The Product ID is ' + leadRecord.Product__r.Id);
    //        qualifiedLeadMap.put(leadRecord.FirstName, leadRecord);
    //    }
    //    update qualifiedLeadMap.values();
    //    System.debug('The updated qualifiedLeadMap is' + qualifiedLeadMap.values());
        
    //    Map<String, lead> updatedLeadMap = new Map<String,Lead>();        
    //    for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id 
    //                           FROM Lead]){

    //        updatedLeadMap.put(leadRecord.Id, leadRecord);
    //        qualifiedLeadList.add(leadRecord);
    //        System.debug('The updatedLeadMap is ' + updatedLeadMap);
    //    }        
    //    Map<String, Loan__c> loanMap = new Map<String, Loan__c>();
    //    List<String> loanIdList = new List<String>();
    //    for (Loan__c loanRecord : [SELECT Id, Name, Lead__r.Id FROM Loan__c]){
    //        loanMap.put(loanRecord.Lead__r.Id, loanRecord);
    //        loanIdList.add(loanRecord.Id);
    //    }
    //    //List<Disbursal__c> disbursalList = [SELECT Id, Name, Loan__r.Id FROM Disbursal__c];
    //    List<Task> taskList = [SELECT Id, Unique_ID__c, Subject, Loan__r.Id FROM Task WHERE Loan__r.Id IN : loanIdList];
    //    Test.stopTest();

    //    //System.assert(disbursalList.size() == 12);
    //    System.debug('The Task List size is ' + taskList.size());
    //    System.debug(taskList);
    //    //System.assert(taskList.size() == 23);
    //    System.assert(loanMap.size() == 4);
    //    for (Lead leadRecordVerify : qualifiedLeadList){
    //        try{
    //            loanMap.get(leadRecordVerify.Id);
    //        }
    //        catch(NullPointerException ex){
    //            nullFail = true;
    //        }
    //    }
    //    System.assertEquals(nullFail, false); 
    }
}