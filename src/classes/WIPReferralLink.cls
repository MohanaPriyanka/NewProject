/**
 * Created by Sarah Renfro on 7/17/2018.
 */

//Should probably put this in the MyAccountController for the customer portal
//And then build out the lightning component?
public with sharing class WIPReferralLink {

    //Grabbing profile of customer in the member portal
    public static User customerUser = new User();
    static {
        customerUser = [SELECT Id, FirstName, LastName, ContactId, Client_Brand_Key__c, Parent_account_id__c, Contact.Account.Id, Contact.AccountId, Contact.Product_Line__c,
                                Contact.Account.Partner__c, Contact.Account.Sales_Representative__c
        FROM User
        WHERE Id = :UserInfo.getUserId()];
    }

    @AuraEnabled
    public static String generateReferralURL () {
        String referralUrl;
        if (customerUser.Contact.Product_Line__c == 'Community Solar') {
            String host = URL.getSalesforceBaseUrl().toExternalForm() + '/';
            referralUrl = host + 'slportal/s/community-solar-application';
            //grabbing partner info when in the partner portal
            //want to generate link when in the customers portal

            if (customerUser.Contact.Account.Partner__c != null && customerUser.Contact.Account.Sales_Representative__c != null) {
                referralUrl += '?partnerId=' + customerUser.Contact.Account.Partner__c + '&salesRepId=' + customerUser.Contact.Account.Sales_Representative__c;
                //add referral code to url
                referralUrl += '?referralCode=' + customerUser.Contact.Customer_Referral_Code__c;
            }
        } else {
            //Dont know whats gonna happen here with an else--> dont want to send them to form assembly
            referralUrl = 'https://forms.bluewaverenewables.com/381687?tfa_531=' + customerUser.referralCode;
        }
        return referralUrl;
    }


}