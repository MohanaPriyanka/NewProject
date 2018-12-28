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
        customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        productSupport = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];

        customerCareEmail = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = 'customercare@bluewavesolar.com'
            LIMIT 1
        ];

        ProductQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];
        CustomerCareQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

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