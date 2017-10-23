/*************************************************************************************
 * Created By:  Cole Swain
 * Description: This is the handler for the Disbursal object.
 * Test: DisbursalHandlerTest
 *************************************************************************************/
public class DisbursalHandler {

    public class DisbursalStructure {      
        public Integer disbursalCount;
        public List<String> percentageList;
        public List<String> nameList;
        public List<String> typeList;

        public DisbursalStructure() {
            disbursalCount = 0;             
            percentageList = new List<String>();
            nameList = new List<String>();     
            typeList = new List<String>();                                
        }       
    }   

    public void createDisbursalsFromOpportunity(Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Loan__c> loanList = new List<Loan__c>();
        List<String> opportunityIdList = new List<String>();
        List<Disbursal__c> disbursalsToInsert = new List<Disbursal__c>();

        for (Opportunity oppRecord : newMap.values()) {
            if (opportunityStageChangesToComplete(oppRecord, newMap, oldMap)) {
                opportunityIdList.add(newMap.get(oppRecord.Id).Id);
            }
        }
        if (!opportunityIdList.isEmpty()) {
            for(Opportunity opp : [SELECT Id, Name,
                                     (SELECT Id, Name, Opportunity__r.StageName, Requested_Loan_Amount__c, Partner__r.Id, Partner__r.Name,
                                        Product__r.Disbursal_Terms__c, Opportunity__r.Requested_Loan_Amount__c, Sales_Agent__r.Id 
                                      FROM Loans__r)
                                    FROM Opportunity
                                    WHERE Id IN : opportunityIdList]) {
                loanList.add(opp.Loans__r);
            }
            for (Loan__c loanRecord : loanList) {
                DisbursalStructure disbursalStrucutre = getDisbursalStructure(loanRecord);
                disbursalsToInsert = createDisbursals(disbursalStrucutre, loanRecord);
            }
            upsert disbursalsToInsert Unique_ID__c;
        }
    }

    public DisbursalStructure getDisbursalStructure (Loan__c loanRecord) {
        DisbursalStructure disbursalStructure = new DisbursalStructure();
        String disbursalTerms = loanRecord.Product__r.Disbursal_Terms__c;
        List<String> disbursalSubStrings = disbursalTerms.split(',');
        disbursalStructure.disbursalCount = 0;
        for (String subString : disbursalSubStrings) {
            disbursalStructure.disbursalCount = disbursalStructure.disbursalCount + 1;
            List<String> rate = subString.split('%');
            disbursalStructure.percentageList.add(rate.get(0)); 
            String disbursalName = subString;
            if (disbursalName.length() >= 80) {
                disbursalName = disbursalName.subString(0,80);
            }
            disbursalStructure.typeList.add(rate.get(1));
            disbursalStructure.nameList.add(disbursalName);
        }
        return disbursalStructure;
    }    

    public List<Disbursal__c> createDisbursals (DisbursalStructure disbursalStructure, Loan__c loanRecord) {
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        Integer i;
        for (i=0; i < disbursalStructure.disbursalCount; i++) {
            Decimal rate = Decimal.valueOf(disbursalStructure.percentageList.get(i).remove(' '));
            rate = rate;
            Disbursal__c disbursal = new Disbursal__c(
                Name = disbursalStructure.nameList.get(i)  + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name,
                Unique_ID__c = loanRecord.Id + ' ' + disbursalStructure.nameList.get(i) + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
                Loan__c = loanRecord.Id,
                Disbursal_Sequence__c = i + 1,
                Disbursal_Percentage__c = rate,
                Partner__c = loanRecord.Partner__r.Id,
                Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
                Status__c = 'Not yet disbursed',
                Amount__c = loanRecord.Requested_Loan_Amount__c * rate / 100,
                Type__c = disbursalStructure.typeList.get(i),
                Anticipated_Date__c = null,
                Date_of_Disbursal__c = null
            );
            disbursalList.add(disbursal);
        }
        return disbursalList;
    }    

    public void updateDisbursalAmountsOnRLAChange (Map<Id,Loan__c> newMap, Map<Id, Loan__c> oldMap) {
        List<Id> updatedLoans = new List<Id>();
        List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
        for (Loan__c loanRecord : newMap.Values()) {
            if (newMap.get(loanRecord.Id).Requested_Loan_Amount__c != oldMap.get(loanRecord.Id).Requested_Loan_Amount__c  
                && oldMap.get(loanRecord.Id).Requested_Loan_Amount__c  != null 
                && newMap.get(loanRecord.Id).Requested_Loan_Amount__c  != null) {
                    updatedLoans.add(loanRecord.Id);
            }
        }
        for (Loan__c loanRecord : [SELECT Id, Name, Requested_Loan_Amount__c, Total_Funds_Disbursed__c, Partner__r.Name, Sales_Agent__r.Id, Partner__r.Id, Product__r.Disbursal_Terms__c,
                                    (SELECT Id, Amount__c, Status__c, Disbursal_Percentage__c, Disbursal_Sequence__c, Name, Adjustments__c
                                    FROM Disbursals__r
                                    ORDER BY Disbursal_Sequence__c)
                                   FROM Loan__c
                                   WHERE Id IN : updatedLoans]) {
            for (Disbursal__c disbursal : calculateNextDisbursalAfterRLAChange(loanRecord, newMap, oldMap)) {
                disbursalsToUpdate.add(disbursal);
            }
        }
        update disbursalsToUpdate;
    }      

