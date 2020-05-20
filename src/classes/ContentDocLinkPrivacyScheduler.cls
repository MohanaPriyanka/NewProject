/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020  
 * Test: ContentDocLinkPrivacySchedulerTest
 *************************************************************************************/

 public without sharing class ContentDocLinkPrivacyScheduler implements Schedulable{
    @TestVisible private ContentDocumentSelector selector = new ContentDocumentSelector();
    @TestVisible private ContentService service = new ContentService();
    public static Integer maxDaysInPast = -60;
    public static Integer minDaysInPast = -10;
    
    public void execute(SchedulableContext sc) {
        try {
            service.makeContentDocLinksPrivate(selector.getLeadDocsCreatedWithinRange(Datetime.now().addDays(maxDaysInPast), Datetime.now().addDays(minDaysInPast)));
        } catch(Exception ex) {
            Logger.logNow('ContentDocLinkPrivacyScheduler', 'execute', ex.getMessage() + '\n' + ex.getStackTraceString(), Logger.ERROR);
        }
    }
    
}