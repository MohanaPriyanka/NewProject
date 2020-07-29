/**
 * Created by peteryao on 7/27/20.
 */
@IsTest
public with sharing class ZuoraContactSelectorTest {
    @IsTest
    private static void testSelectAll() {
        Zuora_Contact__c zuoraContact = new Zuora_Contact__c(Zuora_Id__c = 'foo');
        insert zuoraContact;
        System.assertEquals(1, new ZuoraContactSelector().selectAll(new Set<String>{'foo'}).size(),
            'Expected to get the test zuoraContact');
    }
}