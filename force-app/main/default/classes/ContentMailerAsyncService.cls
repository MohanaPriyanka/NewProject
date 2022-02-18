/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 * Description: Used to start the chained queueable to send content, and also by the ContentMailerService to
 *  requeue itself if there's more content than will fit in a single package
 * Test: ContentMailerServiceTest
 *************************************************************************************/

public with sharing class ContentMailerAsyncService implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private ContentMailerService contentMailerService = new ContentMailerService();

    public ContentMailerAsyncService(List<ContentMailerService.Param> contentToSend) {
        contentMailerService.remainingContentToSend = contentToSend;
    }

    public void execute(QueueableContext context) {
        try {
            contentMailerService.mailContent();
        } catch (Exception e) {
            Logger.logLater(
                'ContentMailerAsyncService',
                'execute',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + contentMailerService.remainingContentToSend,
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }
}