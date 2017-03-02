public class SLPCreditStatus {
  @AuraEnabled 
  public static List<Lead> getLeads (String searchValue, String leadId) {
    System.debug('Begin the getLeads method');
    User u = [SELECT Id, Name, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
    //if(searchValue == null || searchValue == ''){
      if(leadId == null){
      	List<Lead> leadList = [SELECT Id, Name, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c
                    		FROM Lead 
                    		WHERE Partner_Lookup__r.Name = 'BlueWave Customer Care'
                    		AND Status = 'Unfinished'
                    		ORDER BY Pre_Qualification_Status__c];      
    	return leadList;            	
      }else{
      	List<Lead> leadList = [SELECT Id, Name, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c,
      									LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, System_Cost__c
                    		FROM Lead                     		
                    		WHERE Id = : leadId
                    		AND Status = 'Unfinished'];      
    	return leadList;       	
      }	

  //  }

  //  else {
  //    List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, 
  //                  Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode,
  //                  (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = 'Pending' LIMIT 1)  
  //                  FROM Loan__c 
  //                  WHERE Name LIKE : '%'+searchValue+'%'
  //                  AND Partner__r.Name = 'BlueWave Customer Care'];
  //  return loanList;                               
  //  }
  //}
	}
}