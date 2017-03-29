/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: The SLPAddCustomer class serves as a controller for the SLPAddCustomer Lightning component bundle. It allows the user to 
 * add new customers to the database.
 *
 * Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPAddCustomer {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    //the addNewLeadRecord method adds a new SL customer to the database via the SLP
    @AuraEnabled
    public static Lead addNewLeadRecord (Lead newLead) {
        RecordType leadRecordType;
        String recordType;
        String productProgram;
        if (newLead.DOER_Solar_Loan__c) {
            recordType = 'BFG - DOER Solar Loan';
            productProgram = 'MSLP';
        } else {
            recordType = 'BlueWave Solar Loan';
            productProgram = 'BlueWave Solar Loan';
        }

        leadRecordType = [SELECT Id 
                          FROM RecordType 
                          WHERE Name = : recordType
                          AND SobjectType = 'Lead' 
                          LIMIT 1];

        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Product_Program__c = productProgram;
        newLead.Partner_Lookup__c = profile.partnerId;
        newLead.bs_Sales_ID__c = profile.salesRepId;
        newLead.Product_Line__c = 'Residential Loan';
        newLead.RecordTypeId = leadRecordType.Id;
        insert newLead;

        return newLead;
    }

    // Assumes the version of Laser Credit Access that pulls credit via trigger and future method
    // For errors, check Apex Jobs (https://login.salesforce.com/apexpages/setup/listAsyncApexJobs.apexp)
    // or Credit Report Log objects related to the Lead
    @AuraEnabled
    public static void pullCreditStatus(Lead lead) {
        lead.LASERCA__Pull_Credit_Report__c = true;
        update lead;
    }

    //the getPartnerRecord method returns the partner record to the lightning component. It is currently being used to identify the partner's
    //state to determine if the add a customer page should allow the user to submit MSLP applications
    @AuraEnabled
    public static Partner__c getPartnerRecord() {
        return [SELECT Id, Name, Logo__c, State__c 
                FROM Partner__c 
                WHERE Id = : profile.partnerId LIMIT 1];       
    }     
}