/*************************************************************************************
 * Created By: Peter Yao
 * Description: Common methods used across the org
 * Tested by: AccountInfoControllerTest, LoanUnderwritingTest (nullToZero)
 *************************************************************************************/
public with sharing class Util {
    // We're starting to get this error in Apex tests in Sept 2017:
    // System.DmlException: Insert failed. First exception on row 0; first error: 
    // UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record
    // Granular Locking is already turned on, so instead, we'll re-try 10 times if we get this error
    @TestVisible 
    private static Integer MAX_TRIES = 10;
    public static void insertSObj(SObject sobj) {
        insertSobjs(new List<SObject>{sobj}, 0, null, null);
    }
    public static void insertSObjs(List<SObject> sobjs) {
        insertSobjs(sobjs, 0, null, null);
    }

    private static void insertSObjs(List<SObject> sobjs, Integer count, String message, String stack) {
        if (count >= MAX_TRIES) {
            throw new BWException(message + '\n' + stack);
        }
        try {
            insert sobjs;
        } catch (System.DmlException de) {
            if (de.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                insertSObjs(sobjs, count++, de.getMessage(), de.getStackTraceString());
            }
        }
    }

    public static Decimal nullToZero(Decimal value) {
        return (value==null?0:value);
    }

    public static String nullToZero(String value) {
        return (String.isBlank(value)?'0':value);
    }    

    public class BWException extends Exception {}
}