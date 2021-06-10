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

            Map<ID, Opportunity> OppMap = new Map<ID, Opportunity>([SELECT Id, Name, StageName FROM Opportunity LIMIT 10]);
            
 
            DisbursalHandler disbursalHandler = new DisbursalHandler ();

            DisbursalHandler.createDisbursalsFromOpportunity(OppMap, OppMap);

            List<Disbursal__c> disbursalRecords = [
                SELECT Id, Name, Disbursal_Percentage__c, Amount__c
                FROM Disbursal__c
                WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
            ];

            System.assertEquals(0, disbursalRecords.size());
            for (Disbursal__c disbursal : disbursalRecords) {
                totalAmount = totalAmount + disbursal.Amount__c;
                totalPercentage = totalPercentage + disbursal.Disbursal_Percentage__c;
            }
            System.assertEquals(0, totalAmount);
            System.assertEquals(0, totalPercentage);
        Test.stopTest();
    }
   
}