public class DisbursalHandler {

    public class DisbursalStructure {      
    	public Integer disbursalCount;
    	public List<String> percentageList;
    	public List<String> nameList;
    	public List<String> typeList;

        public DisbursalStructure() {
        	disbursalCount = 0;         	
        	percentageList = new List<String>();
        	nameList = new List<String>();     
        	typeList = new List<String>();                                
        }     	
    }	

    public void createDisbursalsFromOpportunity(Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Loan__c> loanList = new List<Loan__c>();
        List<String> opportunityIdList = new List<String>();
        List<Disbursal__c> disbursalsToInsert = new List<Disbursal__c>();

        for (Opportunity oppRecord : newMap.values()) {
        	if (opportunityStageChangesToComplete(oppRecord, newMap, oldMap)) {
                opportunityIdList.add(newMap.get(oppRecord.Id).Id);
        	}
        }
        if (!opportunityIdList.isEmpty()) {
            for(Opportunity opp : [SELECT Id, Name,
            						 (SELECT Id, Name, Opportunity__r.StageName, Requested_Loan_Amount__c, Partner__r.Id, Partner__r.Name,
                                    	Product__r.Disbursal_Terms__c, Opportunity__r.Requested_Loan_Amount__c, Sales_Agent__r.Id 
                                      FROM Loans__r)
                                    FROM Opportunity
                                    WHERE Id IN : opportunityIdList]) {
                loanList.add(opp.Loans__r);
            }
            for (Loan__c loanRecord : loanList) {
            	DisbursalStructure disbursalStrucutre = getDisbursalStructure(loanRecord);
            	disbursalsToInsert = createDisbursals(disbursalStrucutre, loanRecord);
            }
            upsert disbursalsToInsert Unique_ID__c;
        }
    }

    public Boolean opportunityStageChangesToComplete (Opportunity oppRecord, Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        if (newMap.get(oppRecord.Id).StageName == 'Complete'
            && oldMap.get(oppRecord.Id).StageName != 'Complete'
            && newMap.get(oppRecord.Id).Product_Line__c == 'Residential Loan') {
        	return true;
        } else {
        	return false;
        } 	
    }

    public DisbursalStructure getDisbursalStructure (Loan__c loanRecord) {
		DisbursalStructure disbursalStructure = new DisbursalStructure();
		String disbursalTerms = loanRecord.Product__r.Disbursal_Terms__c;
		List<String> disbursalSubStrings = disbursalTerms.split(',');
		disbursalStructure.disbursalCount = 0;
		for (String subString : disbursalSubStrings) {
			disbursalStructure.disbursalCount = disbursalStructure.disbursalCount + 1;
			List<String> rate = subString.split('%');
			disbursalStructure.percentageList.add(rate.get(0));	
			String disbursalName = subString;
			if (disbursalName.length() >= 80) {
				disbursalName = disbursalName.subString(0,80);
			}
			disbursalStructure.typeList.add(rate.get(1));
			disbursalStructure.nameList.add(disbursalName);
		}
		return disbursalStructure;
    }    

    public List<Disbursal__c> createDisbursals (DisbursalStructure disbursalStructure, Loan__c loanRecord) {
    	List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    	Integer i;
    	for (i=0; i < disbursalStructure.disbursalCount; i++) {
    		Decimal rate = Decimal.valueOf(disbursalStructure.percentageList.get(i).remove(' '));
    		rate = rate;
			Disbursal__c disbursal = new Disbursal__c(
			    Name = disbursalStructure.nameList.get(i)  + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name,
			    Unique_ID__c = loanRecord.Id + ' ' + disbursalStructure.nameList.get(i) + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
			    Loan__c = loanRecord.Id,
			    Disbursal_Sequence__c = i + 1,
			    Disbursal_Percentage__c = rate,
			    Partner__c = loanRecord.Partner__r.Id,
			    Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
			    Status__c = 'Not yet disbursed',
			    Amount__c = loanRecord.Requested_Loan_Amount__c * rate / 100,
			    Type__c = disbursalStructure.typeList.get(i),
			    Anticipated_Date__c = null,
			    Date_of_Disbursal__c = null
			);
			disbursalList.add(disbursal);
    	}
    	return disbursalList;
    }    

