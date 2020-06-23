/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 *
 * Description: The SLPAddCustomer class serves as a controller for the SLPAddCustomer Lightning component bundle. It allows the user to
 * add new customers to the database.
 *
 * Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPAddCustomer {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    //the addNewLeadRecord method adds a new SL customer to the database via the SLP
    @AuraEnabled
    public static Lead addNewLeadRecord (Lead newLead) {
        RecordType leadRecordType;
        String recordType;
        String productProgram;
        if (newLead.Product_Program__c == 'MSLP') {
            recordType = 'BFG - DOER Solar Loan';
        } else {
            recordType = 'BlueWave Solar Loan';
        }

        leadRecordType = [SELECT Id
                          FROM RecordType
                          WHERE Name = : recordType
                          AND SobjectType = 'Lead'
                          LIMIT 1];
        if (newLead.LASERCA__Home_State__c.length() > 2) {
            newLead.LASERCA__Home_State__c = BlueWaveParent.convertStateToAbbreviation(newLead.LASERCA__Home_State__c);
        }

        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Unfinished_Lead__c = true;
        newLead.Email_Re_Enter__c = newLead.Email;
        newLead.Application_Source_Phase_1__c = 'SLPortal Phase 1 Application';
        newLead.Partner_Lookup__c = profile.partnerId;
        newLead.Bs_Sales_ID__c = profile.salesRepId;
        newLead.Product_Line__c = 'Residential Loan';
        newLead.RecordTypeId = leadRecordType.Id;

        if (String.isNotBlank(profile.salesRepEmail)) {
            newLead.Partner_Email__c = profile.salesRepEmail;
        } else if (String.isNotBlank(profile.partnerEmail)) {
            newLead.Partner_Email__c = profile.partnerEmail;
        }
        insert newLead;

        return newLead;
    }

    @AuraEnabled
    public static Lead updateLeadRecord (Lead updatedLead) {
        String propertyString = updatedLead.firstName + ' ' + updatedLead.lastName;
        updatedLead.Company = propertyString;
        updatedLead.Email_Re_Enter__c = updatedLead.Email;

        update updatedLead;
        return updatedLead;
    } 

    // Assumes the version of Laser Credit Access that pulls credit via trigger and future method
    // For errors, check Apex Jobs (https://login.salesforce.com/apexpages/setup/listAsyncApexJobs.apexp)
    // or Credit Report Log objects related to the Lead
    @AuraEnabled
    public static void pullCreditStatus(Lead lead) {
        lead.LASERCA__Pull_Credit_Report__c = true;
        update lead;
    }

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

    @AuraEnabled
    public static String checkCreditStatus(Lead leadToQuery) {
        Lead lead = [SELECT Id, Status, LASTMODIFIEDDATE,
                     (SELECT id, LASERCA__Error_Message__c, CREATEDDATE
                      FROM LASERCA__Credit_Report_Logs__r
                      ORDER BY CREATEDDATE DESC),
                     (SELECT Id, Solar_Loan_Approval_Status__c
                      FROM LASERCA__Personal_Credit_Reports__r
                      ORDER BY CREATEDDATE DESC LIMIT 1)
                     FROM Lead
                     WHERE Id = :leadToQuery.Id];
        if (!lead.LASERCA__Personal_Credit_Reports__r.isEmpty()) {
            // If a PCR was successfully created, the Status will be updated on the Lead
            return(lead.Status);
        } else if (!lead.LASERCA__Credit_Report_Logs__r.isEmpty()) {
            // Since an installer can run credit multiple times on an applicant (if there was an error),
            // there might be multiple CRLs, some or all of which might be for previous credit checks.

            // Assuming the credit check is run based on checking the "Pull Credit Check" checkbox, we
            // can use the Lead.LASTMODIFIEDDATE to find the relevant CRL.
            for (LASERCA__Credit_Report_Log__c crl : lead.LASERCA__Credit_Report_Logs__r) {
                if (crl.CREATEDDATE > Lead.LASTMODIFIEDDATE) {
                    return(parseError(crl.LASERCA__Error_Message__c.split('\\n')[0]));
                }
            }
        }
        return(lead.Status);
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

    //the getPartnerRecord method returns the partner record to the lightning component. It is currently being used to identify the partner's
    //state to determine if the add a customer page should allow the user to submit MSLP applications
    @AuraEnabled
    public static Partner__c getPartnerRecord() {
        RecordType partnerRT = [SELECT Id
                                FROM RecordType
                                WHERE Name = : 'Partner Account'
                                AND SobjectType = 'Account'
                                LIMIT 1];
        return [SELECT Id, Name, Logo__c, State__c, Default_Application__c,
                (SELECT Disable_New_Loan_Applications_in_Portal__c,
                    Enable_Storage_Application_in_Portal__c
                 FROM Accounts__r
                 WHERE RecordTypeId = :partnerRT.Id LIMIT 1)
                FROM Partner__c 
                WHERE Id = : profile.partnerId LIMIT 1];
    }

    public static String getCAPUrl(Id leadId) {
        String host = Url.getSalesforceBaseUrl().toExternalForm() + '/';
        return (host + 'apply/s/loan-application?leadId=' + leadId);
    }

  
    @AuraEnabled
    public static List<String> getActiveStates() {
        List<String> states = profile.partnerMarkets.split(';',15);
        List<AggregateResult> activeProducts = [SELECT State__c
                                                FROM Product2
                                                WHERE IsActive = true
                                                AND Product_Type__c = 'Residential Loan'
                                                AND State__c in :states
                                                GROUP BY State__c
                                                ORDER BY State__c];
        List<String> options = new List<String>();
        for (AggregateResult p : activeProducts) {
            options.add((String) p.get('State__c'));
        }
        return options;
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
    public static List<Product2> getProducts(String state) {
        return getProducts(state, 'Residential Loan');
    }

    @AuraEnabled
    public static List<Product2> getProducts(String state, String productType) {
        return Util.getActiveProducts(new List<String>{state}, profile.partnerId, productType);
    }
}