/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: PostSandboxRefresherTest
 *************************************************************************************/
public with sharing class Logger {

    // Apparently Lightning was getting confused if there were two log methods, even if only
    // one of them were AuraEnabled. And calling a future method from Lightning didn't seem
    // to work either.
    // This one is there for convenience to Lightning, to not deal with timestamps in js.
    @AuraEnabled
    public static void logNow(String className, String methodName, String message) {
        log(className, methodName, message, System.now());
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