trigger calculateAmortization on Opportunity (before delete, before insert, before update) {

	Amortization am = new Amortization();
	Map<ID, String> loan_old = new Map<ID, String>();
	Map<ID, String> loan_new = new Map<ID, String>();
	String tmpJSON = '';

	if(!trigger.isDelete){
	
		for(Opportunity opp : trigger.new){
			if(opp.Number_of_Periods_Months__c > 0
				&& opp.Commencement_Date__c != null
				&& opp.Loan_Rate__c > 0
				&& opp.System_Size__c > 0
				&& opp.Financing_Fee__c > 0){
					if(trigger.isInsert
						|| opp.Number_of_Periods_Months__c != trigger.oldMap.get(opp.id).Number_of_Periods_Months__c
						|| opp.Commencement_Date__c != trigger.oldMap.get(opp.id).Commencement_Date__c
						|| opp.Loan_Rate__c != trigger.oldMap.get(opp.id).Loan_Rate__c
						|| opp.System_Size__c != trigger.oldMap.get(opp.id).System_Size__c
						|| opp.Financing_Fee__c != trigger.oldMap.get(opp.id).Financing_Fee__c
						|| opp.Principal_Step_Down_Occurs__c != trigger.oldMap.get(opp.id).Principal_Step_Down_Occurs__c){
							// ------ Call function which generate amortization schedule
							am.storeAmPlanFromTriggerExample(opp);
							if(trigger.isInsert)
								loan_old.put(opp.id, '');
							else{
								tmpJSON = trigger.oldMap.get(opp.id).amortization_plan__c;
								loan_old.put(opp.id, tmpJSON);
							}
							loan_new.put(opp.id, opp.amortization_plan__c);
						}
				} // if
			
		} // for
	} // if
	else{
		for(Opportunity opp : trigger.old){
			if(opp.amortization_plan__c!=null && opp.amortization_plan__c.length()>10){
				loan_old.put(opp.id, opp.amortization_plan__c);
				loan_new.put(opp.id, '');
			}
		}
		
	}
	
	if(loan_new!=null && loan_new.size()>0){
		// ----- Call function which change data in consolidate objects records
		am.changeAmPlanInConsolidateObject(loan_old, loan_new);
	}
}