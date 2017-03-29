/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: The SLPCreditStatus class serves as the controlle to the SLPCreditStatus Lightning Component bundle
 * It shows early stage leads ready for a credit check in the credit status tab. It also shows Pre-Qualified, Pending Review,
 * and Unqualified customers. It allows users to continue a customer's application from this tab.
 *
 Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPCreditStatus {
  public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
  static {
    profile = SLPUserHelper.getPartnerProfile();
  }

  //The searchLeads method enables the user to search for customers on the credit status page
  @AuraEnabled 
  public static List<Lead> searchLeads (String searchValue, String leadId) {
    List<Lead> leadList = new List<Lead>();
    String leadQuery = 'SELECT Id, Name, Firstname, LastName, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, DOER_Solar_Loan__c' ;
    leadQuery += ' FROM Lead' ; 
    leadQuery += ' WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';
    leadQuery += '  AND (Status = \'' + 'Unfinished' + '\' ' ;
    leadQuery += '  OR Status = \'' + 'Ready for Credit Check' + '\' ';
    leadQuery += '  OR Status = \'' + 'Pre-Qualified' + '\' ' ;
    leadQuery += '  OR Status = \'' + 'Pending Credit Review' + '\' ';
    leadQuery += '  OR Status = \'' + 'Unqualified' + '\' ' ;
    leadQuery += '  OR Status = \'' + 'Ready for Credit Check' + '\' )';
    //if the user is not an executive, only show that user's leads
    if (profile.licenseType != 'Executive') {
      leadQuery += ' AND bs_Sales_ID__r.Id =  \'' + profile.salesRepId +  '\' ';
    }
    //if the user types in a name into the search bar, query for leads that contain the searched string.
    if (searchValue != null) {
      leadQuery += ' AND Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;          
    }                
    leadQuery += ' ORDER BY Status ASC, createdDate DESC, Name DESC'; 
    
    for(Lead leadRecord : Database.query(leadQuery)){
      leadList.add(leadRecord);
    }
    return leadList;         	   	      	
  }

  //The getLeads method loads the leads for the credit status page on doInIt and also submits the selected lead into the continue appliation stage.
  @AuraEnabled 
  public static List<Lead> getLeads (String searchValue, String leadId) {
    List<Lead> leadList = new List<Lead>();
    String leadQuery = 'SELECT Id, Name, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c, DOER_Solar_Loan__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, System_Cost__c' ;
    leadQuery += ' FROM Lead' ;
    leadQuery += ' WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';

    if (profile.licenseType != 'Executive' ) {
      //if the user is not an executive, only show that user's leads
      leadQuery += ' AND bs_Sales_ID__r.Id  =  \'' + profile.salesRepId +  '\' ';
    }    
    if (leadId == null) {
      //If no lead is selected show all of the leads
      leadQuery += '  AND (Status = \'' + 'Unfinished' + '\' ' ;
      leadQuery += '  OR Status = \'' + 'Ready for Credit Check' + '\' ';
      leadQuery += '  OR Status = \'' + 'Pre-Qualified' + '\' ' ;
      leadQuery += '  OR Status = \'' + 'Pending Credit Review' + '\' ';
      leadQuery += '  OR Status = \'' + 'Not Interested' + '\' ';
      leadQuery += '  OR Status = \'' + 'Unqualified' + '\' ' ;
      leadQuery += '  OR Status = \'' + 'Ready for Credit Check' + '\' )';
    } else {
      //if a lead is selected, query for that lead
      leadQuery += ' AND Id  =  \'' + leadId +  '\' ';      
    }
    leadQuery += ' ORDER BY Status ASC, createdDate DESC, Name DESC'; 
    for(Lead leadRecord : Database.query(leadQuery)){
      leadList.add(leadRecord);
    }
    return leadList; 
  }     

  @AuraEnabled 
  public static List<Product2> getCustomerProducts (String leadId) {
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
    List<Product2> productList = [SELECT Id, Name, ProductCode, Loan_Term__c, Program__c 
                                  FROM Product2 
                                  WHERE Id = : productId]; 
      return productList[0];                      
  }  
}