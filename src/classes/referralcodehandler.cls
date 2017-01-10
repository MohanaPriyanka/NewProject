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
        integer j;
        integer k;
        integer i;
        integer h;
        string partner;
        list <string> customIds = new List <string>( ); 
        map <string, contact> contactReferralMap = new map <string, contact>();
        map <string, BSST__c> partnersmap = new map <string, BSST__c>();

        for(j = 0; j < trigLeads.size(); j++){
                if ( trigLeads.get(j).custom_id__C != null) {
                        customIds.add (trigLeads.get(j).custom_id__C);
                }
        }

        system.debug(customIds);

        if(customIds.size()>0){

            List <Contact> listContact = [  SELECT Id, Custom_Id__c , email
                                            FROM Contact
                                            WHERE Custom_Id__c IN : customIds];
            system.debug(listContact);

            List <BSST__c> listpartners = [ SELECT id, custom_id__C, partner__r.id, partner__c, email__c
                                            FROM BSST__C
                                            WHERE custom_id__c IN : customIds];
            system.debug(listpartners);
            
            for(i = 0; i < listContact.size(); i++){
                    contactReferralMap.put(listContact.get(i).custom_id__c, listContact.get(i));
            }
            system.debug(contactReferralMap);

            for(h = 0; h < listpartners.size(); h++){
                    partnersmap.put(listpartners.get(h).custom_id__c, listpartners.get(h));
            }
            system.debug(partnersmap);
        }
        
        
                for(k = 0; k < trigLeads.size(); k++){
                    system.debug(contactReferralMap.get(trigLeads.get(k).custom_id__C));
                    system.debug(partnersmap.get(trigLeads.get(k).custom_id__C));
                    
                    if(partnersmap.size()>0){
                            if(partnersmap.get(trigLeads.get(k).custom_id__C) != null){  
                                    trigleads.get(k).Partner_Lookup__c = partnersmap.get(trigleads.get(k).custom_id__C).Partner__c;
                                    trigLeads.get(k).bs_sales_id__c = partnersmap.get(trigLeads.get(k).custom_id__C).id;
                                    trigLeads.get(k).partner_email__c = partnersmap.get(trigLeads.get(k).custom_id__c).email__c;
                                    system.debug(trigLeads.get(k).bs_sales_id__c);
                                    system.debug(trigLeads.get(k).partner_email__c);
                            }

                                else{
                                    trigLeads.get(k).bs_sales_id__c = null;
                                    trigLeads.get(k).partner_email__c = null;
                                }
                    }

                    if(contactReferralMap.size()>0){
                            if(contactReferralMap.get(trigLeads.get(k).custom_id__C) != null){  
                                    trigLeads.get(k).customer_referral__c = contactReferralMap.get(trigLeads.get(k).custom_id__C).id;
                                    trigLeads.get(k).referral_email__c = contactReferralMap.get(trigLeads.get(k).custom_id__c).email;
                                    system.debug(trigLeads.get(k).customer_referral__c);
                                    system.debug(trigLeads.get(k).referral_email__c);
                            }
                            
                                /*else{
                                    trigLeads.get(k).customer_referral__c = null;
                                    trigLeads.get(k).referral_email__c = null;
                                }*/

                    }
                    system.debug(trigLeads.get(k).referral_email__c);

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
                  if (newcid != oldcid && newcid != null) { 
                        triggeredleads.add(newLeads.get(m));
                  }
        } 

        system.debug(triggeredleads);

        // begin normal process
        integer j;
        integer k;
        integer i;
        integer h;
        string partner;
        list <string> customIds = new List <string>( ); 
        map <string, contact> contactReferralMap = new map <string, contact>();
        map <string, BSST__c> partnersmap = new map <string, BSST__c>();

        for(j = 0; j < triggeredleads.size(); j++){
                if ( triggeredleads.get(j).custom_id__C != null) {
                        customIds.add (triggeredleads.get(j).custom_id__C);
                }
        }

        system.debug(customIds);

        if(customIds.size()>0){

            List <Contact> listContact = [  SELECT Id, Custom_Id__c , email
                                            FROM Contact
                                            WHERE Custom_Id__c IN : customIds];
            system.debug(listContact);

            List <BSST__c> listpartners = [ SELECT id, custom_id__C, partner__r.id, partner__c, email__c
                                            FROM BSST__C
                                            WHERE custom_id__c IN : customIds];
            system.debug(listpartners);
            
            for(i = 0; i < listContact.size(); i++){
                    contactReferralMap.put(listContact.get(i).custom_id__c, listContact.get(i));
            }
            system.debug(contactReferralMap);

            for(h = 0; h < listpartners.size(); h++){
                    partnersmap.put(listpartners.get(h).custom_id__c, listpartners.get(h));
            }
            system.debug(partnersmap);
        }
        
        
                for(k = 0; k < triggeredleads.size(); k++){
                    system.debug(contactReferralMap.get(triggeredleads.get(k).custom_id__C));
                    system.debug(partnersmap.get(triggeredleads.get(k).custom_id__C));
                    
                    if(partnersmap.size()>0){
                            if(partnersmap.get(triggeredleads.get(k).custom_id__C) != null){  
                                    triggeredleads.get(k).Partner_Lookup__c = partnersmap.get(triggeredleads.get(k).custom_id__C).Partner__c;
                                    triggeredleads.get(k).bs_sales_id__c = partnersmap.get(triggeredleads.get(k).custom_id__C).id;
                                    triggeredleads.get(k).partner_email__c = partnersmap.get(triggeredleads.get(k).custom_id__c).email__c;
                                    system.debug(triggeredleads.get(k).bs_sales_id__c);
                                    system.debug(triggeredleads.get(k).partner_email__c);
                            }

                                else{
                                    triggeredleads.get(k).bs_sales_id__c = null;
                                    triggeredleads.get(k).partner_email__c = null;
                                }
                    }

                    if(contactReferralMap.size()>0){
                            if(contactReferralMap.get(triggeredleads.get(k).custom_id__C) != null){  
                                    triggeredleads.get(k).customer_referral__c = contactReferralMap.get(triggeredleads.get(k).custom_id__C).id;
                                    triggeredleads.get(k).referral_email__c = contactReferralMap.get(triggeredleads.get(k).custom_id__c).email;
                                    system.debug(triggeredleads.get(k).customer_referral__c);
                                    system.debug(triggeredleads.get(k).referral_email__c);
                            }
                            
                                else{
                                    triggeredleads.get(k).customer_referral__c = null;
                                    triggeredleads.get(k).referral_email__c = null;
                                }

                    }
                }
    }
}