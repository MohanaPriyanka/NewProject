/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: The SLPUserHelper provides the SLP Controller class SOQL queries with the necessary id values for the logged in user. 
 * It also provides the SLPPartnerLogo class with the id value of the partner's logo and handles the alerts system used by BW operators. 
 *
 Tested By: SLPControllerTestclass
 *************************************************************************************/

public without sharing class SLPUserHelper {
    private static String partnerIdVar;
    
    public class PartnerProfile {      
        public String partnerId;
       
        public String salesRepId;
       
        public String licenseType;

        public String partnerName; 

        public string partnerEmail;

        public string salesRepEmail;

        public String partnerMarkets;

        public String referralCode;

        public Boolean csEnabled;

        public Boolean storageEnabled;

        public String csApplicationType;
    }

    @AuraEnabled 
    public static PartnerProfile getPartnerProfile() {
        PartnerProfile partnerProfile = new PartnerProfile();

        User u = [SELECT Id, Partner_Id__c, Sales_Representative_Id__c, Contact.Partner_Lookup__c, 
                    Contact.Account.Enable_CS_Application_in_Portal__c, Contact.Sales_Representative__r.Custom_ID__c,
                    Contact.Partner_Lookup__r.Name, Sales_Representative_Email__c, Contact.Partner_Lookup__r.Email__c,
                    PortalRole, Profile.Name, Contact.Account.State_Market__c, UserRole.Name, Contact.Account.Community_Solar_Application_Type__c,
                    Contact.Account.Enable_Storage_Application_in_Portal__c
                  FROM User 
                  WHERE Id = :UserInfo.getUserId()];
        if (u.Partner_Id__c == null || u.Sales_Representative_Id__c == null) {
            // No Partner ID for this internal user, use the BWCC user's Partner ID instead
             partnerProfile.partnerId = getBWCCId();
        } else {
            // Needs to be 15 characters since that's what is used in the Partner field on the Contact record?
             partnerProfile.partnerId = String.valueOf(u.Partner_Id__c).subString(0,15);
             partnerProfile.salesRepId = String.valueOf(u.Sales_Representative_Id__c).subString(0,15);
             partnerProfile.partnerMarkets = String.valueof(u.Contact.Account.State_Market__c);
             if(u.Contact.Sales_Representative__r.Custom_ID__c != null){
                partnerProfile.referralCode = String.valueof(u.Contact.Sales_Representative__r.Custom_ID__c);
             } else {
                partnerProfile.referralCode = 'bluewave';
             }
             partnerProfile.csEnabled = u.Contact.Account.Enable_CS_Application_in_Portal__c;
             partnerProfile.storageEnabled = u.Contact.Account.Enable_Storage_Application_in_Portal__c;
             if (u.Contact.Account.Enable_CS_Application_in_Portal__c) {
               partnerProfile.csApplicationType = u.Contact.Account.Community_Solar_Application_Type__c;
             }
             if (String.isNotBlank(u.Sales_Representative_Email__c)) {
                 partnerProfile.salesRepEmail = String.valueOf(u.Sales_Representative_Email__c);
             }
             if (u.UserRole.Name.Contains('User')) {
                 partnerProfile.licenseType = 'User';
             } else if (u.UserRole.Name.Contains('Manager')) {
                partnerProfile.licenseType = 'Manager';
             } else if (u.UserRole.Name.Contains('Executive')) {
                partnerProfile.licenseType = 'Executive';
             }
             partnerProfile.partnerName = u.Contact.Partner_Lookup__r.Name;
             partnerProfile.partnerEmail = u.Contact.Partner_Lookup__r.Email__c;
        }
        return partnerProfile;
    }

    @AuraEnabled 
    public static String getPartnerId() {
        if (partnerIdVar == null) {
            // The saved Partner ID isn't set... set it
            User u = [SELECT Id, Partner_Id__c, Sales_Representative_Id__c, Contact.Partner_Lookup__c 
                      FROM User 
                      WHERE Id = :UserInfo.getUserId()];
            if (u.Partner_Id__c == null) {
                // No Partner ID for this internal user, use the BWCC user's Partner ID instead
                partnerIdVar = getBWCCId();
            } else {
                // Needs to be 15 characters since that's what is used in the Partner field on the Contact record?
                partnerIdVar = String.valueOf(u.Partner_Id__c).subString(0,15);
            }
        }
        return partnerIdVar;
    }

    @AuraEnabled         
    // Get the BlueWave Customer Care Partner Id, or if that doesn't exist, another test Partner to use
    public static String getBWCCId() {
        Partner__c partnerRecord;
        Partner__c[] partnerRecords = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Customer Care'];
        if (!partnerRecords.isEmpty()) {
            partnerRecord = partnerRecords[0];
        } else {
            List<Partner__c> backupPartners = [
                SELECT Id FROM Partner__c
                WHERE Name LIKE '%BlueWave%'
                OR Name LIKE '%Testcase%'
                LIMIT 1
            ];
            if (!backupPartners.isEmpty()) {
                partnerRecord = backupPartners[0];
            } else {
                return null;
            }
        }
        return(String.valueOf(partnerRecord.Id).subString(0,15));
    }

    @AuraEnabled
    public static List<String> getPartnerLogo() {
        Partner__c partner;
        List<String> logoList = new List<String>();

        partner = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Id = : getPartnerId()];
        logoList.add(partner.Logo__c);
        return logoList;
    }             
}