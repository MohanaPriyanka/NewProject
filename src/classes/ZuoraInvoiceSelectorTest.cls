/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraInvoiceSelectorTest {
    @IsTest
    public static void testSelectForDownload() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());

        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c(
            Zuora__Zuora_Id__c = '12345'
        );
        insert zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(1, zInvoices.size());

        zInvoice.Downloaded_Date__c = System.today();
        update zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());
    }

    @IsTest
    public static void testSelectForDate() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());

        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12345',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        insert zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(1, zInvoices.size());

        zInvoice.Zuora__InvoiceDate__c = Date.newInstance(2019,01,01);
        update zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(0, zInvoices.size());
    }

    @IsTest
    public static void testBalanceOutstandingByAccount() {
        Account newSFAccountOne = new Account(
            Name = 'Account One',
            Recurring_Billing__c = false
        );
        Account newSFAccountTwo = new Account(
            Name = 'Account Two',
            Recurring_Billing__c = false
        );

        insert new List<Account>{newSFAccountOne, newSFAccountTwo};

        Zuora__CustomerAccount__c newZuoraAccountOne = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountOne.Id,
            Zuora__Zuora_Id__c = '222222222222222222222',
            Zuora__AutoPay__c = false
        );
        Zuora__CustomerAccount__c newZuoraAccountTwo = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccountTwo.Id,
            Zuora__Zuora_Id__c = '333333333333333333333',
            Zuora__AutoPay__c = false
        );

        List<Zuora__CustomerAccount__c> zAccounts = new List<Zuora__CustomerAccount__c>{newZuoraAccountOne, newZuoraAccountTwo};
        insert zAccounts;

        String queryStringWithAccounts = ZuoraInvoiceSelector.getOutstandingBalanceByAccountQuery(zAccounts);
        System.assert(queryStringWithAccounts.contains('222222222222222222222'));
        System.assert(queryStringWithAccounts.contains('333333333333333333333'));
        System.assert(queryStringWithAccounts.contains('Id ='));

        String queryStringNoAccounts = ZuoraInvoiceSelector.getOutstandingBalanceByAccountQuery(null);
        System.assert(!queryStringNoAccounts.contains('222222222222222222222'));
        System.assert(!queryStringNoAccounts.contains('333333333333333333333'));
        System.assert(!queryStringNoAccounts.contains('Id ='));
    }

    @IsTest
    public static void testInvoiceSummary() {
        Date billDate = Date.newInstance(2019,04,20);

        Zuora__ZInvoice__c zInvoiceOne = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12345',
            Ready_For_Email_Send__c = true,
            Zuora__InvoiceDate__c = billDate
        );
        insert zInvoiceOne;

        Zuora__ZInvoice__c zInvoiceTwo = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12346',
            Ready_For_Email_Send__c = true,
            Zuora__InvoiceDate__c = billDate
        );
        insert zInvoiceTwo;

        Zuora__ZInvoice__c zInvoiceThree = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12347',
            Ready_For_Email_Send__c = false,
            Zuora__InvoiceDate__c = billDate
        );
        insert zInvoiceThree;

        List<AggregateResult> aggResult = ZuoraInvoiceSelector.getInvoiceSummary(billDate.addDays(-3));
        Integer invoiceCount;

        for (AggregateResult aggregateResult : aggResult)  {
            if((Boolean)aggregateResult.get('Ready_For_Email_Send__c')){
                invoiceCount = (Integer)aggregateResult.get('numberOfRecords');
            }
        }
        System.assertEquals(2,invoiceCount);
    }

    @IsTest
    public static void testInvoiceQuery(){
        Date startDate = Date.newInstance(2019,10,02);
        Date endDate = Date.newInstance(2019,10,07);

        String queryString = ZuoraInvoiceSelector.getInvoiceTotalQuery(startDate,endDate);
        system.assert(queryString.contains('2019-10-02'));
        system.assert(queryString.contains('2019-10-07'));
    }

    @IsTest
    private static void testGetLatestDueDateForAutopayAccounts() {
        String query = ZuoraInvoiceSelector.getLatestDueDateForAutopayAccounts();
        String dateString = query.right(11).left(10);
        Boolean caughtException = false;
        try {
            Date dt = Date.valueOf(dateString);
            Date today = System.today();
            System.assertEquals(dt, Date.newInstance(today.year(), today.month()-1, today.day()), 'Expected query to include due dates greater than today');
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException, 'Expected to find a valid date string: ' + dateString);
    }
}