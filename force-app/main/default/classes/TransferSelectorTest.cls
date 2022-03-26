/**
 * Created by SarahRenfro on 10/10/2019.
 */
@IsTest
public class TransferSelectorTest {
    @IsTest
    static void testQueryTransfer() {
        Date todaysDate = Date.today();
        TransferSelector.getTransfersByMonth(todaysDate.month(), todaysDate.year());
        new TransferSelector().getAllTransfersById(new List<Id>());
        new TransferSelector().getAllTransfersById(new Set<Id>());
        System.assert(true, 'getTransfersByMonth, getTransfersById(list), getTransferById(set) ran without exception');
    }
    @IsTest
    static void testGetTransferById() {
        TransferSelector.getAllTransfersBySSS(new List<Id>());
        new TransferSelector().getTransferById(Util.getFakeId(Transfer__c.SObjectType));
        System.assert(true, 'getAllTransfersBySSS and getTransferById ran without exception');
    }
    @IsTest
    static void testGetTransfersForBillPeriods() {
        TransferSelector.getTransfersForBillPeriods(new Set<Id>());
        System.assert(true, 'getTransfersForBillPeriods ran without exception');
    }
    @IsTest
    static void testGetAllTransferByBillPeriod() {
        TransferSelector.getAllTransfersByBillPeriod(new Set<Id>());
        System.assert(true, 'getAllTransfersByBillPeriod ran without exception');
    }
    @IsTest
    static void testSSSWithoutTransfers() {
        SharedSolarSystemsSelector.getAllSSSWithTransfersNotInList(null);
        System.assert(true, 'getAllSSSWithTransfersNotInList ran without exception');
    }
    @IsTest
    static void testGetUnbilledTransfersBySSS() {
       new TransferSelector().getUnbilledTransfersBySSS(new Set<Id>());
        System.assert(true, 'getUnbilledTransfersBySSS ran without exception');
    }
}