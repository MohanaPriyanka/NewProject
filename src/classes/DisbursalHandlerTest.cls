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
                                    Custom_Id__c = 'test',
                                    Loan_Term__c = 120,
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
        opportunityRecord.BlueWave_Signature_Status__c = 'Completed';
		update opportunityRecord;        
    }

    @isTest static void testCreateDisbursalsFromOpportunity() {
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
    }

    @isTest static void testUpdateDisbursalsOnOpportunityUpdate() {
        Date myDate = Date.newInstance(2018, 2, 17);
        Test.startTest();
	        Opportunity opportunityRecord = [SELECT Id, Name, 
	        									(SELECT Id, Name FROM Loans__r)
	        								 FROM Opportunity];
	        opportunityRecord.Disbursal_1_Contract_Signature_Checkbox__c = myDate;
	        opportunityRecord.Disbursal_Type_Contract__c = 'ACH Disbursal';

	        opportunityRecord.Disbursal_2_Mechanical_Install_Checkbox__c = myDate;
            opportunityRecord.Disbursal_Type_Mech_Completion__c = 'ACH';
            update opportunityRecord;            

	        opportunityRecord.Disbursal_3_Full_Install_Checkbox__c = myDate;
	        opportunityRecord.Disbursal_Type_Interconnect__c = 'ACH Disbursal';
	        update opportunityRecord;

	        List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Date_of_Disbursal__c, Disbursal_Method__c 
	        									   FROM Disbursal__c 
	        									   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id];

	        System.assertEquals(3, disbursalRecords.size());
	        for (Disbursal__c disbursal : disbursalRecords) {
	        	System.assertEquals(myDate, disbursal.Date_of_Disbursal__c);
	        	System.assertEquals('ACH', disbursal.Disbursal_Method__c);
	        }
        Test.stopTest();                
    }    

    @isTest static void testUpdateDisbursalAmountsOnRLAChange() {
        Date myDate = Date.newInstance(2018, 2, 17);
        Decimal totalAmount = 0;
        Test.startTest();
	        Opportunity opportunityRecord = [SELECT Id, Name, 
	        									(SELECT Id, Name FROM Loans__r)
	        								 FROM Opportunity];

	        opportunityRecord.Disbursal_1_Contract_Signature_Checkbox__c = myDate;
	        opportunityRecord.Disbursal_Type_Contract__c = 'ACH Disbursal';
            opportunityRecord.StageName = 'New';
	        update opportunityRecord;

	        opportunityRecord.Loans__r.get(0).Requested_Loan_Amount__c = 28000;
	        update opportunityRecord.Loans__r.get(0);

	        List<Disbursal__c> disbursalRecords = [SELECT Id, Name, Disbursal_Percentage__c, Amount__c, Status__c, Date_of_Disbursal__c, Disbursal_Method__c 
	        									   FROM Disbursal__c 
	        									   WHERE Loan__r.Id = : opportunityRecord.Loans__r.get(0).Id
	        									   ORDER BY Disbursal_Sequence__c];

	        for (Disbursal__c disbursal : disbursalRecords) {
	        	totalAmount = totalAmount + disbursal.Amount__c;
	        }

	        System.assertEquals('Complete', disbursalRecords.get(0).Status__c);
	        System.assertEquals(9000, disbursalRecords.get(0).Amount__c);
	        System.assertEquals(16200, disbursalRecords.get(1).Amount__c);
	        System.assertEquals(2800, disbursalRecords.get(2).Amount__c);
	        System.assertEquals(28000, totalAmount);
	        Test.stopTest();                
    }        
}