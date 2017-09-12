/*************************************************************************************
 * Created By: Cole Swain
 * 
 * Description: Creates Partner Alert Filters when new Partner Alerts are created
 *
 * Tested By: SLPControllersTestclass
 *************************************************************************************/
public with sharing class PartnerAlertHandler {
    
    public static String createPartnerAlertFilters (Partner_Alert__c[] partnerAlerts){
        Date today = Date.today();
        String alertName;
        List<User> userList = new List<User>();
        List<User> managerList = new List<User>();
        List<User> executiveList = new List<User>();
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();
        for (User user : [SELECT Id, UserRole.Name, Contact.Sales_Representative__r.Id, Contact.Sales_Representative__r.Name
                          FROM User
                          WHERE Profile.Name IN ('Partner Community User (Custom)', 'Partner Community Login User (Custom)')]) {
            if (user.UserRole.Name.Contains('User')) {
                userList.add(user);                
            } else if (user.UserRole.Name.Contains('Manager')) {
                managerList.add(user);                
            } else if (user.UserRole.Name.Contains('Executive')) {
                executiveList.add(user);                
            }
        }
        for (Partner_Alert__c partnerAlert : partnerAlerts) {
            if (partnerAlert.Audience__c.Contains('Users')) {
                for (User userRecord : userList) {
                    alertName = userRecord.Contact.Sales_Representative__r.Name + ' - ' + partnerAlert.Name + ' - ' + today;
                    if (alertName.length() >= 80) {
                        alertName = alertName.subString(0, 80);
                    }
                    Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
                    Partner_Alert__c = partnerAlert.Id,
                    Sales_Representative__c = userRecord.Contact.Sales_Representative__r.Id,
                    Name = alertName);
                    partnerAlertFilterList.add(alertFilter);                      
                }
            }
            if (partnerAlert.Audience__c.Contains('Managers')) {
                for (User userRecord : managerList) {
                    alertName = userRecord.Contact.Sales_Representative__r.Name + ' - ' + partnerAlert.Name + ' - ' + today;
                    if (alertName.length() >= 80) {
                        alertName = alertName.subString(0, 80);
                    }
                    Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
                    Partner_Alert__c = partnerAlert.Id,
                    Sales_Representative__c = userRecord.Contact.Sales_Representative__r.Id,
                    Name = alertName);
                    partnerAlertFilterList.add(alertFilter);                      
                }
            }
            if (partnerAlert.Audience__c.Contains('Executives')) {
                for (User userRecord : executiveList) {
                    alertName = userRecord.Contact.Sales_Representative__r.Name + ' - ' + partnerAlert.Name + ' - ' + today;
                    if (alertName.length() >= 80) {
                        alertName = alertName.subString(0, 80);
                    }
                    Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
                    Partner_Alert__c = partnerAlert.Id,
                    Sales_Representative__c = userRecord.Contact.Sales_Representative__r.Id,
                    Name = alertName);
                    partnerAlertFilterList.add(alertFilter);                      
                }
            }                        
        }
    	insert partnerAlertFilterList;
    	return 'Success';	
    }   
}