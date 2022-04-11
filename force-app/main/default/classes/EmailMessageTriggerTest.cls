/*
 * Created EmailMessageTriggerTest TestClass class for the following:
 * Apex classes- EmailMessageTriggerHandler,ReopenCaseOnEmail
 * Apex Trigger- EmailMessageTrigger
 * 
 */
@isTest
Public class EmailMessageTriggerTest {
    @isTest static void testUpdateClosedCaseEmailStatus() {
        
        Case c = new Case();
        c.Subject = 'Re Open'; 
        c.status='New Email Arrived';
        c.Resolution__c='Duplicate';
        insert c;
        c.status='Closed';
         update c;
       
        
        Test.startTest();
        List<EmailMessage> liem = new List<EmailMessage>();
        EmailMessage em = new EmailMessage();
        em.HtmlBody = 'test';
        em.subject = 'Re Open';
        em.RelatedToId = c.id;
        em.Incoming = true;
        liem.add(em);
        insert liem;  

        case cs = [select id,status from case where id =: c.id];        
        system.assertEquals(cs.status,'New Email Arrived');        
        Test.stopTest();
            
    }
     @isTest static void testUpdateNotClosedCaseEmailStatus() {
        
        Case c = new Case();
        c.Subject = 'Re Open'; 
        c.status='In Progress';
        c.Resolution__c='Duplicate';
        insert c;
        
        
        Test.startTest();
        List<EmailMessage> liem = new List<EmailMessage>();
        EmailMessage em = new EmailMessage();
        em.HtmlBody = 'test';
        em.subject = 'Re Open';
        em.RelatedToId = c.id;
        
        em.Incoming = True;
        liem.add(em);
        insert liem;  

        case cs = [select id,status from case where id =: c.id];        
        system.assertEquals(cs.status,'In Progress');        
        Test.stopTest();
            
    }
}