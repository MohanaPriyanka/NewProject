/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: LoggerTest
 *************************************************************************************/
public with sharing class Logger {
    private Logger() {
    }

    @future
    public static void log(String className, String methodName, String message, Datetime timestamp) {
        Error_Log__c errorLog = 
            new Error_Log__c(Class__c = className,
                             Method__c = methodName,
                             Message__c = message,
                             Timestamp__c = timestamp);
    }
}