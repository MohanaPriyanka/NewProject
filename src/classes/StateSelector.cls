/**
 * Created by: Kristin White on 10/19/2020
 * 
 * Tested by: UtilityDataRequestServiceTest and StateSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class StateSelector {
    public State__c selectByName(String stateName) {
        
        State__c selectedState = [
            SELECT Id, Name, State_Abbreviation__c, Avg_Annual_Resi_kWh__c
            FROM State__c 
            WHERE Name = :stateName
        ];
        
        return selectedState;
    }
}