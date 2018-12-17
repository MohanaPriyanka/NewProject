/*************************************************************************************
 * Created By:  Cole Swain
 * Description: This is the handler for the Disbursal object.
 * Test: DisbursalHandlerTest
 *************************************************************************************/
public class DisbursalHandler {
    private Set<String> protectedDisbursalStatuses = new Set<String>{'Disbursed', 'Reimbursed', 'Hold'};


    public void createDisbursalsFromOpportunity(Map<Id,Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        List<Loan__c> loanList = new List<Loan__c>();
        Map<String, String> disbursalStatuses = new Map<String, String>();
        Map<String, Decimal> disbursalAmounts = new Map<String, Decimal>();
        List<String> opportunityIdList = new List<String>();
        List<Disbursal__c> disbursalsToInsert = new List<Disbursal__c>();

        for (Opportunity oppRecord : newMap.values()) {
            if (fieldHasChanged(oppRecord, newMap, oldMap, 'StageName', 'Complete', null) && oppRecord.Product_Line__c == 'Residential Loan') {
                opportunityIdList.add(newMap.get(oppRecord.Id).Id);
            }
        }
        if (!opportunityIdList.isEmpty()) {
            loanList = getLoansFromOpportunityIds(opportunityIdList);
            List<Id> loanIds = getLoanIdsFromLoanList(loanList);
            List<Disbursal__c> disbursals = getDisbursalsFromLoan(loanIds);

            disbursalStatuses = getDisbursalStatusMap(disbursals);
            disbursalAmounts = getDisbursalAmountMap(disbursals);
            disbursalsToInsert = createAndTrueUpDisbursals(loanList, disbursalStatuses, disbursalAmounts);

            upsert disbursalsToInsert Unique_ID__c;
        }
            }

    public List<Disbursal__c> createAndTrueUpDisbursals(List<Loan__c> loanList, Map<String, String> disbursalStatuses, Map<String, Decimal> disbursalAmounts) {
        List<Disbursal__c> disbursalsToInsert = new List<Disbursal__c>();
            for (Loan__c loanRecord : loanList) {
                List<Disbursal__c> stagedDisbursals = new List<Disbursal__c>();
                Decimal disbursalTotal = 0;
            Boolean loanInvoiceReceived = (loanRecord.Invoice_Amount__c != null);
            Integer sequenceToAllocateBalance;
            Decimal loanAmountMinusTPF = loanRecord.Requested_Loan_Amount__c - loanRecord.Technology_Platform_Fee__c;
                for (Disbursal__c disbursal : createDisbursalsFromDisbursalTermsField(loanRecord)) {
                    String previousStatus = disbursalStatuses.get(disbursal.Unique_ID__c);
                    if (!protectedDisbursalStatuses.contains(previousStatus)) {
                        // if the disbursal's previous status is not protected, use the new amount
                        disbursalTotal += disbursal.Amount__c;
                    } else {
                        // if the disbursal's previous status is protected, use its original amount since it gets filtered out later.
                        disbursalTotal += disbursalAmounts.get(disbursal.Unique_ID__c);
                    }
                    stagedDisbursals.add(disbursal);
                }
                /* If the total Amount to be disbursed matches the loan amount,
                   we filter the list to only update the disbursals without protected statuses.
                   Otherwise we adjust the disbursal amounts to match the loan amount. */
            if ((!loanInvoiceReceived && disbursalTotal == loanRecord.Requested_Loan_Amount__c) ||
                loanInvoiceReceived && disbursalTotal == loanAmountMinusTPF) {
                    disbursalsToInsert.addAll(filterProtectedDisbursals(stagedDisbursals, disbursalStatuses));
                } else {
                if (loanInvoiceReceived) {
                    sequenceToAllocateBalance = 3;
                } else {
                    sequenceToAllocateBalance = 2;
                }
                disbursalsToInsert.addAll(trueUpNewDisbursals(stagedDisbursals,
                    disbursalStatuses, disbursalAmounts, loanRecord.Requested_Loan_Amount__c,
                    sequenceToAllocateBalance, loanRecord.Invoice_Amount__c, loanRecord.Technology_Platform_Fee__c));
            }
        }
        return disbursalsToInsert;
    }

