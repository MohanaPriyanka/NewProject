// Jordan 12.9.2016 to replace trigger on lead

public with sharing class MapCapacityAvailableHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;

    public mapCapacityAvailableHandler (boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    public void OnBeforeInsert (Lead[] newLeads){
        List<lead> leadListToExecute = new List<lead>();
        for (Lead l : newLeads){
            if (l.Product_Line__c == 'Community Solar'){
                leadListToExecute.add(l);
            }
        }
        if (leadListToExecute.size() > 0){
            mapCapacityAvailable(leadListToExecute);  
        }         
    }

    public void OnBeforeUpdate (Lead[] newLeads){
        List<lead> leadListToExecute = new List<lead>();      
        for (Lead l : newLeads){
            if (l.Product_Line__c == 'Community Solar'){
                leadListToExecute.add(l);
            }
        }
        if (leadListToExecute.size() > 0){
            mapCapacityAvailable(leadListToExecute);  
        }      
    }      
    
    private void mapCapacityAvailable (List <Lead> trigleads){
        Integer j;
        Integer k;
        Integer fico = 900;

        List<Shared_Solar_System__c> listSSS = [SELECT Id, Name, System_Utility__c, Service_Territories__c, Credit_Score_Requirement__c, 
                                                Sales_Partners__c, Project_Capacity_Available_kW_DC__c, Product__c
                                                FROM Shared_Solar_System__c
                                                WHERE Open__c = True
                                                AND Sales_Partners__c != NULL 
                                                AND Service_Territories__c != NULL
                                                AND System_Utility__c != NULL];

        for (Lead trigLead : trigleads){          
            Decimal totalavailablecapacity = 0;
            if (trigLead.LASER_Credit_Score__c != NULL){
                fico = Integer.valueof(trigLead.LASER_Credit_Score__c);
            }
            if (trigLead.Partner_Name__c != NULL 
                && trigLead.Load_Zone__c != NULL 
                && trigLead.Utility_1__c != NULL) {
                    for (Shared_Solar_System__c sss : listSSS){
                        if (sss.System_Utility__c == trigLead.Utility_1__c 
                            && sss.Service_Territories__c.contains(trigLead.Load_Zone__c)
                            && sss.Credit_Score_Requirement__c <= fico
                            && (sss.Sales_Partners__c == 'All' || sss.Sales_Partners__c.contains(trigLead.Partner_Name__c))){
                                totalavailablecapacity = totalavailablecapacity + sss.Project_Capacity_Available_kW_DC__c;
                        }
                    }
            }
            trigLead.Available_Capacity__c = totalavailablecapacity;   
        }      
    }
}