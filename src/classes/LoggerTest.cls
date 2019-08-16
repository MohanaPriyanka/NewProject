/*************************************************************************************
 * Created By: peteryao on 2019-02-01  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class LoggerTest {
    @IsTest static void testLogNow() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        Logger.logNow('Class', 'Method', 'Error');
        Logger.logNow('Class', 'Method', 'Error', Logger.ERROR);
        Logger.logNow('Class', 'Method', 'Warn', Logger.WARN);
        Logger.logNow('Class', 'Method', 'Debug', Logger.DEBUG);
        Logger.logNow('Class', 'Method', 'Info', Logger.INFO);
        Logger.logNow('Class', 'Method', 'Fine', Logger.FINE);
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(6, errorLogs.size());
        for (Error_Log__c errorLog : errorLogs) {
            System.assertEquals(errorLog.Severity__c, errorLog.Message__c);
        }
    }

    @IsTest static void testLogLater() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        // Error log 1
        Logger.logLater('Class1', 'Method', 'Error');
        Logger.logLater('Class1', 'Method', 'Another Error', Logger.ERROR);
        // Error log 2
        Logger.logLater('Class2', 'Method', 'Warn', Logger.WARN);
        Logger.logLater('Class2', 'Method', 'Another Warn', Logger.WARN);
        // Error log 3
        Logger.logLater('Class2', 'Method', 'Warn', Logger.DEBUG);
        // Error log 4
        Logger.logLater('Class3', 'Method', 'Warn', Logger.WARN);
        Logger.logLater('Class3', 'Method', 'Another Warn', Logger.WARN);
        // Error log 5
        Logger.logLater('Class3', 'Method1', 'Info', Logger.INFO);
        // Error log 6
        Logger.logLater('Class3', 'Method', 'Fine', Logger.FINE);

        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        Logger.flushLogs();
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(6, errorLogs.size());
        for (Error_Log__c errorLog : errorLogs) {
            if (errorLog.Severity__c == Logger.DEBUG) {
                System.assertEquals('Warn', errorLog.Message__c);
            } else {
                System.assert(errorLog.Message__c.contains(errorLog.Severity__c));
            }
        }
    }

    @IsTest static void testLogSettings() {
        System_Properties__c systemProperties = new System_Properties__c(
            Name = 'Test',
            Log_Level__c = 'Debug'
        );
        insert systemProperties;

        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        Logger.logNow('Class', 'Method', 'Error');
        Logger.logNow('Class', 'Method', 'Error', Logger.ERROR);
        Logger.logNow('Class', 'Method', 'Warn', Logger.WARN);
        Logger.logNow('Class', 'Method', 'Debug', Logger.DEBUG);
        Logger.logNow('Class', 'Method', 'Info', Logger.INFO);
        Logger.logNow('Class', 'Method', 'Fine', Logger.FINE);
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(4, errorLogs.size());
        for (Error_Log__c errorLog : errorLogs) {
            System.assertEquals(errorLog.Severity__c, errorLog.Message__c);
            System.assertNotEquals(Logger.INFO, errorLog.Severity__c);
            System.assertNotEquals(Logger.FINE, errorLog.Severity__c);
        }
    }

    @IsTest static void testLogLaterWithClear() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        // Error log 1
        Logger.logLater('Class1', 'Method', 'Error');
        Logger.clearLogs();
        // Error log 2
        Logger.logLater('Class1', 'Method', 'Another Error', Logger.ERROR);
        // Error log 3
        Logger.logLater('Class2', 'Method', 'Warn', Logger.WARN);
        Logger.logLater('Class2', 'Method', 'Another Warn', Logger.WARN);
        // Error log 4
        Logger.logLater('Class2', 'Method', 'Warn', Logger.DEBUG);
        // Error log 5
        Logger.logLater('Class3', 'Method', 'Warn', Logger.WARN);
        Logger.clearLogs();
        // Error log 6
        Logger.logLater('Class3', 'Method', 'Another Warn', Logger.WARN);
        // Error log 7
        Logger.logLater('Class3', 'Method1', 'Info', Logger.INFO);
        // Error log 8
        Logger.logLater('Class3', 'Method', 'Fine', Logger.FINE);

        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        Logger.flushLogs();
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(8, errorLogs.size());
        for (Error_Log__c errorLog : errorLogs) {
            if (errorLog.Severity__c == Logger.DEBUG) {
                System.assertEquals('Warn', errorLog.Message__c);
            } else {
                System.assert(errorLog.Message__c.contains(errorLog.Severity__c));
            }
        }
    }

    @IsTest
    public static void testLogLaterWithLongMessages() {
        Logger.logLater('Class1', 'Method1', get120kString('Foo'), Logger.ERROR);
        // We should only get Bar 0, and truncate after that
        Logger.logLater('Class1', 'Method1', get120kString('Bar'), Logger.ERROR);
        // We should see all of this in a different log message
        Logger.logLater('Class2', 'Method2', get120kString('Bar'), Logger.ERROR);
        Logger.flushLogs();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
            ORDER BY Class__c
        ];
        System.assertEquals(2, errorLogs.size());
        System.assertEquals('Class1', errorLogs[0].Class__c);
        System.assert(errorLogs[0].Message__c.contains('Bar 0'));
        System.assert(!errorLogs[0].Message__c.contains('Bar 1'));
        System.assertEquals('Class2', errorLogs[1].Class__c);
        System.assert(errorLogs[1].Message__c.contains('Bar 1'));
        System.assertEquals(get120kString('Bar').length(), (errorLogs[1].Message__c+'\n').length());
    }

    public static String get120kString(String prefix) {
        String result = '';
        for (Integer i = 0; i < 1000; i++) {
            result += prefix + ' ' + i + '. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore.\n';
        }
        return result;
    }
}