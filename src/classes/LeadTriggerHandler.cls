/*************************************************************************************
 * Test: LeadTriggerHandlerTest
 *************************************************************************************/

public without sharing class LeadTriggerHandler {
    public static Boolean firstRun = true;
    @TestVisible private static DocuSignHelper dsh;
    @TestVisible private static Boolean skipContractSend = false;
    private Map<String, String> leadToOppConvertMap = new Map<String, String> {
        'Annual_Income_Currency__c'=>'Annual_Independent_Income__c',
        'Application__c'=>'Application_Date__c',
        'Application_Type__c'=>'Application_Type__c',
        'Co_Applicant_Address__c'=>'Co_Applicant_Address__c',
        'Co_Applicant_Date_of_Birth__c'=>'Co_Applicant_Date_of_Birth__c',
        'Co_Applicant_Email__c'=>'Co_Applicant_Email__c',
        'Co_Applicant_First_Name__c'=>'Co_Applicant_First_Name__c',
        'Co_Applicant_Income__c'=>'Co_Applicant_Income__c',
        'Co_Applicant_Last_Name__c'=>'Co_Applicant_Last_Name__c',
        'Co_Applicant_Phone__c'=>'Co_Applicant_Phone__c',
        'Company'=>'Name',
        'Date_of_Application_2__c'=>'Date_of_Application__c',
        'Date_of_Issuance__c'=>'Date_of_Issuance__c',
        'Direct_Disbursal_to_Installer_Authorized__c'=>'Direct_Disbursal_to_Installer_Authorized__c',
        'DOER_Solar_Loan__c'=>'DOER_Solar_Loan__c',
        'Electronic_Disbursal_Authorized__c'=>'Electronic_Disbursal_Authorized__c',
        'Email_Re_Enter__c'=>'Email__c',
        'Employed_for_more_than_one_year__c'=>'Employed_for_more_than_one_year__c',
        'Employed_for_more_than_six_months__c'=>'Employed_for_more_than_six_months__c',
        'IBLS_Category__c'=>'IBLS_Category_MappedFromLead__c',
        'Income_Type__c'=>'Income_Type__c',
        'Income_Type_2__c'=>'Income_Type_2__c',
        'Joint_Applicant_Type__c'=>'Joint_Applicant_Type__c',
        'Lead_ID__c'=>'Lead_ID__c',
        'MobilePhone'=>'Customer_Phone__c',
        'lived_residence_six_months__c'=>'Lived_at_residence_more_than_six_months__c',
        'Partner_Lookup__c'=>'Partner_tag_lookup__c',
        'Partner_Email__c'=>'Partner_Email__c',
        'Partner_Tag__c'=>'Partner_Tag__c',
        'Personal_Credit_Report__c'=>'Personal_Credit_Report2__c',
        'Personal_Credit_Report_Co_Applicant__c'=>'Personal_Credit_Report_Co_Applicant__c',
        'Product__c'=>'Product__c',
        'Product_line__c'=>'Product_Line__c',
        'Product_Program__c'=>'Product_Program__c',
        'Project_Identification_Number__c'=>'project_identification_number__c',
        'Referral_Email__c'=>'Referral_Email__c',
        'Requested_Loan_Amount__c'=>'Requested_Loan_Amount__c',
        'Residence_Owner__c'=>'Residence_Owner__c',
        'bs_Sales_ID__c'=>'BS_Sales_ID__c',
        'Sales_Person__c'=>'Sales_Person_Tag__c',
        'SREC_Product__c'=>'SREC_Product__c',
        'State_of_Issuance__c'=>'State_of_Issuance__c',
        'System_Cost__c'=>'Loan_Principle__c',
        'OwnerId'=>'OwnerId'
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
        List<Lead> convertedCSLeads = new List<Lead>();
        for (Lead lead : updatedLeads) {
            if (lead.IsConverted && !oldLeadMap.get(lead.Id).IsConverted &&
                lead.ConvertedAccountId != null &&
                lead.Product_line__c == 'Community Solar' &&
                firstRun) {
                convertedCSLeads.add(lead);
            }
            if (lead.IsConverted && !oldLeadMap.get(lead.Id).IsConverted) {
                convertCasestoAccount(lead);
            }
            if (!lead.Docs_Requested__c && oldLeadMap.get(lead.Id).Docs_Requested__c) {
                LoanHandler.completeAdditionalIncomeDocTask(lead.Id);
            }
            if (lead.Status == 'Qualified' &&
                oldLeadMap.get(lead.Id).Status != 'Qualified' &&
                !Test.isRunningTest()) {
                CAPController.sendContractIfAbsent(lead, lead.Email);
            }
        }
        if (!convertedCSLeads.isEmpty()) {
            deleteDuplicateContact(convertedCSLeads);
            customerSubscriptionProcess(convertedCSLeads);
            firstRun = false;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Lead lead: updatedLeads) {
            if (lead.IsConverted) {
                Opportunity opp = getUpdatedOpp(lead, oldLeadMap.get(lead.Id));
                if (opp != null) {
                    oppsToUpdate.add(opp);
                }
            }
        }
        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (Exception e) {
                Logger.logNow('LeadTriggerHandler', 'onAfterUpdate',
                    'Could\'t update opps after lead update:' + e.getMessage() + System.JSON.serializePretty(oppsToUpdate));
            }

        }

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


    private void customerSubscriptionProcess(List<Lead> leads) {
        CSSubscriptionEnroller repo = new CSSubscriptionEnroller(leads);
        repo.enroll();
    }

    private void deleteDuplicateContact (List<Lead> convertedLeads) {
        Set<Id> parentAccountIds = new Set<Id>();
        List<Contact> contactsToDelete = new List<Contact>();
        Set<Account> propertyAccountsToUpdate = new Set<Account>();
        Map<Id, Id> propertyToParentAccountMap = new Map<Id, Id>();
        Map<Id, Id> parentAccountToContactMap = new Map<Id, Id>();
        for (Lead lead : convertedLeads) {
            parentAccountIds.add(lead.Parent_AccountId__c);
            propertyToParentAccountMap.put(lead.ConvertedAccountId, lead.Parent_AccountId__c);
        }

        List<Contact> relatedContacts = [
            SELECT Id, Name, AccountId
            FROM Contact
            WHERE AccountId = :parentAccountIds
        ];
        for (Contact contact : relatedContacts) {
            parentAccountToContactMap.put(contact.AccountId, contact.Id);
        }

        // Converted CS contacts are always duplicates, because we create the parent account's contact explicitly
        for (Lead lead : convertedLeads) {
            contactsToDelete.add(new Contact(Id = lead.ConvertedContactId));

            // We need to set the billing contact on the converted lead's account
            Id billingContact = parentAccountToContactMap.get(propertyToParentAccountMap.get(lead.ConvertedAccountId));
            if (billingContact != null) {
                propertyAccountsToUpdate.add(new Account(
                    Id = lead.ConvertedAccountId,
                    Send_Bills_Contact__c = parentAccountToContactMap.get(propertyToParentAccountMap.get(lead.ConvertedAccountId))
                ));
            }
        }
        delete contactsToDelete;
        if (!propertyAccountsToUpdate.isEmpty()) {
            update new List<Account>(propertyAccountsToUpdate);
        }
    }

    private void convertCasestoAccount(Lead convertedLead){
        List<Case> casesList = [SELECT Id, Lead_Lookup__r.ConvertedAccountId, Lead_Lookup__r.ConvertedContactId,
            Lead_Lookup__r.isConverted, Lead_Lookup__r.Product_Line__c, AccountId, ContactId
        FROM Case
        WHERE Lead_Lookup__r.Id = : convertedLead.id
        AND (AccountId = NULL OR ContactId = NULL)];

        for (Case caseToUpdate : casesList) {
            if ( caseToUpdate.AccountId == NULL){
                caseToUpdate.AccountId = convertedLead.ConvertedAccountId;
            }
            if ( caseToUpdate.ContactId == NULL && caseToUpdate.Lead_Lookup__r.Product_Line__c != 'Community Solar'){
                caseToUpdate.ContactId = convertedLead.ConvertedContactId;
            }
        }
        update casesList;
    }

    private Opportunity getUpdatedOpp(Lead newLead, Lead oldLead) {
        Boolean returnNull = true;
        Opportunity opp = new Opportunity(Id = newLead.ConvertedOpportunityId);
        for (String field : leadToOppConvertMap.keySet()) {
            if (newLead.get(field) != oldLead.get(field)) {
                opp.put(leadToOppConvertMap.get(field), newLead.get(field));
                returnNull=false;
            }
        }
        return (returnNull?null:opp);
    }

}