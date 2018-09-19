/*************************************************************************************
 * Created By: Peter Yao
 * Description: Common methods used across the org
 * Tested by: LoanUnderwritingTest,PCRApprovalHandlerTest,SLPControllersTestclass,SLPQuickSalesSheetTestclass
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
            } else {
                throw new BWException(de.getMessage());
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
    private static List<Product2> getActiveProductsInternal(List<String> states, Id partnerId, String productType, Boolean showHidden) {
        List<Product2> productList = [SELECT Id, Name, Program__c, External_Name__c, Require_Junctions_to_Enable__c, Hide_in_Requested_Product__c,
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

    public static String getCommunitySiteURL(String communityName) {
        Domain d = [SELECT Domain, DomainType FROM Domain WHERE Domain LIKE '%memberportal%' LIMIT 1];
        Network n = [SELECT Name,UrlPathPrefix FROM Network WHERE Name = :communityName LIMIT 1];
        return 'https://' + d.Domain + '/' + n.UrlPathPrefix;
    }

    // Because Math.min and Math.max only supports two arguments
    public static Decimal min(List<Decimal> decimalValues) {
        decimalValues.sort();
        return(decimalValues[0]);
    }
    public static Decimal max(List<Decimal> decimalValues) {
        decimalValues.sort();
        return(decimalValues[decimalValues.size()-1]);
    }

    public static void printCPULimit(String prefix) {
        System.debug(LoggingLevel.ERROR, 'Limits: ' + prefix + ': ' + Limits.getCpuTime() + 'ms of '
            + Limits.getLimitCpuTime() + 'ms used');
    }

    public static void printSOQLLimit(String prefix) {
        System.debug(LoggingLevel.ERROR, 'Limits: ' + prefix + ': ' + Limits.getQueries() + ' of '
            + Limits.getLimitQueries() + ' used');
    }

    public class BWException extends Exception {}

    public static String removeComma(String value) {
        return value.replace(',', '');
    }

    public static String removeNewLine(String value) {
        return value.replace('\n', '');
    }

    public static String prepForCSV(String value) {
        value = removeComma(value);
        return removeNewLine(value);
    }
}