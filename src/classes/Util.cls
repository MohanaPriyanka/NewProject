/*************************************************************************************
 * Created By: Peter Yao
 * Description: Common methods used across the org
 * Tested by: AccountInfoControllerTest, LoanUnderwritingTest (nullToZero)
 *************************************************************************************/
public without sharing class Util {
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

    public static List<Product2> getActiveProducts(List<String> states, Id partnerId, String productType) { 
        return getActiveProductsInternal(states, partnerId, productType, false);
    }

    public static List<Product2> getActiveProductsIncludingHidden(List<String> states, Id partnerId, String productType) { 
        return getActiveProductsInternal(states, partnerId, productType, true);
    }

    // Used to show the installer a list of products to apply for (SLPAddCustomer, SLPSendEmailApplication)
    // or to generate a quick sales sheet (SLPQuickSalesSheet).
    public static List<Product2> getActiveProductsInternal(List<String> states, Id partnerId, String productType, Boolean showHidden) {
        List<Product2> productList = [SELECT Id, Name, Program__c, ProductCode, Require_Junctions_to_Enable__c, Hide_in_Requested_Product__c,
                                      (SELECT Id FROM Partner_Product_Junctions__r 
                                       WHERE Partner__c = :partnerId
                                       AND Active__c = true)
                                      FROM Product2
                                      WHERE Product_Type__c = :productType
                                      AND IsActive = true
                                      AND State__c IN : states
                                      ORDER BY State__c, Loan_Term__c];
        Set<Product2> productSet = new Set<Product2>();
        for (Product2 prod : productList) {
            if (prod.Require_Junctions_to_Enable__c) {
                if ((prod.Partner_Product_Junctions__r.size() > 0) && (!prod.Hide_in_Requested_Product__c || showHidden)) {
                    productSet.add(prod);
                }
            } else {
                if (!prod.Hide_in_Requested_Product__c || showHidden) {
                    productSet.add(prod);
                }
            }
        }
        List<Product2> enabledProducts = new List<Product2>();
        enabledProducts.addAll(productSet);
        return enabledProducts;
    }

    public class BWException extends Exception {}
}
