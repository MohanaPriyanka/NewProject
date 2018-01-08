/*************************************************************************************
 * Created By:  Joey Chan 
 * Description: Customer Application Portal controller for the public communities
 * Test: CAPControllerTest
 *************************************************************************************/
public without sharing class CAPController {
    @AuraEnabled
    public static Lead getLead(Id leadId, String email) {
        Lead lead;
        List<Lead> leadList  = [
                SELECT Id, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                        Requested_Loan_Amount__c, System_Cost__c, LASERCA__SSN__c, Annual_Income_Currency__c, Status,
                        Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                        LASERCA__Pull_Credit_Report__c, CAP_Stage__c, Monthly_Mortgage_Tax_and_Insurance__c, IBLS_Category__c,
                        LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c,
                        Residence_Owner__c, Lived_residence_six_months__c, Other_Bank_Executive__c, Application_Type__c, Joint_Applicant_Type__c,
                        Type_of_Avidia_Service_Provider__c, Avidia_Service_Provider__c, DOER_Solar_Loan__c, Year_Employment__c,
                        Monthly_Income__c, Monthly_Income_2__c, Monthly_Income_Details__c, Monthly_Income_Details_2__c, Product_Program__c,
                        Electronic_Disbursal_Authorized__c, Pre_Approval_Form__c,
                        Product__c, Product__r.Lender_of_Record__c,
                        CoApplicant_Contact__c, CoApplicant_Contact__r.FirstName, CoApplicant_Contact__r.LastName,
                        CoApplicant_Contact__r.LASERCA__Home_Address__c, CoApplicant_Contact__r.Year_Employment__c,
                        CoApplicant_Contact__r.LASERCA__Home_City__c, CoApplicant_Contact__r.LASERCA__Home_State__c,
                        CoApplicant_Contact__r.LASERCA__Home_Zip__c, CoApplicant_Contact__r.LASERCA__Co_Applicant_DOB__c,
                        CoApplicant_Contact__r.Income__c, CoApplicant_Contact__r.Phone, CoApplicant_Contact__r.Email,
                        CoApplicant_Contact__r.LASERCA__Social_Security_Number__c,
                        CoApplicant_Contact__r.Credit_Check_Acknowledged__c,
                        CoApplicant_Contact__r.Privacy_Policy_Acknowledged__c,
                        CoApplicant_Contact__r.Other_Bank_Executive__c, CoApplicant_Contact__r.Avidia_Service_Provider__c,
                        CoApplicant_Contact__r.Type_of_Avidia_Service_Provider__c,
                        Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Phone__c, Co_Applicant_Email__c,
                        Co_Applicant_Date_of_Birth__c, Co_App_Monthly_Mortgage__c,
                        Co_Applicant_Income__c, LASERCA__Co_Applicant_Social_Security_Number__c,
                        Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                        SREC_Product__r.Name, Project_Identification_Number__c, License_Number_Encrypted__c, State_of_Issuance__c,
                        Date_of_Issuance__c, Date_of_Expiration__c,
                (SELECT Id, Name, Description from Attachments)
                FROM Lead
                WHERE Id = :leadId
                AND Email = :email LIMIT 1];
        if (leadList.size() > 0) {
            lead = leadList[0];
        }
        return lead;
    }

    @AuraEnabled
    public static void setAppType(Lead capLead) {
        Lead dbLead = getLead(capLead.Id, capLead.email);
        if (dbLead == null) {
            throw new Util.BWException('Invalid lead');
        }

        Lead updateLead = new Lead(Id = capLead.Id,
            Application_Type__c = capLead.Application_Type__c);
        if (capLead.Application_Type__c == 'Joint') {
            if (dbLead.Personal_Credit_Report__c != null ||
                dbLead.Status == 'Pending Credit Review' ||
                dbLead.Status == 'Unqualified') {
                updateLead.Joint_Applicant_Type__c = 'Co-Signer';
            } else {
                updateLead.Joint_Applicant_Type__c = 'Co-Applicant';
            }
        } else {
            updateLead.CoApplicant_Contact__c = null;
            updateLead.Joint_Applicant_Type__c = null;
            updateLead.Co_Applicant_First_Name__c = null;
            updateLead.Co_Applicant_Last_Name__c = null;
            updateLead.Co_Applicant_Phone__c = null;
            updateLead.Co_Applicant_Email__c = null;
            updateLead.Co_Applicant_Date_of_Birth__c = null;
            updateLead.Co_Applicant_Income__c = null;
            updateLead.Co_Applicant_Address__c = null;
            updateLead.Co_Applicant_Income__c = null;

        }
        update updateLead;
    }

    // The Credit Check methods are copied from SLPAddCustomer to make it easier to retire that class
    @AuraEnabled
    public static Integer getCreditCheckTimeout() {
        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.size() > 0 &&
            systemProperties[0].Credit_Check_Timeout__c != null) {
            return(Integer.valueOf(systemProperties[0].Credit_Check_Timeout__c));
        } else {
            return(60000);
        }
    }

    // We don't want to pull credit on applicants twice, so query first and only pull credit if
    // there's no credit report. Customer Care can always pull credit through the UI if needed
    @AuraEnabled
    public static void pullCreditStatus(Lead lead) {
        Lead l = [SELECT Id, Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c, CoApplicant_Contact__c,
            Date_of_Application__c
                  FROM Lead
                  WHERE Id =: lead.Id];
        boolean forceUpdate = false;
        if (l.Date_of_Application__c == null) {
            lead.Date_of_Application__c = System.now().format('YYYY-MM-DD-hh:mm');
        }
        if (l != null && l.Personal_Credit_Report__c == null) {
            lead.LASERCA__Pull_Credit_Report__c = true;
        }
        if (l.Date_of_Application__c == null ||
            (l != null && l.Personal_Credit_Report__c == null)) {
            update lead;
        }
        if (l != null && l.CoApplicant_Contact__c != null && l.Personal_Credit_Report_Co_Applicant__c == null) {
            Contact c = new Contact(Id = l.CoApplicant_Contact__c,
                                    LASERCA__Pull_Credit_Report__c = true);
            update c;
        }
    }

    @AuraEnabled
    public static String checkCreditStatus(Lead leadToQuery) {
        Lead lead = [SELECT Id, Status, Application_Type__c, LASTMODIFIEDDATE, CoApplicant_Contact__c,
                     (SELECT id, LASERCA__Error_Message__c, CREATEDDATE
                      FROM LASERCA__Credit_Report_Logs__r
                      ORDER BY CREATEDDATE DESC),
                     (SELECT id, Solar_Loan_Approval_Status__c
                      FROM LASERCA__Personal_Credit_Reports__r
                      ORDER BY CREATEDDATE)
                     FROM Lead
                     WHERE Id = :leadToQuery.Id];
        if (lead.Application_Type__c == 'Individual') {
            if (!lead.LASERCA__Personal_Credit_Reports__r.isEmpty()) {
                // If a PCR was successfully created, the Status will be updated on the Lead
                return(lead.Status);
            } else {
                // There's no PCR; if there are credit report logs, send the credit report log error
                if (getCreditErrors(lead.LASERCA__Credit_Report_Logs__r, lead.LastModifiedDate) != null) {
                    return getCreditErrors(lead.LASERCA__Credit_Report_Logs__r, lead.LastModifiedDate);
                }
            }
        } else if (lead.Application_Type__c == 'Joint' && lead.CoApplicant_Contact__c != null) {
            if (lead.LASERCA__Personal_Credit_Reports__r.size() >= 2) {
                // If a PCR was successfully created, the Status will be updated on the Lead
                return(lead.Status);
            } else {
                // There's one or zero PCRs, and there could be zero, one, or two CRLs with an error.
                String reportError = '';
                if (getCreditErrors(lead.LASERCA__Credit_Report_Logs__r, lead.LastModifiedDate) != null) {
                    reportError += getCreditErrors(lead.LASERCA__Credit_Report_Logs__r, lead.LastModifiedDate);
                }
                // We can't select co-app crls from the lead query, so we need to query the co-app contact directly.
                Contact coApp = [
                    SELECT Id, LastModifiedDate, (
                        SELECT Id, LASERCA__Error_Message__c, CREATEDDATE
                        FROM LASERCA__Credit_Report_Logs__r
                        ORDER BY CREATEDDATE DESC), (
                        SELECT id, Solar_Loan_Approval_Status__c
                        FROM LASERCA__Personal_Credit_Reports__r
                        ORDER BY CREATEDDATE DESC LIMIT 1)
                    FROM Contact
                    WHERE Id =: lead.CoApplicant_Contact__c];
                if (getCreditErrors(coApp.LASERCA__Credit_Report_Logs__r, coApp.LastModifiedDate) != null) {
                    reportError += getCreditErrors(coApp.LASERCA__Credit_Report_Logs__r, coApp.LastModifiedDate);
                }
                if (reportError != '') {
                    return reportError;
                }
                // There's no errors, but the reports aren't done yet. Instead of returning the lead status,
                // which might be "Unqualified" if this were an Individual running a check on the Co-Signer,
                // return 'Ready for Credit Check'
                return 'Ready for Credit Check';
            }
        }
        return(lead.Status);
    }

    // Since an installer can run credit multiple times on an applicant (if there was an error),
    // there might be multiple CRLs, some or all of which might be for previous credit checks.

    // Assuming the credit check is run based on checking the "Pull Credit Check" checkbox, we
    // can use the Lead.LASTMODIFIEDDATE to find the relevant CRL.
    private static String getCreditErrors(List<LASERCA__Credit_Report_Log__c> crls, Datetime lastModifiedDate) {
        for (LASERCA__Credit_Report_Log__c crl : crls) {
            if (crl.CREATEDDATE > lastModifiedDate) {
                return(parseError(crl.LASERCA__Error_Message__c.split('\\n')[0]));
            }
        }
        return null;
    }

    // We often get errors in this format, if so, we can parse out the error text (everything after the first dash)
    //   ERROR: E999 - CreditBureau - Invalid borrower first name
    @testVisible
    private static String parseError(String s) {
        if (Pattern.matches('^ERROR: [A-Z]\\d* - .*$', s)) {
            return(s.right(s.length() - s.indexOf(' - ') - 3));
        } else {
            return(s);
        }
    }

    @AuraEnabled 
    public static List<Product2> getCustomerProducts(String leadid) {
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
    public static List<Product2> getProducts(String state, String productType) {
        return Util.getActiveProducts(new List<String>{state}, null, productType);
    }

    @AuraEnabled
    public static String getLenderOfRecord(String state) {
        List<AggregateResult> products = [SELECT Lender_of_Record__c
        FROM Product2
        WHERE IsActive = true
        AND Product_Type__c = 'Residential Loan'
        AND State__c = : state
        GROUP BY Lender_of_Record__c
        ORDER BY Lender_of_Record__c];
        String result = '';
        for (AggregateResult p : products) {
            result += (String) p.get('Lender_of_Record__c');
        }
        return result;
    }
}