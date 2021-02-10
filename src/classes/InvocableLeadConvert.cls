/**
 * Created by SarahRenfro on 12/29/2020.
 *
 * Description: Called from the Lead_Qualification_Conversion Flow to Convert Leads
 * Tested By: PostSandboxRefresherTest
 */

public with sharing class InvocableLeadConvert {
    @InvocableMethod(Label='Invocable Lead Converter' Description='Converts a Lead from Lead Qualification/Conversion Flow')
    public static void convertLead(List<Id> leadIdsToConvert) {
        Lead leadToConvert = new LeadSelector().selectOne(leadIdsToConvert[0]);
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(leadToConvert.Id);
        leadConvert.setConvertedStatus('Qualified');
        leadConvert.setDoNotCreateOpportunity(true);
        leadConverts.add(leadConvert);

        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        for (Database.LeadConvertResult lcr : lcrs) {
            if (!lcr.isSuccess()) {
                Logger.logNow('InvocableLeadConvert','convertLead','CS Lead conversion failed for Id: ' + leadToConvert.Id +' error:' + lcr.getErrors()[0].getMessage());
                throw new Util.BWException('Sorry there was an error converting the lead! BizApps has already been notified.');
            }
        }
    }
}