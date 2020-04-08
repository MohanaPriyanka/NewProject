/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020  
 * Test: ContentDocLinkPrivacySchedulerTest
 *************************************************************************************/

 public without sharing class ContentDocLinkPrivacyScheduler implements Schedulable{
    @TestVisible private ContentDocumentSelector selector = new ContentDocumentSelector();
    @TestVisible private ContentService service = new ContentService();
    
    public void execute(SchedulableContext sc) {
        try {
            service.makeContentDocLinksPrivate(selector.getLeadDocsCreatedWithinRange(Datetime.now().addDays(-60), Datetime.now().addDays(-10)));
        } catch(Exception ex) {
            Logger.logNow('ContentDocLinkPrivacyScheduler', 'execute', ex.getMessage() + '\n' + ex.getStackTraceString(), Logger.ERROR);
        }
    }
    
}