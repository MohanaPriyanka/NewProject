public class DisbursalHandler {

    public class DisbursalStructure {      
    	public Integer disbursalCount;
    	public List<String> percentageList;
    	public List<String> nameList;
    	public List<String> typeList;
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
			System.debug('The substrings are ' + subString);
			disbursalStructure.disbursalCount = disbursalStructure.disbursalCount + 1;
			List<String> rate = subString.split('%');
			System.debug('The rate is ' + rate.get(0));
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
    	Decimal rate;
    	Integer i;
    	for (i=0; i <= disbursalStructure.disbursalCount; i++) {
    		rate = Decimal.valueOf(disbursalStructure.percentageList.get(i));
    		rate = rate/100;
			Disbursal__c disbursal = new Disbursal__c(
			    Name = disbursalStructure.nameList.get(i),
			    Unique_ID__c = loanRecord.Id + ' ' + disbursalStructure.nameList.get(i) + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
			    Loan__c = loanRecord.Id,
			    Disbursal_Sequence__c = i,
			    Disbursal_Percentage__c = rate,
			    Partner__c = loanRecord.Partner__r.Id,
			    Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
			    Status__c = 'Not yet disbursed',
			    Amount__c = loanRecord.Requested_Loan_Amount__c * rate,
			    Type__c = disbursalStructure.typeList.get(i),
			    Anticipated_Date__c = null,
			    Date_of_Disbursal__c = null
			);
			disbursalList.add(disbursal);
    	}
    	return disbursalList;
    }    
}