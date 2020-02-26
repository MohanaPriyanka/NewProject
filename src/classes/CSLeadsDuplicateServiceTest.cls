/**
 * Created by SarahRenfro on 2/24/2020.
 */

@IsTest
private class CSLeadsDuplicateServiceTest {
    private static CSLeadsDuplicateService service = new CSLeadsDuplicateService();

    public static void useMocks() {
        Util.mockDML = true;
        service.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new MockLeadSelector());
    }

    @IsTest
    static void testCreateOrderedDuplicateLeadList() {
        useMocks();
        Map<Id, Lead> duplicateMap = new Map<Id, Lead>();
        duplicateMap.put('001000000000111EEA', new Lead());
        duplicateMap.put('001000000000222EEA', new Lead());

        Lead newLead = new Lead(Id = Util.getFakeId(Schema.Lead.SObjectType));
        List<Lead> orderedLeads = service.createOrderedDuplicateLeadList(duplicateMap, newLead);

        System.assertEquals(2, orderedLeads.size());
        System.assertNotEquals(null, service.masterLead);
        System.assertEquals('001000000000111EEA', service.masterLead.Id);
        System.assertEquals(newLead.Id, orderedLeads[0].Id);
    }

    @IsTest
    static void testMoreThanTwoDuplicates() {
        useMocks();
        Map<Id, Lead> duplicateMap = new Map<Id, Lead>();
        duplicateMap.put('001000000000111EEA', new Lead());
        duplicateMap.put('001000000000222EEA', new Lead());
        duplicateMap.put('001000000000333EEA', new Lead());
        duplicateMap.put('001000000000444EEA', new Lead());

        Lead newLead = new Lead(Id = Util.getFakeId(Schema.Lead.SObjectType));
        List<Lead> orderedLeads = service.createOrderedDuplicateLeadList(duplicateMap, newLead);

        System.assertEquals(2, orderedLeads.size());
        System.assertNotEquals(null, service.masterLead);
        System.assertEquals('001000000000111EEA', service.masterLead.Id);
        System.assertEquals(newLead.Id, orderedLeads[0].Id);

        Error_Log__c logError = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertNotEquals(null, logError);
        System.assert(logError.Message__c.contains('more than 2 matching Leads'), 'Error Message must be logged when more than 2 duplicates');
    }


    /********************
    *** SYSTEM TESTS ***
    ********************/

    @IsTest
    static void testCheckLeadDuplicates() {

        Lead masterLead = new Lead(
            FirstName = 'Duplicate',
            LastName = 'Testcase',
            Email = 'email@test.com',
            Company = 'Duplicate Testcase',
            LeadSource = 'Website',
            CreatedDate = System.today().addDays(-2)
        );
        insert masterLead;

        Partner__c partner1 = new Partner__c (
            Name = 'BlueWave Test Partner',
            Email__c = 'bwtest@email.com'
        );
        insert partner1;

        //TODO: do i need to build out an entire switch lead?
        Lead newLead = new Lead(
            FirstName = 'Duplicate',
            LastName = 'Testcase',
            Email = 'email@test.com',
            Company = 'Duplicate Testcase',
            LeadSource = 'Switch',
            MobilePhone = '555-555-5555',
            Partner_Lookup__c = partner1.Id
        );

        insert newLead;


        Account propertyAccount = new Account(
            Name = 'Property Testcase',
            Lead__c = newLead.Id
        );

        insert propertyAccount;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = newLead.Id,
            Account__c = propertyAccount.Id,
            Name = '12345'
        );
        insert ual;

        Lead checkMasterLead = service.checkLeadDuplicates(newLead);
        masterLead = [
            SELECT Id, LeadSource, CreatedDate, Partner_Lookup__r.Id
            FROM Lead
            WHERE Id = :masterLead.Id
            LIMIT 1
        ];

        try {
            Lead checkNewLead = [SELECT Id FROM Lead WHERE Id = :newLead.Id LIMIT 1];
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'New Lead should no longer exist after merge');
        }

        propertyAccount = [
            SELECT Id, Lead__r.Id
            FROM Account
            WHERE Id = :propertyAccount.Id
            LIMIT 1
        ];

        ual = [
            SELECT Id, Lead__r.Id
            FROM Utility_Account_Log__c
            WHERE Id = :ual.Id
            LIMIT 1
        ];

        System.assertEquals(masterLead.Id, checkMasterLead.Id);
        System.assertEquals('Switch', masterLead.LeadSource);
        System.assertEquals(System.today().addDays(-2), masterLead.CreatedDate);
        System.assertEquals(masterLead.Id, ual.Lead__r.Id);
        System.assertEquals(masterLead.Id, propertyAccount.Lead__r.Id);
        System.assertEquals(partner1.Id, masterLead.Partner_Lookup__r.Id);
    }


    /*************
     *** MOCKS ***
     *************/


    private class MockLeadSelector extends MockProvider {

        public MockLeadSelector(){
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String masterJSON = '{"attributes":{"type":"Lead","url":"/services/data/v47.0/sobjects/Lead/001000000000111EEA"},' +
                '"Id": "001000000000111EEA",' +
                '"FirstName": "Duplicate",' +
                '"LastName": "Testcase",' +
                '"Email": "email@test.com",' +
                '"LeadSource": "Website"' +
                '}';

            String jsonLead = '{"attributes":{"type":"Lead","url":"/services/data/v47.0/sobjects/Lead/001000000000222EEA"},' +
                '"Id": "001000000000222EEA",' +
                '"FirstName": "Duplicate",' +
                '"LastName": "Testcase",' +
                '"Email": "email@test.com",' +
                '"LeadSource": "Website"' +
                '}';

            switch on methodCall.stubbedMethodName{
                when 'selectForMerge' {
                    Set<Id> dupeIds =  (Set<Id>) methodCall.listOfArgs[0];
                    List<Lead> duplicateList = new List<Lead>();
                    if(dupeIds != null) {
                        Lead masterLead = (Lead) JSON.deserialize(masterJSON, Lead.class);
                        duplicateList.add(masterLead);
                        for (Integer i = dupeIds.size()-1; i > 0; i--) {
                            Lead duplicate = (Lead) JSON.deserialize(jsonLead, Lead.class);
                            duplicateList.add(duplicate);
                        }
                    }

                    return duplicateList;
                }
            }
            return null;
        }
    }
}