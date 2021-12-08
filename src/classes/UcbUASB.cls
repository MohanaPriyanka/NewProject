/**
 * @description Created by jeff parlin on 3/1/21.
 *
 * Tested By: TransferSheetBillingTest
 */
public class UcbUASB extends UASB {

    private Default_Utility_Fee__c activeUtilityAdminFee;
    private UASB__c ucbPriorUASB;
    private UASB__c ucbParsedTransferUASB;

    /**
     * @description Class constructor for Standard UASB
     * @param szs Schedule Z Subscription, or Allocation Schedule record
     * @param transfer Transfer record
     * @param productEscalatorMap Map of Product Escalators to Apply to UASB, if needed
     * @param ucbPriorUASB Prior UASB__c record generated previously
     * @param ucbParsedTransferUASB UASB__c record generated via transfer .csv (provided by Utility)
     * @param utilityAdminFee Decimal corresponding to active utility Default Utility Fee record
     */
    public UcbUASB(
        Schedule_Z_Subscription__c szs,
        Transfer__c transfer,
        Map<Id,List<Product_Escalator__c>> productEscalatorMap,
        UASB__c ucbPriorUASB,
        UASB__c ucbParsedTransferUASB,
        Default_Utility_Fee__c utilityAdminFee)
    {
        super(szs, transfer, productEscalatorMap);
        this.ucbPriorUASB = ucbPriorUASB;
        this.ucbParsedTransferUASB = ucbParsedTransferUASB;
        this.activeUtilityAdminFee = utilityAdminFee;
    }

    /**
     * @description Creates the appropriate UASB record for the given inputs and situation
     */
    public override void createSObject() {
        super.createSObject();
        setUCBFields();
    }

    @TestVisible
    private void setUCBFields() {
        uasb.Billing_Method__c = 'UCB';
        uasb.Starting_Banked_Credits__c = getStartingBankedCredits();
        uasb.New_available_credits__c = uasb.Credits_Allocated__c;
        uasb.Total_Available_Credits__c = uasb.Starting_Banked_Credits__c + uasb.New_available_credits__c;
        uasb.Satellite_Charges__c = Util.nullToZero(ucbParsedTransferUASB?.Satellite_Charges__c);
        uasb.Calculated_Credits__c = Math.min(uasb.Total_Available_Credits__c, uasb.Satellite_Charges__c);
        uasb.Net_Member_Credits__c = (uasb.Calculated_Credits__c * uasb.NMC_Discount__c / 100)
            .setScale(productionDecimalRounding, DEFAULT_ROUND);
        uasb.Ending_Banked_Credits__c = uasb.Total_Available_Credits__c - uasb.Calculated_Credits__c;
        uasb.Discounted_Utility_Bill__c = uasb.Satellite_Charges__c - uasb.Net_Member_Credits__c;
        uasb.CDG_Subscription_Fee__c = uasb.Calculated_Credits__c - uasb.Net_Member_Credits__c;
        uasb.Utility_Admin_Fee__c = getUtilityAdminFee();
        uasb.CDG_Sponsor_Payment__c = uasb.CDG_Subscription_Fee__c - uasb.Utility_Admin_Fee__c;
        uasb.Satellite_Bill_Date__c = ucbParsedTransferUASB?.Satellite_Bill_Date__c;
    }

    /**
     * @description Get Starting_Banked_Credits__c value from last UCB UASB (only relevant in UCB scenario)
     * @return Decimal value corresponding to last UASB's ending banked credits field
     */
    private Decimal getStartingBankedCredits() {
        if (ucbPriorUASB == null) {
            return 0; // No prior UASB, likely first bill. Start banked credits at 0.
        }
        if (ucbPriorUASB.Ending_Banked_Credits__c == null) {
            throw new Util.BWException('Prior UASB for UCB Subscription ' + szs.Id +
                ' does not have any value for Ending_Banked_Credits__c ... '
            );
        }
        return ucbPriorUASB.Ending_Banked_Credits__c;
    }

    private Decimal getUtilityAdminFee() {
        Decimal utilityAdminFee = 0;
        if (activeUtilityAdminFee == null) {
            throw new Util.BWException('No Default_Utility_Fee__c record found for Utility ' +
                transfer.Shared_Solar_System__r.Utility__c + ' ... '
            );
        }
        switch on activeUtilityAdminFee.Method_for_UCB_Utility_Admin__c {
            when 'Calculated Credits' {
                utilityAdminFee = activeUtilityAdminFee.Utility_Admin_Fee__c / 100 * uasb.Calculated_Credits__c;
            }
            when 'CDG Subscription Fee' {
                utilityAdminFee = activeUtilityAdminFee.Utility_Admin_Fee__c / 100 * uasb.CDG_Subscription_Fee__c;
            }
        }
        return utilityAdminFee.setScale(productionDecimalRounding, DEFAULT_ROUND);
    }
}