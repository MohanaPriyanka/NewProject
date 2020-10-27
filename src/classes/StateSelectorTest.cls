/**
 * Created by: Kristin White on 10/19/2020
 * 
 */

@IsTest
public class StateSelectorTest {
    
    private static StateSelector controller = new StateSelector();
    
    @TestSetup
    public static void setupData() {
        State__c stateGA = new State__c(
            Name = 'Georgia',
            Avg_Annual_Resi_kWh__c = 1234
        );
        
        State__c stateAL = new State__c(
            Name = 'Alabama',
            Avg_Annual_Resi_kWh__c = 9876
        );
        
        List<State__c> testStateList = new List<State__c>{stateGA, stateAL};
        insert testStateList;
    }
    
    @IsTest
    static void getStateObject() {
        State__c selectedState = controller.selectByName('Georgia');
        System.assertEquals(selectedState.Name, 'Georgia', 'The returned State object should be Georgia.');
        System.assertEquals(selectedState.State_Abbreviation__c, 'GA', 'The abbreviation is a formula dependent on the State Name.');
        System.assertEquals(selectedState.Avg_Annual_Resi_kWh__c, 1234, 'The test Avg_Annual_Resi_kWh__c should be 1234.56');
    }
    
}