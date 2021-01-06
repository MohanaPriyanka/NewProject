/**
 * @description Gets Glynt Custom Metadata
 * Tested By: GlyntAPIHelperTest
 */

public without sharing class GlyntSelector {
    public List<Glynt_Configuration__mdt> getGlyntConfiguration() {
        return [
            SELECT Id, Data_Pool_Id__c, Extraction_Processor__c, Extraction_Query_Timeout__c, Authorization_Type__c
            FROM Glynt_Configuration__mdt
            WHERE Production__c = :!Util.isSandboxOrTest()
        ];
    }
}