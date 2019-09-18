/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: ZuoraInvoiceSelectorTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceSelector {
    public static List<Zuora__ZInvoice__c> getInvoicesToDownload() {
        return [
            SELECT Id, Zuora__ZuoraId__c
            FROM Zuora__ZInvoice__c
            WHERE Downloaded_Date__c = NULL
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesToMail() {
        return [
            SELECT Id, Zuora__ZuoraId__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Name,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingStreet,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingCity,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingState,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingPostalCode,
                Content_Document_Id__c
            FROM Zuora__ZInvoice__c
            WHERE Ready_for_Paper_Bill_Queue__c = TRUE
            AND Added_to_Paper_Bill_Queue__c = FALSE
            ORDER BY Id
        ];
    }
}