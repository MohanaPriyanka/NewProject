/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: ZuoraInvoiceSelectorTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceSelector {
    public static List<Zuora__ZInvoice__c> getInvoicesToDownload() {
        return [
            SELECT Id, Zuora__Zuora_Id__c
            FROM Zuora__ZInvoice__c
            WHERE Downloaded_Date__c = NULL
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesToMail() {
        return [
            SELECT Id, Zuora__Zuora_Id__c,
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

    public static List<Zuora__ZInvoice__c> getInvoicesByDate(Date invoiceDate) {
        return [
            SELECT Id, Zuora__ZuoraId__c
            FROM Zuora__ZInvoice__c
            WHERE Zuora__InvoiceDate__c = : invoiceDate
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesForEmail() {
        return [
            SELECT Id, Name, Zuora__ZuoraId__c,
                Bill_Document_Content_Version_ID__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Name,
                Zuora__BillingAccount__r.Zuora__Account__r.Id,
                Zuora__BillingAccount__r.Zuora__Account__r.Client_Brand_Key__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Bill_Delivery_Preference__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email,
                Zuora__BillingAccount__r.Zuora__Account__r.Additional_Contact__r.Email
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = true
        ];
    }
}