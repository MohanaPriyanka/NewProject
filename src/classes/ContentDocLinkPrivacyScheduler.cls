/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020  
 * Test: ContentDocLinkPrivacySchedulerTest
 *************************************************************************************/

 public without sharing class ContentDocLinkPrivacyScheduler implements Schedulable{

    public void execute(SchedulableContext sc) {
        try {
            ContentDocumentSelector selector = new ContentDocumentSelector();
            ContentService service = new ContentService();
            service.makeContentDocLinksPrivate(selector.getLeadDocsCreatedWithinRange(Datetime.now().addDays(-60), Datetime.now().addDays(-10)));
        } catch(Exception ex) {
            Logger.logNow('ContentDocLinkPrivacyScheduler', 'execute', ex.getMessage() + '\n' + ex.getStackTraceString(), Logger.ERROR);
        }
    }
    
}