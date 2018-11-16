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

        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp.Lender_of_Record__c = 'Avidia';
        mslp.Program__c = 'MSLP';
        insert mslp;

        List<Lead> leads = new List<Lead>();
        //Name is exceptionally long to test Disbursal naming validations
        Lead leadRecord = new Lead(
            FirstName = 'Constantineousinson',
            LastName = 'Stephanopolousenbergson Senior',
            Loan_Amount__c = 30000,
            Company = 'Long Name',
            LASERCA__Social_Security_Number__c = '000000001',
            Product_line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 30000,
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productRecord.Id,
            Product_Program__c = 'BlueWave Solar Loan',
            Status = 'Qualified');
        leads.add(leadRecord);
        Lead doerLead = new Lead(
            FirstName = 'DOER',
            LastName = 'Test',
            Loan_Amount__c = 30000,
            Company = 'DOER Test',
            LASERCA__Social_Security_Number__c = '000000001',
            Product_line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 30000,
            DOER_Solar_Loan__c = true,
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = mslp.Id,
            Product_Program__c = 'MSLP',
            Status = 'Qualified');
        leads.add(doerLead);
        insert leads;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadRecord.Id);
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        Database.LeadConvert doerConvert = new Database.LeadConvert();
        doerConvert.setLeadId(doerLead.Id);
        doerConvert.setConvertedStatus('Qualified');
        Database.convertLead(doerConvert);

        // Need to re-query leads to get ConvertedOpportunityId in the subsequent calls
        leads = [
            SELECT Id, FirstName, LastName, Loan_Amount__c, Company, LASERCA__Social_Security_Number__c, Product_line__c,
                LASERCA__Home_State__c, Requested_Loan_Amount__c, Unfinished_Lead__c, Partner_Lookup__c, bs_Sales_ID__c,
                Annual_Income_Currency__c, Product__c, Product_Program__c, Status, DOER_Solar_Loan__c, Loan_System_Information__c,
                Product__r.Loan_Interest_Rate__c, Loan_Financing_Fee__c, System_Cost__c, Loan_Fee_1__c,
                Product__r.Loan_Interest_Only_Period__c, ConvertedOpportunityId, ConvertedContactId
            FROM Lead
        ];

        LoanHandler.createResidentialEquipment(leads);
        LoanHandler.createLoan(leads);

        List<Opportunity> opps = [
            SELECT Id, Name,
            (SELECT Id, Name FROM Loans__r)
            FROM Opportunity
        ];
        for (Opportunity opp : opps) {
            opp.Contract_Status__c = 'Completed';
            opp.StageName = 'Complete';
        }
        update opps;
    }

    @isTest static void testCreateDisbursalsFromOpportunity() {
        Test.startTest();
            Decimal totalAmount = 0;
            Decimal totalPercentage = 0;
            Opportunity opportunityRecord = [
                SELECT Id, Name,
                (SELECT Id, Name FROM Loans__r)
                FROM Opportunity
                WHERE DOER_Solar_Loan__c = FALSE
            ];

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ];

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
        Decimal totalAmount = 0;
        Test.startTest();
            Opportunity opportunityRecord = [
                SELECT Id, Name,
                (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
                FROM Opportunity
                WHERE DOER_Solar_Loan__c = FALSE
            ];
            opportunityRecord.StageName = 'New';
            update opportunityRecord;

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                ORDER BY Disbursal_Sequence__c
            ];
        // update first disbursal to be disbursed
            disbursalRecords.get(0).Status__c = 'Disbursed';
            Decimal originalDisbursalAmount = disbursalRecords.get(0).Amount__c;
            update disbursalRecords;

            LoanHandler.resetTriggerContext();
            opportunityRecord.Loans__r.get(0).Requested_Loan_Amount__c = 28000;
        // update loan
            update opportunityRecord.Loans__r.get(0);


            List<Disbursal__c> updatedDisbursals = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                ORDER BY Disbursal_Sequence__c
            ];
            for (Disbursal__c disbursal : updatedDisbursals) {
                totalAmount = totalAmount + disbursal.Amount__c;
            }
            System.assertEquals(originalDisbursalAmount, updatedDisbursals.get(0).Amount__c);
            System.assertEquals(16200, updatedDisbursals.get(1).Amount__c);
            System.assertEquals(2800, updatedDisbursals.get(2).Amount__c);
            System.assertEquals(28000, totalAmount);
        Test.stopTest();
    }

    @isTest static void testUpdateDisbursalAmountsWithRLAChangeAfterContractSignature() {
        Decimal totalAmount = 0;
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name,
            (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = FALSE
        ];
        opportunityRecord.StageName = 'New';
        update opportunityRecord;

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

         // update first disbursal to be disbursed
        disbursalRecords.get(0).Status__c = 'Disbursed';
        Decimal originalDisbursalAmount = disbursalRecords.get(0).Amount__c;
        update disbursalRecords;

        LoanHandler.resetTriggerContext();
        opportunityRecord.Loans__r.get(0).Requested_Loan_Amount__c = 35000;
        // update loan
        update opportunityRecord.Loans__r.get(0);

        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;

        List<Disbursal__c> updatedDisbursals = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];
        for (Disbursal__c disbursal : updatedDisbursals) {
            totalAmount = totalAmount + disbursal.Amount__c;
        }

        System.assertEquals(originalDisbursalAmount, updatedDisbursals.get(0).Amount__c);
        System.assertEquals(22500, updatedDisbursals.get(1).Amount__c);
        System.assertEquals(3500, updatedDisbursals.get(2).Amount__c);
        System.assertEquals(35000, totalAmount);
        Test.stopTest();
    }

    @isTest static void testOppStageCompleteContractDisbursalReady() {
        Test.startTest();
            Opportunity opportunityRecord = [
                SELECT Id, Name,
                (SELECT Id, Name FROM Loans__r)
                FROM Opportunity
                WHERE DOER_Solar_Loan__c = FALSE
            ];

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecords.get(0).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testOppStageReversionFromCompleteContractDisbursalPending() {
        Test.startTest();
            Opportunity opportunityRecord = [
                SELECT Id, Name,
                (SELECT Id, Name FROM Loans__r)
                FROM Opportunity
                WHERE DOER_Solar_Loan__c = FALSE
            ];
            opportunityRecord.StageName = 'New';
            update opportunityRecord;

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecords.get(0).Status__c, 'Pending');
        Test.stopTest();
    }

    @isTest static void testEquipmentMechInstallDisbursalReady() {
        Test.startTest();
            Residential_Equipment__c equipment = [
                SELECT Id, Mechanically_Installed__c, Interconnected__c, Loan__r.Id
                FROM Residential_Equipment__c
                WHERE Opportunity__r.DOER_Solar_Loan__c = FALSE
                LIMIT 1]
            ;
            equipment.Mechanically_Installed__c = true;
            update equipment;

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Status__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : equipment.Loan__r.Id
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecords.get(1).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testEquipmentInterconnectDisbursalReady() {
        Test.startTest();
            Residential_Equipment__c equipment = [
                SELECT Id, Mechanically_Installed__c, Interconnected__c, Loan__r.Id
                FROM Residential_Equipment__c
                WHERE Opportunity__r.DOER_Solar_Loan__c = FALSE
                LIMIT 1
            ];
            equipment.Interconnected__c = true;
            update equipment;

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Status__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : equipment.Loan__r.Id
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecords.get(2).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testFBOFundedActions() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Status__c, Funds_in_FBO_Account__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c
            ];
            disbursalRecords.get(0).Funds_in_FBO_Account__c = true;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [
                SELECT Id, Status__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c]
            ;
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Ready for Disbursement');
        Test.stopTest();
    }

    @isTest static void testDisbursalToHold() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Status__c, Hold_on_Disbursal__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c
            ];
            disbursalRecords.get(0).Hold_on_Disbursal__c = true;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [
                SELECT Id, Status__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Hold');
        Test.stopTest();
    }

    @isTest static void testDisbursalNoHold() {
        Test.startTest();
            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Status__c, Hold_on_Disbursal__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c
            ];
            disbursalRecords.get(0).Hold_on_Disbursal__c = false;
            update disbursalRecords.get(0);

            List<Disbursal__c> disbursalRecordsAfterUpdate = [
                SELECT Id, Status__c
                FROM Disbursal__c
                WHERE Loan__r.Opportunity__r.DOER_Solar_Loan__c = FALSE
                ORDER BY Disbursal_Sequence__c
            ];
            System.assertEquals(disbursalRecordsAfterUpdate.get(0).Status__c, 'Due');
        Test.stopTest();
    }

    @isTest static void testNYBuildingPermitDisbursalReady() {
        Test.startTest();
            List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
            Partner_Task__c permitTask = new Partner_Task__c();
            Id nyProductId = [SELECT Id FROM Product2 WHERE State__c = 'NY' LIMIT 1].Id;
            delete [SELECT Id, Status__c FROM Disbursal__c ORDER BY Disbursal_Sequence__c];
            Opportunity opportunityRecord = [
                SELECT Id, Name, Lead_Id__c,
                (SELECT Id, Name, Product__c FROM Loans__r)
                FROM Opportunity
                WHERE DOER_Solar_Loan__c = FALSE
            ];
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
            SELECT Id, Name,
            (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = FALSE
        ];

        Id loanId = opportunityRecord.Loans__r.get(0).Id;

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : disbursalRecords) {
            disbursal.Status__c = 'Disbursed';
        }

        update disbursalRecords;

        List<Disbursal__c> updatedDisbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : updatedDisbursalRecords) {
            System.assertEquals('Disbursed', disbursal.Status__c);
        }

        // Make sure disbursed loans statuses do not change when updating opportunity status from 'Complete'
        opportunityRecord.StageName = 'New';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
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
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];
        for (Disbursal__c disbursal : postOppDisbursals2) {
            System.assertEquals('Disbursed', disbursal.Status__c);
        }

        Test.stopTest();
    }

    @isTest static void testOppStageReversionFromCompleteWithDisbursalStatusReimbursed() {
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name, (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = FALSE
        ];

        Id loanId = opportunityRecord.Loans__r.get(0).Id;

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : disbursalRecords) {
            disbursal.Status__c = 'Reimbursed';
        }

        update disbursalRecords;

        List<Disbursal__c> updatedDisbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : updatedDisbursalRecords) {
            System.assertEquals('Reimbursed', disbursal.Status__c);
        }

        // Make sure reimbursed loans statuses do not change when updating opportunity status from 'Complete'
        opportunityRecord.StageName = 'Contract Pending';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];


        for (Disbursal__c disbursal : postOppDisbursals) {
            System.assertEquals('Reimbursed', disbursal.Status__c);
        }

        // Make sure reimbursed loan statuses do not change (if disbursed) when updating opportunity status to 'Complete'
        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals2 = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];
        for (Disbursal__c disbursal : postOppDisbursals2) {
            System.assertEquals('Reimbursed', disbursal.Status__c);
        }

        Test.stopTest();
    }

    @isTest static void testOppStageReversionFromCompleteWithDisbursalStatusOnHold() {
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name, (SELECT Id, Name, Requested_Loan_Amount__c FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = FALSE
        ];

        Id loanId = opportunityRecord.Loans__r.get(0).Id;

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : disbursalRecords) {
            disbursal.Status__c = 'Hold';
        }

        update disbursalRecords;

        List<Disbursal__c> updatedDisbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        for (Disbursal__c disbursal : updatedDisbursalRecords) {
            System.assertEquals('Hold', disbursal.Status__c);
        }

        // Make sure on hold loans statuses do not change when updating opportunity status from 'Complete'
        opportunityRecord.StageName = 'New';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];

        Set<Decimal> disbursalAmounts = new Set<Decimal>();

        for (Disbursal__c disbursal : postOppDisbursals) {
            disbursalAmounts.add(disbursal.Amount__c);
            System.assertEquals('Hold', disbursal.Status__c);
        }

        opportunityRecord.Loans__r.get(0).Requested_Loan_Amount__c += 1000;
        update opportunityRecord.Loans__r.get(0);

        // Make sure on hold loan statuses do not change (if disbursed) when updating opportunity status to 'Complete'
        // on hold loan statuses are allowed to update amount if loan amount changes
        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;

        List<Disbursal__c> postOppDisbursals2 = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : loanId
            ORDER BY Disbursal_Sequence__c
        ];
        for (Disbursal__c disbursal : postOppDisbursals2) {
            System.assertEquals(false, disbursalAmounts.contains(disbursal.Amount__c));
            System.assertEquals('Hold', disbursal.Status__c);
        }

        Test.stopTest();
    }

    @IsTest
    static void testDOERFirstPaymentDueDate() {
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name, (SELECT Id, Name FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = TRUE
        ];
        opportunityRecord.Contract_Status__c = 'Completed';
        opportunityRecord.StageName = 'Complete';
        update opportunityRecord;

        Date disbursalDate = Date.newInstance(2018, 7, 30);
        Loan__c loan = [
            SELECT Id, First_Payment_Due_Date_Override__c, (SELECT Id, Type__c, Status__c, Date_of_Disbursal__c FROM Disbursals__r)
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = TRUE
        ];
        System.assertEquals(null, loan.First_Payment_Due_Date_Override__c);
        System.assertEquals(2, loan.Disbursals__r.size());

        for (Disbursal__c disbursal : loan.Disbursals__r) {
            if (disbursal.Type__c == 'Contract Signature') {
                disbursal.Date_of_Disbursal__c = disbursalDate;
            }
        }
        update loan.Disbursals__r;
        loan = [
            SELECT Id, First_Payment_Due_Date_Override__c, (SELECT Id, Type__c, Status__c, Date_of_Disbursal__c FROM Disbursals__r)
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = TRUE
        ];
        System.assertEquals(Date.newInstance(2018, 9, 1), loan.First_Payment_Due_Date_Override__c);
        for (Disbursal__c disbursal : loan.Disbursals__r) {
            if (disbursal.Type__c == 'Contract Signature') {
                disbursal.Date_of_Disbursal__c = Date.newInstance(2018, 9, 1);
            } else if (disbursal.Type__c == 'Interconnection') {
                disbursal.Date_of_Disbursal__c = Date.newInstance(2018, 10, 1);
            }
        }
        update loan.Disbursals__r;
        loan = [
            SELECT Id, First_Payment_Due_Date_Override__c, (SELECT Id, Status__c, Date_of_Disbursal__c FROM Disbursals__r)
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = TRUE
        ];
        System.assertEquals(Date.newInstance(2018, 10, 1), loan.First_Payment_Due_Date_Override__c);
    }

    @IsTest
    static void testNonDOERFPDD() {
        Test.startTest();
        Loan__c loan = [
            SELECT Id, First_Payment_Due_Date_Override__c
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = FALSE
        ];

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Type__c
            FROM Disbursal__c
            WHERE Loan__r.Id =: loan.Id
            ORDER BY Disbursal_Sequence__c
        ];

        Date disbursalDate = Date.newInstance(2018,1,1);
        System.assertEquals(null, loan.First_Payment_Due_Date_Override__c);
        System.assertEquals(3, disbursalRecords.size());
        for (Disbursal__c disbursal : disbursalRecords) {
            if (disbursal.Type__c == 'Contract Signature') {
                disbursal.Date_of_Disbursal__c = disbursalDate;
            }
        }
        update disbursalRecords;
        loan = [
            SELECT Id, First_Payment_Due_Date_Override__c, (SELECT Id, Status__c, Date_of_Disbursal__c FROM Disbursals__r)
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = FALSE
        ];
        System.assertEquals(null, loan.First_Payment_Due_Date_Override__c);

        for (Disbursal__c disbursal : disbursalRecords) {
            if (disbursal.Type__c == 'Interconnection') {
                disbursal.Date_of_Disbursal__c = disbursalDate;
            }
        }
        update disbursalRecords;
        loan = [
            SELECT Id, First_Payment_Due_Date_Override__c, (SELECT Id, Status__c, Date_of_Disbursal__c FROM Disbursals__r)
            FROM Loan__c
            WHERE DOER_Solar_Loann__c = FALSE
        ];
        System.assertEquals(Date.newInstance(2018,2,1), loan.First_Payment_Due_Date_Override__c);
    }

    @isTest static void testDisbursalNameCreation() {
        Test.startTest();
        Opportunity opportunityRecord = [
            SELECT Id, Name,
            (SELECT Id, Name FROM Loans__r)
            FROM Opportunity
            WHERE DOER_Solar_Loan__c = FALSE
        ];

        List<Disbursal__c> disbursalRecords = [
            SELECT Id, Name, Disbursal_Percentage__c, Amount__c
            FROM Disbursal__c
            WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ORDER BY Disbursal_Sequence__c
        ];

        // if the Disbursal name is over 80 characters, it creates it from the first 80.
        //  In this case it cuts off a portion of the partner name (Bluewave Inside Sales).
        System.assertEquals(3, disbursalRecords.size());
        System.assertEquals('D1 - 30% - Constantineousinson Stephanopolousenbergson Senior - Bluewave Inside', disbursalRecords[0].Name);
        System.assertEquals('D2 - 60% - Constantineousinson Stephanopolousenbergson Senior - Bluewave Inside', disbursalRecords[1].Name);
        System.assertEquals('D3 - 10% - Constantineousinson Stephanopolousenbergson Senior - Bluewave Inside', disbursalRecords[2].Name);

        Test.stopTest();

    }
}