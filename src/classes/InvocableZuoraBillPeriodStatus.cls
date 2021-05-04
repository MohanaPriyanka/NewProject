/*
Tested By: InvocableZuoraActionsTest
*/

public class InvocableZuoraBillPeriodStatus {
    @InvocableMethod(Label='ZuoraBillPeriodStatus')
    public static List<Integer> billStatusUpdate(List<Date> invoiceDates){
        // Assuming only 1 Invoice Date is passed through, only make a list because of invocable limitations:
        Integer response = new BillPeriodService().markBillPeriodsAsBillRunComplete(invoiceDates[0]);
        return new List<Integer>{response};
    }
}