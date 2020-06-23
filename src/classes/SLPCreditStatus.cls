/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: The SLPCreditStatus class serves as the controlle to the SLPCreditStatus Lightning Component bundle
 * It shows early stage leads ready for a credit check in the credit status tab. It also shows Pre-Qualified, Pending Review,
 * and Unqualified customers. It allows users to continue a customer's application from this tab.
 *
 Tested By: SLPControllerTestclass and PCRApprovalHandlerTest.testPreQualified (to test getCustomerProducts)
 *************************************************************************************/

public without sharing class SLPCreditStatus {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
      profile = SLPUserHelper.getPartnerProfile();
    }
  
    //The searchLeads method enables the user to search for customers on the credit status page
    @AuraEnabled 
    public static List<Lead> searchLeads (String searchValue, String leadId) {
        return getLeadsInternal(searchValue, null);
    }
  
    //The getLeads method loads the leads for the credit status page on doInIt and also submits the selected lead into the continue appliation stage.
    @AuraEnabled 
    public static List<Lead> getLeads (String searchValue, String leadId) {
        return getLeadsInternal(null, LeadId);
    }
  
    private static List<Lead> getLeadsInternal (String searchValue, String leadId) {
      List<Lead> leadList = new List<Lead>();
      String leadQuery = 'SELECT Id, Name, Firstname, LastName, Pre_Qualification_Status__c, Status, LASERCA__Home_Address__c, Update_Dummy__c, DOER_Solar_Loan__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, Requested_Loan_Amount__c, Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Email__c, Co_Applicant_Phone__c, Co_Applicant_Social_Security__c, Co_Applicant_Income__c, Co_Applicant_Address__c, Application_Type__c, CoApplicant_Contact__c, Joint_Applicant_Type__c, Co_Applicant_Date_of_Birth__c, Partner_Sent_Co_Signer_Link__c, Product__c, Product__r.Loan_Term__c, Product__r.Program__c' ;
      leadQuery += ' FROM Lead' ;
      leadQuery += ' WHERE Partner_Lookup__r.Id  =  \'' + profile.partnerId +  '\' ';
      leadQuery += ' AND Product_Line__c = \'' + 'Residential Loan' + '\' ' ;
  
      if (profile.licenseType != 'Executive' ) {
        //if the user is not an executive, only show that user's leads
        leadQuery += ' AND bs_Sales_ID__r.Id  =  \'' + profile.salesRepId +  '\' ';
      }    
      //if the user types in a name into the search bar, query for leads that contain the searched string.
      if (searchValue != null) {
        leadQuery += ' AND Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;          
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
        List<Lead> leadList = new List<Lead>();
  
        // If the lead is pre-qualified and has a Product, we want to add that product to the product list
        // even if it's deactivated.
        Lead lead = [SELECT Id, Product__c, Product__r.Name, Product__r.Product_Type__c, Product__r.Program__c, 
                     Product__r.Debt_To_Income_Maximum__c, Product__r.Credit_Minimum__c, Product__r.Credit_Maximum__c, 
                     Product__r.Loan_Interest_Rate__c, Product__r.Loan_Term__c, Product__r.State__c, 
                     Personal_Credit_Report__r.Avidia_Review_Status__c
                     FROM Lead 
                     WHERE Id = :leadId];
        Boolean addLeadsProduct = (lead.Personal_Credit_Report__r.Avidia_Review_Status__c == PCRApprovalHandler.REVIEWEDPREAPPROVED ||
                                   lead.Personal_Credit_Report__r.Avidia_Review_Status__c == PCRApprovalHandler.REVIEWEDAPPROVED);
      
        PCRApprovalHandler.CreditQualifyingMetrics creditMetric = PCRApprovalHandler.calculateCreditQualifyingMetrics(leadId);
        leadList.add(creditMetric.lead);
        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(leadList);
        List<Product2> allProducts = 
            productRepo.getApplicableProducts(creditMetric.lead, creditMetric.creditScore);
        for (Product2 prod : allProducts) {
            if (creditMetric.AdjustedDTI != null) {
                if (creditMetric.AdjustedDTI <= prod.Debt_To_Income_Maximum__c) {
                    productList.add(prod);
                    if (prod.Id == lead.Product__c) {
                        addLeadsProduct = false;
                    }
                }
            } else {
                if (productRepo.calcDTIAfter(prod, creditMetric.lead, 
                                             creditMetric.totalAnnualIncome/12, 
                                             creditMetric.totalMonthlyDebt).dtiAfter <= 
                    prod.Debt_To_Income_Maximum__c) {
                    productList.add(prod);
                    if (prod.Id == lead.Product__c) {
                        addLeadsProduct = false;
                    }
                }
            }
        }
        if (addLeadsProduct) {
            productList.add(lead.Product__r);
        }
                                      
        return productList;
    }
    
    @AuraEnabled 
    public static Product2 getSelectedProduct (String productId) {
      List<Product2> productList = [SELECT Id, Name, External_Name__c, Loan_Term__c, Program__c
                                    FROM Product2 
                                    WHERE Id = : productId]; 
      return productList[0];                      
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