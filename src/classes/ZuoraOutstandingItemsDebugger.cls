/**
 * Created by PeterYao on 7/29/2019.
 * Tested By: ZuoraOutstandingItemsDebuggerTest
 */

public with sharing class ZuoraOutstandingItemsDebugger implements ZuoraOutstandingItemsService.Processor {

    public void processOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        Logger.logNow('ZuoraOutstandingItemsDebugger', 'outstandingItems', JSON.serializePretty(outstandingItems));
        Logger.logNow('ZuoraOutstandingItemsDebugger', 'processingParameter', JSON.serializePretty(processingParameter));
    }
}