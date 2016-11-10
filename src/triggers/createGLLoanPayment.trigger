trigger createGLLoanPayment on loan_payment__c (after insert){ // trigger after insert

    loan_payment__c [] PMTS = trigger.new;
    
    for(loan_payment__c LP : trigger.new){

    if(trigger.isInsert && lp.interest_payment__c != null){
    
        createGL.GeneralLedgerInterestPayment(PMTS);}
   
    if(trigger.isInsert && lp.principal_payment__c != null){
    
        createGL.GeneralLedgerPrincipalPayment(PMTS);}
        
    else{ return;}}}