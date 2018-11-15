/*************************************************************************************
 * Created By:  Cole Swain
 *
 * Description: Creates Partner Alerts
 *
 * Test: SLPControllersTestclass
 *************************************************************************************/

trigger partnerAlertTrigger on Partner_Alert__c (after insert) {
    if(Trigger.isInsert && Trigger.isAfter){        
        PartnerAlertHandler.createPartnerAlertFilters(Trigger.new);
    }
}