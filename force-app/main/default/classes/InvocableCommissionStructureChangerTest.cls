@IsTest
public class InvocableCommissionStructureChangerTest {

    @IsTest
    public static void testWithBadOpportunityStage() {
        Opportunity opp = getOpp(false, true);
        UniversalMocker oppSelectorMock = UniversalMocker.mock(OpportunitiesSelector.class);
        oppSelectorMock.when('getOpportunityWithCommissionPayments').thenReturn(opp);

        UniversalMocker uowMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        InvocableCommissionStructureChanger.opportunitiesSelector = (OpportunitiesSelector) oppSelectorMock.createStub();
        InvocableCommissionStructureChanger.oppUOW = (fflib_SObjectUnitOfWork) uowMock.createStub();

        InvocableCommissionStructureChanger.CommissionChangeData changeData =
            new InvocableCommissionStructureChanger.CommissionChangeData();
        changeData.opportunityId = opp.Id;
        changeData.newCommissionStructureId = Util.getFakeId(Commission_Structure__c.SObjectType);

        List<String> validationErrors = InvocableCommissionStructureChanger.invokeCommissionStructureChange(
            new List<InvocableCommissionStructureChanger.CommissionChangeData>{
                changeData
            });

        System.assert(validationErrors.contains(InvocableCommissionStructureChanger.INVALID_STAGE_ERROR),
            'The opportunity stage of IsWon = false should prevent commission structure change');
        uowMock.assertThat().method('commitWork').wasNeverCalled();
    }

    @IsTest
    public static void testWithApprovedCommissionPayment() {
        Opportunity opp = getOpp(true, true);
        UniversalMocker oppSelectorMock = UniversalMocker.mock(OpportunitiesSelector.class);
        oppSelectorMock.when('getOpportunityWithCommissionPayments').thenReturn(opp);

        UniversalMocker uowMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        InvocableCommissionStructureChanger.opportunitiesSelector = (OpportunitiesSelector) oppSelectorMock.createStub();
        InvocableCommissionStructureChanger.oppUOW = (fflib_SObjectUnitOfWork) uowMock.createStub();

        InvocableCommissionStructureChanger.CommissionChangeData changeData =
            new InvocableCommissionStructureChanger.CommissionChangeData();
        changeData.opportunityId = opp.Id;
        changeData.newCommissionStructureId = Util.getFakeId(Commission_Structure__c.SObjectType);

        List<String> validationErrors = InvocableCommissionStructureChanger.invokeCommissionStructureChange(
            new List<InvocableCommissionStructureChanger.CommissionChangeData>{
                changeData
            });

        System.assert(validationErrors.contains(InvocableCommissionStructureChanger.APPROVED_PAYMENTS_ERROR),
            'Approved commission payments should have been found, preventing commission structure change');
        uowMock.assertThat().method('commitWork').wasNeverCalled();
    }

