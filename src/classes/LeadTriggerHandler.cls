public with sharing class LeadTriggerHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    public static Boolean firstRun = true;
    
    public LeadTriggerHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeInsert(List<Lead> leadList){
        updateLZUL(leadList, null);
    }
    public void OnBeforeUpdate(List<Lead> oldLeads, List<Lead> updatedLeads, Map<ID, Lead> oldLeadMap, Map<ID, Lead> newLeadMap){
        updateLZUL(updatedLeads, oldLeadMap);
    }
    public void OnAfterUpdate(List<Lead> oldLeads, List<Lead> updatedLeads, Map<ID, Lead> oldLeadMap, Map<ID, Lead> newLeadMap){
        //Check if lead got converted in this trigger instance (Changed from IsConverted = false into true)
        if(    updatedLeads.size() == 1 
            && updatedLeads[0].IsConverted && oldLeads[0].IsConverted == false
            && updatedLeads[0].convertedAccountId != null
            && updatedLeads[0].Product_Line__c == 'Community Solar'
            && firstRun){
            customerSubscriptionProcess(updatedLeads[0]);
            firstRun = false;
        } 

        for (Lead convertedLead : updatedLeads){
            if ( convertedLead.IsConverted && !oldLeadMap.get(convertedLead.Id).IsConverted){
                convertCasestoAccount(convertedLead);
            }
        }
    }
    
    private void updateLZUL(List<Lead> leadList, Map<ID, Lead> oldLeadMap){
        Set<String> zipCodeSet = new Set<String>();
        for(Lead l : leadList){
            if(l.Parcel_Zip__c != null){
                zipCodeSet.add(l.Parcel_Zip__c);
            }
        }
        if(zipCodeSet.size() > 0 ){
            Map<String, Load_u__c> validLZU = new Map<String, Load_u__c>();
            for (Load_u__c obj : [SELECT Id, Name, Load_Zone__c, LZ__c, Utility__c FROM Load_u__c WHERE Name IN : zipCodeSet] ){
                validLZU.put(obj.Name, obj); 
            }
            for(Lead l : leadList){
                if(oldLeadMap == null || oldLeadMap.get(l.Id).Parcel_Zip__c != l.Parcel_Zip__c){
                    if(validLZU.containsKey (l.Parcel_Zip__c)){
                        l.LZU__c = validLZU.get (l.Parcel_Zip__c).Load_Zone__c;
                        l.Load_Zone__c = validLZU.get (l.Parcel_Zip__c).LZ__c;
                        l.Utility_1__c = validLZU.get(l.Parcel_Zip__c).Utility__c;
                    }
                }
                else if(oldLeadMap.get(l.Id).Parcel_Zip__c != l.Parcel_Zip__c && !validLZU.containsKey(l.Parcel_Zip__c)){
                    l.LZU__c = null;
                    l.Load_Zone__c = null;
                    l.Utility_1__c = null;
                }
            }
        }
    }

    private Opportunity leadConvertMapping(Lead lead, Opportunity opp){
        opp.AccountId = lead.convertedAccountId;
        opp.Assessors_Parcel_Number__c = lead.Accessor_s_Parcel_Number__c;
        opp.Annual_Independent_Income__c = lead.Annual_Income_Currency__c;
        opp.Application_Date__c = lead.Application__c;
        opp.Application_Type__c = lead.Application_Type__c;
        opp.Avidia_Checking_Account__c = lead.Avidia_Checking_Account__c;
        opp.Business_Title__c = lead.Business_Title__c;
        opp.CS_Capacity_Allocated__c = lead.Capacity_Allocation__c;
        opp.Co_Applicant_Date_of_Birth__c = lead.Co_Applicant_Date_of_Birth__c;
        opp.Co_Applicant_Email__c = lead.Co_Applicant_Email__c;
        opp.Co_Applicant_First_Name__c = lead.Co_Applicant_First_Name__c;
        opp.Co_Applicant_Income__c = lead.Co_Applicant_Income__c;
        opp.Co_Applicant_Last_Name__c = lead.Co_Applicant_Last_Name__c;
        opp.Co_Applicant_Phone__c = lead.Co_Applicant_Phone__c;
        opp.Commencement_Date__c = lead.Commencement_Date__c;
        opp.Cumulative_Loan_to_Value__c = lead.Cumulative_Loan_to_Value_if_Applicable__c;
        opp.Customer_Referral__c = lead.Customer_Referral__c;
        opp.Customer_type__c = lead.Customer_type__c;
        opp.Customer_Group__c = lead.Customer_Type_Formula__c;
        opp.Custom_ID__c = lead.Custom_ID__c;
        opp.Date_of_Application__c = lead.Date_of_Application__c;
        opp.Date_of_Expiration__c = lead.Date_of_Expiration__c;
        opp.Date_of_Issuance__c = lead.Date_of_Issuance__c;
        opp.Direct_Disbursal_to_Installer_Authorized__c = lead.Direct_Disbursal_to_Installer_Authorized__c;
        opp.DOER_Solar_Loan__c = lead.DOER_Solar_Loan__c;
        opp.Utility_Account__c = lead.Electric_Account_Number__c;
        opp.Electronic_Disbursal_Authorized__c = lead.Electronic_Disbursal_Authorized__c;
        opp.Email__c = lead.Email_Re_Enter__c;
        opp.Employed_for_more_than_one_year__c = lead.Employed_for_more_than_one_year__c;
        opp.Employed_for_more_than_six_months__c = lead.Employed_for_more_than_six_months__c;
        opp.External_System_Lead_ID__c = lead.External_System_Lead_ID__c;
        opp.Form_Completion_Time__c = lead.Form_Completion_Time__c;
        opp.State_ab__c = lead.LASERCA__Home_State__c;
        opp.Income_Type__c = lead.Income_Type__c;
        opp.Income_Type_2__c = lead.Income_Type_2__c;
        opp.Is_Loan_Secured__c = lead.Is_Loan_Secured__c;
        opp.Lead_ID__c = lead.Lead_ID__c;
        opp.Lived_at_residence_more_than_six_months__c = lead.Lived_Residence_Six_Months__c;   
        opp.Loan_Program_Class__c = lead.Loan_Program_Class__c;
        opp.Loan_Principle__c  = lead.System_Cost__c;       
        opp.Requested_Loan_Amount__c  = lead.Requested_Loan_Amount__c;        
        opp.Maximum_Loan__c = lead.Maximum_Loan__c;
        opp.Maximum_Monthly_Disbursement__c = lead.Maximum_Monthly_Disbursement2__c;
        opp.Monthly_Income__c = lead.Monthly_Income__c;
        opp.Monthly_Income_2__c = lead.Monthly_Income_2__c;
        opp.Monthly_Income_Details__c = lead.Monthly_Income_Details__c;
        opp.Monthly_Income_Details_2__c = lead.Monthly_Income_Details_2__c;
        opp.More_than_five_years_industry_experience__c = lead.More_than_five_years_industry_experience__c;
        opp.Number_of_Years_at_Location__c = lead.Number_of_Years_at_Location__c;
        opp.Number_of_Years_in_Business__c = lead.Number_of_Years_in_Business__c;
        opp.Parcel_ZIp__c = lead.Parcel_Zip__c;
        opp.Partner_tag_lookup__c = lead.Partner_lookup__c;
        opp.Partner_Email__c = lead.Partner_Email__c;
        opp.Partner_Tag__c = lead.Partner_Tag__c;
        opp.Personal_Credit_Report2__c = lead.Personal_Credit_Report__c;
        opp.Personal_Credit_Report_Co_Applicant__c = lead.Personal_Credit_Report_Co_Applicant__c;
        opp.Customer_Phone__c = lead.Phone2__c;
        opp.Product_Line__c = lead.Product_Line__c;
        opp.Project_Identification_Number__c = lead.Project_Identification_Number__c;
        opp.Referral_Email__c = lead.Referral_Email__c;
        opp.Residence_Owner__c = lead.Residence_Owner__c;
        opp.BS_Sales_ID__c = lead.Sales_Person__c;
        opp.Sales_Person_Tag__c = lead.Sales_Person__c;
        opp.Security_Type__c = lead.Security_Type__c;
        opp.Service_Territory__c = lead.Load_Zone__c;
        opp.Subscription__c = lead.Solar_Coverage__c;
        opp.SREC_Option__c = lead.SREC_Option__c;
        opp.State_of_Issuance__c = lead.State_of_Issuance__c;
        opp.Project_Assignment__c = lead.System_Assignment__c;
        opp.Annual_Consumption_kWh__c = lead.Total_Annual_Consumption_kWh__c;
        opp.Annual_Electricity_Cost__c = lead.Total_Annual_Electricity_Cost__c;
        opp.UtilityMapper__c = lead.Utility__c;
        opp.Utility_Account_Holder_Name__c = lead.Utility_Account_Holder__c;
        opp.Utility_Account_Holder_Business__c = lead.Utility_Account_Holder_Business__c;
        opp.Utility_Password__c = lead.Utility_Account_Password__c;
        opp.Username__c = lead.Utility_Account_Username__c;
        opp.Utility_Relationship__c = lead.Utility_Relationship__c;
        return opp;
    }

    private void customerSubscriptionProcess(Lead lead){
        //Get the list of Utility Account Logs linked to the Lead
        List<Utility_Account_Log__c> ualList = [Select Id, Name, Annual_Cost_of_Electricity__c, Name_On_Account__c
                              From Utility_Account_Log__c
                              Where Lead__c = :lead.Id
                              Order By Annual_Cost_of_Electricity__c DESC];
        //Get the total annual cost of electricity
        Decimal totalAnnualCostofElectricity = 0;
        for(Utility_Account_Log__c ual : ualList){
            if(ual.Annual_Cost_of_Electricity__c > 0){
                totalAnnualCostofElectricity += ual.Annual_Cost_of_Electricity__c;
            }
        }

        system.debug(Lead.Partner_Name__c);


        //No need to process the rest if the total cost of electricity is 0
        if(totalAnnualCostofElectricity == 0){
            return;
        }

        //Get the Shared Solar Systems based on the Lead Details that are still open
        String sssQuery = 'Select Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Product__c, Project_Capacity_Available_kW_DC__c, Estimated_COD_Date__c, Reserved_Capacity_kW_DC__c, Service_Territory__c, System_Utility__c, Utility_NMC_Tariff__c, Credit_Score_Requirement__c  ';
        sssQuery +=       'From Shared_Solar_System__c ';
        sssQuery +=       'Where Open__c = true ';
        sssQuery +=       'AND Capacity_Available_to_be_Reserved__c > 0 ';
        sssQuery +=       'AND Service_Territories__c includes (\'' + lead.Load_Zone__c + '\') ';
        sssQuery +=       'AND System_Utility__c = \'' + lead.Utility__c + '\' ';
        sssQuery +=       'AND Sales_Partners__c includes( \'' + 'All' + '\', \'' + lead.Partner_Name__c + '\' ) ';

        if(lead.System_Assignment__c == 'Automatic - COD Date/Available Capacity' || lead.System_Assignment__c == null){
            sssQuery += 'ORDER BY Estimated_COD_Date_QC__c ASC, Project_Capacity_Available_kW_DC__c ASC';
        }else if(lead.System_Assignment__c == 'Automatic - Assignment Order'){
            sssQuery += 'ORDER BY Assignment_order__c ASC';
        }
        
        System.debug('SSS Query ' + sssQuery);

        Decimal remainingAccountCostToAllocate = totalAnnualCostofElectricity;
        List<Opportunity> oppListToCreate = new List<Opportunity>();
        Map<Id, Decimal> sssRemainingSubscriptionCostMap = new Map<Id, Decimal>();

        Integer oppCounter = 1;
        for(Shared_Solar_System__c sss : Database.query(sssQuery)){
            sssRemainingSubscriptionCostMap.put(sss.Id, sss.Maximum_Subscription_Cost__c);

            system.debug(sss.Sales_Partners__c);

            if(  Integer.valueOf(lead.LASER_Credit_Score__c) >= sss.Credit_Score_Requirement__c && remainingAccountCostToAllocate > 0){
                Decimal annualElectricityCostAssigned = Math.min(remainingAccountCostToAllocate, sss.Maximum_Subscription_Cost__c);
                remainingAccountCostToAllocate = remainingAccountCostToAllocate - annualElectricityCostAssigned;
                Opportunity opp = new Opportunity(AccountId = lead.ConvertedAccountId,
                                                  Shared_Solar_System__c = sss.Id,
                                                  Reserved_System_Capacity_kW_DC2__c = sss.Reserved_Capacity_kW_DC__c,
                                                  Available_System_Capacity_kW_DC__c = sss.Project_Capacity_Available_kW_DC__c,
                                                  Product__c = sss.Product__c,
                                                  System_Assigned__c = true,
                                                  NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
                                                  Name = lead.FirstName + ' ' + lead.LastName,
                                                  StageName = 'New',
                                                  CloseDate = Date.today(),
                                                  UAS_Created__c = true,
                                                  Annual_Electricity_Cost__c = annualElectricityCostAssigned,
                                                  Annual_Electricity_Cost2__c = annualElectricityCostAssigned,
                                                  Opportunity_Order__c = oppCounter);
                opp = leadConvertMapping(lead, opp);
                oppListToCreate.add(opp);
                oppCounter++;
                
            }
        }
        if(oppListToCreate.size() > 0){
            insert oppListToCreate;
        }

        //Create the Utility_Account_Subscription__c records (From the createUAS.trigger)
        List<Utility_Account_Subscription__c> uasListToCreate = new List<Utility_Account_Subscription__c>();
        for(Utility_Account_Log__c ual : ualList){
            Integer uasNumberCounter = 1;

            Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;

            for(Opportunity opp : oppListToCreate){
                if(sssRemainingSubscriptionCostMap.containsKey(opp.Shared_Solar_System__c)){
                    Decimal sssRemainingSubscriptionCost = sssRemainingSubscriptionCostMap.get(opp.Shared_Solar_System__c);
                    
                    Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
                    System.debug('remainingUALCostToAllocate ' + remainingUALCostToAllocate);
                    System.debug('sssRemainingSubscriptionCost ' + sssRemainingSubscriptionCost);
                    
                    if(annualElectricityCostAssigned > 0){
                        //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                        sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
                        sssRemainingSubscriptionCostMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCost);

                        remainingUALCostToAllocate = remainingUALCostToAllocate - annualElectricityCostAssigned;
                        uasListToCreate.add(new Utility_Account_Subscription__c(Name = ual.Name,
                                                                        Name_On_account__c = ual.Name_On_Account__c, 
                                                                        Opportunity__c = opp.Id,
                                                                        Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c, 
                                                                        Utility_Account_Log__c = ual.Id,
                                                                        UAS_Number__c = uasNumberCounter,
                                                                        Calculated_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned,
                                                                        Subscribed_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned
                                                                        ));
                        uasNumberCounter++;
                    }
                }
            }
        }
        if(uasListToCreate.size() > 0){
            insert uasListToCreate;
        }

        //Aggregate the totals to the opportunity field
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        for(AggregateResult ar : [SELECT Opportunity__c oppId,
                                          Sum(Subscribed_Annual_Cost_of_Electricity__c) sumUlCosts, 
                                          Sum(Customer_Subscription_kW_DC__c) sumULsubsDynamic
                                    FROM Utility_Account_Subscription__c 
                                    WHERE Opportunity__c IN : oppListToCreate
                                    Group By Opportunity__c]){
            Opportunity opp = new Opportunity(Id = (String) ar.get('oppId'));
            opp.Annual_Electricity_Cost__c = (Decimal)ar.get('sumUlCosts');
            opp.CS_Capacity_Allocated__c = (Decimal)ar.get('sumULsubsDynamic');
            oppListToUpdate.add(opp);
        }
        if(oppListToUpdate.size() > 0) update oppListToUpdate;

    }

    private void convertCasestoAccount(Lead convertedLead){
        List<Case> casesList = [SELECT Id, Lead_Lookup__r.ConvertedAccountId, Lead_Lookup__r.ConvertedContactId, 
                                    Lead_Lookup__r.isConverted, AccountId, ContactId
                                FROM Case 
                                WHERE Lead_Lookup__r.Id = : convertedLead.id
                                AND (AccountId = NULL OR ContactId = NULL)];

        for (Case caseToUpdate : casesList) {
            if ( caseToUpdate.AccountId == NULL){
                caseToUpdate.AccountId = convertedLead.ConvertedAccountId;
            }
            if ( caseToUpdate.ContactId == NULL){
                caseToUpdate.ContactId = convertedLead.ConvertedContactId;
            }
        }
        update casesList;
    }

}