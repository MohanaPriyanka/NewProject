@isTest
private class AmortizationEmailTest {

    static testMethod void myUnitTest() {
        AmortizationEmail amEmail = new AmortizationEmail();
        Account a = new Account();
        a.Name = 'Test Account';
        try{
        	insert a;
	        List<RecordType> rtl = [select id from RecordType where name = 'BFG - Solar Loan'];
	        if(rtl.size()==0){
	        	rtl = [select id from RecordType limit 1];
	        }
	        Opportunity op = new Opportunity();
	        if(rtl.size()>0)
	        	op.RecordTypeID = rtl[0].id;
	        op.Name = 'Test Opportunity';
	        op.StageName = 'New';
	        op.CloseDate = Date.today();
	        op.AccountID = a.id;
	        op.Email__c = 'test@test.com';
	        insert op;
	        try{
	        	AmortizationEmail.sendEmail(op.id, op.Email__c);
	        }catch(Exception ex){
	        	system.debug(ex);
	        }
	        Blob content = Blob.toPdf('Hello');
	        amEmail.sendEmail2(op.Email__c, content);
        }catch(Exception e){
        	system.debug(e);
        }
    }
}