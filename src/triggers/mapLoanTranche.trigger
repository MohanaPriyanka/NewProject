//Commented out for LoanTrancheUpdateHandler and the migration of tranching to the loan object instead.
Trigger mapLoanTranche on Opportunity (before update, before insert) {

/*
set <id> oppIds = new Set <id>( ); 
integer availableCapital;


    for ( opportunity l : trigger.new) {

      if((l.loan_assignment__c == 'Automatic' || l.loan_assignment__c == null) && l.product_line__c == 'Residential Loan' && trigger.isInsert){           
    
        list<id> trancheList = new list<id>();
        list<decimal> availableCapitalList = new list<decimal>();
        
        for (Loan_Traunch__c obj : [SELECT Id, available_capital__c FROM Loan_Traunch__c WHERE Available_Capital__c > 0  ORDER BY Available_Capital__c DESC] ) {

            trancheList.add (obj.id); 
            availableCapitalList.add (obj.available_capital__c);
        }

        for ( Opportunity l2 : trigger.new) {

            if ( trigger.isInsert){
            
               if(trancheList.size() == 0){
               
               l2.loan_traunch__c= null;
               l2.available_capital_in_tranche__c = null;
               
               }
               
               else{
         
               l2.loan_traunch__c = trancheList.get(0);           
               l2.available_capital_in_tranche__c = availableCapitalList.get(0);
               
               }
            
            }
            
           
        else {

             l2.loan_traunch__c= null;
             l2.available_capital_in_tranche__c = null;
    }
    }
}

      if(trigger.isUpdate){     
      
        for(opportunity l3 : trigger.new){
        
        if(l3.product_line__c == 'Residential Loan' && trigger.isUpdate){      
                
        oppIds.add (l3.loan_traunch__c); }
        
        }
    
        list<id> trancheList = new list<id>();
        list<decimal> availableCapitalList = new list<decimal>();
       
       if(oppIds.size() > 0){
        
        for (Loan_Traunch__c obj : [SELECT Id, available_capital__c FROM Loan_Traunch__c WHERE id IN : oppIds] ) {
            
            availableCapitalList.add (obj.available_capital__c);
        }
          

               l.available_capital_in_tranche__c = availableCapitalList.get(0);
               
               }
               
               else{
         
                        
               l.available_capital_in_tranche__c = null;
               
               }
            
            }
            
           
     
    }
*/
return;


}