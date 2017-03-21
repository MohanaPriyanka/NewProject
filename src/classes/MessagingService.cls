/**
 * Created By: Peter Yao
 * Description:  Class that allows us to not send emails if running tests, but instead,
 *               validate the emails that are intended to be sent.
 * Tested by: PostSandboxRefresherTest
 **/

public class MessagingService {
    public static Messaging.Email[] emailsSent;

    public static Messaging.SendEmailResult[] sendEmail(Messaging.Email[] emails) {
        if (Test.isRunningTest()) {
            emailsSent = emails.clone();
            return null;
        } else {
            return Messaging.sendEmail(emails);
        }
    }
}