    public void updateDisbursalsOnOpportunityUpdate (List<Opportunity> updatedOppList, List<Opportunity> oldOppList) { 
        Opportunity updatedOpportunity = updatedOppList.get(0);
        Opportunity oldOpportunity = oldOppList.get(0); 
        String disbursalMethodContract;
        String disbursalMethodMechInstall;
        String disbursalMethodInterconnect;
        List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();        
        if(dibursalMethodOrDateIsChanged(updatedOpportunity, oldOpportunity, 'Disbursal_1_Contract_Signature_Checkbox__c', 'Disbursal_Type_Contract__c') ||
            dibursalMethodOrDateIsChanged(updatedOpportunity, oldOpportunity, 'Disbursal_2_Mechanical_Install_Checkbox__c', 'Disbursal_Type_Mech_Completion__c') || 
            dibursalMethodOrDateIsChanged(updatedOpportunity, oldOpportunity, 'Disbursal_3_Full_Install_Checkbox__c', 'Disbursal_Type_Interconnect__c')) {
            for (Loan__c loan : [SELECT Id, Opportunity__r.Id, 
                                    (SELECT Id, Name, Status__c, Disbursal_Method__c, Date_of_Disbursal__c, Reason_For_Hold__c, Type__c 
                                    FROM Disbursals__r)
                                 FROM Loan__c
                                 WHERE Opportunity__r.Id = : updatedOpportunity.Id]) {
                if (!loan.Disbursals__r.isEmpty()) {
                    for (Disbursal__c disbursal : loan.Disbursals__r) {
                        if (updatedOpportunity.Disbursal_Type_Contract__c == 'ACH Disbursal') {
                            disbursalMethodContract = 'ACH';
                        } else if (updatedOpportunity.Disbursal_Type_Contract__c == 'Check Disbursal') {
                            disbursalMethodContract = 'Check';
                        } else {
                            disbursalMethodContract = null;
                        }
                        if (updatedOpportunity.Disbursal_Type_Interconnect__c == 'ACH Disbursal') {
                            disbursalMethodInterconnect = 'ACH';
                        } else if (updatedOpportunity.Disbursal_Type_Interconnect__c == 'Check Disbursal') {
                            disbursalMethodInterconnect = 'Check';
                        } else {
                            disbursalMethodInterconnect = null;
                        }
                        if (updatedOpportunity.Disbursal_Type_Mech_Completion__c == 'ACH') {
                            disbursalMethodMechInstall = 'ACH';
                        } else if (updatedOpportunity.Disbursal_Type_Mech_Completion__c == 'Check') {
                            disbursalMethodMechInstall = 'Check';
                        } else {
                            disbursalMethodMechInstall = null;
                        }                            
                        if (disbursal.Type__c == 'Contract Signature') {
                            disbursalsToUpdate.add(updateDisbursalValues(Disbursal, Loan, updatedOpportunity, oldOpportunity,  
                                'Disbursal_1_Contract_Signature_Checkbox__c', 'Disbursal_Type_Contract__c', disbursalMethodContract));
                        } else if (disbursal.Type__c == 'Mechanical installation') {
                            disbursalsToUpdate.add(updateDisbursalValues(Disbursal, Loan, updatedOpportunity, oldOpportunity, 
                                'Disbursal_2_Mechanical_Install_Checkbox__c', 'Disbursal_Type_Mech_Completion__c', disbursalMethodMechInstall));
                        } else if (disbursal.Type__c == 'Interconnection') {
                            disbursalsToUpdate.add(updateDisbursalValues(Disbursal, Loan, updatedOpportunity, oldOpportunity,
                                'Disbursal_3_Full_Install_Checkbox__c', 'Disbursal_Type_Interconnect__c', disbursalMethodInterconnect));
                        }
                    }
                }
            }
            update disbursalsToUpdate;
        }
    }

    public Boolean dibursalMethodOrDateIsChanged (Opportunity updatedOpportunity, Opportunity oldOpportunity, String disbursalDateField, String disbursalMethodField) {
        if (updatedOpportunity.get(disbursalDateField) != oldOpportunity.get(disbursalDateField) ||
            updatedOpportunity.get(disbursalMethodField) != oldOpportunity.get(disbursalMethodField)) {
            return true;
        } else {
            return false;
        }
    }    

