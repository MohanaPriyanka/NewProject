/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020  
 * Test: ContentDocLinkPrivacySchedulerTest
 *************************************************************************************/

 public without sharing class ContentDocLinkPrivacyScheduler implements Schedulable{
    
    public Datetime dt1;
    public Datetime dt2;

    public ContentDocLinkPrivacyScheduler() {
        this.dt1 = Datetime.now().addDays(-60);
        this.dt2 = Datetime.now().addDays(-10);
    }

    public ContentDocLinkPrivacyScheduler(Integer daysAgo1, Integer daysAgo2) {
        this.dt1 = daysAgo1 == daysAgo2 ? Datetime.newInstance(Date.today().addDays(daysAgo1), Time.newInstance(0, 0, 0, 0)) : Datetime.now().addDays(daysAgo1*-1);
        this.dt2 = daysAgo1 == daysAgo2 ? Datetime.newInstance(Date.today().addDays(daysAgo2), Time.newInstance(23, 59, 59, 999)) : Datetime.now().addDays(daysAgo2*-1);
    }

    public ContentDocLinkPrivacyScheduler(Date date1, Date date2) {
        this.dt1 = date1 == date2 ? Datetime.newInstance(date1, Time.newInstance(0, 0, 0, 0)) : Datetime.newInstance(date1, Datetime.now().time());
        this.dt2 = date1 == date2 ? Datetime.newInstance(date2, Time.newInstance(23, 59, 59, 999)) : Datetime.newInstance(date2, Datetime.now().time());
    }

    public ContentDocLinkPrivacyScheduler(Datetime datetime1, Datetime datetime2) {
        this.dt1 = datetime1;
        this.dt2 = datetime2;
    }


    public void execute(SchedulableContext sc) {
        ContentDocumentSelector selector = new ContentDocumentSelector();
        ContentService service = new ContentService();
        service.makeContentDocLinksPrivate(selector.getDocsCreatedWithinRange(dt1, dt2));
    }
}