/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: LoggerTest
 *************************************************************************************/
public with sharing class Logger {
    @TestVisible
    private static Map<String, List<Log>> logs;
    public static final String ERROR = 'Error';
    public static final String WARN = 'Warn';
    public static final String DEBUG = 'Debug';
    public static final String INFO = 'Info';
    public static final String FINE = 'Fine';
    private static System_Properties__c systemProperty;
    private static Map<String, Integer> severityToInt =
        new Map<String, Integer>{FINE => 1, INFO => 2, DEBUG => 3, WARN => 4, ERROR => 5};

    // Apparently Lightning was getting confused if there were two log methods, even if only
    // one of them were AuraEnabled. And calling a future method from Lightning didn't seem
    // to work either.
    // This one is there for convenience to Lightning, to not deal with timestamps in js.
    @AuraEnabled
    public static void logNow(String className, String methodName, String message, String severity) {
        if (severity == null) {
            severity = ERROR;
        }
        log(className, methodName, message, System.now(), severity);
    }

    public static void logNow(String className, String methodName, String message) {
        log(className, methodName, message, System.now(), ERROR);
    }

    public static void logLater(String className, String methodName, String message) {
        logLater(className, methodName, message, ERROR);
    }

    public static void logLater(String className, String methodName, String message, String severity) {
        Log l = new Log(className, methodName, message, severity);
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
                String message = '', className, methodName, severity;
                for (Log l : logs.get(logKey))  {
                    message += l.message + '\n';
                    className = l.className;
                    methodName = l.method;
                    severity = l.severity;
                }
                log(className, methodName, message, System.now(), severity);
            }
            logs = null;
        }
    }

    public static void log(String className, String methodName, String message, Datetime timestamp) {
        log(className, methodName, message, timestamp, ERROR);
    }

    // timestamp is expected to be in GMT (e.g. System.now()), and this will convert and log it as local time
    public static void log(String className, String methodName, String message, Datetime timestamp, String severity) {
        Error_Log__c errorLog =
            new Error_Log__c(
                User__c = UserInfo.getUserID(),
                Class__c = className,
                Method__c = methodName,
                Message__c = message.left(32768),
                Severity__c = severity,
                Timestamp__c = Datetime.newInstance(timestamp.date(), timestamp.time()));
        if (systemProperty == null) {
            List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
            if (systemProperties.size() > 0) {
                systemProperty = systemProperties[0];
            } else {
                systemProperty = new System_Properties__c();
            }
        }
        if (shouldLog(severity, systemProperty.Log_Level__c)) {
            Database.insert(errorLog, false);
        }
    }

    @TestVisible
    private static Boolean shouldLog(String severity, String logLevel) {
        if (severityToInt.containsKey(severity) &&
            severityToInt.containsKey(logLevel)) {
            return severityToInt.get(severity) >= severityToInt.get(logLevel);
        } else {
            return true;
        }
    }

    @TestVisible
    private class Log {
        public String className;
        public String method;
        public String message;
        public String severity;
        private Log(String className, String method, String message, String severity) {
            this.className = className;
            this.method = method;
            this.message = message;
            this.severity = severity;
        }
        private String getKey() {
            return className + '|' + method + '|' + severity;
        }
    }
}