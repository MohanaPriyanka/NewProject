/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Sends collections emails based on how many days late an account is
 + * Meant to be run as scheduled apex once a day.
 + * 
 + * Tested By: CustomerCommunicationHandlerTest
 + *************************************************************************************/

global class CustomerCommunicationHandler Implements Schedulable {
    public static Map<String, String> templateMap;

    global void execute(SchedulableContext sc){
        Decimal outstandingbalance;
        List<Messaging.SingleEmailMessage> emailstosend =  new List<Messaging.SingleEmailMessage>();    
        templateMap = new Map<String, String>();

        List<Account> billedacclist = [ SELECT id, Name, Send_Bills_Contact__C, 
                                            Last_Bill_Send_Date__c, Do_not_Send_Bills__c,
                                            Recurring_Billing__c, Days_Past_Due__c, 
                                            RecordTypeId, Total_Outstanding_Balance__c, 
                                            Total_Billed__c
                                        FROM Account 
                                        WHERE Total_Outstanding_Balance__c > 1
                                        AND Last_Bill_Send_Date__c != null 
                                        AND Send_Bills_Contact__c != null 
                                        AND Do_not_Send_Bills__c = false
                                        AND Recurring_Billing__c = false];

        for (EmailTemplate template : [ SELECT id, HtmlValue, Body, DeveloperName
                                        FROM EmailTemplate]) {
            templateMap.put(template.DeveloperName, template.HtmlValue);
        }

        OrgWideEmailAddress owa = [ SELECT Id, Address 
                                    FROM OrgWideEmailAddress
                                    WHERE Address = 'customercare@bluewavesolar.com' 
                                    LIMIT 1];

        if (billedacclist.size()>0){
            for (Account act : billedacclist){
                String contactid = act.Send_Bills_Contact__c;
                if (contactid != null) {   
                    Date maxDueDate = act.Last_Bill_Send_Date__c;
                    Date todaysDate = system.today();
                    Date threeDaysAgo = maxDueDate - 3;
                    system.debug(threeDaysAgo);

                    String email;
                    String htmlbody; 
                    String fullname = act.Name;
                    String subject = 'Your BlueWave account is ' + act.Days_Past_Due__c + ' days past due';
                    String dollar = String.valueof(act.Total_Outstanding_Balance__c);
                    String balance = '$' + dollar;   

                    if(threeDaysAgo == todaysDate){ 
                        htmlBody = templateMap.get('X3_Days_Bill_Due_Notice'); 
                        subject = 'Your Community Solar Bill Is Almost Due';
                    } else {
                        htmlBody = getTemplate(act);
                    }
                    if (fullname != null && balance != null){
                        htmlBody = htmlBody.replace('{!Account.Name}', fullname);
                        htmlBody = htmlBody.replace('{!Account.Total_Outstanding_Balance__c}', balance);
                    } 
                    if (htmlBody != null && htmlbody != 'DONOTSEND'){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setHtmlBody(htmlBody);                          
                        mail.setOrgWideEmailAddressId(owa.Id); 
                        String[] ccAddresses = new String[] {'compliance@bluewavesolar.com'};
                        mail.setccAddresses(ccAddresses);
                        mail.setSubject(subject);
                        mail.setTargetObjectId(contactid);                        
                        emailstosend.add(mail);
                    }
                    htmlbody = 'DONOTSEND';
                }
            }
            MessagingService.sendEmail(emailstosend);
        }     
    }

    public static String getTemplate(Account account){
        String htmlBody = 'DONOTSEND';
        if(account.Days_Past_Due__c == 7){
            htmlBody = templateMap.get('Bill_Late_1_Week');    
        } else if(account.Days_Past_Due__c == 15){
            htmlBody = templateMap.get('Bill_Late_15_Days');    
        } else if(account.Days_Past_Due__c == 30){
            htmlBody = templateMap.get('Bill_Late_30_Days');    
        } else if(account.Days_Past_Due__c == 45){
            htmlBody = templateMap.get('Bill_Late_45_Days');   
        } else if(account.Days_Past_Due__c == 60){
            htmlBody = templateMap.get('Bill_Late_60_Days');    
        } else if(account.Days_Past_Due__c == 67){
            htmlBody = templateMap.get('Bill_Late_67_Days');    
        } else if(account.Days_Past_Due__c == 74){
            htmlBody = templateMap.get('Bill_Late_74_Days');     
        } else if(account.Days_Past_Due__c == 81){
            htmlBody = templateMap.get('Bill_Late_81_Days');   
        } else if(account.Days_Past_Due__c == 88){
            htmlBody = templateMap.get('Bill_Late_88_Days');    
        } else if(account.Days_Past_Due__c == 90){
            htmlBody = templateMap.get('Bill_Late_90_Days');    
        }    
        return htmlBody;    
    }
}