/**
 * Created by PeterYao on 4/4/2021.
 * Tested By: SubscriptionTransferServiceTest
 */

public with sharing class InvocableSubscriptionTransferer {
    private static SubscriptionTransferService subscriptionTransferService = new SubscriptionTransferService();
    @InvocableMethod(Label='InvocableSubscriptionTransferer' Description='Moves capacity from one UAS to another')
    public static void transferSubscription(List<Request> request) {
        subscriptionTransferService.transferToUAS(request[0].oldUASId, request[0].newUASId, request[0].amount);
    }

    public class Request {
        @InvocableVariable(Label='Old UAS Id')
        public Id oldUASId;
        @InvocableVariable(Label='New UAS Id')
        public Id newUASId;
        @InvocableVariable(Label='Amount, in kWh or Cost')
        public Decimal amount;
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Request() {
        }
    }

}