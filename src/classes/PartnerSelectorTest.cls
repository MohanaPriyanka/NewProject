/**
 * Created by SarahRenfro on 6/13/2019.
 *
 */

@IsTest
private class PartnerSelectorTest {
    @TestSetup
    public static void testSetup() {
        Partner__c realPartner = new Partner__c(
            Name = 'Real Test Partner',
            Email__c = 'test@email.com'
        );
        insert realPartner;

        Partner__c defaultPartner = new Partner__c(
            Name = 'Default CS Partner',
            Email__c = 'default@email.com'
        );
        insert defaultPartner;

        TestFactory.setDefaultCSPartner(defaultPartner.Id);

    }

    @IsTest
    static void testSelectPartnerWithId() {
        Partner__c realPartner = [SELECT Id, Name, Email__c FROM Partner__c WHERE Name = 'Real Test Partner' LIMIT 1];

        Partner__c testSelectPartner = PartnerSelector.selectPartnerByPartnerId(realPartner.Id);

        System.assertEquals('Real Test Partner', testSelectPartner.Name);
        System.assertEquals('test@email.com', testSelectPartner.Email__c);

    }

    @IsTest
    static void testSelectDefaultPartner(){
        Partner__c testSelectPartner = PartnerSelector.selectDefaultCSPartner();

        System.assertEquals('Default CS Partner', testSelectPartner.Name);
        System.assertEquals('default@email.com', testSelectPartner.Email__c);

    }

    @IsTest
    static void testBrokenPartnerId() {
        String brokenId = '0000444';
        Partner__c testSelectPartner = new Partner__c();
        try {
          testSelectPartner = PartnerSelector.selectPartnerByPartnerId(brokenId);
        } catch(Exception e) {
            testSelectPartner = PartnerSelector.selectDefaultCSPartner();
        }

        System.assertEquals('Default CS Partner', testSelectPartner.Name);
        System.assertEquals('default@email.com', testSelectPartner.Email__c);

    }
}