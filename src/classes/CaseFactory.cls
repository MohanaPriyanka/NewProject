/**
 * @description Creates cases for various input scenarios
 * Tested by: CaseFactoryTest, UtilityDataRequestServiceTest
 */
public without sharing class CaseFactory implements Queueable {

    /* INSTANCE VARS */
    public Set<Id> erroredUtilityDataRequestIds;
    private String queueType;
    private Lead lead;
    private List<Utility_Data_Request__c> utilityDataRequests;
    private Set<Id> utilityDataRequestsWithOpenErrorCases;
    private RecordType customerCare;
    private RecordType productSupport;
    private RecordType partnerCareCase;
    private OrgWideEmailAddress customerCareEmail;
    private Group customerCareQueue;
    private Group productQueue;
    private Group collectionsQueue;
    private Group dataOpsQueue;
    private Group customerQCQueue;
    private Group partnerSupportQueue;
    private Case newCase;
    private Map<String, EDI_Error_Mapping__mdt> ediErrorMappings;
    @TestVisible private UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();
    @TestVisible private CaseSelector caseSelector = new CaseSelector();

    public CaseFactory() {
        queryForRecordTypesAndQueues();
    }

    /**
     * @description This method is used to insert asynchronous cases based on queueType.
     * @param ctx Queueable context (is nullable if not run in queueable context)
     */
    public void execute(QueueableContext ctx) {
        try {
            switch on queueType {
                when 'No FICO Match' {
                    insertNoMatchCreditReportCase();
                }
                when 'Low FICO Match' {
                    insertLowMatchCreditReportCase();
                }
                when 'EDI Error' {
                    insertEDIErrorCases();
                }
            }
        } catch (Exception e) {
            String message =  e.getMessage() + '\n\n';
            message += 'Lead Id: ' + lead?.Id + '\n';
            message += 'Queue Type: ' + queueType + '\n';
            if (queueType == 'EDI Error') {
                message += 'Utility Data Requests: ' +
                    (erroredUtilityDataRequestIds.isEmpty() ? 'N/A' : erroredUtilityDataRequestIds.toString());
            }
            message += '\n\n' + e.getStackTraceString();
            Logger.logNow('CaseFactory', 'execute', message, Logger.ERROR);
        }
    }

    public void setLead(Lead lead) {
        this.lead = new LeadSelector().selectOne(lead.Id);
    }

    public void setQueueType(String queueType) {
        this.queueType = queueType;
    }

    public void assignTypes(List<RecordType> typeList) {
        for (RecordType type : typeList) {
            switch on type.DeveloperName {
                when 'Product_Support' {
                    productSupport = type;
                } when 'Customer_Care' {
                    customerCare = type;
                } when 'Partner_Care_Case' {
                    partnerCareCase = type;
                }
            }
        }
    }

    /**
     * @description This method creates a new case and sets defaults for owner, record type id, and record type
     * @param type The desired record type of the case.
     * @return new case
     */
    public Case getCase(String type) {
        newCase = new Case();
        switch on type {
            when 'Product_Support' {
                newCase.RecordTypeId = productSupport.Id;
                newCase.RecordType = productSupport;
                newCase.OwnerId = productQueue.Id;
            } when 'Customer_Care' {
                newCase.RecordTypeId = customerCare.Id;
                newCase.RecordType = customerCare;
                newCase.OwnerId = customerCareQueue.Id;
            } when 'Collections' {
                // Collections uses the customer care record type
                newCase.RecordTypeId = customerCare.Id;
                newCase.RecordType = customerCare;
                newCase.OwnerId = collectionsQueue.Id;
            } when 'Customer_QC' {
                newCase.RecordTypeId = customerCare.Id;
                newCase.RecordType = customerCare;
                newCase.OwnerId = customerQCQueue.Id;
            } when 'Data_Ops' {
                // Data Ops uses the customer care record type
                newCase.RecordTypeId = customerCare.Id;
                newCase.RecordType = customerCare;
                newCase.OwnerId = dataOpsQueue.Id;
            } when 'Partner_Care_Case' {
                newCase.RecordTypeId = partnerCareCase.Id;
                newCase.RecordType = partnerCareCase;
                newCase.OwnerId = partnerSupportQueue.Id;
            }
        }
        return newCase;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void queryForRecordTypesAndQueues() {
        if (customerCare == null || productSupport == null) {
            List<RecordType> caseRecordTypes = [
                SELECT Id, Name, DeveloperName
                FROM RecordType
                WHERE SobjectType = 'Case'
                AND (DeveloperName = 'Product_Support' OR DeveloperName = 'Customer_Care' OR DeveloperName = 'Partner_Care_Case')
                ORDER BY DeveloperName
            ];

            if (caseRecordTypes.size() != 3) {
                Logger.logNow('CaseFactory', 'constructor', 'Missing RecordType for case. Available RecordTypes: ' + caseRecordTypes);
            } else {
                assignTypes(caseRecordTypes);
            }
        }
        if (customerCareEmail == null) {
            customerCareEmail = [
                SELECT Id, Address
                FROM OrgWideEmailAddress
                WHERE Address = 'customercare@bluewavesolar.com'
                LIMIT 1
            ];
        }
        if (collectionsQueue == null || customerCareQueue == null || productQueue == null || customerQCQueue == null) {
            List<Group> assignmentGroups = [
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue'
                AND (DeveloperName = 'Collections' OR DeveloperName = 'Customer_Care' OR DeveloperName = 'Customer_QC'
                OR DeveloperName = 'Data_Ops' OR DeveloperName = 'Product_Support' OR DeveloperName = 'Partner_Support')
                ORDER BY DeveloperName
            ];
            if (assignmentGroups.size() != 6) {
                Logger.logNow('CaseFactory', 'constructor', 'Missing Groups for assignment. Available Groups: ' + assignmentGroups);
            } else {
                collectionsQueue = assignmentGroups[0];
                customerCareQueue = assignmentGroups[1];
                customerQCQueue = assignmentGroups[2];
                dataOpsQueue = assignmentGroups[3];
                partnerSupportQueue = assignmentGroups[4];
                productQueue = assignmentGroups[5];
            }
        }
    }

    /**
     * @description This method inserts a case when a leads credit report comes back as a no match.
     */
    private void insertNoMatchCreditReportCase() {
        if (caseSelector.selectOpenNoMatchCasesFromLead(lead).size() == 0) {
            Case newCcCase = getCase('Customer_QC');
            newCcCase.Lead_Lookup__c = lead.Id;
            newCcCase.Disable_Followup_Email__c = true;
            newCcCase.QC_Case_Subject__c = 'No Credit Match - Provide Additional Background on Guarantor (New Address or DOB)';
            newCcCase.Product_Line__c = 'Community Solar';
            newCcCase.AccountId = lead.Partner_Account__c;
            newCcCase.ContactId = lead.Sales_Person__c;
            newCcCase.Category__c = 'QC';
            newCcCase.Case_Type__c = '3rd Party';
            newCcCase.Sale_Status__c = 'Pre-Sale';
            newCcCase.Subject = lead.Name + ' - No Match Credit Report';
            newCcCase.Description = lead.Name + ' - This is a no match Personal Credit Report,' +
                ' please provide more information.';
            insert newCcCase;
        }
    }

    /**
     * @description This method inserts a case when a leads credit report comes back as a low match.
     */
    private void insertLowMatchCreditReportCase() {
        if (caseSelector.selectOpenLowMatchCasesFromLead(lead).size() == 0) {
            Case newCcCase = getCase('Customer_QC');
            newCcCase.Lead_Lookup__c = lead.Id;
            newCcCase.QC_Case_Subject__c = 'Low Credit Match - New Guarantor Needs to Apply';
            newCcCase.Product_Line__c = 'Community Solar';
            newCcCase.AccountId = lead.Partner_Account__c;
            newCcCase.ContactId = lead.Sales_Person__c;
            newCcCase.Category__c = 'QC';
            newCcCase.Sale_Status__c = 'Pre-Sale';
            newCcCase.Case_Type__c = '3rd Party';
            newCcCase.Subject = lead.Name + ' - Low Match Credit Report';
            newCcCase.Description = lead.Name + ' - Credit score does not qualify, ' +
                'please provide a passing credit report or we will send adverse action notice to customer';
            insert newCcCase;
        }
    }

    /**
     * @description This method inserts a case when Utility Data Requests come back in an error state
     * Handles multiple UDRs in error state in a single transaction
     */
    @TestVisible
    private void insertEDIErrorCases() {
        List<Case> casesToInsert = new List<Case>();
        getEDIErrorMappings();
        utilityDataRequests = udrSelector.selectUdrsForErrorCase(erroredUtilityDataRequestIds);
        utilityDataRequestsWithOpenErrorCases = udrSelector.getUtilityDataRequestsWithOpenErrorCases(utilityDataRequests);
        for (Utility_Data_Request__c udr : utilityDataRequests) {
            if (!utilityDataRequestsWithOpenErrorCases.contains(udr.Id)) {
                casesToInsert.add(createEDIErrorCase(udr));
            }
        }
        insert casesToInsert;
    }

    @TestVisible
    private void getEDIErrorMappings() {
        ediErrorMappings = new Map<String, EDI_Error_Mapping__mdt>();
        List<EDI_Error_Mapping__mdt> cmdtRecords = [
            SELECT Exception_Reason_Code__c, Case_Subject__c, Case_Description__c
            FROM EDI_Error_Mapping__mdt
        ];
        for (EDI_Error_Mapping__mdt errorDetail : cmdtRecords) {
            ediErrorMappings.put(errorDetail.Exception_Reason_Code__c, errorDetail);
        }
    }

    @TestVisible
    private Case createEDIErrorCase(Utility_Data_Request__c udr) {
        EDI_Error_Mapping__mdt errorDetail = ediErrorMappings.get(udr.Exception_Reason_Code__c);
        Case ediErrorCase = getCase('Customer_QC');
        ediErrorCase.Lead_Lookup__c = udr.Utility_Account_Log__r.Lead__c;
        ediErrorCase.QC_Case_Subject__c = 'Upload Complete Utility Bill to Case - Need More Pages';
        ediErrorCase.Product_Line__c = 'Community Solar';
        ediErrorCase.AccountId = udr.Utility_Account_Log__r.Lead__r.Partner_Account__c;
        ediErrorCase.ContactId = udr.Utility_Account_Log__r.Lead__r.Sales_Person__c;
        ediErrorCase.Category__c = 'QC';
        ediErrorCase.Sale_Status__c = 'Pre-Sale';
        ediErrorCase.Case_Type__c = '3rd Party';
        ediErrorCase.Subject = parseEDIMergeFields(udr, getEDICaseFieldText(errorDetail, 'Subject'));
        ediErrorCase.Description = parseEDIMergeFields(udr, getEDICaseFieldText(errorDetail, 'Description'));
        return ediErrorCase;
    }

    @TestVisible
    private String getEDICaseFieldText(EDI_Error_Mapping__mdt errorDetail, String requestedField) {
        String fieldValue;
        switch on requestedField {
            when 'Subject' {
                fieldValue = errorDetail != null ? errorDetail.Case_Subject__c :
                    '{Lead} - Unable to Obtain Annual Usage Data';
            } when 'Description' {
                fieldValue = errorDetail != null ? errorDetail.Case_Description__c :
                    '{Lead} - Unable to obtain annual usage data due to an error indicated by the utility. Please check ' +
                        'the submitted information and provide a new account number or additional details for utility ' +
                        'account {UAL}.';
            }
        }
        return fieldValue;
    }

    /**
     * @description Returns string with merge field replaced with record data
     * @param udr Utility Data Request record in error status
     * @param caseFieldValue Case field value with merge fields, if existing
     * @return String of field value
     */
    @TestVisible
    private String parseEDIMergeFields(Utility_Data_Request__c udr, String caseFieldValue) {
        String newFieldValue = caseFieldValue
            .replaceAll('\\{Lead\\}', udr.Utility_Account_Log__r.Lead__r.Name)
            .replaceAll('\\{UAL\\}', udr.Utility_Account_Log__r.Name);
        return newFieldValue;
    }
}