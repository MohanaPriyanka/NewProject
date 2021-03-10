/**
 * Created by Jeff Battles on 3/4/2021.
 * Description: Called from the ScreenFlow_SSS_Date_Customer_Comms Flow to retrieve a List of Send Bills Contacts that are assigned  ta a given SSS
 * Tested By: ContactSelectorTest
 */

public without sharing class InvocableSendBillsContactsSelector {
    @InvocableMethod(Label='Get Send Bills Contacts for a Shared Solar System')

    public static List<List<Contact>> getSendBillsContactsBySSSId(List<Id> sharedSolarSystemId) {
        return new List<List<Contact>>{ContactSelector.selectSendBillsContactBySSSId(sharedSolarSystemId[0])};
    }
}