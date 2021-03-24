/**
 * Created by mstackhouse on 12/28/2018.
 * Description: 
 * Test: CaseFactoryTest
 */


public without sharing class CaseFactory implements Queueable {
    public static RecordType customerCare;
    public static RecordType productSupport;
    public static RecordType partnerCareCase;
    public static OrgWideEmailAddress customerCareEmail;
    public static Group customerCareQueue;
    public static Group productQueue;
    public static Group collectionsQueue;
    public static Group dataOpsQueue;
    public static Group customerQCQueue;
    public static Group partnerSupportQueue;
    public static Case newCase;
    private Lead lead;

    private String queueType;
    public CaseFactory() {
        queryForRecordTypesAndQueues();
    }
    public void setLead(Lead lead){
        this.lead = new LeadSelector().selectOne(lead.Id);
    }

    public void setQueueType(String queueType){
        this.queueType = queueType;
    }

    public void assignTypes(List<RecordType> typeList){
        for(RecordType type : typeList){
            if(type.DeveloperName=='Product_Support'){
                productSupport = type;
            } else if(type.DeveloperName=='Customer_Care'){
                customerCare = type;
            } else if(type.DeveloperName=='Partner_Care_Case'){
                partnerCareCase = type;
            }
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void queryForRecordTypesAndQueues() {
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
     * This method creates a new case and sets defaults for owner, record type id, and record type
     * @param type The desired record type of the case.
     *
     * @return new case
     */
    public Case getCase(String type) {
        newCase = new Case();
        if (type == 'Product_Support' ) {
            newCase.RecordTypeId = productSupport.Id;
            newCase.RecordType = productSupport;
            newCase.OwnerId = productQueue.Id;
        } else if (type == 'Customer_Care') {
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = customerCareQueue.Id;
        } else if (type == 'Collections') {
            // Collections uses the customer care record type
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = collectionsQueue.Id;
        } else if (type == 'Customer_QC') {
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = customerQCQueue.Id;
        } else if (type == 'Data_Ops') {
            // Data Ops uses the customer care record type
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = dataOpsQueue.Id;
        } else if (type == 'Partner_Care_Case') {
            newCase.RecordTypeId = partnerCareCase.Id;
            newCase.RecordType = partnerCareCase;
            newCase.OwnerId = partnerSupportQueue.Id;
        }
        return newCase;
    }
    /**
     * This method inserts a case when a leads credit report comes back as a no match.
     * @param lead The lead that the no match credit report case will be made for.
     */
    public void insertNoMatchCreditReportCase(Lead lead) {
        if (new CaseSelector().selectOpenNoMatchCasesFromLead(lead).size() == 0) {
            queryForRecordTypesAndQueues();
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
    * This method inserts a case when a leads credit report comes back as a low match.
    * @param lead The lead that the low match credit report case will be made for.
    */
    public void insertLowMatchCreditReportCase(Lead lead){
        if (new CaseSelector().selectOpenLowMatchCasesFromLead(lead).size() == 0) {
            queryForRecordTypesAndQueues();
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
            newCcCase.Description = lead.Name+' - Credit score does not qualify, ' +
                'please provide a passing credit report or we will send adverse action notice to customer';
            insert newCcCase;
        }
    }
    /**
     * This method is used to insert asynchronous cases based on queueType.
     * @param param1 Unused by method, but is required for queueable interface
     */
    public void execute(QueueableContext param1) {
        if(this.queueType =='No FICO Match'){
            insertNoMatchCreditReportCase(this.lead);
        }
        if(this.queueType == 'Low FICO Match'){
            insertLowMatchCreditReportCase(this.lead);
        }
    }
}