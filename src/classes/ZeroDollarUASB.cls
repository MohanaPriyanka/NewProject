/**
 * @description Created by jeff parlin on 3/1/21.
 * Can be removed with the elimination of the zero-dollar bill concept
 *
 * Tested By: TransferSheetBillingTest
 */
public class ZeroDollarUASB extends UASB {

    public ZeroDollarUASB(Schedule_Z_Subscription__c szs, Transfer__c transfer) {
        super(szs, transfer);
    }

    /**
     * @description Sets fields which are specific to this type of UASB. In this case, this is a "Zero-Dollar UASB"
     */
    public override void setSpecificFields() {
        uasb.Total_System_NMCs__c = 0;
        uasb.Total_System_Production_kWh__c = 0;
        uasb.Subscription_Production_kWh_Static__c = 0;
        uasb.NMC_Rate__c = 0;
        uasb.Share_of_System__c = 0;
        uasb.Credits_Allocated__c = 0;
    }
}