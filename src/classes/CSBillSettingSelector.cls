/*************************************************************************************
 * Created By: peteryao on 2019-03-31  
 * Description: 
 * Test: CSBillSettingSelectorTest
 *************************************************************************************/

public with sharing class CSBillSettingSelector {
    public static CS_Bill_Setting__c getBillSetting() {
        List<CS_Bill_Setting__c> csBillSettings = [
            SELECT Id, Default_Bill_Message_for_Autopay__c, Default_Bill_Message_for_Non_Autopay__c
            FROM CS_Bill_Setting__c
            LIMIT 1
        ];
        if (!csBillSettings.isEmpty()) {
            return csBillSettings[0];
        } else {
            return new CS_Bill_Setting__c();
        }
    }
}