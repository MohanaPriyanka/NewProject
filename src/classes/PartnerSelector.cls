/**
 * @description Created by SarahRenfro on 6/13/2019.
 * Tested By: PartnerSelectorTest, PartnerCommissionStructureLocatorTest
 */
public without sharing class PartnerSelector {

    public static Partner__c selectPartnerByPartnerId(String partnerId) {
        return [
            SELECT Id, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Email__c, Name, Account__c
            FROM Partner__c
            WHERE Id = :partnerId
        ];
    }

    public static Partner__c selectDefaultCSPartner() {
        Partner__c defaultCSPartner = new Partner__c();
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0 ) {
            defaultCSPartner = [
                SELECT Id, Default_Sales_Rep__c, Default_Sales_Rep__r.Name, Email__c, Name, Account__c
                FROM Partner__c
                WHERE Id = :systemProperties[0].Default_CS_Partner__c
                LIMIT 1
            ];
        } else {
            Logger.logNow('PartnerSelector', 'selectDefaultCSPartner', 'No Default CS Partner stored in System Properties');
        }
        return defaultCSPartner;
    }

    /**
     * @description Retrieves map of Partner Id => Partner Account Id (from Partner_tag_lookup__r lookup on Opp)
     * Required because calling code runs in BEFORE_INSERT context where relationship data is inaccessible, need to query
     * TODO: Deprecate in the future when Partner__c object becomes obsolete
     * @param opportunities Opportunities
     * @return Map of Partner Id => Partner Account Id
     */
    public Map<Id, Id> legacyGetPartnerAccountIdsByOpp(List<Opportunity> opportunities) {
        Map<Id, Id> oppToPartnerAccountIdMap = new Map<Id, Id>();
        Set<Id> partnerIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            partnerIds.add(opp.Partner_tag_lookup__c);
        }
        Map<Id, Partner__c> partners = new Map<Id, Partner__c>([
            SELECT Id, Account__c
            FROM Partner__c
            WHERE Id IN : partnerIds
        ]);
        for (Opportunity opp : opportunities) {
            if (opp.Partner_tag_lookup__c != null) {
                Id partnerAccountId = partners.get(opp.Partner_tag_lookup__c)?.Account__c;
                oppToPartnerAccountIdMap.put(opp.Partner_tag_lookup__c, partnerAccountId);
            }
        }
        return oppToPartnerAccountIdMap;
    }
}