@isTest
    private class MapLateCategoryTest {

    static testMethod void MapLateCategory() {
        Account newAccount = new Account(name = 'Testcase');
        insert newAccount;

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                    Total_Capital__c = 10000000,
                                                    Investor__c = 'The Bank',
                                                    Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Date myDate = Date.newInstance(2015, 2, 17);
        Date codDate = Date.newInstance(2015, 4, 17);
        Date codDateTwo = Date.newInstance(2015, 7, 17);

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(Name = 'Avidia 1',
                                                            Tranche_Cap__c = 1000000,
                                                            Tranche_Type__c = 'Standard',
                                                            State__c = 'MA',
                                                            Stage__c = 'Open',
                                                            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;  

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(Name = 'Tranche Assignment Pending',
                                                                 Tranche_Type__c = 'Holding',
                                                                 Stage__c = 'Closed',
                                                                 Loan_Data__c = capitalPool.id);
        insert loanTranchePending;                  

        Partner__c partner = new partner__c(name = 'Partner');
        insert partner;

        BSST__c newSalesId = new BSST__c (name = 'Cole Swain', partner__c = partner.id, custom_id__c = 'Cole 1');
        
        insert NewSalesId;  
             
        BSST__c salesIdQuery = [SELECT id FROM Bsst__c WHERE Name = 'Cole Swain'];

        Opportunity newOp = new Opportunity(name ='Cole Swain', email__c ='cswain@bluewave-capital.com', 
                                            commencement_date__c = myDate, account = newAccount, Loan_Principle__c = 25000, 
                                            stageName = 'new', type = 'New Business', closeDate = myDate, 
                                            loan_traunch__c = loanTranchePending.id ) ;

        insert newOp;

        MCEC_Report_Data__c newPipeLine = new MCEC_Report_Data__c(name = 'Test', opportunity__c = newOp.id);
        insert newPipeLine;

        Lead newLead = new Lead(FirstName = 'Cole',
                                LastName = 'Test',
                                Loan_Amount__c = 25000,
                                Company = 'Cole Swain',
                                Retired__c = true,
                                LASERCA__Social_Security_Number__c = '000000001',
                                Product_Line__c = 'Residential Loan',
                                LASERCA__Home_State__c = 'MA',
                                Requested_Loan_Amount__c = 25000,
                                Unfinished_Lead__c = true,
                                Custom_Id__c = 'test',
                                Loan_Term__c = 120,
                                Partner_Lookup__c = partner.Id,
                                //Personal_Credit_Report__c = creditReportRecord.Id,
                                Annual_Income_Currency__c = 150000,
                                Product__c = null,
                                Pre_Approval_Form__c = true,
                                Product_Program__c = 'BlueWave Solar Loan',
                                Automatic_Product_Assignment__c = true,
                                Status = 'Ready for Credit Check');
        insert newLead;
        newLead.Unfinished_Lead__c = false;
        update newLead;
        newLead.Status = 'Pending Information';
        update newLead;
        newLead.Status = 'Qualified';
        update newLead;

        Loan__c loanRecord = [SELECT Id, Name FROM Loan__c WHERE Name = 'Cole Test'];

        capitalPool.month__c = 'September';
        capitalPool.year__c = '2016';

        update capitalPool;

        update loanTrancheMA;

        update loanRecord;

        Loan_Payment__c loanRecordPayment = 
            new Loan_Payment__c(Unique_ID__c = 'abvksjfkjri2j', loan__c = loanRecord.id, 
                                payment_1__c = myDate, payment_number2__c = 1, year__c = '2015');

        test.startTest();

        insert loanRecordPayment;
 
        test.stopTest();
 
        Loan__c loanQuery = [SELECT late_category__c FROM Loan__c WHERE name = 'Cole Test'];
 
        System.assertEquals(null, loanQuery.late_category__c);
 
 
    }
}