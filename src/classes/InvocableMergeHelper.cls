/**
 * Created by peteryao on 7/27/20.
 * Tested By: MergeHelperTest
 */

public without sharing class InvocableMergeHelper {
    @TestVisible
    private static MergeHelper mergeHelper = new MergeHelper();

    @InvocableMethod(Label='Invocable Merge Helper' Description='Deletes the related Zuora Account (if any, if it does not yet have a subscription, and updates the Account Name in Salesforce with "dupe"')
    public static void prepForMerge(List<Id> propertyAccountIdsToPrep) {
        if (propertyAccountIdsToPrep.size() != 1) {
            throw new Util.BWException('Only one account supported right now');
        }
        try {
            mergeHelper.prepForMerge(propertyAccountIdsToPrep[0]);
        } catch (Exception e) {
            throw new Util.BWException(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}