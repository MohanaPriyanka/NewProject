/*
    Developed by Cole Swain - colemswain@gmail.com (Last Updated 07/06/2016)
    mapSharedSolarSystemHandler is a triggered batch script that runs on the insert of a community solar opportunity record.
    The script assigns the opportunity to the correct shared solar system object according to COD date and Available Capacity. 
    It also assigns the correct net metering credit rate to the opportunity record.

    In order to un-comment the NMC mapping an update implementation is needed to map the new NMC when the system is manually
    changed on update. Current another trigger handles the NMC mapping. this will be deactivated in the future
*/

public with sharing class mapSharedSolarSystemHandler {
/*    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public mapSharedSolarSystemHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeInsert(opportunity[] newOpps){
        mapSharedSolarSystem(newOpps);
    }
    public void OnBeforeUpdate(opportunity[] oldOpps, opportunity[] updatedOpps, Map<ID, opportunity> oldOppMap, Map<ID, opportunity> newOppMap){
        mapNMConSSSchange(oldOpps,updatedOpps);
    }
    private void mapSharedSolarSystem(List<opportunity> oppsList){ 
        //Instantiate the variables and lists
        integer i;
        integer j;
        integer t;
        integer x;
        boolean oppIdVerification = FALSE;
        list<string> serviceTerritoryList = new list<string>();
        list<string> utilityList = new list<string>();
        list<string> sssSelectionList= new list<string>();
        //loop through th opportunities to set their system assigned field to FALSE. Therefore on the clone it doesn't think the system has already been assigned and skip over the assignment logic.
        for(opportunity opp : oppsList){
            opp.System_Assigned__c = FALSE;
        }
        //Run a for loop that adds the customer's Load Zone, Utility and Shared Solar System picklist value to their respective lists. 
        for(j = 0; j < oppsList.size(); j++){
            serviceTerritoryList.add(oppsList.get(j).Service_territory__c);
            utilityList.add(oppsList.get(j).UtilityMapper__c);
            sssSelectionList.add(oppsList.get(j).Shared_solar_system_picklist__c);
        }
        //Query the Shared Solar System object for records that are set as open and have Load Zones/Utilities matching the customer's being triggered. Sort them by the Estimated COD Date in order to automatically
        //subscribe customers to the systems that have a closer COD Date. Order by available capacity as well in case more than one system has the same COD date.
        for(Shared_Solar_System__c sssListAuto :[SELECT Id, Name, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, 
                                                        Reserved_Capacity_kW_DC__c, Service_territory__c, System_Utility__c, 
                                                        Utility_NMC_Tariff__c, Credit_Score_Requirement__c,
                                                        (SELECT AccountId FROM Opportunities__r)
                                                FROM Shared_solar_system__c 
                                                WHERE Project_Capacity_Available_kW_DC__c > 0 
                                                AND Open__c = TRUE
                                                AND Service_territory__c IN : serviceTerritoryList   
                                                AND System_Utility__c IN : utilityList
                                                ORDER BY Estimated_COD_Date_QC__c ASC, Project_Capacity_Available_kW_DC__c  ASC]){
            //Load all Opportunity Account IDs that are related to the Shared Solar System into a list. 
            Opportunity[] sssOppsAccountIds = sssListAuto.Opportunities__r;
            system.debug('The Shared Solar System is ' + sssListAuto.Name);
            system.debug('Child Opportunity of Shared Solar System - ' + sssListAuto.Opportunities__r);                                                                                                                                      
            //Run a for loop that cycles through all of the trigger.new records.                                          
            for(opportunity opp : oppsList){
                system.debug(opp.AccountID);
                //Loop through all of the sssOppAccountId values to see if any of them are equal to the Account Id of the triggered opportunity.
                //If there is one that is equal to the triggered opportunity's Account ID set the oppIdVerfication to TRUE and debug.
                //The oppIdVerification serves as a boolean variable that tells the system if the SSS has the Opp.Account already in it.
                for(x=0;x<sssOppsAccountIds.size();x++){
                    if(sssOppsAccountIds.get(x).AccountId == opp.AccountId){
                        oppIdVerification = TRUE;
                        system.debug('The Shared Solar System does have the Account in it already');
                    }
                }
                //If there was an opportunity in the Shared Solar System that shared the same Account ID as the triggered opportunity 
                //(oppIdVerification == TRUE means this) then continue loop to next iteration and skip code below. Reset oppIdVerification to FALSE.
                if(oppIdVerification == TRUE){
                    oppIdVerification = FALSE;
                    continue;           
                }               
                //Only assign the customer to a project if they are a community solar customer, their System Assignment field is set to automatic or null and the above query yields results. The default value is Automatic. 
                if((opp.Project_assignment__c == 'Automatic - COD Date/Available Capacity' || opp.Project_assignment__c == null)
                && opp.Product_line__c == 'Community Solar'
                && opp.System_assigned__c == FALSE
                && opp.Service_territory__c == sssListAuto.Service_territory__c 
                && opp.UtilityMapper__c == sssListAuto.System_Utility__c 
                && Integer.valueOf(opp.Credit_Score__c) >= sssListAuto.Credit_Score_Requirement__c){
                    system.debug('The Shared Solar System Assigned is ' + sssListAuto.Name);
                    opp.Shared_Solar_System__c = sssListAuto.Id;
                    opp.Reserved_System_Capacity_kW_DC2__c = sssListAuto.Reserved_Capacity_kW_DC__c;
                    opp.Available_System_Capacity_kW_DC__c = sssListAuto.Project_Capacity_Available_kW_DC__c;
                    //Set the Project Assignment to Manual so that the sssListAuto loop only assigns each opp to the SSS found first.
                    //therefore the same Opps are not looped through the oppsList loop again and assigned to avdifferent SSS.
                    opp.System_Assigned__c = TRUE;
                    //Set the Opportunity's NMC Tariff to the lookup record found on the SSS.
                    opp.NMC_Tariff__c = sssListAuto.Utility_NMC_Tariff__c;                                             
                }
            }
        }
        //Query the Shared Solar System object for records that are set as open and have Load Zones/Utilities matching the customer's being triggered. Sort them by the assignment order
        //subscribe customers to the systems that have a higher assignment order.                                
        for(Shared_Solar_System__c ssssListAuto2 : [SELECT Id, Name, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, 
                                                               Reserved_Capacity_kW_DC__c, Service_territory__c, System_Utility__c, 
                                                               Utility_NMC_Tariff__c, Credit_Score_Requirement__c,
                                                               (SELECT AccountId FROM Opportunities__r)
                                                    FROM Shared_solar_system__c 
                                                    WHERE Project_Capacity_Available_kW_DC__c > 0 
                                                    AND Open__c = TRUE
                                                    AND Service_territory__c IN : serviceTerritoryList   
                                                    AND System_Utility__c IN : utilityList
                                                    ORDER BY Assignment_order__c ASC]){
            //Load all Opportunity Account IDs that are related to the Shared Solar System into a list. 
            Opportunity[] sssOppsAccountIds = ssssListAuto2.Opportunities__r;
            system.debug('The Shared Solar System is ' + ssssListAuto2.Name);
            system.debug('Child Opportunity of Shared Solar System - ' + ssssListAuto2.Opportunities__r);                                                                                                                                          
            //Run a for loop that cycles through all of the trigger.new records.                                          
            for(opportunity opp : oppsList){
                system.debug(opp.AccountID);
                //Loop through all of the sssOppAccountId values to see if any of them are equal to the Account Id of the triggered opportunity.
                //If there is one that is equal to the triggered opportunity's Account ID set the oppIdVerfication to TRUE and debug.
                //The oppIdVerification serves as a boolean variable that tells the system if the SSS has the Opp.Account already in it.
                for(x=0;x<sssOppsAccountIds.size();x++){
                    if(sssOppsAccountIds.get(x).AccountId == opp.AccountId){
                        oppIdVerification = TRUE;
                        system.debug('The Shared Solar System does have the Account in it already');
                    }
                }
                //If there was an opportunity in the Shared Solar System that shared the same Account ID as the triggered opportunity 
                //(oppIdVerification == TRUE means this) then continue loop to next iteration and skip code below. Reset oppIdVerification to FALSE.
                if(oppIdVerification == TRUE){
                    oppIdVerification = FALSE;
                    continue;           
                }               
                //Only assign the customer to a project if they are a community solar customer, their System Assignment field is set to automatic or null and the above query yields results. The default value is Automatic. 
                if((opp.Project_assignment__c == 'Automatic - Assignment Order')
                && opp.Product_line__c == 'Community Solar'
                && opp.System_assigned__c == FALSE
                && opp.Service_territory__c == ssssListAuto2.Service_territory__c 
                && opp.UtilityMapper__c == ssssListAuto2.System_Utility__c 
                && Integer.valueOf(opp.Credit_Score__c) >= ssssListAuto2.Credit_Score_Requirement__c){
                    system.debug('The Shared Solar System Assigned is ' + ssssListAuto2.Name);
                    opp.Shared_Solar_System__c = ssssListAuto2.Id;
                    opp.Reserved_System_Capacity_kW_DC2__c = ssssListAuto2.Reserved_Capacity_kW_DC__c;
                    opp.Available_System_Capacity_kW_DC__c = ssssListAuto2.Project_Capacity_Available_kW_DC__c;
                    //Set the Project Assignment to Manual so that the ssssListAuto2 loop only assigns each opp to the SSS found first.
                    //therefore the same Opps are not looped through the oppsList loop again and assigned to avdifferent SSS.
                    opp.System_Assigned__c = TRUE;
                    //Set the Opportunity's NMC Tariff to the lookup record found on the SSS.
                    opp.NMC_Tariff__c = ssssListAuto2.Utility_NMC_Tariff__c;                                             
                }
            }
        }                                                          
    }

    //if the user changes the shared solar system that the record is a part of the below method changes the NMC relationship to the record related to the Shared Solar System.
    private void mapNMConSSSchange(List<opportunity> oldOppsList, List<opportunity> updatedOppsList){     
        integer s;
        integer l;
        list<Id> updatedOppsSSSList= new list<Id>();
        map<Id,Shared_Solar_System__c> sssMap = new map<Id,Shared_Solar_System__c>();
        system.debug(oldOppsList.size());

        for(l=0;l<updatedOppsList.size();l++){
            updatedOppsSSSList.add(updatedOppsList.get(l).Shared_Solar_System__c);
        }
        
        for(Shared_Solar_System__c sssListAutoNMC : [SELECT Id, Name, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, 
                                                               Reserved_Capacity_kW_DC__c, Service_territory__c, System_Utility__c, 
                                                               Utility_NMC_Tariff__c, Credit_Score_Requirement__c
                                                    FROM Shared_solar_system__c 
                                                    WHERE Id IN : updatedOppsSSSList]){
            sssMap.put(sssListAutoNMC.Id,sssListAutoNMC);
        }   
        for(s=0;s<oldOppsList.size();s++){
            system.debug('The oldOppsList Shared Solar System is ' + oldOppsList.get(s).Shared_Solar_System__c);
            if(oldOppsList.get(s).Shared_Solar_System__c != updatedOppsList.get(s).Shared_Solar_System__c){
                system.debug('The updated NMC Tariff is ' + sssMap.get(updatedOppsList.get(s).Shared_Solar_System__c).Utility_NMC_Tariff__c);
                updatedOppsList.get(s).NMC_Tariff__c = sssMap.get(updatedOppsList.get(s).Shared_Solar_System__c).Utility_NMC_Tariff__c;
            }      
        }
    }*/
}