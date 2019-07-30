/**
 * Created by WParker on 7/31/2018.
 *
 * This class handles the creation and deletion of Cases related to faulty Chargent Orders.
 * If there's no existing Case, a Case should be created for a Chargent Order if:
 *          a. the order has Payment Status equal to 'Error',
 *          b. the order has a Next Transaction Date set to the current date or a past date,
 *          c. the order has an account with bills but is not tied to any account bill
 *
 * If there is a Case open pertaining to a Chargent Order, and the Chargent Order in question
 *    does not fall into one of the above categories, that Case should be closed.
 *
 * Test Class: PaymentCaseTest
 *
 */

public without sharing class PaymentCaseCreator implements Schedulable {

    public enum OrderCaseType {
        PaymentStatusError,
        InvalidNextTransDate,
        AccountBillError,
        NoCaseNeeded
    }

    OrgWideEmailAddress customerCareEmail = [
        SELECT Id, Address
        FROM OrgWideEmailAddress
        WHERE Address = 'customercare@bluewavesolar.com'
        LIMIT 1
    ];

    List<EmailTemplate> emailTemplates = [
        SELECT Id, HtmlValue, Body, DeveloperName, Subject
        FROM EmailTemplate
        WHERE DeveloperName LIKE '%CS_Autopay_Error_Message%'
    ];

    public static String paymentStatusErrorDescription =
        'The Payment Status of this Chargent Order is equal to Error. [Auto-generated]';
    public static String invalidNextTransDateDescription =
        'The Next Transaction Date on this Chargent Order is set to an invalid value(today or in the past). [Auto-generated]';
    public static String accountBillErrorDescription =
        'The Chargent Order has no Account Bill yet the Account it is tied to has Account Bills. [Auto-generated]';
    private Map<OrderCaseType, String> caseTypeDescriptionMap =
        new Map<OrderCaseType, String>{OrderCaseType.PaymentStatusError => paymentStatusErrorDescription,
        OrderCaseType.InvalidNextTransDate => invalidNextTransDateDescription,
        OrderCaseType.AccountBillError => accountBillErrorDescription};

    private Map<OrderCaseType, String> caseTypeSubjectMap =
        new Map<OrderCaseType, String>{OrderCaseType.PaymentStatusError => 'Transaction Failed',
        OrderCaseType.InvalidNextTransDate => 'Internal - Send to Product Team',
        OrderCaseType.AccountBillError => 'Internal - Send to Product Team'};

    public void execute(SchedulableContext sc) {
        // without batching just run this:
        fetchOrdersAndRun();
    }


    public void fetchOrdersAndRun() {

        // fetch orders
        List<ChargentOrders__ChargentOrder__c> allOrders = getAllRelevantOrders();

        // run the close/open cases method
        if (allOrders.size() > 0) {
            closeAndOpenNecessaryCases(allOrders);
        }
    }

    // queries for all chargent orders
    public List<ChargentOrders__ChargentOrder__c> getAllRelevantOrders() {
        return [
            SELECT Id, Property_Account_ID__c, ChargentOrders__Account__c, Account_Bill__c, Property_Account__r.Id,
            ChargentOrders__Payment_Status__c, ChargentOrders__Next_Transaction_Date__c, Account_Bill__r.Parent_Account__r.Client_Brand_Key__c,
            CreatedDate, ChargentOrders__Billing_Last_Name__c, Entity__c, ChargentOrders__Gateway__r.Name,
            Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Id, Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Email,
            ChargentOrders__Account__r.Send_Bills_Contact__r.Email, ChargentOrders__Billing_First_Name__c, Account_Bill__r.Due_Date_SB__c,
            Account_Bill__r.Date__c,Account_Bill__r.Parent_Account__r.Additional_Contact__r.Email,ChargentOrders__Account__r.Additional_Contact__r.Email,
                Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.FirstName,
            (SELECT Id, Status, Chargent_Order__c FROM Cases__r WHERE Status != 'Closed'),
            (SELECT Id, ChargentOrders__Response_Status__c, ChargentOrders__Response_Message__c,
            CreatedDate, ChargentOrders__Gateway_Date__c, ChargentOrders__Account__r.Send_Bills_Contact__r.Id
            FROM ChargentOrders__Transactions__r
            ORDER BY ChargentOrders__Gateway_Date__c DESC
            LIMIT 1)
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Next_Transaction_Date__c <= : System.today()
            OR ChargentOrders__Payment_Status__c = 'Error'
            OR (Account_Bill__c = NULL
            AND ChargentOrders__Gateway__r.Name != 'SREC')
        ];
    }

    // Creates a case for every chargent order that needs one and doesn't yet have a case open
    // Fetches all cases with chargent orders and deletes unnecessary cases
    // Returns all chargent orders passed in, except those with cases assigned to them
    public void closeAndOpenNecessaryCases(List<ChargentOrders__ChargentOrder__c> chOrders) {

        Map<Id, List<Case>> orderToCaseMap = new Map<Id, List<Case>>();

        // query for all Cases relating to a Chargent Order and put them into a map
        List<Case> casesRelatedToOrders = [
            SELECT Id, Chargent_Order__c, Status
            FROM Case
            WHERE Chargent_Order__c != NULL
            AND Status != 'Closed'
        ];

        for (Case aCase: casesRelatedToOrders) {
            List<Case> newListOfCases;
            if (orderToCaseMap.containsKey(aCase.Chargent_Order__c)) {
                newListOfCases = orderToCaseMap.get(aCase.Chargent_Order__c);
                newListOfCases.add(aCase);
            } else {
                newListOfCases = new List<Case>{aCase};
            }
            orderToCaseMap.put(aCase.Chargent_Order__c, newListOfCases);
        }

        // create a map of order to boolean(whether that order has an account with account bills)
        Map<ChargentOrders__ChargentOrder__c, Boolean> orderAccountHasBillsMap =
            new Map<ChargentOrders__ChargentOrder__c, Boolean>();

        List<Id> propertyAccountIds = new List<Id>();
        for (ChargentOrders__ChargentOrder__c order: chOrders) {
            propertyAccountIds.add(order.Property_Account__c);
        }

        List<Account_Bill__c> billsOnAccounts = [
            SELECT Id, Parent_Account__c
            FROM Account_Bill__c
            WHERE Parent_Account__c IN : propertyAccountIds
        ];

        Map<Id, Account_Bill__c> billMap = new Map<Id, Account_Bill__c>();
        for (Account_Bill__c bill: billsOnAccounts) {
            billMap.put(bill.Parent_Account__c, bill);
        }

        for (ChargentOrders__ChargentOrder__c order : chOrders) {
            orderAccountHasBillsMap.put(order, billMap.containsKey(order.Property_Account__c));
        }

        // iterate through orders and create a new case if needed, close an old case if doesn't fit case criteria
        List<Case> allCasesToClose = new List<Case>();
        List<Case> allCasesToOpen = new List<Case>();

        Map<Case, ChargentOrders__ChargentOrder__c> newCasesToOrderMap = new Map<Case, ChargentOrders__ChargentOrder__c>();
        Map<Id, ChargentOrders__ChargentOrder__c> orderIdToOrderMap = new Map<Id, ChargentOrders__ChargentOrder__c>();

        // First, iterate through the relevant orders and
        //    if there's no case already
        //        check if it needs one and create it
        //    else if there's already a case
        //        check if it needs one and if not, close the existing case(s)
        //        remove the order/case pairing from the orderToCaseMap (We already looked at these cases)
        //
        // Second, iterate through the remaining cases stored in the orderToCaseMap and close them ALL,
        //   as there is no way that the order associated can have an error if it wasn't picked up in the first query
        for (ChargentOrders__ChargentOrder__c order : chOrders) {

            OrderCaseType caseType = needsCase(order, orderAccountHasBillsMap.get(order));
            if (caseType == OrderCaseType.NoCaseNeeded) {                                     // shouldn't be a case
                // if a Case is open for this order, it shouldn't be, so close it.
                if (orderToCaseMap.containsKey(order.Id)) {
                    List<Case> casesToClose = orderToCaseMap.get(order.Id);
                    for (Case caseToClose : casesToClose) {
                        caseToClose.Status = 'Closed';
                        caseToClose.Resolution__c = 'Other';
                    }

                    allCasesToClose.addAll(casesToClose);

                    // remove the order from the map
                    orderToCaseMap.remove(order.Id);
                }
            } else {                                                                          // should be a case
                if (orderToCaseMap.containsKey(order.Id)) {
                    // there is already a case for this order, ignore it
                    // remove the order from the map
                    orderToCaseMap.remove(order.Id);
                } else {
                    // there needs to be a case for this order, create it
                    Case caseToOpen = createCaseForOrder(order, caseType);
                    allCasesToOpen.add(caseToOpen);
                    newCasesToOrderMap.put(caseToOpen, order);
                    orderIdToOrderMap.put(order.Id, order);
                }
            }
        }



        // Close leftover cases
        for (Id order : orderToCaseMap.keySet()) {
            for (Case caseToClose: orderToCaseMap.get(order)) {
                caseToClose.Status = 'Closed';
                caseToClose.Resolution__c = 'Other';
                allCasesToClose.add(caseToClose);
            }
        }

        Database.SaveResult[] insertResults = Database.insert(allCasesToOpen, false);
        Database.SaveResult[] updateResults = Database.update(allCasesToClose, false);

        /// Emails ////////////////////////////////////
        sendAllRequiredEmails(allCasesToOpen, orderIdToOrderMap);

        /////// LOGGING ////////
        // Get # of successful opens/closes
        Integer numOpened = 0;
        String openLogString = '\n';
        for (Database.SaveResult result : insertResults) {
            if (result.isSuccess()) {
                numOpened += 1;
            } else {
                openLogString += '(Attempting to Open) Error on item of id [' + result.getId() + ']: ' + result.getErrors()[0].getMessage();
            }
        }

        Integer numClosed = 0;
        String closedLogString = '\n';
        for (Database.SaveResult result : updateResults) {
            if (result.isSuccess()) {
                numClosed += 1;
            } else {
                closedLogString += '(Attempting to Close) Error on item of id [' + result.getId() + ']: ' + result.getErrors()[0].getMessage();
            }
        }

        if (numOpened > 0 || numClosed > 0) {
            Logger.logNow('PaymentCaseCreator',
                'closeAndOpenNecessaryCases',
                '# of cases opened: ' + numOpened + '; # of cases closed: ' + numClosed +
                    openLogString +
                    closedLogString, Logger.INFO);
            Logger.logNow('PaymentCaseCreator',
                'closeAndOpenNecessaryCases',
                'allCasesToOpen:' + allCasesToOpen + '\n' +
                    'allCasesToClose:' + allCasesToClose, Logger.FINE);
        }


    }

    // Determines whether a case needs to be created for a chargent order and returns the corresponding enum value
    private OrderCaseType needsCase(ChargentOrders__ChargentOrder__c chOrder, Boolean accountHasBill) {

        if (chOrder.ChargentOrders__Payment_Status__c != null &&
            chOrder.ChargentOrders__Payment_Status__c.equals('Error')) {
            return OrderCaseType.PaymentStatusError;
        } else if (chOrder.ChargentOrders__Next_Transaction_Date__c != null &&
            chOrder.ChargentOrders__Next_Transaction_Date__c.daysBetween(Date.today()) >= 0 &&
            chOrder.ChargentOrders__Payment_Status__c != 'Stopped' &&
            chOrder.ChargentOrders__Payment_Status__c != 'Complete') {
            return OrderCaseType.InvalidNextTransDate;
        } else if (chOrder.ChargentOrders__Payment_Status__c != 'Stopped' &&
            chOrder.ChargentOrders__Payment_Status__c != 'Complete' &&
            chOrder.ChargentOrders__Payment_Status__c != null &&
            chOrder.Account_Bill__c == null &&
            accountHasBill){
            return OrderCaseType.AccountBillError;
        } else {
            return OrderCaseType.NoCaseNeeded;
        }
    }

    public Case createCaseForOrder(ChargentOrders__ChargentOrder__c chOrder, OrderCaseType type) {
        if (type == OrderCaseType.NoCaseNeeded) {
            return null;
        }

        CaseFactory caseFactory = new CaseFactory();
        Case newCase;

        if (type == OrderCaseType.PaymentStatusError) {
            newCase = caseFactory.getCase('Customer_Care');
            newCase.ContactId = chOrder.Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Id;
        } else {
            newCase = caseFactory.getCase('Product_Support');
        }

        newCase.Subject = 'Automatic Payment Error [' + caseTypeSubjectMap.get(type) + ']';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Payment';
        newCase.Sale_Status__c = 'Post-sale';
        newCase.Chargent_Order__c = chOrder.Id;
        newCase.Description = this.caseTypeDescriptionMap.get(type);
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;

        // Set related Account
        if (chOrder.Account_Bill__c != null) {
            newCase.AccountId = chOrder.Account_Bill__r.Parent_Account__r.Id;
        } else {
            newCase.AccountId = chOrder.ChargentOrders__Account__c;
        }

        // Set description to include error message from last transaction
        if (chOrder.ChargentOrders__Transactions__r.size() == 1 &&
            type == OrderCaseType.PaymentStatusError) {
            newCase.Description += '\n\nMessage from Gateway: \'' +
                chOrder.ChargentOrders__Transactions__r.get(0).ChargentOrders__Response_Message__c + '\'';
        }

        // successfully created case
        return newCase;
    }

    // Loops through all cases and sends an email if one is required
    //      i.e. calls prepareAndSendEmailForCase on individual case/order pairs
    public void sendAllRequiredEmails(List<Case> cases, Map<Id, ChargentOrders__ChargentOrder__c> caseToOrderMap) {

        List<String> errorsWarrantingAnEmail =
            new List<String>{'Credit Card Declined.',
                'This transaction has been declined.',
                'Warning! Your credit card is expired',
                'The given name on the account and/or the account type does not match the actual account.',
                'The ABA code is invalid',
                'Invalid Credit Card',
                'Invalid Route.'};

        Map<String,EmailTemplate> templateMap = new Map<String,EmailTemplate>();
        for (EmailTemplate template : emailTemplates) {
            templateMap.put(template.DeveloperName, template);
        }

        List<Messaging.Email> emailsToSend = new List<Messaging.Email>();

        for (Case aCase : cases) {
            ChargentOrders__ChargentOrder__c chOrder = caseToOrderMap.get(aCase.Chargent_Order__c);
            if (chOrder == null || chOrder.ChargentOrders__Transactions__r.size() == 0) {
                continue;
            }
            ChargentOrders__Transaction__c latestTransaction = chOrder.ChargentOrders__Transactions__r.get(0);
            if (latestTransaction != null && errorsWarrantingAnEmail.contains(latestTransaction.ChargentOrders__Response_Message__c)) {
                String toEmail = chOrder.Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.Email;
                String name = chOrder.Account_Bill__r.Parent_Account__r.Send_Bills_Contact__r.FirstName;//chOrder.ChargentOrders__Billing_First_Name__c;
                String errorMessage = latestTransaction.ChargentOrders__Response_Message__c;
                List<String> emailList = new List<String>();

                if (toEmail != null && name != null) {
                    emailList.add(toEmail);
                    if (chOrder.Account_Bill__r.Parent_Account__r.Additional_Contact__r.Email != null) {
                        emailList.add(chOrder.ChargentOrders__Account__r.Additional_Contact__r.Email);
                    }
                    if (chOrder.Account_Bill__r.Due_Date_SB__c != null) {
                        Date billDueDate = chOrder.Account_Bill__r.Due_Date_SB__c;
                        Datetime dt = Datetime.newInstance(billDueDate.year(), billDueDate.month(), billDueDate.day());
                        String billDueDateString = dt.format('MMMMM dd, yyyy');   //dt.format('yyyy-MM-dd');

                        Boolean isAmp = chOrder.Account_Bill__r.Parent_Account__r.Client_Brand_Key__c != null &&
                            chOrder.Account_Bill__r.Parent_Account__r.Client_Brand_Key__c.contains('Amp');
                        if (isAmp) {
                            emailsToSend.add(sendTransactionErrorEmail(name, billDueDateString, errorMessage, emailList,
                                templateMap.get('CS_Autopay_Error_Message_AmpRed'), chOrder.Account_Bill__r.Parent_Account__r.Send_Bills_Contact__c, aCase));
                        } else {
                            emailsToSend.add(sendTransactionErrorEmail(name, billDueDateString, errorMessage, emailList,
                                templateMap.get('CS_Autopay_Error_Message'), chOrder.Account_Bill__r.Parent_Account__r.Send_Bills_Contact__c, aCase));
                        }
                    } else {
                        emailsToSend.add(sendInternalErrorEmail('AUTOPAY EMAIL SEND FAIL FOR ORDER: ' + chOrder.Id + ' because there is no bill due date on the related account bill'));
                    }
                } else {
                    emailsToSend.add(sendInternalErrorEmail('AUTOPAY EMAIL SEND FAIL FOR ORDER: ' + chOrder.Id + ' because there is no email for the related contact'));
                }
            }
        }

        if (emailsToSend.size() > 0) {

            // Send all emails at once
            List<Messaging.SendEmailResult> results = MessagingService.sendEmail(emailsToSend);

            // Iterate through results and log whatever errors there are
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    String logString = 'Autopay Auto-Email send failed with errors:\n';

                    List<Messaging.SendEmailError> errors = result.getErrors();
                    for (Messaging.SendEmailError error : errors) {
                        logString += error.getMessage() + '\n';
                    }
                    Logger.logLater('PaymentCaseCreator', 'sendAllRequiredEmails',logString,'Error');
                }
            }

            Logger.flushLogs();
        }
    }

    public Messaging.Email sendTransactionErrorEmail(String name, String billDueDate, String errorMessage, List<String> recipientEmailAddresses, EmailTemplate template, Id contactId, Case caseToAttach) {
        // Replace the merge fields in the template with the passed in strings
        String HTML = template.htmlValue;
        String plaintext = template.body;

        Map<String,String> moreClearMessageMap = CreateOrderandPaymentRequest.responseMap;
        if (moreClearMessageMap.containsKey(errorMessage)) {
            errorMessage = moreClearMessageMap.get(errorMessage);
        }

        errorMessage = '\'' + errorMessage + '\'';

        HTML = HTML.replace('&lt;First Name&gt;', name);
        HTML = HTML.replace('&lt;Error Message&gt;', errorMessage);
        HTML = HTML.replace('&lt;current bill due date&gt;', billDueDate);
        plaintext = plaintext.replace('<First Name>', name);
        plaintext = plaintext.replace('<Error Message>', errorMessage);
        plaintext = plaintext.replace('<current bill due date>', billDueDate);

        // create the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(customerCareEmail.Id);
        mail.setSubject(template.Subject);
        mail.setHtmlBody(HTML);
        mail.setPlainTextBody(plaintext);
        mail.setToAddresses(recipientEmailAddresses);
        mail.setSaveAsActivity(true);
        mail.setTargetObjectId(contactId);
        mail.setWhatId(caseToAttach.Id);

        // return the email
        return mail;
    }

    public Messaging.Email sendInternalErrorEmail(String errorMessage) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(customerCareEmail.Id);
        mail.setSubject('Autopay Email Failed');
        mail.setHtmlBody(errorMessage);
        mail.setPlainTextBody(errorMessage);
        mail.setToAddresses(new List<String>{'communitysolar@bluewavesolar.com'});
        List<Messaging.Email> emailsToSend = new List<Messaging.Email>{mail};

        return mail;
    }
}