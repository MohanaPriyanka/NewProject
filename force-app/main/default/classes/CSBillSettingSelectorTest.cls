/*************************************************************************************
 * Created By: peteryao on 2019-03-31  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class CSBillSettingSelectorTest {
    @IsTest
    public static void testBillSetting() {
        System.assertEquals(new CS_Bill_Setting__c(), CSBillSettingSelector.getBillSetting());
        CS_Bill_Setting__c csBillSetting = new CS_Bill_Setting__c(
            Default_Bill_Message_for_Autopay__c = 'AUTOPAY_MESSAGE',
            Default_Bill_Message_for_Non_Autopay__c = 'NON_AUTOPAY_MESSAGE'
        );
        insert csBillSetting;
        System.assertEquals(csBillSetting, CSBillSettingSelector.getBillSetting());
    }
}