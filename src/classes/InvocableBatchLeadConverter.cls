/**
 * Created by peteryao on 1/31/20.
 */

public with sharing class InvocableBatchLeadConverter {
    @InvocableMethod(Label='Invocable Batch Lead Converter' Description='Starts a batch process to convert leads one at a time to a Qualified status without an Opportunity')
    public static void startLeadConversionBatch(List<List<Lead>> leadsToConvert) {
        GenericBatchDMLOperation genericBatchDMLOperation = new GenericBatchDMLOperation(leadsToConvert[0], 'Convert');
        GenericBatchDMLOperation.LeadConvertOption leadConvertOption = new GenericBatchDMLOperation.LeadConvertOption('Qualified');
        leadConvertOption.doNotCreateOpportunity = true;
        genericBatchDMLOperation.setLeadConvertOption(leadConvertOption);
        Database.executeBatch(genericBatchDMLOperation, 1);
    }
}