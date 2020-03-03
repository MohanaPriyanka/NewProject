// Tested By: ZuoraUsageSelectorTest
// 2.24.20: Apex Heap Limit / CPU Timeout occurs ~3,500 usage rows so these queries should be limited to return
// less than that amount.

public inherited sharing class ZuoraUsageSelector {
    public String selectStatement = 'SELECT ' +
        'rp.Project__c as Project, ' +
        'rp.ClientOwner__c as Client, ' +
        'us.id as ExternalId, ' +
        'us.startdatetime as BillDatetime, ' +
        'us.crm_id__c as InternalId, ' +
        'us.accountnumber as CustomerNumber, ' +
        'us.quantity as Amount ' +
        'FROM USAGE us ';

    public String joinStatements = 'INNER JOIN RatePlanCharge rp ON us.rateplanchargeid = rp.Id ';
    public String orderByDate = 'ORDER BY us.startdatetime ';

    public String getUsageQueryStringFilterByAccountAndDate(Set<String> accountIds, Date startDate, Date endDate) {
        String queryString = selectStatement + joinStatements + 'WHERE ';
        queryString += getAccountFilter(accountIds);
        queryString += 'AND ';
        queryString += getDateFilter(startDate, endDate);
        queryString += orderByDate;
        return queryString;
    }

    public String getAccountFilter(Set<String> accountIds) {
        String accountFilter = '(';
        Integer count = 0;
        for (String accountId : accountIds){
            if (count != 0){
                accountFilter += 'OR ';
            }
            accountFilter += 'us.accountnumber = \'' + accountId + '\' ';
            count ++;
        }
        accountFilter += ') ';
        return accountFilter;
    }

    public String getDateFilter(Date startDate, Date endDate) {
        String queryString = '';
        //Midnight on the 1st of the month to midnight of the first of the following month:
        Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),01);
        Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month() + 1,01);
        queryString += '(us.startdatetime > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
        queryString += ' AND us.startdatetime < TIMESTAMP \'' + String.valueOf(endTime)+ '\') ';
        return queryString;
    }
}