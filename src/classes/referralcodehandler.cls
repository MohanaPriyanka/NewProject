public with sharing class referralcodehandler {

    public void OnBeforeInsert (Lead[] newLead){
        assignAcquisitionObjectFromCustomId(newLead);
    }

    public void OnBeforeUpdate(Map<Id, Lead> oldLeadMap, Map<Id, Lead> newLeadMap){
    List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead leadRecord : newLeadMap.values()) {
            if (leadRecord.Custom_Id__c != oldLeadMap.get(leadRecord.Id).Custom_Id__c && leadRecord.Product_Line__c == 'Community Solar') {
                leadsToUpdate.add(leadRecord);
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            assignAcquisitionObjectFromCustomId(leadsToUpdate);            
        }
    }

    public void assignAcquisitionObjectFromCustomId(list<Lead> leads){
        String partnerlookup;
        String salesid;
        String email;
        List <String> leadReferralCodeList = new List<String>();
        Map <String, Contact> contactReferralMap = new Map <String, Contact>();
        Map <String, BSST__c> partnerMap = new Map <String, BSST__c>();

        for (Lead leadRecord : leads) {
            if (leadRecord.Custom_ID__c != null) {
                leadReferralCodeList.add(leadRecord .Custom_Id__c);
            }
        }
        leadReferralCodeList.add('holder');
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c 
                                FROM BSST__c 
                                WHERE Custom_Id__c IN : leadReferralCodeList]){
            partnerMap.put(partner.Custom_Id__c, partner);
        } 
        for (Contact contact : [SELECT Id, Custom_Id__c, Email
                                FROM Contact
                                WHERE Custom_Id__c IN : leadReferralCodeList]){
            contactReferralMap.put(contact.Custom_Id__c, contact);
        }

        for(lead leadRecord : leads){
            if(leadRecord.Custom_Id__c == null){
                if(partnerMap.containsKey('holder')){
                    partnerlookup = partnerMap.get('holder').Partner__r.Id;
                    salesid = partnerMap.get('holder').Id;
                    email = partnerMap.get('holder').Email__c;
                } else{
                    partnerlookup = null;
                    salesid = null;
                    email = null;
                }
            } else if(leadRecord.Custom_Id__c != null){
                if(partnerMap.containsKey(leadRecord.Custom_Id__c) && !contactReferralMap.containsKey(leadRecord.Custom_Id__c)){
                    partnerlookup = partnerMap.get(leadRecord.Custom_Id__c).Partner__r.Id;
                    salesid = partnerMap.get(leadRecord.Custom_Id__c).Id;
                    email = partnerMap.get(leadRecord.Custom_Id__c).Email__c;
                } else if(contactReferralMap.containsKey(leadRecord.Custom_Id__c) && !partnerMap.containsKey(leadRecord.Custom_Id__c)){
                    leadRecord.Customer_referral__c = contactReferralMap.get(leadRecord.Custom_Id__c).Id;
                    leadRecord.Referral_email__c = contactReferralMap.get(leadRecord.Custom_Id__c).Email;
                } else if (!contactReferralMap.containsKey(leadRecord.Custom_Id__c) && !partnerMap.containsKey(leadRecord.Custom_Id__c)){
                    if (leadRecord.Product_Line__c == 'Residential Loan') {
                        return;                   
                    }
                    if (leadRecord.Product_Line__c == 'Community Solar') {
                        if(partnerMap.containsKey('holder')){
                            partnerlookup = partnerMap.get('holder').Partner__r.Id;
                            salesid = partnerMap.get('holder').Id;
                            email = partnerMap.get('holder').Email__c;
                        }
                    }
                } else {
                    if (leadRecord.Product_Line__c == 'Residential Loan') {
                        return;                   
                    }
                    if (leadRecord.Product_Line__c == 'Community Solar') {
                        if(partnerMap.containsKey('holder')){
                            partnerlookup = partnerMap.get('holder').Partner__r.Id;
                            salesid = partnerMap.get('holder').Id;
                            email = partnerMap.get('holder').Email__c;
                        }
                    }                    
                }
            }        
            if(partnerlookup != null){
                leadRecord.Partner_Lookup__c = partnerlookup;
            }
            if(salesid != null){
                leadRecord.Bs_sales_id__c = salesid;
            }
            if(email != null){
                leadRecord.Partner_Email__c = email;
            }
        }   
    }
}