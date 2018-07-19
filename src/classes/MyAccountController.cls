/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 * 
 * Description: This class handles most actions needed to be performed by the Community Solar Customer Portal's My Account Page.
 * 
 Tested By: CommunitySolarCUstomerPortalTest
 *************************************************************************************/

public without sharing class MyAccountController {

    public static User customerUser = new User();
    static {
        customerUser = [SELECT Id, FirstName, LastName, ContactId, Client_Brand_Key__c, Parent_account_id__c, Contact.Account.Id, Contact.AccountId, Contact.Product_Line__c,
                                 Contact.Account.Partner__c, Contact.Account.Sales_Representative__c, Contact.Customer_Referral_Code__c
                        FROM User 
                        WHERE Id = :UserInfo.getUserId()];
    }

    @AuraEnabled
    public static Contact getContactInfo() {
        User u =  [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
        Contact c;
        if(u.ContactId != null) {
            try {
                c = [Select Id, Phone, MobilePhone, Email, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact where Id = :u.ContactId];
            }
            catch(Exception ex) {
                
            }
        }
        return c;
    }
    
    @AuraEnabled
    public static Contact updateContactInfo(Contact contactToUpdate) {
        update contactToUpdate;
        return contactToUpdate;
    }

    @AuraEnabled
    public static User getUser() {
        return customerUser;
    }

    @AuraEnabled
    public static List<Account> getMenuLabelList() {
        list<Account> propertyAccountLabelList = new list<Account>();
        User u = customerUser;
        String userAccountId = (String)u.Contact.Account.Id;      
        for(Account propertyAccount : [ SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c 
                                        FROM Account 
                                        WHERE Parent_Account__c = : u.Contact.AccountId]) {
            propertyAccountLabelList.add(propertyAccount);
        }    
        return propertyAccountLabelList;
    }

    @AuraEnabled
    public static List<AggregateResult> getSystemBills(String propertyAccountId) {
        User u = customerUser;
        List<AggregateResult> aggresultlist = new List<AggregateResult>();
        Decimal maxBillNumber = 0;
        if (propertyAccountId == 'All' || propertyAccountId == null) {
            List<Account_Bill__c> acctBillsParent = [
                SELECT Id, Name, Bill_Number__c, Parent_Account__r.Max_Account_Bill_Number__c
                FROM Account_Bill__c
                WHERE Account_ID__c = : u.Parent_Account_ID__c
                AND Published__c = true
                AND Is_Most_Recent__c = true
                ORDER BY Bill_Number__c DESC
            ];

            for (AggregateResult systemBillsListParent : [  SELECT Account_Bill__c, 
                                                                Shared_Solar_System__r.BWC_Project_Entity_Manual__c ChargentOrders__Shipping_Name__c, 
                                                                SUM(Carry_Over_Balance__c) ChargentOrders__Subtotal__c
                                                            FROM System_Bill__c
                                                            WHERE Account_Bill__c IN : acctBillsParent
                                                            GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c]) {
                aggresultlist.add(systemBillsListParent);
            }
        } else {
            Account_Bill__c mostRecentAccountBill = [
                SELECT Id, Name
                FROM Account_Bill__c
                WHERE Parent_Account__r.Id = : propertyAccountId
                AND Published__c = true
                AND Is_Most_Recent__c = true
                ORDER BY Bill_Number__c
            ];

            for( AggregateResult systemBillsListProperty : [SELECT Account_Bill__c, 
                                                                Shared_Solar_System__r.BWC_Project_Entity_Manual__c ChargentOrders__Shipping_Name__c, 
                                                                SUM(Carry_Over_Balance__c) ChargentOrders__Subtotal__c
                                                            FROM System_Bill__c
                                                            WHERE Account_Bill__r.Id = : mostRecentAccountBill.Id
                                                            GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c]) {
                aggresultlist.add(systemBillsListProperty);
            }                                      
        }
        return aggresultlist;  
    }  

    @AuraEnabled
    public static List<Account_Bill__c> getAccountBills (String propertyAccountId) {
        User u = customerUser;
        List<Account_Bill__c> accountBillList = new List<Account_Bill__c>();
        if(propertyAccountId == 'All' || propertyAccountId == null) {
            for(Account_Bill__c accountBillAll : [  SELECT Parent_Account__r.Name, Date__c, Activity_Type__c, 
                                                        Due_this_month__c, Total_Due_This_Month__c, Total_Due__c, 
                                                        Carry_Over_Balance__c, Bill_number__c, Bill_Attach_Document__c,
                                                        Savings_Rollup__c, Subscription_Production_kWh__c, Published__c,
                                                        Balance_Net_Late_Payments__c, Date_of_Last_Payment__c, 
                                                        Due_Date_SB__c, Total_due_minus_payment_plan__c
                                                    FROM Account_Bill__c
                                                    WHERE Account_ID__c = : u.Parent_Account_ID__c
                                                    AND Published__c = true
                                                    ORDER BY Bill_Number__c DESC]) {
                accountBillList.add(accountBillAll);
            }
        }
        else{
            for(Account_Bill__c accountBillProperty : [ SELECT Parent_Account__r.Name, Date__c, Activity_Type__c,
                                                            Due_this_month__c, Balance_Net_Late_Payments__c,
                                                            Total_Due_This_Month__c, Total_due_minus_payment_plan__c,
                                                            Savings_Rollup__c, Subscription_Production_kWh__c, Published__c,
                                                            Total_Due__c, Due_Date_SB__c, Carry_Over_Balance__c, 
                                                            Bill_number__c, Bill_Attach_Document__c
                                                        FROM Account_Bill__c
                                                        WHERE Parent_Account__r.Id = : propertyAccountId
                                                        AND Published__c = true
                                                        ORDER BY Bill_Number__c DESC]) {
                accountBillList.add(accountBillProperty);
            }
        }
        return accountBillList;
    }

    @AuraEnabled
    public static ChargentOrders__ChargentOrder__c getChargentOrder (String propertyAccountId) {
        User u = customerUser;
        ChargentOrders__ChargentOrder__c chargentOrder;
        if(propertyAccountId == 'All' || propertyAccountId == null) {
            List<ChargentOrders__ChargentOrder__c> chargentOrderList = [
                SELECT  Account_Bill__r.Parent_Account__r.Name,
                    ChargentOrders__Payment_Status__c,
                    ChargentOrders__Bank_Account_Number__c,
                    ChargentOrders__Card_Number__c,
                    ChargentOrders__Next_Transaction_Date__c,
                    ChargentOrders__Gateway__r.Entity__r.Name
                FROM ChargentOrders__ChargentOrder__c
                WHERE Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                ORDER BY CreatedDate DESC
                LIMIT 1];
            if(chargentOrderList.size() > 0){
                chargentOrder = chargentOrderList[0];
            }
        }
        else{
            List<ChargentOrders__ChargentOrder__c> chargentOrderList = [
                SELECT  Account_Bill__r.Parent_Account__r.Name,
                    ChargentOrders__Payment_Status__c,
                    ChargentOrders__Bank_Account_Number__c,
                    ChargentOrders__Card_Number__c,
                    ChargentOrders__Next_Transaction_Date__c,
                    ChargentOrders__Gateway__r.Entity__r.Name
                FROM ChargentOrders__ChargentOrder__c
                WHERE Account_Bill__r.Parent_Account__r.Id = : propertyAccountId
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                ORDER BY CreatedDate DESC
                LIMIT 1];
            if(chargentOrderList.size() > 0){
                chargentOrder = chargentOrderList[0];
            }
        }
        return chargentOrder;
    }

    @AuraEnabled
    public static List<ChargentOrders__Transaction__c > getTransactions (String propertyAccountId) {
        User u = customerUser;
        List<ChargentOrders__Transaction__c> chargentTransactionsList = new List<ChargentOrders__Transaction__c>();
        if(propertyAccountId == 'All' || propertyAccountId == null) {
            for(ChargentOrders__Transaction__c chargentTransactionsAll : [  SELECT ChargentOrders__Type__c, Activity_Type__c, 
                                                                                Negative_Amount__c, 
                                                                                ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name, 
                                                                                ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                                ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c, 
                                                                                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                                                                                ChargentOrders__Order__r.ChargentOrders__Bank_Account_Number__c,
                                                                                ChargentOrders__Order__r.ChargentOrders__Card_Number__c,
                                                                                ChargentOrders__Order__r.ChargentOrders__Next_Transaction_Date__c,
                                                                                ChargentOrders__Order__r.ChargentOrders__Gateway__r.Entity__r.Name , 
                                                                                ChargentOrders__Response_Status__c 
                                                                            FROM ChargentOrders__Transaction__c
                                                                            WHERE ChargentOrders__Order__r.Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
                                                                            AND ChargentOrders__Response_Status__c = 'Approved'
                                                                            ORDER BY CreatedDate DESC]) {
            
                chargentTransactionsList.add(chargentTransactionsAll);
            }
        }
        else{
            for(ChargentOrders__Transaction__c chargentTransactionsProperty : [ SELECT ChargentOrders__Type__c, Activity_Type__c,Negative_Amount__c, 
                                                                                    ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name, 
                                                                                    ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                                    ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c,
                                                                                    ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                                                                                    ChargentOrders__Order__r.ChargentOrders__Bank_Account_Number__c,
                                                                                    ChargentOrders__Order__r.ChargentOrders__Card_Number__c,
                                                                                    ChargentOrders__Order__r.ChargentOrders__Next_Transaction_Date__c,
                                                                                    ChargentOrders__Order__r.ChargentOrders__Gateway__r.Entity__r.Name, 
                                                                                    ChargentOrders__Response_Status__c 
                                                                                FROM ChargentOrders__Transaction__c
                                                                                WHERE ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id = : propertyAccountId
                                                                                AND ChargentOrders__Response_Status__c = 'Approved'
                                                                                ORDER BY CreatedDate DESC]) {
                chargentTransactionsList.add(chargentTransactionsProperty);
            }
        }
        return chargentTransactionsList;
    }  

    @AuraEnabled
    public static String getCode() {
        User u = customerUser;
        String code;
        if(u.ContactId != null) {
            try {
              code = [Select Id, Referral_Code__c from Contact where Id = :u.ContactId].Referral_Code__c;
            }catch(Exception ex) { 
            }
        }
        return code;
    }  

   @AuraEnabled
   public static String sendEmail(String emailAddress) {
        try {
            EmailTemplate et = [Select Id from EmailTemplate where DeveloperName = 'Community_Referral_email'];
            User u = customerUser;
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            sem.setTemplateId(et.Id);
            sem.setTargetObjectId(u.ContactId);
            sem.setTreatTargetObjectAsRecipient(false);
            sem.setToAddresses(new String[] { emailAddress});
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {sem});
            if(results != null && results[0].isSuccess()) {
                return 'success';
            }
            if(results[0] != null)
                return results[0].getErrors()[0].getMessage();
            return 'There was an error sending the email.';
        } catch (Exception ex) {
           return ex.getMessage();
        }
    }

    @AuraEnabled
    public static String generateReferralURL () {
        String referralUrl;
        if (customerUser.Contact.Product_Line__c == 'Community Solar') {
            String host = URL.getSalesforceBaseUrl().toExternalForm() + '/';
            referralUrl = host + 'apply/s/csap';
            //grabbing partner info when in the partner portal
            //want to generate link when in the customers portal

            if (customerUser.Contact.Account.Partner__c != null && customerUser.Contact.Customer_Referral_Code__c != null) {
                referralUrl += '?partnerId=' + customerUser.Contact.Account.Partner__c + '&salesRepId=' + customerUser.Contact.Account.Sales_Representative__c +
                    '&referralCode=' + customerUser.Contact.Customer_Referral_Code__c;
                //add referral code to url
                //referralUrl += '?referralCode=' + customerUser.Contact.Customer_Referral_Code__c;

            } else if (customerUser.Contact.Customer_Referral_Code__c != null) {
                //Dont know whats gonna happen here with an else--> dont want to send them to form assembly
                referralUrl = 'http://www.ebay.com';
                //referralUrl = 'https://forms.bluewaverenewables.com/381687?tfa_531=' + customerUser.Contact.Customer_Referral_Code__c;
            } else if (customerUser.Contact.Customer_Referral_Code__c != null) {
                referralUrl = 'http://amazon.com';
            }
        }
            return referralUrl;
        }


}