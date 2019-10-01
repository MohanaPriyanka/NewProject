/*************************************************************************************
 + * Created By:  Jordan Pentaleri
 + * Sends collections emails based on how many days late an account is
 + * Meant to be run as scheduled apex once a day.
 + *
 + * Tested By: CustomerCommunicationHandlerTest
 + *************************************************************************************/

public class CustomerCommunicationHandler implements Database.Batchable<sObject>, Schedulable { 
    public void execute(SchedulableContext sc){
       Database.executeBatch(this, 10);
    }

    public Map<String, String> templateMap;
    public String errorsToLog;

    public String getTemplate(String templateKey, Account acct){
        String templateHTML;
        if (errorsToLog == null){
            errorsToLog = 'None';
        } 
        if (templateMap.containsKey(templateKey)){
            templateHTML = templateMap.get(templateKey);
        } else {
            templateHTML = 'DONOTSEND';
            errorsToLog = errorsToLog + ' / ' + acct.Id + ' - '+ templateKey;
        }
        return templateHTML;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Send_Bills_Contact__c, ' +
                        'Last_Bill_Send_Date__c, Do_not_Send_Bills__c, ' +
                        'Recurring_Billing__c, Days_Past_Due__c, ' + 
                        'RecordTypeId, Total_Outstanding_Balance_Merge__c, ' +
                        'Total_Billed__c, Client_Brand_Key__c, ' +
                        'Collection_Call_Today__c, Collection_Email_To_Fire_Today__c, ' +
                        'Max_Overdue_Due_Date_Merge__c ' +
                        'FROM Account ' +
                        'WHERE Total_Outstanding_Balance_Merge__c > 1 ' +
                        'AND Send_Bills_Contact__c != null ' +
                        'AND Do_not_Send_Bills__c = false ' +
                        'AND (Collection_Email_To_Fire_Today__c = true ' +
                        'OR Collection_Call_Today__c = true) ' +
                        'AND Recurring_Billing__c = false ';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){
        Decimal outstandingbalance;
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage>();
        List<Case> caseToInsertList = new List<Case>();
        templateMap = new Map<String, String>();

        for (EmailTemplate template :   [SELECT Id, HtmlValue, Body, DeveloperName
                                        FROM EmailTemplate
                                        WHERE DeveloperName LIKE 'Bill_Late%']) {
            templateMap.put(template.DeveloperName, template.HtmlValue);        
        }
        
        OrgWideEmailAddress owa = [ SELECT Id, Address
                                    FROM OrgWideEmailAddress
                                    WHERE Address = 'customercare@bluewavesolar.com'
                                    LIMIT 1];
        for (Account act : scope){
            String contactid = act.Send_Bills_Contact__c;

            if (contactid != null && act.Collection_Call_Today__c){
                caseToInsertList = createCollectionsCallCase(caseToInsertList,act);
            }
            if (contactid != null && act.Collection_Email_To_Fire_Today__c) {
                Date todaysDate = system.today();
                Date sendBillReminderDate = act.Max_Overdue_Due_Date_Merge__c - 3;
                String email;
                String htmlBody;
                String fullName = act.Name;
                String subject = 'Your BlueWave account is ' + act.Days_Past_Due__c + ' days past due';
                String dollar = String.valueof(act.Total_Outstanding_Balance_Merge__c);
                String balance = '$' + dollar;
                String templateKey = '';

                if (sendBillReminderDate == todaysDate){
                    templateKey = 'Bill_Late_3DayReminder_' + act.Client_Brand_Key__c;
                    htmlBody = getTemplate(templateKey, act);
                    subject = 'Your Community Solar Bill Is Almost Due';
                } else {
                    templateKey = 'Bill_Late_' + (act.Days_Past_Due__c).setScale(0) + '_' + act.Client_Brand_Key__c;
                    htmlBody = getTemplate(templateKey, act);
                    subject = 'Your Community Solar Is ' + (act.Days_Past_Due__c).setScale(0) + ' Days Past Due';
                }
                if (fullName != null && balance != null){
                    htmlBody = htmlBody.replace('{!Account.Name}', fullName);
                    htmlBody = htmlBody.replace('{!Account.Total_Outstanding_Balance_Merge__c}', balance);
                }
                if (htmlBody != null && htmlBody != 'DONOTSEND'){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setHtmlBody(htmlBody);
                    mail.setOrgWideEmailAddressId(owa.Id);
                    String[] ccAddresses = new String[] {'compliance@bluewavesolar.com'};
                    mail.setccAddresses(ccAddresses);
                    mail.setSubject(subject);
                    mail.setTargetObjectId(contactId);
                    emailsToSend.add(mail);
                }
                htmlBody = 'DONOTSEND';
            }
        }
        MessagingService.sendEmail(emailsToSend);

        if (caseToInsertList != null){
            insert caseToInsertList;
        }

        if (errorsToLog != null && errorsToLog != 'None'){
            Logger.logLater('CustomerCommunicationHandler', 'Missing Email Templates: acct / template', errorsToLog);
            Logger.flushLogs();
        }
    }

    public List<Case> createCollectionsCallCase(List<Case> caseToInsertList, Account acct){
        CaseFactory caseFactory = new CaseFactory();
        Case newCase;
        newCase = caseFactory.getCase('Collections');
        newCase.ContactId = acct.Send_Bills_Contact__c;
        newCase.Subject = 'Collections Call: ' + acct.Days_Past_Due__c + ' Days';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Payment';
        newCase.Description =
                'Remind them their payment is Past due' + ' / ' +
                'Ask if they have sent payment and if so when and note check number' + ' / ' +
                'Note this info on the case in the chatter' + ' / ' +
                'If there is no reply leave a voice note';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        caseToInsertList.add(newCase);
        return caseToInsertList;
    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        String emailBody = 'Collections Emails Have been Processed Job Id: '+ job.Id 
                            + '  Apex Errors: ' + job.NumberOfErrors 
                            + '  Total Jobs Processed (groups of 10): ' + job.JobItemsProcessed;

        List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com' , 'communitysolar@bluewavesolar.com'};   
        if (!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Email Send Processing Complete', postJobEmailAddresses);
        }
    }  
}