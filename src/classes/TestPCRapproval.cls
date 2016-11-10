@isTest
private class TestPCRapproval {

Static testMethod void TestPCRapproval(){


        Lead lead = new Lead (LastName = 'Chan',
                                 FirstName = 'Joey',
                                 Email = 'test@email.com',
                                 Company = 'Cloud Jedi',
                                 Status = 'Qualified',
                                 Annual_Income_Currency__c = 50000,
                                 Loan_Amount__c = 45000,
                                 Construction_Period_DOER__c = 0,
                                 DOER_Solar_Loan__c = TRUE,
                                 Pre_Approval_Form__c = TRUE,
                                  Custom_ID__c = 'BOS'
                                                             );
        insert lead;
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'
                                                                                        );
        
        insert pcr;
                                                                                       
        LASERCA__Trade_Accounts__c  tradeacct = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcr.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacct;  
        update tradeacct;       
                                                                               
        lead.Personal_Credit_Report__c = pcr.Id;

        update lead;

                Lead leadA = new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Annual_Income_Currency__c = 20000,
                                                             Loan_Amount__c = 65000,
                                                             Construction_Period_DOER__c = 0,
                                                             DOER_Solar_Loan__c = FALSE,
                                                             Pre_Approval_Form__c = TRUE,
                                                             Custom_ID__c = 'BOS'
                                                             );
        insert leadA;
        LASERCA__Personal_Credit_Report__c pcrA = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadA.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '400');
        
        insert pcrA;
                                                                                        
        LASERCA__Trade_Accounts__c  tradeacctA = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrA.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacctA;  
        update tradeacctA;    
         
        leadA.Personal_Credit_Report__c = pcrA.Id;

        update leadA;
        //
                    Lead leadAA = new Lead (LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Annual_Income_Currency__c = 20000,
                                                             Loan_Amount__c = 65000,
                                                             Construction_Period_DOER__c = 0,
                                                             DOER_Solar_Loan__c = FALSE,
                                                             Pre_Approval_Form__c = TRUE,
                                                             Custom_ID__c = 'BOS'
                                                             );
        insert leadAA;
        LASERCA__Personal_Credit_Report__c pcrAA = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadAA.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '400');
        insert pcrAA;
                                                                                      
        LASERCA__Trade_Accounts__c  tradeacctAA = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrAA.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacctAA;  
        update tradeacctAA;    
         
        leadAA.Personal_Credit_Report__c = pcrAA.Id;

        update leadAA;
        //


        /*        Lead leadBB = new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Annual_Income_Currency__c= 21150,
                                                             Loan_Amount__c = 30000,
                                                             Construction_Period_DOER__c = 0,
                                                             DOER_Solar_Loan__c = TRUE,
                                                             Custom_ID__c = 'BOS'
                                                             );
        insert leadBB;
        LASERCA__Personal_Credit_Report__c pcrBB = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadBB.Id,
                                                                                        LASERCA__Code__c = '020',
                                                                                        LASERCA__Credit_Score_TransUnion__c = '692');
        
        insert pcrBB;
                                                                                       
        LASERCA__Trade_Accounts__c  tradeacctBB = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrBB.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacctBB;  
        update tradeacctBB;                                                                                         
                                                                                        
        lead.Personal_Credit_Report__c = pcrBB.Id;

        update leadBB;
    */


    /*            Lead leadC = new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Annual_Income_Currency__c = 10000,
                                                             Loan_Amount__c = 20000,
                                                             Construction_Period_DOER__c = 0,
                                                             DOER_Solar_Loan__c = TRUE,
                                                             Custom_ID__c = 'BOS'
                                                             );
        insert leadC;
        LASERCA__Personal_Credit_Report__c pcrC = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadC.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '800',
                                                                                        Solar_Loan_Manual_Approval__c = TRUE);   
                                                                                        
        insert pcrC; 
                                                                                        
        LASERCA__Trade_Accounts__c  tradeacctC = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrC.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacctC;  
        update tradeacctC;                                                                                          
                                                                                                                                                              
        lead.Personal_Credit_Report__c = pcrC.Id;

        update leadC;

*/

/*                Lead leadD = new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Annual_Income_Currency__c = 1000,
                                                             Loan_Amount__c = 35000,
                                                             Construction_Period_DOER__c = 0,
                                                             DOER_Solar_Loan__c = TRUE,
                                                             Custom_ID__c = 'BOS'
                                                             );
        insert leadD;
        LASERCA__Personal_Credit_Report__c pcrD = new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadD.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '800',
                                                                                        Solar_Loan_Manual_Decline__c = TRUE
                                                                                        );
        insert pcrD;
                                                                                       
        LASERCA__Trade_Accounts__c  tradeacctD = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = pcrD.id,
                                                                                LASERCA__Monthly_Payment__c = 500);
                                                                                         
        insert tradeacctD;  
        update tradeacctD;                                                                                          
                                                                                        
        lead.Personal_Credit_Report__c = pcrD.Id;

        update leadD;
        */
        
        }}