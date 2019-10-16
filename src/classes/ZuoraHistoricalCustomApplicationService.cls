/**
 * Created by PeterYao on 10/14/2019.
 * Tested By: ZuoraHistoricalCustomApplicationTest
 */

public with sharing class ZuoraHistoricalCustomApplicationService {
    public static Map<Id, String> transactionIdToCustomerName = new Map<Id, String>{
        'a210a00000GkIXgAAN' => 'NNF',
        'a210a00000AnnHTAAZ' => 'Stelios',
        'a210a0000010tTCAAY' => 'YongShing'
    };

    public static void customApplication(Id transactionId, List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        switch on transactionIdToCustomerName.get(transactionId) {
            when 'NNF' {
                applyNNF(outstandingItems, itemsToApply);
            } when 'Stelios' {
                applyStelios(outstandingItems, itemsToApply);
            } when 'YongShing' {
                applyYongShing(outstandingItems, itemsToApply);
            }
        }
    }

    @TestVisible
    private static void applyNNF(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        for (ZuoraOutstandingItemsService.OutstandingItem oi : outstandingItems) {
            checkAndSetOutstandingItem(oi, Date.newInstance(2018, 6, 15), 'SSS-000021', 209.20, 0, 0);
            checkAndSetOutstandingItem(oi, Date.newInstance(2018, 6, 15), 'SSS-000017', 209.20, 209.20, 209.20);
        }
        for (ZuoraOutstandingItemsService.OutstandingItem applyItem : itemsToApply) {
            checkAndSetApplyItem(applyItem, Date.newInstance(2018, 6, 15), 'SSS-000021', 1.15, 210.35);
            checkAndSetApplyItem(applyItem, Date.newInstance(2018, 6, 15), 'SSS-000017', 216.50, 7.30);
        }
    }

    @TestVisible
    private static void applyStelios(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        for (ZuoraOutstandingItemsService.OutstandingItem oi : outstandingItems) {
            checkAndSetOutstandingItem(oi, Date.newInstance(2017, 5, 15), 'SSS-000019', 165.06, 37.13, 0);
            checkAndSetOutstandingItem(oi, Date.newInstance(2017, 5, 15), 'SSS-000020', 59.12, 37.14, 38.49);
            checkAndSetOutstandingItem(oi, Date.newInstance(2017, 5, 15), 'SSS-000021', 122.62, 37.13, 122.62, itemsToApply);
            checkAndSetOutstandingItem(oi, Date.newInstance(2017, 5, 15), 'SSS-000016', 109.91, 37.15, 109.91, itemsToApply);
            checkAndSetOutstandingItem(oi, Date.newInstance(2017, 5, 15), 'SSS-000017', 105.26, 37.14, 105.26, itemsToApply);
        }
        for (ZuoraOutstandingItemsService.OutstandingItem applyItem : itemsToApply) {
            checkAndSetApplyItem(applyItem, Date.newInstance(2017, 5, 15), 'SSS-000019', 37.13, 165.06);
            checkAndSetApplyItem(applyItem, Date.newInstance(2017, 5, 15), 'SSS-000020', 37.14, 20.63);
        }
    }

    @TestVisible
    private static void applyYongShing(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        for (ZuoraOutstandingItemsService.OutstandingItem oi : outstandingItems) {
            checkAndSetOutstandingItem(oi, Date.newInstance(2018, 6, 15), 'SSS-000017', 212.59, 0, 212.59);
            checkAndSetOutstandingItem(oi, Date.newInstance(2018, 6, 15), 'SSS-000019', 307.41, 0, 14.56);
            checkAndSetOutstandingItem(oi, Date.newInstance(2018, 6, 15), 'SSS-000016', 231.79, 227.15, 0);
        }
        for (ZuoraOutstandingItemsService.OutstandingItem applyItem : itemsToApply) {
            checkAndSetApplyItem(applyItem, Date.newInstance(2018, 6, 15), 'SSS-000017', 0, 212.59);
            checkAndSetApplyItem(applyItem, Date.newInstance(2018, 6, 15), 'SSS-000019', 0, 14.56);
            checkAndSetApplyItem(applyItem, Date.newInstance(2018, 6, 15), 'SSS-000016', 227.15, 231.79);
        }
    }

    @TestVisible
    private static void checkAndSetOutstandingItem(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
        Date effectiveDate, String project, Decimal startingAmount, Decimal applicationAmount, Decimal expectedAmount) {
        checkAndSetOutstandingItem(outstandingItem, effectiveDate, project, startingAmount, applicationAmount, expectedAmount, null);
    }

    @TestVisible
    private static void checkAndSetOutstandingItem(ZuoraOutstandingItemsService.OutstandingItem outstandingItem,
        Date effectiveDate, String project, Decimal startingAmount, Decimal applicationAmount, Decimal expectedAmount, List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply) {
        if (outstandingItem.EffectiveDate == effectiveDate && outstandingItem.Project == project) {
            if (outstandingItem.AmountOutstanding == expectedAmount) {
                outstandingItem.AmountOutstanding = startingAmount - applicationAmount;
                if (itemsToApply != null) {
                    ZuoraOutstandingItemsService.OutstandingItem newApplyItem = outstandingItem.clone();
                    newApplyItem.AmountToApply = applicationAmount;
                    itemsToApply.add(newApplyItem);
                }
            } else {
                Logger.logLater(
                    'ZuoraHistoricalApplicationService',
                    'custom applyPayment',
                    'Expected ' + project + ' to have '+ expectedAmount +' outstanding' + '\n' + JSON.serialize(outstandingItem),
                    Logger.ERROR
                );
            }
        }
    }

    @TestVisible
    private static void checkAndSetApplyItem(ZuoraOutstandingItemsService.OutstandingItem applyItem,
        Date effectiveDate, String project, Decimal amountToApply, Decimal expectedAmount) {
        if (applyItem.EffectiveDate == effectiveDate && applyItem.Project == project) {
            if (applyItem.AmountToApply == expectedAmount) {
                applyItem.AmountToApply = amountToApply;
            } else {
                Logger.logLater(
                    'ZuoraHistoricalApplicationService',
                    'custom applyPayment',
                    'Expected ' + project + ' to have ' + expectedAmount + ' applied' + '\n' + JSON.serialize(applyItem),
                    Logger.ERROR);
            }
        }
    }
}