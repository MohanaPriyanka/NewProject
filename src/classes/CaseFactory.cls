/**
 * Created by mstackhouse on 12/28/2018.
 * Description: 
 * Test: CaseFactoryTest
 */


public without sharing class CaseFactory {
    public static RecordType customerCare;
    public static RecordType productSupport;
    public static OrgWideEmailAddress customerCareEmail;
    public static Group customerCareQueue;
    public static Group productQueue;
    public static Group collectionsQueue;
    public static Group dataOpsQueue;
    public static Case newCase;

    public CaseFactory() {
        if (customerCare == null || productSupport == null) {
            List<RecordType> caseRecordTypes = [
                SELECT Id, Name
                FROM RecordType
                WHERE SobjectType = 'Case'
                AND (DeveloperName = 'Product_Support' OR DeveloperName = 'Customer_Care')
                ORDER BY DeveloperName
            ];

            if (caseRecordTypes.size() != 2) {
                Logger.logNow('CaseFactory', 'constructor', 'Missing RecordType for case. Available RecordTypes: ' + caseRecordTypes);
            } else {
                customerCare = caseRecordTypes[0];
                productSupport = caseRecordTypes[1];
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

        if (collectionsQueue == null || customerCareQueue == null || productQueue == null){
            List<Group> assignmentGroups = [
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue'
                AND (DeveloperName = 'Product_Support' OR DeveloperName = 'Customer_Care' OR DeveloperName = 'Collections' OR DeveloperName = 'Data_Ops')
                ORDER BY DeveloperName
            ];

            if (assignmentGroups.size() != 4) {
                Logger.logNow('CaseFactory', 'constructor', 'Missing Groups for assignment. Available Groups: ' + assignmentGroups);
            } else {
                collectionsQueue = assignmentGroups[0];
                customerCareQueue = assignmentGroups[1];
                dataOpsQueue = assignmentGroups[2];
                productQueue = assignmentGroups[3];
            }
        }
    }

    public Case getCase(String type) {
        newCase = new Case();
        if (type == 'Product_Support') {
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
        } else if (type == 'Data_Ops') {
            // Data Ops uses the customer care record type
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = dataOpsQueue.Id;
        }
        return newCase;
    }
}