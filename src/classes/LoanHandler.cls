public without sharing class LoanHandler{
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
        
    // Default constructor
    public LoanHandler() {
    }


    
    // Constructor to override m_isExecuting and Batch Size
    public LoanHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    //On After Insertion of Loan Record
    public void onAfterInsert(List<Loan__c> newLoans){
        createLoanPartnerTasks(newLoans);
    }
    
    //On Before Update of Lead Record
    public void onBeforeLeadUpdate(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap){
        //map the loan, equipment and partner tasks to the opporunity upon conversion
        mapLoanToOpportunity(updatedLeadMap, oldLeadMap);
        mapEquipmentToOpportunity(updatedLeadMap, oldLeadMap);     
        mapPartnerTasksToOpportunity(updatedLeadMap, oldLeadMap);   
        mapCoApplicantContactToOpportunity(updatedLeadMap, oldLeadMap);
    }

    //On After Update of Lead Record
    public void onAfterLeadUpdate(List<Lead> updatedLeads, List<Lead> oldLeads){
        List<Lead> leadsToCreateLoanAndEquipment = new List<Lead>();
        List<Lead> leadsToValidatePartnerTasks = new List<Lead>();
        List<Lead> leadsToSetBlueWaveReviewToComplete = new List<Lead>();
        List<String> leadIds = new List<String>();

        for (Lead leadRecord : updatedLeads) {
            leadIds.add(leadRecord.Id);
        }
        for (Lead newLead : updatedLeads){
            for (Lead oldLead : oldLeads){
                if (newLead.Id == oldLead.Id){
                    if (newLead.Status == 'Pending Information' 
                        && oldLead.Status != 'Pending Information' 
                        && newLead.Product_Line__c == 'Residential Loan'){
                        leadsToCreateLoanAndEquipment.add(newLead);                       
                    }
                }
                if (newLead.Update_Dummy__c != oldLead.Update_Dummy__c 
                    && newLead.Product_Line__c == 'Residential Loan'){
                    leadsToValidatePartnerTasks.add(newLead);
                }
                if (newLead.isConverted == true 
                    && oldLead.isConverted == false 
                    && newLead.Product_Line__c == 'Residential Loan'){
                    leadsToSetBlueWaveReviewToComplete.add(newLead);
                }
            }
        }
        if (leadsToCreateLoanAndEquipment.size() > 0){
            createResidentialEquipment(leadsToCreateLoanAndEquipment);
            createLoan(leadsToCreateLoanAndEquipment);
        }

        if (leadsToValidatePartnerTasks.size() > 0){
            validateLoanInformationProvidedOnLead(leadsToValidatePartnerTasks, getPartnerTasks(leadIds));
        }

        if (leadsToSetBlueWaveReviewToComplete.size() > 0){
            updatePartnerTaskUnderBlueWaveReview(leadsToSetBlueWaveReviewToComplete, getPartnerTasks(leadIds));
        }
    }

    //On After Update of Opportunity Record
    public void onAfterOpportunityUpdate(List<Opportunity> updatedOpportunities, List<Opportunity> oldOpportunities, Map<Id, Opportunity> updatedOpportunityMap, Map<Id, Opportunity> oldOpportunityMap){
        List<String> completedOppIds = new List<String>();
        List<String> signedCustomerOppIds = new List<String>();        
        List<String> counterSignedCustomerOppIds = new List<String>();        
        List<String> uploadedSalesAgreementCustomerOppIds = new List<String>();                
        List<String> oppLeadIds = new List<String>();
        List<String> oppLeadIdsList = new List<String>();
        Integer loanTerm;
        Integer interestOnlyPeriod;

        for (Opportunity newOpp : updatedOpportunities) {
            if (newOpp.StageName == 'Complete' && oldOpportunityMap.get(newOpp.Id).StageName != 'Complete' && newOpp.Product_Line__c == 'Residential Loan') {
                completedOppIds.add(newOpp.Id);
            }
            if (newOpp.Contract_Status__c == 'Completed' && oldOpportunityMap.get(newOpp.Id).Contract_Status__c != 'Completed' && newOpp.Product_Line__c == 'Residential Loan') {
                signedCustomerOppIds.add(newOpp.Id);
            }            
            if (newOpp.BlueWave_Signature_Status__c == 'Completed' && oldOpportunityMap.get(newOpp.Id).BlueWave_Signature_Status__c != 'Completed' && newOpp.Product_Line__c == 'Residential Loan') {
                counterSignedCustomerOppIds.add(newOpp.Id);
            }               
            if (newOpp.Partner_Sales_Agreement_Status__c == 'Completed' && oldOpportunityMap.get(newOpp.Id).Partner_Sales_Agreement_Status__c != 'Completed' && newOpp.Product_Line__c == 'Residential Loan') {
                uploadedSalesAgreementCustomerOppIds.add(newOpp.Id);
            }                 
            if (newOpp.Disbursal_1_Contract_Signature_Checkbox__c != oldOpportunityMap.get(newOpp.Id).Disbursal_1_Contract_Signature_Checkbox__c || 
                newOpp.Disbursal_Type_Contract__c != oldOpportunityMap.get(newOpp.Id).Disbursal_Type_Contract__c) {
                updateDisbursalRecords(updatedOpportunityMap, oldOpportunityMap);
            }
            if (newOpp.Disbursal_3_Full_Install_Checkbox__c != oldOpportunityMap.get(newOpp.Id).Disbursal_3_Full_Install_Checkbox__c || 
                newOpp.Disbursal_Type_Interconnect__c != oldOpportunityMap.get(newOpp.Id).Disbursal_Type_Interconnect__c) {
                updateDisbursalRecords(updatedOpportunityMap, oldOpportunityMap);
            }
            if (newOpp.Disbursal_2_Mechanical_Install_Checkbox__c != oldOpportunityMap.get(newOpp.Id).Disbursal_2_Mechanical_Install_Checkbox__c) {
                updateDisbursalRecords(updatedOpportunityMap, oldOpportunityMap);
            }                     
        }
        if (!completedOppIds.isEmpty()){
            List<Loan__c> completedOpportunityLoans = [SELECT Id, Name, Lead__c, Loan_Tranche__c, DOER_Solar_Loann__c, 
                                                        Interest_Ratee__c, Unique_ID__c, Sales_Agent__c, Financing_Fee__c, 
                                                        System_Costt__c, Partner__c, State__c, Lead_ID__c, Product__c, 
                                                        Product__r.Loan_Term__c, Product__r.Loan_Interest_Only_Period__c,
                                                        Technology_Platform_Fee__c
                                                       FROM Loan__c 
                                                       WHERE Opportunity__r.Id IN : completedOppIds];
            List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(completedOpportunityLoans));
            for (Loan__c loanRecord : tranchedLoans){
                loanRecord.Contracted__c = true;
            }    
            upsert new list<Loan__c>(tranchedLoans) Unique_ID__c;
        }
        for (Opportunity oppRecord : updatedOpportunities) {
            oppLeadIds.add(oppRecord.Lead_ID__c);
        }              
        if (!signedCustomerOppIds.isEmpty()) {          
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(updatedOpportunities);
            if (partnerTaskList.size() > 0) {
                updatePartnerTaskObtainContractSignature(updatedOpportunities, getPartnerTasks(oppLeadIds));       
            }
        }
        if (!counterSignedCustomerOppIds.isEmpty()) {          
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(updatedOpportunities);
            if (partnerTaskList.size() > 0) {
                updatePartnerTaskBlueWaveCounterSignature(updatedOpportunities, getPartnerTasks(oppLeadIds));       
            }
        }       
        if (!uploadedSalesAgreementCustomerOppIds.isEmpty()) {
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(updatedOpportunities);
            if (partnerTaskList.size() > 0) {
                updateSalesAgreementPartnerTask(updatedOpportunities, getPartnerTasks(oppLeadIds));       
            }
        }          
    }
        
    public List<Partner_Task__c> checkForPartnerTasksOnOpportunity(List<Opportunity> opportunities) {
        List<String> oppIds = new List<String>();
        for (Opportunity oppRecord : opportunities) {
            oppIds.add(oppRecord.Id);
        }
        List<Partner_Task__c> partnerTasks = [SELECT Id FROM Partner_Task__c WHERE Opportunity__r.Id IN : oppIds];
        return partnerTasks;
    }

    public void onAfterResidentialEquipmentUpdate(List<Residential_Equipment__c> newEquipment, List<Residential_Equipment__c> oldEquipment){
        List<String> equipmentLeadIdListMechInstall = new List<String>();
        List<String> equipmentLeadIdListInterconnection = new List<String>();

        Map<Id, Residential_Equipment__c> newEquipmentMap = (Map<Id,Residential_Equipment__c>) Trigger.newMap;
        Map<Id, Residential_Equipment__c> oldEquipmentMap = (Map<Id,Residential_Equipment__c>) Trigger.oldMap;

        for (Residential_Equipment__c equipment : newEquipment) {
            if (newEquipmentMap.get(equipment.Id).Mechanically_Installed__c 
                && !oldEquipmentMap.get(equipment.Id).Mechanically_Installed__c) {
                    equipmentLeadIdListMechInstall.add(equipment.Lead__r.Id);
            }
            if (newEquipmentMap.get(equipment.Id).Interconnected__c 
                && !oldEquipmentMap.get(equipment.Id).Interconnected__c) {
                    equipmentLeadIdListInterconnection.add(equipment.Lead__r.Id);
            }            
        }
         //if the equipment gets set to mechanically installed update the partner task to be complete.        
        if(equipmentLeadIdListMechInstall.size() > 0 ){
            updatePartnerTaskMechanicalInstallation(newEquipment, getPartnerTasks(equipmentLeadIdListMechInstall));
        }
        //if the equipment gets set to interconnected update the partner task to be complete.        
        if(equipmentLeadIdListInterconnection.size() > 0 ){
            updatePartnerTaskInterconnection(newEquipment, getPartnerTasks(equipmentLeadIdListInterconnection));
        }        
    }
    public void createResidentialEquipment(List<Lead> newLeadList){
        Map<String, RecordType> recordTypeMap = new Map<String, RecordType>();
        for (RecordType recordTypeVar : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Residential_Equipment__c' AND (Name = 'BlueWave Solar Loan' OR Name ='MSLP')]) {
            recordTypeMap.put(recordtypeVar.Name, recordTypeVar);
        }
        List<Residential_Equipment__c> newEquipmentList = new List<Residential_Equipment__c>();
        integer i;
        for (i = 0; i < newLeadList.size(); i++){
            if(newLeadList.get(i).Product_Line__c == 'Residential Loan'){
                if(newLeadList.get(i).DOER_Solar_Loan__c == false){
                    Residential_Equipment__c equipmentRecord = new Residential_Equipment__c(
                        Name = newLeadList.get(i).FirstName + ' ' + newLeadList.get(i).LastName,
                        Lead__c = newLeadList.get(i).Id,
                        RecordTypeId = recordTypeMap.get('BlueWave Solar Loan').Id);
                    newEquipmentList.add(equipmentRecord);                
                }
                else{
                    Residential_Equipment__c equipmentRecord = new Residential_Equipment__c(
                        Name = newLeadList.get(i).FirstName + ' ' + newLeadList.get(i).LastName,
                        Lead__c = newLeadList.get(i).Id,
                        RecordTypeId = recordTypeMap.get('MSLP').Id);
                    newEquipmentList.add(equipmentRecord);      
                }         
            }
        }
        //List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(newLoanList));    
        insert newEquipmentList;
    }

    public void createLoan(List<Lead> newLeadList){
        Loan_Traunch__c tranchePending = [SELECT Id, Name 
                                          FROM Loan_Traunch__c 
                                          WHERE Name = 'Tranche Assignment Pending'];
        List<Loan__c> newLoanList = new List<Loan__c>();
        integer i;
        for (i = 0; i < newLeadList.size(); i++){
            if(newLeadList.get(i).Product_Line__c == 'Residential Loan'){
                if(newLeadList.get(i).DOER_Solar_Loan__c == false){
                    Loan__c loan = new loan__c(
                        Name = newLeadList.get(i).FirstName + ' ' + newLeadList.get(i).LastName,
                        Lead__c = newLeadList.get(i).Id,
                        Loan_Tranche__c = tranchePending.Id,
                        DOER_Solar_Loann__c = newLeadList.get(i).DOER_Solar_Loan__c,
                        Interest_Ratee__c = newLeadLIst.get(i).Product__r.Loan_Interest_rate__c,
                        Unique_ID__c = newLeadList.get(i).id,
                        Sales_Agent__c = newLeadList.get(i).BS_Sales_ID__c,
                        //Principall__c = newLeadList.get(i).Loan_Principal__c,
                        Financing_Fee__c = newLeadList.get(i).Loan_Financing_Fee__c,
                        Technology_Platform_Fee__c = newLeadList.get(i).Technology_Platform_Fee__c,
                        System_Costt__c = newLeadList.get(i).System_Cost__c,
                        Partner__c = newLeadList.get(i).Partner_Lookup__c,
                        State__c = newLeadList.get(i).LASERCA__Home_State__c,
                        Lead_ID__c = newLeadList.get(i).Id,
                        Product__c = newLeadList.get(i).Product__c);
                    newLoanList.add(loan);                
                }
                else{
                    Loan__c loan = new loan__c(
                        Name = newLeadList.get(i).FirstName + ' ' + newLeadList.get(i).LastName,
                        DOER_Solar_Loann__c = true,                         
                        Lead__c = newLeadList.get(i).Id,
                        Loan_Tranche__c = tranchePending.Id,
                        Interest_Only_Period_DOER__c = newLeadList.get(i).Product__r.Loan_Interest_Only_period__c,
                        Interest_Ratee__c = newLeadLIst.get(i).Product__r.Loan_Interest_rate__c,
                        Unique_ID__c = newLeadList.get(i).id,
                        Sales_Agent__c = newLeadList.get(i).BS_Sales_ID__c,
                        //Principall__c = newLeadList.get(i).Loan_Principal__c,
                        Financing_Fee__c = newLeadList.get(i).Loan_Financing_Fee__c,
                        Technology_Platform_Fee__c = newLeadList.get(i).Technology_Platform_Fee__c,
                        System_Costt__c = newLeadList.get(i).System_Cost__c,
                        Partner__c = newLeadList.get(i).Partner_Lookup__c,
                        State__c = newLeadList.get(i).LASERCA__Home_State__c,
                        Lead_ID__c = newLeadList.get(i).Id,
                        Product__c = newLeadList.get(i).Product__c);
                    newLoanList.add(loan);       
                }         
            }
        }
        //List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(newLoanList));    
        upsert new list<Loan__c>(newLoanList) Unique_ID__c;
        assignResidentialEquipmentToLoan(newLoanList);
    }
    
    public void mapLoanToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap){
        List<Loan__c>loanListToUpdate = new List<Loan__c>();         
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()){
            if (leadRecord.IsConverted 
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan'){
                feedback2OppId.put(leadRecord.Id, leadRecord.ConvertedOpportunityId);
                opportunityMap.put(leadRecord.ConvertedOpportunityId,leadRecord.ConvertedOpportunityId);
            }
        }
        if(!opportunityMap.values().isEmpty()){        
            for(Loan__c loanRecord : [SELECT Lead__c, Opportunity__c FROM Loan__c WHERE Lead__c IN : feedback2OppId.keySet()]) {
                loanRecord.Opportunity__c = feedBack2OppId.get(loanRecord.Lead__c);
                loanListToUpdate.add(loanRecord);
            }
            update loanListToUpdate;
        }
    }  

    public void mapEquipmentToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap){
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();        
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()){
             if (leadRecord.IsConverted 
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan'){
                feedback2OppId.put(leadRecord.Id, leadRecord.convertedOpportunityId);
                opportunityMap.put(leadRecord.convertedOpportunityId,leadRecord.convertedOpportunityId);
            }
        }
        if(!feedback2OppId.values().isEmpty()){        
            for(Residential_Equipment__c equipment : [SELECT Lead__c, Opportunity__c FROM Residential_Equipment__c WHERE Lead__c IN : feedback2OppId.keySet()]) {
                equipment.Opportunity__c = feedBack2OppId.get(equipment.Lead__c);
                equipmentListToUpdate.add(equipment);
            }
            update equipmentListToUpdate;
        }
    }  

    public void mapPartnerTasksToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap){
        List<Partner_Task__c> partnerTaskListToUpdate = new List<Partner_Task__c>();                
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()){
             if (leadRecord.IsConverted 
                && !oldLeadMap.get(leadRecord.Id).IsConverted
                && leadRecord.Product_Line__c == 'Residential Loan'){
                feedback2OppId.put(leadRecord.Id, leadRecord.convertedOpportunityId);
                opportunityMap.put(leadRecord.convertedOpportunityId,leadRecord.convertedOpportunityId);
            }
        }
        if(!feedback2OppId.values().isEmpty()) {
            if(!opportunityMap.values().isEmpty()){        
                for(Partner_Task__c task : [SELECT Lead__c, Opportunity__c FROM Partner_Task__c WHERE Lead__c IN : feedback2OppId.keySet()]) {
                    task.Opportunity__c = feedBack2OppId.get(task.Lead__c);
                    partnerTaskListToUpdate.add(task);
                }
                update partnerTaskListToUpdate;
            }
        }
    }   

    public void mapCoApplicantContactToOpportunity(Map<Id, Lead> updatedLeadMap, Map<Id, Lead> oldLeadMap){
        List<Contact> contactListToUpdate = new List<Contact>();
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead leadRecord : updatedLeadMap.values()) {
            if (leadRecord.IsConverted 
                && !oldLeadMap.get(leadRecord.Id).IsConverted 
                && leadRecord.ConvertedOpportunityId != null 
                && leadRecord.Product_Line__c == 'Residential Loan' 
                && leadRecord.Application_Type__c == 'Joint') {
                feedBack2OppId.put(leadRecord.Id, leadRecord.ConvertedOpportunityId);
                opportunityMap.put(leadRecord.ConvertedOpportunityId, leadRecord.ConvertedOpportunityId);
            }
        }
        if(!feedback2OppId.values().isEmpty()) {
            for(Contact contactRecord : [SELECT Lead__c, Opportunity__c FROM Contact WHERE Lead__c IN : feedback2OppId.keySet()]) {
                contactRecord.Opportunity__c = feedBack2OppId.get(contactRecord.Lead__c);
                contactListToUpdate.add(contactRecord);
            }
            update contactListToUpdate;
        }
    }

    public List<Loan__c> assignLoanTranche(List<Loan__c> newLoanList){
        Loan_Traunch__c temporaryHoldingTranche;
        List<Loan_Traunch__c> trancheRecordList = new List<Loan_Traunch__c>();
        List<Loan__c> tranchedLoans = new List<Loan__c>();
        List<String> productIds = new List<String>();
        Map<String, Product2> loanProductMap = new Map<String, Product2>();
        try{
            for (Loan__c l : newLoanList){
                productIds.add(l.Product__c);
            }
            for(Product2 productRecord : [SELECT Id, Name, Loan_Capital_Pool__r.Id, Loan_Tranche_type__c FROM Product2 WHERE Id IN : productIds]){
                for (Loan__c l : newLoanList){
                    if (l.Product__c == productRecord.Id){
                        loanProductMap.put(l.Id, productRecord);
                    }
                }                
            }
            for (Loan_Traunch__c trancheRecord : [SELECT Id, Name, State__c, Loan_Data__r.Id, Available_Capital__c, Stage__c FROM Loan_Traunch__c]){
                if (trancheRecord.Stage__c == 'Open' && trancheRecord.Available_Capital__c > 0 && trancheRecord.Name != 'No Available Capital - Temporary Holding Tranche'){
                    trancheRecordList.add(trancheRecord);
                }
                if (trancheRecord.Name == 'No Available Capital - Temporary Holding Tranche'){
                    temporaryHoldingTranche = trancheRecord;
                }               
            }
            for (Loan__c loanRecord : newLoanList){
                    for(Loan_Traunch__c trancheRecord : trancheRecordList){
                    //Error messages must be put in place
                    //if(trancheRecord.Available_Capital__c <= oppRecord.Loan_Amount_Financed__c){
                    //    //trancheRecord.addError('There is not enough capital available in the tranches' , false);
                    //    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,''+'There is not enough capital available in the tranches' ));
                    //}
                    if(trancheRecord.State__c == loanRecord.State__c && 
                        trancheRecord.Loan_Data__r.Id == loanProductMap.get(loanRecord.Id).Loan_Capital_Pool__r.Id &&                        
                        trancheRecord.Tranche_Type__c == loanProductMap.get(loanRecord.Id).Loan_Tranche_type__c){   
                        if(trancheRecord.Available_Capital__c >= loanRecord.System_Costt__c){
                            loanRecord.Loan_Tranche__c = trancheRecord.Id;
                            tranchedLoans.add(loanRecord);
                        }else{
                            loanRecord.Loan_Tranche__c = temporaryHoldingTranche.Id;
                            tranchedLoans.add(loanRecord);
                        }          
                    }
                }
            }             
            return tranchedLoans;   
        }
        catch(exception e){

            return null;
        }
    }

    public void createDisbursalsFromOpportunity(List<Opportunity> updatedOppList, List<Opportunity> oldOppList){
        List<Loan__c> loanList = new List<Loan__c>();    
        List<String> disbursalOppList = new List<String>();

        Map<Id, Opportunity> newOppMap = (Map<Id,Opportunity>) Trigger.newMap;
        Map<Id, Opportunity> oldOppMap = (Map<Id,Opportunity>) Trigger.oldMap;

        for (Opportunity oppRecord : updatedOppList) {
            if (newOppMap.get(oppRecord.Id).StageName == 'Complete' 
                && oldOppMap.get(oppRecord.Id).StageName != 'Complete'
                && newOppMap.get(oppRecord.Id).Product_Line__c == 'Residential Loan') {
                    disbursalOppList.add(newOppMap.get(oppRecord.Id).Id);
            }
        }
        if(disbursalOppList.size() > 0){
            for(Opportunity opp : [SELECT Id, Name, (SELECT Id, Name FROM Loans__r) 
                                    FROM Opportunity 
                                    WHERE Id IN : disbursalOppList]){
                loanList.add(opp.Loans__r);
            }
            createDisbursals(loanList);            
        }
    }

    public void createDisbursals(List<Loan__c> newLoanList){
        List<Disbursal__c> disbursalInsertList = new List<Disbursal__c>();
        Decimal systemCost;
        String disbursalName;
        for (Loan__c loanRecord : [SELECT Id, Name, Opportunity__r.StageName, System_Costt__c, Partner__r.Id, Partner__r.Name, 
                                    Product__r.Disbursal_Terms__c, Opportunity__r.Loan_Principle__c, Sales_Agent__r.Id 
                                    FROM Loan__c 
                                    WHERE Id IN : newLoanList]){
            // make this code more efficient by creating fields on the product that allow the user to select :
            // Number of dibursals - disubrsals percentage intervals. Parse the text by commas.
            // Example : 
            //      Disbursal_Count__c = 3
            //      Disbursal Setup = .30, .60, .10
            if(loanRecord.Opportunity__r.StageName == 'Complete'){
                if(loanRecord.System_Costt__c != null && loanRecord.System_Costt__c > 0) {
                    systemCost = loanRecord.System_Costt__c;
                }else {
                    systemCost = loanRecord.Opportunity__r.Loan_Principle__c;
                }
                if(loanRecord.Product__r.Disbursal_Terms__c == '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection'){
                    
                    disbursalName = '30% Contract Signature' + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                        disbursalName = disbursalName.subString(0,80);
                    }

                    Disbursal__c disbursal1 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '30% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 1,
                        Disbursal_Percentage__c = 0.3,
                        Partner__c = loanRecord.Partner__r.Id,
                        Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.30,
                        Type__c = 'Contract Signature',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);

                    disbursalInsertList.add(disbursal1);
                    disbursalName = '60% Mechanical Installation' + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                    disbursalName = disbursalName.subString(0,80);
                    }                                                            
                    Disbursal__c disbursal2 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '60% Mechanical Installation' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 2,
                        Partner__c = loanRecord.Partner__r.Id,
                        Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                        Disbursal_Percentage__c = 0.6,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.60,
                        Type__c = 'Mechanical Installation',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);

                    disbursalInsertList.add(disbursal2);
                    disbursalName = '10% Interconnection'  + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                    disbursalName = disbursalName.subString(0,80);
                    }                                                               
                    Disbursal__c disbursal3 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '10% Interconnection' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 3,
                        Partner__c = loanRecord.Partner__r.Id,
                        Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                        Disbursal_Percentage__c = 0.1,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.10,
                        Type__c = 'Interconnection',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                     disbursalInsertList.add(disbursal3);
                }
                if(loanRecord.Product__r.Disbursal_Terms__c == '35% Contract Signature, 65% Interconnection'){
                    disbursalName = '35% Contract Signature' + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                    disbursalName = disbursalName.subString(0,80);
                    }                                                              
                    Disbursal__c disbursal1 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '35% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 1,
                        Partner__c = loanRecord.Partner__r.Id,
                        Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                        Disbursal_Percentage__c = 0.35,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.35,
                        Type__c = 'Contract Signature',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);

                    disbursalInsertList.add(disbursal1);
                    disbursalName = '65% Interconnection' + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                    disbursalName = disbursalName.subString(0,80);
                    }                                                             
                    Disbursal__c disbursal2 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '65% Interconnection' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 2,
                        Partner__c = loanRecord.Partner__r.Id,
                        Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                        Disbursal_Percentage__c = 0.65,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.65,
                        Type__c = 'Interconnection',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                     disbursalInsertList.add(disbursal2);                
                }
                disbursalName = null;
            }
        }  
        upsert disbursalInsertList Unique_ID__c ;
    }

    public void createLoanPartnerTasks(List<Loan__c> newLoanList){
        List<Partner_Task__c> taskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> parentTaskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> subParentTaskInsertList = new List<Partner_Task__c>();
        List<Partner_Task__c> subTaskInsertList = new List<Partner_Task__c>();
        List<Loan__c> loanList = new List<Loan__c>();
        List<String> leadIdList = new List<String>();
        Map<String, Partner_Task__c> parentTaskAssignmentMap = new Map<String, Partner_Task__c>();
        Map<String, Partner_Task__c> subParentTaskAssignmentMap = new Map<String, Partner_Task__c>();
        Map<String, Partner_Task__c> taskMap = new Map<String, Partner_Task__c>();       
        String taskUniqueId;
        String subTaskTypeMapUniqueId;
        String parentTaskTypeMapUniqueId;
        String shortenedIdForMapKey;
        String leadIdSubString;
        RecordType parentPartnerTaskRecordType;
        RecordType childPartnerTaskRecordType;
        Integer partnerSequenceCounter = 1;

        parentPartnerTaskRecordType = [SELECT Id FROM RecordType WHERE Name = 'Parent Partner Task' AND SobjectType = 'Partner_Task__c' LIMIT 1];
        childPartnerTaskRecordType = [SELECT Id FROM RecordType WHERE Name = 'Child Partner Task' AND SobjectType = 'Partner_Task__c' LIMIT 1];
        
        for (Loan__c loanRecord : [SELECT Id, Name, System_Costt__c, Partner__r.Id, Partner__r.Name, Lead__r.Id, Lead__c,
                                   Product__r.Disbursal_Terms__c, Opportunity__r.DOER_Solar_Loan__c, DOER_Solar_Loann__c,
                                   Lead__r.System_Cost__c, Lead__r.Retired__c, Lead__r.Self_Employed__c, Lead__r.Application_Type__c,
                                   Sales_Agent__r.Id 
                                   FROM Loan__c 
                                   WHERE Id IN : newLoanList]){
            Partner_Task__c creditTask = createPartnerTask(loanRecord, 'GrandParent', 'Run Credit Check', 'Run Credit Check', partnerSequenceCounter, 'Complete', 'Credit Check', null, null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Credit');            
            partnerSequenceCounter += 1;
            Partner_Task__c allInformationTask = createPartnerTask(loanRecord, 'GrandParent', 'Provide All Customer Information', 'Provide All Customer Information', partnerSequenceCounter, 'Pending', 'Customer Information', null, null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Information');
            partnerSequenceCounter += 1;
            Partner_Task__c bwReviewTask = createPartnerTask(loanRecord, 'GrandParent', 'Under BlueWave Review', 'Under BlueWave Review', partnerSequenceCounter, 'Incomplete', 'Under BlueWave Review', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Review');
            partnerSequenceCounter += 1;
            Partner_Task__c contractSignatureTask = createPartnerTask(loanRecord, 'GrandParent', 'Obtain Contract Signature', 'Obtain Contract Signature', partnerSequenceCounter, 'Incomplete', 'Contract', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Contract');                
            partnerSequenceCounter += 1;  
            if (!loanRecord.DOER_Solar_Loann__c){                      
                Partner_Task__c salesAgreementTask = createPartnerTask(loanRecord, 'GrandParent', 'Provide Sales Agreement', 'Sales Agreement', partnerSequenceCounter, 'Incomplete', 'Sales Agreement', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Sales Agreement');
                partnerSequenceCounter += 1;
            }
            Partner_Task__c bwContractSignature = createPartnerTask(loanRecord, 'GrandParent', 'BlueWave Counter Signature', 'BlueWave Counter Signature', partnerSequenceCounter, 'Incomplete', 'Contract', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Countersign');                
            partnerSequenceCounter += 1;            
            if (!loanRecord.DOER_Solar_Loann__c){
                Partner_Task__c mechanicalInstallationTask = createPartnerTask(loanRecord, 'GrandParent', 'Mechanical Installation', 'Mechanical Installation', partnerSequenceCounter, 'Incomplete', 'Mechanical Installation', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Install');                
                partnerSequenceCounter += 1;
                Partner_Task__c interconnectionTask = createPartnerTask(loanRecord, 'GrandParent', 'Interconnection', 'Interconnection', partnerSequenceCounter, 'Incomplete', 'Interconnection', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Interconnect');                            
                partnerSequenceCounter += 1;
            } else {
                Partner_Task__c interconnectionTaskMSLP = createPartnerTask(loanRecord, 'GrandParent', 'Report Interconnection to MCEC', 'Interconnection', partnerSequenceCounter, 'Incomplete', 'Interconnection MSLP', null,  null, parentPartnerTaskRecordType, parentTaskInsertList, null, null, parentTaskAssignmentMap, null, 'Interconnect');                                            
                partnerSequenceCounter += 1;           
            }
            Partner_Task__c incomeDocumentationTask = createPartnerTask(loanRecord, 'Parent', 'Provide Income Documentation', 'Income Documentation', null, 'Incomplete', 'Customer Information', 'Income Documentation',  allInformationTask, childPartnerTaskRecordType, null, subParentTaskInsertList, null, null, subParentTaskAssignmentMap, null);                                            
            if (!loanRecord.DOER_Solar_Loann__c){
                Partner_Task__c systemInformationTask = createPartnerTask(loanRecord, 'Parent', 'Provide all System Information', 'Provide all System Information', null, 'Incomplete', 'Customer Information', 'System Information', allInformationTask, childPartnerTaskRecordType, null, subParentTaskInsertList, null, null, subParentTaskAssignmentMap, null);                                            
            } else {
                Partner_Task__c technicalApprovalTask = createPartnerTask(loanRecord, 'Parent', 'Provide Technical Confirmation Documentation', 'Technical Approval Confirmation', null, 'Incomplete', 'Customer Information', 'Technical Approval', allInformationTask, childPartnerTaskRecordType, null, subParentTaskInsertList, null, null, subParentTaskAssignmentMap, null);                                                        
            }
            if (loanRecord.Lead__r.Self_Employed__c == false && loanRecord.lead__r.Retired__c == false){
                Partner_Task__c payStubDocumentationTask = createPartnerTask(loanRecord, 'Child', 'Provide PayStub Documentation', 'PayStub Documentation', null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask, childPartnerTaskRecordType, null, null, subTaskInsertList, null, null, null);                                                                        
            } else if(loanRecord.Lead__r.Self_Employed__c == true && loanRecord.lead__r.Retired__c == false){
                Partner_Task__c selfEmploymentTaxReturnPreviousYearTask = createPartnerTask(loanRecord, 'Child', 'Provide Tax Return (Previous Year)', 'Tax Return (Previous Year)', null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask, childPartnerTaskRecordType, null, null, subTaskInsertList, null, null, null);                                                                        
                Partner_Task__c selfEmploymentTaxReturnTwoYearsPreviousTask = createPartnerTask(loanRecord, 'Child', 'Provide Tax Return (Two Years Previous)', 'Tax Return (Two Years Previous)', null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask, childPartnerTaskRecordType, null, null, subTaskInsertList, null, null, null);                                                                                    
            } else if(loanRecord.Lead__r.Self_Employed__c == false && loanRecord.lead__r.Retired__c == true){
                Partner_Task__c retirementIncomeDocumentationTask = createPartnerTask(loanRecord, 'Child', 'Provide SSN/Pension Award Letter or Bank Statement', 'SSN/Pension Award Letter or Bank Statement', null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask, childPartnerTaskRecordType, null, null, subTaskInsertList, null, null, null);                                                                                    
            } else if(loanRecord.Lead__r.Self_Employed__c == true && loanRecord.lead__r.Retired__c == true){
                Partner_Task__c allIncomeDocumentationTask = createPartnerTask(loanRecord, 'Child', 'Provide All Income Documentation', 'All Income Documentation', null, 'Incomplete', 'Customer Information', 'Income Documentation', incomeDocumentationTask, childPartnerTaskRecordType, null, null, subTaskInsertList, null, null, null);                                                                                    
            }

        loanList.add(loanRecord);
        leadIdList.add(loanRecord.Lead__c);   
        partnerSequenceCounter = 1;
        }
        Upsert parentTaskInsertList Unique_ID__c;
        for (Partner_Task__c task : subParentTaskInsertList){
            shortenedIdForMapKey = task.Task_Type__c + ' ' + task.Unique_ID__c.subString(0,18);
            task.Parent_Task__c = parentTaskAssignmentMap.get(shortenedIdForMapKey).Id;
        }
        upsert subParentTaskInsertList Unique_ID__c;
        for (Partner_Task__c task : subTaskInsertList){             
            shortenedIdForMapKey = task.Sub_Task_Type__c + ' ' + task.Unique_ID__c.subString(0,18);           
            task.Parent_Task__c = subParentTaskAssignmentMap.get(shortenedIdForMapKey).Id;
        }        

        taskInsertList.addAll(parentTaskInsertList);
        taskInsertList.addAll(subParentTaskInsertList);
        taskInsertList.addAll(subTaskInsertList);

        for (Partner_Task__c taskRecord : taskInsertList){
            taskMap.put(taskRecord.Unique_ID__c, taskRecord);
        }

        Upsert subTaskInsertList Unique_ID__c;
        List<Lead> leadList = [SELECT Id, Name, Self_Employed__c, Retired__c  FROM Lead WHERE Id IN : leadIdList];
        validateLoanInformationProvidedOnLead(leadList, taskMap);   // add conditional customer type as a parameter to run income check on retirees, etc. 
    }

    public Partner_Task__c createPartnerTask (Loan__c loanRecord, String taskLevel, String name, String uniqueId, Integer partnerSequenceCounter, String status, String taskType, String subTaskType, Partner_Task__c parentTask, RecordType recordType, List<Partner_Task__c> parentTaskInsertList, List<Partner_Task__c> subParentTaskInsertList, List<Partner_Task__c> subTaskInsertList,  Map<String, Partner_Task__c> parentTaskAssignmentMap, Map<String, Partner_Task__c> subParentTaskAssignmentMap, String progressBarName){
        String parentTaskTypeMapUniqueId;
        String subTaskTypeMapUniqueId;        
        if (taskLevel == 'Grandparent') {
            Partner_Task__c task = new Partner_Task__c(
                Name = name,
                RecordType = recordType,
                Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + uniqueId,                
                Partner__c = loanRecord.Partner__r.Id,
                Sales_Representative__c = LoanRecord.Sales_Agent__r.Id,
                Parent__c = true,
                Task_Sequence__c = partnerSequenceCounter,
                Status__c = status,
                Start_Date__c = Date.today(),                
                Task_Type__c = taskType,
                Loan__c = loanRecord.Id,
                Progress_Bar_Name__c = progressBarName 
            );
            if (name == 'Run Credit Check') {
                task.Completion_Date__c = Date.today();
            }
            if (name == 'Provide All Customer Information') {
                task.SubTasks__c = true;
            }            
            parentTaskInsertList.add(task);
            parentTaskTypeMapUniqueId = task.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, task);
            partnerSequenceCounter = partnerSequenceCounter + 1;                  
            return task;                                      
        } else if (taskLevel == 'Parent') {
            Partner_Task__c task = new Partner_Task__c(
                Name = name,
                RecordType = recordType,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + uniqueId,                
                Partner__c = loanRecord.Partner__r.Id,
                Sales_Representative__c = LoanRecord.Sales_Agent__r.Id,
                Parent__c = true,
                Status__c = status,
                Start_Date__c = Date.today(),
                Task_Type__c = taskType,
                Sub_Task_Type__c = subTaskType,                
                Parent_Task__c = parentTask.Id,                
                Loan__c = loanRecord.Id
            );
            if (name == 'Provide Income Documentation') {
                task.SubTasks__c = true;
            }
            subParentTaskInsertList.add(task);
            subTaskTypeMapUniqueId = task.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, task);              
            return task;                          
        } else if (taskLevel == 'Child') {
            Partner_Task__c task = new Partner_Task__c(
                Name = name,
                RecordType = recordType,
                Parent_Task__c = parentTask.Id,                                
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + uniqueId,                
                Partner__c = loanRecord.Partner__r.Id,
                Sales_Representative__c = LoanRecord.Sales_Agent__r.Id,
                Status__c = status,
                Sub_Task_Type__c = subTaskType, 
                Start_Date__c = Date.today(),
                Task_Type__c = taskType
            );
            subTaskInsertList.add(task);            
            return task;                                      
        } else {
            return null;
        }         
    }

    public Map<String, Partner_Task__c> getPartnerTasks(List<String> leadList){
        Map<String, Partner_Task__c> taskMap = new Map<String, Partner_Task__c>();
        for (Partner_Task__c partnerTask : [SELECT Id, Name, Parent_Task__c, Unique_ID__c, Partner__c, Parent__c,  Task_Sequence__c,
                                                Status__c, Start_Date__c, Task_Type__c, Lead__c, Lead__r.Id, Comments__c,
                                                (SELECT Id, Name, Status__c, Parent_Task__c, Parent_Task__r.Name 
                                                 FROM subTasks__r)
                                            FROM Partner_Task__c
                                            WHERE (Lead__c IN : leadList 
                                                OR Parent_Task__r.Loan__r.Lead__r.Id IN : leadList)]){
            taskMap.put(partnerTask.Unique_ID__c, partnerTask);
        }
        return taskMap;
    }

    public void validateLoanInformationProvidedOnLead(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        List<Partner_Task__c> validatedTaskList = new List<Partner_Task__c>();
        
        if (!leadList.isEmpty()) {
            List<Partner_Task__c> incomeTaskList = new List<Partner_Task__c>(checkLoanIncomeFiles(leadList, taskMap));
            validatedTaskList.addAll(incomeTaskList);  

            List<Partner_Task__c> systemInfoTaskList = new List<Partner_Task__c>(checkSystemInformation(leadList, taskMap));
            validatedTaskList.addAll(systemInfoTaskList);
            
            List<Partner_Task__c> technicalApprovalTaskList = new List<Partner_Task__c>(checkTechnicalConfirmationFiles(leadList, taskMap));
            validatedTaskList.addAll(technicalApprovalTaskList);        
        }
        //Load the validatedTaskList into a set to remove duplicates. This is important, if the validation methods return
        //a task in both lists it will send an error. Main cause of this is due to the inocompleteTaskList return statement
        //at the bottom of both methods. They're needed however to save the method. 
        Set<Partner_Task__c> validatedTaskSet = new Set<Partner_Task__c>(validatedTaskList);
        ////load the set back into a list for update
        List<Partner_Task__c> validatedTaskListDuplicatesRemoved = new List<Partner_Task__c>();
        validatedTaskListDuplicatesRemoved.addAll(validatedTaskSet);
        update validatedTaskListDuplicatesRemoved; //update the subtasks
        //run through this method twice because the child tasks have to be updated before the parent tasks in order to qualify for completion.
        updatePartnerParentTaskStatus(taskMap); //update the Parent SubTasks
        updatePartnerParentTaskStatus(taskMap); //update the Parent Tasks
    } 

    public List<Partner_Task__c> checkLoanIncomeFiles(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        String customerIncomeType;
        List<Id> leadIdList = new List<Id>();
        List<String> loanIdList = new List<String>();
        List<Attachment> payStubList = new List<Attachment>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());
        Map<String, String> customerIncomeTypeMap = new Map<String, String>();

        for (Lead leadRecord : leadList){
            leadIdList.add(leadRecord.Id);
            if(leadRecord.Self_Employed__c == false && leadRecord.Retired__c == false){
                customerIncomeType = 'Standard';
            }else if(leadRecord.Self_Employed__c == true && leadRecord.Retired__c == false){
                customerIncomeType = 'selfEmployed';
            }else if(leadRecord.Self_Employed__c == false && leadRecord.Retired__c == true){
                customerIncomeType = 'retired';               
            }else if(leadRecord.Self_Employed__c == true && leadRecord.Retired__c == true){
                customerIncomeType = 'selfEmployedRetired';
            } 
            customerIncomeTypeMap.put(leadRecord.Id, customerIncomeType);            
        }

        for (Attachment incomeAttachment : [SELECT Id, Name, Body, ParentId, Description
                                            FROM Attachment
                                            WHERE Description != null AND ParentId IN : leadIdList]){
            for (String customerIncomeLeadId : customerIncomeTypeMap.keySet()){
                if(customerIncomeLeadId == incomeAttachment.ParentId){
                    if(customerIncomeTypeMap.get(customerIncomeLeadId) == 'Standard'){
                        if(incomeAttachment.Description.contains('Paystub')){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'PayStub Documentation';
                            taskMap.get(taskUniqueId).Status__c = 'Complete';
                            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();  
                            completedTaskList.add(taskMap.get(taskUniqueId));                           
                        }
                    }else if(customerIncomeTypeMap.get(customerIncomeLeadId) == 'selfEmployed'){
                        if(incomeAttachment.Description.contains('Tax Return (Previous Year)')){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'Tax Return (Previous Year)';
                            taskMap.get(taskUniqueId).Status__c = 'Complete';
                            taskMap.get(taskUniqueId).Completion_Date__c = Date.today(); 
                            completedTaskList.add(taskMap.get(taskUniqueId));
                        }else if(incomeAttachment.Description.contains('Tax Return (Two Years Previous)')){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'Tax Return (Two Years Previous)';
                            taskMap.get(taskUniqueId).Status__c = 'Complete';
                            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                            completedTaskList.add(taskMap.get(taskUniqueId));
                        }
                    }else if(customerIncomeTypeMap.get(customerIncomeLeadId) == 'retired'){
                        if(incomeAttachment.Description.contains('SSN Award Letter') 
                            || incomeAttachment.Description.contains('Pension Award Letter')
                            || incomeAttachment.Description.contains('Bank Statement (SSN Income)') ){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'SSN/Pension Award Letter or Bank Statement';
                            taskMap.get(taskUniqueId).Status__c = 'Complete';
                            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                            completedTaskList.add(taskMap.get(taskUniqueId));                         
                        }
                    }
                }
            }
        }
        if(completedTaskList.size()>0){
            return completedTaskList;
        }else{
            return incompleteTaskList;
        }  
    }

    public List<Partner_Task__c> checkSystemInformation(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        List<String> leadIdList = new List<String>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values()); 

        for (Lead leadRecord : leadList){
            leadIdList.add(leadRecord.Id);                        
        }

        for (Residential_Equipment__c equipment : [SELECT Id, Lead__c, Lead__r.Id, Loan__c, Loan__r.Id, Loan__r.Commencement_Datee__c,
                                                    Lead__r.System_Cost__c, Type_of_Module__c, Type_of_Inverter__c,
                                                    Number_of_Modules__c, Number_of_Inverters__c, Generator_Nameplate_Capacity__c,
                                                    Module_Manufacturer__c, Module_Model_Number__c, Inverter_Manufacturer__c, Inverter_Model_Number__c 
                                                   FROM Residential_Equipment__c
                                                   WHERE Lead__c IN : leadIdList]){
            taskUniqueId = equipment.Lead__r.Id + ' ' + 'Provide all System Information';
            if(equipment.Lead__r.System_Cost__c > 0 
                && equipment.Module_Manufacturer__c != null
                && equipment.Module_Model_Number__c != null
                && equipment.Number_of_Modules__c != null
                && equipment.Inverter_Manufacturer__c != null
                && equipment.Inverter_Model_Number__c != null
                && equipment.Number_of_Inverters__c != null
                && equipment.Generator_Nameplate_Capacity__c != null
                && equipment.Loan__r.Commencement_Datee__c != null
                && taskMap.get(taskUniqueId) != null
                && taskMap.get(taskUniqueId).Status__c != 'Complete'){
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                completedTaskList.add(taskMap.get(taskUniqueId));
            }
        }
        if(completedTaskList.size() > 0){
            return completedTaskList;
        }else{
            return incompleteTaskList;
        }
    }

    public List<Partner_Task__c> checkTechnicalConfirmationFiles (List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        List<Id> leadIdList = new List<Id>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());

        for (Lead leadRecord : leadList){
            leadIdList.add(leadRecord.Id);                      
        }

        for (Attachment technicalConfirmAttachment: [SELECT Id, Name, Body, ParentId, Description
                                                    FROM Attachment
                                                    WHERE Description != null             
                                                    AND ParentId IN : leadIdList]){
            if(technicalConfirmAttachment.Description.contains('MSLP Technical Confirmation')){
                taskUniqueId = technicalConfirmAttachment.ParentId + ' ' + 'Technical Approval Confirmation';
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                completedTaskList.add(taskMap.get(taskUniqueId));
            }
        }
        if(completedTaskList.size()>0){
            return completedTaskList;
        }else{
            return incompleteTaskList;
        }  
    }               


    //If all Partner Sub-Tasks are set to complete, set the parent Partner task to complete.
    public void updatePartnerParentTaskStatus(Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        Integer subTaskCompleteCount = 0;
        Integer subTaskSize;
        Decimal nextTask;
        List<Partner_Task__c> parentTasksToUpdate = new List<Partner_Task__c>();
        List<Partner_Task__c> parentTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> completedParentTasksWithNextTask = new List<Partner_Task__c>();
        List<String> leadIdList = new List<String>();

        for (Partner_Task__c task : taskMap.values()){
            if(task.Parent__c == true){ 
                parentTaskList.add(task);
            }
        }
        //check to see if below query is needed - it may not be. Written in due to uncertainty of child records coming into the taskMap parameter.
        for (Partner_Task__c parentTask : [SELECT Id, Name, Task_Type__c, Status__c, Parent__c, Task_Sequence__c, 
                                            Parent_Task__c, Unique_ID__c, Lead__r.Id, Lead__c,
                                            (SELECT Id, Name, Status__c, Parent_Task__c, Parent_Task__r.Name 
                                            FROM subTasks__r)
                                           FROM Partner_Task__c
                                           WHERE Id IN : parentTaskList]){            
            subTaskSize = parentTask.subTasks__r.size();
            for (Partner_Task__c subTask : parentTask.subTasks__r){
                if(subTask.Status__c == 'Complete'){
                    subTaskCompleteCount = subTaskCompleteCount + 1;
                }
            }
            if(subTaskCompleteCount == subTaskSize && subTaskCompleteCount != 0 && parentTask.Status__c != 'Complete'){
                parentTask.Status__c = 'Complete';
                parentTask.Completion_Date__c = Date.today();
                parentTasksToUpdate.add(parentTask);
                //Add all Parent tasks that have been set to complete to the completedTask list. Do not add it if it is the last task in the sequence
                if(parentTask.Sub_Task_Type__c == null && parentTask.Parent_Task__c == null){
                    leadIdList.add(parentTask.Lead__c);
                    completedParentTasksWithNextTask.add(parentTask);
                }
            }
            subTaskCompleteCount = 0;
        }
        //add the tasks that need to be changed to pending to the update list
        parentTasksToUpdate.addAll(updateNextTaskToPending(leadIdList, completedParentTasksWithNextTask));
        update parentTasksToUpdate;
    }

    public List<Partner_Task__c> updateNextTaskToPending(List<String> leadIdList, List<Partner_Task__c> completedTasks){
        String taskSequenceKey; //key value
        String taskSequenceUniqueId; //accessor value
        Decimal nextTask;
        Boolean executeLeadUpdate = false;
        List<Partner_Task__c> tasksToUpdate = new List<Partner_Task__c>();
        Map<String,Partner_Task__c> parentTaskSequenceMap = new Map<String, Partner_Task__c>();
        Map<String, Integer> parentTaskSizeMap = new Map<String, Integer>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        for (Lead leadRecord : [SELECT Id, Name, 
                                    (SELECT Id, Name, Task_Type__c, Status__c, Parent__c, Task_Sequence__c, 
                                        Parent_Task__c, Unique_ID__c
                                     FROM Partner_Tasks__r)
                                FROM Lead
                                WHERE Id IN : leadIdList]){
            leadMap.put(leadRecord.Id, leadRecord);
            for (Partner_Task__c task : leadRecord.Partner_Tasks__r){
                    taskSequenceKey = leadRecord.Id + ' ' + task.Task_Sequence__c;
                    parentTaskSequenceMap.put(taskSequenceKey, task);
            }
            parentTaskSizeMap.put(leadRecord.Id, leadRecord.Partner_Tasks__r.size());            
        }
        if(completedTasks.size() > 0){
            for (Partner_Task__c task : completedTasks){
                //if the partner task is not the last task in the sequence, update the next task to pending
                if(task.Task_Sequence__c < parentTaskSizeMap.get(task.Lead__r.Id)){
                    nextTask = task.Task_Sequence__c + 1;
                    taskSequenceUniqueId = task.Lead__r.Id + ' ' + nextTask;
                    if (task.Name == 'Provide All Customer Information') {
                        leadMap.get(task.Lead__c).Status = 'Under BlueWave Review';
                        executeLeadUpdate = true; 
                    }

                    if(parentTaskSequenceMap.get(taskSequenceUniqueId).Status__c == 'Incomplete' 
                        && task.Task_Sequence__c < parentTaskSequenceMap.size()){
                         parentTaskSequenceMap.get(taskSequenceUniqueId).Status__c = 'Pending';                   
                         parentTaskSequenceMap.get(taskSequenceUniqueId).Start_Date__c = Date.today(); 
                         tasksToUpdate.add(parentTaskSequenceMap.get(taskSequenceUniqueId));
                    }
                }
            }            
        }
        if (executeLeadUpdate) {
            update leadMap.values();            
        }
        return tasksToUpdate;    
    }

    // update the under BW review partner task when the lead gets converted to an opportunity
    public void updatePartnerTaskUnderBlueWaveReview(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> leadIdList = new List<String>();


        for (Lead leadRecord : leadList){
            taskUniqueId = leadRecord.Id + ' ' + 'Under BlueWave Review';
            taskMap.get(taskUniqueId).Status__c = 'Complete';
            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(taskMap.get(taskUniqueId));
            leadIdList.add(leadRecord.Id);
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(leadIdList, taskUpdateList));
        update nextTasksToUpdate;
    } 

    // update the contract signature partner task when the contract is signed and the oppStage is set to closed.
    public void updatePartnerTaskObtainContractSignature(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        String partnerTaskLeadIdSubString;
        String partnerTaskLeadIdString;
        String partnerTaskUniqueIdSubString;
        Partner_Task__c partnerTask;
        List<Partner_Task__c> parentPartnerTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> OppLeadIdList = new List<String>();
        Map<String, Partner_Task__c> tempTaskMapLeadId15String = new Map<String, Partner_Task__c>();

        // filter out the child-tasks from the task map
        for (Partner_Task__c partnerTaskLoopRecord : taskMap.values()) {
            if(partnerTaskLoopRecord.Parent__c == true && partnerTaskLoopRecord.Lead__c != null) {
                parentPartnerTaskList.add(partnerTaskLoopRecord);
            }
        }

        //create a new map that sets the 15 digit ID to the keyValue
        for (Partner_Task__c partnerTaskLoopRecord : parentPartnerTaskList) {
            partnerTaskLeadIdString = String.valueOf(partnerTaskLoopRecord.Lead__r.Id);
            partnerTaskLeadIdSubString = partnerTaskLeadIdString.subString(0,15);
            partnerTaskUniqueIdSubString = partnerTaskLeadIdSubString + ' ' + partnerTaskLoopRecord.Name;
            partnerTask = taskMap.get(partnerTaskLoopRecord.Unique_ID__c);
            tempTaskMapLeadId15String.put(partnerTaskUniqueIdSubString, partnerTask);
        }

        //locate the task and set it to complete
        for (Opportunity oppRecord : oppList){
            taskUniqueId = oppRecord.Lead_ID__c + ' ' + 'Obtain Contract Signature';
            tempTaskMapLeadId15String.get(taskUniqueId).Status__c = 'Complete';
            tempTaskMapLeadId15String.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(tempTaskMapLeadId15String.get(taskUniqueId));
            OppLeadIdList.add(oppRecord.Lead_ID__c);
        }
        //update the task and set the next task to pending
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(OppLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    } 

    // update the contract signature partner task when the contract is signed and the oppStage is set to closed.
    public void updateSalesAgreementPartnerTask(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        String partnerTaskLeadIdSubString;
        String partnerTaskLeadIdString;
        String partnerTaskUniqueIdSubString;
        Partner_Task__c partnerTask;
        List<Partner_Task__c> parentPartnerTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> OppLeadIdList = new List<String>();
        Map<String, Partner_Task__c> tempTaskMapLeadId15String = new Map<String, Partner_Task__c>();

        // filter out the child-tasks from the task map
        for (Partner_Task__c partnerTaskLoopRecord : taskMap.values()) {
            if(partnerTaskLoopRecord.Parent__c == true && partnerTaskLoopRecord.Lead__c != null) {
                parentPartnerTaskList.add(partnerTaskLoopRecord);
            }
        }

        //create a new map that sets the 15 digit ID to the keyValue
        for (Partner_Task__c partnerTaskLoopRecord : parentPartnerTaskList) {
            partnerTaskLeadIdString = String.valueOf(partnerTaskLoopRecord.Lead__r.Id);
            partnerTaskLeadIdSubString = partnerTaskLeadIdString.subString(0,15);
            partnerTaskUniqueIdSubString = partnerTaskLeadIdSubString + ' ' + partnerTaskLoopRecord.Name;
            partnerTask = taskMap.get(partnerTaskLoopRecord.Unique_ID__c);
            tempTaskMapLeadId15String.put(partnerTaskUniqueIdSubString, partnerTask);
        }

        //locate the task and set it to complete
        for (Opportunity oppRecord : oppList){
            System.debug('The taskMap is ' + tempTaskMapLeadId15String);
            taskUniqueId = oppRecord.Lead_ID__c + ' ' + 'Provide Sales Agreement';
            tempTaskMapLeadId15String.get(taskUniqueId).Status__c = 'Complete';
            tempTaskMapLeadId15String.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(tempTaskMapLeadId15String.get(taskUniqueId));
            OppLeadIdList.add(oppRecord.Lead_ID__c);
        }
        //update the task and set the next task to pending
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(OppLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }

    // update the contract signature partner task when the contract is signed and the oppStage is set to closed.
    public void updatePartnerTaskBlueWaveCounterSignature(List<Opportunity> oppList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        String partnerTaskLeadIdSubString;
        String partnerTaskLeadIdString;
        String partnerTaskUniqueIdSubString;
        Partner_Task__c partnerTask;
        List<Partner_Task__c> parentPartnerTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> OppLeadIdList = new List<String>();
        Map<String, Partner_Task__c> tempTaskMapLeadId15String = new Map<String, Partner_Task__c>();

        // filter out the child-tasks from the task map
        for (Partner_Task__c partnerTaskLoopRecord : taskMap.values()) {
            if(partnerTaskLoopRecord.Parent__c == true && partnerTaskLoopRecord.Lead__c != null) {
                parentPartnerTaskList.add(partnerTaskLoopRecord);
            }
        }

        //create a new map that sets the 15 digit ID to the keyValue
        for (Partner_Task__c partnerTaskLoopRecord : parentPartnerTaskList) {
            partnerTaskLeadIdString = String.valueOf(partnerTaskLoopRecord.Lead__r.Id);
            partnerTaskLeadIdSubString = partnerTaskLeadIdString.subString(0,15);
            partnerTaskUniqueIdSubString = partnerTaskLeadIdSubString + ' ' + partnerTaskLoopRecord.Name;
            partnerTask = taskMap.get(partnerTaskLoopRecord.Unique_ID__c);
            tempTaskMapLeadId15String.put(partnerTaskUniqueIdSubString, partnerTask);
        }

        //locate the task and set it to complete
        for (Opportunity oppRecord : oppList){
            taskUniqueId = oppRecord.Lead_ID__c + ' ' + 'BlueWave Counter Signature';
            tempTaskMapLeadId15String.get(taskUniqueId).Status__c = 'Complete';
            tempTaskMapLeadId15String.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(tempTaskMapLeadId15String.get(taskUniqueId));
            OppLeadIdList.add(oppRecord.Lead_ID__c);
        }
        //update the task and set the next task to pending
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(OppLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }     

    //update the mechanical install partner task when the equipment is reported as mechanically installed.
    public void updatePartnerTaskMechanicalInstallation(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();

        for (Residential_Equipment__c equipmentLoopVar : equipmentList){
            if(!equipmentLoopVar.DOER_Solar_Loan__c) {
                taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Mechanical Installation';
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                taskUpdateList.add(taskMap.get(taskUniqueId));
                equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
            }
        }                    
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;                    
    }      

    // updat the interconnection partner task when the equipment is reported as interconnected
    public void updatePartnerTaskInterconnection(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap){
        String taskUniqueId;
        List<Partner_Task__c> taskUpdateList = new List<Partner_Task__c>();
        List<Partner_Task__c> nextTasksToUpdate = new List<Partner_Task__c>();
        List<String> equipmentLeadIdList = new List<String>();

        for (Residential_Equipment__c equipmentLoopVar : equipmentList){
            taskUniqueId = equipmentLoopVar.Lead__c + ' ' + 'Interconnection';
            taskMap.get(taskUniqueId).Status__c = 'Complete';
            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
            taskUpdateList.add(taskMap.get(taskUniqueId));
            equipmentLeadIdList.add(equipmentLoopVar.Lead__c);
        }
        update taskUpdateList;
        nextTasksToUpdate.addAll(updateNextTaskToPending(equipmentLeadIdList, taskUpdateList));
        update nextTasksToUpdate;
    }                

    public void assignResidentialEquipmentToLoan(List<Loan__c> loanList){
        List<Residential_Equipment__c> equipmentUpdateList =   new List<Residential_Equipment__c>();
        List<String> leadIdList = new List<String>();
        for (Loan__c loan : loanList){
            leadIdList.add(loan.Lead__c);
        }
        List<Residential_Equipment__c> equipmentRecords = [SELECT Id FROM Residential_Equipment__c];
        for (Residential_Equipment__c equipment : [SELECT Id, Lead__c, Lead__r.Id, Loan__c 
                                                   FROM Residential_Equipment__c
                                                   WHERE Lead__c IN : leadIdList]){
            for (Loan__c loanRecord : loanList){
                if(loanRecord.Lead__c == equipment.Lead__c){
                    equipment.Loan__c = loanRecord.Id;
                    equipmentUpdateList.add(equipment);
                }            
            }
        }
        update equipmentUpdateList; 
    }

    public void updateDisbursalRecords (Map<Id, Opportunity> updatedOppMap, Map<Id, Opportunity> oldOppMap){
        String disbursalMethodContract;
        String disbursalMethodMechInstall;
        String disbursalMethodInterconnect;
        List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
        for (Loan__c loan : [SELECT Id, Opportunity__r.Id, (SELECT Id, Name, Status__c, Disbursal_Method__c, Date_of_Disbursal__c, Reason_For_Hold__c FROM Disbursals__r) 
                             FROM Loan__c
                             WHERE Opportunity__r.Id IN : updatedOppMap.KeySet()]) {
            if (!loan.Disbursals__r.isEmpty()) {
                for (Disbursal__c disbursal : loan.Disbursals__r) {
                    if (updatedOppMap.get(loan.Opportunity__r.Id).DOER_Solar_Loan__c) {
                        if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Contract__c == 'ACH Disbursal') {
                            disbursalMethodContract = 'ACH';
                        } else if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Contract__c == 'Check Disbursal') {
                            disbursalMethodContract = 'Check';
                        } else {
                            disbursalMethodContract = null;
                        }
                        if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Interconnect__c == 'ACH Disbursal') {
                            disbursalMethodInterconnect = 'ACH';
                        } else if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Interconnect__c == 'Check Disbursal') {
                            disbursalMethodInterconnect = 'Check';
                        } else {
                            disbursalMethodInterconnect = null;
                        }    
                    } else {
                        disbursalMethodContract = 'ACH';
                        disbursalMethodMechInstall = 'ACH';
                        disbursalMethodInterconnect = 'ACH';
                    }                           
                    if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_1_Contract_Signature_Checkbox__c != oldOppMap.get(loan.Opportunity__r.Id).Disbursal_1_Contract_Signature_Checkbox__c || 
                        updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Contract__c != oldOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Contract__c) {
                        if (disbursal.Name.Contains('Contract Signature')) {
                            disbursal.Status__c = 'Complete';      
                            disbursal.Disbursal_Method__c = disbursalMethodContract;
                            disbursal.Date_of_Disbursal__c = updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_1_Contract_Signature_Checkbox__c;
                            disbursalsToUpdate.add(disbursal);  
                        }
                    }
                    if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_3_Full_Install_Checkbox__c != oldOppMap.get(loan.Opportunity__r.Id).Disbursal_3_Full_Install_Checkbox__c || 
                        updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Interconnect__c != oldOppMap.get(loan.Opportunity__r.Id).Disbursal_Type_Interconnect__c) {
                        if (disbursal.Name.Contains('Interconnection')) {
                            disbursal.Status__c = 'Complete';
                            disbursal.Disbursal_Method__c = disbursalMethodInterconnect;
                            disbursal.Date_of_Disbursal__c = updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_3_Full_Install_Checkbox__c;
                            disbursalsToUpdate.add(disbursal);  
                        }
                    }                           
                    if (updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_2_Mechanical_Install_Checkbox__c != oldOppMap.get(loan.Opportunity__r.Id).Disbursal_2_Mechanical_Install_Checkbox__c) {
                        if (disbursal.Name.Contains('Mechanical Installation')) {
                            disbursal.Status__c = 'Complete';
                            disbursal.Date_of_Disbursal__c = updatedOppMap.get(loan.Opportunity__r.Id).Disbursal_2_Mechanical_Install_Checkbox__c; 
                            disbursal.Disbursal_Method__c = disbursalMethodMechInstall;   
                            disbursalsToUpdate.add(disbursal);                      
                        }
                    }                               
                }
            }
        }
        update disbursalsToUpdate;
    }

    // Called from before insert and before update from Loan Trigger
    // Tested by MapLateCategoryTest
    public void mapLateCategory() {
        Set<String> loanMonths = new Set<String>();
        Set<String> loanYears = new Set<String>();
        Set<String> loanNames = new Set<String>();
 
        for (Loan__c l : (List<Loan__c>) Trigger.new) {
            if (l.name != null) {
                loanNames.add(l.name);
            }
            if (l.monthLT__c != null) {
                loanMonths.add(l.monthLT__c);
            }
            if (l.yearLT__c != null) {
                loanYears.add(l.yearLT__c);
            }
        }
 
        if (loanNames.size() > 0 && loanMonths.size() > 0 && loanYears.size() > 0) {
            Map<String, Loan_Payment__c > loanPayMap = new Map<String, Loan_Payment__c>();
 
            for (Loan_Payment__c loanPayQuery : [SELECT id, name, month__c, year2__c, loan_name__c, late_category__c 
                                                 FROM Loan_Payment__c 
                                                 WHERE loan_name__c IN :loanNames 
                                                 AND month__c IN :loanMonths 
                                                 AND year2__c IN :loanYears]) {
                loanPayMap.put(loanPayQuery.Loan_Name__c,loanPayQuery);
            }
 
            for (Loan__c lf : (List<Loan__c>) Trigger.new) {
                if ((Trigger.isInsert || Trigger.isUpdate || 
                     ((Map<Id, Loan__c>) Trigger.oldMap).get(lf.Id).monthLT__c != lf.monthLT__c)
                    && loanPayMap.containsKey(lf.name)) {
                    lf.late_category__c = loanPayMap.get(lf.name).late_category__c;
                } else {
                    lf.late_category__c = null;
                }
            }
        }
    }
}  


//need to write a method that updates the next tasks for tasks that do not have child records that get completed
// e.g. Submit for BlueWave Review

//Need to make the parentTaskSequenceMap not just have a key value of the sequence number, as there will be multiple
//duplicate key values if more than one lead is updated at once.

//and max out the sequnce number at the last on