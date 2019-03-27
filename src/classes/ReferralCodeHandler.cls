/*************************************************************************************
 * Description: Sets Partner Lookup, Sales Rep, and Partner Email on leads based on Custom ID
 *
 * Tested By: ReferralCodeHandlerTest
 *************************************************************************************/

public without sharing class ReferralCodeHandler {

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
            if (leadRecord.Custom_ID__c != null) {
                leadReferralCodeList.add(leadRecord.Custom_Id__c);
            }
        }

        leadReferralCodeList.add('holder');
        // As of 5/24/17, Custom ID on Leads starts being populated with a Partner ID. This
        // method should use the ID to find a partner as well as a Custom ID.
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c
                                FROM BSST__c
                                WHERE Custom_Id__c IN :leadReferralCodeList
                                OR Id IN :leadReferralCodeList]) {


            partnerMap.put(partner.Custom_Id__c, partner);
            partnerMap.put(((String) partner.Id).left(15), partner);
            partnerMap.put(partner.Id, partner);
        }

        for (Contact contact : [SELECT Id, Custom_Id__c, Email
                                FROM Contact
                                WHERE Custom_Id__c IN : leadReferralCodeList]) {
            contactReferralMap.put(contact.Custom_Id__c, contact);
        }
        for (lead leadRecord : leads) {
            if (leadRecord.Application_Source_Phase_1__c != 'CSAP 2.1 with Partner'
                && leadRecord.Application_Source_Phase_1__c != 'CSAP 3.0 Flow with Partner'
                && leadRecord.Application_Source_Phase_1__c != 'CSAP 2.1 with Inside Sales') {
                if (leadRecord.Partner_Lookup__c == null && leadRecord.Bs_Sales_Id__c == null) {
                    holderPartner = partnerMap.get('holder');
                }
                if (leadRecord.Custom_Id__c == null && holderPartner != null) {
                    leadRecord.Partner_Lookup__c = holderPartner.Partner__r.Id;
                    leadRecord.Bs_sales_id__c = holderPartner.Id;
                    leadRecord.Partner_Email__c = holderPartner.Email__c;
                } else {
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