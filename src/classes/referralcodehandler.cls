// replaces referralCodeMap trigger on the lead 

public with sharing class referralcodehandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public referralcodehandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeInsert (Lead[] newLead){
      referralcodeinsert(newLead);
  }

  public void OnBeforeUpdate(Lead[] newLeads, Lead[] oldLeads){
      referralcode(newLeads, oldLeads);
  }

  private void referralcodeinsert(list<Lead> trigLeads){
        string partnerlookup;
        string salesid;
        string email;
        List <String> leadReferralCodeList = new List<String>();
        map <string, contact> contactReferralMap = new map <string, contact>();
        map <string, BSST__c> partnermap = new map <string, BSST__c>();


        for(Lead ld : trigLeads){
            leadReferralCodeList.add('holder');
            if(ld.Custom_ID__c != null){
                leadReferralCodeList.add(ld.Custom_Id__c);
            }
        }
        
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c 
                                FROM BSST__c 
                                WHERE Custom_Id__c IN : leadReferralCodeList]){
                partnerMap.put(partner.Custom_Id__c, partner);
        }
        System.debug('PartnerMap ' + partnerMap);   

        for (Contact contact : [SELECT Id, Custom_Id__c , email
                                    FROM Contact
                                    WHERE Custom_Id__c IN : leadReferralCodeList]){
                contactReferralMap.put(contact.Custom_Id__c, contact);
        }
        System.debug('ContactMap ' + contactReferralMap);  

        for(lead l : trigLeads){
            if(l.Custom_Id__c == null){
                if(partnerMap.containsKey('holder')){
                    system.debug(partnerMap.get('holder').Partner__r.Id);
                    partnerlookup = partnerMap.get('holder').Partner__r.Id;
                    salesid = partnerMap.get('holder').Id;
                    email = partnerMap.get('holder').Email__c;
                }
                else{
                    partnerlookup = null;
                    salesid = null;
                    email = null;
                }
            }
            if(l.Custom_Id__c != null){
                if(partnerMap.containsKey(l.Custom_Id__c)){
                    partnerlookup = partnerMap.get(l.Custom_Id__c).Partner__r.Id;
                    salesid = partnerMap.get(l.Custom_Id__c).Id;
                    email = partnerMap.get(l.Custom_Id__c).Email__c;
                }
                else if(contactReferralMap.containsKey(l.Custom_Id__c)){
                    l.customer_referral__c = contactReferralMap.get(l.custom_id__C).id;
                    l.referral_email__c = contactReferralMap.get(l.custom_id__c).email;
                }
                else{
                    if(partnerMap.containsKey('holder')){
                        partnerlookup = partnerMap.get('holder').Partner__r.Id;
                        salesid = partnerMap.get('holder').Id;
                        email = partnerMap.get('holder').Email__c;
                    }
                }
            }
            system.debug(partnerlookup);
            system.debug(salesid);
            system.debug(email);
            
            if(partnerlookup != null){
                l.Partner_Lookup__c = partnerlookup;
            }
            if(salesid != null){
                l.Bs_sales_id__c = salesid;
            }
            if(email != null){
                l.Partner_Email__c = email;
            }
        }   

  }

  private void referralcode(List<Lead> oldLeads, List<Lead> newLeads){
   
        system.debug(oldLeads);
        system.debug(newLeads);

        integer m;

        Map<Id, Lead> oldvalues = new Map<Id, Lead> ();
        List<Lead> triggeredleads = new list<Lead> ();

        for(Lead oldLead: oldLeads){
              oldvalues.put(oldLead.id, oldLead);
        }

        for(m = 0; m < newLeads.size(); m++){  
              string newvalueID = newLeads.get(m).Id;
              string newcid = newLeads.get(m).Custom_Id__c;
              string oldcid = oldvalues.get(newvalueID).Custom_Id__c;
                  if (newcid != oldcid) { 
                        triggeredleads.add(newLeads.get(m));
                  }
        } 

        system.debug(triggeredleads);

        // begin normal process
        string partnerlookup;
        string salesid;
        string email;
        List <String> leadReferralCodeList = new List<String>();
        map <string, contact> contactReferralMap = new map <string, contact>();
        map <string, BSST__c> partnermap = new map <string, BSST__c>();

        for(Lead ld : triggeredleads){
            leadReferralCodeList.add('holder');
            if(ld.Custom_ID__c != null){
                leadReferralCodeList.add(ld.Custom_Id__c);
            }
        }
        
        for (BSST__c partner : [SELECT Id, Name, Custom_Id__c, Partner__r.Id, Email__c 
                                FROM BSST__c 
                                WHERE Custom_Id__c IN : leadReferralCodeList]){
                partnerMap.put(partner.Custom_Id__c, partner);
        }
        System.debug('PartnerMap ' + partnerMap);   

        for (Contact contact : [SELECT Id, Custom_Id__c , email
                                    FROM Contact
                                    WHERE Custom_Id__c IN : leadReferralCodeList]){
                contactReferralMap.put(contact.Custom_Id__c, contact);
        }
        System.debug('ContactMap ' + contactReferralMap);  

        for(lead l : triggeredleads){
            if(l.Custom_Id__c == null){
                if(partnerMap.containsKey('holder')){
                    system.debug(partnerMap.get('holder').Partner__r.Id);
                    partnerlookup = partnerMap.get('holder').Partner__r.Id;
                    salesid = partnerMap.get('holder').Id;
                    email = partnerMap.get('holder').Email__c;
                }
                else{
                    partnerlookup = null;
                    salesid = null;
                    email = null;
                }
            }
            if(l.Custom_Id__c != null){
                if(partnerMap.containsKey(l.Custom_Id__c)){
                    partnerlookup = partnerMap.get(l.Custom_Id__c).Partner__r.Id;
                    salesid = partnerMap.get(l.Custom_Id__c).Id;
                    email = partnerMap.get(l.Custom_Id__c).Email__c;
                }
                else if(contactReferralMap.containsKey(l.Custom_Id__c)){
                    l.customer_referral__c = contactReferralMap.get(l.custom_id__C).id;
                    l.referral_email__c = contactReferralMap.get(l.custom_id__c).email;
                }
                else{
                    if(partnerMap.containsKey('holder')){
                        partnerlookup = partnerMap.get('holder').Partner__r.Id;
                        salesid = partnerMap.get('holder').Id;
                        email = partnerMap.get('holder').Email__c;
                    }
                }
            }
            system.debug(partnerlookup);
            system.debug(salesid);
            system.debug(email);
            
            if(partnerlookup != null){
                l.Partner_Lookup__c = partnerlookup;
            }
            if(salesid != null){
                l.Bs_sales_id__c = salesid;
            }
            if(email != null){
                l.Partner_Email__c = email;
            }
        }
   }   

}