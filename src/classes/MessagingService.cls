/**
 * Created By: Peter Yao
 * Description:  Class that allows us to not send emails if running tests, but instead,
 *               validate the emails that are intended to be sent.
 * Tested by: PostSandboxRefresherTest
 **/

public class MessagingService {
    public static Messaging.Email[] emailsSent;

    public static Messaging.SendEmailResult[] sendEmail(Messaging.Email[] emails) {
        Messaging.SendEmailResult[] sendEmailResults;
        emailsSent = emails.clone();
        try {
            sendEmailResults = Messaging.sendEmail(emails);
        } catch (EmailException ee) {Logger.logNow('MessagingService', 'sendEmail', ee.getMessage());}
        return sendEmailResults;
    }
}