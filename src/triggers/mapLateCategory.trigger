trigger mapLateCategory on loan__c (before insert, before update) {
 
 set <string> loanMonths = new set <string>();
 set <string> loanYears = new set <string>();
 set <string> loanNames = new set <string>();
 
  for(loan__c l : trigger.new){
 
     if( l.name != null){
     
         loanNames.add(l.name);}
        
     }
     
 
 for(loan__c lm : trigger.new){
 
     if( lm.monthLT__c != null){
     
         loanMonths.add(lm.monthLT__c);}
        
     }
 
  for(loan__c ly : trigger.new){
 
     if( ly.yearLT__c != null){
     
         loanYears.add(ly.yearLT__c);}
        
     }
 If( loanNames.size() > 0 && loanMonths.size() > 0 && loanYears.size() > 0){
 
     map <string, loan_payment__c > loanPayMap = new map <string, loan_payment__c> ();
 
     for(loan_payment__c loanPayQuery :[SELECT id, name, month__c, year2__c, loan_name__c, late_category__c FROM loan_payment__c WHERE loan_name__c IN :loanNames AND month__c IN :loanMonths AND year2__c IN :loanYears]){
 
         loanPayMap.put(loanPayQuery.Loan_Name__c,loanPayQuery);
 
 }
 
 for ( loan__c lf : trigger.new) {

        if (( trigger.isInsert || trigger.isUpdate || trigger.oldMap.get(lf.Id).monthLT__c != lf.monthLT__c) && loanPayMap.containsKey (lf.name)) {

            lf.late_category__c = loanPayMap.get (lf.name).late_category__C;
            
            }
 
  else {
 
        
            lf.late_category__c = null;
    }

}
}

}