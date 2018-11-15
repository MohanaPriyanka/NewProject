/*
 * Tested By: TestcaseRecordDeleterTest or CommunitySolarCustomerPortalTest
 * TODO: Fix the SOQL in loop
 */
trigger referralCodeGeneration on Contact (before insert) {
    if (Util.isDisabled('Disable_ContactTrigger__c')) {
        return;
    }
    for (Contact c : Trigger.new) {
        if (Trigger.isInsert) {
            String referralCode = 'bluewave' + c.FirstName.left(1) + c.LastName;
            String firstNameLetter = c.FirstName.left(1);
            List<AggregateResult> aggregateResults = [
                SELECT COUNT(Custom_ID__c) cntID
                FROM Contact
                WHERE First_Letter_First_Name__c = : firstNameLetter
                AND LastName = : c.LastName
            ];
            for(AggregateResult obj : aggregateResults){
                if (Integer.valueOf(obj.get('cntID')) < 1) {
                    c.Custom_ID__c = referralCode;
                } else {
                    referralCode = referralCode + obj.get('cntID');
                    c.Custom_ID__c = referralCode;
                }
            }
        }
    }
}