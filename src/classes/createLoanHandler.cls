/*
Developed by Cole Swain - colemswain@gmail.com (Last Updated 07/13/2016)

createLoanHandler is a triggered batch script that runs after a loan contract is fully completed on the opportunity record.
The script assigns the creates a loan record and attaches it to the opportunity. It does not allow for duplicates by utilizing the upsert function.
*/
public with sharing class createLoanHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public createLoanHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterUpdate(opportunity[] oldOpps, opportunity[] updatedOpps, Map<ID, opportunity> oldOppMap, Map<ID, opportunity> newOppMap){
        createLoan(updatedOpps);
    }

    private void createLoan(List<opportunity> newOppList){
     Set<Loan__c> newLoanSet = new Set<Loan__c>();
     integer i;

     for(i = 0;i < newOppList.size(); i++){
        if(newOpplist.get(i).Product_Line__c == 'Residential Loan'){
            if(newOppList.get(i).StageName == 'Complete'){
                if(newOppList.get(i).State_ab__c != 'MA'){
                    Loan__c loan = new loan__c(
                        Name = newOppList.get(i).Name,
                        Unique_ID__c = newOppList.get(i).id,
                        Commencement_datee__c = newOppList.get(i).Commencement_date__c,
                        DOER_Solar_Loann__c = newOppList.get(i).DOER_Solar_Loan__c,
                        Interest_Ratee__c = newOppList.get(i).Interest_rate__c,
                        Maturity_datee__c = newOppList.get(i).Maturity_date2__c,
                        Opportunity__c = newOppList.get(i).Id,
                        Origination_datee__c = newOppList.get(i).Origination_date__c,
                        Principall__c = newOppList.get(i).Loan_Amount_Financed__c,
                        Requested_Loan_Amount__c = newOppList.get(i).Requested_Loan_Amount__c,
                        System_Costt__c = newOppList.get(i).Loan_Principle__c,
                        BlueWave_Capital__c = TRUE,
                        Partner__c = newOppList.get(i).Partner_tag_lookup__c,
                        State__c = newOppList.get(i).State_ab__c);
                    
                    newLoanSet.add(loan);
                }

                else{
                    Loan__c loan = new loan__c(
                        Name = newOppList.get(i).Name,
                        Unique_ID__c = newOppList.get(i).id,
                        Commencement_datee__c = newOppList.get(i).Commencement_date__c,
                        DOER_Solar_Loann__c = newOppList.get(i).DOER_Solar_Loan__c,
                        Interest_Ratee__c = newOppList.get(i).Interest_rate__c,
                        Maturity_datee__c = newOppList.get(i).Maturity_date2__c,
                        Opportunity__c = newOppList.get(i).Id,
                        Partner__c = newOppList.get(i).Partner_tag_lookup__c,
                        Origination_datee__c = newOppList.get(i).Origination_date__c,
                        Principall__c = newOppList.get(i).Loan_Amount_Financed__c,
                        Requested_Loan_Amount__c = newOppList.get(i).Requested_Loan_Amount__c,
                        System_Costt__c = newOppList.get(i).Loan_Principle__c,                        
                        State__c = newOppList.get(i).State_ab__c);
                    
                    newLoanSet.add(loan);
                }
            }
        }
        upsert new list<Loan__c>(newLoanSet) Unique_ID__c;
    }
}
}