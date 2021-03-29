/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Assists in logging debug and error messages to a custom object
 * https://developer.salesforce.com/page/An_Introduction_to_Exception_Handling#Logging_in_a_custom_object
 * Tested By: LoggerTest
 *************************************************************************************/
public with sharing class Logger implements fflib_SObjectUnitOfWork.IDoWork {
    @TestVisible private static Map<String, List<Log>> logs;
    private static Integer timesLogsCleared = 0;
    public static final String ERROR = 'Error';
    public static final String WARN = 'Warn';
    public static final String DEBUG = 'Debug';
    public static final String INFO = 'Info';
    public static final String FINE = 'Fine';
    private static Map<String, Integer> severityToInt =
        new Map<String, Integer>{FINE => 1, INFO => 2, DEBUG => 3, WARN => 4, ERROR => 5};
    @TestVisible private static System_Properties__c systemProperty;

    static {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperty = systemProperties.size() > 0 ? systemProperties[0] : new System_Properties__c();
    }

    // Unfortunately, LWC doesn't see the overloaded logNow method we get this error and need to add this method
    // Error:(1, 1) Apex action method 'Logger.logNow' must be static and annotated with AuraEnabled
    @AuraEnabled
    public static void insertLog(String className, String methodName, String message, String severity) {
        logNow(className, methodName, message, severity);
    }
    
    // Apparently Lightning was getting confused if there were two log methods, even if only
    // one of them were AuraEnabled. And calling a future method from Lightning didn't seem
    // to work either.
    // This one is there for convenience to Lightning, to not deal with timestamps in js.
    @AuraEnabled
    public static void logNow(String className, String methodName, String message, String severity) {
        if (severity == null) {
            severity = ERROR;
        }
        insertLog(className, methodName, message, System.now(), severity);
    }

    public static void logNow(String className, String methodName, String message) {
        insertLog(className, methodName, message, System.now(), ERROR);
    }

    public static void logNow(String className, String methodName, Exception excep, String additionalMessage, String severity){
        String message =  excep.getMessage() + '\n' + additionalMessage + '\n' + excep.getStackTraceString();
        logNow(className, methodName, message, severity);
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
        if (logs == null) {
            return;
        }
        for (String key : logs.keySet()) {
            logKey(key);
        }
        logs = null;
    }

    private static void logKey(String logKey) {
        String message = '';
        String className;
        String methodName;
        String severity;
        for (Log l : logs.get(logKey)) {
            // Don't add additional log messages if the length is going to go over the field definition limit of 130k
            if (message.length() > 0 && message.length() + l.message.length() > 130000) {
                message += l.message.substringBefore('\n') + '...\n';
            } else {
                message += l.message + '\n';
            }
            className = l.className;
            methodName = l.method;
            severity = l.severity;
        }
        insertLog(className, methodName, message, System.now(), severity);
    }

    public static void clearLogs() {
        timesLogsCleared++;
        for (String key : logs.keySet()) {
            logs.put(key+timesLogsCleared, logs.get(key));
            logs.remove(key);
        }
    }

    // timestamp is expected to be in GMT (e.g. System.now()), and this will convert and log it as local time
    private static void insertLog(String className, String methodName, String message, Datetime timestamp, String severity) {
        Error_Log__c errorLog =
            new Error_Log__c(
                User__c = UserInfo.getUserId(),
                Class__c = className,
                Method__c = methodName,
                Message__c = message.left(130000),
                Severity__c = severity,
                Timestamp__c = Datetime.newInstance(timestamp.date(), timestamp.time()),
                Limits_CPU_Time_Used__c = Limits.getCpuTime(),
                Limits_CPU_Time_Max__c = Limits.getLimitCpuTime(),
                Limits_Heap_Size_Used__c = Limits.getHeapSize(),
                Limits_Heap_Size_Max__c = Limits.getLimitHeapSize(),
                Limits_SOQL_Queries_Used__c = Limits.getQueries(),
                Limits_SOQL_Queries_Max__c = Limits.getLimitQueries(),
                Limits_SOQL_Query_Rows_Used__c = Limits.getQueryRows(),
                Limits_SOQL_Query_Rows_Max__c = Limits.getLimitQueryRows(),
                Limits_DML_Statements_Used__c = Limits.getDmlStatements(),
                Limits_DML_Statements_Max__c = Limits.getLimitDmlStatements(),
                Limits_DML_Rows_Used__c = Limits.getDmlRows(),
                Limits_DML_Rows_Max__c = Limits.getLimitDmlRows());
        if (shouldLog(severity) || closeToLimits(errorLog)) {
            Database.insert(errorLog, false);
        }
    }

    public static Boolean shouldLog(String severity) {
        if (severityToInt.containsKey(severity) &&
            severityToInt.containsKey(systemProperty.Log_Level__c)) {
            return severityToInt.get(severity) >= severityToInt.get(systemProperty.Log_Level__c);
        } else {
            return true;
        }
    }

    private static Boolean closeToLimits(Error_Log__c errorLog) {
        Formula.recalculateFormulas(new List<Error_Log__c>{errorLog});
        return errorLog.Max_Limit_Used__c > systemProperty.Log_Limit_Threshold__c;
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

    public void doWork() {
        Logger.flushLogs();
    }
}