/*************************************************************************************
 * Created By:  Cole Swain
 *
 * Description: This class handles most actions needed to be performed by the Community Solar Customer Portal's My Account Page.
 *
 * Tested By: CommunitySolarCustomerPortalTest,CSPaymentTest
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
    public static Shared_Solar_System__c getProject(String projectId) {
        return SharedSolarSystemsSelector.getMyProject(projectId);
    }

    @AuraEnabled
    public static List<Account> getMenuLabelList() {
        List<Account> propertyAccountLabelList = [
            SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance_Merge__c
            FROM Account
            WHERE Parent_Account__c = : customerUser.Contact.AccountId];

        return propertyAccountLabelList;
    }

    @AuraEnabled
    public static List<String> getPaymentMethods(String propertyAccountId) {
        return(convertPaymentMethods(getGatewayPaymentMethods(propertyAccountId)));
    }

    public static Map<String, String> PAYMENT_MAP = new Map<String, String>{
        'eCheck'=>'ACH', 'Bank Transfer'=>'ACH', 'Cash Transfer'=>'ACH', 'Credit Card'=>'Credit Card'};

    // Converts Gateway payment methods to {'ACH', 'Credit Card'} for use in Chargent Orders
    // We only want to add a payment method if ALL gateways accept that payment method, since the order will be applied
    // across all gateways
    @TestVisible
    private static List<String> convertPaymentMethods(List<String> gatewayPaymentMethods) {
        List<String> chargentOrderList = new List<String>();
        Map<String, Integer> paymentMethodCountMap = new Map<String, Integer>();
        for (String gatewayMethods : gatewayPaymentMethods) {
            updatePaymentMethodCountMap(gatewayMethods, paymentMethodCountMap);
        }
        for (String method : paymentMethodCountMap.keySet()) {
            if (paymentMethodCountMap.get(method) == gatewayPaymentMethods.size()) {
                chargentOrderList.add(method);
            }
        }
        chargentOrderList.sort();
        return chargentOrderList;
    }

    private static void updatePaymentMethodCountMap(String gatewayMethods, Map<String, Integer> paymentMap) {
        List<String> gatewayMethodList = gatewayMethods.split(';');
        Set<String> gatewayMethodsSet = new Set<String>();
        for (String gatewayMethod : gatewayMethodList) {
            if (PAYMENT_MAP.get(gatewayMethod) != null) {
                gatewayMethodsSet.add(PAYMENT_MAP.get(gatewayMethod));
            } else {
                throw new AuraHandledException('Unexpected payment method found: ' + gatewayMethod);
            }
        }
        for (String method : gatewayMethodsSet) {
            if (paymentMap.get(method) != null) {
                paymentMap.put(method, paymentMap.get(method) + 1);
            } else {
                paymentMap.put(method, 1);
            }
        }
    }

    // Returns a list of strings like {'eCheck;Bank Transfer', 'Credit Card;eCheck'} from Gateways related to
    // System Bills if they exist, or Opportunities if not. There will be one element in the list for each gateway
    private static List<String> getGatewayPaymentMethods(String propertyAccountId) {
        Set<String> paymentMethods = new Set<String>();
        List<Account_Bill__c> accountBills = getAccountBills(propertyAccountId);
        List<System_Bill__c> systemBills = [
            SELECT Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c
            FROM System_Bill__c
            WHERE Account_Bill__c IN :accountBills
        ];
        if (systemBills.isEmpty()) {
            List<Opportunity> opps;
            if (propertyAccountId == 'All' || propertyAccountId == null) {
                User u = customerUser;
                opps = [
                    SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c
                    FROM Opportunity
                    WHERE Account.Parent_Account__c = :u.Parent_Account_ID__c
                ];
            } else {
                opps = [
                    SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c
                    FROM Opportunity
                    WHERE AccountId = :propertyAccountId
                ];
            }
            for (Opportunity opp : opps) {
                if (opp.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c == null) {
                    throw new AuraHandledException('Unconfigured gateway found for propertyAccountId: ' + propertyAccountId);
                }
                paymentMethods.add(opp.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c);
            }
        } else {
            for (System_Bill__c systemBill : systemBills) {
                if (systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c == null) {
                    throw new AuraHandledException('Unconfigured gateway found for propertyAccountId: ' + propertyAccountId);
                }
                paymentMethods.add(systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.ChargentBase__Available_Payment_Methods__c);
            }
        }
        return new List<String>(paymentMethods);
    }

    @AuraEnabled
    public static List<AggregateResult> getSystemBills(String propertyAccountId) {
        List<Account_Bill__c> accountBills = getAccountBills(propertyAccountId);
        // Need to go backwards since we might be removing elements from the list
        for (Integer i = accountBills.size()-1; i >= 0; i--) {
            if (!accountBills[i].Is_Most_Recent__c) {
                accountBills.remove(i);
            }
        }
        return aggregateSystemBills(accountBills);
    }

    private static List<AggregateResult> aggregateSystemBills(List<Account_Bill__c> accountBills) {
        return [
            SELECT Account_Bill__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__c Entity__c,
                SUM(Carry_Over_Balance__c) ChargentOrders__Subtotal__c
            FROM System_Bill__c
            WHERE Account_Bill__c IN :accountBills
            GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c
        ];
    }

    @AuraEnabled
    public static List<Account_Bill__c> getAccountBills (String propertyAccountId) {
        User u = customerUser;
        if (propertyAccountId == 'All' || propertyAccountId == null) {
            return [
                SELECT Parent_Account__r.Name, Date__c, Activity_Type__c,
                    Due_This_Month__c, Total_Due_This_Month__c, Total_Due__c,
                    Carry_Over_Balance__c, Bill_Number__c, Bill_Attach_Document__c,
                    Savings_Rollup__c, Subscription_Production_kWh__c, Published__c,
                    Balance_Net_Late_Payments__c,
                    Due_Date_SB__c, Total_Due_Minus_Payment_Plan__c, Is_Most_Recent__c
                FROM Account_Bill__c
                WHERE Account_ID__c = : u.Parent_Account_ID__c
                AND Published__c = TRUE
                ORDER BY Bill_Number__c DESC
            ];
        } else {
            return [
                SELECT Parent_Account__r.Name, Date__c, Activity_Type__c,
                    Due_This_Month__c, Balance_Net_Late_Payments__c,
                    Total_Due_This_Month__c, Total_Due_Minus_Payment_Plan__c,
                    Savings_Rollup__c, Subscription_Production_kWh__c, Published__c,
                    Total_Due__c, Due_Date_SB__c, Carry_Over_Balance__c,
                    Bill_Number__c, Bill_Attach_Document__c, Is_Most_Recent__c
                FROM Account_Bill__c
                WHERE Parent_Account__r.Id = :propertyAccountId
                AND Published__c = TRUE
                ORDER BY Bill_Number__c DESC
            ];
        }
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
                ChargentOrders__Amount__c,
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
                ChargentOrders__Amount__c,
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

    // If partner is passed (from a URL parameter) use partnerId
    // Otherwise, use the default partner (if a guest user)
    @AuraEnabled
    public static Partner__c getPartner(String partnerId){
        Partner__c partner = new Partner__c();

        try {
            partner = PartnerSelector.selectPartnerByPartnerId(partnerId);
        } catch (Exception e ) {
            partner = PartnerSelector.selectDefaultCSPartner();
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
            SELECT Id, Partner_tag_lookup__c, Name, CloseDate, AccountId, BS_Sales_ID__c
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