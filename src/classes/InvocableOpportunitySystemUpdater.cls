/**
 * Created by PeterYao on 4/1/2021.
 * Tested By: SubscriptionTransferServiceTest
 */

public with sharing class InvocableOpportunitySystemUpdater {
    private static SubscriptionTransferService subscriptionTransferService = new SubscriptionTransferService();
    @InvocableMethod(Label='InvocableOpportunitySystemUpdater' Description='Changes SSS on Opportunity via new UAS and SOs')
    public static List<Request> changeSystem(List<Request> request) {
        return subscriptionTransferService.changeOpportunitySSS(request[0].opportunityId, request[0].sssId);
    }

    public class Request {
        @InvocableVariable(Label='Opportunity Id')
        public Id opportunityId;
        @InvocableVariable(Label='SSS Id')
        public Id sssId;
        @InvocableVariable(Label='Is Success')
        public Boolean isSuccess;
        @InvocableVariable(Label='Error Message')
        public String errorMessage;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Request() {
        }
    }
}