/**
 * @description Initiates credit pulls via LASERCA. Assumes a soft pull (which is set by the login account username).
 * Tested By: CreditReportPullerTest
 */
public without sharing class CreditReportPuller {
    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static FeatureSelector featureSelector = new FeatureSelector();
    // This needs to be static because there's a different instance of LeadTriggerHandler (and by extension CreditReportPuller)
    // between the Before and After Update trigger, and the After Update needs to know the leads that were found at the end
    // of the Before Update
    private static Set<Id> leadsWithSoftPullCreditReportChecked = new Set<Id>();

    /**
     * @description Unchecks Soft_Pull_Credit_Report__c on Lead, and removes LASERCA__Applicant_Id__c that might have been
     * Set. We can't make the request in the before update trigger, because LASERCA will query the Applicant Id from the
     * lead. That needs to be cleared out to handle the case where we change information on a lead and re-pull credit.
     * If we don't, we get a Credit Report Log error "Invalid app_id: Applicant not found"
     * @param newLeads Trigger.new
     * @param oldLeadMap Trigger.oldMap
     */
    public void handleSoftPullCreditCheckedBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        for (Lead newLead : newLeads) {
            if (oldLeadMap.get(newLead.Id).Soft_Pull_Credit_Report__c == false &&
                newLead.Soft_Pull_Credit_Report__c == true) {
                newLead.Soft_Pull_Credit_Report__c = false;
                newLead.LASERCA__Applicant_Id__c = null;
                leadsWithSoftPullCreditReportChecked.add(newLead.Id);
            }
        }
    }

    /**
     * @description Requires that handleSoftPullCreditCheckedBeforeUpdate() puts leads needing credit pulls into
     * leadsWithSoftPullCreditReportChecked (or otherwise, leads do not have LASERCA__Applicant_Id__c set), and makes requests
     * for them.
     */
    public void requestCreditPullsAfterUpdate() {
        if (leadsWithSoftPullCreditReportChecked.isEmpty()) {
            return;
        }
        try {
            sendRequest(leadsWithSoftPullCreditReportChecked);
        } catch (Exception e) {
            Logger.logNow('CreditReportPuller', 'handleSoftPullCreditCheckedBeforeUpdate', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    private void sendRequest(Set<Id> leadIds) {
        System_Default__mdt systemDefault = featureSelector.getSystemDefaults();
        List<Lead> leadsForCreditReports = leadSelector.selectAll(leadIds);
        List<LASERCA.PullCreditReportAction.PullCreditReportActionRequest> requests =
            new List<LASERCA.PullCreditReportAction.PullCreditReportActionRequest>();
        for (Lead lead : leadsForCreditReports) {
            requests.add(getRequest(lead, systemDefault));
        }
        Logger.logNow('CreditReportPuller', 'sendRequest', requests.toString(), Logger.FINE);
        LASERCA.PullCreditReportAction.sendRequest(requests);
    }

    @TestVisible
    private LASERCA.PullCreditReportAction.PullCreditReportActionRequest getRequest(Lead lead, System_Default__mdt systemDefault) {
        LASERCA.PullCreditReportAction.PullCreditReportActionRequest request =
            new LASERCA.PullCreditReportAction.PullCreditReportActionRequest();
        request.relatedObjectId = lead.Id;
        request.loginAccount = systemDefault.Credit_Login_Account_Username__c;
        request.firstName = lead.FirstName;
        request.lastName = lead.LastName;
        request.homeAddress = lead.LASERCA__Home_Address__c;
        request.homeCity = lead.LASERCA__Home_City__c;
        request.homeState = lead.LASERCA__Home_State__c;
        request.homeZip = lead.LASERCA__Home_Zip__c;
        request.birthDate = lead.LASERCA__Birthdate__c;
        request.provider = systemDefault.Credit_Provider__c;
        request.applicantIdField = 'LASERCA__Applicant_Id__c';
        if (systemDefault.Credit_Provider__c == 'CREDITAPI') { // Transunion
            request.ssn = getSSNForSoftpullTransunionRequest(lead);
        } else if (systemDefault.Credit_Provider__c == 'CBCNEW') { // Experian
            convertTestcaseRequestsForExperian(request, systemDefault);
        } else {
            throw new Util.BWException('Credit Provider not implemented: ' + systemDefault.Credit_Provider__c);
        }
        return request;
    }

    @TestVisible
    private String getSSNForSoftpullTransunionRequest(Lead lead) {
        if (lead.LastName.toLowerCase().contains('testcase')) {
            if (lead.FirstName != null && lead.FirstName.toLowerCase().contains('frozen')) {
                return '000000010';
            } else if (lead.FirstName != null && lead.FirstName.toLowerCase().contains('fail')) {
                return '000000008';
            }
            return '000000001';
        }
        return '000000000';
    }

    /**
     * @description Converts a request into one of the experian test subjects, using the Experian UAT system, per:
     * https://lasercreditaccess.my.salesforce.com/sfc/p/#U0000000HHjH/a/7V000000sXy7/Au_y.madjFFmBAiNh7zI0SXTRA60fv8Q8K4Gwbv30DE
     * @param request The request that could get converted into an experian test subject
     * @param systemDefault Custom Metadata that has the Experian test username
     */
    @TestVisible
    private void convertTestcaseRequestsForExperian(LASERCA.PullCreditReportAction.PullCreditReportActionRequest request, System_Default__mdt systemDefault) {
        if (Util.isSandboxOrTest()) {
            request.loginAccount = systemDefault.Test_Credit_Login_Account_Username__c;
        }
        if (request.lastName.toLowerCase().contains('testcase')) {
            request.loginAccount = systemDefault.Test_Credit_Login_Account_Username__c;
            request.firstName = 'Paul';
            request.lastName = 'Burnia';
            request.ssn = '666390426';
            request.homeAddress = '19103 Tajauta Ave';
            request.homeCity = 'Carson';
            request.homeState = 'CA';
            request.homeZip = '90746';
        }
    }
}