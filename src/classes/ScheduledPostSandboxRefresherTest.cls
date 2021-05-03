@IsTest
public with sharing class ScheduledPostSandboxRefresherTest {
    @IsTest
    private static void testScheduledJob() {
        try {
            new ScheduledPostSandboxRefresher().runApexClass(null);
        } catch (Exception e) {
            System.assert(false, 'Did not expect exception: ' + e.getMessage() + '/n' + e.getStackTraceString());
        }
    }
}