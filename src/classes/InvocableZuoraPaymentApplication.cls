/*
Tested By: InvocableZuoraActionsTest
*/

public class InvocableZuoraPaymentApplication {
    @InvocableMethod(label='ZuoraPaymentApplication')
    public static void paymentApplication(){
        ZuoraPaymentService.getAndApplyPaymentsWithUnappliedBalance();
    }
}