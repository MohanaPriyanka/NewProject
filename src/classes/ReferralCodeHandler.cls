/*************************************************************************************
 * Description: Sets Partner Lookup, Sales Rep, and Partner Email on leads based on Custom ID
 *
 * Tested By: ReferralCodeHandlerTest
 *
 * Notes: As of 5/24/17, Custom ID on Leads starts being populated with a Partner ID. This
          method should use the ID to find a partner as well as a Custom ID.

          SR (5/28/2019): As we begin to handle Switch leads, we are cleaning the code and creating a
          LeadTrigger (LeadTriggerHandler 2.0). When CSAP is retired, we will also retire this class
 *************************************************************************************/

public without sharing class ReferralCodeHandler {

    public void OnBeforeInsert (Lead[] newLead) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead lead : newLead) {
            if (lead.Product_Line__c == 'Community Solar') {
                leadsToUpdate.add(lead);
            }
        }
        assignPartner(leadsToUpdate);
    }

    public void assignPartner(list<Lead> leads) {
        //Update to set the Default Partner and Sales Rep to BlueWave Inside Sales (not Placeholder Partner or Bluewave inside sales)
        Partner__c defaultCSPartner = new Partner__c();
        BSST__c defaultRep = new BSST__c();
        List <String> leadReferralCodeList = new List<String>();
        Map <String, BSST__c> partnerMap = new Map <String, BSST__c>();
        for (Lead leadRecord : leads) {
            if (leadRecord.Custom_ID__c != null) {
                leadReferralCodeList.add(leadRecord.Custom_Id__c);
            }
        }
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c
                                FROM BSST__c
                                WHERE Custom_Id__c IN :leadReferralCodeList
                                OR Id IN :leadReferralCodeList]) {


            partnerMap.put(partner.Custom_Id__c, partner);
            partnerMap.put(((String) partner.Id).left(15), partner);
            partnerMap.put(partner.Id, partner);
        }

        try {
            defaultCSPartner = PartnerSelector.selectDefaultCSPartner();
        } catch (Exception e ) {
            defaultCSPartner = null;
        }


        for (lead leadRecord : leads) {
            if (leadRecord.Partner_Lookup__c == null) {
                //Need to assign partner if it is empty - meaning it came from the Website or from a Campaign
                if (leadRecord.Custom_ID__c == null && defaultCSPartner != null) {
                    leadRecord.Partner_Lookup__c = defaultCSPartner.Id;
                    leadRecord.bs_Sales_ID__c = defaultRep.Id;
                    leadRecord.Partner_Email__c = defaultCSPartner.Email__c;
                } else {
                    if (partnerMap.containsKey(leadRecord.Custom_ID__c)) {
                        BSST__c partner = partnerMap.get(leadRecord.Custom_ID__c);
                        leadRecord.Partner_Lookup__c = partner.Partner__r.Id;
                        leadRecord.bs_Sales_ID__c = partner.Id;
                        leadRecord.Partner_Email__c = partner.Email__c;
                    }
                }




            }
        }
    }
}