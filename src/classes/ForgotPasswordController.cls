/**
 * An apex page controller that exposes the site forgot password functionality
 * Tested By: ForgotPasswordControllerTest
 */
public without sharing class ForgotPasswordController {
    public String ERRORMSGSTRING {get; set;}
    public String EMAILSENT {get; set;}
    public String username {get; set;}   
    public String errorMsg {get; set;}
    public String firstname {get; set;}
    public String lastname {get; set;}
    public String phone {get; set;}
    public String subject {get; set;}

    public ForgotPasswordController() {
        ERRORMSGSTRING = 'NOUSER';
        EMAILSENT = 'EMAILSENT';
    }
	
    public PageReference forgotPassword() {
        Boolean success = false;
        // Check to see if there's a user by that username
        List<User> userList = [SELECT Id
                               FROM User
                               WHERE Username = :username
                               AND IsActive = true];
        if (userList.size() > 0) {
            success = Site.forgotPassword(username);
            PageReference pr = Page.ForgotPasswordConfirm;
            pr.setRedirect(true);
  		
            if (success) {  			
                return pr;
            }
            return null;
        } else {
            errorMsg = ERRORMSGSTRING;
            return null;
        }
    }

    public PageReference send() {
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
 
        // Sets the parameters of the email
        if (subject == '') {
            subject = 'Please help setup: ' + username;
        }
        email.setSubject(subject);
        // Reset subject in case user updates the form again
        subject = '';

        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        List<String> toAddress = new List<String>();
        if (systemProperties.size() > 0 &&
            systemProperties[0].Customer_Care_Email__c != null) {
            toAddress.add(systemProperties[0].Customer_Care_Email__c);
        } else {
            toAddress.add('pyao@bluewave-capital.com');
        }            
        email.setToAddresses(toAddress);
        email.setPlainTextBody('Customer Care,\n\n' +
                               'A user is having trouble setting up their account and just submitted this form from the Forgot Password page.\n\n' +
                               'Firstname: ' + firstname + '\n' +
                               'Lastname: ' + lastname + '\n' +
                               'Email: ' + username + '\n' +
                               'Phone: ' + phone + '\n\n' +
                               'Please check Salesforce for their account and setup as necessary');
     
        // Sends the email
        Messaging.SendEmailResult [] r =
            MessagingService.sendEmail(new Messaging.SingleEmailMessage[] {email});

        errorMsg = EMAILSENT;
         
        return null;
    }

}