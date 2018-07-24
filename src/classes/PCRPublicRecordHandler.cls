/**
 * Created by mstackhouse on 7/9/2018.
 * Description: Used to hold methods that look at the Public Records of a PCR
 * Test: PCRApprovalHandlerTest
 */


public with sharing class PCRPublicRecordHandler {
    public static Boolean appHasCurrentBankruptcy(List<LASERCA__Personal_Credit_Report__c> pcrs) {
        Boolean currentBankruptcy = false;
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            if (pcrHasCurrentBankruptcy(pcr)) {
                currentBankruptcy = true;
            }
        }
        return currentBankruptcy;
    }

    private static Boolean pcrHasCurrentBankruptcy(LASERCA__Personal_Credit_Report__c pcr) {
        Boolean currentBankruptcy = false;
        for (LASERCA__Public_Records__c publicRecord : pcr.LASERCA__Public_Records__r) {
            if (publicRecord.LASERCA__Type__c != null
                && publicRecord.LASERCA__Type__c.contains('Bankruptcy')
                && publicRecord.LASERCA__Disposition_Date__c == null
                && publicRecord.LASERCA__Disposition__c == 'Filed') {
                currentBankruptcy = true;
            }
        }
        return currentBankruptcy;
    }

}