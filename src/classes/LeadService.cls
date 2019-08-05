/**
 * Created by SarahRenfro on 5/15/2019.
 *
 * Tested By: LeadServiceTestclass
 */

public without sharing class LeadService {
    public static Boolean firstRun = true;

    private AccountService accountService = new AccountService();
    private UALService ualService = new UALService();

    private LeadSelector leadSelector = new LeadSelector();


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

    /**
     * Copies Property Account info from a Lead
     *
     * @deprecated  Not to be used after Switch moves to v2 API (new Property Account / UAL structure)
     */
    public Account buildPropertyAccountFromLegacyLead(Lead lead) {
        Id recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
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
        return propAcct;
    }


    /**
     * Copies UAL info from a Lead
     *
     * @deprecated  Not to be used after Switch moves to v2 API (new Property Account / UAL structure)
     */
    public Utility_Account_Log__c buildUtilityAccountLogFromLegacyLead(Lead lead, Account propertyAccount) {

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = '',
            Account__c = propertyAccount.Id,
            Name_on_Account__c = propertyAccount.Name,
            Service_Address__c = lead.LASERCA__Home_Address__c,
            Service_City__c = lead.LASERCA__Home_City__c,
            Service_State__c = lead.LASERCA__Home_State__c,
            Service_Zip_Code__c = lead.LASERCA__Home_Zip__c,
            Utility_lookup__c = lead.Utility_relationship__c,
            Lead__c = lead.Id
        );

        return ual;
    }

    /**
     * Inserts a legacy lead into the new data model
     *
     * @deprecated  Not to be used after Switch moves to v2 API (new Property Account / UAL structure)
     */
    public Lead createLegacyLead(Lead lead) {
        lead = this.insertLead(lead);
        Account propertyAccount = accountService.insertAccount(this.buildPropertyAccountFromLegacyLead(lead));
        ualService.insertUAL(this.buildUtilityAccountLogFromLegacyLead(lead, propertyAccount));
        return lead;
    }

    public Lead insertLead(Lead lead) {
        //Set DMLOptions to run Lead Assignment Rules on insert
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        lead.setOptions(dmo);

        insert lead;
        lead = leadSelector.selectOne(lead.Id);
        return lead;
    }

    public Lead updateLead(Lead lead) {
        update lead;
        lead = leadSelector.selectOne(lead.Id);
        return lead;
    }

}