    public static List<Disbursal__c> createDisbursalsFromDisbursalTermsField (Loan__c loanRecord) {
        Integer count = 1;
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        List<String> disbursalSubStrings = loanRecord.Product__r.Disbursal_Terms__c.split(', ');
        for (String subString : disbursalSubStrings) {
            List<String> rateAndType = subString.split('%');
            String disbursalName = subString;
            disbursalList.add(createDisbursal(Decimal.valueOf(rateAndType.get(0).remove(' ')), disbursalName, rateAndType.get(1), count, loanRecord));
            count = count + 1;
        }
        return disbursalList;
    }

    public static Disbursal__c createDisbursal (Decimal rate, String name, String disbursalType, Integer sequence, Loan__c loanRecord) {
        Disbursal__c disbursal = new Disbursal__c(
            Name = 'D' + String.valueOf(sequence) + ' - ' + String.valueOf(rate) + '%' + ' - ' + loanRecord.Name + ' - ' + loanRecord.Partner__r.Name,
            Unique_ID__c = loanRecord.Id + ' ' + name + ' ' + loanRecord.Partner__r.Name + ' ' + loanRecord.Name,
            Loan__c = loanRecord.Id,
            Disbursal_Sequence__c = sequence,
            Disbursal_Percentage__c = rate,
            Partner__c = loanRecord.Partner__c,
            Sales_Representative__c = loanRecord.Sales_Agent__c,
            Status__c = 'Pending',
            Amount__c = calcDisbursalAmount(loanRecord, sequence, rate),
            Type__c = disbursalType
        );
        if (disbursal.Name.length() >= 80) {
            disbursal.Name = disbursal.Name.substring(0,80);
        }
        return disbursal;
    }

    public List<Disbursal__c> getDisbursalsFromLoan(List<Id> loanIds) {
        List<Disbursal__c> disbursals = [
            SELECT Id, Unique_ID__c, Status__c, Amount__c
            FROM Disbursal__c
            WHERE Loan__c IN : loanIds
        ];
        return disbursals;
    }

    public static Decimal calcDisbursalAmount(Loan__c loanRecord, Integer sequence, Decimal rate) {
        Decimal disbursalAmount;
        if (loanRecord.Invoice_Amount__c != null && sequence == 2) {
            disbursalAmount = loanRecord.Invoice_Amount__c;
        } else if (loanRecord.Invoice_Amount__c != null && sequence == 3) {
            disbursalAmount = loanRecord.Requested_Loan_Amount__c - loanRecord.Invoice_Amount__c - loanRecord.Technology_Platform_Fee__c;
        } else {
            disbursalAmount = loanRecord.Requested_Loan_Amount__c * rate / 100;
        }
        return disbursalAmount;
    }

    public Map<String, String> getDisbursalStatusMap(List<Disbursal__c> disbursals) {
        Map<String, String> disbursalStatuses = new Map<String, String>();
        for (Disbursal__c disbursal : disbursals) {
            disbursalStatuses.put(disbursal.Unique_ID__c, disbursal.Status__c);
        }
        return disbursalStatuses;
    }

    public Map<String, Decimal> getDisbursalAmountMap(List<Disbursal__c> disbursals) {
        Map<String, Decimal> disbursalAmounts = new Map<String, Decimal>();
        for (Disbursal__c disbursal : disbursals) {
            disbursalAmounts.put(disbursal.Unique_ID__c, disbursal.Amount__c);
        }
        return disbursalAmounts;
    }

    public List<Loan__c> getLoansFromOpportunityIds(List<Id> opportunityIdList) {
        List<Loan__c> loanList = new List<Loan__c>();
        for(Opportunity opp :  [
            SELECT Id, Name,
            (SELECT Id, Name, Opportunity__r.StageName, Requested_Loan_Amount__c, Partner__r.Id, Partner__r.Name,
                Product__r.Disbursal_Terms__c, Opportunity__r.Requested_Loan_Amount__c, Sales_Agent__r.Id,
                Profit_Center__c, Invoice_Amount__c, Technology_Platform_Fee__c
            FROM Loans__r)
            FROM Opportunity
            WHERE Id IN : opportunityIdList
        ]) {
            loanList.add(opp.Loans__r);
        }
        return loanList;
    }


