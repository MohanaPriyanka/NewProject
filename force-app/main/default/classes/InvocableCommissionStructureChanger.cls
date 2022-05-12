/**
 * @description Created by jeffparlin on 5/3/22. Changes Commission Structure on Opportunity, and modifies existing
 * Commission Payments and Subscription Orders accordingly. Will not process Opportunities not meeting specific criteria.
 * Used in the Change Commission Structure flow
 * Tested By: InvocableCommissionStructureChangerTest
 */
public class InvocableCommissionStructureChanger {

    @TestVisible private static final String INVALID_STAGE_ERROR = 'Invalid Opportunity Stage';
    @TestVisible private static final String APPROVED_PAYMENTS_ERROR = 'Approved Commission Payment Found';
    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
    @TestVisible private static fflib_SObjectUnitOfWork oppUOW = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Opportunity.SObjectType
        }
    );
    @TestVisible private static fflib_SObjectUnitOfWork commissionPaymentUOW = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Commission_Payment__c.SObjectType
        }
    );

    public List<String> validationErrors = new List<String>();
    private Opportunity opp;
    private List<Commission_Payment__c> commissionPayments;
    private String newCommissionStructureId;

    public InvocableCommissionStructureChanger(String opportunityId, String newCommissionStructureId) {
        this.opp = opportunitiesSelector.getOpportunityWithCommissionPayments(opportunityId);
        this.commissionPayments = opp.Commission_Payments__r;
        this.newCommissionStructureId = newCommissionStructureId;
        if (newCommissionStructureId == null) {
            throw new Util.BWException('newCommissionStructureId cannot be null!');
        }
    }

    @InvocableMethod(
        Label='Invocable Commission Structure Changer'
        Description='Modifies the Commission Structure on an Opportunity and adjusts Commission Payments where found')
    public static List<String> invokeCommissionStructureChange(List<CommissionChangeData> changeData) {
        InvocableCommissionStructureChanger worker = new InvocableCommissionStructureChanger(
            changeData[0].opportunityId, changeData[0].newCommissionStructureId
        );
        worker.execute();
        return worker.validationErrors;
    }

    public class CommissionChangeData {
        @InvocableVariable(Description='Opportunity to Process' Required=true)
        public String opportunityId;

        @InvocableVariable(Description='New Commission Structure Id' Required=true)
        public String newCommissionStructureId;
    }

    public void execute() {
        validate();
        if (!validationErrors.isEmpty()) {
            return;
        }
        updateOpportunity();
        if (!opp.Commission_Payments__r.isEmpty()) {
            if (featureService.isEnabled('New_Partner_Commission_Generator')) {
                PartnerCommissionCalculator calculator = new PartnerCommissionCalculator(opp.Id);
                calculator.calculate();
                commissionPaymentUOW.registerDirty(calculator.getUpsertList());
                commissionPaymentUOW.commitWork();
            } else {
                PartnerCommissionHandler.invokeCommissionStructureChange(new List<Id>{opp.Id});
            }
        }
    }

    private void validate() {
        if (!opp.IsWon) {
            validationErrors.add(INVALID_STAGE_ERROR);
            return;
        }
        for (Commission_Payment__c cp : commissionPayments) {
            if (cp.Status__c == 'Approved') {
                validationErrors.add(APPROVED_PAYMENTS_ERROR);
                break;
            }
        }
    }

    private void updateOpportunity() {
        opp.Commission_Structure__c = newCommissionStructureId;
        oppUOW.registerDirty(opp);
        oppUOW.commitWork();
    }

}