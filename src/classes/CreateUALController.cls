public class CreateUALController {
    @AuraEnabled
    public static List<Utility_Account_Log__c> getUALs(String propAccount) {
        List<Utility_Account_Log__c> ualList = [SELECT Id, Name, Account__c, Annual_Cost_of_Electricity__c, Service_Address__c, Service_City__c, 
                                                Service_State__c, Service_Zip_Code__c, Name_on_Account__c, Account_ID__c 
                                                FROM Utility_Account_Log__c 
                                                WHERE Account_ID__c = : propAccount];
        return ualList;
    }
}