public with sharing class LoanHandler{
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
    public void onBeforeLeadUpdate(List<Lead> convertedLeads){
        mapLoanToOpportunity(convertedLeads);
    }

    //On After Update of Lead Record
    public void onAfterLeadUpdate(List<Lead> updatedLeads, List<Lead> oldLeads){
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead newLead : updatedLeads){
            for (Lead oldLead : oldLeads){
                if (newLead.Id == oldLead.Id){
                    if (newLead.Status == 'Qualified' && oldLead.Status != 'Qualified' && newLead.Product_Line__c == 'Residential Loan'){
                        leadsToUpdate.add(newLead);                       
                    }
                }
            }
        }
        if (leadsToUpdate.size() > 0){
            createLoan(leadsToUpdate);
        }    
    }

    //On After Update of Opportunity Record
    public void onAfterOpportunityUpdate(List<Opportunity> updatedOpportunities, List<Opportunity> oldOpportunities){
        List<String> opportunityIds = new List<String>();
        Integer loanTerm;
        Integer interestOnlyPeriod;
        for (Opportunity newOpp : updatedOpportunities){
            for (Opportunity oldOpp : oldOpportunities){
                if (newOpp.Id == oldOpp.Id){
                    if (newOpp.StageName == 'Complete' && oldOpp.StageName != 'Complete' && newOpp.Product_Line__c == 'Residential Loan'){
                        System.debug('newOpp ID is ' + newOpp.Id);
                        opportunityIds.add(newOpp.Id);                       
                    }
                }
            }
        }
        if (opportunityIds.size() > 0){
            List<Loan__c> completedOpportunityLoans = [SELECT Id, Name, Lead__c, Loan_Tranche__c, DOER_Solar_Loann__c, Interest_Ratee__c, Unique_ID__c,
                                                      Sales_Agent__c, Financing_Fee__c, System_Costt__c, Partner__c, State__c, Lead_ID__c, Product__c, Product__r.Loan_Term__c,
                                                      Product__r.Loan_Interest_Only_Period__c
                                                      FROM Loan__c WHERE Opportunity__r.Id IN : opportunityIds];
            //Assign the Loans to their appropriate Tranche
            List<Loan__c> tranchedLoans = new List<Loan__c> (assignLoanTranche(completedOpportunityLoans));
            //Enter the Origination, Commencement and Maturity dates for the loans                 
            for (Loan__c l : tranchedLoans){
                l.Contracted__c = true;
                loanTerm = (Integer)l.Product__r.Loan_Term__c / 12 * 365;
                interestOnlyPeriod = (Integer)l.Product__r.Loan_Interest_Only_Period__c / 12 * 365;
                if(l.DOER_Solar_Loann__c == false){
                    l.Origination_Datee__c = Date.today();
                    l.Commencement_Datee__c = Date.today() + 45;
                    l.Maturity_Datee__c = (Date.today() + 45) + loanTerm;
                }else{
                    l.Origination_Datee__c = Date.today();
                    l.Commencement_Datee__c = Date.today();
                    l.Maturity_Datee__c = Date.today() + interestOnlyPeriod + loanTerm;
                }
            }    
            upsert new list<Loan__c>(tranchedLoans) Unique_ID__c;        
        }    
    }

    public List<Loan__c> assignLoanTranche(List<Loan__c> newLoanList){
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
            for (Loan_Traunch__c trancheRecord : [SELECT Id, Name, State__c, Loan_Data__r.Id, Available_Capital__c FROM Loan_Traunch__c]){
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

    public void createLoan(List<Lead> newLeadList){
        System.debug('LeadList Size is ' + newLeadList.size());
        Loan_Traunch__c tranchePending = [SELECT Id, Name FROM Loan_Traunch__c WHERE Name = 'Tranche Assignment Pending'];
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
    }
    
    private void mapLoanToOpportunity(List<Lead> leadsList){
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

    public void createDisbursalsFromOpportunity(List<Opportunity> updatedOppList, List<Opportunity> oldOppList){
        List<Loan__c> loanList = new List<Loan__c>();    
        List<String> disbursalOppList = new List<String>();
        for (Opportunity updatedOpp : updatedOppList){
            for (Opportunity oldOpp : oldOppList){
                if(updatedOpp.StageName == 'Complete' && oldOpp.StageName != 'Complete' && oldOpp.Product_Line__c == 'Residential Loan'){
                    disbursalOppList.add(updatedOpp.Id);
                }
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
        for (Loan__c loanRecord : [SELECT Id, Name, Opportunity__r.StageName, System_Costt__c, Partner__r.Id, Partner__r.Name, 
                                    Product__r.Disbursal_Terms__c 
                                    FROM Loan__c 
                                    WHERE Id IN : newLoanList]){
            if(loanRecord.Opportunity__r.StageName == 'Complete'){
                if(loanRecord.Product__r.Disbursal_Terms__c == '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection'){
                    System.debug('The partner ID is ' + loanRecord.Partner__r.Id);
                    Disbursal__c disbursal1 = new Disbursal__c(
                        Name = '30% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Unique_ID__c = loanRecord.Id + ' ' + '30% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 1,
                        Disbursal_Percentage__c = 0.3,
                        Partner__c = loanRecord.Partner__r.Id,
                        Status__c = 'Not yet disbursed',
                        Amount__c = LoanRecord.System_Costt__c * 0.30,
                        Type__c = 'Contract Signature',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                    disbursalInsertList.add(disbursal1);
                    Disbursal__c disbursal2 = new Disbursal__c(
                        Name = '60% Mechanical Installation' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Unique_ID__c = loanRecord.Id + ' ' + '60% Mechanical Installation' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 2,
                        Partner__c = loanRecord.Partner__r.Id,
                        Disbursal_Percentage__c = 0.6,
                        Status__c = 'Not yet disbursed',
                        Amount__c = LoanRecord.System_Costt__c * 0.60,
                        Type__c = 'Mechanical Installation',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                     disbursalInsertList.add(disbursal2);
                    Disbursal__c disbursal3 = new Disbursal__c(
                        Name = '10% Interconnection' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Unique_ID__c = loanRecord.Id + ' ' + '10% Interconnection' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 3,
                        Partner__c = loanRecord.Partner__r.Id,
                        Disbursal_Percentage__c = 0.1,
                        Status__c = 'Not yet disbursed',
                        Amount__c = LoanRecord.System_Costt__c * 0.10,
                        Type__c = 'Interconnection',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                     disbursalInsertList.add(disbursal3);
                }
                if(loanRecord.Product__r.Disbursal_Terms__c == '35% Contract Signature, 65% Interconnection'){
                    Disbursal__c disbursal1 = new Disbursal__c(
                        Name = '35% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Unique_ID__c = loanRecord.Id + ' ' + '35% Contract Signature' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 1,
                        Partner__c = loanRecord.Partner__r.Id,
                        Disbursal_Percentage__c = 0.35,
                        Status__c = 'Not yet disbursed',
                        Amount__c = LoanRecord.System_Costt__c * 0.35,
                        Type__c = 'Contract Signature',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                    disbursalInsertList.add(disbursal1);
                    Disbursal__c disbursal2 = new Disbursal__c(
                        Name = '65% Interconnection' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Unique_ID__c = loanRecord.Id + ' ' + '65% Mechanical Installation' + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                        Loan__c = loanRecord.Id,
                        Disbursal_Sequence__c = 2,
                        Partner__c = loanRecord.Partner__r.Id,
                        Disbursal_Percentage__c = 0.65,
                        Status__c = 'Not yet disbursed',
                        Amount__c = LoanRecord.System_Costt__c * 0.65,
                        Type__c = 'Interconnection',
                        Anticipated_Date__c = null,
                        Date_of_Disbursal__c = null);
                     disbursalInsertList.add(disbursal2);                
                }
            }
        }  
        upsert disbursalInsertList Unique_ID__c ;
        //disbursalInsertList.clear();                      
    }

    public void createLoanPartnerTasks(List<Loan__c> newLoanList){
        List<Task> taskInsertList = new List<Task>();
        integer partnerSequenceCounter = 1;
        User u = [SELECT Id FROM User WHERE Name = 'BlueWave Customer Care'];
        for (Loan__c loanRecord : [SELECT Id, Name, System_Costt__c, Partner__r.Id, Partner__r.Name, 
                                   Product__r.Disbursal_Terms__c, Opportunity__r.DOER_Solar_Loan__c, DOER_Solar_Loann__c 
                                   FROM Loan__c 
                                   WHERE Id IN : newLoanList]){
            Task creditTask = new Task(
                OwnerId = u.Id,
                Unique_ID__c = loanRecord.Id + ' ' + 'Run Credit Check',
                Subject = 'Run Credit Check',
                Loan_Partner_Sequence__c = partnerSequenceCounter,
                Status = 'Complete',
                Priority = 'Normal',
                Start_Date__c = Date.today(),
                Loan__c = loanRecord.Id
            );
            taskInsertList.add(creditTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;
            
            Task informationTask = new Task(
                OwnerId = u.Id,
                Unique_ID__c = loanRecord.Id + ' ' + 'Provide All Customer Information',
                Subject = 'Provide All Customer Information',
                Loan_Partner_Sequence__c = partnerSequenceCounter,
                Status = 'New',
                Priority = 'Normal',
                Start_Date__c = Date.today(),
                Loan__c = loanRecord.Id
            );
            taskInsertList.add(informationTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;            
            
            Task bwReviewTask = new Task(
                OwnerId = u.Id,
                Unique_ID__c = loanRecord.Id + ' ' + 'Submit for BlueWave Review',
                Subject = 'Submit for BlueWave Review',
                Loan_Partner_Sequence__c = partnerSequenceCounter,
                Status = 'New',
                Priority = 'Normal',
                Start_Date__c = Date.today(),
                Loan__c = loanRecord.Id
            );
            taskInsertList.add(bwReviewTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;  
            
            Task contractSignatureTask = new Task(
                OwnerId = u.Id,
                Unique_ID__c = loanRecord.Id + ' ' + 'Obtain Contract Signature',
                Subject = 'Obtain Contract Signature',
                Loan_Partner_Sequence__c = partnerSequenceCounter,
                Status = 'New',
                Priority = 'Normal',
                Start_Date__c = Date.today(),
                Loan__c = loanRecord.Id
            );
            taskInsertList.add(contractSignatureTask);
            partnerSequenceCounter = partnerSequenceCounter + 1;

            if (loanRecord.DOER_Solar_Loann__c == false){
                Task mechanicalInstallationTask = new Task(
                    OwnerId = u.Id,
                    Unique_ID__c = loanRecord.Id + ' ' + 'Mechanical Installation',
                    Subject = 'Mechanical Installation',
                    Loan_Partner_Sequence__c = partnerSequenceCounter,
                    Status = 'New',
                    Priority = 'Normal',
                    Start_Date__c = Date.today(),
                    Loan__c = loanRecord.Id
                );
                taskInsertList.add(mechanicalInstallationTask);
                partnerSequenceCounter = partnerSequenceCounter + 1;
            }            
            Task interconnectionTask = new Task(
                OwnerId = u.Id,
                Unique_ID__c = loanRecord.Id + ' ' + 'Interconnection',
                Subject = 'Interconnection',
                Loan_Partner_Sequence__c = partnerSequenceCounter,
                Status = 'New',
                Priority = 'Normal',
                Start_Date__c = Date.today(),
                Loan__c = loanRecord.Id
            );
            taskInsertList.add(interconnectionTask);
            partnerSequenceCounter = 1;   
        }
        System.debug('Task Insert list is ' + taskInsertList);
        Upsert taskInsertList Unique_ID__c ;
        //taskInsertList.clear();
    }
}