/* Created by Jordan Pentaleri on 2/11/19
Tested by: TestBillCreationandPayment
*/

public class InvocableCSBillOverpaymentApplication {

    @InvocableMethod(   label='OverpaymentApplication'
                        description='Once bills are done generating, applies overpayments and adjustments')
    public static void applyOverpayments(){
        OverpaymentApplication.triggerApplication();
    }
}