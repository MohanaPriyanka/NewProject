/**
 * @description Parent class for SubscriptionOrder and ContractFeeDetail, used to make them comparable
 * Tested By: ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */
@SuppressWarnings('PMD.TooManyFields')
public virtual without sharing class FeeQualification {
    public Id sharedSolarSystemId;
    public List<Id> contractIds;
    public Id recordId;
    public Decimal amount;
    @TestVisible protected Boolean acquisition;
    @TestVisible protected Boolean reacquisition;
    @TestVisible protected Boolean bcsAcquired;
    @TestVisible protected Boolean notBCSAcquired;
    @TestVisible protected Boolean closedByBCS;
    @TestVisible protected Boolean anchor;
    @TestVisible protected Boolean publicOfftake;
    @TestVisible protected Boolean notPublicOfftake;
    @TestVisible protected Boolean residential;
    @TestVisible protected Boolean nonResidential;
    @TestVisible protected Boolean investmentGradeAnchor;
    @TestVisible protected Boolean notInvestmentGradeAnchor;
    @TestVisible protected Boolean downsizing;
    @TestVisible protected Boolean upsizing;
}