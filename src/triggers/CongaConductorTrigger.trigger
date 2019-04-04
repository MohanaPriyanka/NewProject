// CS Template assignment and email sending is only triggered off the conga conductor because it is where users
// are currently generating conga pdf records.

trigger CongaConductorTrigger on APXT_BPM__Conductor__c (after update) {

}