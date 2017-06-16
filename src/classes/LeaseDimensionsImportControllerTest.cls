/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Tests LeaseDimensionsImportController and CSVReader
 *************************************************************************************/
@isTest
public with sharing class LeaseDimensionsImportControllerTest {
    @testSetup static void setupTestData() {
        System_Properties__c sysProp = new System_Properties__c(Name = 'System');
        insert sysProp;
        LoanServicerTest.setupTestData();

        Product2 ma10Yr = [SELECT Id, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c
                           FROM Product2
                           WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%' LIMIT 1];
        Loan_Traunch__c loanTraunch = [SELECT Id FROM Loan_Traunch__c WHERE Name = 'Tranche Assignment Pending' LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Testerson' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Testerson Loan' LIMIT 1];
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Partner' LIMIT 1];

        Loan__c loan = new Loan__c(Product__c = ma10Yr.Id,
                                   Lead__c = testLead.Id,
                                   Partner__c = partner.Id,
                                   Opportunity__c = opp.Id,
                                   Loan_Tranche__c = loanTraunch.Id,
                                   Requested_Loan_Amount__c = 40316.93,
                                   Financing_Fee__c = 2015.85,
                                   Commencement_Datee__c = Date.parse('1/1/2017'),
                                   First_Payment_Due_Date_Override__c = Date.parse('2/1/2017'));
        insert loan;
    }

    static testMethod void testFileLoad() {
        Loan__c loan = [SELECT Loan_Number__c,
                        (SELECT Id, Period__c, Payment_Due_Date2__c
                         FROM Loan_Payments__r
                         WHERE Period__c <> null
                         ORDER BY Period__c)
                        FROM Loan__c LIMIT 1];
        System.assertEquals(120, loan.Loan_Payments__r.size());
        
        testFile = testFile.replace('GOODLOANINIO', loan.Loan_Number__c.replace('BW','   '));
        testFile = testFile.replace('GOODLOANINPI', loan.Loan_Number__c + ' ');

        Test.startTest();
        LeaseDimensionsImportController ldic = new LeaseDimensionsImportController();
        TransactionApplicationHandler.batchSize = 20;
        ldic.document = new Document(name='foo',
                                     body = Blob.valueOf(testFile));
        ldic.processCSV();
        List<Transaction_Application__c> taList =
            [SELECT Id, Loan_Payment__c
             FROM Transaction_Application__c];
        System.assertEquals(3, taList.size());
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, logs.size());
        Test.stopTest();
    }

    public static string testFile = 
        'Portfolio,Company,Region,Office,Account #,Customer Name,Process Date,Payment Effective Date,Invoice Due Date,Transaction Description,Invoice Number,Check Number,Cash Code, Amount ,Reversal Reason,Comments\n' +
        '2,1,1,4,GOODLOANINIO,Daniel Prince,5/19/2017,5/27/2017,5/27/2017,IBL PMT - INTEREST,2866,5486,125, 131.74 ,,\n' +
        '2,1,2,1,GOODLOANINPI,Michael Woodcock and Lauren Woodcock,5/19/2017,6/6/2017,6/6/2017,IBL PMT - INTEREST,3033,A051817,125, 74.12 ,,\n' +
        '2,1,2,1,GOODLOANINPI,Michael Woodcock and Lauren Woodcock,5/19/2017,6/6/2017,6/6/2017,IBL PMT - PRINCIPAL,3033,A051817,125, 186.18 ,,\n' +
        '2,1,2,1,GOODLOANINPI,Michael Woodcock and Lauren Woodcock,5/19/2017,6/6/2015,6/6/2015,IBL PMT - PRINCIPAL,3033,A051817,125, 186.18 ,,\n' +
        '2,1,2,1,BW0099999,Kathryn Farrell and Donald Fail,5/19/2017,4/3/2017,,IBL PRN WRITE-DOWN,,BW IBLS PAYDOWN APR 17,130," (6,121.50)",UNDO,\n' +
        ',,,,,,,,,,,,,,,\n';        
}