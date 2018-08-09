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
        customerUser = [SELECT Id, FirstName, LastName, ContactId, Client_Brand_Key__c, Parent_account_id__c, Contact.Account.Id, Contact.AccountId, Contact.Product_Line__c
        FROM User
        WHERE Id = :UserInfo.getUserId()];
    }

    @AuraEnabled
    public static Contact getContactInfo() {
        User u =  [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
        Contact c;
        if (u.ContactId != null) {
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
        List<Account> propertyAccountLabelList = [
            SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c
            FROM Account
            WHERE Parent_Account__c = : customerUser.Contact.AccountId];

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

            for (AggregateResult systemBillsListParent : [
                SELECT Account_Bill__c,
                    Shared_Solar_System__r.BWC_Project_Entity_Manual__c Entity__c,
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

            for ( AggregateResult systemBillsListProperty : [
                SELECT Account_Bill__c,
                    Shared_Solar_System__r.BWC_Project_Entity_Manual__c Entity__c,
                    SUM(Carry_Over_Balance__c) ChargentOrders__Subtotal__c
                FROM System_Bill__c
                WHERE Account_Bill__r.Id = : mostRecentAccountBill.Id
                GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c
            ]) {
                aggresultlist.add(systemBillsListProperty);
            }
        }
        return aggresultlist;
    }

    @AuraEnabled
    public static List<Account_Bill__c> getAccountBills (String propertyAccountId) {
        User u = customerUser;
        List<Account_Bill__c> accountBillList = new List<Account_Bill__c>();
        if (propertyAccountId == 'All' || propertyAccountId == null) {
            for (Account_Bill__c accountBillAll : [  SELECT Parent_Account__r.Name, Date__c, Activity_Type__c,
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
        } else {
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
        if (propertyAccountId == 'All' || propertyAccountId == null) {
            List<ChargentOrders__ChargentOrder__c> chargentOrderList = [
                SELECT  Account_Bill__r.Parent_Account__r.Name,
                    ChargentOrders__Payment_Status__c,
                    ChargentOrders__Bank_Account_Number__c,
                    ChargentOrders__Card_Number__c,
                    ChargentOrders__Next_Transaction_Date__c,
                    Entity__r.Name
                FROM ChargentOrders__ChargentOrder__c
                WHERE Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                ORDER BY CreatedDate DESC
                LIMIT 1];
            if (chargentOrderList.size() > 0) {
                chargentOrder = chargentOrderList[0];
            }
        } else {
            List<ChargentOrders__ChargentOrder__c> chargentOrderList = [
                SELECT  Account_Bill__r.Parent_Account__r.Name,
                    ChargentOrders__Payment_Status__c,
                    ChargentOrders__Bank_Account_Number__c,
                    ChargentOrders__Card_Number__c,
                    ChargentOrders__Next_Transaction_Date__c,
                    Entity__r.Name
                FROM ChargentOrders__ChargentOrder__c
                WHERE Account_Bill__r.Parent_Account__r.Id = : propertyAccountId
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                ORDER BY CreatedDate DESC
                LIMIT 1];
            if (chargentOrderList.size() > 0) {
                chargentOrder = chargentOrderList[0];
            }
        }
        return chargentOrder;
    }

    @AuraEnabled
    public static List<ChargentOrders__Transaction__c > getTransactions (String propertyAccountId) {
        User u = customerUser;
        List<ChargentOrders__Transaction__c> chargentTransactionsList = new List<ChargentOrders__Transaction__c>();
        if (propertyAccountId == 'All' || propertyAccountId == null) {
            for (ChargentOrders__Transaction__c chargentTransactionsAll : [  SELECT ChargentOrders__Type__c, Activity_Type__c,
                Negative_Amount__c,
                ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name,
                ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c,
                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                ChargentOrders__Order__r.ChargentOrders__Bank_Account_Number__c,
                ChargentOrders__Order__r.ChargentOrders__Card_Number__c,
                ChargentOrders__Order__r.ChargentOrders__Next_Transaction_Date__c,
                ChargentOrders__Order__r.Entity__r.Name ,
                ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
            AND ChargentOrders__Response_Status__c = 'Approved'
            ORDER BY CreatedDate DESC]) {

                chargentTransactionsList.add(chargentTransactionsAll);
            }
        } else {
            for(ChargentOrders__Transaction__c chargentTransactionsProperty : [ SELECT ChargentOrders__Type__c, Activity_Type__c,Negative_Amount__c,
                ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name,
                ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c,
                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                ChargentOrders__Order__r.ChargentOrders__Bank_Account_Number__c,
                ChargentOrders__Order__r.ChargentOrders__Card_Number__c,
                ChargentOrders__Order__r.ChargentOrders__Next_Transaction_Date__c,
                ChargentOrders__Order__r.Entity__r.Name,
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

    // If partner is passed (from a URL parameter) use that.
    // If it's an installer, use that partner
    // Otherwise, use the default partner (if a guest user)
    @AuraEnabled
    public static Partner__c getPartner(String partnerId){
        Partner__c partner = new Partner__c();

        if (partnerId != null && partnerId != '') {
            partner = [
                SELECT Id, Email__c, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Name
                FROM Partner__c
                WHERE Id = :partnerId
                LIMIT 1
            ];
        } else if (UserInfo.getUserType() == 'PowerPartner') {
            partner = [
                SELECT Id, Email__c, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Name
                FROM Partner__c
                WHERE Id = :CSAPController.profile.partnerId
                LIMIT 1
            ];
        } else {
            List<Partner__c> partners = [
                SELECT Id, Email__c, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Name
                FROM Partner__c
                WHERE CS_Referral_Status__c = 'Default CS Partner'
            ];
            if (partners.isEmpty()) {
                return null;
            } else {
                partner = partners[0];
            }
        }

        return partner;
    }


    @AuraEnabled
    public static String sendEmail(String emailAddress) {
        try {
            EmailTemplate et = [Select Id, HtmlValue from EmailTemplate where DeveloperName = 'Community_Referral_email'];
            User u = customerUser;
            Partner__c customerPartner;
            BSST__c salesRep;

            String htmlBody = et.HtmlValue;

            Opportunity opp = getMostRecentOpportunityInfo();

            if (opp != null) {
                customerPartner = getPartner(opp.Partner_tag_lookup__c);

                if (opp.BS_Sales_ID__c != null) {
                    salesRep = [SELECT Id, Name FROM BSST__c WHERE Id = :opp.BS_Sales_ID__c LIMIT 1];
                } else {
                    salesRep = new BSST__c(Id = customerPartner.Default_Sales_Rep__c, Name = customerPartner.Default_Sales_Rep__r.Name);
                }
            } else {
                customerPartner = getPartner(null);
                salesRep = new BSST__c(Id = customerPartner.Default_Sales_Rep__c, Name = customerPartner.Default_Sales_Rep__r.Name);
            }

            htmlBody = htmlBody.replace('{!Account.Sales_RepresentativeId__c}', salesRep.Id);
            htmlBody = htmlBody.replace('{!Account.PartnerId__c}', customerPartner.Id);
            htmlBody = htmlBody.replace('{!Contact.Id}', u.Contact.Id);
            htmlBody = htmlBody.replace('{!Contact.FirstName}', u.FirstName);
            htmlBody = htmlBody.replace('{!Contact.LastName}', u.LastName);

            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            sem.setHtmlBody(htmlBody);
            sem.setTemplateId(et.Id);
            sem.setTargetObjectId(u.ContactId);
            sem.setSubject('A Community Solar Share for you!');
            sem.setTreatTargetObjectAsRecipient(false);
            sem.setToAddresses(new String[] { emailAddress});
            sem.setCcAddresses(new String[] { customerPartner.Email__c});

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {sem});

            if (results != null ) {
                if (results[0].isSuccess()) {

                    //CREATE TASK FOR PARTNER
                    Task emailTask = new Task();
                    emailTask.RecordTypeId = [SELECT Id, SobjectType, Name FROM RecordType WHERE Name = 'Customer Care Task' AND SobjectType = 'Task' LIMIT 1].Id;
                    emailTask.WhatId = customerPartner.Id;
                    emailTask.Product_Line__c = 'Community Solar';
                    emailTask.Subject = 'Email: Your Customer Referred a Friend for CS!';
                    emailTask.Description = 'Your customer, ' + u.FirstName + ' ' + u.LastName + ', referred a friend at ' + emailAddress + ' to join BlueWave Community Solar!';
                    insert emailTask;
                    return 'success';
                } else {
                    Logger.logNow('MyAccountController', 'sendEmail', results[0].getErrors()[0].getMessage());
                }
            }
            return 'There was an error sending the email.';


        } catch (Exception ex) {
            Logger.logNow('MyAccountController', 'sendEmail', ex.getMessage());
            return ex.getMessage();
        }
    }

    public static Opportunity getMostRecentOpportunityInfo () {
        User u = customerUser;

        Account parentAccount = [
            SELECT Id, Name, Partner__c, Sales_Representative__c
            FROM Account
            WHERE Id = :u.Parent_Account_ID__c
        ];

        Account propertyAccount = [
            SELECT Id, Product_Line__c, Name, ParentId, CreatedDate
            FROM Account
            WHERE Parent_Account__c = :parentAccount.Id AND Product_Line__c = 'Community Solar'
            ORDER BY CreatedDate DESC LIMIT 1
        ];

        List<Opportunity> oppList = [
            SELECT Id, Partner_tag_lookup__c, CloseDate, AccountId, BS_Sales_ID__c
            FROM Opportunity
            WHERE AccountID = :propertyAccount.Id AND StageName = 'Complete'
            ORDER BY CloseDate DESC LIMIT 1
        ];

        if (oppList.size() == 1) {
            return oppList[0];
        } else {
            return null;
        }

    }




}