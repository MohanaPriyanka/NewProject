/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class ForgotPasswordController {
    public static final String ERRORMSGSTRING = 'There is no user by the username: ';
    public String username {get; set;}   
    public String errorMsg {get; set;}
       
    public ForgotPasswordController() {}
	
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
            errorMsg = ERRORMSGSTRING + username;
            return null;
        }
    }
}