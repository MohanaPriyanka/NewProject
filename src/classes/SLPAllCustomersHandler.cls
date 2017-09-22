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

  public class LoanRecords {      
    @AuraEnabled
    public Loan__c[] allLoans {get;set;}

    @AuraEnabled
    public Loan__c[] loansInProcess {get;set;}

    @AuraEnabled
    public Loan__c[] completedLoans {get;set;}    


    public LoanRecords() { 
      allLoans = new List<Loan__c>();
      loansInProcess = new List<Loan__c>();    
      completedLoans = new List<Loan__c>();                                   
    }       
  }

  public class LeadRecords {      
    @AuraEnabled
    public Lead[] allLeads {get;set;}

    @AuraEnabled
    public Lead[] pendingApplications {get;set;}

    @AuraEnabled
    public Lead[] declinedApplicants {get;set;}    


    public LeadRecords() { 
      allLeads = new List<Lead>();
      pendingApplications = new List<Lead>();    
      declinedApplicants = new List<Lead>();                                   
    }       
  }



 //The getAllCustomers method returns a list of loans to the SLPCustomer lightning component to show up in the customers tab
  @AuraEnabled
  public static LoanRecords getAllCustomers () {
    LoanRecords LoanRecords = new LoanRecords();
    List<Loan__c> loanList = new List<Loan__c>();
    String loanQuery = 'SELECT Id, Name, Requested_Loan_Amount__c, createdDate, Total_Funds_Disbursed__c, Sales_Agent__r.Name,' + 
    					         'Product__r.ProductCode, Sales_Agent__r.Id, Lead__r.Date_of_Application_2__c, (SELECT Id, Name, Owner__c FROM Partner_Tasks__r WHERE Status__c = \'' + 'Pending' + '\' LIMIT 1)' ;
    loanQuery += '      FROM Loan__c' ;
    loanQuery += '      WHERE Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
    if (profile.LicenseType != 'Executive') {
      loanQuery += '    AND Sales_Agent__r.Id  =  \'' + profile.salesRepId +  '\' ';
    }
    loanQuery += '      ORDER BY createdDate DESC';
    loanQuery += '      LIMIT 10';
    for(Loan__c loanRecord : Database.query(loanQuery)){
      loanList.add(loanRecord);
    }

    for (Loan__c loan : loanList) {
      if (loan.Partner_Tasks__r.size() == 0) {
        LoanRecords.completedLoans.add(loan);
      } else {
        LoanRecords.loansInProcess.add(loan);
      }
      LoanRecords.allLoans.add(loan);
    }
    return LoanRecords;
  }

  //The getLeads method loads the leads for the credit status page on doInIt and also submits the selected lead into the continue appliation stage.
  @AuraEnabled 
  public static LeadRecords getLeads (String leadId) {
    LeadRecords LeadRecords = new LeadRecords();
    List<Lead> leadList = new List<Lead>();
    String leadQuery = 'SELECT Id, Name, Firstname, createdDate, LastName, Pre_Qualification_Status__c, System_Cost__c, Status, LASERCA__Home_Address__c, Update_Dummy__c, DOER_Solar_Loan__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Email, Annual_Income_Currency__c, Requested_Loan_Amount__c, Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Email__c, Co_Applicant_Phone__c, Co_Applicant_Social_Security__c, Co_Applicant_Income__c, Co_Applicant_Address__c, Application_Type__c, CoApplicant_Contact__c, Joint_Applicant_Type__c, Co_Applicant_Date_of_Birth__c, Partner_Sent_Co_Signer_Link__c' ;
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
      leadQuery += '  AND Id  =  \'' + leadId +  '\' ';      
    }
    leadQuery += '    ORDER BY createdDate DESC, Name DESC'; 
    //leadQuery += '    LIMIT 10';
    for(Lead leadRecord : Database.query(leadQuery)){
      leadList.add(leadRecord);
    }

    for (Lead lead : leadList) {
      if (Lead.Status == 'Unqualified') {
        LeadRecords.declinedApplicants.add(lead);
      } else {
        LeadRecords.pendingApplications.add(lead);
      }
      LeadRecords.allLeads.add(lead);
    }
    return LeadRecords;
  }    
} 