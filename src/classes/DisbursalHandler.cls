/*************************************************************************************
 * Created By:  Cole Swain
 * Description: This is the handler for the Disbursal object.
 * Test: DisbursalHandlerTest
 *************************************************************************************/
public class DisbursalHandler {

    public void createDisbursalsFromOpportunity(Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Loan__c> loanList = new List<Loan__c>();
        List<String> opportunityIdList = new List<String>();
        List<Disbursal__c> disbursalsToInsert = new List<Disbursal__c>();

        for (Opportunity oppRecord : newMap.values()) {
            if (fieldHasChanged(oppRecord, newMap, oldMap, 'StageName', 'Complete', null) && oppRecord.Product_Line__c == 'Residential Loan') {
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
                for (Disbursal__c disbursal : createDisbursalsFromDisbursalTermsField(loanRecord)) {
                    disbursalsToInsert.add(disbursal);
                }
            }
            upsert disbursalsToInsert Unique_ID__c;
        }
    }

    public static List<Disbursal__c> createDisbursalsFromDisbursalTermsField (Loan__c loanRecord) {
        Integer count = 1;
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        List<String> disbursalSubStrings = loanRecord.Product__r.Disbursal_Terms__c.split(',');
        for (String subString : disbursalSubStrings) {
            List<String> rateAndType = subString.split('%');
            String disbursalName = subString;
            if (disbursalName.length() >= 80) {
                disbursalName = disbursalName.subString(0,80);
            }
            disbursalList.add(createDisbursal(Decimal.valueOf(rateAndType.get(0).remove(' ')), disbursalName, rateAndType.get(1), count, loanRecord));
            count = count + 1;
        }
        return disbursalList;
    }        

    public static Disbursal__c createDisbursal (Decimal rate, String name, String disbursalType, Integer sequence, Loan__c loanRecord) {
            Disbursal__c disbursal = new Disbursal__c(
            Name = name  + ' - ' + loanRecord.Partner__r.Name + ' - ' + loanRecord.Name,
            Unique_ID__c = loanRecord.Id + ' ' + name + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
            Loan__c = loanRecord.Id,
            Disbursal_Sequence__c = sequence,
            Disbursal_Percentage__c = rate,
            Partner__c = loanRecord.Partner__r.Id,
            Sales_Representative__c = loanRecord.Sales_Agent__r.Id,
            Status__c = 'Pending',
            Amount__c = loanRecord.Requested_Loan_Amount__c * rate / 100,
            Type__c = disbursalType
        );
        return disbursal;
    }  

