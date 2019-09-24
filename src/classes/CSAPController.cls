/*************************************************************************************
 * Created By:  Joey Chan
 * Description: Community Solar Application Portal controller for the public communities
 * Test: CSAPControllerTest, DocuSignHelperTest, LeadTriggerHandlerTest
 *************************************************************************************/
public without sharing class CSAPController {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    public class SSSResult {
        // at the time of adding this, we only have a single SREC and SMART product, we we need not handle multiple ysstems with differen SREC and SMART Products.
        // if this were to become the case, the code should be adjusted to accomadate this scenario.
        @AuraEnabled
        public String sssCreditQualification;

        @AuraEnabled
        public List<Product2> productList;
    }

    @AuraEnabled
    public static Lead getLead(Id leadId, String email) {
        List<Lead> leadList = [
                SELECT Id, Personal_Credit_Report__c, CSAP_Stage__c, FirstName, LastName, Email, Phone, MobilePhone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                        Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                        Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                        Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                        Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Application_Source_Phase_1__c, Application_Source_Phase_2__c,
                        LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c, ZipCode__c,
                        Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Customer_Referral__c, Owner.Id,
                        LoadZone__c, Utility_relationship__c, Continue_Application_Link__c, Partner_Email__c, (
                        // CSAP will use this to send a DocuSign contract for a converted lead. If we have multiple opportunities
                        // for the lead, we'll just get the first. Ordering by created date should get the one(s) that were created
                        // in the transaction that converted the lead.
                        SELECT Id, Parent_Account_Name__c
                        FROM Opportunities__r
                        ORDER BY CreatedDate DESC, Opportunity_Order__c ASC
                )
                FROM Lead
                WHERE Id = :leadId
                AND Email = :email
                LIMIT 1
        ];

        Lead lead = (leadList.size() > 0) ? leadList[0] : null;
        return lead;
    }
    @AuraEnabled
    public static List<Attachment> getAttachments(Id parentId) {
        return [SELECT Id, Name, Description FROM Attachment WHERE ParentId = :parentId];
    }

    @AuraEnabled
    public static SSSResult checkLeadCreditIfQualified(Id leadId) {
        Decimal creditScore = 0;
        SSSResult result = new SSSResult();
        result.sssCreditQualification = 'Ready for Credit Check';

        //Get the latest Credit Report Log completed for the Lead and get the PCR's Credit Score
        List<LASERCA__Credit_Report_Log__c> crList = [
                SELECT LASERCA__Personal_Credit_Report__r.LASERCA__Credit_Score__c
                FROM LASERCA__Credit_Report_Log__c
                WHERE LASERCA__Lead__c = :leadId
                AND (LASERCA__Status__c = 'Completed' OR LASERCA__Status__c = 'Error')
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Lead lead = [SELECT Id, Personal_Credit_Report__c FROM Lead WHERE Id = :leadId];

        if (crList.size() > 0) {
            if (crList[0].LASERCA__Personal_Credit_Report__c == null) {
                throw new AuraHandledException('An error occurred: No credit report was returned. Please contact BlueWave Support Team at the number below.');
            }

            LASERCA__Personal_Credit_Report__c pcr = [
                    SELECT LASERCA__Credit_Score__c, LASERCA__Credit_Score_TransUnion__c
                    FROM LASERCA__Personal_Credit_Report__c
                    WHERE Id = :crList[0].LASERCA__Personal_Credit_Report__c
            ];

            if (pcr.LASERCA__Credit_Score__c != null) {
                creditScore = Decimal.valueOf(pcr.LASERCA__Credit_Score__c);
            } else {
                //No PCR returned
                pcr.LASERCA__Credit_Score_TransUnion__c = '9999';
                pcr.LASERCA__Credit_Score__c = '9999';
                creditScore = 9999;
                update pcr;
            }

            result = checkCreditReport(leadId, creditScore);
        }
        return result;
    }

    @AuraEnabled
    public static SSSResult checkForAlreadyRunCredit(Lead secondLead) {
        Decimal creditScore = 0;
        SSSResult result = new SSSResult();
        result.sssCreditQualification = 'Ready for Credit Check';

        List<LASERCA__Personal_Credit_Report__c> pcrList = [
                SELECT LASERCA__Credit_Score__c
                FROM LASERCA__Personal_Credit_Report__c
                WHERE LASERCA__Lead__r.Parent_Account__c = :secondLead.Parent_Account__c
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (pcrList.size() > 0) {
            if (pcrList[0].LASERCA__Credit_Score__c != null) {
                creditScore = Decimal.valueOf(pcrList[0].LASERCA__Credit_Score__c);
                secondLead.Personal_Credit_Report__c = pcrList[0].Id;
                update secondLead;
            }
        }

        result = checkCreditReport(secondLead.Id, creditScore);
        return result;
    }

    @AuraEnabled
    public static SSSResult checkCreditReport(Id leadId, Decimal creditScore) {
        SSSResult sssResult = new SSSResult();
        sssResult.sssCreditQualification = 'Ready for Credit Check';

        Lead lead = [SELECT Id, Status, Partner_Name__c, Application_Source_Phase_2__c, LoadZone__c, Utility_relationship__c FROM Lead WHERE Id = :leadId];
        String sssQuery = 'SELECT Id, Credit_Score_Requirement__c, Product__r.Id, Product__r.Name , Product__c, Product__r.Program__c ';
        sssQuery += 'FROM Shared_Solar_System__c ';
        sssQuery += 'WHERE Open__c = true ';
        sssQuery += 'AND Capacity_Available_to_be_Reserved__c > 0 ';
        sssQuery += 'AND Utility__c IN (\'' + lead.Utility_relationship__c + '\') ';
        sssQuery += 'AND Service_Territories__c INCLUDES(\'' + lead.LoadZone__c + '\') ';

        if (lead.Partner_Name__c != null) {
            sssQuery += 'AND Sales_Partners__c INCLUDES( \'' + 'All' + '\', \'' + lead.Partner_Name__c + '\' ) ';
        } else {
            sssQuery += 'AND Public__c = true ';
        }
        sssQuery += 'ORDER BY Credit_Score_Requirement__c ASC ';
        List<Shared_Solar_System__c> sssList = Database.query(sssQuery);

        Map<String, Product2> productProgramMap = new Map<String, Product2>();
        String passedCredit = 'Unqualified';

        for (Shared_Solar_System__c sss : sssList) {
            if (creditScore >= sss.Credit_Score_Requirement__c) {
                Product2 sssProduct = new Product2();
                sssProduct.Id = sss.Product__c;
                sssProduct.Program__c = sss.Product__r.Program__c;
                productProgramMap.put(sss.Product__r.Program__c, sssProduct);
                passedCredit = 'Qualified';
            }
        }
        sssResult.sssCreditQualification = passedCredit;
        sssResult.productList = productProgramMap.values();

        return sssResult;
    }

    @AuraEnabled
    public static Lead addAdditionalLead(Lead lead) {
        lead = processLead(lead);
        lead.Id = null;
        insert lead;
        // The lead trigger sets the Load Zone and Utility, which we need in case it ends up being split.
        Lead insertedLead = [
                SELECT LoadZone__c, Utility_relationship__c, ZipCode__c, ZipCode__r.LZ__c, ZipCode__r.Utility_Junction_Count__c
                FROM Lead
                WHERE Id = :lead.Id
        ];

        lead.ZipCode__c = insertedLead.ZipCode__c;

        if (insertedLead.ZipCode__r.Utility_Junction_Count__c != 1) {
            lead.Utility_relationship__c = null;
        } else {
            lead.Utility_relationship__c = insertedLead.Utility_relationship__c;
        }
        if (insertedLead.ZipCode__r.LZ__c.contains('/')) {
            lead.LoadZone__c = null;
        } else {
            lead.LoadZone__c = insertedLead.LoadZone__c;
        }
        return lead;
    }
    public static Lead processLead(Lead lead) {
        if (lead.Date_of_Application__c == null) {
            lead.Date_of_Application__c = System.now().format('YYYY-MM-DD-hh:mm');
        }
        lead.State = BlueWaveParent.convertAbbreviationToState(lead.State);
        lead.Customer_type__c = lead.Application_Type__c;
        return lead;
    }

    @AuraEnabled
    public static Boolean checkApplicationPartner(String partnerId) {
        Boolean partnerApp;
        Partner__c customerPartner = new Partner__c();

        try {
            customerPartner = PartnerSelector.selectPartnerByPartnerId(partnerId);
        } catch (Exception e) {
            customerPartner = PartnerSelector.selectDefaultCSPartner();
        }

        //Set boolean based on BIS (and BlueWave Test Partner?) or Partner to determine application process
        if (customerPartner.Name == 'CS Self-Originations' || customerPartner.Name == 'BlueWave Test Partner') {
            partnerApp = false;
        } else {
            partnerApp = true;
        }
        return partnerApp;
    }

    @AuraEnabled
    public static String getCSApplicationURL() {
        String partnerId = PartnerSelector.selectDefaultCSPartner().Id;

        Domain dom = [SELECT Domain, DomainType FROM Domain];

        String appURL = 'https://' + dom.Domain + '/apply/s/csap?partnerId=' + partnerId;

        return appURL;
    }

    @AuraEnabled
    public static Lead upsertCSAPRecords(Lead lead, String partnerId, String salesRepId, String referralCode) {
        Partner__c customerPartner = new Partner__c();

        try {
            customerPartner = PartnerSelector.selectPartnerByPartnerId(partnerId);
        } catch (Exception e) {
            customerPartner = PartnerSelector.selectDefaultCSPartner();
            if (partnerId != null) {
                Logger.logNow('CSAPController', 'upsertCSAPRecords', 'Partner not found with Id ' + partnerId + ' for Lead: ' + lead.Id);
            }
        }


        if (lead.Parent_Account__c == null) {
            lead = setupParentAccount(lead, customerPartner);
        }

        // If if an installer, use the installer's salesRepId from the profile instead of a default for the partner
        if (salesRepId != null && salesRepId != '') {
            lead.bs_Sales_ID__c = salesRepId;
        } else {
            lead.bs_Sales_ID__c = customerPartner.Default_Sales_Rep__c;
        }

        lead = processLead(lead);

        if (String.isNotBlank(referralCode) && referralCode != 'undefined') {
            List<Contact> referralContacts = [SELECT Id FROM Contact WHERE Id = :referralCode];
            if (referralContacts.size() == 1) {
                lead.Customer_Referral__c = referralContacts[0].Id;
            } else {
                Logger.logNow('CSAPController', 'upsertCSAPRecords', 'Bad referral code: ' + referralCode + ', for lead under parent account id: ' + account.Id);
            }
        }


        upsert lead;
        Lead insertedLead = [
                SELECT LoadZone__c, Utility_relationship__c, Confirm_Utility__c
                FROM Lead
                WHERE Id = :lead.Id
        ];


        String continueApplicationUrl = Util.getCommunitySiteURL('Apply') + '/s/csap-payment?leadId=' + lead.Id;
        insertedLead.Continue_Application_Link__c = continueApplicationUrl;
        update insertedLead;

        lead.Continue_Application_Link__c = continueApplicationUrl;
        lead.LoadZone__c = insertedLead.LoadZone__c;
        lead.Utility_relationship__c = insertedLead.Utility_relationship__c;
        lead.Confirm_Utility__c = insertedLead.Confirm_Utility__c;
        return lead;
    }
    @AuraEnabled
    public static Boolean hasAvailableCapacity(Id leadId) {
        Lead lead = [
                SELECT Id, Partner_Name__c, Application_Source_Phase_2__c, System_Assignment__c,
                        LASERCA__Home_State__c, Application_Type__c, Utility_relationship__c, LoadZone__c
                FROM Lead
                WHERE Id = :leadId
        ];
        if (lead.Utility_relationship__c == null || lead.LoadZone__c == null) {
            return false;
        }
        String sssQuery = 'SELECT Id, Product__r.Name  ';
        sssQuery += 'FROM Shared_Solar_System__c ';
        sssQuery += 'WHERE Open__c = true ';
        sssQuery += 'AND Capacity_Available_to_be_Reserved__c > 0 ';
        sssQuery += 'AND Utility__c = \'' + lead.Utility_relationship__c + '\' ';
        sssQuery += 'AND Service_Territories__c INCLUDES(\'' + lead.LoadZone__c + '\') ';
        if (lead.Partner_Name__c != null) {
            sssQuery += 'AND Sales_Partners__c INCLUDES( \'' + 'All' + '\', \'' + lead.Partner_Name__c + '\' ) ';
        } else {
            sssQuery += 'AND Public__c = true ';
        }
        if (lead.System_Assignment__c == 'Automatic - COD Date/Available Capacity' || lead.System_Assignment__c == null) {
            sssQuery += 'ORDER BY Estimated_COD_Date_QC__c ASC, Project_Capacity_Available_kW_DC__c ASC';
        } else if (lead.System_Assignment__c == 'Automatic - Assignment Order') {
            sssQuery += 'ORDER BY Assignment_order__c ASC';
        }
        List<Shared_Solar_System__c> sssList = Database.query(sssQuery);

        return (sssList.size() > 0);
    }

    // The Credit Check methods are copied FROM SLPAddCustomer to make it easier to retire that class
    @AuraEnabled
    public static Integer getCreditCheckTimeout() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
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
        Lead l = [
                SELECT Id, Name, Personal_Credit_Report__c, Date_of_Application__c, Application_Source_Phase_2__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
        String name = l.Name.toLowerCase();
        if (o.IsSandbox || name.contains('testcase')) {
            // Per Tracy: sandboxes always need to have an SSN for a credit pull in sandboxes / testcases
            if (name.contains('frozen')) {
                // let's give a way to submit frozen apps
                lead.LASERCA__SSN__c = '000000010';
            } else if (name.contains('fail')) {
                // returns a 498 credit score
                lead.LASERCA__SSN__c = '000000008';
            } else {
                lead.LASERCA__SSN__c = '000000001';
            }
        } else {
            // for Prod, we need SSN to be all zeros
            lead.LASERCA__SSN__c = '000000000';
        }

        if (l != null && l.Personal_Credit_Report__c == null) {
            lead.Soft_Pull_Credit_Report__c = true;
        }
        if (l.Date_of_Application__c == null ||
                (l != null && l.Personal_Credit_Report__c == null)) {
            update lead;
        }
    }

    @AuraEnabled
    public static Product2 getProduct(String productId) {
        return [
                SELECT Id, Name, Program__c, Customer_Subscription_Type__c, Default_Residential_Usage__c,
                        Default_Business_Usage__c, Disable_Multiple_UAL_CSAP__c
                FROM Product2
                WHERE Id = :productId
        ];
    }

    @AuraEnabled
    public static Utility__c getUtility(String utilityId) {
        return [SELECT Id, Name FROM Utility__c WHERE Id = :utilityId];
    }

    @AuraEnabled
    public static List<Rate_Class__c> getRateClassesForUtility(String utilityId) {

        List<Rate_Class__c> rateClasses = [
                SELECT Id, Name, Utility__c
                FROM Rate_Class__c
                WHERE Utility__c = :utilityId
        ];

        return rateClasses;
    }

    @AuraEnabled
    public static Lead convertCSLead(Id leadId, String email) {
        Lead primaryLead = getLead(leadId, email);
        List<Lead> leads = [
                SELECT Id, OwnerId
                FROM Lead
                WHERE Parent_Account__c = :primaryLead.Parent_Account__c
                AND Status = 'Qualified'
        ];

        // make sure that the lead owner is a user, if not set it to API
        Boolean updatedLeadOwner = false;
        User apiUser = [
                SELECT Id, Name, Username
                FROM User
                WHERE Name = 'API'
                AND IsActive = TRUE
                LIMIT 1
        ];
        for (Lead lead : leads) {
            if (lead.OwnerId.getSobjectType() != User.SObjectType) {
                lead.OwnerId = apiUser.Id;
            }
            lead.CSAP_Stage__c = 'NAV_Complete';
        }
        update leads;

        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead leadToConvert : leads) {
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(leadToConvert.Id);
            leadConvert.setConvertedStatus('Qualified');
            leadConvert.setDoNotCreateOpportunity(true);
            leadConverts.add(leadConvert);
        }

        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        for (Database.LeadConvertResult lcr : lcrs) {
            if (!lcr.isSuccess()) {
                Logger.logLater(
                        'CSAPController',
                        'convertCSLead',
                        'CS Lead conversion failed for Id: ' + leadId +
                                ' error:' + lcr.getErrors()[0].getMessage());
            }
        }
        Logger.flushLogs();
        return getLead(leadId, email);
    }

    @AuraEnabled
    public static void unsplitLead(Lead lead) {
        Lead primaryLead = getLead(lead.Id, lead.Email);
        if (primaryLead == null) {
            throw new AuraHandledException('Invalid lead');
        }
        primaryLead.Utility_relationship__c = lead.Utility_relationship__c;
        primaryLead.LoadZone__c = lead.LoadZone__c;
        primaryLead.Status = 'Ready for Credit Check';
        update primaryLead;
    }

    private static Lead setupParentAccount(Lead lead, Partner__c customerPartner) {
        User apiUser = [
                SELECT Id, Name, Username
                FROM User
                WHERE Name = 'API'
                AND IsActive = TRUE
                LIMIT 1
        ];

        Group csInsideSales = [
                SELECT Id, Name
                FROM Group
                WHERE Type = 'Queue'
                AND DeveloperName = 'CS_Inside_Sales'
                LIMIT 1
        ];

        Account account = new Account(
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId(),
                Name = lead.FirstName + ' ' + lead.LastName,
                ShippingStreet = lead.Street,
                ShippingCity = lead.City,
                ShippingState = BlueWaveParent.convertAbbreviationToState(lead.State),
                ShippingPostalCode = lead.PostalCode,
                BillingStreet = lead.LASERCA__Home_Address__c,
                BillingCity = lead.LASERCA__Home_City__c,
                BillingState = BlueWaveParent.convertAbbreviationToState(lead.LASERCA__Home_State__c),
                BillingPostalCode = lead.LASERCA__Home_Zip__c,
                Social_Security_Number__c = lead.LASERCA__SSN__c,
                OwnerId = apiUser.Id
        );
        insert account;
        lead.Parent_Account__c = account.Id;
        lead.OwnerId = csInsideSales.Id;

        lead.Partner_Lookup__c = customerPartner.Id;
        if (customerPartner.Email__c != null) {
            lead.Partner_Email__c = customerPartner.Email__c;
        }


        // only need to insert contact if they don't have a parent account already
        Contact contact = new Contact();
        contact.FirstName = lead.FirstName;
        contact.LastName = lead.LastName;
        contact.MobilePhone = lead.MobilePhone;
        contact.Email = lead.Email;
        contact.Phone = lead.Phone;
        contact.AccountId = account.Id;
        contact.LASERCA__Home_Address__c = lead.LASERCA__Home_Address__c;
        contact.LASERCA__Home_City__c = lead.LASERCA__Home_City__c;
        contact.LASERCA__Home_State__c = lead.LASERCA__Home_State__c;
        contact.LASERCA__Home_Zip__c = lead.LASERCA__Home_Zip__c;
        contact.Product_Line__c = 'Community Solar';
        insert contact;

        return lead;
    }

    @AuraEnabled
    public static void insertChargentOrderOnLead(ChargentOrders__ChargentOrder__c newOrder, Lead lead) {
        Lead primaryLead = getLead(lead.Id, lead.Email);
        List<Entity__c> defaultEntities = [
                SELECT Id, Gateway__c
                FROM Entity__c
                WHERE Name = 'BWC Holdings, LLC'
                LIMIT 1
        ];
        if (primaryLead != null && !defaultEntities.isEmpty()) {
            newOrder.Lead__c = primaryLead.Id;
            newOrder.Entity__c = defaultEntities[0].Id;
            newOrder.ChargentOrders__Gateway__c = defaultEntities[0].Gateway__c;
            insert newOrder;
        } else if (defaultEntities.isEmpty()) {
            Logger.logNow('CSAPController', 'insertChargentOrderOnLead', 'Could not identify the default entity to insert with');
            throw new AuraHandledException('Cannot insert order without Default Entity');
        }
    }

    @AuraEnabled
    public static List<String> getStates() {
        return BlueWaveParent.getUSStates(true);
    }
    @AuraEnabled
    public static Boolean hasCapacity(String zipcode) {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse capacityServiceResponse = service.findCapacityByZipcode(zipcode);
        return capacityServiceResponse.hasCapacity();

    }

    @AuraEnabled
    public static List<Utility_Account_Log__c> saveUtilityAccountLogList(List<Utility_Account_Log__c> ualList) {
        upsert ualList;
        return ualList;
    }

    @AuraEnabled
    public static void saveUtilityAccountLog(Utility_Account_Log__c ual) {
        upsert ual;

        List<Attachment> utilityBills = [
                SELECT Name, Body, ContentType, Description
                FROM Attachment
                WHERE ParentId = :ual.Lead__c
                AND Description LIKE '%electric bill%'
        ];

        Util.reparentAttachments(utilityBills, ual.Id);
    }

    @AuraEnabled
    public static void saveTerms(String terms, Lead lead, String termsType) {
        // Create a Task on the lead that stores the Payment Terms & BW Application Credit Check terms
        User apiUser = [
                SELECT Id, Name, Username
                FROM User
                WHERE Name = 'API'
                AND IsActive = TRUE
                LIMIT 1
        ];

        Task task = new Task(
                Subject = 'Customer Consent to ' + termsType,
                WhoId = lead.Id,
                OwnerId = apiUser.Id,
                Priority = 'Normal',
                Status = 'Completed',
                Start_Date__c = System.today(),
                Description = terms
        );
        insert task;
    }

    @AuraEnabled
    public static Boolean sendEmailForPaymentInfo(Lead lead) {
        lead = getLead(lead.Id, lead.Email);

        lead.CSAP_Stage__c = 'NAV_Energy_Information';
        update lead;


        EmailService.createCSCustomerRequestPaymentInfoEmails(new List<Lead>{
                lead
        });
        Messaging.SendEmailResult[] result = EmailService.sendMessages();

        if (!result.isEmpty() && result[0].isSuccess()) {
            return true;
        } else {
            String message = 'Message did not send for lead: ' + lead.Id + '. Error: ' + result[0].getErrors();
            Logger.logNow('CSAPController', 'sendEmailForPaymentInfo', message, 'Error');
            return false;
        }
    }
    // See https://github.com/docusign/sfdc-recipe-embedded-signing/blob/master/src/classes/DS_Recipe_Signer_View_Controller.cls
    // for comments on DocuSign API usage for embedded signing
    @AuraEnabled
    public static String sendEmbeddedContract(Lead lead, Integer oppCounter) {
        // We should query the lead since it might not be fully populated (with a list of opportunities)
        lead = getLead(lead.Id, lead.Email);

        Opportunity opp = OpportunitiesSelector.selectForContractSend(lead.Opportunities__r[oppCounter].Id);

        DocuSignAPI.RequestRecipientTokenAuthenticationAssertion assertion =
                new DocuSignAPI.RequestRecipientTokenAuthenticationAssertion();
        assertion.AssertionID = '1';
        assertion.AuthenticationInstant = Datetime.now();
        assertion.AuthenticationMethod = 'Email';
        assertion.SecurityDomain = 'CSAPController';

        DocuSignAPI.RequestRecipientTokenClientURLs urls = new DocuSignAPI.RequestRecipientTokenClientURLs();


        String returnURLBase = Util.getCommunitySiteURL('Apply') + '/s/';

        if ((lead.Opportunities__r.size() - 1) == oppCounter) {
            urls.OnSigningComplete = returnURLBase + 'contract-complete' + '?event=signing_complete';
        } else {
            String showContract = returnURLBase;
            showContract += 'contract-show';
            showContract += '?oppCounter=' + (oppCounter + 1);
            showContract += '&oppTotal=' + lead.Opportunities__r.size();
            showContract += '&leadId=' + lead.Id;
            showContract += '&leadEmail=' + lead.Email;
            urls.OnSigningComplete = showContract + '&event=signing_complete';
        }

        urls.OnViewingComplete = returnURLBase + 'contract-complete?event=viewing_complete';
        urls.OnCancel = returnURLBase + 'contract-complete?event=cancel';
        urls.OnDecline = returnURLBase + 'contract-complete?event=decline';
        urls.OnSessionTimeout = returnURLBase + 'contract-complete?event=session_timeout';
        urls.OnTTLExpired = returnURLBase + 'contract-complete?event=ttl_expired';
        urls.OnException = returnURLBase + 'contract-complete?event=exception';
        urls.OnAccessCodeFailed = returnURLBase + 'contract-complete?event=failed_access_code';
        urls.OnIdCheckFailed = returnURLBase + 'contract-complete?event=failed_id_check';
        urls.OnFaxPending = returnURLBase + 'contract-complete?event=fax_pending';

        DocuSignAPI.EnvelopeStatus envelopeStatus;
        try {
            envelopeStatus = DocuSignHelper.sendCSPackage(opp, 1, 1);
        } catch (Exception e) {
            // Something bad and uncaught happened, have the Lightning Component show the user the exception page
            Logger.logLater('CSAPController', 'sendEmbeddedContract', 'Unhanded exception caught for : ' + opp.Id + '\n' + e.getMessage(), 'Error');
            Logger.flushLogs();
            return urls.OnException;
        }
        // EnvelopeStatus can be null if a callout exception was caught, which can happen for a timeout.
        if (envelopeStatus == null) {
            Logger.logLater('CSAPController', 'sendEmbeddedContract', 'Did not expect a null Envelope Status' + opp.Id, 'Error');
            Logger.flushLogs();
            return urls.OnSessionTimeout;
        }
        // If there's something wrong with the envelope status (not sure if this can happen), redirect to an error
        if (envelopeStatus.RecipientStatuses.RecipientStatus == null) {
            Logger.logLater('CSAPController', 'sendEmbeddedContract', 'Recipient Status for envelope was missing for ' + opp.Id, 'Error');
            Logger.flushLogs();
            return urls.OnException;
        }

        // Per https://github.com/docusign/docusign-soap-sdk/wiki/Code-Walkthrough-_-Embedded-Signing:
        // ClientUserId must be a unique value on the Envelope. You can use something simple like “1” or “2”, or you
        // can use some localID that is significant in your application – like a customerId. It just has to be unique
        // on the envelope because this value will be used along with the Recipient’s Name and Email to request the
        // RecipientToken. Remember that while the you can have multiple Recipients with the same Name and Email address
        // (because the same person can act in multiple roles on a single envelope), they must all have different ClientUserIds.
        String userName, email, recipientType, clientUserId;
        for (DocuSignAPI.RecipientStatus rs : envelopeStatus.RecipientStatuses.RecipientStatus) {
            if (rs.Type_x == 'Signer' && rs.RoutingOrder == 1) {
                userName = rs.UserName;
                email = rs.Email;
                recipientType = rs.Type_x;
                clientUserId = DocuSignHelper.getCaptiveInfo(opp, rs.Type_x).ClientUserId;
            }
        }
        if (userName == null || email == null) {
            Logger.logLater('CSAPController', 'sendEmbeddedContract', 'Sent a contract for ' + opp.Id +
                    'but didn\'t find a recipient with RoutingOrder 1', 'Error');
            Logger.flushLogs();
            return urls.OnException;
        }

        String signerViewURL;
        try {
            signerViewURL =
                    DocuSignHelper.dsAPI.RequestRecipientToken(envelopeStatus.EnvelopeID, clientUserId, userName, email, assertion, urls);
            Logger.logLater('CSAPController', 'sendEmbeddedContract', 'Successfully got a embedded DocuSign link for ' +
                    opp.Id + ': ' + signerViewURL, 'Info');

        } catch (Exception e) {
            signerViewURL = urls.OnException;
            Logger.logNow('CSAPController', 'sendEmbeddedContract', 'Exception caught for ' + opp.Id + '\n' + e.getMessage(), 'Error');
        }
        Logger.flushLogs();
        return signerViewURL;
    }

    @AuraEnabled
    public static Boolean zuoraPaymentPageEnabled() {
        return ZuoraAPIHelper.zuoraPaymentPageEnabled();
    }
}