/**
 * Created by Jeff Battles on 3/4/2021.
 * Description: Called from the ScreenFlow_SSS_Date_Customer_Comms Flow to retrieve a List of Send Bills Contacts that are assigned  ta a given SSS
 * Tested By: ContactSelectorTest
 */

public without sharing class InvocableSendBillsContactsSelector {
    @InvocableMethod(Label='Get Send Bills Contacts for a Shared Solar System')

    public static List<List<Contact>> getSendBillsContactsBySSSId(List<GetSendBillsContactsBySSSIdInfo> sssInfo) {
        Id sssId = sssInfo[0].sharedSolarSystemId;
        Boolean includeActiveALSOnly = sssInfo[0].includeActiveALSOnly;
        
        if (includeActiveALSOnly) {
            return new List<List<Contact>>{contactSelector.selectActiveAlsSendBillsContactBySSSId(sssId)};
        }
        else{
            return new List<List<Contact>>{contactSelector.selectSendBillsContactBySSSId(sssId)};
        }
    }

    public class GetSendBillsContactsBySSSIdInfo {
        @InvocableVariable( label='Shared Solar System ID'
                            description='The SSS Id to find related Send Bills Contacts'
                            required=true)
            public Id sharedSolarSystemId;

        @invocableVariable( label='Include Contacts on Active ALS only'
                            description='If yes, only send bill contacts with an active ALS will be returned'
                            required=true)
            public boolean includeActiveALSOnly;
        }
}