    @IsTest
    public static void testCommissionRecalculation() {
        FeatureService.Mock mockFeatureService = new FeatureService.Mock(new Map<String,Boolean>{
            'New_Partner_Commission_Generator' => true
        });
        InvocableCommissionStructureChanger.featureService = (FeatureService)
            Test.createStub(FeatureService.class, mockFeatureService);
        Opportunity opp = getOpp(true, false);
        UniversalMocker oppSelectorMock = UniversalMocker.mock(OpportunitiesSelector.class);
        oppSelectorMock.when('getOpportunityWithCommissionPayments').thenReturn(opp);

        UniversalMocker oppUOWMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        UniversalMocker paymentUOWMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        InvocableCommissionStructureChanger.opportunitiesSelector = (OpportunitiesSelector) oppSelectorMock.createStub();
        InvocableCommissionStructureChanger.oppUOW = (fflib_SObjectUnitOfWork) oppUOWMock.createStub();
        InvocableCommissionStructureChanger.commissionPaymentUOW = (fflib_SObjectUnitOfWork) paymentUOWMock.createStub();

        InvocableCommissionStructureChanger.CommissionChangeData changeData =
            new InvocableCommissionStructureChanger.CommissionChangeData();
        changeData.opportunityId = opp.Id;
        changeData.newCommissionStructureId = Util.getFakeId(Commission_Structure__c.SObjectType);

        UniversalMocker paymentSelector = UniversalMocker.mock(CommissionPaymentSelector.class);
        paymentSelector.when('getWithSubscriptionOrdersBySingleOpp').thenReturn(getCommissionPayments());
        PartnerCommissionCalculator.paymentSelector = (CommissionPaymentSelector) paymentSelector.createStub();

        List<String> validationErrors = InvocableCommissionStructureChanger.invokeCommissionStructureChange(
            new List<InvocableCommissionStructureChanger.CommissionChangeData>{
                changeData
            });

        System.assert(validationErrors.isEmpty(), 'No validation errors should be present when trying to change structure');
        oppUOWMock.assertThat().method('commitWork').wasCalled(1);
        paymentUOWMock.assertThat().method('commitWork').wasCalled(1);

        List<Commission_Payment__c> payments = (List<Commission_Payment__c>)
            paymentUOWMock.forMethod('registerDirty').andInvocationNumber(0).getValueOf('records');
        Commission_Payment__c updatedCommissionPayment = payments[0];
        System.assertEquals(1000, updatedCommissionPayment.Amount_Due__c, 'Amount due should reflect SOs');
        System.assertEquals(500, updatedCommissionPayment.Contract_Execution_Amount__c, 'Contract ex due should reflect SOs');
        System.assertEquals(250, updatedCommissionPayment.First_Bill_Sent_Amount__c, 'First bill sent due should reflect SOs');
        System.assertEquals(250, updatedCommissionPayment.First_Bill_Paid_Amount__c, 'First bill paid due due should reflect SOs');
    }

    private static Opportunity getOpp(Boolean isWon, Boolean withApprovedPayment) {
        sfab_FabricatedSObject commissionPayment = new sfab_FabricatedSObject(Commission_Payment__c.class);
        commissionPayment.setField(Commission_Payment__c.Status__c, withApprovedPayment == true ? 'Approved' : 'Pending Approval');

        sfab_FabricatedSObject opp = new sfab_FabricatedSObject(Opportunity.class);
        opp.setField(Opportunity.Id, Util.getFakeId(Opportunity.SObjectType));
        opp.setField(Opportunity.IsWon, isWon);
        opp.setChildren('Commission_Payments__r', new List<sfab_FabricatedSObject>{
            commissionPayment
        });

        return (Opportunity) opp.toSObject();
    }

    private static List<Commission_Payment__c> getCommissionPayments() {
        sfab_FabricatedSObject commissionPayment = new sfab_FabricatedSObject(Commission_Payment__c.class);
        commissionPayment.setField(Commission_Payment__c.Amount_Due__c, 500);
        commissionPayment.setField(Commission_Payment__c.Contract_Execution_Amount__c, 400);
        commissionPayment.setField(Commission_Payment__c.First_Bill_Sent_Amount__c, 50);
        commissionPayment.setField(Commission_Payment__c.First_Bill_Paid_Amount__c, 50);

        sfab_FabricatedSObject subscriptionOrder = new sfab_FabricatedSObject(Subscription_Order__c.class);
        subscriptionOrder.setField(Subscription_Order__c.Id, Util.getFakeId(Subscription_Order__c.SObjectType));
        subscriptionOrder.setField(Subscription_Order__c.Contract_Close_Estimated_Commission__c, 500);
        subscriptionOrder.setField(Subscription_Order__c.First_Bill_Paid_Estimated_Commission__c, 250);
        subscriptionOrder.setField(Subscription_Order__c.First_Bill_Sent_Estimated_Commission__c, 250);

        commissionPayment.setChildren('Subscription_Orders__r', new List<sfab_FabricatedSObject>{subscriptionOrder});
        commissionPayment.setChildren('First_Bill_Subscription_Orders__r', new List<sfab_FabricatedSObject>{subscriptionOrder});
        commissionPayment.setChildren('First_Bill_Paid_Subscription_Orders__r', new List<sfab_FabricatedSObject>{subscriptionOrder});

        return new List<Commission_Payment__c>{
            (Commission_Payment__c) commissionPayment.toSObject()
        };
    }
}