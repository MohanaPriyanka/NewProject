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
     * Tested By: SLPControllersTestclass
     *************************************************************************************/
        public class LoanRecords {
            @AuraEnabled
            public Loan__c[] loansInProcess { get; set; }
            @AuraEnabled
            public Loan__c[] completedLoans { get; set; }
            @AuraEnabled
            public Loan__c[] expiredApplicants { get; set; }
            public LoanRecords() {
                loansInProcess = new List<Loan__c>();
                completedLoans = new List<Loan__c>();
                expiredApplicants = new List<Loan__c>();
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
    }