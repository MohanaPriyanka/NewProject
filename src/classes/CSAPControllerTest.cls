@isTest
public with sharing class CSAPControllerTest {
    @testSetup static void setupTestData(){
        LoanTestRecordWarehouse.partnerSetup();
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
    }

    @isTest static void testCSAPApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c LIMIT 1];

            Load_U__c everLZU = new Load_U__c (Name = '02052', 
                                               Load_zone__c = 'SEMA Eversource', 
                                               LZ__c = 'SEMA', 
                                               Town__c= 'Medfield');
        
        Lead lead = new Lead(FirstName = 'Tester',
                            LastName = 'Testcase',
                            Company = 'Test',
                            Email = 'test@tester.com',
                            LASERCA__Home_Address__c = '55 Boston St.',
                            LASERCA__Home_City__c = 'Boston',
                            LASERCA__Home_State__c = 'MA',
                            LASERCA__Home_Zip__c = '02052',
                            Parcel_Zip__c = '02052',
                            LASERCA__Social_Security_Number__c = '000000001',
                            Requested_Loan_Amount__c = 35000,
                            Annual_Income_Currency__c = 15000,
                            Partner_Lookup__c = partner.Id,
                            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
                            Status = 'Ready for Credit Check',
                            Utility_1__c = 'Eversource',
                            Electricity_Provider__c = 'Eversource');
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score__c = '200'
        );

        insert pcr;

        LASERCA__Credit_Report_Log__c crLog = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = lead.Id,
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crLog;


        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
                                                                    Service_Territory__c = 'NEMA',
                                                                    Open__c = true,
                                                                    Reserved_Capacity_kW_DC__c = '10',
                                                                    Capacity_Committed_kW_DC__c = 0,
                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                    System_Utility__c = 'Eversource',
                                                                    Credit_Score_Requirement__c = 300,
                                                                    Assignment_order__c = '1',
                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                    Assemblage_Count__c = 1,
                                                                    Sales_Partners__c = 'Bluewave Inside Sales',
                                                                    Maximum_Subscription_Assemblage__c = 25);
        insert sss1;


        Test.startTest();
        CSAPController.upsertCSAPRecords(lead, partner.Id, salesRep.Id);

        //Check upserted Lead, Contact and Account records
        System.assertEquals(lead.Id, CSAPController.getLead(lead.Id, lead.Email).Id);
        System.assert(CSAPController.getContact(lead.Id, lead.Email).Id != null);
        System.assert(CSAPController.getAccount(lead.Id, lead.Email).Id != null);

        System.assert(true, CSAPController.hasAvailableCapacity(lead.Id));

        //Try pulling credit report
        CSAPController.pullCreditStatus(lead);
        //Check not qualified since Credit Score is only 200
        System.assertEquals(CSAPController.checkLeadCreditIfQualified(lead.Id), 'Unqualified');

        //Check for qualified
        pcr.LASERCA__Credit_Score__c = '800';
        update pcr;
        System.assertEquals(CSAPController.checkLeadCreditIfQualified(lead.Id), 'Qualified');

        Test.stopTest();
    }

    @isTest static void creditCheckTimeout() {
        System.assertEquals(CSAPController.getCreditCheckTimeout(), 60000);
        System_Properties__c systemProperties = System_Properties__c.getall().values()[0];
        systemProperties.Credit_Check_Timeout__c = 30000;
        update systemProperties;
        System.assertEquals(CSAPController.getCreditCheckTimeout(), 30000);
    }
}
