/*************************************************************************************
 * Created By: peteryao on 10/24/19  
 * Description: Promotes User Stories to production on schedule.
 * Test: UserStoryPromoterTest
 *************************************************************************************/

public without sharing class UserStoryPromoter implements Schedulable {
    @TestVisible
    private CopadoSelector copadoSelector = new CopadoSelector();
    @TestVisible
    private CopadoService copadoService = new CopadoService();

    private Id sourceEnv;
    private Id sourceCredential;
    private Id project;

    public void execute(SchedulableContext context) {
        try {
            createPromotionFromStories();
        } catch (Exception e) {
            Logger.logNow('UserStoryPromoter', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    public void createPromotionFromStories() {
        List<copado__User_Story__c> storiesToPromote = new List<copado__User_Story__c>();
        for (copado__User_Story__c userStory : copadoSelector.getUserStoriesToPromote()) {
            if (userStory.copado__Promoted_User_Stories__r.size() == 0) {
                addStoryToPromotionList(userStory, storiesToPromote);
            }
        }
        if (storiesToPromote.isEmpty()) {
            return;
        }
        copado__Promotion__c promotion = createPromotion();
        String testLevel = addStoriesToPromotion(storiesToPromote, promotion);

        String apiKey = Util.getSystemPropertyString('Copado_API_Key__c');
        String endpoint ='https://copado.herokuapp.com/json/v1/webhook/promotions/' + promotion.Id + '/process?' +
            'testLevel='+testLevel+'&' +
            'api_key='+apiKey+'&' +
            'deploymentName='+promotion.Name+'+to+prod+via+Apex';
        UserStoryPromoter.startPromotion(endpoint);
        Logger.flushLogs();
    }

    @TestVisible
    private String addStoriesToPromotion(List<copado__User_Story__c> storiesToPromote, copado__Promotion__c promotion) {
        String testLevel = 'NoTestRun';
        List<copado__Promoted_User_Story__c> promotedUserStories = new List<copado__Promoted_User_Story__c>();
        for (copado__User_Story__c userStory : storiesToPromote) {
            copado__Promoted_User_Story__c promotedUserStory = new copado__Promoted_User_Story__c(
                copado__Promotion__c = promotion.Id,
                copado__User_Story__c = userStory.Id
            );
            promotedUserStories.add(promotedUserStory);
            if (userStory.copado__Promotion_Test_Level__c == 'RunSpecifiedTests') {
                testLevel = 'RunSpecifiedTests';
            }
        }
        copadoService.insertPromotedUserStories(promotedUserStories);
        return testLevel;
    }

    @TestVisible
    private copado__Promotion__c createPromotion() {
        copado__Environment__c productionEnv = copadoSelector.getProductionEnvironment();
        copado__Org__c productionCredential = copadoSelector.getDefaultCredential(productionEnv.Id);
        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = project,
            copado__Source_Environment__c = sourceEnv,
            copado__Source_Org_Credential__c = sourceCredential,
            copado__Destination_Environment__c = productionEnv.Id,
            copado__Destination_Org_Credential__c = productionCredential.Id,
            copado__Send_Deployment_Complete_email__c = true
        );
        promotion = copadoService.insertPromotion(promotion);
        return promotion;
    }

    @TestVisible
    private void addStoryToPromotionList(copado__User_Story__c userStory, List<copado__User_Story__c> storiesToPromote) {
        if (sourceEnv == null) {
            sourceEnv = userStory.copado__Environment__c;
            sourceCredential = userStory.copado__Org_Credential__c;
            project = userStory.copado__Project__c;
        } else if (sourceEnv != userStory.copado__Environment__c ||
            sourceCredential != userStory.copado__Org_Credential__c ||
            project != userStory.copado__Project__c) {
            Logger.logLater(
                'UserStoryPromoter',
                'createPromotionFromStories',
                'Skipping ' + userStory.Name + ' because it has an unexpected source environment or project',
                Logger.ERROR
            );
            return;
        }
        Logger.logLater(
            'UserStoryPromoter',
            'createPromotionFromStories',
            'Adding to promotion list, ' + userStory.Name + ': ' + userStory.copado__User_Story_Title__c,
            Logger.INFO
        );
        storiesToPromote.add(userStory);
    }

    @Future(Callout=true)
    public static void startPromotion(String url) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(url);
        Logger.logLater('UserStoryPromoter', 'startPromotion', url, Logger.FINE);
        HttpResponse response = new Http().send(request);
        WebhookResponse webhookResponse = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
        Logger.logLater('UserStoryPromoter', 'startPromotion', response.getBody(), Logger.FINE);
        if (webhookResponse.error != null) {
            Logger.logLater('UserStoryPromoter', 'startPromotion', response.getBody(), Logger.ERROR);
        }
        Logger.flushLogs();
    }

    public class WebhookResponse {
        public String ok;
        public String copadoJobId;
        public String status;
        public Boolean isFinished;
        public String error;
    }
}