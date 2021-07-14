/**
 * Created by jeffparlin on 7/8/21.
 * @description Uses Marketing Cloud API to email Autopay customers with balances at a specified time to remind
 * them about their upcoming auto-payment
 * Tested By: ZuoraAutopayEmailerTest
 */
public without sharing class ZuoraAutopayEmailer implements Schedulable {

    @TestVisible private static final String MC_EVENT_KEY = 'APIEvent-7e12d0f4-1f3c-f499-ad4e-a6c5477cb479';
    @TestVisible private static final String CRON_EXP = '0 0 12 26-29 * ?'; // Run every month on days 26, 27, 28, 29 at noon
    public Boolean dryRun = false;
    public Date dateOverride;
    @TestVisible private List<MarketingJourneyEnrollmentDetail> enrollments;
    @TestVisible private ZuoraAccountSelector accountSelector = new ZuoraAccountSelector();
    private Date todaysDate;

    public static String scheduleJob() {
        return System.schedule('Zuora Autopay Emailer (Marketing Cloud API)', CRON_EXP, new ZuoraAutopayEmailer());
    }

    /**
     * @description Schedulable execution to get Zuora accounts on autopay with balances and push email-specific
     * data into Marketing Cloud via API (MarketingJourneyEnroller) so that customers receive personalized branded emails
     * @param context Schedulable context
     */
    public void execute(SchedulableContext context) {
        enrollments = new List<MarketingJourneyEnrollmentDetail>();
        todaysDate = dateOverride == null ? Date.today() : dateOverride;
        if (!shouldSendEmailsToday(todaysDate)) {
            return;
        }
        for (Zuora__CustomerAccount__c account : accountSelector.getAutopayAccountsWithBalanceForEmail()) {
            MarketingJourneyEnrollmentDetail enrollmentDetail = generateEnrollmentData(account);
            if (isValidEmailEnrollment(enrollmentDetail)) {
                enrollments.add(enrollmentDetail);
            } else {
                String message = 'Invalid email merge field data for autopay reminder email to Zuora Account ' + account.Id
                    + '\n\n' + JSON.serializePretty(enrollmentDetail);
                Logger.logLater('ZuoraAutopayEmailer', 'execute', message, Logger.ERROR);
            }
        }
        if (dryRun) {
            Logger.logLater('ZuoraAutopayEmailer', 'execute (dry run)', JSON.serialize(enrollments), Logger.INFO);
        } else {
            System.enqueueJob(new MarketingJourneyEnroller(enrollments));
        }
        Logger.flushLogs();
    }

    private MarketingJourneyEnrollmentDetail generateEnrollmentData(Zuora__CustomerAccount__c acc) {
        MarketingJourneyEnrollmentDetail enrollmentDetail = new MarketingJourneyEnrollmentDetail();
        enrollmentDetail.EventDefinitionKey = MC_EVENT_KEY;
        enrollmentDetail.ContactId = acc.Zuora__Account__r.Send_Bills_Contact__c;
        enrollmentDetail.EventProperties = getEmailProperties(acc);
        return enrollmentDetail;
    }

    /**
     * @param acc Zuora Customer Account
     * @return Data for Marketing Cloud journey Data Extension
     */
    private List<FlowMap> getEmailProperties(Zuora__CustomerAccount__c acc) {
        List<FlowMap> properties = new List<FlowMap>();
        properties.add(new FlowMap('ContactId', acc.Zuora__Account__r.Send_Bills_Contact__c));
        properties.add(new FlowMap('AccountId', acc.Zuora__Account__c));
        properties.add(new FlowMap('BrandKey', acc.Zuora__Account__r.Client_Brand_Key__c));
        properties.add(new FlowMap('WithdrawalDate', getNextWithdrawalDate()));
        properties.add(new FlowMap('ACH', acc.Zuora__Default_Payment_Method__r.Zuora__AchAccountNumberMask__c));
        properties.add(new FlowMap('CC', acc.Zuora__Default_Payment_Method__r.Zuora__CreditCardMaskNumber__c));
        properties.add(new FlowMap('AmountDue', String.valueOf(acc.Zuora__Balance__c)));
        properties.add(new FlowMap('FirstName', acc.Zuora__Account__r.Send_Bills_Contact__r.FirstName));
        properties.add(new FlowMap('EmailAddress', acc.Zuora__Account__r.Send_Bills_Contact__r.Email));
        return properties;
    }

    @TestVisible
    private Boolean isValidEmailEnrollment(MarketingJourneyEnrollmentDetail detail) {
        Boolean isValid = true;
        Boolean achPaymentPresent = false;
        Boolean ccPaymentPresent = false;
        if (detail.ContactId == null) {
            isValid = false;
        }
        for (FlowMap property : detail.EventProperties) {
            if (property.key == 'ACH') {
                achPaymentPresent = property.value != null;
            } else if (property.key == 'CC') {
                ccPaymentPresent = property.value != null;
            } else if (property.value == null) {
                isValid = false;
            }
        }
        return isValid && (achPaymentPresent || ccPaymentPresent);
    }

    /**
     * @description Assesses if the cron should run on the day of the current execution. The business wants emails to
     * go out on the 3rd to the last day of every month, and this method decides if today is the correct day
     * @return Boolean on if today is the correct date to be sending emails
     */
    @TestVisible
    private Boolean shouldSendEmailsToday(Date cronRunDate) {
        Integer numOfDaysInMonth = Date.daysInMonth(cronRunDate.year(), cronRunDate.month());
        Date thirdToLastDayInMonth = Date.newInstance(cronRunDate.year(), cronRunDate.month(), numOfDaysInMonth).addDays(-2);
        return cronRunDate == thirdToLastDayInMonth;
    }

    private String getNextWithdrawalDate() {
        Date dateOfNextWithdrawal = todaysDate.toStartOfMonth().addMonths(1);
        return Datetime.newInstance(dateOfNextWithdrawal, Time.newInstance(0,0,0,0)).format('MM/dd/yyyy');
    }
}