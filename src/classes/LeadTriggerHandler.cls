/*************************************************************************************
 * Test: LeadTriggerHandlerTest
 *************************************************************************************/

public without sharing class LeadTriggerHandler {
    public static Boolean firstRun = true;
    @TestVisible
    private static DocuSignHelper dsh;
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
        'Sales_Person__c'=>'Sales_Person_Tag__c',
        'SREC_Product__c'=>'SREC_Product__c',
        'State_of_Issuance__c'=>'State_of_Issuance__c',
        'System_Cost__c'=>'Loan_Principle__c'
    };

    public void onBeforeInsert(List<Lead> leadList){
        List<Lead> communitySolarLeads = new List<Lead>();
        for (Lead lead : leadList) {
            if (lead.Product_Line__c == 'Community Solar') {
                communitySolarLeads.add(lead);
            }
        }
        updateLZUL(communitySolarLeads, null);
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
        updateLZUL(communitySolarLeads, communitySolarOldLeadMap);
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
        }
        if (!convertedCSLeads.isEmpty()) {
            deleteDuplicateContact(convertedCSLeads);
            customerSubscriptionProcess(convertedCSLeads);
            firstRun = false;
        } 

        for (Lead lead : updatedLeads) {
            if (lead.IsConverted && !oldLeadMap.get(lead.Id).IsConverted) {
                convertCasestoAccount(lead);
            }
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
    
    private void updateLZUL(List<Lead> leadList, Map<ID, Lead> oldLeadMap){
        Set<String> zipCodeSet = new Set<String>();
        for (Lead l : leadList){
            if (l.Parcel_Zip__c != null){
                zipCodeSet.add(l.Parcel_Zip__c);
            }
        }
        if (zipCodeSet.size() > 0 ){
            Map<String, Load_u__c> validLZU = new Map<String, Load_u__c>();
            for (Load_u__c obj : [SELECT Id, Name, Load_Zone__c, LZ__c, Utility__c FROM Load_u__c WHERE Name IN : zipCodeSet] ){
                validLZU.put(obj.Name, obj); 
            }
            for (Lead l : leadList){
                if (oldLeadMap == null || oldLeadMap.get(l.Id).Parcel_Zip__c != l.Parcel_Zip__c){
                    if (validLZU.containsKey (l.Parcel_Zip__c)){
                        l.LZU__c = validLZU.get (l.Parcel_Zip__c).Load_Zone__c;
                        l.Load_Zone__c = validLZU.get (l.Parcel_Zip__c).LZ__c;
                        l.Utility_1__c = validLZU.get(l.Parcel_Zip__c).Utility__c;
                    }
                }
                else if (oldLeadMap.get(l.Id).Parcel_Zip__c != l.Parcel_Zip__c && !validLZU.containsKey(l.Parcel_Zip__c)){
                    l.LZU__c = null;
                    l.Load_Zone__c = null;
                    l.Utility_1__c = null;
                }
            }
        }
    }

    // Used by the CS process since opportunities aren't created on lead conversion
    private static Opportunity setDefaultOppFields(Lead lead, Opportunity opp){
        opp.AccountId = lead.convertedAccountId;
        opp.Assessors_Parcel_Number__c = lead.Accessor_s_Parcel_Number__c;
        opp.Annual_Independent_Income__c = lead.Annual_Income_Currency__c;
        opp.Application_Date__c = lead.Application__c;
        opp.Application_Type__c = lead.Application_Type__c;
        opp.Avidia_Checking_Account__c = lead.Avidia_Checking_Account__c;
        opp.Business_Title__c = lead.Business_Title__c;
        opp.Co_Applicant_Date_of_Birth__c = lead.Co_Applicant_Date_of_Birth__c;
        opp.Co_Applicant_Email__c = lead.Co_Applicant_Email__c;
        opp.Co_Applicant_First_Name__c = lead.Co_Applicant_First_Name__c;
        opp.Co_Applicant_Income__c = lead.Co_Applicant_Income__c;
        opp.Co_Applicant_Last_Name__c = lead.Co_Applicant_Last_Name__c;
        opp.Co_Applicant_Phone__c = lead.Co_Applicant_Phone__c;
        opp.Commencement_Date__c = lead.Commencement_Date__c;
        opp.Cumulative_Loan_to_Value__c = lead.Cumulative_Loan_to_Value_if_Applicable__c;
        opp.Customer_Referral__c = lead.Customer_Referral__c;
        opp.Customer_type__c = lead.Customer_type__c;
        opp.Customer_Group__c = lead.Customer_Type_Formula__c;
        opp.Custom_ID__c = lead.Custom_ID__c;
        opp.Date_of_Application__c = lead.Date_of_Application__c;
        opp.Date_of_Expiration__c = lead.Date_of_Expiration__c;
        opp.Date_of_Issuance__c = lead.Date_of_Issuance__c;
        opp.Direct_Disbursal_to_Installer_Authorized__c = lead.Direct_Disbursal_to_Installer_Authorized__c;
        opp.DOER_Solar_Loan__c = lead.DOER_Solar_Loan__c;
        opp.Utility_Account__c = lead.Electric_Account_Number__c;
        opp.Electronic_Disbursal_Authorized__c = lead.Electronic_Disbursal_Authorized__c;
        opp.Email__c = lead.Email_Re_Enter__c;
        opp.Employed_for_more_than_one_year__c = lead.Employed_for_more_than_one_year__c;
        opp.Employed_for_more_than_six_months__c = lead.Employed_for_more_than_six_months__c;
        opp.External_System_Lead_ID__c = lead.External_System_Lead_ID__c;
        opp.Form_Completion_Time__c = lead.Form_Completion_Time__c;
        opp.State_ab__c = lead.LASERCA__Home_State__c;
        opp.Income_Type__c = lead.Income_Type__c;
        opp.Income_Type_2__c = lead.Income_Type_2__c;
        opp.Is_Loan_Secured__c = lead.Is_Loan_Secured__c;
        opp.Lead_ID__c = lead.Lead_ID__c;
        opp.Lived_at_residence_more_than_six_months__c = lead.Lived_Residence_Six_Months__c;
        opp.Loan_Program_Class__c = lead.Loan_Program_Class__c;
        opp.Loan_Principle__c  = lead.System_Cost__c;       
        opp.Requested_Loan_Amount__c  = lead.Requested_Loan_Amount__c;        
        opp.Maximum_Loan__c = lead.Maximum_Loan__c;
        opp.Maximum_Monthly_Disbursement__c = lead.Maximum_Monthly_Disbursement2__c;
        opp.Monthly_Income__c = lead.Monthly_Income__c;
        opp.Monthly_Income_2__c = lead.Monthly_Income_2__c;
        opp.Monthly_Income_Details__c = lead.Monthly_Income_Details__c;
        opp.Monthly_Income_Details_2__c = lead.Monthly_Income_Details_2__c;
        opp.More_than_five_years_industry_experience__c = lead.More_than_five_years_industry_experience__c;
        opp.Name = lead.Company;
        opp.Number_of_Years_at_Location__c = lead.Number_of_Years_at_Location__c;
        opp.Number_of_Years_in_Business__c = lead.Number_of_Years_in_Business__c;
        opp.Parcel_ZIp__c = lead.Parcel_Zip__c;
        opp.Partner_tag_lookup__c = lead.Partner_lookup__c;
        opp.Partner_Email__c = lead.Partner_Email__c;
        opp.Partner_Tag__c = lead.Partner_Tag__c;
        opp.Personal_Credit_Report2__c = lead.Personal_Credit_Report__c;
        opp.Personal_Credit_Report_Co_Applicant__c = lead.Personal_Credit_Report_Co_Applicant__c;
        opp.Customer_Phone__c = lead.Phone2__c;
        opp.Product_Line__c = lead.Product_Line__c;
        opp.Project_Identification_Number__c = lead.Project_Identification_Number__c;
        opp.Referral_Email__c = lead.Referral_Email__c;
        opp.Residence_Owner__c = lead.Residence_Owner__c;
        opp.BS_Sales_ID__c = lead.bs_Sales_ID__c;
        opp.Sales_Person_Tag__c = lead.Sales_Person__c;
        opp.Security_Type__c = lead.Security_Type__c;
        opp.Service_Territory__c = lead.Load_Zone__c;
        opp.Subscription__c = lead.Solar_Coverage__c;
        opp.State_of_Issuance__c = lead.State_of_Issuance__c;
        opp.Project_Assignment__c = lead.System_Assignment__c;
        opp.Annual_Consumption_kWh__c = lead.Total_Annual_Consumption_kWh__c;
        opp.Annual_Electricity_Cost__c = lead.Total_Annual_Electricity_Cost__c;
        opp.UtilityMapper__c = lead.Utility__c;
        opp.Utility_Account_Holder_Name__c = lead.Utility_Account_Holder__c;
        opp.Utility_Account_Holder_Business__c = lead.Utility_Account_Holder_Business__c;
        opp.Utility_Password__c = lead.Utility_Account_Password__c;
        opp.Username__c = lead.Utility_Account_Username__c;
        opp.Utility_Relationship__c = lead.Utility_Relationship__c;
        return opp;
    }

    private void customerSubscriptionProcess(List<Lead> leads) {
        SubscriptionRepo repo = new SubscriptionRepo(leads);
        for (Integer leadIndex = 0; leadIndex < leads.size(); leadIndex++) {
            if (repo.getTotalAnnualCostOfElectricity(leads[leadIndex]) == 0) {
                leads.remove(leadIndex);
            }
        }
        for (Lead lead : leads) {
            repo.createOpportunity(lead);
        }
        repo.insertOpps();
        for (Lead lead : leads) {
            repo.createUAS(lead);
        }
        repo.insertUASes();
        repo.sendContracts();
    }

    private class SubscriptionRepo {
        private List<Utility_Account_Log__c> ualList;
        private List<Shared_Solar_System__c> sssList;
        private Map<Id, List<Opportunity>> leadOppsMap;
        private List<Utility_Account_Subscription__c> uasList;
        private List<Id> oppIdList;

        public SubscriptionRepo(List<Lead> leads) {
            List<Id> leadIds = new List<Id>();
            for (Lead lead : leads) {
                leadIds.add(lead.Id);
            }
            ualList = [
                SELECT Id, Name, Annual_Cost_of_Electricity__c, Name_on_Account__c, Lead__c
                FROM Utility_Account_Log__c
                WHERE Lead__c IN :leadIds
                ORDER BY Annual_Cost_of_Electricity__c DESC
            ];

            sssList = [
                SELECT Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Product__c,
                    Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, Service_Territories__c,
                    Reserved_Capacity_kW_DC__c, Service_Territory__c, System_Utility__c,
                    Utility_NMC_Tariff__c, Credit_Score_Requirement__c, Assignment_Order__c, Estimated_COD_Date_QC__c
                FROM Shared_Solar_System__c
                WHERE Open__c = TRUE
                AND Capacity_Available_to_be_Reserved__c > 0
            ];

            leadOppsMap = new Map<Id, List<Opportunity>>();
            uasList = new List<Utility_Account_Subscription__c>();
            oppIdList = new List<Id>();
        }

        public List<Utility_Account_Log__c> getUALList(Lead lead) {
            List<Utility_Account_Log__c> ualListForLead = new List<Utility_Account_Log__c>();
            for (Utility_Account_Log__c ual : ualList) {
                if (ual.Lead__c == lead.Id) {
                    ualListForLead.add(ual);
                }
            }
            return ualListForLead;
        }

        public List<Shared_Solar_System__c> getSortedSharedSolarSystems(Lead lead) {
            List<SSSWrapper> sssWrappers = new List<SSSWrapper>();
            List<Shared_Solar_System__c> sortedSharedSolarSystems = new List<Shared_Solar_System__c>();
            for (Shared_Solar_System__c sss : sssList) {
                if (sss.System_Utility__c == lead.Utility__c &&
                    (sss.Service_Territories__c != null &&
                        sss.Service_Territories__c.contains(lead.Load_Zone__c)) &&
                    (sss.Sales_Partners__c != null &&
                        (sss.Sales_Partners__c.contains('All') ||
                            sss.Sales_Partners__c.contains(lead.Partner_Name__c))) &&
                    (lead.Product__c == null ||
                        sss.Product__c == lead.Product__c)) {
                    sssWrappers.add(new SSSWrapper(sss, lead.System_Assignment__c));
                }
            }
            sssWrappers.sort();
            for (Integer wrapperIndex = 0; wrapperIndex < sssWrappers.size(); wrapperIndex++) {
                sortedSharedSolarSystems.add(sssWrappers[wrapperIndex].sss);
            }
            return sortedSharedSolarSystems;
        }

        public Decimal getTotalAnnualCostOfElectricity(Lead lead) {
            Decimal totalAnnualCostOfElectricity = 0;
            for (Utility_Account_Log__c ual : ualList) {
                if (ual.Lead__c == lead.Id) {
                    totalAnnualCostOfElectricity += ual.Annual_Cost_of_Electricity__c;
                }
            }
            return totalAnnualCostOfElectricity;
        }

        public void createOpportunity(Lead lead) {
            Decimal remainingAccountCostToAllocate = getTotalAnnualCostOfElectricity(lead);
            List<Opportunity> oppListToCreate = new List<Opportunity>();
            Integer oppCounter = 1;
            for (Shared_Solar_System__c sss : getSortedSharedSolarSystems(lead)) {
                if (Integer.valueOf(lead.LASER_Credit_Score__c) >= sss.Credit_Score_Requirement__c &&
                    remainingAccountCostToAllocate > 0) {
                    Decimal annualElectricityCostAssigned = Math.min(remainingAccountCostToAllocate, sss.Maximum_Subscription_Cost__c);
                    remainingAccountCostToAllocate = remainingAccountCostToAllocate - annualElectricityCostAssigned;
                    Opportunity opp = new Opportunity(
                        AccountId = lead.ConvertedAccountId,
                        Shared_Solar_System__c = sss.Id,
                        Reserved_System_Capacity_kW_DC2__c = sss.Reserved_Capacity_kW_DC__c,
                        Available_System_Capacity_kW_DC__c = sss.Project_Capacity_Available_kW_DC__c,
                        Product__c = sss.Product__c,
                        System_Assigned__c = true,
                        NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
                        Name = lead.FirstName + ' ' + lead.LastName,
                        StageName = 'New',
                        CloseDate = Date.today(),
                        UAS_Created__c = true,
                        Annual_Electricity_Cost__c = annualElectricityCostAssigned,
                        Annual_Electricity_Cost2__c = annualElectricityCostAssigned,
                        Opportunity_Order__c = oppCounter,
                        Lead__c = lead.Id
                    );
                    opp = setDefaultOppFields(lead, opp);
                    oppListToCreate.add(opp);
                    oppCounter++;
                }
            }
            leadOppsMap.put(lead.Id, oppListToCreate);
        }

        public void insertOpps() {
            List<Opportunity> oppsToInsert = new List<Opportunity>();
            for (List<Opportunity> opps : leadOppsMap.values()) {
                oppsToInsert.addAll(opps);
            }
            insert oppsToInsert;
        }

        public void createUAS(Lead lead) {
            Map<Id, Decimal> sssRemainingSubscriptionCostMap = new Map<Id, Decimal>();
            List<Id> oppIdsWithUASes = new List<Id>();

            for (Shared_Solar_System__c sss : getSortedSharedSolarSystems(lead)) {
                sssRemainingSubscriptionCostMap.put(sss.Id, sss.Maximum_Subscription_Cost__c);
            }

            for (Utility_Account_Log__c ual : getUALList(lead)) {
                Integer uasNumberCounter = 1;
                Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;

                for (Opportunity opp : leadOppsMap.get(lead.Id)) {
                    if (sssRemainingSubscriptionCostMap.containsKey(opp.Shared_Solar_System__c)){
                        Decimal sssRemainingSubscriptionCost = sssRemainingSubscriptionCostMap.get(opp.Shared_Solar_System__c);
                        Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
                        if (annualElectricityCostAssigned > 0) {
                            //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                            sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
                            sssRemainingSubscriptionCostMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCost);

                            remainingUALCostToAllocate = remainingUALCostToAllocate - annualElectricityCostAssigned;
                            uasList.add(new Utility_Account_Subscription__c(
                                Name = ual.Name,
                                Name_on_Account__c = ual.Name_on_Account__c,
                                Opportunity__c = opp.Id,
                                Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c,
                                Utility_Account_Log__c = ual.Id,
                                UAS_Number__c = uasNumberCounter,
                                calculated_annual_cost_of_electricity__c = annualElectricityCostAssigned,
                                Subscribed_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned
                            ));
                            uasNumberCounter++;
                            oppIdList.add(opp.Id);
                        }
                    }
                }
            }
        }

        public void insertUASes() {
            insert uasList;
        }

        public void sendContracts() {
            DocuSignHelper.sendCSPackageFuture(oppIdList);
        }
    }

    public class SSSWrapper implements Comparable {
        public Shared_Solar_System__c sss;
        public String systemAssignment;
        public SSSWrapper(Shared_Solar_System__c sss, String systemAssignment) {
            this.sss = sss;
            this.systemAssignment = systemAssignment;
        }
        public Integer compareTo(Object compareTo) {
            SSSWrapper compareToSSS = (SSSWrapper) compareTo;
            Integer returnValue = 0;
            if (systemAssignment == 'Automatic - COD Date/Available Capacity' || systemAssignment == null) {
                if (sss.Estimated_COD_Date_QC__c > compareToSSS.sss.Estimated_COD_Date_QC__c) {
                    returnValue = 1;
                } else if (sss.Estimated_COD_Date_QC__c < compareToSSS.sss.Estimated_COD_Date_QC__c) {
                    returnValue = -1;
                } else {
                    if (sss.Project_Capacity_Available_kW_DC__c > compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = 1;
                    } else if (sss.Project_Capacity_Available_kW_DC__c < compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = -1;
                    }
                }
            } else if (systemAssignment == 'Automatic - Assignment Order') {
                if (sss.Assignment_Order__c > compareToSSS.sss.Assignment_Order__c) {
                    return 1;
                } else if (sss.Assignment_Order__c < compareToSSS.sss.Assignment_Order__c) {
                    return -1;
                }
            }
            return returnValue;
        }
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