/*************************************************************************************
 * Created By:  Joey Chan 
 * Description: Customer Application Portal controller for the public communities
 * Test: CAPControllerTest
 *************************************************************************************/
public without sharing class CAPController {
    @AuraEnabled
    public static Lead getLead(Id leadId, String email) {
        return getLeadWrapper(leadId, email).lead;
    }

    @AuraEnabled
    public static LeadWrapper getLeadWrapper(Id leadId, String email) {
        Lead lead;
        List<Lead> leadList  = [
                SELECT Id, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode, MobilePhone,
                        Requested_Loan_Amount__c, System_Cost__c, LASERCA__SSN__c, Annual_Income_Currency__c, Status,
                        Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                        LASERCA__Pull_Credit_Report__c, CAP_Stage__c, Monthly_Mortgage_Tax_and_Insurance__c, IBLS_Category__c,
                        LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Update_Dummy__c,
                        Residence_Owner__c, Not_Residence_Owner__c, lived_residence_six_months__c, Other_Bank_Executive__c, Application_Type__c, Joint_Applicant_Type__c,
                        Type_of_Avidia_Service_Provider__c, Avidia_Service_Provider__c, DOER_Solar_Loan__c, Year_Employment__c,
                        Monthly_Income__c, Monthly_Income_2__c, Monthly_Income_Details__c, Monthly_Income_Details_2__c, Product_Program__c,
                        Employed_less_than_a_year__c, Retired__c, Not_Retired__c, Not_Self_Employed__c, Self_Employed__c, No_Veteran_Disability__c, Veteran_Disability__c,
                        Employed__c, Not_Employed__c, Electronic_Disbursal_Authorized__c, Express_Consent__c,
                        Product__c, Product__r.Lender_of_Record__c, Reliant_on_Alimony_Child_Support_Other__c, Not_Reliant_on_Alimony_Child_Support_Oth__c,
                        CoApplicant_Contact__c, CoApplicant_Contact__r.FirstName, CoApplicant_Contact__r.LastName,
                        CoApplicant_Contact__r.LASERCA__Home_Address__c, CoApplicant_Contact__r.Year_Employment__c,
                        CoApplicant_Contact__r.LASERCA__Home_City__c, CoApplicant_Contact__r.LASERCA__Home_State__c,
                        CoApplicant_Contact__r.LASERCA__Home_Zip__c, CoApplicant_Contact__r.LASERCA__Co_Applicant_DOB__c,
                        CoApplicant_Contact__r.Income__c, CoApplicant_Contact__r.Phone, CoApplicant_Contact__r.Email,
                        CoApplicant_Contact__r.LASERCA__Social_Security_Number__c, CoApplicant_Contact__r.Express_Consent__c,
                        CoApplicant_Contact__r.Credit_Check_Acknowledged__c,
                        CoApplicant_Contact__r.Privacy_Policy_Acknowledged__c,
                        CoApplicant_Contact__r.Other_Bank_Executive__c, CoApplicant_Contact__r.Avidia_Service_Provider__c,
                        CoApplicant_Contact__r.Type_of_Avidia_Service_Provider__c,
                        CoApplicant_Contact__r.Employed_less_than_a_year__c,
                        Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Phone__c, Co_Applicant_Email__c,
                        Co_Applicant_Date_of_Birth__c, Co_App_Monthly_Mortgage__c,
                        Co_Applicant_Income__c, LASERCA__Co_Applicant_Social_Security_Number__c,
                        Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                        SREC_Product__r.Name, Project_Identification_Number__c, License_Number_Encrypted__c, State_of_Issuance__c,
                        Date_of_Issuance__c, Date_of_Expiration__c, Change_Order_Status__c, Loan_System_Information__c,
                        bs_Sales_ID__c, bs_Sales_ID__r.Name, bs_Sales_ID__r.Email__c, ConvertedContactId,
                        IsConverted, Product_line__c, Loan_Financing_Fee__c,
                        Partner_Lookup__c, Product__r.Loan_Interest_Rate__c, Loan_Fee_1__c, Product__r.Loan_Interest_Only_Period__c,
                        ConvertedOpportunityId,
                (SELECT Id, Name, Description FROM Attachments),
                (SELECT Id FROM Loans__r),
                (SELECT Id, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,
                    Inverter_Manufacturer__c, Inverter_Model_Number__c, Number_of_Inverters__c, Generator_Nameplate_Capacity__c,
                    Loan__r.Commencement_Datee__c, Loan__r.Estimated_Completion_Date__c, Storage_Grid_Hybrid__c,
                    Storage_Capacity__c, Storage_Full_or_Partial_Home__c, Storage_Inverter_Manufacturer__c,
                    Storage_Inverter_Model__c, Storage_Manufacturer__c, Storage_Model__c, Loan__r.Lead__r.Storage__c
                FROM Residential_Equipment__r),
                (SELECT Id, Name, Status__c FROM Partner_Tasks__r)
                FROM Lead
                WHERE Id = :leadId
                AND Email = :email LIMIT 1];
        if (leadList.size() == 0) {
            throw new AuraHandledException('Invalid lead');
        }
        lead = leadList[0];
        List<Attachment> attachments = new List<Attachment>();
        attachments.addAll(lead.Attachments);
        if (lead.ConvertedContactId != null) {
            List<Attachment> contactAttachments = [
                SELECT Id, Name, Description
                FROM Attachment
                WHERE ParentId =: lead.ConvertedContactId
            ];
            attachments.addAll(contactAttachments);
        }
        return new LeadWrapper(lead, attachments);
    }

    @AuraEnabled
    public static void setAppType(Lead capLead) {
        Lead dbLead = getLead(capLead.Id, capLead.email);
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
            lead.Date_of_Application__c = System.now().format('YYYY-MM-dd-hh:mm');
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
        Lead lead = [SELECT Id, Product__c, Product__r.Name, Product__r.External_Name__c, Product__r.Product_Type__c, Product__r.Program__c,
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

    @AuraEnabled
    public static Residential_Equipment__c getEquipment(Id leadId) {
        Residential_Equipment__c re  = [
            SELECT Id, Loan__c, Loan__r.Lead__r.System_Cost__c, Loan__r.Lead__r.Requested_Loan_Amount__c, Loan__r.Commencement_Datee__c,
                Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,
                Inverter_Manufacturer__c, Inverter_Model_Number__c, Number_of_Inverters__c, Generator_Nameplate_Capacity__c,
                Lead__r.Maximum_monthly_Disbursement__c, Loan__r.DOER_Solar_Loann__c, Loan__r.Estimated_Completion_Date__c,
                Storage_Grid_Hybrid__c, Storage_Capacity__c, Storage_Full_or_Partial_Home__c, Storage_Inverter_Manufacturer__c,
                Storage_Inverter_Model__c, Storage_Manufacturer__c, Loan__r.Lead__r.Storage__c, Storage_Model__c
            FROM Residential_Equipment__c
            WHERE Loan__r.Lead__c =: leadId LIMIT 1
        ];
        // We're sticking the max loan amount in this field to return it to the CAPStartHelper with one trip to the server.
        // Unfortunately, Max_Loan__c is a formula and can't be set in apex...
        re.Lead__r.Maximum_monthly_Disbursement__c = SLPCustomerHandler.getMaximumLoanAmount(re.Loan__c);
        return re;
    }

    @AuraEnabled
    public static Contact getSalesPartner(Id bsstId) {
        Contact c = [
            SELECT Id, Phone, MobilePhone
            FROM Contact
            WHERE Sales_Representative__c = :bsstId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return c;
    }

    @AuraEnabled
    public static void setApprovedChangeOrder(Id leadId, String email) {
        Lead lead = getLead(leadId, email);
        Map<String, Object> changeOrder = (Map<String, Object>) JSON.deserializeUntyped(lead.Loan_System_Information__c);
        String completionDate = (String) changeOrder.get('Estimated_Completion_Date__change');
        Residential_Equipment__c re = getEquipment(leadId);
        re.Generator_Nameplate_Capacity__c = (Decimal) changeOrder.get('Generator_Nameplate_Capacity__change');
        re.Module_Manufacturer__c = (String) changeOrder.get('Module_Manufacturer__change');
        re.Module_Model_Number__c = (String) changeOrder.get('Module_Model_Number__change');
        re.Number_of_Modules__c = (Integer) changeOrder.get('Number_of_Modules__change');
        re.Inverter_Manufacturer__c = (String) changeOrder.get('Inverter_Manufacturer__change');
        re.Inverter_Model_Number__c = (String) changeOrder.get('Inverter_Model_Number__change');
        re.Number_of_Inverters__c = (Integer) changeOrder.get('Number_of_Inverters__change');
        if ((Boolean) changeOrder.get('Storage__change')) {
            re.Storage_Full_or_Partial_Home__c = (String) changeOrder.get('Storage_Full_or_Partial_Home__change');
            re.Storage_Capacity__c = (Integer) changeOrder.get('Storage_Capacity__change');
            re.Storage_Manufacturer__c = (String) changeOrder.get('Storage_Manufacturer__change');
            re.Storage_Model__c = (String) changeOrder.get('Storage_Model__change');
            re.Storage_Inverter_Manufacturer__c = (String) changeOrder.get('Storage_Inverter_Manufacturer__change');
            re.Storage_Inverter_Model__c = (String) changeOrder.get('Storage_Inverter_Model__change');
            re.Loan__r.Lead__r.Storage__c = (Boolean) changeOrder.get('Storage__change');
            if (changeOrder.get('Storage_Grid_Hybrid__change') == 'Yes') {
                re.Storage_Grid_Hybrid__c = true;
            } else {
                re.Storage_Grid_Hybrid__c = false;
                re.Storage_Full_or_Partial_Home__c = 'N/A';
            }
            update re.Loan__r.Lead__r;
        } else {
            re.Storage_Grid_Hybrid__c = false;
            re.Storage_Full_or_Partial_Home__c = null;
            re.Storage_Capacity__c = null;
            re.Storage_Manufacturer__c = null;
            re.Storage_Model__c = null;
            re.Storage_Inverter_Manufacturer__c = null;
            re.Storage_Inverter_Model__c = null;
            re.Loan__r.Lead__r.Storage__c = false;
            update re.Loan__r.Lead__r;
        }

        Loan__c loan;
        if (completionDate != null && completionDate != '') {
            loan = new Loan__c(
                Id = re.Loan__c,
                Estimated_Completion_Date__c = Date.parse(completionDate),
                Commencement_Datee__c = Date.parse(completionDate) + (re.Loan__r.DOER_Solar_Loann__c?45:30)
            );
        } else {
            loan = new Loan__c(
                Id = re.Loan__c,
                Estimated_Completion_Date__c = null,
                Commencement_Datee__c = null
            );
        }

        lead.System_Cost__c = (Decimal) changeOrder.get('System_Cost__change');
        lead.Requested_Loan_Amount__c = (Decimal) changeOrder.get('Requested_Loan_Amount__change');
        lead.Change_Order_Status__c = 'Customer Authorized';
        lead.Update_Dummy__c = !lead.Update_Dummy__c;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            Id = lead.Personal_Credit_Report__c,
            Avidia_Review_Status__c = PCRApprovalHandler.NOTYETREVIEWED
        );

        try {
            update re;
            update loan;
            update lead;
            update pcr;
            sendChangeOrderCompletionEmail(lead, '');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void setRejectedChangeOrder(Id leadId, String email, String loanSystemInformation) {
        Lead lead = getLead(leadId, email);
        lead.Change_Order_Status__c = 'Customer Rejected';
        lead.Loan_System_Information__c = loanSystemInformation;
        update lead;
        Map<String, Object> lsi = (Map<String, Object>) System.JSON.deserializeUntyped(loanSystemInformation);
        sendChangeOrderCompletionEmail(lead, (String) lsi.get('Reject_Reason'));
    }

    public static void sendChangeOrderCompletionEmail(Lead lead, String reason) {
        MessagingService.EmailEnvelope ee =
            getPartnerEmailEnvelope(lead, 'RS_SLP_Completed_Change_Order', 'BlueWave Solar Loan - Change Order Completed');
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!Change_Order_Status__c}', (lead.Change_Order_Status__c=='Customer Authorized'?'authorized':'rejected')));
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!Reject_Reason}', (reason!=''?'They provided a reason of: <i>' + reason + '</i>':'')));
        MessagingService.sendEmailTemplate(ee);
    }

    private static MessagingService.EmailEnvelope getPartnerEmailEnvelope(Lead lead, String templateName, String subject) {
        Domain d = [SELECT Domain, DomainType FROM Domain];
        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = templateName;
        ee.orgWideEmail = 'customercare@bluewavesolar.com';
        ee.subjectLine = subject;
        ee.addressList = new List<String>{lead.bs_Sales_ID__r.Email__c};
        ee.replacementTexts = new List<MessagingService.ReplacementText>();
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!Lead.FullName}', lead.FirstName + ' ' + lead.LastName));
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!partnerName}', lead.bs_Sales_ID__r.Name));
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!slpurl}', 'https://' + d.domain + '/slportal/s/login'));
        ee.sobjectId = lead.ConvertedContactId!=null?lead.ConvertedContactId:lead.Id;
        return ee;
    }

    @AuraEnabled
    public static Lead convertLead(Id leadId, String email) {
        Lead lead = getLead(leadId, email);
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(leadId);
        leadConvert.setConvertedStatus('Interested');
        Database.LeadConvertResult lcr = Database.convertLead(leadConvert, false);
        return getLead(leadId, email);
    }

    @AuraEnabled
    public static Boolean createLoanAndEquipment(Id leadId, String email) {
        Lead lead = getLead(leadId, email);
        if (!lead.Residential_Equipment__r.isEmpty() || !lead.Loans__r.isEmpty()) {
            Logger.logNow('CAPController', 'createLoanAndEquipment', 'Loans or Equipment already created, equipment: ' +
                lead.Residential_Equipment__r[0] + ' loans: ' + lead.Loans__r[0]);
        } else {
            try {
                System.debug('Inside try block');
                LoanHandler.createResidentialEquipment(new List<Lead>{lead});
                System.debug('equipment created');
                LoanHandler.createLoan(new List<Lead>{lead});
                System.debug('Loan created');
                // createLoan creates the Loan and Partner Tasks before associating the RE to the Loan. If the RE is complete,
                // we should close out the system info partner task
                String searchCriteria = lead.Id + '%';
                List<Partner_Task__c> tasks = [SELECT Id, Unique_ID__c, Parent__c, Status__c FROM Partner_Task__c WHERE Unique_ID__c LIKE :searchCriteria];
                Map<String, Partner_Task__c> taskMap = new Map<String, Partner_Task__c>();
                for (Partner_Task__c task : tasks) {
                    taskMap.put(task.Unique_ID__c, task);
                }
                LoanHandler lh = new LoanHandler();
                lh.validateLoanInformationProvidedOnLead(new List<Lead>{lead}, taskMap);
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        return getLeadWrapper(leadId, email).systemInfoComplete;
    }

    @AuraEnabled
    public static void sendLoanDocs(Id leadId, String email) {
        Lead lead = getLead(leadId, email);
        if (lead.Residential_Equipment__r.size() == 1 &&
            LoanHandler.equipmentPopulated(lead.Residential_Equipment__r[0])) {
            if (!pendingOrCompleteLoanDoc(lead.Partner_Tasks__r)) {
                try {
                    DocuSignHelper.sendLoanPackageFuture(lead.ConvertedOpportunityId);
                } catch (Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }
            }
        } else {
            MessagingService.EmailEnvelope ee =
                getPartnerEmailEnvelope(lead, 'RS_SLP_Confirmed_Contingent_Note', 'BlueWave Solar Loan - Contingent Note Confirmed');
            MessagingService.sendEmailTemplate(ee);
        }
    }

    private static Boolean pendingOrCompleteLoanDoc(List<Partner_Task__c> tasks) {
        for (Partner_Task__c task : tasks) {
            if (task.Name == 'Obtain Contract Signature') {
                return (task.Status__c == 'Pending' || task.Status__c == 'Complete');
            }
        }
        return false;
    }

    // With the contingent process, we create the Loan and Partner tasks before an applicant has declared their income
    // type, so we don't know until after partner tasks are initially created, what income task to create. This method
    // inserts the PT list after the applicant declares income to create the last task.
    // Incidentally, this could also be used to handle task changes from MSLP to BW?
    @AuraEnabled
    public static void insertPartnerTasks(Id leadId, String email) {
        Lead lead = getLead(leadId, email);
        LoanHandler lh = new LoanHandler();
        lh.createLoanPartnerTasksStatusOption(lead.Loans__r, false);
    }

    public class LeadWrapper {
        @AuraEnabled
        public Lead lead {get;set;}
        @AuraEnabled
        public List<Attachment> attachments {get;set;}
        @AuraEnabled
        public Boolean contractSent {get;set;}
        @AuraEnabled
        public Boolean systemInfoComplete {get;set;}
        @AuraEnabled
        public Boolean warnOnMaxLoanAmount {get;set;}

        public LeadWrapper(Lead l, List<Attachment> attachments) {
            this.lead = l;
            this.attachments = attachments;
            this.contractSent = pendingOrCompleteLoanDoc(l.Partner_Tasks__r);
            if (l.Residential_Equipment__r.size() > 0) {
                this.systemInfoComplete = LoanHandler.equipmentPopulated(l.Residential_Equipment__r[0]);
            } else {
                this.systemInfoComplete = false;
            }
            List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
            if (systemProperties.size() > 0) {
                this.warnOnMaxLoanAmount = systemProperties[0].Warn_on_Max_Loan_Amount__c;
            } else {
                this.warnOnMaxLoanAmount = true;
            }
        }
    }

}