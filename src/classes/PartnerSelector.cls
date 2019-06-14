/**
 * Created by SarahRenfro on 6/13/2019.
 *
 * Test: PartnerSelectorTest
 */

public without sharing class PartnerSelector {
    public static Partner__c selectPartnerByPartnerId(String partnerId) {
        return [
            SELECT Id, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Email__c, Name
            FROM Partner__c
            WHERE Id = :partnerId
        ];
    }

    //Only ever going to return one partner so does it HAVE to be a list?
    public static Partner__c selectDefaultCSPartner() {
        Partner__c defaultCSPartner = new Partner__c();
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0 ) {
            defaultCSPartner = [
                SELECT Id, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Email__c, Name
                FROM Partner__c
                WHERE Id = :systemProperties[0].Default_CS_Partner__c
                LIMIT 1
            ];
        } else {
            Logger.logNow('PartnerSelector', 'selectDefaultCSPartner', 'No Default CS Partner stored in System Properties');
        }
        return defaultCSPartner;
    }

}