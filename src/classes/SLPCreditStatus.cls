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
    leadQuery += '  AND Product_Line__c = \'' + 'Residential Loan' + '\' ' ;
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
    String leadQuery = 'SELECT Id, Name, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c, DOER_Solar_Loan__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, Requested_Loan_Amount__c' ;
    leadQuery += ' FROM Lead' ;
    leadQuery += ' WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';
    leadQuery += ' AND Product_Line__c = \'' + 'Residential Loan' + '\' ' ;

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
    List<Product2> productList = new List<Product2>();
    PCRApprovalHandler.CreditQualifyingMetrics creditMetric = PCRApprovalHandler.calculateCreditQualifyingMetrics(leadId);
    PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(creditMetric.leadList);
    List<Product2> allProducts = 
        productRepo.getApplicableProducts(creditMetric.leadList[0], creditMetric.creditScore);
    for (Product2 prod : allProducts) {
        if (productRepo.calcDTIAfter(prod, creditMetric.leadList[0], 
                                     creditMetric.totalAnnualIncome/12, 
                                     creditMetric.totalMonthlyDebt).dtiAfter <= 
            prod.Debt_To_Income_Maximum__c) {
            productList.add(prod);
        }
    }
    return productList;
  }
  
  @AuraEnabled 
  public static Product2 getSelectedProduct (String productId) {
    List<Product2> productList = [SELECT Id, Name, ProductCode, Loan_Term__c, Program__c 
                                  FROM Product2 
                                  WHERE Id = : productId]; 
    return productList[0];                      
  }

  @AuraEnabled 
  public static String sendApplication (String leadId, Product2 product, Integer loanTerm) {
    String continueApplicationUrl;
    String customerName;
    Boolean updateDummy;
    Lead lead = [SELECT Id, Name, Product_Line__c, Product_Program__c, LASERCA__Home_State__c, LASER_Credit_Score__c, LASERCA__Home_Address__c,
                        LASERCA__Home_City__c, LASERCA__Home_Zip__c, Annual_Income_Currency__c, Requested_Loan_Amount__c, Update_Dummy__c, FirstName,
                        LastName, Partner_Email__c, Email, Partner_Lookup__r.Name
                        FROM Lead
                        WHERE Id = : leadId
                        LIMIT 1];  
    customerName = lead.FirstName + ' ' + lead.LastName + ' - ' + lead.Email;                        
    EmailTemplate template = [SELECT Id, HtmlValue, Body 
                              FROM EmailTemplate 
                              WHERE DeveloperName = 'RS_SLP_Customer_Continue_Application'];

    if (lead.Update_Dummy__c == true){
        updateDummy = false;
    } else{
        updateDummy = true;
    }                     
    if (product.Program__c == 'BlueWave Solar Loan') {
      continueApplicationUrl = 'https://forms.bluewaverenewables.com/381610?' + 'tfa_1311=' + lead.LASERCA__Home_Address__c 
                                + '&' + 'tfa_154=' + lead.LASERCA__Home_State__c
                                + '&' + 'tfa_526=' + lead.Id 
                                + '&' + 'tfa_1180=' + updateDummy
                                + '&' + 'tfa_390=' + lead.Annual_Income_Currency__c 
                                + '&' + 'tfa_1312=' + lead.LASERCA__Home_City__c 
                                + '&' + 'tfa_1179=' + product.Id 
                                + '&' + 'tfa_1313=' + lead.LASERCA__Home_Zip__c     
                                + '&' + 'tfa_1287=' + loanTerm     
                                + '&' + 'tfa_1375=' + 'SLPortal - Emailed Customer Phase 2 Application 381610'     
                                + '&' + 'tfa_1372=' + lead.FirstName     
                                + '&' + 'tfa_1373=' + lead.LastName;       
    } else if (product.Program__c == 'MSLP') {
      continueApplicationUrl = 'https://forms.bluewaverenewables.com/' + '381607' + '?tfa_572=Individually' 
                                + '&' + 'tfa_154=Massachusetts&tfa_526=' + lead.Id 
                                + '&' + 'tfa_1180=' + updateDummy
                                + '&' + 'tfa_390=' + lead.Annual_Income_Currency__c 
                                + '&' + 'tfa_63=' + lead.LASERCA__Home_City__c 
                                + '&' + 'tfa_1179=' + product.Id 
                                + '&' + 'tfa_81=' + lead.LASERCA__Home_Zip__c     
                                + '&' + 'tfa_1287=' + loanTerm     
                                + '&' + 'tfa_1181=true'    
                                + '&' + 'tfa_1310=' + 'SLPortal - Emailed Customer Phase 2 Application 381607'                                     
                                + '&' + 'tfa_94=' + lead.LASERCA__Home_Address__c ;        
    }     
    String htmlBody = template.HtmlValue;
    htmlBody = htmlBody.replace('{!Lead.Name}', lead.Name);
    htmlBody = htmlBody.replace('{!continueApplication}', continueApplicationUrl);
    htmlBody = htmlBody.replace('{!partnerName}', lead.Partner_Lookup__r.Name);

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setHtmlBody(htmlBody);
    for (OrgWideEmailAddress senderEmail : [SELECT Id, Address 
                                       FROM OrgWideEmailAddress
                                       WHERE Address = 'customercare@bluewavesolar.com' 
                                       LIMIT 1]) {
      mail.setOrgWideEmailAddressId(senderEmail.Id); 
    }
    if (lead.Partner_Email__c != null){
      String partnerEmail = lead.Partner_Email__c;
      String[] copiedEmailAddresses = new String[] {partneremail};
      mail.setccAddresses(copiedEmailAddresses);
    }    
    String emailSubject = 'BlueWave Solar Loan - ' +  lead.FirstName + ' ' + lead.LastName + ' - Continue your application here'; 
    mail.setSubject(emailSubject);
    mail.setTargetObjectId(lead.Id);
    MessagingService.sendEmail(new Messaging.SingleEmailMessage[] {mail});    
    return customerName;
  }

  @AuraEnabled 
  public static void viewPreQualifiedRecords () {
    List<Lead> leadsNotViewedByAdminList = new List<Lead>();
    List<Lead> leadsNotViewedByAgentList = new List<Lead>();

    String leadQuery = 'SELECT Id, Viewed_by_Partner_Admin__c, Viewed_by_Partner_Agent__c' ;
    leadQuery += '   FROM Lead' ;    
    leadQuery += '   WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';
    leadQuery += '   AND Product_Line__c = \'' + 'Residential Loan' + '\' ';
    if (profile.LicenseType != 'Executive') {
      leadQuery += '    AND bs_Sales_ID__r.Id  =  \'' + profile.salesRepId +  '\' ';            
    }
    for(Lead leadRecord : Database.query(leadQuery)){
      if (!leadRecord.Viewed_by_Partner_Admin__c) {
        leadsNotViewedByAdminList.add(leadRecord);
      } 
      if (!leadRecord.Viewed_by_Partner_Agent__c) {
        leadsNotViewedByAgentList.add(leadRecord);
      }       
    } 
    if (profile.LicenseType == 'Executive') {
      for (Lead leadRecord : leadsNotViewedByAdminList) {
        leadRecord.Viewed_by_Partner_Admin__c = true;
      }
      update leadsNotViewedByAdminList;      
    }
    if (profile.LicenseType == 'User') {
      for (Lead leadRecord : leadsNotViewedByAgentList) {
        leadRecord.Viewed_by_Partner_Agent__c = true;
      }
      update leadsNotViewedByAgentList;
    }               
  }   
}