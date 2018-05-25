@isTest
public class DisbursalHandlerTest {
    @testSetup public static void setupTestData(){
        Partner__c partner = new Partner__c(Name = 'Bluewave Inside Sales');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        BSST__c salesRepExec = new BSST__c(Name = 'BlueWave Executive', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'executive@Sales.com');
        insert salesRepExec;

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                Total_Capital__c = 10000000,
                                                Investor__c = 'The Bank',
                                                Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Date myDate = Date.newInstance(2015, 2, 17);

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Product2 productRecord = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, 7, '750', '999', capitalPool.Id);
        insert productRecord;

        Product2 productRecordNY = LoanTestRecordWarehouse.getDefaultProduct('NY', 5.99, 10, 7, '750', '999', capitalPool.Id);
        productRecordNY.Disbursal_Terms__c = '30% Building Permit Approved, 60% Mechanical Installation, 10% Interconnection';
        productRecordNY.Lender_of_Record__c = 'Avidia';
        insert productRecordNY;

        Lead leadRecord = new lead(FirstName = 'Cole',
                                    LastName = 'Swain',
                                    Loan_Amount__c = 30000,
                                    Company = 'Cole Swain',
                                    Retired__c = false,
                                    Self_Employed__c = false,
                                    LASERCA__Social_Security_Number__c = '000000001',
                                    Product_Line__c = 'Residential Loan',
                                    LASERCA__Home_State__c = 'MA',
                                    Requested_Loan_Amount__c = 30000,
                                    DOER_Solar_Loan__c = false,
                                    Unfinished_Lead__c = true,
                                    Partner_Lookup__c = partner.Id,
                                    Bs_Sales_ID__c = salesRep.Id,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = productRecord.Id,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = false,
                                    Status = 'Ready for Credit Check');
        insert leadRecord;
        leadRecord.Status = 'Pending Information';
        update leadRecord;
        leadRecord.Status = 'Qualified';
        update leadRecord;

