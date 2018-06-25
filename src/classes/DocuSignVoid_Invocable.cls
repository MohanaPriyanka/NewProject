/*************************************************************************************
 * Created By:  Peter Yao
 * Description: Exposes void envelope method to Process Builder
 * Test: DocuSignHelperTest
 *************************************************************************************/

public with sharing class DocuSignVoid_Invocable {
    @InvocableMethod(Label='Void DocuSign Envelopes' Description='Calls DocuSign API to void envelopes with reason provided')
    public static void voidPackages(List<VoidRequest> requests) {
        for (VoidRequest voidRequest : requests) {
            voidPackageFuture(voidRequest.envelopeId, voidRequest.reason==null?'Automatically voided':voidRequest.reason);
        }
    }

    @Future(Callout=true)
    public static void voidPackageFuture(String envelopeId, String reason) {
        try {
            DocuSignHelper.connect();
            DocuSignAPI.VoidEnvelopeStatus result = DocuSignHelper.dsAPI.VoidEnvelope(envelopeId, reason);
            if (result == null || !result.VoidSuccess) {
                Logger.logLater('DocuSignHelper', 'checkAndRegeneratePackage', 'Unsuccessful void for envelope ' + envelopeId);
            }
        } catch (CalloutException e) {
            Logger.logLater('DocuSignHelper', 'checkAndRegeneratePackage',
                'Callout Exception caught voiding envelope ' + envelopeId + ' error message: ' + e.getMessage());
        }
    }

    public class VoidRequest {
        @InvocableVariable(Required=true)
        public String envelopeId;
        @InvocableVariable(Required=false)
        public String reason;
    }
}