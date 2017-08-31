public without sharing class SLPAllCustomersHandler {
/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 *
 * Description: The SLPAllCustomerHandler class services the SLP Customer
 * tab and customer window. For the most part, it returns data for
 * display; however it also allows the user to update system information
 * and loan information. It returns disubrsal information, updates disbursals 
 * as confirmed and returns equipment information.
 *
 * Tested By: 
 *************************************************************************************/

  public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
  static {
    profile = SLPUserHelper.getPartnerProfile();
  }

  @AuraEnabled
  public static String getLicenseType() {
      return profile.LicenseType;
  }

 //The getAllCustomers method returns a list of loans to the SLPCustomer lightning component to show up in the customers tab
  @AuraEnabled
  public static List<Loan__c> getAllCustomers (String searchValue) {
    List<Loan__c> loanList = new List<Loan__c>();
    String loanQuery = 'SELECT Id, Name, Requested_Loan_Amount__c, Total_Funds_Disbursed__c, Sales_Agent__r.Name,' + 
    					         'Product__r.ProductCode, Sales_Agent__r.Id, Lead__r.Date_of_Application_2__c, (SELECT Id, Name FROM Partner_Tasks__r WHERE Status__c = \'' + 'Pending' + '\' LIMIT 1)' ;
    loanQuery += '      FROM Loan__c' ;
    loanQuery += '      WHERE Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
    if (profile.LicenseType != 'Executive') {
      loanQuery += '    AND Sales_Agent__r.Id  =  \'' + profile.salesRepId +  '\' ';
    }
    if (searchValue != null) {
      loanQuery += '    AND Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;
    }
    loanQuery += '      ORDER BY createdDate DESC';
    loanQuery += '      LIMIT 5';
    for(Loan__c loanRecord : Database.query(loanQuery)){
      loanList.add(loanRecord);
    }
    return loanList;
  }
}