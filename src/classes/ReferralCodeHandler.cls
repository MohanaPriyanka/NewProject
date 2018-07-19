/*************************************************************************************
 * Description: Sets Partner Lookup, Sales Rep, and Partner Email on leads based on Custom ID
 *
 * Tested By: ReferralCodeHandlerTest
 *************************************************************************************/

public with sharing class ReferralCodeHandler {

    public void OnBeforeInsert (Lead[] newLead) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead lead : newLead) {
            if (lead.Product_Line__c == 'Community Solar') {
                leadsToUpdate.add(lead);
            }
        }
        assignAcquisitionObjectFromCustomId(leadsToUpdate);
    }

    public void OnBeforeUpdate(Map<Id, Lead> oldLeadMap, Map<Id, Lead> newLeadMap) {
    List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead leadRecord : newLeadMap.values()) {
            if (leadRecord.Custom_Id__c != oldLeadMap.get(leadRecord.Id).Custom_Id__c) {
                leadsToUpdate.add(leadRecord);
            }
        }
        assignAcquisitionObjectFromCustomId(leadsToUpdate);
    }

    public void assignAcquisitionObjectFromCustomId(list<Lead> leads) {
        BSST__c holderPartner = new BSST__C();
        List <String> leadReferralCodeList = new List<String>();
        Map <String, Contact> contactReferralMap = new Map <String, Contact>();
        Map <String, BSST__c> partnerMap = new Map <String, BSST__c>();
        for (Lead leadRecord : leads) {
                //Where is this custom id for the lead initially being set?
            if (leadRecord.Custom_ID__c != null) {
                leadReferralCodeList.add(leadRecord.Custom_Id__c);
            }
        }
            //why are we adding this string to a list of Ids?
        leadReferralCodeList.add('holder');
        // As of 5/24/17, Custom ID on Leads starts being populated with a Partner ID. This
        // method should use the ID to find a partner as well as a Custom ID.
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c
                                FROM BSST__c
                                WHERE Custom_Id__c IN :leadReferralCodeList
                                OR Id IN :leadReferralCodeList]) {
                                    //Why would the contact ID be in this list?

                //Why is the same partner getting added to the partner map 3 separate times with different versions of its custom Id or ID
            partnerMap.put(partner.Custom_Id__c, partner);
            partnerMap.put(((String) partner.Id).left(15), partner);
            partnerMap.put(partner.Id, partner);
        }

            //Why does this leadReferralCodeList have BSST and Contact Ids in it?
        for (Contact contact : [SELECT Id, Custom_Id__c, Email
                                FROM Contact
                                WHERE Custom_Id__c IN : leadReferralCodeList]) {
            contactReferralMap.put(contact.Custom_Id__c, contact);
        }
        for (lead leadRecord : leads) {
            if (leadRecord.Application_Source_Phase_1__c != 'CSAP with Partner') {
                    //if Partner and BSST are not populated, set holderPartner to holder
                if (leadRecord.Partner_Lookup__c == null && leadRecord.Bs_Sales_Id__c == null) {
                    holderPartner = partnerMap.get('holder');
                }
                    //if lead doesnt have custom Id but holder partner is populated (would have been set right above),
                    // Set Partner, BSST, and Email to Holder
                    // Seems like this would happen most times --> but when does custom id get set?
                    // Is it only set when there is actually a referral code that comes through the pipeline?
                    // Is this why its not populated on the most recent leads because we are not setting it (or just asking for it?) in the CSAP?
                if (leadRecord.Custom_Id__c == null && holderPartner != null) {
                    leadRecord.Partner_Lookup__c = holderPartner.Partner__r.Id;
                    leadRecord.Bs_sales_id__c = holderPartner.Id;
                    leadRecord.Partner_Email__c = holderPartner.Email__c;
                } else {
                        //Because if the Custom Id is populated, you end up here
                        // Checking if the custom Id is associated with a Partner first and then a contact
                        // If not partner or contact, then set it up with Holder partner info
                    if (partnerMap.containsKey(leadRecord.Custom_Id__c)) {
                        BSST__c partner = partnerMap.get(leadRecord.Custom_Id__c);
                        leadRecord.Partner_Lookup__c = partner.Partner__r.Id;
                        leadRecord.Bs_sales_id__c = partner.Id;
                        leadRecord.Partner_Email__c = partner.Email__c;
                    } else if (contactReferralMap.containsKey(leadRecord.Custom_Id__c)) {
                            // Referral code is only being populated when the custom ID is associated with a contact
                        Contact contact = contactReferralMap.get(leadRecord.Custom_Id__c);
                        leadRecord.Customer_referral__c = contact.Id;
                        leadRecord.Referral_email__c = contact.Email;
                    } else if (leadRecord.Product_Line__c == 'Community Solar' && holderPartner != null) {
                        leadRecord.Partner_Lookup__c = holderPartner.Partner__r.Id;
                        leadRecord.Bs_sales_id__c = holderPartner.Id;
                        leadRecord.Partner_Email__c = holderPartner.Email__c;
                    }
                }
            }
        }
    }
}