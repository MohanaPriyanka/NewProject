/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: PostSandboxRefresherTest and LeaseDimensionsImportControllerTest
 *************************************************************************************/
public with sharing class Logger {
    private static Map<String, List<Log>> logs;

    // Apparently Lightning was getting confused if there were two log methods, even if only
    // one of them were AuraEnabled. And calling a future method from Lightning didn't seem
    // to work either.
    // This one is there for convenience to Lightning, to not deal with timestamps in js.
    @AuraEnabled
    public static void logNow(String className, String methodName, String message) {
        log(className, methodName, message, System.now());
    }

    public static void logLater(String className, String methodName, String message) {
        Log l = new Log(className, methodName, message);
        if (logs == null) {
            logs = new Map<String, List<Log>>();
        }
        if (logs.get(l.getKey()) == null) {
            logs.put(l.getKey(), new List<Log>{l});
        } else {
            logs.get(l.getKey()).add(l);
        }
    }

    public static void flushLogs() {
        if (logs != null) {
            for (String logKey : logs.keySet()) {
                String message = '', className, methodName;
                for (Log l : logs.get(logKey))  {
                    message += l.message + '\n';
                    className = l.className;
                    methodName = l.method;
                }
                log(className, methodName, message, System.now());
            }
            logs = null;
        }
    }

    // timestamp is expected to be in GMT (e.g. System.now()), and this will convert and log it as local time
    public static void log(String className, String methodName, String message, Datetime timestamp) {
        Error_Log__c errorLog = 
            new Error_Log__c(User__c = UserInfo.getUserID(),
                             Class__c = className,
                             Method__c = methodName,
                             Message__c = message.left(32768),
                             Timestamp__c = Datetime.newInstance(timestamp.date(),
                                                                 timestamp.time()));
        Database.insert(errorLog, false);
    }

    private class Log {
        private String className;
        private String method;
        private String message;
        private Log(String className, String method, String message) {
            this.className = className;
            this.method = method;
            this.message = message;
        }
        private String getKey() {
            return className + '|' + method;
        }
    }
}