trigger DOERCalculator on Opportunity (before insert, before update) {/*

List <opportunity> opportunityList = new List <opportunity>( );
List <decimal> principalInterestList = new List <decimal>( );
List <decimal > interestList = new List <decimal >( );
List <opportunity> NPVInterestList = new List <opportunity>( );
List <decimal> paymentList = new List <decimal>( );
List <decimal> paymentList2 = new List <decimal>( );
List <decimal> interestPaymentPIList = new List <decimal>( );
List <decimal> principalPaymentPIList = new List <decimal>( );



for ( opportunity opp : trigger.new) {

If (trigger.isUpdate && opp.doer_solar_loan__c == TRUE && opp.loan_principle__c != null) {    

decimal interestRate = opp.WSJ_Prime_2_75__c/100;
decimal IRBDrate = opp.IRBD_Rate__c/100;
decimal interestPeriod = opp.Interest_Only_Period_DOER__c;
decimal principalInterestPeriod = opp.Principal_and_Interest_Period_DOER__c;
decimal interestPayment;
decimal IRBDinterestPayment;
decimal principalInterestPayment;
decimal IRBDprincipalInterestPaymentFee;
decimal IRBDprincipalInterestPayment;
decimal principal = opp.Loan_Amount_Financed__c;
decimal firstDisbursalRate = 0.35;
decimal secondDisbursalRate = 0.65;
decimal interestPaymentDifference;
decimal PIpaymentDifference;
decimal NPVperiod;
decimal NPVperiodPI;
decimal NPVpayment = 0;
decimal NPVperiodPayment; 
decimal NPVinterestOnly = 0;
decimal NPVpi = 0;
decimal exponentHelper;
decimal exponentHelper2;
decimal exponentHelperPI;
decimal exponentHelper2PI;
decimal exponentHelperPayment;
decimal exponentHelper2Payment; 
decimal loanBalanceAtPurchase1;
decimal loanBalanceAtPurchase2;
decimal payments; 
decimal loanBalance = opp.loan_amount_financed__c;
decimal interestPaymentPI;
decimal disbursalOne;
decimal disbursalTwo;
decimal loanBalancePostDisbursals ;
decimal principalPaymentPI ;
decimal principalDeduction = 0;

integer i;    

        interestPayment = opp.loan_amount_financed__c * (interestRate / 12) * firstDisbursalRate;

        IRBDinterestPayment = opp.loan_amount_financed__c * (IRBDrate / 12) * firstDisbursalRate;

        interestPaymentDifference = interestPayment - IRBDinterestPayment;

            for( i = 0; i < interestPeriod; i++){

                interestList.add(interestPaymentDifference);}
    
            for( i = 0; i < interestPeriod; i++){
            
                exponentHelper = (1 + interestRate/12);
                exponentHelper2 = exponentHelper.pow(i+1);

                NPVperiod = interestList.get(i)/(exponentHelper2);
    
                NPVinterestOnly = NPVperiod + NPVinterestOnly;}
          
   opp.IRBD_Interest_Only__c = NPVinterestOnly ;
   
//.   
   
        decimal principalInterestPaymentHelper = (1 + interestRate/12);       
        decimal principalInterestPaymentHelper2 = (1 + IRBDrate/12); 
       
        principalInterestPayment = interestRate/12 * (opp.loan_principle__c) / (1 - (1/(principalInterestPaymentHelper.pow(120))));               

        IRBDprincipalInterestPayment = IRBDrate/12 * (opp.Loan_Principle__c ) / (1 - (1/(principalInterestPaymentHelper2.pow(120)))); 

        PIpaymentDifference = principalInterestPayment - IRBDprincipalInterestPayment ;

            for( i = 0; i < principalInterestPeriod; i++){

                principalInterestList.add(PIpaymentDifference);}
    
            for( i = 0; i < principalInterestPeriod ; i++){
            
                exponentHelperPI = (1 + interestRate/12);
                exponentHelper2PI = exponentHelperPI.pow(i+1);

                NPVperiodPI = principalInterestList.get(i)/(exponentHelper2PI);
    
                NPVpi = NPVperiodPI + NPVpi;}
          
   opp.IRBD_Principal_Interest__c = NPVpi;
   
   //.
   
            IRBDprincipalInterestPaymentFee = IRBDrate/12 * (opp.loan_amount_financed__c) / (1 - (1/(principalInterestPaymentHelper2.pow(120))));
            
            for( i = 0; i < (principalInterestPeriod-opp.Month_of_Loan_Purchase__c); i++){

                paymentList.add(IRBDprincipalInterestPaymentFee );}
    
            for( i = 0; i < (principalInterestPeriod-opp.Month_of_Loan_Purchase__c); i++){
            
                exponentHelperPayment = (1 + opp.BlueWave_Avidia_Rate__c/100/12);
                exponentHelper2Payment = exponentHelperPayment.pow(i+1);

                NPVperiodPayment = paymentList.get(i)/(exponentHelper2Payment);
    
                NPVpayment = NPVperiodPayment + NPVpayment;}
          
            opp.Loan_Purchase_Price__c = NPVpayment;
   //.
               
            disbursalOne = opp.loan_principle__c * firstDisbursalRate;
            disbursalTwo = opp.loan_principle__c * secondDisbursalRate;
            
            loanBalancePostDisbursals = opp.loan_amount_financed__c - NPVpi - NPVinterestOnly;
           
            for( i = 0; i < (opp.Month_of_Loan_Purchase__c + 1); i++){
            
                interestPaymentPI = loanBalance * IRBDrate/12;
                principalPaymentPI = (IRBDprincipalInterestPaymentFee - interestPaymentPI);
                
                interestPaymentPIList.add(interestPaymentPI);
                principalPaymentPIList.add(principalPaymentPI);
                                               
                loanBalance = loanBalance - principalPaymentPIList.get(i);
                
                principalDeduction = principalDeduction + principalPaymentPIList.get(i);
                
                opp.Loan_Balance_at_Purchase__c = (disbursalOne - NPVinterestOnly) + disbursalTwo - NPVpi - principalDeduction ;}}}*/}