    public void updateDisbursalAmounts (Map<Id,Loan__c> newMap, Map<Id, Loan__c> oldMap) {
    	List<Id> updatedLoans = new List<Id>();
    	List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
    	for (Loan__c loanRecord : newMap.Values()) {
    		if (loanRecord.DOER_Solar_Loann__c) {
	    		if (newMap.get(loanRecord.Id).Requested_Loan_Amount__c != oldMap.get(loanRecord.Id).Requested_Loan_Amount__c  
	    			&& oldMap.get(loanRecord.Id).Requested_Loan_Amount__c  != null 
	    			&& newMap.get(loanRecord.Id).Requested_Loan_Amount__c  != null) {
		    			updatedLoans.add(loanRecord.Id);
	    		}
    		}
    	}
    	for (Loan__c loanRecord : [SELECT Id, Name, Requested_Loan_Amount__c, Total_Funds_Disbursed__c, Partner__r.Name, Sales_Agent__r.Id, Partner__r.Id,
    								(SELECT Id, Amount__c, Status__c, Disbursal_Percentage__c
    								FROM Disbursals__r)
    							   FROM Loan__c
    							   WHERE Id IN : updatedLoans]) {
    		if (oldMap.get(loanRecord.Id).Requested_Loan_Amount__c > newMap.get(loanRecord.Id).Requested_Loan_Amount__c) {
    			insert createDownPaymentDisbursal(loanRecord, newMap.get(loanRecord.Id).Requested_Loan_Amount__c - oldMap.get(loanRecord.Id).Requested_Loan_Amount__c);
			} 
    		disbursalsToUpdate = calculateRemainingDisbursalValues(loanRecord, newMap);
    	}
    	update disbursalsToUpdate;
    }      

    public Disbursal__c createDownPaymentDisbursal (Loan__c loanRecord, Decimal downPayment) {
		Disbursal__c disbursal = new Disbursal__c(
		    Name = 'Down Payment due to Adjustment'  + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name,
		    Unique_ID__c = loanRecord.Id + ' Down Payment ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
		    Loan__c = loanRecord.Id,
		    Disbursal_Sequence__c = null,
		    Disbursal_Percentage__c = null,
		    Partner__c = loanRecord.Partner__r.Id,
		    Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
		    Status__c = null,
		    Amount__c = downPayment,
		    Type__c = 'Down payment',
		    Anticipated_Date__c = null,
		    Date_of_Disbursal__c = null
		);  
		return disbursal;  	
	}

    public List<Disbursal__c> calculateRemainingDisbursalValues (Loan__c loanRecord, Map<Id, Loan__c> newMap) {
    	List<Disbursal__c> disbursalRateList = new List<Disbursal__c>();
    	List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
    	Decimal disbursalSumRate = 0;
    	Decimal disbursalChangeMultiplier;    	
		Decimal dollarsLeftToDisburse = newMap.get(loanRecord.Id).Requested_Loan_Amount__c - loanRecord.Total_Funds_Disbursed__c;
		for (Disbursal__c disbursal : loanRecord.Disbursals__r) {
			if (disbursal.Status__c != 'Complete') {
				disbursalSumRate = disbursal.Disbursal_Percentage__c + disbursalSumRate;
				disbursalRateList.add(disbursal);
			}
		}
		disbursalChangeMultiplier = 1 / disbursalSumRate;
		for (Disbursal__c disbursal : disbursalRateList) {
			disbursal.Amount__c = dollarsLeftToDisburse * disbursalChangeMultiplier * disbursal.Disbursal_Percentage__c;
			disbursalsToUpdate.add(disbursal);
		}
		return disbursalsToUpdate;
	}	
}
//set field tracking history on amount of disbursal
//Total funds not yet disbursed roll up summary changed