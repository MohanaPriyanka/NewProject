/**
 * Created by mstackhouse on 12/28/2018.
 * Description: 
 * Test: CaseFactoryTest
 */


public without sharing class CaseFactory {
    public RecordType customerCare;
    public RecordType productSupport;
    public OrgWideEmailAddress customerCareEmail;
    public Group CustomerCareQueueID;
    public Group ProductQueueID;
    public Case newCase;

    public caseFactory() {
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

        customerCareEmail = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = 'customercare@bluewavesolar.com'
            LIMIT 1
        ];

        List<Group> assignmentGroups = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND (DeveloperName = 'Product_Support' OR DeveloperName = 'Customer_Care')
            ORDER BY DeveloperName
        ];

        if (assignmentGroups.size() != 2) {
            Logger.logNow('CaseFactory', 'constructor', 'Missing Groups for assignment. Available Groups: ' + assignmentGroups);
        } else {
            CustomerCareQueueID = assignmentGroups[0];
            ProductQueueID = assignmentGroups[1];
        }
    }

    public Case getCase(String type) {
        newCase = new Case();
        if (type == 'Product_Support') {
            newCase.RecordTypeId = productSupport.Id;
            newCase.RecordType = productSupport;
            newCase.OwnerId = ProductQueueID.Id;
        } else if (type == 'Customer_Care') {
            newCase.RecordTypeId = customerCare.Id;
            newCase.RecordType = customerCare;
            newCase.OwnerId = CustomerCareQueueID.Id;
        }
        return newCase;
    }
}