/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: PostSandboxRefresherTest
 *************************************************************************************/
public with sharing class Logger {

    // future method should be used if the caller isn't a batch or itself a future method
    @AuraEnabled
    @future
    public static void logFuture(String className, String methodName, String message, Datetime timestamp) {
        log(className, methodName, message, timestamp);
    }

    // timestamp is expected to be in GMT (e.g. System.now()), and this will convert and log it as local time
    public static void log(String className, String methodName, String message, Datetime timestamp) {
        Error_Log__c errorLog = 
            new Error_Log__c(User__c = UserInfo.getUserID(),
                             Class__c = className,
                             Method__c = methodName,
                             Message__c = message,
                             Timestamp__c = Datetime.newInstance(timestamp.date(),
                                                                 timestamp.time()));
        Database.insert(errorLog, false);
    }
}