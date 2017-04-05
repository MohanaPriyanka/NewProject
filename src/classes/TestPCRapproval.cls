@isTest
private class TestPCRapproval {
    static testMethod void TestPCRapproval() {
        List<Lead> insertleads = new List<Lead>();
        List<LASERCA__Personal_Credit_Report__c> insertpcrlist = new List<LASERCA__Personal_Credit_Report__c>();
        List<LASERCA__Trade_Accounts__c> inserttradeacct = new List<LASERCA__Trade_Accounts__c>();
        
        Product2 productVar = new Product2( name = 'BlueWave Solar Loan - MA',
                                            State__c = 'MA',
                                            Family = 'Solar Loan',
                                            IsActive = TRUE,
                                            ProductCode = 'x',
                                            Loan_Term__c = 120,
                                            Loan_Interest_Rate__c = .0599,
                                            Loan_Interest_Only_Period__c = 12,
                                            Loan_Base_Rate__c = .0625,
                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                            Loan_Financing_Fee_Terms__c ='Maximum (5%, $1,250)');
        insert productVar;                                      

        Lead lead = getLead(50000, 45000, productVar.Id, true, true);
        insertleads.add(lead);
        Lead leadA = getLead(20000, 65000, productVar.Id, false, true);
        insertleads.add(leadA);
        Lead leadAA = getLead(1000, 65000, productVar.Id, false, false);
        insertleads.add(leadAA);
        Lead leadAB = getLead(14000, 15000, productVar.Id, true, false);
        insertleads.add(leadAB);
        Lead leadAC = getLead(14000, 46000, productVar.Id, true, false);
        insertleads.add(leadAC);
        Lead leadAD = getLead(90000, 20000, productVar.Id, false, true);
        insertleads.add(leadAD);
        insert insertleads;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Code_2__c = '034',
                                                                                        LASERCA__Code__c = '039',
                                                                                        LASERCA__Code_3__c = '040',
                                                                                        LASERCA__Code_4__c = '022',
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700',
                                                                                        Avidia_Review_Status__c = 'Reviewed - PreApproved');
        insertpcrlist.add(pcr);
        LASERCA__Personal_Credit_Report__c pcrA = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadA.Id,
                                                                                         LASERCA__Credit_Score_TransUnion__c = '401');
        insertpcrlist.add(pcrA);
        LASERCA__Personal_Credit_Report__c pcrAA = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAA.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '402');
        insertpcrlist.add(pcrAA);
        LASERCA__Personal_Credit_Report__c pcrAB = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAB.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '800');
        insertpcrlist.add(pcrAB);
        LASERCA__Personal_Credit_Report__c pcrAC = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAC.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '701');
        insertpcrlist.add(pcrAC);
        LASERCA__Personal_Credit_Report__c pcrAD = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAD.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '801');
        insertpcrlist.add(pcrAD);
        insert insertpcrlist;
                                                                                        
        LASERCA__Trade_Accounts__c  tradeacctA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrA.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
        inserttradeacct.add(tradeacctA);  
        LASERCA__Trade_Accounts__c  tradeacctAA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAA.id,
                                                                                 LASERCA__Monthly_Payment__c = 500);
        inserttradeacct.add(tradeacctAA);  
        LASERCA__Trade_Accounts__c  tradeacct = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                                                               LASERCA__Monthly_Payment__c = 500);
        inserttradeacct.add(tradeacct);  
        LASERCA__Trade_Accounts__c  tradeacctAB = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAB.id,
                                                                                 LASERCA__Monthly_Payment__c = 500);
        inserttradeacct.add(tradeacctAB);  
        LASERCA__Trade_Accounts__c  tradeacctAC = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAC.id,
                                                                                 LASERCA__Monthly_Payment__c = 1000);
        inserttradeacct.add(tradeacctAC); 
        LASERCA__Trade_Accounts__c  tradeacctAD = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAD.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAD); 
        insert inserttradeacct;
        update inserttradeacct;

        pcrAB.Solar_Loan_Manual_Decline__c = True;
        update pcrAB;

        pcrAA.Solar_Loan_Manual_Approval__c = True;
        update pcrAA;

        Test.startTest();

        List<LASERCA__Personal_Credit_Report__c> pcrlist = 
            [SELECT Id, Solar_Loan_Approval_Status__c, Solar_Loan_Pre_Qualification_Status__c, 
             LASERCA__Credit_Score_TransUnion__c, DTI__c
             FROM LASERCA__Personal_Credit_Report__c];

        for (LASERCA__Personal_Credit_Report__c creditreport : pcrlist) {
            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '700') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Pending Review');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Pre-Qualified');
            }

            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '401') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Declined');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Unable to Pre-Qualify');
            }

            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '402') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Approved');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Pre-Qualified');
            }

            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '800') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Declined');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Unable to Pre-Qualify');
            }

            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '701') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Declined');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Unable to Pre-Qualify');
            }
            
            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '801') {
                System.assertEquals(creditreport.Solar_Loan_Approval_Status__c, 'Approved');
                System.assertEquals(creditreport.Solar_Loan_Pre_Qualification_Status__c, 'Pre-Qualified');
            }
        }

        Test.stopTest();
    }

    private static Lead getLead(Integer annualIncome, Integer loanAmount, Id productId, Boolean doerLoan, Boolean preApproval) {
        return(new Lead(LastName = 'Chan',
                        FirstName = 'Joey',
                        Automatic_Product_Assignment__c = false,
                        Email = 'test@email.com',
                        Company = 'Cloud Jedi',
                        Status = 'Ready for Credit Check',
                        Annual_Income_Currency__c = annualIncome,
                        Loan_Amount__c = loanAmount,
                        Product__c = productId,
                        DOER_Solar_Loan__c = doerLoan,
                        Pre_Approval_Form__c = preApproval));
    }
}