trigger DOERCalculatorLoan on loan__c (before insert, before update) {

//List <opportunity> opportunityList = new List <opportunity>( );
//List <decimal> principalInterestList = new List <decimal>( );
//List <decimal > interestList = new List <decimal >( );
//List <decimal > interestListCompleted = new List <decimal >( );
//List <opportunity> NPVInterestList = new List <opportunity>( );
//List <decimal> paymentList = new List <decimal>( );
//List <decimal> paymentList2 = new List <decimal>( );
//List <decimal> interestPaymentPIList = new List <decimal>( );
//List <decimal> principalPaymentPIList = new List <decimal>( );



//for ( loan__c opp : trigger.new) {

//If (trigger.isUpdate && opp.doer_solar_loann__c == TRUE && opp.Principall__c!= null && opp.Loan_Base_Rate__c != null && opp.Loan_Internal_Lender_Rate__c != null) {    

//decimal interestRate = opp.Loan_Base_Rate__c/100;
//decimal IRBDrate = opp.Interest_Rate__c/100;
//decimal interestPeriod = opp.Interest_Only_Period_DOER__c;
//decimal principalInterestPeriod = opp.Principal_and_Interest_Period_DOER__c;
//decimal interestPayment;
//decimal IRBDinterestPayment;
//decimal interestPaymentCompleted;
//decimal IRBDinterestPaymentCompleted;
//decimal principalInterestPayment;
//decimal IRBDprincipalInterestPaymentFee;
//decimal IRBDprincipalInterestPayment;
//decimal principal = opp.Principall__c;
//decimal firstDisbursalRate = 0.35;
//decimal secondDisbursalRate = 0.65;
//decimal interestPaymentDifference;
//decimal interestPaymentDifferenceCompleted;
//decimal PIpaymentDifference;
//decimal NPVperiod;
//decimal NPVperiodCompleted;
//decimal NPVperiodPI;
//decimal NPVpayment = 0;
//decimal NPVperiodPayment; 
//decimal NPVinterestOnly = 0;
//decimal NPVinterestOnlyCompleted = 0;
//decimal NPVpi = 0;
//decimal NPVpiCompleted = 0;
//decimal exponentHelper;
//decimal exponentHelper2;
//decimal exponentHelperCompleted;
//decimal exponentHelper2Completed;
//decimal exponentHelperPI;
//decimal exponentHelper2PI;
//decimal exponentHelperPayment;
//decimal exponentHelper2Payment; 
//decimal loanBalanceAtPurchase1;
//decimal loanBalanceAtPurchase2;
//decimal payments; 
//decimal loanBalance = opp.Principall__c;
//decimal interestPaymentPI;
//decimal disbursalOne;
//decimal disbursalTwo;
//decimal loanBalancePostDisbursals ;
//decimal principalPaymentPI ;
//decimal principalDeduction = 0;
//decimal completedInterestOnlyIRBD;

//integer i;    

//        interestPayment = opp.Principall__c * (interestRate / 12) * firstDisbursalRate;

//        IRBDinterestPayment = opp.Principall__c * (IRBDrate / 12) * firstDisbursalRate;

//        interestPaymentDifference = interestPayment - IRBDinterestPayment;

//            for( i = 0; i < 12; i++){

//                interestList.add(interestPaymentDifference);}
    
//            for( i = 0; i < 12; i++){
            
//                exponentHelper = (1 + interestRate/12);
//                exponentHelper2 = exponentHelper.pow(i+1);

//                NPVperiod = interestList.get(i)/(exponentHelper2);
    
//                NPVinterestOnly = NPVperiod + NPVinterestOnly;}
          
//   opp.IRBD_Interest_Only__c = NPVinterestOnly ;
   
////.   

//    if(trigger.isUpdate && opp.Interest_Only_Period_DOER__c != null && trigger.oldMap.get(opp.id).Interest_Only_Period_DOER__c != opp.Interest_Only_Period_DOER__c ){

//        interestPaymentCompleted = opp.Principall__c * (interestRate / 12) * firstDisbursalRate;

//        IRBDinterestPaymentCompleted = opp.Principall__c * (IRBDrate / 12) * firstDisbursalRate;

//        interestPaymentDifferenceCompleted = interestPaymentCompleted - IRBDinterestPaymentCompleted;

//            for( i = 0; i < interestPeriod; i++){

//                interestListCompleted.add(interestPaymentDifferenceCompleted);}
    
//            for( i = 0; i < interestPeriod; i++){
            
//                exponentHelperCompleted = (1 + interestRate/12);
//                exponentHelper2Completed = exponentHelper.pow(i+1);

//                NPVperiodCompleted = interestListCompleted.get(i)/(exponentHelper2Completed);
    
//                NPVinterestOnlyCompleted = NPVperiodCompleted + NPVinterestOnlyCompleted;}
          
//   completedInterestOnlyIRBD = NPVinterestOnlyCompleted;}
////.   
   
//        decimal principalInterestPaymentHelper = (1 + interestRate/12);       
//        decimal principalInterestPaymentHelper2 = (1 + IRBDrate/12); 
       
//        principalInterestPayment = interestRate/12 * (opp.Principall__c) / (1 - (1/(principalInterestPaymentHelper.pow(120))));               

//        IRBDprincipalInterestPayment = IRBDrate/12 * (opp.Principall__c) / (1 - (1/(principalInterestPaymentHelper2.pow(120)))); 

//        PIpaymentDifference = principalInterestPayment - IRBDprincipalInterestPayment ;

//            for( i = 0; i < principalInterestPeriod; i++){

//                principalInterestList.add(PIpaymentDifference);}
    
//            for( i = 0; i < principalInterestPeriod ; i++){
            
//                exponentHelperPI = (1 + interestRate/12);
//                exponentHelper2PI = exponentHelperPI.pow(i+1);

//                NPVperiodPI = principalInterestList.get(i)/(exponentHelper2PI);
    
//                NPVpi = NPVperiodPI + NPVpi;}
   
//   if(trigger.isUpdate && opp.Interest_Only_Period_DOER__c != null && trigger.oldMap.get(opp.id).Interest_Only_Period_DOER__c != opp.Interest_Only_Period_DOER__c ){
       
//       NPVpiCompleted = NPVpi - (NPVinterestOnly - completedInterestOnlyIRBD);
//       opp.IRBD_Principal_Interest__c = NPVpiCompleted;}
   
//   else{       
      
//       opp.IRBD_Principal_Interest__c = NPVpi;}
   
//   //.
   
//            IRBDprincipalInterestPaymentFee = IRBDrate/12 * (opp.Principall__c) / (1 - (1/(principalInterestPaymentHelper2.pow(120))));
            
//            for( i = 0; i < (principalInterestPeriod-opp.Month_of_Loan_Purchase__c); i++){

//                paymentList.add(IRBDprincipalInterestPaymentFee );}
    
//            for( i = 0; i < (principalInterestPeriod-opp.Month_of_Loan_Purchase__c); i++){
            
//                exponentHelperPayment = (1 + opp.Loan_Internal_Lender_Rate__c/100/12);
//                exponentHelper2Payment = exponentHelperPayment.pow(i+1);

//                NPVperiodPayment = paymentList.get(i)/(exponentHelper2Payment);
    
//                NPVpayment = NPVperiodPayment + NPVpayment;}
          
//            opp.Loan_Purchase_Price__c = NPVpayment;



//____________________________leave commented below   //.
               
            //disbursalOne = opp.Principall__c* firstDisbursalRate;
            //disbursalTwo = opp.Principall__c* secondDisbursalRate;
            
            //loanBalancePostDisbursals = opp.Principall__c- NPVpi - NPVinterestOnly;
           
            //for( i = 0; i < (opp.Month_of_Loan_Purchase__c + 1); i++){
            
                //interestPaymentPI = loanBalance * IRBDrate/12;
                //principalPaymentPI = (IRBDprincipalInterestPaymentFee - interestPaymentPI);
                
                //interestPaymentPIList.add(interestPaymentPI);
                //principalPaymentPIList.add(principalPaymentPI);
                                               
               // loanBalance = loanBalance - principalPaymentPIList.get(i);
                
                //principalDeduction = principalDeduction + principalPaymentPIList.get(i);
                
                //if(trigger.isUpdate && opp.Interest_Only_Period_DOER__c != null && trigger.oldMap.get(opp.id).Interest_Only_Period_DOER__c != opp.Interest_Only_Period_DOER__c ){
                
                    //opp.Avidia_Outstanding_Loan_Balance__c= (disbursalOne - NPVinterestOnly) + disbursalTwo - NPVpiCompleted - principalDeduction ;}
                    
                //else{
                
                    //opp.Avidia_Outstanding_Loan_Balance__c= (disbursalOne - NPVinterestOnly) + disbursalTwo - NPVpi - principalDeduction ;}}
//_____________________________________    

    //}}
                }