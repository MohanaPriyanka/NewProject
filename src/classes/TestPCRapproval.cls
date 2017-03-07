@isTest
private class TestPCRapproval {

Static testMethod void TestPCRapproval(){

    List <Lead> insertleads = new List <Lead>();
    List <LASERCA__Personal_Credit_Report__c> insertpcrlist = new List <LASERCA__Personal_Credit_Report__c>();
    List <LASERCA__Trade_Accounts__c> inserttradeacct = new List <LASERCA__Trade_Accounts__c>();


        
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
                                               


        Lead lead = new Lead (LastName = 'Chan',
                                 FirstName = 'Joey',
                                 Automatic_Product_Assignment__c = false,
                                 Email = 'test@email.com',
                                 Company = 'Cloud Jedi',
                                 Status = 'Ready for Credit Check',
                                 Annual_Income_Currency__c = 50000,
                                 Loan_Amount__c = 45000,
                                 Product__c = productVar.Id,
                                 DOER_Solar_Loan__c = TRUE,
                                 Pre_Approval_Form__c = TRUE
                                 //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(lead);


                Lead leadA = new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Automatic_Product_Assignment__c = false,
                                                             Status = 'Ready for Credit Check',
                                                             Annual_Income_Currency__c = 20000,
                                                             Loan_Amount__c = 65000,
                                                             Product__c = productVar.Id,
                                                             DOER_Solar_Loan__c = FALSE,
                                                             Pre_Approval_Form__c = TRUE
                                                             //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(leadA);

                    Lead leadAA = new Lead (LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Automatic_Product_Assignment__c = false,
                                                             Status = 'Ready for Credit Check',
                                                             Annual_Income_Currency__c = 1000,
                                                             Loan_Amount__c = 65000,
                                                             Product__c = productVar.Id,
                                                             DOER_Solar_Loan__c = FALSE,
                                                             Pre_Approval_Form__c = FALSE
                                                             //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(leadAA);


                    Lead leadAB = new Lead (LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Automatic_Product_Assignment__c = false,
                                                             Status = 'Ready for Credit Check',
                                                             Annual_Income_Currency__c = 140000,
                                                             Loan_Amount__c = 15000,
                                                             Product__c = productVar.Id,
                                                             DOER_Solar_Loan__c = TRUE,
                                                             Pre_Approval_Form__c = FALSE
                                                             //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(leadAB);

                            Lead leadAC = new Lead (LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Automatic_Product_Assignment__c = false,
                                                             Status = 'Ready for Credit Check',
                                                             Annual_Income_Currency__c = 14000,
                                                             Loan_Amount__c = 46000,
                                                             Product__c = productVar.Id,
                                                             DOER_Solar_Loan__c = TRUE,
                                                             Pre_Approval_Form__c = FALSE
                                                             //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(leadAC);

                                    Lead leadAD = new Lead (LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Automatic_Product_Assignment__c = false,
                                                             Status = 'Ready for Credit Check',
                                                             Annual_Income_Currency__c = 90000,
                                                             Loan_Amount__c = 20000,
                                                             Product__c = productVar.Id,
                                                             DOER_Solar_Loan__c = FALSE,
                                                             Pre_Approval_Form__c = TRUE
                                                             //Custom_ID__c = 'BOS'
                                                             );
        insertleads.add(leadAD);

        insert insertleads;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Code_2__c = '034',
                                                                                        LASERCA__Code__c = '039',
                                                                                        LASERCA__Code_3__c = '040',
                                                                                        LASERCA__Code_4__c = '022',
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700',
                                                                                        Avidia_Review_Status__c = 'Reviewed - PreApproved'
                                                                                        );
        
        insertpcrlist.add(pcr);
                                                                                       

        LASERCA__Personal_Credit_Report__c pcrA = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadA.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '401');
        
        insertpcrlist.add(pcrA);

        LASERCA__Personal_Credit_Report__c pcrAA = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadAA.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '402');
        insertpcrlist.add(pcrAA);

        LASERCA__Personal_Credit_Report__c pcrAB = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadAB.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '800');
        insertpcrlist.add(pcrAB);

        LASERCA__Personal_Credit_Report__c pcrAC = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAC.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '701'
                                                                                        );
        
        insertpcrlist.add(pcrAC);

        LASERCA__Personal_Credit_Report__c pcrAD = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAD.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '801'
                                                                                        );
        
        insertpcrlist.add(pcrAD);


        insert insertpcrlist;


                                                                                        
        LASERCA__Trade_Accounts__c  tradeacctA = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrA.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        inserttradeacct.add(tradeacctA);  
                                                                                      
        LASERCA__Trade_Accounts__c  tradeacctAA = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrAA.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        inserttradeacct.add(tradeacctAA);  

        LASERCA__Trade_Accounts__c  tradeacct = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcr.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        inserttradeacct.add(tradeacct);  

        LASERCA__Trade_Accounts__c  tradeacctAB = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrAB.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        inserttradeacct.add(tradeacctAB);  

        LASERCA__Trade_Accounts__c  tradeacctAC = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrAC.id,
                                                                                   LASERCA__Monthly_Payment__c = 1000);         
        inserttradeacct.add(tradeacctAC); 

        LASERCA__Trade_Accounts__c  tradeacctAD = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrAD.id,
                                                                                   LASERCA__Monthly_Payment__c = 200);         
        inserttradeacct.add(tradeacctAD); 

        insert inserttradeacct;
        update inserttradeacct;

        pcrAB.Solar_Loan_Manual_Decline__c = True;
        update pcrAB;

        pcrAA.Solar_Loan_Manual_Approval__c = True;
        update pcrAA;

        test.startTest();


        List <LASERCA__Personal_Credit_Report__c> pcrlist = [ SELECT id, Solar_Loan_Approval_Status__c, Solar_Loan_Pre_Qualification_Status__c, LASERCA__Credit_Score_TransUnion__c
                                                            FROM LASERCA__Personal_Credit_Report__c];

        for(LASERCA__Personal_Credit_Report__c creditreport : pcrlist){
            system.debug(creditreport);

            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '700'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Pending Review');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Pre-Qualified');
            }

            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '401'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Declined');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Unable to Pre-Qualify');
            }

            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '402'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Approved');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Pre-Qualified');
            }

            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '800'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Declined');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Unable to Pre-Qualify');
            }

            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '701'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Declined');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Unable to Pre-Qualify');
            }
            
            if(creditreport.LASERCA__Credit_Score_TransUnion__c == '801'){
                system.assert(creditreport.Solar_Loan_Approval_Status__c == 'Approved');
                system.assert(creditreport.Solar_Loan_Pre_Qualification_Status__c == 'Pre-Qualified');
            }

        }

        test.stopTest();
        
        }}