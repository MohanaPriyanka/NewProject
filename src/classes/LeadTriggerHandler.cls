/*************************************************************************************
 * Test: LeadTriggerHandlerTest
 *************************************************************************************/

public without sharing class LeadTriggerHandler {
    public static Boolean firstRun = true;
    @TestVisible private static DocuSignHelper dsh;
    @TestVisible private static Boolean skipContractSend = false;
    private Map<String, String> leadToOppConvertMap = new Map<String, String> {
        'Acquired_By_Client_Closed_By_BlueWave__c'=>'Acquired_By_Client_Closed_By_BlueWave__c',
        'Application__c'=>'Application_Date__c',
        'Application_Type__c'=>'Application_Type__c',
        'bs_Sales_ID__c'=>'BS_Sales_ID__c',
        'Company'=>'Name',
        'Date_of_Application_2__c'=>'Date_of_Application__c',
        'Lead_ID__c'=>'Lead_ID__c',
        'MobilePhone'=>'Customer_Phone__c',
        'OwnerId'=>'OwnerId',
        'Partner_Account__c' => 'Partner_Account__c',
        'Partner_Contact__c' => 'Partner_Contact__c',
        'Partner_Email__c'=>'Partner_Email__c',
        'Partner_Lookup__c'=>'Partner_tag_lookup__c',
        'Partner_Tag__c'=>'Partner_Tag__c',
        'Personal_Credit_Report__c'=>'Personal_Credit_Report2__c',
        'Product__c'=>'Product__c',
        'Product_line__c'=>'Product_Line__c',
        'Product_Program__c'=>'Product_Program__c',
        'Referral_Email__c'=>'Referral_Email__c',
        'Underwriting_Criteria__c'=>'Underwriting_Criteria__c'
    };

    public void onBeforeInsert(List<Lead> leadList){
        List<Lead> communitySolarLeads = new List<Lead>();
        for (Lead lead : leadList) {
            if (lead.Product_Line__c == 'Community Solar') {
                communitySolarLeads.add(lead);
            }
        }
        UtilityLoadZoneService.updateLZUL(communitySolarLeads, null);
    }
    public void onBeforeUpdate(List<Lead> oldLeads, List<Lead> updatedLeads, Map<ID, Lead> oldLeadMap, Map<ID, Lead> newLeadMap){
        List<Lead> communitySolarLeads = new List<Lead>();
        Map<Id, Lead> communitySolarOldLeadMap = new Map<Id, Lead>();

        for (Lead lead : updatedLeads) {
            if (lead.Product_Line__c == 'Community Solar') {
                communitySolarLeads.add(lead);
            }
        }
        for (Lead lead : oldLeadMap.values()) {
            if (lead.Product_Line__c == 'Community Solar') {
                communitySolarOldLeadMap.put(lead.Id, lead);
            }
        }

        UtilityLoadZoneService.updateLZUL(communitySolarLeads, communitySolarOldLeadMap);
    }
    
    public void onAfterUpdate(List<Lead> oldLeads, List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        
        // As part of the Loan Change Order process, if docs are generated (which implies the lead is converted), we
        // need to void them, regenerate, and send.
        List<Id> oppsWithAuthorizedChange = new List<Id>();
        for (Lead lead : updatedLeads) {
            if (lead.ConvertedOpportunityId != null &&
                lead.Change_Order_Status__c == 'Customer Authorized' &&
                oldLeadMap.get(lead.Id).Change_Order_Status__c != 'Customer Authorized') {
                oppsWithAuthorizedChange.add(lead.ConvertedOpportunityId);
            }
        }
        if (!oppsWithAuthorizedChange.isEmpty()) {
            DocuSignHelper.handleLoanChangeOrder(System.JSON.serialize(oppsWithAuthorizedChange));
        }
    }
    
}