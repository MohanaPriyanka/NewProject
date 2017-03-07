public without sharing class SLPCreditStatus {
  @AuraEnabled 
  public static List<Lead> searchleads (String searchValue, String leadId) {
    System.debug('Begin the getLeads method');
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '') {
      partnerId = SLPUserHelper.getBWCCId();
    }
 
    if(searchValue == null || searchValue == ''){
      	List<Lead> leadList = [SELECT Id, Name, Firstname, LastName, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, DOER_Solar_Loan__c
                    		FROM Lead 
                    		WHERE Partner_Lookup__r.Id = : partnerId
                        AND (Status = 'Unfinished' 
                          OR Status = 'Ready for Credit Check' 
                          OR Status = 'Pre-Qualified')
                    		ORDER BY Status ASC, createdDate DESC, Name DESC];      
    	return leadList;            	
      }else{
      	List<Lead> leadList = [SELECT Id, Name, Firstname, LastName, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c,
      									LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, System_Cost__c, DOER_Solar_Loan__c
                    		FROM Lead                     		
                    		WHERE Name LIKE : '%'+searchValue+'%'
                        AND Partner_Lookup__r.Id = : partnerId                        
                    		AND (Status = 'Unfinished' 
                          OR Status = 'Ready for Credit Check' 
                          OR Status = 'Pre-Qualified')
                        ORDER BY Status ASC, createdDate DESC, Name DESC];      
    	return leadList;       	
      }	
  }

  @AuraEnabled 
  public static List<Lead> getLeads (String searchValue, String leadId) {
    System.debug('Begin the getLeads method');
    String partnerId = SLPUserHelper.getPartnerId(); 
    Partner__c partnerRecord;

    if (partnerId == null || partnerId == '') {
      partnerId = SLPUserHelper.getBWCCId();
    }
   
    //if(searchValue == null || searchValue == ''){
      if(leadId == null){
        List<Lead> leadList = [SELECT Id, Name, Firstname, LastName, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, DOER_Solar_Loan__c
                        FROM Lead 
                        WHERE Partner_Lookup__c = : partnerId
                        AND (Status = 'Unfinished' OR Status = 'Ready for Credit Check' OR Status = 'Pre-Qualified')
                        ORDER BY Status ASC, createdDate DESC, Name DESC];      
      return leadList;              
      }else{
        List<Lead> leadList = [SELECT Id, Name, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c, DOER_Solar_Loan__c,
                        LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, System_Cost__c
                        FROM Lead                         
                        WHERE Id = : leadId
                        AND (Status = 'Unfinished' 
                          OR Status = 'Ready for Credit Check' 
                          OR Status = 'Pre-Qualified')];      
      return leadList;         
      }  
  }

  @AuraEnabled 
  public static List<Product2> getCustomerProducts (String leadId) {
    System.debug('Begin the getProducts method');
    Lead leadRecord = [SELECT Id, Product_Line__c, Product_Program__c, LASERCA__Home_State__c, LASER_Credit_Score__c 
                        FROM Lead
                        WHERE Id = : leadId];

    List<Product2> productList = [SELECT Id, Name, ProductCode, Loan_Term__c, Program__c   
                                  FROM Product2 
                                  WHERE Product_Type__c = : leadRecord.Product_Line__c
                                  AND Program__c = : leadRecord.Product_Program__c
                                  AND State__c = : leadRecord.LASERCA__Home_State__c
                                  AND Credit_Minimum__c <= : leadRecord.LASER_Credit_Score__c
                                  AND Credit_Maximum__c >= : leadRecord.LASER_Credit_Score__c
                                  AND isActive = true]; 
      return productList;                      
	}

  @AuraEnabled 
  public static Product2 getSelectedProduct (String productId) {
    System.debug('Begin the getProducts method');

    List<Product2> productList = [SELECT Id, Name, ProductCode, Loan_Term__c, Program__c 
                                  FROM Product2 
                                  WHERE Id = : productId]; 
      return productList[0];                      
  }  

  @AuraEnabled 
  public static String getFormAssemblyIds (String productProgram, String formType) {
    System.debug('Begin the getFormAssemblyIds method');
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    Map<String, String> formIdsMap = new Map<String, String>();
    String formMapKey = productProgram + ' ' + formType;
    if (systemProperties.size() > 0) {
      if (systemProperties[0].SLP_Continue_Application_Standard__c != null) {
          formIdsMap.put('BlueWave Solar Loan Continue Application', systemProperties[0].SLP_Continue_Application_Standard__c);
      }   
      if (systemProperties[0].SLP_Continue_Application_MSLP__c != null) {
          formIdsMap.put('MSLP Continue Application', systemProperties[0].SLP_Continue_Application_MSLP__c);
      }           
    }  
    return formIdsMap.get(formMapKey);    
  }
}