        Database.leadConvert lc = new Database.leadConvert();
        lc.setLeadId(leadRecord.id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel 
                                    FROM LeadStatus 
                                    WHERE IsConverted=true 
                                    LIMIT 1];

        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        Opportunity opportunityRecord = [SELECT Id, Name, 
                                            (SELECT Id, Name FROM Loans__r)
                                         FROM Opportunity];
        opportunityRecord.Contract_Status__c = 'Completed';
        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;
    }

    @isTest static void testCreateDisbursalsFromOpportunity() {
        Test.startTest();
            Decimal totalAmount = 0;
            Decimal totalPercentage = 0;
            Opportunity opportunityRecord = [SELECT Id, Name,
                                                (SELECT Id, Name FROM Loans__r)
                                             FROM Opportunity];

            List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c 
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id];

            System.assertEquals(3, disbursalRecords.size());
            for (Disbursal__c disbursal : disbursalRecords) {
                totalAmount = totalAmount + disbursal.Amount__c;
                totalPercentage = totalPercentage + disbursal.Disbursal_Percentage__c;
            }
            System.assertEquals(30000, totalAmount);
            System.assertEquals(100, totalPercentage);
        Test.stopTest();
    }

    @isTest static void testUpdateDisbursalAmountsOnRLAChange() {
        Date myDate = Date.newInstance(2018, 2, 17);
        Decimal totalAmount = 0;
        Test.startTest();
            Opportunity opportunityRecord = [SELECT Id, Name,
                                                (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
                                             FROM Opportunity];
            opportunityRecord.StageName = 'New';
            update opportunityRecord;

            List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c 
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                                                   ORDER BY Disbursal_Sequence__c];
        // update first disbursal to be disbursed
            disbursalRecords.get(0).Status__c = 'Disbursed';
            Decimal originalDisbursalAmount = disbursalRecords.get(0).Amount__c;
            update disbursalRecords;

            opportunityRecord.Loans__r.get(0).Requested_Loan_Amount__c = 28000;
        // update loan
            update opportunityRecord.Loans__r.get(0);


            List<Disbursal__c> updatedDisbursals = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c 
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                                                   ORDER BY Disbursal_Sequence__c];
            for (Disbursal__c disbursal : updatedDisbursals) {
                totalAmount = totalAmount + disbursal.Amount__c;
            }
            System.assertEquals(originalDisbursalAmount, updatedDisbursals.get(0).Amount__c);
            System.assertEquals(16200, updatedDisbursals.get(1).Amount__c);
            System.assertEquals(2800, updatedDisbursals.get(2).Amount__c);
            System.assertEquals(28000, totalAmount);
        Test.stopTest();
    }

    @isTest static void testOppStageCompleteContractDisbursalReady() {
        Test.startTest();
            Opportunity opportunityRecord = [SELECT Id, Name,
                                                (SELECT Id, Name FROM Loans__r)
                                             FROM Opportunity];

            List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c 
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                                                   ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecords.get(0).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testOppStageReversionFromCompleteContractDisbursalPending() {
        Test.startTest();
            Opportunity opportunityRecord = [SELECT Id, Name,
                                                (SELECT Id, Name FROM Loans__r)
                                             FROM Opportunity];
            opportunityRecord.StageName = 'New';
            update opportunityRecord;

            List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c 
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                                                   ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecords.get(0).Status__c, 'Pending');
        Test.stopTest();
    }

    @isTest static void testEquipmentMechInstallDisbursalReady() {
        Test.startTest();
            Residential_Equipment__c equipment = [SELECT Id, Mechanically_Installed__c, Interconnected__c, Loan__r.Id 
                                                  FROM Residential_Equipment__c 
                                                  LIMIT 1];
            equipment.Mechanically_Installed__c = true;
            update equipment;

            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : equipment.Loan__r.Id
                                                   ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecords.get(1).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testEquipmentInterconnectDisbursalReady() {
        Test.startTest();
            Residential_Equipment__c equipment = [SELECT Id, Mechanically_Installed__c, Interconnected__c, Loan__r.Id 
                                                  FROM Residential_Equipment__c 
                                                  LIMIT 1];
            equipment.Interconnected__c = true;
            update equipment;

            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : equipment.Loan__r.Id
                                                   ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecords.get(2).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testFBOFundedActions() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c, Funds_in_FBO_Account__c
                                                   FROM Disbursal__c 
                                                   ORDER BY Disbursal_Sequence__c];
            disbursalRecords.get(0).Funds_in_FBO_Account__c = true;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [SELECT Id, Status__c
                                                              FROM Disbursal__c 
                                                              ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Ready for Disbursement');
        Test.stopTest();
    }

    @isTest static void testDisbursalToHold() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c, Hold_on_Disbursal__c
                                                   FROM Disbursal__c 
                                                   ORDER BY Disbursal_Sequence__c];
            disbursalRecords.get(0).Hold_on_Disbursal__c = true;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [SELECT Id, Status__c
                                                              FROM Disbursal__c 
                                                              ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Hold');
        Test.stopTest();
    }

    @isTest static void testDisbursalNoHold() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c, Hold_on_Disbursal__c
                                                   FROM Disbursal__c 
                                                   ORDER BY Disbursal_Sequence__c];
            disbursalRecords.get(0).Hold_on_Disbursal__c = false;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [SELECT Id, Status__c
                                                              FROM Disbursal__c 
                                                              ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testNYBuildingPermitDisbursalReady() {
        Test.startTest();
            List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
            Partner_Task__c permitTask = new Partner_Task__c();
            Id nyProductId = [SELECT Id FROM Product2 WHERE State__c = 'NY' LIMIT 1].Id;
            delete [SELECT Id, Status__c FROM Disbursal__c ORDER BY Disbursal_Sequence__c];
            Opportunity opportunityRecord = [SELECT Id, Name, Lead_Id__c,
                                                (SELECT Id, Name, Product__c FROM Loans__r)
                                             FROM Opportunity];
            opportunityRecord.StageName = 'New';
            opportunityRecord.Product__c = nyProductId;
            System.debug('ny opp test');
            update opportunityRecord;

            opportunityRecord.Loans__r.get(0).Product__c = nyProductId;
            opportunityRecord.Loans__r.get(0).State__c = 'NY';
            update opportunityRecord.Loans__r.get(0);

            opportunityRecord.StageName = 'Complete';
            update opportunityRecord;

            permitTask.Name = 'Building Permit';
            permitTask.Partner__c = [SELECT Id FROM Partner__c LIMIT 1].Id;
            insert permitTask;

            for (Partner_Task__c partnerTask : [SELECT Task_Sequence__c FROM Partner_Task__c WHERE Task_Sequence__c >= 7 ORDER BY Task_Sequence__c]) {
                partnerTask.Task_Sequence__c = partnerTask.Task_Sequence__c + 1;
                partnerTaskList.add(partnerTask);
                permitTask = partnerTask;
            }
            update partnerTaskList;

            String leadId = [SELECT Id FROM Lead LIMIT 1].Id;

            permitTask.Task_Type__c = 'Building Installation';
            permitTask.Task_Sequence__c = 7;
            permitTask.Unique_ID__c = leadId + ' ' + 'Building Permit';
            update permitTask;

            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            Residential_Equipment__c equipment = [SELECT Id, Mechanically_Installed__c, Labor_Performed__c, Materials_Supplied__c, Interconnected__c, Loan__r.Id 
                                                  FROM Residential_Equipment__c 
                                                  LIMIT 1];

            Attachment buildingPermitDoc = new Attachment();
            buildingPermitDoc.ParentId = equipment.Id;
            buildingPermitDoc.Description = 'Building Permit';
            buildingPermitDoc.Name =  String.valueOf('test.txt');
            buildingPermitDoc.Body = bodyBlob;
            insert buildingPermitDoc;

            equipment.Labor_Performed__c = 'Application for Building Permit';
            equipment.Materials_Supplied__c = 'Modules';
            update equipment;

            List<Disbursal__c> disbursalRecords = [SELECT Id, Status__c, Type__c
                                                   FROM Disbursal__c 
                                                   WHERE Loan__r.Id = : equipment.Loan__r.Id
                                                   ORDER BY Disbursal_Sequence__c];
            System.assertEquals(disbursalRecords.get(0).Type__c, 'Building Permit Approved');
            System.assertEquals(disbursalRecords.get(0).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testOppStageReversionFromCompleteWithDisbursalStatusDisbursed() {
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name, (SELECT Id, Name FROM Loans__r)
            FROM Opportunity
        ];

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : disbursalRecords) {
            disbursal.Status__c = 'Disbursed';
        }

        update disbursalRecords;

        List<Disbursal__c> updatedDisbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : updatedDisbursalRecords) {
            System.assertEquals('Disbursed', disbursal.Status__c);
        }

        // Make sure disbursed loans statuses do not change when updating opportunity status from 'Complete'
        opportunityRecord.StageName = 'Contract Pending';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : postOppDisbursals) {
            System.assertEquals('Disbursed', disbursal.Status__c);
        }

        // Make sure disbursed loan statuses do not change (if disbursed) when updating opportunity status to 'Complete'
        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals2 = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : postOppDisbursals2) {
            System.assertEquals('Disbursed', disbursal.Status__c);
        }

        Test.stopTest();
    }
}
