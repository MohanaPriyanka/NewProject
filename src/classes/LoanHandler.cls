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
        System.debug('The new loans are ' + newLoans);
    }
    
    //On Before Update of Lead Record
    public void onBeforeLeadUpdate(List<Lead> convertedLeads){
        //map the loan, equipment and partner tasks to the opporunity upon conversion
        mapLoanToOpportunity(convertedLeads);
        mapEquipmentToOpportunity(convertedLeads);     
        mapPartnerTasksToOpportunity(convertedLeads);   
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
            validateLoanInformationProvided(leadsToValidatePartnerTasks, getPartnerTasks(leadIds));
        }

        if (leadsToSetBlueWaveReviewToComplete.size() > 0){
            updatePartnerTaskUnderBlueWaveReview(leadsToSetBlueWaveReviewToComplete, getPartnerTasks(leadIds));
        }
    }

    //On After Update of Opportunity Record
    public void onAfterOpportunityUpdate(List<Opportunity> updatedOpportunities, List<Opportunity> oldOpportunities){
        List<String> opportunityIds = new List<String>();
        List<String> oppleadIds = new List<String>();

        Integer loanTerm;
        Integer interestOnlyPeriod;
        for (Opportunity newOpp : updatedOpportunities){
            for (Opportunity oldOpp : oldOpportunities){
                if (newOpp.Id == oldOpp.Id){
                    if (newOpp.StageName == 'Complete' 
                        && oldOpp.StageName != 'Complete' 
                        && !newOpp.Submitted_to_First_Associates__c
                        && newOpp.Product_Line__c == 'Residential Loan'){
                        System.debug('newOpp ID is ' + newOpp.Id);
                        opportunityIds.add(newOpp.Id);                       
                    }
                }
            }
        }
        if (opportunityIds.size() > 0){
            List<Loan__c> completedOpportunityLoans = [SELECT Id, Name, Lead__c, Loan_Tranche__c, DOER_Solar_Loann__c, 
                                                        Interest_Ratee__c, Unique_ID__c, Sales_Agent__c, Financing_Fee__c, 
                                                        System_Costt__c, Partner__c, State__c, Lead_ID__c, Product__c, 
                                                        Product__r.Loan_Term__c, Product__r.Loan_Interest_Only_Period__c
                                                      FROM Loan__c 
                                                      WHERE Opportunity__r.Id IN : opportunityIds];
            //Assign the Loans to their appropriate Tranche
            List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(completedOpportunityLoans));
            //Enter the Origination, Commencement and Maturity dates for the loans                 
            for (Loan__c l : tranchedLoans){
                l.Contracted__c = true;
                loanTerm = (Integer)l.Product__r.Loan_Term__c / 12 * 365;
                interestOnlyPeriod = (Integer)l.Product__r.Loan_Interest_Only_Period__c / 12 * 365;
                if(l.DOER_Solar_Loann__c == false){
                    //l.Origination_Datee__c = Date.today();
                    //l.Commencement_Datee__c = Date.today() + 45;
                    //l.Maturity_Datee__c = (Date.today() + 45) + loanTerm;
                }else{
                    //l.Origination_Datee__c = Date.today();
                    //l.Commencement_Datee__c = Date.today();
                    //l.Maturity_Datee__c = Date.today() + interestOnlyPeriod + loanTerm;
                }
            }    
            upsert new list<Loan__c>(tranchedLoans) Unique_ID__c;

            for (Opportunity oppRecord : updatedOpportunities) {
                oppLeadIds.add(oppRecord.Lead_ID__c);
            }
            
            List<Partner_Task__c> partnerTaskList = checkForPartnerTasksOnOpportunity(updatedOpportunities);
            if (partnerTaskList.size() > 0) {
                    //Set the partner task - Obtain Contract Signature to Complete when the Stage is completed.
                    updatePartnerTaskObtainContractSignature(updatedOpportunities, getPartnerTasks(oppLeadIds));       
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
        System.debug('Being createResidentialEquipment method');
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
        //System.debug('The tranchedLoans before update are ' + tranchedLoans);  
        insert newEquipmentList;
    }

    public void createLoan(List<Lead> newLeadList){
        System.debug('Being createLoan method');
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
        //System.debug('The tranchedLoans before update are ' + tranchedLoans);  
        upsert new list<Loan__c>(newLoanList) Unique_ID__c;
        assignResidentialEquipmentToLoan(newLoanList);
    }
    
    public void mapLoanToOpportunity(List<Lead> leadsList){
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead L : leadsList){
             if (l.isConverted && l.Product_Line__c == 'Residential Loan'){
                      feedback2OppId.put(l.Id, l.convertedOpportunityId);
                      opportunityMap.put(l.convertedOpportunityId,l.convertedOpportunityId);
            }
        }

        if(opportunityMap.size() > 0){
                 List<Loan__c> loan = [SELECT Lead__c, Opportunity__c 
                                       FROM Loan__c 
                                       WHERE Lead__c IN :feedback2OppId.keySet()];
                for (Loan__c l : loan){
                    l.Opportunity__c = feedback2OppId.get(l.Lead__c);
                }            
                update loan;
        }
    }  

    public void mapEquipmentToOpportunity(List<Lead> leadsList){
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead L : leadsList){
             if (l.isConverted && l.Product_Line__c == 'Residential Loan'){
                      feedback2OppId.put(l.Id, l.convertedOpportunityId);
                      opportunityMap.put(l.convertedOpportunityId,l.convertedOpportunityId);
            }
        }

        if(opportunityMap.size() > 0){
                 List<Residential_Equipment__c > equipment = [SELECT Lead__c, Opportunity__c 
                                                               FROM Residential_Equipment__c 
                                                               WHERE Lead__c IN :feedback2OppId.keySet()];
                for (Residential_Equipment__c equipmentRecord : equipment){
                    equipmentRecord.Opportunity__c = feedback2OppId.get(equipmentRecord.Lead__c);
                }            
                update equipment;
        }
    }  

    public void mapPartnerTasksToOpportunity(List<Lead> leadsList){
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> opportunityMap = new Map<Id, Id>();

        for(Lead L : leadsList){
             if (l.isConverted && l.Product_Line__c == 'Residential Loan'){
                      feedback2OppId.put(l.Id, l.convertedOpportunityId);
                      opportunityMap.put(l.convertedOpportunityId,l.convertedOpportunityId);
            }
        }

        if(opportunityMap.size() > 0){
                 List<Partner_Task__c > partnerTasks = [SELECT Lead__c, Opportunity__c 
                                                       FROM Partner_Task__c 
                                                       WHERE Lead__c IN :feedback2OppId.keySet()];
                for (Partner_Task__c task : partnerTasks){
                    task.Opportunity__c = feedback2OppId.get(task.Lead__c);
                }            
                update partnerTasks;
        }
    }                 

    public List<Loan__c> assignLoanTranche(List<Loan__c> newLoanList){
        System.debug('Begin assignLoanTranche method');
        System.debug('The NewLoanList is ' + newLoanList);
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
                    //    System.debug('There is not enough capital available in the tranches');
                    //    //trancheRecord.addError('There is not enough capital available in the tranches' , false);
                    //    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,''+'There is not enough capital available in the tranches' ));
                    //}
                    if(trancheRecord.State__c == loanRecord.State__c && 
                        trancheRecord.Loan_Data__r.Id == loanProductMap.get(loanRecord.Id).Loan_Capital_Pool__r.Id &&                        
                        trancheRecord.Tranche_Type__c == loanProductMap.get(loanRecord.Id).Loan_Tranche_type__c){   
                        System.debug('The TrancheRecord Available Capital is ' + trancheRecord.Available_Capital__c);
                        System.debug('The loanRecord System Cost is ' + loanRecord.System_Costt__c);                        
                        if(trancheRecord.Available_Capital__c >= loanRecord.System_Costt__c){
                            loanRecord.Loan_Tranche__c = trancheRecord.Id;
                            tranchedLoans.add(loanRecord);
                            System.debug(loanRecord.Name + ' ' + 'has been assigned to ' + trancheRecord.Name);
                        }else{
                            loanRecord.Loan_Tranche__c = temporaryHoldingTranche.Id;
                            tranchedLoans.add(loanRecord);
                            System.debug(LoanRecord.Name + ' ' + 'has been assigned to ' + temporaryHoldingTranche.Id);
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
                && oldOppMap.get(oppRecord.Id).StageName != ' Complete'
                && newOppMap.get(oppRecord.Id).Product_Line__c == 'Residential Loan'
                && !newOppMap.get(oppRecord.Id).Submitted_to_First_Associates__c) {
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
                                    Product__r.Disbursal_Terms__c, Opportunity__r.Loan_Principle__c 
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
                        Disbursal_Percentage__c = 0.35,
                        Status__c = 'Not yet disbursed',
                        Amount__c = systemCost * 0.35,
                        Type__c = 'Contract Signature',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);

                    disbursalInsertList.add(disbursal1);
                    disbursalName = '65% Mechanical Installation' + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name;
                    if(disbursalName.length() >= 80) {
                    disbursalName = disbursalName.subString(0,80);
                    }                                                             
                    Disbursal__c disbursal2 = new Disbursal__c(
                        Name = disbursalName,
                        Unique_ID__c = loanRecord.Id + ' ' + '65% Mechanical Installation' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 2,
                        Partner__c = loanRecord.Partner__r.Id,
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
                                   Lead__r.System_Cost__c, Lead__r.Retired__c, Lead__r.Self_Employed__c, Lead__r.Application_Type__c 
                                   FROM Loan__c 
                                   WHERE Id IN : newLoanList]){
            Partner_Task__c creditTask = new Partner_Task__c(
                Name = 'Run Credit Check',
                RecordType = parentPartnerTaskRecordType,
                Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Run Credit Check',                
                Partner__c = loanRecord.Partner__r.Id,
                Parent__c = true,
                Task_Sequence__c = partnerSequenceCounter,
                Status__c = 'Complete',
                Start_Date__c = Date.today(),
                Completion_Date__c = Date.today(),
                Task_Type__c = 'Credit Check',
                Loan__c = loanRecord.Id
            );
            parentTaskInsertList.add(creditTask);
            parentTaskTypeMapUniqueId = creditTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, creditTask);
            partnerSequenceCounter = partnerSequenceCounter + 1; 
            
            Partner_Task__c allInformationTask = new Partner_Task__c(
                Name = 'Provide All Customer Information',
                RecordType = parentPartnerTaskRecordType,
                Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Provide All Customer Information',              
                Partner__c = loanRecord.Partner__r.Id,
                Task_Sequence__c = partnerSequenceCounter,
                Status__c = 'Pending',
                Start_Date__c = Date.today(),
                Task_Type__c = 'Customer Information',
                Parent__c = true,
                SubTasks__c = true,
                Loan__c = loanRecord.Id
            );
            parentTaskInsertList.add(allInformationTask);
            parentTaskTypeMapUniqueId = allInformationTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, allInformationTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;                         
            
            Partner_Task__c bwReviewTask = new Partner_Task__c(
                Name = 'Under BlueWave Review',
                RecordType = parentPartnerTaskRecordType,
                Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Under BlueWave Review',          
                Partner__c = loanRecord.Partner__r.Id,
                Task_Sequence__c = partnerSequenceCounter,
                Status__c = 'Incomplete',
                Start_Date__c = Date.today(),
                Task_Type__c = 'Under BlueWave Review',
                Parent__c = true,
                Loan__c = loanRecord.Id
            );
            parentTaskInsertList.add(bwReviewTask);
            parentTaskTypeMapUniqueId = bwReviewTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, bwReviewTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;            

            Partner_Task__c contractSignatureTask = new Partner_Task__c(
                Name = 'Obtain Contract Signature',
                RecordType = parentPartnerTaskRecordType,
                Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Obtain Contract Signature',          
                Partner__c = loanRecord.Partner__r.Id,
                Task_Sequence__c = partnerSequenceCounter,
                Status__c = 'Incomplete',
                Start_Date__c = Date.today(),
                Task_Type__c = 'Contract',
                Parent__c = true,
                Loan__c = loanRecord.Id
            );
            parentTaskInsertList.add(contractSignatureTask);
            parentTaskTypeMapUniqueId = contractSignatureTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, contractSignatureTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;  

            if (loanRecord.DOER_Solar_Loann__c == false){
                Partner_Task__c mechanicalInstallationTask = new Partner_Task__c(
                    Name = 'Mechanical Installation',
                    RecordType = parentPartnerTaskRecordType,
                    Lead__c = loanRecord.Lead__r.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Mechanical Installation',          
                    Partner__c = loanRecord.Partner__r.Id,
                    Task_Sequence__c = partnerSequenceCounter,
                    Parent__c = true,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Task_Type__c = 'Mechanical Installation',
                    Loan__c = loanRecord.Id
                );
                parentTaskInsertList.add(mechanicalInstallationTask);
                parentTaskTypeMapUniqueId = mechanicalInstallationTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
                parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, mechanicalInstallationTask);                
                partnerSequenceCounter = partnerSequenceCounter + 1;                     

                Partner_Task__c interconnectionTask = new Partner_Task__c(
                    Name = 'Interconnection',
                    RecordType = parentPartnerTaskRecordType,
                    Lead__c = loanRecord.Lead__r.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Interconnection',        
                    Partner__c = loanRecord.Partner__r.Id,
                    Parent__c = true,
                    Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Task_Type__c = 'Interconnection',
                    Loan__c = loanRecord.Id
                );
                parentTaskInsertList.add(interconnectionTask);
                parentTaskTypeMapUniqueId = interconnectionTask.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
                parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, interconnectionTask);            
                partnerSequenceCounter = partnerSequenceCounter + 1;                           
            }
            if (loanRecord.DOER_Solar_Loann__c == true){
                Partner_Task__c interconnectionTaskMSLP = new Partner_Task__c(
                    Name = 'Report Interconnection to MCEC',
                    RecordType = parentPartnerTaskRecordType,
                    Lead__c = loanRecord.Lead__r.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Interconnection',        
                    Partner__c = loanRecord.Partner__r.Id,
                    Parent__c = true,
                    Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Task_Type__c = 'Interconnection MSLP',
                    Loan__c = loanRecord.Id
                );
                parentTaskInsertList.add(interconnectionTaskMSLP);
                parentTaskTypeMapUniqueId = interconnectionTaskMSLP.Task_Type__c + ' ' + loanRecord.Lead__r.Id;
                parentTaskAssignmentMap.put(parentTaskTypeMapUniqueId, interconnectionTaskMSLP);            
                partnerSequenceCounter = partnerSequenceCounter + 1;                                                                         
            }

            Partner_Task__c incomeDocumentationTask = new Partner_Task__c(
                Name = 'Provide Income Documentation',
                RecordType = childPartnerTaskRecordType,
                //Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Income Documentation',              
                Partner__c = loanRecord.Partner__r.Id,
                Status__c = 'Incomplete',
                Start_Date__c = Date.today(),
                Sub_Task_Type__c = 'Income Documentation',
                Task_Type__c = 'Customer Information',
                Parent__c = true,
                SubTasks__c = true,
                Parent_Task__c = allInformationTask.Id,
                Loan__c = loanRecord.Id
            );
            subParentTaskInsertList.add(incomeDocumentationTask);
            subTaskTypeMapUniqueId = incomeDocumentationTask.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;
            subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, incomeDocumentationTask);
            
            if (loanRecord.DOER_Solar_Loann__c == false){ 
                Partner_Task__c systemInformationTask = new Partner_Task__c(
                    Name = 'Provide all System Information',
                    RecordType = childPartnerTaskRecordType,
                    //Lead__c = loanRecord.Lead__r.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Provide all System Information',                
                    Partner__c = loanRecord.Partner__r.Id,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'System Information',
                    Task_Type__c = 'Customer Information',
                    Parent__c = true,
                    Parent_Task__c = allInformationTask.Id,
                    Loan__c = loanRecord.Id
                );            
                subParentTaskInsertList.add(systemInformationTask);
                subTaskTypeMapUniqueId = systemInformationTask.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;            
                subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, systemInformationTask);
            }
            if (loanRecord.DOER_Solar_Loann__c == true){
                Partner_Task__c technicalApprovalTask = new Partner_Task__c(
                    Name = 'Provide Technical Confirmation Documentation',
                    //Lead__c = loanRecord.Lead__r.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Technical Approval Confirmation',                
                    Partner__c = loanRecord.Partner__r.Id,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Technical Approval',
                    Task_Type__c = 'Customer Information',
                    //Parent__c = true,
                    Parent_Task__c = allInformationTask.Id,
                    Loan__c = loanRecord.Id
                );                
                subParentTaskInsertList.add(technicalApprovalTask);
                subTaskTypeMapUniqueId = technicalApprovalTask.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;            
                subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, technicalApprovalTask);
            }

            Partner_Task__c salesAgreementTask = new Partner_Task__c(
                Name = 'Provide Sales Agreement',
                RecordType = childPartnerTaskRecordType,
                //Lead__c = loanRecord.Lead__r.Id,
                Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Sales Agreement',             
                Partner__c = loanRecord.Partner__r.Id,
                Status__c = 'Incomplete',
                Start_Date__c = Date.today(),
                Sub_Task_Type__c = 'Sales Agreement',
                Task_Type__c = 'Customer Information',
                Parent__c = true,
                Parent_Task__c = allInformationTask.Id,
                Loan__c = loanRecord.Id
            );
            subParentTaskInsertList.add(salesAgreementTask);
            subTaskTypeMapUniqueId = salesAgreementTask.Sub_Task_Type__c + ' ' + loanRecord.Lead__r.Id;            
            subParentTaskAssignmentMap.put(subTaskTypeMapUniqueId, salesAgreementTask); 
            if(loanRecord.Lead__r.Self_Employed__c == false && loanRecord.lead__r.Retired__c == false){
                Partner_Task__c payStubDocumentationTask = new Partner_Task__c(
                    Name = 'Provide PayStub Documentation',
                    RecordType = childPartnerTaskRecordType,
                    Parent_Task__c = incomeDocumentationTask.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'PayStub Documentation',              
                    Partner__c = loanRecord.Partner__r.Id,
                    //Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Income Documentation',
                    Task_Type__c = 'Customer Information' 
                    //Loan__c = loanRecord.Id
                );
                subTaskInsertList.add(payStubDocumentationTask);
            }        
            if(loanRecord.Lead__r.Self_Employed__c == true && loanRecord.lead__r.Retired__c == false){
                Partner_Task__c selfEmploymentTaxReturnPreviousYearTask = new Partner_Task__c(
                    Name = 'Provide Tax Return (Previous Year)',
                RecordType = childPartnerTaskRecordType,
                    Parent_Task__c = incomeDocumentationTask.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Tax Return (Previous Year)',              
                    Partner__c = loanRecord.Partner__r.Id,
                    //Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Income Documentation',
                    Task_Type__c = 'Customer Information'
                    //Loan__c = loanRecord.Id
                );
                subTaskInsertList.add(selfEmploymentTaxReturnPreviousYearTask);

                Partner_Task__c selfEmploymentTaxReturnTwoYearsPreviousTask = new Partner_Task__c(
                    Name = 'Provide Tax Return (Two Years Previous)',
                    RecordType = childPartnerTaskRecordType,
                    Parent_Task__c = incomeDocumentationTask.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'Tax Return (Two Years Previous)',              
                    Partner__c = loanRecord.Partner__r.Id,
                    //Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Income Documentation',
                    Task_Type__c = 'Customer Information'
                    //Loan__c = loanRecord.Id
                );
                subTaskInsertList.add(selfEmploymentTaxReturnTwoYearsPreviousTask);                           

            }else if(loanRecord.Lead__r.Self_Employed__c == false && loanRecord.lead__r.Retired__c == true){
                
                Partner_Task__c retirementIncomeDocumentationTask = new Partner_Task__c(
                    Name = 'Provide SSN/Pension Award Letter or Bank Statement',
                    RecordType = childPartnerTaskRecordType,
                    Parent_Task__c = incomeDocumentationTask.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'SSN/Pension Award Letter or Bank Statement',              
                    Partner__c = loanRecord.Partner__r.Id,
                    //Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Income Documentation',
                    Task_Type__c = 'Customer Information'
                    //Loan__c = loanRecord.Id
                );
                subTaskInsertList.add(retirementIncomeDocumentationTask);

            }else if(loanRecord.Lead__r.Self_Employed__c == true && loanRecord.lead__r.Retired__c == true){
                
                Partner_Task__c allIncomeDocumentationTask = new Partner_Task__c(
                    Name = 'Provide All Income Documentation',
                    RecordType = childPartnerTaskRecordType,
                    Parent_Task__c = incomeDocumentationTask.Id,
                    Unique_ID__c = loanRecord.Lead__r.Id + ' ' + 'All Income Documentation',              
                    Partner__c = loanRecord.Partner__r.Id,
                    //Task_Sequence__c = partnerSequenceCounter,
                    Status__c = 'Incomplete',
                    Start_Date__c = Date.today(),
                    Sub_Task_Type__c = 'Income Documentation',
                    Task_Type__c = 'Customer Information'
                    //Loan__c = loanRecord.Id
                );
                subTaskInsertList.add(allIncomeDocumentationTask);
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
        validateLoanInformationProvided(leadList, taskMap);   // add conditional customer type as a parameter to run income check on retirees, etc. 
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

    public void validateLoanInformationProvided(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        System.debug('Begin validateLoanInformationProvided method');
        List<Partner_Task__c> validatedTaskList = new List<Partner_Task__c>();

        List<Partner_Task__c> incomeTaskList = new List<Partner_Task__c>(checkLoanIncomeFiles(leadList, taskMap));
        validatedTaskList.addAll(incomeTaskList);

        List<Partner_Task__c> salesAgreementTaskList = new List<Partner_Task__c>(checkSalesAgreementFiles(leadList, taskMap));
        validatedTaskList.addAll(salesAgreementTaskList);        

        List<Partner_Task__c> systemInfoTaskList = new List<Partner_Task__c>(checkSystemInformation(leadList, taskMap));
        validatedTaskList.addAll(systemInfoTaskList);
        
        List<Partner_Task__c> technicalApprovalTaskList = new List<Partner_Task__c>(checkTechnicalConfirmationFiles(leadList, taskMap));
        validatedTaskList.addAll(technicalApprovalTaskList);        

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
        System.debug('Begin checkLoanIncomeFiles Method');
        //System.debug('the taskMap is ' + taskMap);
        String taskUniqueId;
        String customerIncomeType;
        System.debug('The TaskMap is ' + taskMap);
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
                        if(incomeAttachment.Description.contains('PayStub')){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'PayStub Documentation';
                            taskMap.get(taskUniqueId).Status__c = 'Complete';
                            taskMap.get(taskUniqueId).Completion_Date__c = Date.today();  
                            completedTaskList.add(taskMap.get(taskUniqueId));                           
                        }
                    }else if(customerIncomeTypeMap.get(customerIncomeLeadId) == 'selfEmployed'){
                        if(incomeAttachment.Description.contains('Tax Return (Previous Year)')){
                            taskUniqueId = incomeAttachment.ParentId + ' ' + 'Tax Return (Previous Year)';
                            System.debug('The Task Unique_ID__c is ' + taskUniqueId);                            
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

    public List<Partner_Task__c> checkSalesAgreementFiles(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        System.debug('Begin checkSalesAgreementFile Method');
        String taskUniqueId;
        List<Id> leadIdList = new List<Id>();
        List<Partner_Task__c> completedTaskList = new List<Partner_Task__c>();
        List<Partner_Task__c> incompleteTaskList = new List<Partner_Task__c>(taskMap.values());

        for (Lead leadRecord : leadList){
            leadIdList.add(leadRecord.Id);                      
        }

        for (Attachment salesAgreementAttachment: [SELECT Id, Name, Body, ParentId, Description
                                                    FROM Attachment
                                                    WHERE Description != null             
                                                    AND ParentId IN : leadIdList]){
            if(salesAgreementAttachment.Description.contains('Sales Agreement')){
                taskUniqueId = salesAgreementAttachment.ParentId + ' ' + 'Sales Agreement';
                taskMap.get(taskUniqueId).Status__c = 'Complete';
                taskMap.get(taskUniqueId).Completion_Date__c = Date.today();
                completedTaskList.add(taskMap.get(taskUniqueId));
            }
        }
        System.debug('The Compeleted Task List is ' + completedTaskList);
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
        System.debug('Begin checkTechnicalConfirmationFiles Method');
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
        System.debug('The Compeleted Task List is ' + completedTaskList);
        if(completedTaskList.size()>0){
            return completedTaskList;
        }else{
            return incompleteTaskList;
        }  
    }               


    //If all Partner Sub-Tasks are set to complete, set the parent Partner task to complete.
    public void updatePartnerParentTaskStatus(Map<String, Partner_Task__c> taskMap){
        System.debug('Begin updatePartnerParentTaskStatus method');
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
                    System.debug('parentTask name ' + parentTask.Name);
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

    public  List<Partner_Task__c> updateNextTaskToPending(List<String> leadIdList, List<Partner_Task__c> completedTasks){
        System.debug('Begin the updateNextTaskToPending method');
        String taskSequenceKey; //key value
        String taskSequenceUniqueId; //accessor value
        Decimal nextTask;
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
        update leadMap.values();
        return tasksToUpdate;    
    }

    // update the under BW review partner task when the lead gets converted to an opportunity
    public void updatePartnerTaskUnderBlueWaveReview(List<Lead> leadList, Map<String, Partner_Task__c> taskMap){
        System.debug('Begin updatePartnerTaskUnderBlueWaveReview');
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
        System.debug('Begin updatePartnerTaskObtainContractSignature method');
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

    //update the mechanical install partner task when the equipment is reported as mechanically installed.
    public void updatePartnerTaskMechanicalInstallation(List<Residential_Equipment__c> equipmentList, Map<String, Partner_Task__c> taskMap){
        System.debug('Begin updatePartnerTaskMechanicalInstallation');
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
        System.debug('Begin updatePartnerTaskInterconnection');
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
        System.debug('Begin assignResidentialEquipmentToLoan method');
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
}  


//need to write a method that updates the next tasks for tasks that do not have child records that get completed
// e.g. Submit for BlueWave Review

//Need to make the parentTaskSequenceMap not just have a key value of the sequence number, as there will be multiple
//duplicate key values if more than one lead is updated at once.

//and max out the sequnce number at the last one