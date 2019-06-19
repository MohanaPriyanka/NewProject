/**
 * Created by SarahRenfro on 5/15/2019.
 *
 * Tested By: LeadServiceTestclass
 */

public without sharing class LeadService {
    public static Boolean firstRun = true;
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

    public void setupPropertyAccount(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap) {
        List<Account> propertyAccounts = new List<Account>();
        Id recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();

        for (Lead lead : updatedLeads) {
            if (lead.Status == 'Qualified' && oldLeadMap.get(lead.Id).Status != 'Qualified') {
                //Create Property Account for Qualified Leads - will store UALs
                Account propAcct = new Account(
                    Name = lead.Company,
                    Product_Line__c = lead.Product_line__c,
                    RecordTypeId = recordType,
                    Electricity_Provider__c = lead.Utility_relationship__r.Id,
                    Lead__c = lead.Id,
                    BillingStreet = lead.LASERCA__Home_Address__c,
                    BillingCity = lead.LASERCA__Home_City__c,
                    BillingState = BlueWaveParent.convertAbbreviationToState(lead.LASERCA__Home_State__c.toUpperCase()),
                    BillingPostalCode = lead.LASERCA__Home_Zip__c
                );

                propertyAccounts.add(propAcct);
            }
        }

        try {
            insert propertyAccounts;
        } catch (DmlException e) {
            Logger.logNow('LeadService', 'setupQualifiedLead', 'Failed to create Property Account for Leads: ' +  e.getMessage() + System.JSON.serializePretty(updatedLeads));
        }
    }

    public void completeLeadConversion(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        List<Lead> convertedCSLeads = new List<Lead>();

        for (Lead lead : updatedLeads) {
            if (lead.IsConverted && !oldLeadMap.get(lead.Id).IsConverted &&
                lead.ConvertedAccountId != null &&
                lead.Product_line__c == 'Community Solar' &&
                firstRun) {
                convertedCSLeads.add(lead);
            }

            if (lead.ConvertedAccountId != null) {
                setupSwitchLead(lead);
            }
        }

        if (!convertedCSLeads.isEmpty()) {
            CSSubscriptionEnroller repo = new CSSubscriptionEnroller(convertedCSLeads);
            repo.enroll();
            firstRun = false;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Lead lead : updatedLeads) {
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
            } catch(Exception e) {
                Logger.logNow('LeadService', 'completeLeadConversion', 'Couldn\'t update opps after lead update: ' + e.getMessage() + System.JSON.serializePretty(oppsToUpdate));
            }
        }
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


    public void setupSwitchLead(Lead lead){
        List<Account> propAcctsList = new List<Account>();
        List<Account> updateAccounts = new List<Account>();

        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lead.ConvertedAccountId LIMIT 1];
        Contact convertedContact = [SELECT Id FROM Contact WHERE Id = :lead.ConvertedContactId LIMIT 1];

        propAcctsList = [
            SELECT Id, Parent_Account__c, Send_Bills_Contact__c
            FROM Account
            WHERE Lead__c = :lead.Id AND RecordType.Name = 'Property'
        ];

        Id recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        convertedAccount.ShippingStreet = lead.Street;
        convertedAccount.ShippingCity = lead.City;
        convertedAccount.ShippingState = lead.State;
        convertedAccount.ShippingPostalCode = lead.PostalCode;
        convertedAccount.RecordTypeId = recordType;
        convertedAccount.BillingStreet = lead.LASERCA__Home_Address__c;
        convertedAccount.BillingCity = lead.LASERCA__Home_City__c;
        convertedAccount.BillingState = BlueWaveParent.convertAbbreviationToState(lead.LASERCA__Home_State__c);
        convertedAccount.BillingPostalCode = lead.LASERCA__Home_Zip__c;
        convertedAccount.OwnerId = apiUser.Id;

        convertedContact.LASERCA__Home_Address__c = lead.LASERCA__Home_Address__c;
        convertedContact.LASERCA__Home_City__c = lead.LASERCA__Home_City__c;
        convertedContact.LASERCA__Home_State__c = lead.LASERCA__Home_State__c;
        convertedContact.LASERCA__Home_Zip__c = lead.LASERCA__Home_Zip__c;
        convertedContact.Product_Line__c = 'Community Solar';

        update convertedContact;
        updateAccounts.add(convertedAccount);


        for (Account propAcct : propAcctsList) {
            propAcct.Parent_Account__c = convertedAccount.Id;
            propAcct.Send_Bills_Contact__c = convertedContact.Id;
            propAcct.UAL_Convert__c = true;
            updateAccounts.add(propAcct);
        }

        if (updateAccounts.size() > 0 ) {
            update updateAccounts;
        }

    }

    public void convertCasesToContact(List<Lead> convertedLeads) {
        List<Case> updateCases = new List<Case>();
        List<Case> casesList = [
            SELECT Id, Subject, Lead_Lookup__r.ConvertedAccountId, Lead_Lookup__r.ConvertedContactId, Lead_Lookup__r.IsConverted,
                Lead_Lookup__r.Product_line__c, AccountId, ContactId
            FROM Case
            WHERE Lead_Lookup__r.Id IN :convertedLeads
            AND Lead_Lookup__r.IsConverted = TRUE
            AND (AccountId = NULL OR ContactId = NULL)
        ];

        for (Case caseToUpdate : casesList) {
            if (caseToUpdate.ContactId == null)  {
                caseToUpdate.ContactId = caseToUpdate.Lead_Lookup__r.ConvertedContactId;
                updateCases.add(caseToUpdate);
            }
        }

        if (updateCases.size() > 0 ) {
            update updateCases;
        }

    }




}