/**
 * Created by lholmes_gearscrm on 8/17/2020.
 * Description: test methods for RateClassesSelector
 */


@IsTest
private class RateClassesSelectorTest {
    
    @IsTest
    static void testSelectByUtilities(){
        Utility__c utility1 = new Utility__c(Name = 'utility1');
        Utility__c utility2 = new Utility__c(Name = 'utility2');
        insert new List<Utility__c>{utility1, utility2};

        Rate_Class__c rateClass1 = new Rate_Class__c(Name = 'rateClass1', Utility__c = utility1.Id);
        Rate_Class__c rateClass2 = new Rate_Class__c(Name = 'rateClass2');
        insert new List<Rate_Class__c>{rateClass1, rateClass2};

        List<Rate_Class__c> response1 = RateClassesSelector.selectByUtilities(new Set<Id>{utility1.Id, utility2.Id});
        System.assertEquals(1, response1.size(), 'Method should have returned one Rate Class, as there is one Rate Class associated with the input Utility IDs');
        System.assertEquals(rateClass1.Id, response1[0].Id, 'Method should have returned the Rate Class associated with the input Utility ID');
        
        List<Rate_Class__c> response2 = RateClassesSelector.selectByUtilities(new Set<Id>{utility2.Id});
        System.assertEquals(0, response2.size(), 'Method should have returned no Rate Classes, as there are no Rate Classes associated with the input Utility ID');
    }
    
    @IsTest
    static void testSelectByName(){
        Rate_Class__c rateClass1 = new Rate_Class__c(Name = 'rateClass1');
        Rate_Class__c rateClass2 = new Rate_Class__c(Name = 'rateClass2');
        insert new List<Rate_Class__c>{rateClass1, rateClass2};

        RateClassesSelector rateClassesSelector = new RateClassesSelector();
        List<Rate_Class__c> response1 = rateClassesSelector.selectByName('rateClass1');
        System.assertEquals(1, response1.size(), 'Method should have returned one Rate Class, as there is one Rate Class with the input name');
        System.assertEquals(rateClass1.Id, response1[0].Id, 'Method should have returned the Rate Class with the input name');
        
        List<Rate_Class__c> response2 = rateClassesSelector.selectByName('different rate class');
        System.assertEquals(0, response2.size(), 'Method should have returned no Rate Classes, as there are no Rate Classes with the input name');
    }
    
    @IsTest
    static void testSelectByNameAndUtility(){
        Utility__c utility1 = new Utility__c(Name = 'utility1');
        Utility__c utility2 = new Utility__c(Name = 'utility2');
        insert new List<Utility__c>{utility1, utility2};

        Rate_Class__c rateClass1 = new Rate_Class__c(Name = 'rateClass', Utility__c = utility1.Id);
        Rate_Class__c rateClass2 = new Rate_Class__c(Name = 'rateClass', Utility__c = utility1.Id);
        insert new List<Rate_Class__c>{rateClass1, rateClass2};

        RateClassesSelector rateClassesSelector = new RateClassesSelector();
        List<Rate_Class__c> response = rateClassesSelector.selectByNameAndUtility('rateClass', utility1.Id);
        System.assertEquals(2, response.size(), 'Method should have returned both Rate Class records, as both match the input name and input utility');
        
        response = rateClassesSelector.selectByNameAndUtility('rateClass', utility2.Id);
        System.assertEquals(0, response.size(), 'Method should have returned no Rate Classes, as both match the input name but neither Rate Class matches the input utility');
        
        response = rateClassesSelector.selectByNameAndUtility('different rate class name', utility1.Id);
        System.assertEquals(0, response.size(), 'Method should have returned no Rate Classes, as both match the input utility but neither Rate Class matches the input name');

        rateClass2.Utility__c = utility2.Id;
        update rateClass2;
        response = rateClassesSelector.selectByNameAndUtility('rateClass', utility2.Id);
        System.assertEquals(1, response.size(), 'Method should have returned one Rate Class, as both match the input name but only one matches the input utility');
        System.assertEquals(rateClass2.Id, response[0].Id, 'Method should have returned the Rate Class that matched both the input name and the input utility');

        rateClass1.Name = 'new name';
        rateClass2.Utility__c = utility1.Id;
        update new List<Rate_Class__c>{rateClass1, rateClass2};
        response = rateClassesSelector.selectByNameAndUtility('new name', utility1.Id);
        System.assertEquals(1, response.size(), 'Method should have returned one Rate Class, as both match the input utility but only one matches the input name');
        System.assertEquals(rateClass1.Id, response[0].Id, 'Method should have returned the Rate Class that matched both the input name and the input utility');
    }
}