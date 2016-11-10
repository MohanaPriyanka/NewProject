Trigger deductLoanValue on Loan_Traunch__c (after insert, after update) {
if(helperclass2.bool != false){

set <string> traunchNames = new Set <string>( ); 
set<id> opId = new set<id>();
List <Loan_Traunch__c> loanOutflows = new List <Loan_Traunch__c>( );
Integer capExSum;
integer capd1Sum;
integer capExSumComp ;

for (Loan_Traunch__c traunch: trigger.new) {

    If (Loan_Traunch__c.name != null) {
        traunchNames.add (traunch.name);
    }
}

for(opportunity op : [select id,loan_principle__c, loan_traunch__r.name  FROM opportunity WHERE loan_traunch__r.name  IN :traunchNames])
{
    opId.add(op.id);
}


for(Aggregateresult large : [select SUM(loan_principle__c)lc, sum(Disbursal_1_Contract_Signature__c)d1 FROM opportunity WHERE id IN: opId AND stageName != 'Complete' AND stageName != 'Declined']){
         capExSum = integer.valueOf(large.get('lc'));
         capd1Sum = integer.valueOf(large.get('d1'));

         if(capExSum == null) { 
         
         capExSum = 0; }    
}

for(Aggregateresult large2 : [select SUM(Disbursal_1_Contract_Signature__c)lc2, sum(loan_principle__c)d1a FROM opportunity WHERE id IN: opId AND stageName = 'Complete']){
         capExSumComp = integer.valueOf(large2.get('d1a'));
         
         if(capExSum == null) { 
         
         capExSum = 0; }    
}


for(loan_traunch__c lt : [SELECT id FROM loan_traunch__c WHERE loan_traunch__c.name  IN :traunchNames]){
    
lt.capital_reserved__c = capExSumComp ;
lt.capital_outflows__c = capexSum;
loanOutflows.add(lt);
}



if(loanOutflows != null){
    
    helperclass2.bool = false; 
    update loanOutflows;
}
}
}