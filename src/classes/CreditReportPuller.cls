/**
 * @description Initiates credit pulls via LASERCA. Assumes a soft pull (which is set by the login account username)
 * Tested By: CreditReportPullerTest
 */
public without sharing class CreditReportPuller {
    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    @TestVisible private static FeatureSelector featureSelector = new FeatureSelector();

    public void handleSoftPullCreditCheckedBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> leadsWithSoftPullCreditReportChecked = new Set<Id>();
        for (Lead newLead : newLeads) {
            if (oldLeadMap.get(newLead.Id).Soft_Pull_Credit_Report__c == false &&
                newLead.Soft_Pull_Credit_Report__c == true) {
                newLead.Soft_Pull_Credit_Report__c = false;
                leadsWithSoftPullCreditReportChecked.add(newLead.Id);
            }
        }
        if (!leadsWithSoftPullCreditReportChecked.isEmpty()) {
            sendRequest(leadsWithSoftPullCreditReportChecked);
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
        LASERCA.PullCreditReportAction.sendRequest(requests);
    }

    private LASERCA.PullCreditReportAction.PullCreditReportActionRequest getRequest(Lead lead, System_Default__mdt systemDefault) {
        LASERCA.PullCreditReportAction.PullCreditReportActionRequest request =
            new LASERCA.PullCreditReportAction.PullCreditReportActionRequest();
        if (systemDefault.Credit_Provider__c == 'CREDITAPI') {
            request.relatedObjectId = lead.Id;
            request.loginAccount = systemDefault.Credit_Login_Account_Username__c;
            request.firstName = lead.FirstName;
            request.lastName = lead.LastName;
            request.ssn = getSSNForSoftpullTransunionRequest(lead);
            request.homeAddress = lead.LASERCA__Home_Address__c;
            request.homeCity = lead.LASERCA__Home_City__c;
            request.homeState = lead.LASERCA__Home_State__c;
            request.homeZip = lead.LASERCA__Home_Zip__c;
            request.birthDate = lead.LASERCA__Birthdate__c;
            request.provider = systemDefault.Credit_Provider__c;
            request.applicantIdField = lead.LASERCA__Applicant_Id__c;
        } else {
            throw new Util.BWException('Credit Provider not implemented: ' + systemDefault.Credit_Provider__c);
        }
        return request;
    }

    @TestVisible
    private String getSSNForSoftpullTransunionRequest(Lead lead) {
        if (lead.LastName.toLowerCase().contains('testcase')) {
            if (lead.FirstName.toLowerCase().contains('frozen')) {
                return '000000010';
            } else if (lead.FirstName.toLowerCase().contains('fail')) {
                return '000000008';
            }
            return '000000001';
        }
        return '000000000';
    }
}