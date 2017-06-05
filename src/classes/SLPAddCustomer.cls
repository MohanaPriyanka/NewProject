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
        if (newLead.DOER_Solar_Loan__c) {
            recordType = 'BFG - DOER Solar Loan';
            productProgram = 'MSLP';
        } else {
            recordType = 'BlueWave Solar Loan';
            productProgram = 'BlueWave Solar Loan';
        }

        leadRecordType = [SELECT Id 
                          FROM RecordType 
                          WHERE Name = : recordType
                          AND SobjectType = 'Lead' 
                          LIMIT 1];

        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Email_Re_Enter__c = newLead.Email;
        newLead.Product_Program__c = productProgram;
        newLead.Partner_Lookup__c = profile.partnerId;
        newLead.bs_Sales_ID__c = profile.salesRepId;
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
        Lead lead = [SELECT Id, Status,
                     (SELECT id, LASERCA__Error_Message__c 
                      FROM LASERCA__Credit_Report_Logs__r 
                      ORDER BY CREATEDDATE DESC LIMIT 1),
                     (SELECT id, Solar_Loan_Approval_Status__c 
                      FROM LASERCA__Personal_Credit_Reports__r 
                      ORDER BY CREATEDDATE DESC LIMIT 1)
                     FROM Lead
                     WHERE Id = :leadToQuery.Id];
        if (!lead.LASERCA__Personal_Credit_Reports__r.isEmpty()) {
            // If a PCR was successfully created, the Status will be updated on the Lead
            return(lead.Status);
        } else if (!lead.LASERCA__Credit_Report_Logs__r.isEmpty()) {
            // If a PCR was successfully created but a Credit Report Log was, return the first line of the error
            return(lead.LASERCA__Credit_Report_Logs__r[0].LASERCA__Error_Message__c.split('\\n')[0]);
        } else {
            return(lead.Status);
        }
    }

    //the getPartnerRecord method returns the partner record to the lightning component. It is currently being used to identify the partner's
    //state to determine if the add a customer page should allow the user to submit MSLP applications
    @AuraEnabled
    public static Partner__c getPartnerRecord() {
        return [SELECT Id, Name, Logo__c, State__c 
                FROM Partner__c 
                WHERE Id = : profile.partnerId LIMIT 1];       
    }     

    @AuraEnabled 
    public static String sendApplication (String customerEmail, String productProgram) {
        System.debug('the productProgram is ' + productProgram);
        String startApplicationUrl;
        String customerName;
        String mslpUrl;
        String bwslUrl;
        Boolean updateDummy;  
        List<String> emailList = new List<String>();
        Map<String, String> mslpUrlParametersMap = new Map<String, String>();
        Map<String, String> bwslUrlParametersMap = new Map<String, String>();

        emailList.add(customerEmail);
        EmailTemplate template = [SELECT Id, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE DeveloperName = 'RS_SLP_Start_Customer_Application'];    

        mslpUrlParametersMap.put('648', (String)profile.partnerId);
        mslpUrlParametersMap.put('649', (String)profile.salesRepId);
        mslpUrlParametersMap.put('529', emailList.get(0));
        mslpUrl = FormAssemblyHelper.createFormAssemblyUrl('381613', mslpUrlParametersMap);

        bwslUrlParametersMap.put('648', (String)profile.partnerId);
        bwslUrlParametersMap.put('649', (String)profile.salesRepId);
        bwslUrlParametersMap.put('529', emailList.get(0));
        bwslUrl = FormAssemblyHelper.createFormAssemblyUrl('381614', bwslUrlParametersMap);

        if (productProgram == 'bwsl') {
          startApplicationUrl = bwslUrl;       
        } else if (productProgram == 'mslp') {
          startApplicationUrl = mslpUrl;       
        }        
        String htmlBody = template.HtmlValue;
        htmlBody = htmlBody.replace('{!startApplication}', startApplicationUrl);
        htmlBody = htmlBody.replace('{!partnerName}', profile.PartnerName);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlBody);
        for (OrgWideEmailAddress senderEmail : [SELECT Id, Address 
                                           FROM OrgWideEmailAddress
                                           WHERE Address LIKE '%info%' 
                                           LIMIT 1]) {
          mail.setOrgWideEmailAddressId(senderEmail.Id); 
        }  
        String emailSubject = 'BlueWave Solar Loan - Start your application here'; 
        mail.setSubject(emailSubject);
        mail.setToAddresses(emailList);
        //mail.setTargetObjectId(lead.Id);
        MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{mail});        
        return customerName;
      }     
}    