    public void updateDisbursalAmountsOnRLAChange (Map<Id,Loan__c> newMap, Map<Id, Loan__c> oldMap) {
        List<Id> updatedLoans = new List<Id>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
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
            if (!loanRecord.Disbursals__r.isEmpty()) {
                disbursalList = new List<Disbursal__c>(calculateNextDisbursalAfterRLAChange(loanRecord, newMap, oldMap));
            }
        }
        if (!disbursalList.isEmpty()) {
            update disbursalList;
        }
    }

    public void setContractDisbursalToReady (List<Opportunity> oppList, Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Id> oppIdList = new List<Id>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        for (Opportunity oppRecord : oppList) {
            oppIdList.add(oppRecord.Id);
        }
        Map<String,Disbursal__c> disbursalMap = getDisbursalMap(oppIdList);
        for (Opportunity oppRecord : oppList) {
            if (disbursalMap.get(oppRecord.Id + 'Contract Signature') != null) {
                if (fieldHasChanged(oppRecord, newMap, oldMap, 'StageName', 'Complete', null) && oppRecord.Product_Line__c == 'Residential Loan') {
                    disbursalList.add(setDisbursalStatus('Contract Signature', oppRecord.Id, disbursalMap, oppRecord.DOER_Solar_Loan__c?'Ready for FBO Funding':'Due', null));
                } else if (fieldHasChanged(oppRecord, newMap, oldMap, 'StageName', 'Complete', 'Complete') && oppRecord.Product_Line__c == 'Residential Loan') {
                    disbursalList.add(setDisbursalStatus('Contract Signature', oppRecord.Id, disbursalMap, 'Pending', null));
                }
            }
        }
        if (!disbursalList.isEmpty()) {
            update disbursalList;
        }
    }

    public void setEquipmentDisbursals (List<Residential_Equipment__c> equipmentList, Map<Id,Residential_Equipment__c> newMap, Map<Id, Residential_Equipment__c> oldMap) {
        List<Id> oppIdList = new List<Id>();
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        List<Residential_Equipment__c> queriedEquipment = new List<Residential_Equipment__c>();
        List<Id> equipmentIdList = new List<Id>();
        for (Residential_Equipment__c equipment : equipmentList) {
            equipmentIdList.add(equipment.Id);
        }
        for (Residential_Equipment__c equipment : [SELECT Id, Opportunity__r.Id, Opportunity__r.Lender_of_Record__c, Opportunity__r.DOER_Solar_Loan__c FROM Residential_Equipment__c WHERE Id IN : equipmentIdList]) {
            queriedEquipment.add(equipment);
            oppIdList.add(equipment.Opportunity__r.Id);
        }
        Map<String,Disbursal__c> disbursalMap = getDisbursalMap(oppIdList);
        for (Residential_Equipment__c equipment : queriedEquipment) {
            if (disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation') != null) {
                if (fieldHasChanged(equipment, newMap, oldMap, 'Mechanically_Installed__c', 'true', null)) {
                    disbursalList.add(setDisbursalStatus('Mechanical Installation', equipment.Opportunity__r.Id, disbursalMap, 'Due', null));
                } 
            }
            if (disbursalMap.get(equipment.Opportunity__r.Id + 'Interconnection') != null) {
                if (fieldHasChanged(equipment, newMap, oldMap, 'Interconnected__c', 'true', null)) {
                    if (!equipment.Opportunity__r.DOER_Solar_Loan__c) {
                        disbursalList.add(setDisbursalStatus('Interconnection', equipment.Opportunity__r.Id, disbursalMap,  'Due', null));
                    }
                } 
            }
        }
        if (!disbursalList.isEmpty()) {
            update disbursalList;
        }
    }

    public Disbursal__c setDisbursalStatus (String disbursalType, String opportunityId, Map<String,Disbursal__c> disbursalMap, String status, String doNotSetStatusValue) {
        Disbursal__c disbursal = disbursalMap.get(opportunityId + disbursalType);
        if (disbursal != null) {
            if (doNotSetStatusValue != null) {
                if (disbursal.Status__c == doNotSetStatusValue) {
                    return disbursal;
                } else {
                    disbursal.Status__c = status;
                    disbursal.Anticipated_Date__c = Date.today();
                }
            } else {
                disbursal.Status__c = status;
                disbursal.Anticipated_Date__c = Date.today();
            }
        }
        return disbursal;
    }

    public void setStatusToDisbursed (List<Disbursal__c> disbursalList, Map<Id,Disbursal__c> newMap, Map<Id, Disbursal__c> oldMap) {
        for (DisbursaL__c disbursal : disbursalList) {
            if (newMap.get(disbursal.Id).Date_of_Disbursal__c != oldMap.get(disbursal.Id).Date_of_Disbursal__c) {
                if (newMap.get(disbursal.Id).Date_of_Disbursal__c != null) {
                    disbursal.Status__c = 'Disbursed';
                    disbursal.Funds_in_FBO_Account__c = false;
                } else {
                    disbursal.Status__c = 'Ready for Disbursement';
                    if (oldMap.get(disbursal.Id).Date_of_FBO_Funding__c != null) {
                        disbursal.Funds_in_FBO_Account__c = true;
                    }
                }
            }
        }
    }

    public void setStatusAndFBODateonFBOFunding (List<Disbursal__c> disbursalList, Map<Id,Disbursal__c> newMap, Map<Id, Disbursal__c> oldMap) {
        for (DisbursaL__c disbursal : disbursalList) {
            if (fieldHasChanged(disbursal, newMap, oldMap, 'Funds_in_FBO_Account__c', 'true', null)) {
                disbursal.Date_of_FBO_Funding__c = Date.today();
                if (disbursal.Status__c != 'Disbursed') {
                    disbursal.Status__c = 'Ready for Disbursement';
                }
            } else if (fieldHasChanged(disbursal, newMap, oldMap, 'Funds_in_FBO_Account__c', 'false', null)) {
                    disbursal.Date_of_FBO_Funding__c = null;
            }
        }
    }

    public void setStatusToHold (List<Disbursal__c> disbursalList, Map<Id,Disbursal__c> newMap, Map<Id, Disbursal__c> oldMap) {
        for (DisbursaL__c disbursal : disbursalList) {
            if (fieldHasChanged(disbursal, newMap, oldMap, 'Hold_on_Disbursal__c', 'true', null)) {
                disbursal.Status_Before_Hold__c = disbursal.Status__c;
                disbursal.Status__c = 'Hold';
            } else if (fieldHasChanged(disbursal, newMap, oldMap, 'Hold_on_Disbursal__c', 'false', null)) {
                disbursal.Status__c = disbursal.Status_Before_Hold__c;
                disbursal.Status_before_hold__c = null;
            }
        }
    }

    public Boolean fieldHasChanged (SObject record, Map<Id,SObject> newMap, Map<Id, SObject> oldMap, String fieldName, String changeValue, String notChangeValue) {
        if (notChangeValue == null) {
            return (String.valueOf(newMap.get(record.Id).get(fieldName)) == changeValue
                && String.valueOf(oldMap.get(record.Id).get(fieldName)) != changeValue);
        } else {
            return (String.valueOf(newMap.get(record.Id).get(fieldName)) != notChangeValue
                && String.valueOf(oldMap.get(record.Id).get(fieldName)) == changeValue);
        }
    }


    public Map<String,Disbursal__c> getDisbursalMap (List<String> oppIdList) {
        Map<String,Disbursal__c> disbursalMap = new Map<String, Disbursal__c>();
        for (Disbursal__c disbursal : [SELECT Id, Status__c, Name, Loan__r.Opportunity__r.Id, Type__c FROM Disbursal__c WHERE Loan__r.Opportunity__r.Id IN : oppIdList]) {
            disbursalMap.put(disbursal.Loan__r.Opportunity__r.Id + disbursal.Type__c, disbursal);
        }
        return disbursalMap;
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
        Decimal differenceInCompletedDisbursals = 0;
        Disbursal__c nextDisbursal;
        Disbursal__c disbursal;
        DateTime now = System.now();
        Date today = Date.newInstance(now.year(), now.month(), now.day());
        for (i=0;i<loanRecord.Disbursals__r.size();i++) {
            disbursal = loanRecord.Disbursals__r.get(i);
            oldAmount = disbursal.Amount__c;
            newAmount = newMap.get(loanRecord.Id).Requested_Loan_Amount__c * disbursal.Disbursal_Percentage__c/100;
            if (disbursal.Status__c == 'Disbursed') {
                differenceInCompletedDisbursals = differenceInCompletedDisbursals + newAmount - oldAmount;
            }
        }
        for (i=0;i<loanRecord.Disbursals__r.size();i++) {
            disbursal = loanRecord.Disbursals__r.get(i);
            if (disbursal.Status__c != 'Disbursed') {
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
                    disbursal.Adjustments__c = 'Adjusted from ' +  disbursal.Amount__c + ' to '+ newAmount + ' on ' + today;
                    disbursal.Amount__c = newAmount;
                    disbursalsToUpdate.add(disbursal);
                }
            }
        }
        nextAmount = loanRecord.Requested_Loan_Amount__c * nextDisbursal.Disbursal_Percentage__c/100 + differenceInCompletedDisbursals;
        nextDisbursal.Adjustments__c = 'Adjusted from ' +  nextDisbursal.Amount__c + ' to '+ nextAmount + ' on ' + today; 
        nextDisbursal.Amount__c = nextAmount;
        disbursalsToUpdate.add(nextDisbursal);
        return disbursalsToUpdate;
    }
}