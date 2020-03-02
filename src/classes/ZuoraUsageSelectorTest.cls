@IsTest
public with sharing class ZuoraUsageSelectorTest {
    @IsTest
    public static void testOther(){
        Date startDate = Date.newInstance(2017,05,14);
        Date endDate = Date.newInstance(2017,06,13);
        Set<String> accountIds = new Set<String>();
        accountIds.add('BW-0001234');
        accountIds.add('BW-0006666');
        ZuoraUsageSelector selector = new ZuoraUsageSelector();
        String queryString = selector.getUsageQueryStringFilterByAccountAndDate(accountIds,startDate,endDate);

        System.assert(queryString.contains('us.quantity as Amount FROM USAGE us'));
        System.assert(queryString.contains('WHERE (us.accountnumber = \'BW-0001234\' OR us.accountnumber = \'BW-0006666\' )'));
        System.assert(queryString.contains('AND (us.startdatetime > TIMESTAMP \'2017-05-01 00:00:00\' AND us.startdatetime < TIMESTAMP \'2017-07-01 00:00:00\''));
    }
}