    public List<Id> getLoanIdsFromLoanList(List<Loan__c> loanList) {
        List<Id> loanIds = new List<Id>();
        for (Loan__c loan : loanList) {
            loanIds.add(loan.Id);
        }
        return loanIds;
    }

    public List<Disbursal__c> filterProtectedDisbursals(List<Disbursal__c> stagedDisbursals, Map<String, String> disbursalStatuses) {
        List<Disbursal__c> approvedDisbursals = new List<Disbursal__c>();
        for (Disbursal__c disbursal : stagedDisbursals) {
            // We want to check for a disbursal with the same unique ID and get its status
            String previousStatus = disbursalStatuses.get(disbursal.Unique_ID__c);
            // If the disbursal status is protected we don't want to update it
            if (!protectedDisbursalStatuses.contains(previousStatus)) {
                approvedDisbursals.add(disbursal);
            }
        }
        return approvedDisbursals;
    }

    public List<Disbursal__c> trueUpNewDisbursals(List<Disbursal__c> stagedDisbursals, Map<String, String> disbursalStatuses, Map<String, Decimal> disbursalAmounts, Decimal loanAmount, Integer sequenceToAllocateBalance, Decimal InvoiceAmount, Decimal tpf) {
        List<Disbursal__c> approvedDisbursals = new List<Disbursal__c>();
        Decimal remainingDisbursalAmount = loanAmount;
        // Iterate through the disbursals once to get the remainder after removing protected disbursals and the D3 disbursal.
        for (Disbursal__c disbursal : stagedDisbursals) {
            String previousStatus = disbursalStatuses.get(disbursal.Unique_ID__c);
            // If the disbursal status is protected we don't want to update it, just subtract it's total from the remaining balance.
            if (protectedDisbursalStatuses.contains(previousStatus)) {
                remainingDisbursalAmount -=  disbursalAmounts.get(disbursal.Unique_ID__c);
            } else if (disbursal.Disbursal_Sequence__c != sequenceToAllocateBalance) {
                remainingDisbursalAmount -= disbursal.Amount__c;
                approvedDisbursals.add(disbursal);
            }
        }
        // Iterate through the disbursals a second time to isolate the D2 disbural and assign the remaining amount to it.
        if (InvoiceAmount != null) {
            remainingDisbursalAmount -= tpf;
        }
        for (Disbursal__c disbursal : stagedDisbursals) {
            String previousStatus = disbursalStatuses.get(disbursal.Unique_ID__c);
            if (!protectedDisbursalStatuses.contains(previousStatus) &&
               disbursal.Disbursal_Sequence__c == sequenceToAllocateBalance) {
                disbursal.Amount__c = remainingDisbursalAmount;
                approvedDisbursals.add(disbursal);
            }
        }
        return approvedDisbursals;
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
        for (Residential_Equipment__c equipment : [SELECT Id, Opportunity__r.Id, Opportunity__r.Lender_of_Record__c, Opportunity__r.Product__r.Name, Opportunity__r.DOER_Solar_Loan__c FROM Residential_Equipment__c WHERE Id IN : equipmentIdList]) {
            queriedEquipment.add(equipment);
            oppIdList.add(equipment.Opportunity__r.Id);
        }
        Map<String,Disbursal__c> disbursalMap = getDisbursalMap(oppIdList);
        for (Residential_Equipment__c equipment : queriedEquipment) {
            if (disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation') != null) {
                if (fieldHasChanged(equipment, newMap, oldMap, 'Mechanically_Installed__c', 'true', null)) {
                    String newStatus = 'Due';
                    if (disbursalMap.get(equipment.Opportunity__r.Id + 'Contract Signature') != null &&
                        disbursalMap.get(equipment.Opportunity__r.Id + 'Contract Signature').Status__c == 'Hold') {
                        newStatus = 'Hold';
                        disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation').Hold_on_Disbursal__c = true;
                        disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation').Reason_for_Hold__c = 'A previous disbursal is on hold.';
                        if (disbursalMap.get(equipment.Opportunity__r.Id + 'CED Ensemble') != null) {
                            disbursalMap.get(equipment.Opportunity__r.Id + 'CED Ensemble').Hold_on_Disbursal__c = true;
                            disbursalMap.get(equipment.Opportunity__r.Id + 'CED Ensemble').Reason_for_Hold__c = 'A previous disbursal is on hold.';
                        }
                    }
                    if (disbursalMap.get(equipment.Opportunity__r.Id + 'CED Ensemble') != null) {
                        disbursalList.add(setDisbursalStatus('CED Ensemble', equipment.Opportunity__r.Id, disbursalMap, newStatus, null));
                    }
                    disbursalList.add(setDisbursalStatus('Mechanical Installation', equipment.Opportunity__r.Id, disbursalMap, newStatus, null));
                } 
            }
            if (disbursalMap.get(equipment.Opportunity__r.Id + 'Interconnection') != null) {
                if (fieldHasChanged(equipment, newMap, oldMap, 'Interconnected__c', 'true', null)) {
                    if (!equipment.Opportunity__r.DOER_Solar_Loan__c) {
                        String newStatus = 'Due';
                        if (disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation') != null &&
                            disbursalMap.get(equipment.Opportunity__r.Id + 'Mechanical Installation').Status__c == 'Hold') {
                            newStatus = 'Hold';
                            disbursalMap.get(equipment.Opportunity__r.Id + 'Interconnection').Hold_on_Disbursal__c = true;
                            disbursalMap.get(equipment.Opportunity__r.Id + 'Interconnection').Reason_for_Hold__c = 'A previous disbursal is on hold.';
                        }
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
            if (protectedDisbursalStatuses.contains(disbursal.Status__c)) {
                status = disbursal.Status__c;
            }
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
        for (Disbursal__c disbursal : disbursalList) {
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
        for (Disbursal__c disbursal : disbursalList) {
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
        for (Disbursal__c disbursal : disbursalList) {
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
        for (Disbursal__c disbursal : [
            SELECT Id, Status__c, Name, Loan__r.Opportunity__r.Id,
                Type__c, Amount__c
            FROM Disbursal__c
            WHERE Loan__r.Opportunity__r.Id IN : oppIdList
        ]) {
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

    public void setFirstPaymentDueDate(List<Disbursal__c> newDisbursals, Map<Id, Disbursal__c> oldDisbursals) {
        Set<Id> loanIds = new Set<Id>();
        for (Disbursal__c disbursal : newDisbursals) {
            if (disbursal.Date_of_Disbursal__c != oldDisbursals.get(disbursal.Id).Date_of_Disbursal__c) {
                loanIds.add(disbursal.Loan__c);
            }
        }
        Map<Id, Loan__c> loanMap = new Map<Id, Loan__c>([
            SELECT Id, DOER_Solar_Loann__c, First_Payment_Due_Date_Override__c
            FROM Loan__c
            WHERE Id = :loanIds
        ]);
        List<Loan__c> loansToUpdate = new List<Loan__c>();
        for (Disbursal__c disbursal : newDisbursals) {
            if (disbursal.Date_of_Disbursal__c != oldDisbursals.get(disbursal.Id).Date_of_Disbursal__c) {
                Loan__c relatedLoan = loanMap.get(disbursal.Loan__c);
                if ((disbursal.Disbursal_Sequence__c == 1 && relatedLoan.DOER_Solar_Loann__c) ||
                    (disbursal.Disbursal_Sequence__c == 3 && !relatedLoan.DOER_Solar_Loann__c)) {
                    Loan__c loan = new Loan__c(
                        Id = disbursal.Loan__c,
                        First_Payment_Due_Date_Override__c = getFirstPaymentDueDate(disbursal.Date_of_Disbursal__c)
                    );
                    loansToUpdate.add(loan);

                }
            }
        }
        if (!loansToUpdate.isEmpty()) {
            update loansToUpdate;
        }
    }

    // Per Lease Dimensions, if a due date falls on the 29 or later, move the date to the first of the next month
    private Date getFirstPaymentDueDate(Date disbursalDate) {
        if (disbursalDate == null) {
            return null;
        }
        Date firstPaymentDueDate = disbursalDate.addMonths(1);
        if (firstPaymentDueDate.day() > 28) {
            firstPaymentDueDate = Date.newInstance(firstPaymentDueDate.year(), firstPaymentDueDate.month()+1, 1);
        }
        return firstPaymentDueDate;
    }
}