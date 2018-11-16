/*
 * Tested by: testTraunchCapitalMetrics
 */
trigger deductLoanValue on Loan_Traunch__c (after insert, after update) {
    if (Util.isDisabled('Disable_LoanTrancheTrigger__c')) {
        return;
    }
    if (helperclass2.bool != false) {
        Set<String> traunchNames = new Set<String>( );
        Set<Id> opId = new Set<Id>();
        List<Loan_Traunch__c> loanOutflows = new List<Loan_Traunch__c>( );
        Integer capExSum;
        Integer capd1Sum;
        Integer capExSumComp ;

        for (Loan_Traunch__c traunch: Trigger.new) {
            if (Loan_Traunch__c.name != null) {
                traunchNames.add(traunch.Name);
            }
        }
        List<Opportunity> opps = [
            SELECT Id,Requested_Loan_Amount__c, loan_traunch__r.Name
            FROM Opportunity
            WHERE loan_traunch__r.Name IN :traunchNames
        ];
        for (Opportunity op : opps) {
            opId.add(op.Id);
        }
        List<AggregateResult> aggregateResults = [
            SELECT SUM(Requested_Loan_Amount__c)lc, SUM(Disbursal_1_Contract_Signature__c) d1
            FROM Opportunity
            WHERE Id IN: opId
            AND StageName != 'Complete'
            AND StageName != 'Declined'
        ];
        for (AggregateResult large :aggregateResults) {
            capExSum = Integer.valueOf(large.get('lc'));
            capd1Sum = Integer.valueOf(large.get('d1'));

            if(capExSum == null) {
                capExSum = 0;
            }
        }
        aggregateResults = [
            SELECT SUM(Disbursal_1_Contract_Signature__c)lc2, SUM(Requested_Loan_Amount__c) d1a
            FROM Opportunity
            WHERE Id IN: opId
            AND StageName = 'Complete'
        ];
        for (AggregateResult large2 : aggregateResults) {
            capExSumComp = Integer.valueOf(large2.get('d1a'));
            if(capExSum == null) {
                capExSum = 0;
            }
        }

        List<Loan_Traunch__c> traunches = [
            SELECT Id
            FROM Loan_Traunch__c
            WHERE loan_traunch__c.Name IN :traunchNames
        ];
        for (Loan_Traunch__c lt : traunches) {
            lt.Capital_Reserved__c = capExSumComp ;
            lt.Capital_Outflows__c = capExSum;
            loanOutflows.add(lt);
        }
        if (loanOutflows != null) {
            helperclass2.bool = false;
            update loanOutflows;
        }
    }
}