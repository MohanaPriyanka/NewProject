public class PartnerAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public PartnerAssignmentHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void onBeforeInsertOrUpdate(List<Lead> newLeads){
        assignPartnerToLead(newLeads);     
        System.debug('Partner Assignment Begin Execution');  
    }    
    
    public void assignPartnerToLead(List<Lead> leadList){
    	List<String> leadReferralCodeList = new List<String>();
    	List<Id> leadIdList = new List<Id>();

    	Map<String, BSST__c> partnerMap = new Map<String, BSST__c>();
    	for (Lead l : LeadList){
    		if(l.Custom_ID__c != null){
    			leadIdList.add(l.Id);
    		}
    	}
    	if(leadIdList.size()>0){
	    	for(lead l : [SELECT Id, Name, Custom_Id__c, Bs_sales_id__c, Partner_Email__c
	    					FROM Lead
	    					WHERE Id IN : leadIdList]){
	    		leadReferralCodeList.add(l.Custom_Id__c);
	    	}
	    	for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c 
	    							FROM BSST__c 
	    							WHERE Custom_Id__c IN : leadReferralCodeList]){
	    		partnerMap.put(partner.Custom_Id__c, partner);
	    	}
			System.debug('PartnerMap ' + partnerMap);     	
	    	if(partnerMap.size()>0){
	    		for(lead l : leadList){
	    			l.Partner_Lookup__c = partnerMap.get(l.Custom_Id__c).Partner__r.Id;
	    			l.Bs_sales_id__c = partnerMap.get(l.Custom_Id__c).Id;
	    			l.Partner_Email__c = partnerMap.get(l.Custom_Id__c).Email__c;
	    		}    		
	    	}
    	}
    }
}