    public Disbursal__c updateDisbursalValues (Disbursal__c disbursal, Loan__c loan, Opportunity updatedOpportunity, Opportunity oldOpportunity, String disbursalDateField, String disbursalMethodField, String disbursalMethod) {
        if (updatedOpportunity.get(disbursalDateField) != null && updatedOpportunity.get(disbursalDateField) != oldOpportunity.get(disbursalDateField)) {
            disbursal.Status__c = 'Complete';
            disbursal.Disbursal_Method__c = disbursalMethod;
            disbursal.Date_of_Disbursal__c = (Date)updatedOpportunity.get(disbursalDateField);
        } else {
            disbursal = setToNotYetDisbursed(disbursal);
        }
        if (updatedOpportunity.get(disbursalMethodField) != oldOpportunity.get(disbursalMethodField)) {
            disbursal.Disbursal_Method__c = disbursalMethod;
        } 
        return disbursal;
    }    

    public Disbursal__c setToNotYetDisbursed (Disbursal__c disbursal) {
        disbursal.Status__c = 'Not yet disbursed';
        disbursal.Disbursal_Method__c = null;
        disbursal.Date_of_Disbursal__c = null;
        return disbursal;
    }      

    public List<Disbursal__c> calculateNextDisbursalAfterRLAChange (Loan__c loanRecord, Map<Id,Loan__c> newMap, Map<Id, Loan__c> oldMap) {
        List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
        String name;
        String increaseDecrease;
        Integer i;
        Decimal oldAmount;
        Decimal newAmount;
        Decimal nextAmount;
        Decimal minimumSequenceCount = 0;
        Decimal changeInLoanAmount = newMap.get(loanRecord.Id).Requested_Loan_Amount__c - oldMap.get(loanRecord.Id).Requested_Loan_Amount__c;
        Decimal differenceInCompletedDisbursals = 0;
        Disbursal__c nextDisbursal;
        Disbursal__c disbursal;
        DisbursalStructure disbursalStructure = getDisbursalStructure(loanRecord);   
        DateTime now = System.now();
        Date today = date.newInstance(now.year(), now.month(), now.day());

        for (i=0;i<loanRecord.Disbursals__r.size();i++) {
            disbursal = loanRecord.Disbursals__r.get(i);
            oldAmount = disbursal.Amount__c;
            newAmount = newMap.get(loanRecord.Id).Requested_Loan_Amount__c * disbursal.Disbursal_Percentage__c/100;
            if (disbursal.Status__c == 'Complete') {
                differenceInCompletedDisbursals = differenceInCompletedDisbursals + newAmount - oldAmount;                     
            }            
        }     
        for (i=0;i<loanRecord.Disbursals__r.size();i++) {
            disbursal = loanRecord.Disbursals__r.get(i);
            if (disbursal.Status__c != 'Complete') {
                if (minimumSequenceCount == 0) {
                    minimumSequenceCount = disbursal.Disbursal_Sequence__c;
                    nextDisbursal = disbursal;
                    name = disbursal.Name;
                }
                if (disbursal.Disbursal_Sequence__c <= minimumSequenceCount) {
                    minimumSequenceCount = disbursal.Disbursal_Sequence__c;          
                    nextDisbursal = disbursal;
                    name = disbursal.Name;
                } else {
                    newAmount =  newMap.get(loanRecord.Id).Requested_Loan_Amount__c * disbursal.Disbursal_Percentage__c /100;
                    disbursal.Adjustments__c = 'Adjusted from ' +  disbursal.Amount__c + ' to '+ newAmount + ' ' + today;                    
                    disbursal.Amount__c = newAmount;
                    disbursalsToUpdate.add(disbursal);
                }
            }           
        }  
        nextAmount = loanRecord.Requested_Loan_Amount__c * nextDisbursal.Disbursal_Percentage__c/100 + differenceInCompletedDisbursals;
        nextDisbursal.Adjustments__c = 'Adjusted from ' +  nextDisbursal.Amount__c + ' to '+ nextAmount + ' ' + today; 
        nextDisbursal.Amount__c = nextAmount;
        disbursalsToUpdate.add(nextDisbursal);       
        return disbursalsToUpdate;
    }

    public Boolean opportunityStageChangesToComplete (Opportunity oppRecord, Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        if (newMap.get(oppRecord.Id).StageName == 'Complete'
            && oldMap.get(oppRecord.Id).StageName != 'Complete'
            && newMap.get(oppRecord.Id).Product_Line__c == 'Residential Loan') {
            return true;
        } else {
            return false;
        }   
    }    
}