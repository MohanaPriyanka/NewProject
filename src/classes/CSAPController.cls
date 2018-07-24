/*************************************************************************************
 * Created By:  Joey Chan
 * Description: Community Solar Application Portal controller for the public communities
 * Test: CSAPControllerTest
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
        public Product2 srecProduct;

        @AuraEnabled
        public Product2 smartProduct;
    }

    @AuraEnabled
    public static Lead getLead(Id leadId, String email) {
        List<Lead> leadList  = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                    Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c, 
                    Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                    Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                    Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c,
                    LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                    Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Customer_Referral__c
            FROM Lead
            WHERE Id = :leadId
            AND Email = :email
            LIMIT 1
        ];

        Lead lead = (leadList.size() > 0) ? leadList[0] : null;
        return lead;
    }
    @AuraEnabled
    public static Contact getContact(Id leadId, String email) {
        List<Contact> contactList = [
            SELECT Id, FirstName, LastName, Email, Phone, AccountId, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, MobilePhone, Product_Line__c
            FROM Contact
            WHERE Account.Lead__c = :leadId
            AND Account.Lead__r.Email = :email
            LIMIT 1
        ];
        return (contactList.size() > 0) ? contactList[0] : new Contact();
    }
    @AuraEnabled
    public static Account getAccount(Id leadId, String email) {
        List<Account> accountList = [
            SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, BillingStreet, BillingCity, BillingState, BillingPostalCode, Social_Security_Number__c
            FROM Account
            WHERE Lead__c = :leadId
            AND Lead__r.Email = :email];

        Account account = (accountList.size() > 0) ? accountList[0] : new Account();
        account.ShippingState = (account.ShippingState != null) ? BlueWaveParent.convertStateToAbbreviation(account.ShippingState) : null;
        account.BillingState = (account.BillingState != null) ? BlueWaveParent.convertStateToAbbreviation(account.BillingState) : null;
        return account;
    }
    @AuraEnabled
    public static List<Attachment> getAttachments(Id parentId) {
        return [SELECT Id, Name, Description from Attachment Where ParentId = :parentId];
    }

    @AuraEnabled
    public static SSSResult checkLeadCreditIfQualified(Id leadId) {
        Decimal creditScore = 0;
        SSSResult sssResult = new SSSResult();
        Id srecId;
        Id smartId;
        sssResult.sssCreditQualification = 'Ready for Credit Check';
        List<Shared_Solar_System__c> srecSystems = new List<Shared_Solar_System__c>();
        List<Shared_Solar_System__c> smartSystems = new List<Shared_Solar_System__c>();
        //Get the latest Credit Report Log completed for the Lead and get the PCR's Credit Score
        List<LASERCA__Credit_Report_Log__c> crList = [SELECT LASERCA__Personal_Credit_Report__r.LASERCA__Credit_Score__c
                                                          FROM LASERCA__Credit_Report_Log__c
                                                          WHERE LASERCA__Lead__c = :leadId
                                                          AND LASERCA__Status__c = 'Completed'
                                                          ORDER BY CreatedDate DESC
                                                          LIMIT 1];
        if (crList.size() > 0){
            if (crList[0].LASERCA__Personal_Credit_Report__r.LASERCA__Credit_Score__c != null){
                creditScore = Decimal.valueOf(crList[0].LASERCA__Personal_Credit_Report__r.LASERCA__Credit_Score__c);
            }
            Lead lead = [SELECT Id, Status, Partner_Name__c, Utility__c FROM Lead WHERE Id = :leadId];
            String sssQuery = 'SELECT Id, Credit_Score_Requirement__c, Product__r.Id, Product__r.Name , Product__c, Product__r.Program__c ';
            sssQuery +=       'FROM Shared_Solar_System__c ';
            sssQuery +=       'WHERE Open__c = true ';
            sssQuery +=       'AND Capacity_Available_to_be_Reserved__c > 0 ';
            sssQuery +=       'AND System_Utility__c IN (\'' + lead.Utility__c + '\') ';
            if (lead.Partner_Name__c != null){
                sssQuery +=       'AND Sales_Partners__c INCLUDES( \'' + 'All' + '\', \'' + lead.Partner_Name__c + '\' ) ';
            } else {
                sssQuery +=       'AND Public__c = true ';
            }
            sssQuery += 'ORDER BY Credit_Score_Requirement__c ASC ';
            List<Shared_Solar_System__c> sssList = Database.query(sssQuery);
            for (Shared_Solar_System__c sss : sssList) {
                if (sss.Product__r.Program__c == 'SREC - Community Solar') {
                    srecSystems.add(sss);
                }
                if (sss.Product__r.Program__c == 'SMART - Community Solar') {
                    smartSystems.add(sss);
                }
            }
            for (Shared_Solar_System__c srec : srecSystems) {
                if (creditScore >= srec.Credit_Score_Requirement__c) {
                    sssResult.srecProduct = srec.Product__r;
                    break;
                }
            }
            for (Shared_Solar_System__c smart : smartSystems) {
                if (creditScore >= smart.Credit_Score_Requirement__c) {
                    sssResult.smartProduct = smart.Product__r;
                    break;
                }
            }
            if (sssResult.smartProduct != null || sssResult.srecProduct != null) {
                sssResult.sssCreditQualification = 'Qualified';
            } else {
                sssResult.sssCreditQualification = 'Unqualified';
            }
        }
        return sssResult;
    }


    @AuraEnabled
    public static Lead upsertCSAPRecords(Lead lead, String partnerId, String salesRepId, String referralCode){
        User apiUser = [SELECT Id, Name, Username 
                        FROM User 
                        WHERE Name = 'API'
                        AND IsActive = True
                        LIMIT 1];
        Account account = getAccount(lead.Id, lead.Email);
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        account.Name = lead.FirstName + ' ' + lead.LastName;
        account.ShippingStreet = lead.Street;
        account.ShippingCity = lead.City;
        account.ShippingState = BlueWaveParent.convertAbbreviationToState(lead.State);
        account.ShippingPostalCode = lead.PostalCode;
        account.BillingStreet = lead.LASERCA__Home_Address__c;
        account.BillingCity = lead.LASERCA__Home_City__c;
        account.BillingState = BlueWaveParent.convertAbbreviationToState(lead.LASERCA__Home_State__c);
        account.BillingPostalCode = lead.LASERCA__Home_Zip__c;
        account.Social_Security_Number__c = lead.LASERCA__SSN__c;
        account.OwnerId = apiUser.Id;
        upsert account;

        if (lead.Date_of_Application__c == null) {
            lead.Date_of_Application__c = System.now().format('YYYY-MM-DD-hh:mm');
        }
        lead.State = BlueWaveParent.convertAbbreviationToState(lead.State);
        lead.Parent_Account__c = account.Id;
        lead.Parcel_Zip__c = lead.LASERCA__Home_Zip__c;
        if (lead.Application_Type__c == 'Residential') {
            lead.Customer_Type__c = 'Residential';
        }
        if (lead.Application_Type__c == 'Non-Residential') {
            lead.Customer_Type__c = 'Business';
        }
        if (String.isNotBlank(partnerId)) {
            lead.Partner_lookup__c = partnerId;
        } else if (String.isNotBlank(profile.partnerId)) {
            lead.Partner_lookup__c = profile.partnerId;
        }
        if (String.isNotBlank(salesRepId)) {
            lead.Bs_Sales_ID__c = salesRepId;
        } else if (String.isNotBlank(profile.salesRepId)) {
            lead.Bs_Sales_ID__c = profile.salesRepId;
        }
        if(String.isBlank(referralCode) || referralCode == 'undefined'){
            lead.Customer_Referral__c = null;
        }else{
            List<Contact> referralContacts = [SELECT Id FROM Contact WHERE Id = :referralCode];
            if(referralContacts.size()==1){
                lead.Customer_Referral__c = referralContacts[0].Id;
            }else{
                Logger.logNow('CSAPController', 'upsertCSAPRecords', 'Bad referral code: ' + referralCode + ', for lead under parent account id: ' + account.Id);
            }
        }
        lead.Product__c = '01t0a000004Uk2x'; // Community Solar - SMART 18-02
        upsert lead;

        //Update the Account with the lookup back to the lead
        account.Lead__c = lead.Id;
        update account;

        Contact contact = getContact(lead.Id, lead.Email);
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
        contact.MobilePhone = lead.Phone;
        contact.Product_Line__c = 'Community Solar';
        upsert contact;
        return lead;
    }

    @AuraEnabled
    public static Boolean hasAvailableCapacity(Id leadId) {
        Lead lead = [SELECT Id, Load_Zone__c, Utility__c, Partner_Name__c, System_Assignment__c FROM Lead WHERE Id = :leadId];
        String sssQuery = 'SELECT Id, Product__r.Name  ';
        sssQuery +=       'FROM Shared_Solar_System__c ';
        sssQuery +=       'WHERE Open__c = true ';
        sssQuery +=       'AND Capacity_Available_to_be_Reserved__c > 0 ';
        sssQuery +=       'AND System_Utility__c = \'' + lead.Utility__c + '\' ';
        if (lead.Partner_Name__c != null){
            sssQuery +=       'AND Sales_Partners__c INCLUDES( \'' + 'All' + '\', \'' + lead.Partner_Name__c + '\' ) ';
        } else {
            sssQuery +=       'AND Public__c = true ';
        }
        if (lead.System_Assignment__c == 'Automatic - COD Date/Available Capacity' || lead.System_Assignment__c == null){
            sssQuery += 'ORDER BY Estimated_COD_Date_QC__c ASC, Project_Capacity_Available_kW_DC__c ASC';
        } else if (lead.System_Assignment__c == 'Automatic - Assignment Order'){
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
        Lead l = [SELECT Id, Personal_Credit_Report__c, Date_of_Application__c
                  FROM Lead
                  WHERE Id =:lead.Id];

        if (l != null && l.Personal_Credit_Report__c == null) {
            lead.LASERCA__Pull_Credit_Report__c = true;
        }
        if (l.Date_of_Application__c == null ||
            (l != null && l.Personal_Credit_Report__c == null)) {
            update lead;
        }
    }

    @AuraEnabled
    public static Product2 getProduct (String productId) {
        return [SELECT Id, Name, Program__c FROM Product2 WHERE Id =: productId];
    }
}
