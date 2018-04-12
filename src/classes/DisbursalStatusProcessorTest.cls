@isTest
public without sharing class DisbursalStatusProcessorTest {
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
        opportunityRecord.Disbursal_Type_Contract__c = 'ACH Disbursal';
        opportunityRecord.Disbursal_Type_Mech_Completion__c = 'ACH';
        opportunityRecord.Disbursal_Type_Interconnect__c = 'ACH Disbursal';
        opportunityRecord.Disbursal_1_Contract_Signature_Checkbox__c = myDate;
        opportunityRecord.FBO_Funded_Mech_Completion__c = true;
        opportunityRecord.FBO_Funded_System_Op__c = true;
        opportunityRecord.FBO_Funded_Contract_Signature__c = true;
        opportunityRecord.Manual_Hold_on_Disbursal__c = true;
        update opportunityRecord;
        opportunityRecord.Disbursal_2_Mechanical_Install_Checkbox__c = myDate;
        update opportunityRecord;
    }

    @isTest static void testDisbursalStatusProcessor() {
    	Id batchJobId = Database.executeBatch(new DisbursalStatusProcessor(), 200);
    }
}