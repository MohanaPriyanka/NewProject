/**
 * @description Created by PeterYao on 11/3/2021.
 */
@IsTest
private with sharing class CustomLabelResolverTest {
    @IsTest
    private static void testResolver() {
        String text = 'Welcome to {!$Label.Company_Name} Community Solar powered by {!$Label.Company_Name}. ' +
            'Call us at {!$Label.phone_customercare}';
        String expectedResolution = 'Welcome to ' + System.Label.Company_Name + ' Community Solar powered by ' + System.Label.Company_Name + '. ' +
            'Call us at ' + System.Label.phone_customercare;
        String resolvedText = new CustomLabelResolver().resolve(text);
        System.assertEquals(expectedResolution, resolvedText, 'Labels should get replaced');

        text = text + ' {!$Label.unhandledlabel}';
        try {
            new CustomLabelResolver().resolve(text);
            System.assert(false, 'Expected CustomLabelResolver to throw an exception for an unhandled label');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Unknown label'),
                'Expected a message about adding the unknown label to CustomLabelResolver, but got ' + e.getMessage());
        }

        text = ' We do not look for {!Label.poorly formatted labels} right now';
        try {
            new CustomLabelResolver().resolve(text);
            System.assert(true, 'We are not checking for labels that are not formatted correctly yet');
        } catch (Exception e) {
            System.assert(false, 'Did not expect an exception for a poorly formatted label, until we handle it:\n' + text);
        }
    }
}