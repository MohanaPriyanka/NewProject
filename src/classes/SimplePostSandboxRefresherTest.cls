/**
 * Created by PeterYao on 5/2/2021.
 */
@IsTest
public with sharing class SimplePostSandboxRefresherTest {
    @IsTest
    private static void testSimpleJob() {
        try {
            new SimplePostSandboxRefresher().runApexClass(null);
        } catch (Exception e) {
            System.assert(false, 'Did not expect exception: ' + e.getMessage() + '/n' + e.getStackTraceString());
        }
    }

}