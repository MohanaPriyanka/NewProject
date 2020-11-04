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
        try {
            if (subject == '' || subject == null) {
                subject = 'Please help setup: ' + username;
            }

            String description = 'Customer Care,\n\n' +
                'A user is having trouble setting up their account and just submitted this form from the Forgot Password page.\n\n' +
                'Firstname: ' + firstname + '\n' +
                'Lastname: ' + lastname + '\n' +
                'Email: ' + username + '\n' +
                'Phone: ' + phone + '\n\n' +
                'Please check Salesforce for their account and setup as necessary';

            Case passwordCase = new CaseFactory().getCase('Customer_Care');
            passwordCase.Subject = subject;
            passwordCase.Description = description;
            passwordCase.Product_Line__c = 'Community Solar';
            passwordCase.Category__c = 'Portal Support';
            passwordCase.Origin = 'Web';
            insert passwordCase;
        } catch (Exception e) {
            Logger.logNow('ForgotPasswordController', 'send', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }

        // Reset subject in case user updates the form again
        subject = '';
        errorMsg = EMAILSENT;
         
        return null;
    }

}