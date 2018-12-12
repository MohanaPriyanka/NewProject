/*************************************************************************************
 * Created By:  Cole Swain
 * Description: Called from LeadTrigger, OpportunityTrigger, LoanTrigger,
 *              and ResidentialEquipementTrigger
 * Test: LoanHandlerTestClass
 *************************************************************************************/

public without sharing class LoanHandler{
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    public static Boolean ranBeforeInsert = false, ranAfterInsert = false, ranBeforeUpdate = false, ranAfterUpdate = false;

    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    // Default constructor
    public LoanHandler() {
    }

    // Constructor to override m_isExecuting and Batch Size
    public LoanHandler(boolean isExecuting, Integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    //On After Insertion of Loan Record
    public void onAfterInsert(List<Loan__c> newLoans) {
        createLoanPartnerTasks(newLoans);
    }

    public void onBeforeInsert(List<Loan__c> newLoans) {
        for (Loan__c newLoan : newLoans){
            setDaysPastDue(newLoan, null);
        }
    }

    public void onBeforeUpdate(List<Loan__c> newLoans, Map<Id, Loan__c> oldLoanMap) {
        for (Loan__c newLoan : newLoans){
            setDaysPastDue(newLoan, oldLoanMap);
            checkLoanCompletePartnerTasks(newLoan, oldLoanMap);
        }
    }

    //On Before Update of Lead Record
    public void onBeforeLeadUpdate(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        // map the loan, equipment and partner tasks to the opportunity upon conversion
        mapLoanToOpportunity(updatedLeadMap, oldLeadMap);
        mapEquipmentToOpportunity(updatedLeadMap, oldLeadMap);
        mapPartnerTasksToOpportunity(updatedLeadMap, oldLeadMap);
        mapCoApplicantContactToOpportunity(updatedLeadMap, oldLeadMap);
    }

    public void onAfterLeadUpdate(List<Lead> updatedLeads, List<Lead> oldLeads, Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        List<Lead> leadsToValidatePartnerTasks = new List<Lead>();
        List<String> leadIds = new List<String>();
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Lead leadRecord : updatedLeads) {
            leadIds.add(leadRecord.Id);
        }
        for (Lead lead : updatedLeads) {
            if (lead.Update_Dummy__c != oldLeadMap.get(lead.Id).Update_Dummy__c
                && lead.Product_line__c == 'Residential Loan') {
                leadsToValidatePartnerTasks.add(lead);
            }
            if ((lead.Product__c != oldLeadMap.get(lead.Id).Product__c ||
                lead.Requested_Loan_Amount__c != oldLeadMap.get(lead.Id).Requested_Loan_Amount__c ||
                lead.System_Cost__c != oldLeadMap.get(lead.Id).System_Cost__c) &&
                lead.ConvertedOpportunityId != null &&
                lead.Product_line__c == 'Residential Loan') {
                Opportunity opp = new Opportunity(
                    Id = lead.ConvertedOpportunityId,
                    Product__c = lead.Product__c,
                    Requested_Loan_Amount__c = lead.Requested_Loan_Amount__c,
                    Loan_Principle__c = lead.System_Cost__c
                );
                opportunities.add(opp);
            }
        }

        if (leadsToValidatePartnerTasks.size() > 0) {
            validateLoanInformationProvidedOnLead(leadsToValidatePartnerTasks, getPartnerTasks(leadIds));
        }
        if (!opportunities.isEmpty()) {
            update opportunities;
        }
    }

    //On After Update of Opportunity Record
    public void onAfterOpportunityUpdate(List<Opportunity> updatedOpportunities,
                                         List<Opportunity> oldOpportunities,
                                         Map<Id, Opportunity> updatedOpportunityMap,
                                         Map<Id, Opportunity> oldOpportunityMap) {
        List<String> completedOppIds = new List<String>();
        List<Opportunity> signedCustomerOpps = new List<Opportunity>();
        List<String> counterSignedCustomerOppIds = new List<String>();
        List<String> uploadedSalesAgreementCustomerOppIds = new List<String>();
        List<Opportunity> validateSalesAgreementList = new List<Opportunity>();
        List<String> oppLeadIds = new List<String>();
        List<String> oppLeadIdsList = new List<String>();
        List<Id> oppsWithRequestedLoanAmountChange = new List<Id>();
        Integer loanTerm;
        Integer interestOnlyPeriod;

        for (Opportunity newOpp : updatedOpportunities) {
            if (newOpp.StageName == 'Complete' && oldOpportunityMap.get(newOpp.Id).StageName != 'Complete' && newOpp.Product_Line__c == 'Residential Loan') {
                completedOppIds.add(newOpp.Id);
            }
            if (newOpp.Requested_Loan_Amount__c != null &&
                newOpp.Requested_Loan_Amount__c != oldOpportunityMap.get(newOpp.Id).Requested_Loan_Amount__c) {
                oppsWithRequestedLoanAmountChange.add(newOpp.Id);
            }
            if (checkCustomerContractSignatures(newOpp, oldOpportunityMap.get(newOpp.Id))) {
                signedCustomerOpps.add(newOpp);
            }
            if (newOpp.BlueWave_Signature_Status__c == 'Completed' && oldOpportunityMap.get(newOpp.Id).BlueWave_Signature_Status__c != 'Completed' && newOpp.Product_Line__c == 'Residential Loan') {
                counterSignedCustomerOppIds.add(newOpp.Id);
            }
            if (newOpp.Partner_Sales_Agreement_Status__c == 'Completed' && oldOpportunityMap.get(newOpp.Id).Partner_Sales_Agreement_Status__c != 'Completed' && newOpp.Product_Line__c == 'Residential Loan') {
                uploadedSalesAgreementCustomerOppIds.add(newOpp.Id);
            }
            if (newOpp.Update_Dummy__c != oldOpportunityMap.get(newOpp.Id).Update_Dummy__c) {
                validateSalesAgreementList.add(newOpp);
                if (newOpp.Lead_Id__c != null) {
                    oppLeadIdsList.add(newOpp.Lead_Id__c);
                }
            }
        }

        if (!completedOppIds.isEmpty()) {
            List<Loan__c> completedOpportunityLoans = [SELECT Id, Name, Lead__c, Loan_Tranche__c, DOER_Solar_Loann__c,
                                                        Interest_Ratee__c, Unique_ID__c, Sales_Agent__c, Financing_Fee__c,
                                                        Requested_Loan_Amount__c, Partner__c, State__c, Lead_ID__c, Product__c,
                                                        Product__r.Loan_Term__c, Product__r.Loan_Interest_Only_Period__c
                                                       FROM Loan__c
                                                       WHERE Opportunity__r.Id IN : completedOppIds];
            List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(completedOpportunityLoans));
            for (Loan__c loanRecord : tranchedLoans) {
                loanRecord.Contracted__c = true;
            }
            upsert new List<Loan__c>(tranchedLoans) Unique_ID__c;
        }
        // System Cost can change on the Opportunity because of customer downpayments - we pull that
        // field into DocuSign.
        if (!oppsWithRequestedLoanAmountChange.isEmpty()) {
            List<Loan__c> checkRequestedLoanAmountLoans = [SELECT Id, Opportunity__c, Requested_Loan_Amount__c
                                                  FROM Loan__c
                                                  WHERE Opportunity__r.Id IN : oppsWithRequestedLoanAmountChange];
            List<Loan__c> requestedLoanAmountLoansToUpdate = new List<Loan__c>();
            for (Loan__c requestedLoanAmountLoan : checkRequestedLoanAmountLoans) {
                if (requestedLoanAmountLoan.Requested_Loan_Amount__c !=
                    updatedOpportunityMap.get(requestedLoanAmountLoan.Opportunity__c).Requested_Loan_Amount__c) {
                    requestedLoanAmountLoan.Requested_Loan_Amount__c =
                        updatedOpportunityMap.get(requestedLoanAmountLoan.Opportunity__c).Requested_Loan_Amount__c;
                    requestedLoanAmountLoansToUpdate.add(requestedLoanAmountLoan);
                }
            }
            if (!requestedLoanAmountLoansToUpdate.isEmpty()) {
                update requestedLoanAmountLoansToUpdate;
            }
        }
        for (Opportunity oppRecord : updatedOpportunities) {
            if (oppRecord.Lead_ID__c != null) {
                oppLeadIds.add(oppRecord.Lead_ID__c);
            }
        }

        if (!signedCustomerOpps.isEmpty()) {
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(signedCustomerOpps);
            if (partnerTaskList.size() > 0) {
                updatePartnerTaskObtainContractSignature(signedCustomerOpps, getPartnerTasks(oppLeadIds));
            }
        }
        if (!counterSignedCustomerOppIds.isEmpty()) {
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(updatedOpportunities);
            if (partnerTaskList.size() > 0) {
                updatePartnerTaskBlueWaveCounterSignature(updatedOpportunities, getPartnerTasks(oppLeadIds));
            }
        }
        if (!validateSalesAgreementList.isEmpty()) {
            validateLoanInformationProvidedOnOpp(validateSalesAgreementList, getPartnerTasks(oppLeadIdsList));
        }
    }

    public List<Partner_Task__c> checkForPartnerTasksOnOpportunity(List<Opportunity> opportunities) {
        List<String> oppIds = new List<String>();
        for (Opportunity oppRecord : opportunities) {
            oppIds.add(oppRecord.Id);
        }
        List<Partner_Task__c> partnerTasks = [SELECT Id FROM Partner_Task__c WHERE Opportunity__r.Id IN : oppIds];
        return partnerTasks;
    }

    public void onAfterResidentialEquipmentUpdate(Map<Id, Residential_Equipment__c> newEquipmentMap, Map<Id,Residential_Equipment__c> oldEquipmentMap) {
        DisbursalHandler disbursalHandler = new DisbursalHandler ();
        List<String> equipmentLeadIdListNYBuildingPermit = new List<String>();
        List<String> equipmentLeadIdListMechInstall = new List<String>();
        List<String> equipmentLeadIdListInterconnection = new List<String>();
        List<Id> interconnectionTaskToUpdateEquipIds = new List<Id>();
        List<String> oppIdList = new List<String>();
        List<Residential_Equipment__c> newEquipment = [
            SELECT Id, Interconnection_Update_Dummy__c, Mechanically_Installed__c, DOER_Solar_Loan__c, Opportunity__r.Id,
                Lead__c, Lead__r.Id, State__c, Labor_Performed__c, Materials_Supplied__c, Annual_Production_kWh_kW__c, Opportunity__r.Lender_of_Record__c,
                Interconnected__c, Interconnection_Date__c, Percentage_of_System_Shaded__c, SREC_Opt_In_Calendar_Quarter__c,
                Generator_Type__c, MA_Facility_Sector__c, Generator_Nameplate_Capacity__c, Contract_Execution_Date__c,
                Generator_Interconnection_Date__c, Generator_Installation_Date__c, Generator_Energized_Online_Date__c,
                Module_Manufacturer__c, Module_Model_Number__c, Module_Power_Rating__c, Number_of_Modules__c,
                Module_Array_Mounting_Type__c, Module_Array_Azimuth__c,  Module_Array_Tilt__c, Module_Mounting_Location__c,
                Inverter_Manufacturer__c, Inverter_Model_Number__c, Number_of_Meters__c, Solar_Meter_Manufacturer__c,
                Solar_Meter_Model__c, Solar_Meter_Serial_Number__c, (SELECT Id, Name, Description FROM Attachments)
            FROM Residential_Equipment__c
            WHERE Id IN :newEquipmentMap.keySet()
        ];
        for (Residential_Equipment__c equipment : newEquipment) {
            oppIdList.add(equipment.Opportunity__r.Id);
        }
        Map<String,Disbursal__c> disbursalMap = disbursalHandler.getDisbursalMap(oppIdList);
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        for (Residential_Equipment__c equipment : newEquipment) {
            if (equipment.Mechanically_Installed__c && !oldEquipmentMap.get(equipment.Id).Mechanically_Installed__c) {
                equipmentLeadIdListMechInstall.add(equipment.Lead__r.Id);
            }
            if (equipment.Interconnected__c && !oldEquipmentMap.get(equipment.Id).Interconnected__c) {
                equipmentLeadIdListInterconnection.add(equipment.Lead__r.Id);
            }
            if (!equipment.Interconnected__c && oldEquipmentMap.get(equipment.Id).Interconnected__c) {
                interconnectionTaskToUpdateEquipIds.add(equipment.Id);
            }
            if (equipment.Interconnection_Update_Dummy__c != oldEquipmentMap.get(equipment.Id).Interconnection_Update_Dummy__c) {
                equipmentLeadIdListInterconnection.add(equipment.Lead__r.Id);
            }
            if (nyBuildingPermitApproved(equipment, oldEquipmentMap)) {
                equipmentLeadIdListNYBuildingPermit.add(equipment.Lead__r.Id);
            }
            if (disbursalMap.get(equipment.Opportunity__r.Id + 'Building Permit Approved') != null) {
                if (nyBuildingPermitApproved(equipment, oldEquipmentMap)) {
                    disbursalList.add(disbursalHandler.setDisbursalStatus('Building Permit Approved', equipment.Opportunity__r.Id, disbursalMap, 'Due', 'Disbursed'));
                } else {
                    disbursalList.add(disbursalHandler.setDisbursalStatus('Building Permit Approved', equipment.Opportunity__r.Id, disbursalMap, 'Pending', 'Disbursed'));
                }
            }
            if (!disbursalList.isEmpty()) {
                update disbursalList;
            }
        }
        if (equipmentLeadIdListNYBuildingPermit.size() > 0 ) {
            updatePartnerTaskNYBuildingPermit(newEquipment, getPartnerTasks(equipmentLeadIdListNYBuildingPermit));
        }
         //if the equipment gets set to mechanically installed update the partner task to be complete.
        if (equipmentLeadIdListMechInstall.size() > 0 ) {
            updatePartnerTaskMechanicalInstallation(newEquipment, getPartnerTasks(equipmentLeadIdListMechInstall));
        }
        //if the equipment gets set to interconnected update the partner task to be complete.
        if (equipmentLeadIdListInterconnection.size() > 0 ) {
            updatePartnerTaskInterconnection(newEquipment, getPartnerTasks(equipmentLeadIdListInterconnection));
        }
        if (!interconnectionTaskToUpdateEquipIds.isEmpty()) {
            rollbackEquipmentAndInterconnectionTask(interconnectionTaskToUpdateEquipIds);
        }
    }

    public boolean nyBuildingPermitApproved(Residential_Equipment__c re, Map<Id, Residential_Equipment__c> oldEquipmentMap) {
        if (re.State__c != 'NY') {
            return false;
        } else {
            Boolean hasAttachment = false;
            for (Attachment a : re.Attachments) {
                if (a.Description == 'Building Permit') {
                    hasAttachment = true;
                }
            }
            if (hasAttachment &&
                String.isNotBlank(re.Labor_Performed__c) &&
                String.isNotBlank(re.Materials_Supplied__c)) {
                return true;
            } else {
                return false;
            }
        }
    }

    public static void createResidentialEquipment(List<Lead> newLeadList) {
        Id mslpRTId = Schema.SObjectType.Residential_Equipment__c.getRecordTypeInfosByName().get('MSLP').getRecordTypeId();
        Id bwslRTId = Schema.SObjectType.Residential_Equipment__c.getRecordTypeInfosByName().get('BlueWave Solar Loan').getRecordTypeId();
        List<Residential_Equipment__c> newEquipmentList = new List<Residential_Equipment__c>();
        for (Lead lead : newLeadList) {
            if (lead.Product_Line__c == 'Residential Loan') {
                Residential_Equipment__c equipmentRecord = new Residential_Equipment__c();
                equipmentRecord.Name = lead.FirstName + ' ' + lead.LastName;
                equipmentRecord.Lead__c = lead.Id;
                equipmentRecord.Opportunity__c = lead.ConvertedOpportunityId;
                equipmentRecord.RecordTypeId = (lead.DOER_Solar_Loan__c?mslpRTId:bwslRTId);
                if (lead.Loan_System_Information__c != null) {
                    mapJSONToObject(lead.Loan_System_Information__c, 'Residential_Equipment__c', equipmentRecord);
                }
                newEquipmentList.add(equipmentRecord);
            }
        }
        insert newEquipmentList;
    }

    public static void createLoan(List<Lead> newLeadList) {
        Loan_Traunch__c tranchePending = [SELECT Id, Name
                                          FROM Loan_Traunch__c
                                          WHERE Name = 'Tranche Assignment Pending' LIMIT 1];
        List<Loan__c> newLoanList = new List<Loan__c>();
        for (Lead lead : newLeadList) {
            if (lead.Product_Line__c == 'Residential Loan') {
                Loan__c loan = new Loan__c();
                loan.Name = lead.FirstName + ' ' + lead.LastName;
                loan.Lead__c = lead.Id;
                loan.Opportunity__c = lead.ConvertedOpportunityId;
                loan.Loan_Tranche__c = tranchePending.Id;
                loan.Interest_Ratee__c = lead.Product__r.Loan_Interest_rate__c;
                loan.Unique_ID__c = lead.id;
                loan.Sales_Agent__c = lead.BS_Sales_ID__c;
                loan.Financing_Fee__c = lead.Loan_Financing_Fee__c;
                loan.Requested_Loan_Amount__c = lead.Requested_Loan_Amount__c;
                loan.System_Costt__c = lead.System_Cost__c;
                loan.Partner__c = lead.Partner_Lookup__c;
                loan.State__c = lead.LASERCA__Home_State__c;
                loan.Lead_ID__c = lead.Id;
                loan.Product__c = lead.Product__c;
                loan.DOER_Solar_Loann__c = lead.DOER_Solar_Loan__c;
                loan.Loan_Fee_1__c = lead.Loan_Fee_1__c;
                if (lead.DOER_Solar_Loan__c) {
                    loan.Interest_Only_Period_DOER__c = lead.Product__r.Loan_Interest_Only_period__c;
                }
                if (lead.Loan_System_Information__c != null) {
                    Loan__c loanRecord = (Loan__c)mapJSONToObject(lead.Loan_System_Information__c, 'Loan__c', loan);
                    if (loanRecord.Estimated_Completion_Date__c != null) {
                        loanRecord.Commencement_Datee__c = loanRecord.Estimated_Completion_Date__c + (lead.DOER_Solar_Loan__c?45:30);
                    }
                    newLoanList.add(loanRecord);
                } else {
                    newLoanList.add(loan);
                }
            }
        }
        upsert newLoanList Unique_ID__c;
        assignResidentialEquipmentToLoan(newLoanList);
    }

    // We store JSON like this:
    // {"number_of_modules__c":"28","commencement_datee__c":"05/15/2018","generator_nameplate_capacity__c":"10.080"}
    // {"number_of_modules__c":"28","commencement_datee__c":"","generator_nameplate_capacity__c":"10.080"}
    // But deserialize expects date formats like yyyy-MM-dd or null so we need to convert and remove empty elements
    // The whole problem is that dates come from BlueWaveDate, which treats the date value as a String, not Date, but
    // allows us to automatically format.
    public static String convertDateStrings(String jsonString) {
        Pattern datePattern = Pattern.compile('(\\d{2}[\\/\\-]\\d{2}[\\/\\-](?:[0-9]{2})?[0-9]{2})+');
        Matcher matcher = datePattern.matcher(jsonString);
        Map<String, String> formattedDates = new Map<String, String>();
        while (matcher.find()) {
            Date d = Date.parse(matcher.group());
            String formattedDate = DateTime.newInstance(d.year(), d.month(), d.day()).format('yyyy-MM-dd');
            formattedDates.put(matcher.group(), formattedDate);
        }
        for (String inputDate : formattedDates.keySet()) {
            jsonString = jsonString.replace(inputDate, formattedDates.get(inputDate));
        }
        Map<String, Object> jsonObj = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        for (String key : jsonObj.keySet()) {
            if (jsonObj.get(key) == '') {
                jsonObj.remove(key);
            }
        }
        return JSON.serialize(jsonObj);
    }

    public static SObject mapJSONToObject(String jsonString, String objectType, SObject recordToUpdate) {
        SObject sobj = (SObject) JSON.deserialize(convertDateStrings(jsonString), Type.forName(objectType));
        Map<String, Object> fieldMap = sobj.getPopulatedFieldsAsMap();
        for (String field : fieldMap.keySet()) {
            recordToUpdate.put(field, fieldMap.get(field));
        }
        return recordToUpdate;
    }

    public void mapLoanToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        List<Loan__c> loanListToUpdate = new List<Loan__c>();
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        Map<Id, Id> rlLeadToOppMap = new Map<Id, Id>();

        for (Lead leadRecord : updatedLeadMap.values()) {
            if (leadRecord.IsConverted
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan') {
                rlLeadToOppMap.put(leadRecord.Id, leadRecord.ConvertedOpportunityId);
            }
        }
        // We calculate APR and all of the Monthly Payment fields on Loan, because the Opportunity doesn't exist yet.
        if (!rlLeadToOppMap.values().isEmpty()) {
            for(Loan__c loanRecord : [
                SELECT Id, APR__c, Lead__c, Opportunity__c,
                    First_Adjustable_Monthly_Payment_Amount__c, Second_Adjustable_Monthly_Payment_Amount__c,
                    Third_Adjustable_Monthly_Payment_Amount__c, Fourth_Adjustable_Monthly_Payment_Amount__c,
                    Fifth_Adjustable_Monthly_Payment_Amount__c, Sixth_Adjustable_Monthly_Payment_Amount__c,
                    Total_Loan_Payments_Override__c
                FROM Loan__c
                WHERE Lead__c IN : rlLeadToOppMap.keySet()]) {
                loanRecord.Opportunity__c = rlLeadToOppMap.get(loanRecord.Lead__c);
                loanListToUpdate.add(loanRecord);
                oppListToUpdate.add(new Opportunity(
                    Id = loanRecord.Opportunity__c,
                    APR__c = loanRecord.APR__c,
                    First_Adjustable_Monthly_Payment_Amount__c = loanRecord.First_Adjustable_Monthly_Payment_Amount__c,
                    Second_Adjustable_Monthly_Payment_Amount__c = loanRecord.Second_Adjustable_Monthly_Payment_Amount__c,
                    Third_Adjustable_Monthly_Payment_Amount__c = loanRecord.Third_Adjustable_Monthly_Payment_Amount__c,
                    Fourth_Adjustable_Monthly_Payment_Amount__c = loanRecord.Fourth_Adjustable_Monthly_Payment_Amount__c,
                    Fifth_Adjustable_Monthly_Payment_Amount__c = loanRecord.Fifth_Adjustable_Monthly_Payment_Amount__c,
                    Sixth_Adjustable_Monthly_Payment_Amount__c = loanRecord.Sixth_Adjustable_Monthly_Payment_Amount__c,
                    Total_Loan_Payments_Override__c = loanRecord.Total_Loan_Payments_Override__c
                ));
            }
            update loanListToUpdate;
            update oppListToUpdate;
        }
    }

    public void mapEquipmentToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()) {
             if (leadRecord.IsConverted
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan') {
                feedback2OppId.put(leadRecord.Id, leadRecord.convertedOpportunityId);
                opportunityMap.put(leadRecord.convertedOpportunityId,leadRecord.convertedOpportunityId);
            }
        }
        if (!feedback2OppId.values().isEmpty()) {
            for(Residential_Equipment__c equipment : [SELECT Lead__c, Opportunity__c FROM Residential_Equipment__c WHERE Lead__c IN : feedback2OppId.keySet()]) {
                equipment.Opportunity__c = feedBack2OppId.get(equipment.Lead__c);
                equipmentListToUpdate.add(equipment);
            }
            update equipmentListToUpdate;
        }
    }

    public void mapPartnerTasksToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        List<Partner_Task__c> partnerTaskListToUpdate = new List<Partner_Task__c>();
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()) {
             if (leadRecord.IsConverted
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan') {
                feedback2OppId.put(leadRecord.Id, leadRecord.convertedOpportunityId);
                opportunityMap.put(leadRecord.convertedOpportunityId,leadRecord.convertedOpportunityId);
            }
        }
        if (!feedback2OppId.values().isEmpty()) {
            if (!opportunityMap.values().isEmpty()) {
                for(Partner_Task__c task : [SELECT Lead__c, Opportunity__c FROM Partner_Task__c WHERE Lead__c IN : feedback2OppId.keySet()]) {
                    task.Opportunity__c = feedBack2OppId.get(task.Lead__c);
                    partnerTaskListToUpdate.add(task);
                }
                update partnerTaskListToUpdate;
            }
        }
    }

    public void mapCoApplicantContactToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap) {
        List<Contact> contactListToUpdate = new List<Contact>();
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()) {
            if (leadRecord.IsConverted
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.ConvertedOpportunityId != null
                && leadRecord.Product_Line__c == 'Residential Loan'
                && leadRecord.Application_Type__c == 'Joint') {
                feedBack2OppId.put(leadRecord.Id, leadRecord.ConvertedOpportunityId);
                opportunityMap.put(leadRecord.ConvertedOpportunityId, leadRecord.ConvertedOpportunityId);
            }
        }
        if (!feedback2OppId.values().isEmpty()) {
            for(Contact contactRecord : [SELECT Lead__c, Opportunity__c FROM Contact WHERE Lead__c IN : feedback2OppId.keySet()]) {
                contactRecord.Opportunity__c = feedBack2OppId.get(contactRecord.Lead__c);
                contactListToUpdate.add(contactRecord);
            }
            update contactListToUpdate;
        }
    }

    public List<Loan__c> assignLoanTranche(List<Loan__c> newLoanList) {
        Loan_Traunch__c temporaryHoldingTranche;
        List<Loan_Traunch__c> trancheRecordList = new List<Loan_Traunch__c>();
        List<Loan__c> tranchedLoans = new List<Loan__c>();
        List<String> productIds = new List<String>();
        Map<String, Product2> loanProductMap = new Map<String, Product2>();
        try{
            for (Loan__c l : newLoanList) {
                productIds.add(l.Product__c);
            }
            for(Product2 productRecord : [SELECT Id, Name, Loan_Capital_Pool__r.Id, Loan_Tranche_type__c FROM Product2 WHERE Id IN : productIds]) {
                for (Loan__c l : newLoanList) {
                    if (l.Product__c == productRecord.Id) {
                        loanProductMap.put(l.Id, productRecord);
                    }
                }
            }
            for (Loan_Traunch__c trancheRecord : [SELECT Id, Name, State__c, Loan_Data__r.Id, Available_Capital__c, Stage__c FROM Loan_Traunch__c]) {
                if (trancheRecord.Stage__c == 'Open' && trancheRecord.Available_Capital__c > 0 && trancheRecord.Name != 'No Available Capital - Temporary Holding Tranche') {
                    trancheRecordList.add(trancheRecord);
                }
                if (trancheRecord.Name == 'No Available Capital - Temporary Holding Tranche') {
                    temporaryHoldingTranche = trancheRecord;
                }
            }
            for (Loan__c loanRecord : newLoanList) {
                for(Loan_Traunch__c trancheRecord : trancheRecordList) {
                    if (trancheRecord.State__c == loanRecord.State__c &&
                        trancheRecord.Loan_Data__r.Id == loanProductMap.get(loanRecord.Id).Loan_Capital_Pool__r.Id &&
                        trancheRecord.Tranche_Type__c == loanProductMap.get(loanRecord.Id).Loan_Tranche_type__c) {
                        if (trancheRecord.Available_Capital__c >= loanRecord.Requested_Loan_Amount__c) {
                            loanRecord.Loan_Tranche__c = trancheRecord.Id;
                            tranchedLoans.add(loanRecord);
                        } else {
                            loanRecord.Loan_Tranche__c = temporaryHoldingTranche.Id;
                            tranchedLoans.add(loanRecord);
                        }
                    }
                }
            }
            return tranchedLoans;
        }
        catch(exception e) {
            return null;
        }
    }

    public void createLoanPartnerTasks(List<Loan__c> newLoanList) {
        createLoanPartnerTasksStatusOption(newLoanList, true);
    }
    public void createLoanPartnerTasksStatusOption(List<Loan__c> newLoanList, Boolean withDefaultStatus) {
        List<Partner_Task__c> taskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> parentTaskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> subParentTaskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> subTaskInsertList = new List<Partner_Task__c>();
        List<Loan__c> loanList = new List<Loan__c>();
        List<String> leadIdList = new List<String>();
        Map<String, Partner_Task__c> parentTaskAssignmentMap = new Map<String, Partner_Task__c>();
        Map<String, Partner_Task__c> subParentTaskAssignmentMap = new Map<String, Partner_Task__c>();
        Map<String, Partner_Task__c> taskMap = new Map<String, Partner_Task__c>();
        String shortenedIdForMapKey;
        RecordType parentPartnerTaskRecordType;
        RecordType childPartnerTaskRecordType;
        Integer partnerSequenceCounter = 1;

        parentPartnerTaskRecordType = [SELECT Id FROM RecordType WHERE Name = 'Parent Partner Task' AND SobjectType = 'Partner_Task__c' LIMIT 1];
        childPartnerTaskRecordType = [SELECT Id FROM RecordType WHERE Name = 'Child Partner Task' AND SobjectType = 'Partner_Task__c' LIMIT 1];

        for (Loan__c loanRecord : [SELECT Id, Name, Requested_Loan_Amount__c, Partner__r.Id, Partner__r.Name, Lead__r.Id, Lead__c, State__c,
                                   Product__r.Disbursal_Terms__c, Opportunity__r.DOER_Solar_Loan__c, DOER_Solar_Loann__c,
                                   Lead__r.Requested_Loan_Amount__c, Lead__r.Retired__c, Lead__r.Self_Employed__c, Lead__r.Application_Type__c,
                                   Sales_Agent__r.Id, Lead__r.Employed__c, Lead__r.Veteran_Disability__c, Opportunity__c,
                                   Lead__r.Product_Program__c
                                   FROM Loan__c
                                   WHERE Id IN : newLoanList]) {
            Partner_Task__c creditTask =
                createPartnerTask(loanRecord, 'GrandParent', 'Run Credit Check', 'Run Credit Check',
                                  partnerSequenceCounter, 'Complete', 'Credit Check', null, null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Credit', withDefaultStatus);
            partnerSequenceCounter += 1;
            Partner_Task__c allInformationTask =
                createPartnerTask(loanRecord, 'GrandParent', 'Provide All Customer Information', 'Provide All Customer Information',
                                  partnerSequenceCounter, 'Pending', 'Customer Information', null, null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Information', withDefaultStatus);
            partnerSequenceCounter += 1;
            Partner_Task__c bwReviewTask =
                createPartnerTask(loanRecord, 'GrandParent', 'Under BlueWave Review', 'Under BlueWave Review',
                                  partnerSequenceCounter, 'Incomplete', 'Under BlueWave Review', null, null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Review', withDefaultStatus);
            partnerSequenceCounter += 1;
            Partner_Task__c contractSignatureTask =
                createPartnerTask(loanRecord, 'GrandParent', 'Obtain Contract Signature', 'Obtain Contract Signature',
                                  partnerSequenceCounter, 'Incomplete', 'Contract', null,  null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Contract', withDefaultStatus);
            partnerSequenceCounter += 1;
            if (!loanRecord.DOER_Solar_Loann__c) {
                Partner_Task__c salesAgreementTask =
                    createPartnerTask(loanRecord, 'GrandParent', 'Provide Sales Agreement', 'Sales Agreement',
                                      partnerSequenceCounter, 'Incomplete', 'Sales Agreement', null,  null,
                                      parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                      parentTaskAssignmentMap, null, 'Sales Agreement', withDefaultStatus);
                partnerSequenceCounter += 1;
            }
            Partner_Task__c bwContractSignature =
                createPartnerTask(loanRecord, 'GrandParent', 'BlueWave Counter Signature', 'BlueWave Counter Signature',
                                  partnerSequenceCounter, 'Incomplete', 'Contract', null,  null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Countersign', withDefaultStatus);
            partnerSequenceCounter += 1;
            if (loanRecord.State__c == 'NY') {
                createPartnerTask(loanRecord, 'GrandParent', 'Building Permit', 'Building Permit',
                    partnerSequenceCounter, 'Incomplete', 'Building Installation', null,  null,
                    parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                    parentTaskAssignmentMap, null, 'Install', withDefaultStatus);
                partnerSequenceCounter += 1;
            }
            if (loanRecord.Lead__r.Product_Program__c == 'CED') {
                createPartnerTask(loanRecord, 'GrandParent', 'Material Invoice', 'Material Invoice',
                    partnerSequenceCounter, 'Incomplete', 'Material Invoice', null,  null,
                    parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                    parentTaskAssignmentMap, null, 'Install', withDefaultStatus);
                partnerSequenceCounter += 1;
            }
            if (!loanRecord.DOER_Solar_Loann__c) {
                Partner_Task__c mechanicalInstallationTask =
                    createPartnerTask(loanRecord, 'GrandParent', 'Mechanical Installation', 'Mechanical Installation',
                                      partnerSequenceCounter, 'Incomplete', 'Mechanical Installation', null,  null,
                                      parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                      parentTaskAssignmentMap, null, 'Install', withDefaultStatus);
                partnerSequenceCounter += 1;

            }
            Partner_Task__c interconnectionTask =
                createPartnerTask(loanRecord, 'GrandParent', 'Interconnection', 'Interconnection',
                                  partnerSequenceCounter, 'Incomplete', 'Interconnection', null,  null,
                                  parentPartnerTaskRecordType, parentTaskInsertList, null, null,
                                  parentTaskAssignmentMap, null, 'Interconnect', withDefaultStatus);
            partnerSequenceCounter += 1;
            Partner_Task__c incomeDocumentationTask =
                createPartnerTask(loanRecord, 'Parent', 'Provide Income Documentation', 'Income Documentation',
                                  null, 'Incomplete', 'Customer Information', 'Income Documentation', allInformationTask,
                                  childPartnerTaskRecordType, null, subParentTaskInsertList, subTaskInsertList,
                                  null, subParentTaskAssignmentMap, null, withDefaultStatus);
            Partner_Task__c systemInformationTask =
                createPartnerTask(loanRecord, 'Parent', 'Provide all System Information', 'Provide all System Information',
                    null, 'Pending', 'Customer Information', 'System Information', allInformationTask,
                    childPartnerTaskRecordType, null, subParentTaskInsertList, null,
                    null, subParentTaskAssignmentMap, null, withDefaultStatus);
            if (loanRecord.DOER_Solar_Loann__c) {
                Partner_Task__c technicalApprovalTask =
                    createPartnerTask(loanRecord, 'Parent', 'Provide Technical Confirmation Documentation', 'Technical Approval Confirmation',
                                      null, 'Pending', 'Customer Information', 'Technical Approval', allInformationTask,
                                      childPartnerTaskRecordType, null, subParentTaskInsertList, null,
                                      null, subParentTaskAssignmentMap, null, withDefaultStatus);
            }
            if (loanRecord.Lead__r.Employed__c) {
                Partner_Task__c payStubDocumentationTask =
                    createPartnerTask(loanRecord, 'Child', 'Provide PayStub Documentation', 'PayStub Documentation',
                                      null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask,
                                      childPartnerTaskRecordType, null, null, subTaskInsertList,
                                      null, null, null, withDefaultStatus);
            }
            if (loanRecord.Lead__r.Self_Employed__c) {
                Partner_Task__c selfEmploymentTaxReturnPreviousYearTask =
                    createPartnerTask(loanRecord, 'Child', 'Provide Tax Return (Previous Year)', 'Tax Return (Previous Year)',
                                      null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask,
                                      childPartnerTaskRecordType, null, null, subTaskInsertList,
                                      null, null, null, withDefaultStatus);
                Partner_Task__c selfEmploymentTaxReturnTwoYearsPreviousTask =
                    createPartnerTask(loanRecord, 'Child', 'Provide Tax Return (Two Years Previous)', 'Tax Return (Two Years Previous)',
                                      null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask,
                                      childPartnerTaskRecordType, null, null, subTaskInsertList,
                                      null, null, null, withDefaultStatus);
            }
            if (loanRecord.Lead__r.Retired__c) {
                Partner_Task__c retirementIncomeDocumentationTask =
                    createPartnerTask(loanRecord, 'Child', 'Provide SSN/Pension Award Letter or Bank Statement', 'SSN/Pension Award Letter or Bank Statement',
                                      null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask,
                                      childPartnerTaskRecordType, null, null, subTaskInsertList,
                                      null, null, null, withDefaultStatus);
            }
            if (loanRecord.Lead__r.Veteran_Disability__c) {
                Partner_Task__c allIncomeDocumentationTask =
                    createPartnerTask(loanRecord, 'Child', 'Provide All Income Documentation', 'All Income Documentation',
                                      null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask,
                                      childPartnerTaskRecordType, null, null, subTaskInsertList,
                                      null, null, null, withDefaultStatus);
            }
            loanList.add(loanRecord);
            leadIdList.add(loanRecord.Lead__c);
            partnerSequenceCounter = 1;
        }
        
        upsert parentTaskInsertList Unique_ID__c;
        for (Partner_Task__c task : subParentTaskInsertList) {
            shortenedIdForMapKey = task.Task_Type__c + ' ' + task.Unique_ID__c.subString(0,18);
            task.Parent_Task__c = parentTaskAssignmentMap.get(shortenedIdForMapKey).Id;
        }
        upsert subParentTaskInsertList Unique_ID__c;
        for (Partner_Task__c task : subTaskInsertList) {
            shortenedIdForMapKey = task.Sub_Task_Type__c + ' ' + task.Unique_ID__c.subString(0,18);
            task.Parent_Task__c = subParentTaskAssignmentMap.get(shortenedIdForMapKey).Id;
        }

        taskInsertList.addAll(parentTaskInsertList);
        taskInsertList.addAll(subParentTaskInsertList);
        taskInsertList.addAll(subTaskInsertList);

        for (Partner_Task__c taskRecord : taskInsertList) {
            taskMap.put(taskRecord.Unique_ID__c, taskRecord);
        }

        upsert subTaskInsertList Unique_ID__c;
        List<Lead> leadList = [SELECT Id, Name, Self_Employed__c, Retired__c, ConvertedContactId FROM Lead WHERE Id IN : leadIdList];
        validateLoanInformationProvidedOnLead(leadList, taskMap);   // add conditional customer type as a parameter to run income check on retirees, etc.
    }

    public Partner_Task__c createPartnerTask (Loan__c loanRecord, String taskLevel, String name, String uniqueId,
                                              Integer partnerSequenceCounter, String status, String taskType, String subTaskType, Partner_Task__c parentTask,
                                              RecordType recordType, List<Partner_Task__c> parentTaskInsertList,
                                              List<Partner_Task__c> subParentTaskInsertList, List<Partner_Task__c> subTaskInsertList,
                                              Map<String, Partner_Task__c> parentTaskAssignmentMap,
                                              Map<String, Partner_Task__c> subParentTaskAssignmentMap,
                                              String progressBarName, Boolean withDefaultStatus) {
        Partner_Task__c task = new Partner_Task__c(
            Name = name,
            RecordType = recordType,
            Unique_ID__c = loanRecord.Lead__r.Id + ' ' + uniqueId,
            Partner__c = loanRecord.Partner__r.Id,
            Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
            Start_Date__c = Date.today(),
            Task_Type__c = taskType
        );
        if (withDefaultStatus) {
            task.Status__c = status;
        }
        if (taskLevel == 'Grandparent') {
            task.Lead__c = loanRecord.Lead__r.Id;
            task.Opportunity__c = loanRecord.Opportunity__c;
            task.Parent__c = true;
            task.Task_Sequence__c = partnerSequenceCounter;
            task.Loan__c = loanRecord.Id;
            task.Progress_Bar_Name__c = progressBarName;
            if (name == 'Run Credit Check') {
                task.Completion_Date__c = Date.today();
            }
            if (name == 'Provide All Customer Information') {
                task.SubTasks__c = true;
            }
            parentTaskInsertList.add(task);
            String parentTaskTypeMapUniqueId = task.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, task);
            partnerSequenceCounter = partnerSequenceCounter + 1;
        } else if (taskLevel == 'Parent') {
            task.Parent__c = true;
            task.Sub_Task_Type__c = subTaskType;
            task.Parent_Task__c = parentTask.Id;
            task.Loan__c = loanRecord.Id;
            if (name == 'Provide Income Documentation' &&
                (loanRecord.Lead__r.Employed__c ||
                    loanRecord.Lead__r.Self_Employed__c ||
                    loanRecord.Lead__r.Retired__c ||
                    loanRecord.Lead__r.Veteran_Disability__c)) {
                task.SubTasks__c = true;
            }
            subParentTaskInsertList.add(task);
            String subTaskTypeMapUniqueId = task.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, task);
        } else if (taskLevel == 'Child') {
            task.Parent_Task__c = parentTask.Id;
            task.Sub_Task_Type__c = subTaskType;
            subTaskInsertList.add(task);
        }
        return task;
    }

    public static Map<String, Partner_Task__c> getPartnerTasks(List<String> leadList) {
        Map<String, Partner_Task__c> taskMap = new Map<String, Partner_Task__c>();
        for (Partner_Task__c partnerTask : [SELECT Id, Name, Parent_Task__c, Unique_ID__c, Partner__c, Parent__c,  Task_Sequence__c,
                                                Status__c, Start_Date__c, Task_Type__c, Lead__c, Lead__r.Id, Comments__c, Completion_Date__c,
                                                (SELECT Id, Name, Status__c, Parent_Task__c, Parent_Task__r.Name, Completion_Date__c
                                                 FROM subTasks__r)
                                            FROM Partner_Task__c
                                            WHERE (Lead__c IN : leadList
                                                OR Parent_Task__r.Loan__r.Lead__r.Id IN : leadList)]) {
            taskMap.put(partnerTask.Unique_ID__c, partnerTask);
        }
        return taskMap;
    }

    //Check if Individual or Joint Application for Contract Signature
    public static Boolean checkCustomerContractSignatures(Opportunity newOpp, Opportunity oldOpp){
        if (newOpp.Application_Type__c == 'Joint' &&  newOpp.Product_Line__c == 'Residential Loan'
            && newOpp.Contract_Status__c == 'Completed' && newOpp.Co_Applicant_Signature_Status__c == 'Completed'
            && (oldOpp.Contract_Status__c != 'Completed' || oldOpp.Co_Applicant_Signature_Status__c != 'Completed')){
            return true;
        } else if (newOpp.Application_Type__c == 'Individual' && newOpp.Contract_Status__c == 'Completed'
            && oldOpp.Contract_Status__c != 'Completed'
            && newOpp.Product_Line__c == 'Residential Loan') {
            return true;
        } else {
            return false;
        }
    }

    public void validateLoanInformationProvidedOnLead(List<Lead> leadList, Map<String, Partner_Task__c> taskMap) {
        List<Partner_Task__c> validatedTaskList = new List<Partner_Task__c>();

        if (!leadList.isEmpty()) {
            List<Partner_Task__c> incomeTaskList = new List<Partner_Task__c>(checkLoanIncomeFiles(leadList, taskMap));
            validatedTaskList.addAll(incomeTaskList);

            List<Partner_Task__c> systemInfoTaskList = new List<Partner_Task__c>(checkSystemInformation(leadList, taskMap));
            validatedTaskList.addAll(systemInfoTaskList);

            List<Partner_Task__c> technicalApprovalTaskList = new List<Partner_Task__c>(checkTechnicalConfirmationFiles(leadList, taskMap));
            validatedTaskList.addAll(technicalApprovalTaskList);
        }
        //Load the validatedTaskList into a set to remove duplicates. This is important, if the validation methods return
        //a task in both lists it will send an error. Main cause of this is due to the incompleteTaskList return statement
        //at the bottom of both methods. They're needed however to save the method.
        Set<Partner_Task__c> validatedTaskSet = new Set<Partner_Task__c>(validatedTaskList);
        ////load the set back into a list for update
        List<Partner_Task__c> validatedTaskListDuplicatesRemoved = new List<Partner_Task__c>();
        validatedTaskListDuplicatesRemoved.addAll(validatedTaskSet);
        update validatedTaskListDuplicatesRemoved; //update the subtasks
        //run through this method twice because the child tasks have to be updated before the parent tasks in order to qualify for completion.
        updatePartnerParentTaskStatus(taskMap); //update the Parent SubTasks
        updatePartnerParentTaskStatus(taskMap); //update the Parent Tasks
    }

     public void validateLoanInformationProvidedOnOpp(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap) {
         List<Partner_Task__c> validatedTaskList = new List<Partner_Task__c>();
         if (!oppList.isEmpty()) {
             List<Partner_Task__c> salesAgreementTaskList = new List<Partner_Task__c>(checkSalesAgreementFiles(oppList, taskMap));
             validatedTaskList.addAll(salesAgreementTaskList);
         }

         //Load the validatedTaskList into a set to remove duplicates. This is important, if the validation methods return
         //a task in both lists it will send an error. Main cause of this is due to the inocompleteTaskList return statement
         //at the bottom of both methods. They're needed however to save the method.
         Set<Partner_Task__c> validatedTaskSet = new Set<Partner_Task__c>(validatedTaskList);
         ////load the set back into a list for update
         List<Partner_Task__c> validatedTaskListDuplicatesRemoved = new List<Partner_Task__c>();
         validatedTaskListDuplicatesRemoved.addAll(validatedTaskSet);
         update validatedTaskListDuplicatesRemoved; //update the subtasks
         //run through this method twice because the child tasks have to be updated before the parent tasks in order to qualify for completion.
         updatePartnerParentTaskStatus(taskMap); //update the Parent SubTasks
         updatePartnerParentTaskStatus(taskMap); //update the Parent Tasks
    }

    public List<Partner_Task__c> checkLoanIncomeFiles(List<Lead> leadList, Map<String, Partner_Task__c> taskMap) {
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());

        Set<Id> parentIds = new Set<Id>();
        Map<Id, Id> contactToLeadMap = new Map<Id, Id>();
        for (Lead leadRecord : leadList) {
            parentIds.add(leadRecord.Id);
            parentIds.add(leadRecord.ConvertedContactId);
            contactToLeadMap.put(leadRecord.ConvertedContactId, leadRecord.Id);
        }
        List<Attachment> attachments = [
            SELECT Id, Name, ParentId, Description
            FROM Attachment
            WHERE Description != NULL AND ParentId IN : parentIds
        ];
        for (Attachment incomeAttachment : attachments) {
            for (String attachmentKeys : attachmentToTaskMap.keySet()) {
                if (incomeAttachment.Description.contains(attachmentKeys)) {
                    Partner_Task__c incomeTask = taskMap.get(getLeadId(incomeAttachment.ParentId, contactToLeadMap) + ' ' + attachmentToTaskMap.get(attachmentKeys));
                    if (incomeTask == null) {continue;}
                    incomeTask.Status__c = 'Complete';
                    incomeTask.Completion_Date__c = Date.today();
                    completedTaskList.add(incomeTask);
                }
            }
        }
        if (completedTaskList.size()>0) {
            return completedTaskList;
        } else {
            return incompleteTaskList;
        }
    }

    private Map<String, String> attachmentToTaskMap = new Map<String, String>{
        'PayStub' => 'PayStub Documentation',
        'Tax Return (Previous Year)' => 'Tax Return (Previous Year)',
        'Tax Return (Two Years Previous)' => 'Tax Return (Two Years Previous)',
        'SSN Award Letter' => 'SSN/Pension Award Letter or Bank Statement',
        'Pension Award Letter' => 'SSN/Pension Award Letter or Bank Statement',
        'Bank Statement (SSN Income)' => 'SSN/Pension Award Letter or Bank Statement',
        'Veteran Income Documentation' => 'All Income Documentation'
    };

    public List<Partner_Task__c> checkSalesAgreementFiles(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap) {
         String taskUniqueId;
         List<Id> oppIdList = new List<Id>();
         List<String> oppLeadIdList = new List<String>();
         List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
         List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());
         List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
         Map<String, String> oppLeadIdMap = new Map<String,String>();

         for (Opportunity opportunityRecord : oppList) {
             oppIdList.add(opportunityRecord.Id);
             oppLeadIdList.add(opportunityRecord.Lead_ID__c);
         }
         for (Lead leadRecord : [SELECT Id, ConvertedOpportunityId FROM Lead WHERE ConvertedOpportunityId IN : oppIdList]) {
             oppLeadIdMap.put(leadRecord.ConvertedOpportunityId, leadRecord.Id);
         }

         for (Attachment salesAgreementAttachment: [SELECT Id, Name, Body, ParentId, Description
                                                     FROM Attachment
                                                     WHERE Description != null
                                                     AND ParentId IN : oppIdList]) {
             if (salesAgreementAttachment.Description.contains('Sales Agreement')) {
                 taskUniqueId = oppLeadIdMap.get(salesAgreementAttachment.ParentId) + ' ' + 'Sales Agreement';
                 taskMap.get(taskUniqueId).Status__c = 'Complete';
                 taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                 completedTaskList.add(taskMap.get(taskUniqueId));
             }
         }
         nextTasksToUpdate.addAll(updateNextTaskToPending(oppLeadIdList, completedTaskList));
         update nextTasksToUpdate;
         if (completedTaskList.size()>0) {
             return completedTaskList;
         } else {
             return incompleteTaskList;
         }
     }

    public List<Partner_Task__c> checkSystemInformation(List<Lead> leadList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        List<String> leadIdList = new List<String>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());

        for (Lead leadRecord : leadList) {
            leadIdList.add(leadRecord.Id);
        }

        for (Residential_Equipment__c equipment : [SELECT Id, Lead__c, Lead__r.Id, Loan__c, Loan__r.Id, Loan__r.Commencement_Datee__c,
                                                    Lead__r.Requested_Loan_Amount__c, Type_of_Module__c, Type_of_Inverter__c, Loan__r.Lead__c,
                                                    Number_of_Modules__c, Number_of_Inverters__c, Generator_Nameplate_Capacity__c,
                                                    Module_Manufacturer__c, Module_Model_Number__c, Inverter_Manufacturer__c, Inverter_Model_Number__c,
                                                    Loan__r.Lead__r.Storage__c, Storage_Grid_Hybrid__c, Storage_Full_or_Partial_Home__c, Storage_Capacity__c,
                                                    Storage_Manufacturer__c, Storage_Model__c, Storage_Inverter_Manufacturer__c, Storage_Inverter_Model__c
                                                   FROM Residential_Equipment__c
                                                   WHERE Lead__c IN : leadIdList]) {
            taskUniqueId = equipment.Lead__r.Id + ' ' + 'Provide all System Information';
            if (equipment.Lead__r.Requested_Loan_Amount__c > 0
                && equipmentPopulated(equipment)
                && taskMap.get(taskUniqueId) != null
                && taskMap.get(taskUniqueId).Status__c != 'Complete') {
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                completedTaskList.add(taskMap.get(taskUniqueId));
            }
        }
        if (completedTaskList.size() > 0) {
            return completedTaskList;
        } else {
            return incompleteTaskList;
        }
    }

    public static Boolean equipmentPopulated(Residential_Equipment__c equipment) {
        if (equipment.Loan__r.Lead__r.Storage__c && equipment.Storage_Grid_Hybrid__c) {
            return (equipmentPopulatedForLoan(equipment)
                && equipmentPopulatedForStorage(equipment)
                && equipment.Storage_Full_or_Partial_Home__c != null);
        } else if (equipment.Loan__r.Lead__r.Storage__c && !equipment.Storage_Grid_Hybrid__c) {
            return (equipmentPopulatedForLoan(equipment)
                && equipmentPopulatedForStorage(equipment));
        } else {
            return (equipmentPopulatedForLoan(equipment));
        }
    }

    private static Boolean equipmentPopulatedForLoan(Residential_Equipment__c equipment) {
        return (equipment.Module_Manufacturer__c != null
            && equipment.Module_Model_Number__c != null
            && equipment.Number_of_Modules__c != null
            && equipment.Inverter_Manufacturer__c != null
            && equipment.Inverter_Model_Number__c != null
            && equipment.Number_of_Inverters__c != null
            && equipment.Generator_Nameplate_Capacity__c != null
            && equipment.Loan__r.Commencement_Datee__c != null);
    }

    private static Boolean equipmentPopulatedForStorage(Residential_Equipment__c equipment) {
        return (equipment.Storage_Grid_Hybrid__c != null
            && equipment.Storage_Capacity__c != null
            && equipment.Storage_Manufacturer__c != null
            && equipment.Storage_Model__c != null
            && equipment.Storage_Inverter_Manufacturer__c != null
            && equipment.Storage_Inverter_Model__c != null);
    }

    public List<Partner_Task__c> checkTechnicalConfirmationFiles (List<Lead> leadList, Map<String, Partner_Task__c> taskMap) {
        Set<Id> parentIds = new Set<Id>();
        Map<Id, Id> contactToLeadMap = new Map<Id, Id>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());

        for (Lead leadRecord : leadList) {
            parentIds.add(leadRecord.Id);
            parentIds.add(leadRecord.ConvertedContactId);
            contactToLeadMap.put(leadRecord.ConvertedContactId, leadRecord.Id);
        }
        List<Attachment> attachments = [
            SELECT Id, Name, ParentId, Description
            FROM Attachment
            WHERE Description LIKE '%MSLP Technical Confirmation%' AND ParentId IN : parentIds
        ];
        for (Attachment attachment : attachments) {
            Partner_Task__c task = taskMap.get(getLeadId(attachment.ParentId, contactToLeadMap) + ' ' + 'Technical Approval Confirmation');
            if (task == null) {continue;}
            task.Status__c = 'Complete';
            task.Completion_Date__c = Date.today();
            completedTaskList.add(task);
        }
        if (completedTaskList.size()>0) {
            return completedTaskList;
        } else {
            return incompleteTaskList;
        }
    }

    //If all Partner Sub-Tasks are set to complete, set the parent Partner task to complete.
    public void updatePartnerParentTaskStatus(Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        Integer subTaskCompleteCount = 0;
        Integer subTaskSize;
        Decimal nextTask;
        List<Partner_Task__c> parentTasksToUpdate = new List<Partner_Task__c>();
        List<Partner_Task__c> parentTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> completedParentTasksWithNextTask = new List<Partner_Task__c>();
        List<String> leadIdList = new List<String>();

        for (Partner_Task__c task : taskMap.values()) {
            if (task.Parent__c == true) {
                parentTaskList.add(task);
            }
        }
        //check to see if below query is needed - it may not be. Written in due to uncertainty of child records coming into the taskMap parameter.
        for (Partner_Task__c parentTask : [SELECT Id, Name, Task_Type__c, Status__c, Parent__c, Task_Sequence__c,
                                            Parent_Task__c, Unique_ID__c, Lead__r.Id, Lead__c,
                                            (SELECT Id, Name, Status__c, Parent_Task__c, Parent_Task__r.Name
                                            FROM subTasks__r)
                                           FROM Partner_Task__c
                                           WHERE Id IN : parentTaskList]) {
            subTaskSize = parentTask.subTasks__r.size();
            for (Partner_Task__c subTask : parentTask.subTasks__r) {
                if (subTask.Status__c == 'Complete') {
                    subTaskCompleteCount = subTaskCompleteCount + 1;
                }
            }
            if (subTaskCompleteCount == subTaskSize && subTaskCompleteCount != 0 && parentTask.Status__c != 'Complete') {
                parentTask.Status__c = 'Complete';
                parentTask.Completion_Date__c = Date.today();
                parentTasksToUpdate.add(parentTask);
                //Add all Parent tasks that have been set to complete to the completedTask list. Do not add it if it is the last task in the sequence
                if (parentTask.Sub_Task_Type__c == null && parentTask.Parent_Task__c == null) {
                    leadIdList.add(parentTask.Lead__c);
                    completedParentTasksWithNextTask.add(parentTask);
                }
            }
            subTaskCompleteCount = 0;
        }
        //add the tasks that need to be changed to pending to the update list
        parentTasksToUpdate.addAll(updateNextTaskToPending(leadIdList, completedParentTasksWithNextTask));
        update parentTasksToUpdate;
    }

    public static List<Partner_Task__c> updateNextTaskToPending(List<String> leadIdList, List<Partner_Task__c> completedTasks) {
        String taskSequenceKey; //key value
        String taskSequenceUniqueId; //accessor value
        Decimal nextTask;
        Boolean executeLeadUpdate = false;
        List<Partner_Task__c> tasksToUpdate = new List<Partner_Task__c>();
        Map<String,Partner_Task__c> parentTaskSequenceMap = new Map<String, Partner_Task__c>();
        Map<String, Integer> parentTaskSizeMap = new Map<String, Integer>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        for (Lead leadRecord : [SELECT Id, Name,
                                    (SELECT Id, Name, Task_Type__c, Status__c, Parent__c, Task_Sequence__c,
                                        Parent_Task__c, Unique_ID__c
                                     FROM Partner_Tasks__r)
                                FROM Lead
                                WHERE Id IN : leadIdList]) {
            leadMap.put(leadRecord.Id, leadRecord);
            for (Partner_Task__c task : leadRecord.Partner_Tasks__r) {
                    taskSequenceKey = leadRecord.Id + ' ' + task.Task_Sequence__c;
                    parentTaskSequenceMap.put(taskSequenceKey, task);
            }
            parentTaskSizeMap.put(leadRecord.Id, leadRecord.Partner_Tasks__r.size());
        }
        if (completedTasks.size() > 0) {
            for (Partner_Task__c task : completedTasks) {
                //if the partner task is not the last task in the sequence, update the next task to pending
                if (task.Task_Sequence__c < parentTaskSizeMap.get(task.Lead__r.Id)) {
                    nextTask = task.Task_Sequence__c + 1;
                    taskSequenceUniqueId = task.Lead__r.Id + ' ' + nextTask;
                    if (task.Name == 'Provide All Customer Information') {
                        leadMap.get(task.Lead__c).Status = 'Under BlueWave Review';
                        executeLeadUpdate = true;
                    }

                    if (parentTaskSequenceMap.get(taskSequenceUniqueId).Status__c == 'Incomplete'
                        && task.Task_Sequence__c < parentTaskSequenceMap.size()) {
                         parentTaskSequenceMap.get(taskSequenceUniqueId).Status__c = 'Pending';
                         parentTaskSequenceMap.get(taskSequenceUniqueId).Start_Date__c = Date.today();
                         tasksToUpdate.add(parentTaskSequenceMap.get(taskSequenceUniqueId));
                    }
                }
            }
        }
        if (executeLeadUpdate) {
            update leadMap.values();
        }
        return tasksToUpdate;
    }

    // update the under BW review partner task when the lead gets converted to an opportunity
    public static void updatePartnerTaskUnderBlueWaveReview(List<Lead> leadList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> leadIdList = new List<String>();

        for (Lead leadRecord : leadList) {
            taskUniqueId = leadRecord.Id + ' ' + 'Under BlueWave Review';
            taskMap.get(taskUniqueId).Status__c = 'Complete';
            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(taskMap.get(taskUniqueId));
            leadIdList.add(leadRecord.Id);
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(leadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    // update the contract signature partner task when the contract is signed and the oppStage is set to closed.
    public void updatePartnerTaskObtainContractSignature(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        String partnerTaskLeadIdSubString;
        String partnerTaskLeadIdString;
        String partnerTaskUniqueIdSubString;
        Partner_Task__c partnerTask;
        List<Partner_Task__c> parentPartnerTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> OppLeadIdList = new List<String>();
        Map<String, Partner_Task__c> tempTaskMapLeadId15String = new Map<String, Partner_Task__c>();

        // filter out the child-tasks from the task map
        for (Partner_Task__c partnerTaskLoopRecord : taskMap.values()) {
            if (partnerTaskLoopRecord.Parent__c == true && partnerTaskLoopRecord.Lead__c != null) {
                parentPartnerTaskList.add(partnerTaskLoopRecord);
            }
        }

        //create a new map that sets the 15 digit ID to the keyValue
        for (Partner_Task__c partnerTaskLoopRecord : parentPartnerTaskList) {
            partnerTaskLeadIdString = String.valueOf(partnerTaskLoopRecord.Lead__r.Id);
            partnerTaskLeadIdSubString = partnerTaskLeadIdString.subString(0,15);
            partnerTaskUniqueIdSubString = partnerTaskLeadIdSubString + ' ' + partnerTaskLoopRecord.Name;
            partnerTask = taskMap.get(partnerTaskLoopRecord.Unique_ID__c);
            tempTaskMapLeadId15String.put(partnerTaskUniqueIdSubString, partnerTask);
        }

        //locate the task and set it to complete
        for (Opportunity oppRecord : oppList) {
            taskUniqueId = oppRecord.Lead_ID__c + ' ' + 'Obtain Contract Signature';
            tempTaskMapLeadId15String.get(taskUniqueId).Status__c = 'Complete';
            tempTaskMapLeadId15String.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(tempTaskMapLeadId15String.get(taskUniqueId));
            OppLeadIdList.add(oppRecord.Lead_ID__c);
        }
        //update the task and set the next task to pending
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(OppLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    // update the contract signature partner task when the contract is signed and the oppStage is set to closed.
    public void updatePartnerTaskBlueWaveCounterSignature(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        String partnerTaskLeadIdSubString;
        String partnerTaskLeadIdString;
        String partnerTaskUniqueIdSubString;
        Partner_Task__c partnerTask;
        List<Partner_Task__c> parentPartnerTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> OppLeadIdList = new List<String>();
        Map<String, Partner_Task__c> tempTaskMapLeadId15String = new Map<String, Partner_Task__c>();

        // filter out the child-tasks from the task map
        for (Partner_Task__c partnerTaskLoopRecord : taskMap.values()) {
            if (partnerTaskLoopRecord.Parent__c && partnerTaskLoopRecord.Lead__c != null) {
                parentPartnerTaskList.add(partnerTaskLoopRecord);
            }
        }

        //create a new map that sets the 15 digit ID to the keyValue
        for (Partner_Task__c partnerTaskLoopRecord : parentPartnerTaskList) {
            partnerTaskLeadIdString = String.valueOf(partnerTaskLoopRecord.Lead__r.Id);
            partnerTaskLeadIdSubString = partnerTaskLeadIdString.subString(0,15);
            partnerTaskUniqueIdSubString = partnerTaskLeadIdSubString + ' ' + partnerTaskLoopRecord.Name;
            partnerTask = taskMap.get(partnerTaskLoopRecord.Unique_ID__c);
            tempTaskMapLeadId15String.put(partnerTaskUniqueIdSubString, partnerTask);
        }

        //locate the task and set it to complete
        for (Opportunity oppRecord : oppList) {
            taskUniqueId = oppRecord.Lead_ID__c + ' ' + 'BlueWave Counter Signature';
            tempTaskMapLeadId15String.get(taskUniqueId).Status__c = 'Complete';
            tempTaskMapLeadId15String.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(tempTaskMapLeadId15String.get(taskUniqueId));
            OppLeadIdList.add(oppRecord.Lead_ID__c);
        }
        //update the task and set the next task to pending
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(OppLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    public void updatePartnerTaskMaterialsInvoice (Loan__c loanToUpdate, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();

        taskUniqueId = loanToUpdate.Lead__c + ' ' + 'Material Invoice';
            if (taskMap.get(taskUniqueId).Status__c != 'Complete') {
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                taskUpdateList.add(taskMap.get(taskUniqueId));
                equipmentLeadIdList.add(loanToUpdate.Lead__c);
            }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    public void updatePartnerTaskNYBuildingPermit(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();

        for (Residential_Equipment__c equipmentLoopVar : equipmentList) {
            taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Building Permit';
            if (!equipmentLoopVar.DOER_Solar_Loan__c && taskMap.get(taskUniqueId).Status__c != 'Complete') {
                taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Building Permit';
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                taskUpdateList.add(taskMap.get(taskUniqueId));
                equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
            }
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    //update the mechanical install partner task when the equipment is reported as mechanically installed.
    public void updatePartnerTaskMechanicalInstallation(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();

        for (Residential_Equipment__c equipmentLoopVar : equipmentList) {
            if (!equipmentLoopVar.DOER_Solar_Loan__c) {
                taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Mechanical Installation';
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                taskUpdateList.add(taskMap.get(taskUniqueId));
                equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
            }
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    // update the interconnection partner task when the equipment is reported as interconnected
    public void updatePartnerTaskInterconnection(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap) {
        String taskUniqueId;
        Boolean ptoDocumentProvided = false;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();
        List<String> equipmentIdList = new List<String>();
        for (Residential_Equipment__c equipmentLoopVar : equipmentList) {
            equipmentIdList.add(equipmentLoopVar.Id);
        }
        for (Attachment ptoAttachment : [SELECT Id, Name, Body, ParentId, Description
                                         FROM Attachment
                                         WHERE Description != null AND ParentId IN : equipmentIdList]) {
            if (ptoAttachment.Description.contains('PTO Documentation')) {
                ptoDocumentProvided = true;
            }
        }
        for (Residential_Equipment__c equipmentLoopVar : equipmentList) {
            List<String> fieldNames = new List<String>{'Annual_Production_kWh_kW__c', 'Interconnected__c', 'Interconnection_Date__c',  'Percentage_of_System_Shaded__c',  'SREC_Opt_In_Calendar_Quarter__c',  'Generator_Type__c',  'MA_Facility_Sector__c',  'Generator_Nameplate_Capacity__c',  'Contract_Execution_Date__c',  'Generator_Interconnection_Date__c',  'Generator_Installation_Date__c',  'Generator_Energized_Online_Date__c',  'Module_Manufacturer__c',  'Module_Model_Number__c',  'Module_Power_Rating__c',  'Number_of_Modules__c',  'Module_Array_Mounting_Type__c',  'Module_Array_Azimuth__c',  'Module_Array_Tilt__c',  'Module_Mounting_Location__c',  'Inverter_Manufacturer__c',  'Inverter_Model_Number__c',  'Number_of_Meters__c',  'Solar_Meter_Manufacturer__c',  'Solar_Meter_Model__c',    'Solar_Meter_Serial_Number__c'};
            Boolean nullOrBlankResult = checkNullOrBlankField(equipmentList.get(0), fieldNames);
            if (equipmentLoopVar.State__c == 'MA') {
                if (nullOrBlankResult && ptoDocumentProvided) {
                    taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Interconnection';
                    taskMap.get(taskUniqueId).Status__c = 'Complete';
                    taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                    taskUpdateList.add(taskMap.get(taskUniqueId));
                    equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
                } else {
                    return;
                }
            } else {
                if (ptoDocumentProvided) {
                    taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Interconnection';
                    taskMap.get(taskUniqueId).Status__c = 'Complete';
                    taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                    taskUpdateList.add(taskMap.get(taskUniqueId));
                    equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
                } else {
                        return;
                }
            }
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    public static void completeAdditionalIncomeDocTask(Id leadId){
        Map<String, Partner_Task__c> taskMap = getPartnerTasks(new List<String>{
            leadId
        });
        Partner_Task__c provideAddIncomeTask = taskMap.get(leadId + ' Additional Income Documentation');
        provideAddIncomeTask.Status__c = 'Complete';
        provideAddIncomeTask.Completion_Date__c = Date.today();
        taskMap.remove(leadId + ' Additional Income Documentation');
        taskMap.put(leadId + ' Additional Income Documentation', provideAddIncomeTask);

        update provideAddIncomeTask;
        LoanHandler lh = new LoanHandler();
        lh.updatePartnerParentTaskStatus(taskMap);
        updateNextTaskToPending(new List<String> {leadId}, taskMap.values());
    }

    // Sets status of Interconnection Partner task to Pending if the ResiEquip's interconnected status moves from true to false.
    public void rollbackEquipmentAndInterconnectionTask(List<Id> equipIds) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Id> leadIds = new List<Id>();
        List<Residential_Equipment__c> resiEquips = [
            SELECT Id, Interconnected__c, Lead__r.Lead_ID__c, Opportunity__r.Interconnected__c
            FROM Residential_Equipment__c
            WHERE Id IN :equipIds
        ];

        for (Residential_Equipment__c resiEquip : resiEquips) {
            resiEquip.Opportunity__r.Interconnected__c = false;
            oppsToUpdate.add(resiEquip.Opportunity__r);
            leadIds.add(resiEquip.Lead__r.Lead_ID__c);
        }

        update oppsToUpdate;

        Map<String, Partner_Task__c> taskMap =  getPartnerTasks(leadIds);

        for (Residential_Equipment__c equipmentLoopVar : resiEquips) {
            String taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Interconnection';
            taskMap.get(taskUniqueId).Status__c = 'Pending';
            taskUpdateList.add(taskMap.get(taskUniqueId));
        }
        update taskUpdateList;
    }

    public static Boolean checkNullOrBlankField(Residential_Equipment__c equipment, List<String> fieldNames) {
        Boolean checkResult = true;
        Map<String, Object> equipmentFieldMap = new Map<String,Object>(equipment.getPopulatedFieldsAsMap());

        for (String fieldName : fieldNames) {
            if (equipmentFieldMap.get(fieldName) instanceof Integer || equipmentFieldMap.get(fieldName) instanceof Double) {
                if (equipmentFieldMap.get(fieldName) != null) {
                    continue;
                } else {
                    checkResult = false;
                }
            } else if (equipmentFieldMap.get(fieldName) instanceof String) {
                if (String.isNotBlank((String)equipmentFieldMap.get(fieldName))) {
                    continue;
                } else {
                    checkResult = false;
                }
            } else if (equipmentFieldMap.get(fieldName) instanceof Boolean) {
                continue;
            } else if (equipmentFieldMap.get(fieldName) instanceof Date) {
                if (equipmentFieldMap.get(fieldName) != null) {
                    continue;
                } else {
                    checkResult = false;
                }
            } else {
                checkResult = false;
            }
        }
        return checkResult;
     }

    public static void assignResidentialEquipmentToLoan(List<Loan__c> loanList) {
        List<Residential_Equipment__c> equipmentUpdateList =   new List<Residential_Equipment__c>();
        List<String> leadIdList = new List<String>();
        for (Loan__c loan : loanList) {
            leadIdList.add(loan.Lead__c);
        }
        for (Residential_Equipment__c equipment : [SELECT Id, Lead__c, Lead__r.Id, Loan__c
                                                   FROM Residential_Equipment__c
                                                   WHERE Lead__c IN : leadIdList]) {
            for (Loan__c loanRecord : loanList) {
                if (loanRecord.Lead__c == equipment.Lead__c) {
                    equipment.Loan__c = loanRecord.Id;
                    equipmentUpdateList.add(equipment);
                }
            }
        }
        update equipmentUpdateList;
    }

    // Because we attach documents to contacts if a lead is converted, and we use the Lead ID to
    // find partner tasks, we need to turn a contact id into a lead id if necessary.
    private String getLeadId(Id id, Map<Id, Id> contactToLeadMap) {
        if (id.getSObjectType().getDescribe().getName() == 'Lead') {
            return id;
        } else {
            return contactToLeadMap.get(id);
        }
    }

    public void checkLoanCompletePartnerTasks(Loan__c newLoan, Map<Id, Loan__c> oldLoanMap) {
        if (newLoan.Profit_Center__c != null && oldLoanMap.get(newLoan.Id).Profit_Center__c == null) {
            updatePartnerTaskMaterialsInvoice(newLoan, getPartnerTasks(new List<String>{newLoan.Lead__c}));
            updateDisbursalsForCEDLoan(newLoan);
        }
    }

    public void updateDisbursalsForCEDLoan(Loan__c loan) {
        QueueableDisbursalUpsert updateJob = new QueueableDisbursalUpsert(loan);
        System.enqueueJob(updateJob);
    }

    // Called before update or insert to set Number of Days past due
    public void setDaysPastDue(Loan__c loan, Map<Id, Loan__c> oldLoanMap) {
            Integer numDPD = (Integer) loan.Number_of_Days_Past_Due__c;
            if (oldLoanMap == null ||
                numDPD != oldLoanMap.get(loan.Id).Number_of_Days_Past_Due__c) {
                if (numDPD == null || numDPD == 0) {
                    loan.Days_Past_Due__c = null;
                } else if (numDPD >= 1 && numDPD <= 30) {
                    loan.Days_Past_Due__c = '1-30';
                } else if (numDPD >= 31 && numDPD <= 60) {
                    loan.Days_Past_Due__c = '31-60';
                } else if (numDPD >= 61 && numDPD <= 90) {
                    loan.Days_Past_Due__c = '61-90';
                } else if (numDPD >= 91) {
                    loan.Days_Past_Due__c = '91+';
                }
            }
    }

    @TestVisible
    private static void resetTriggerContext() {
        ranAfterUpdate = false;
        ranBeforeUpdate = false;
        ranAfterInsert = false;
        ranBeforeInsert = false;
    }
}