/**
 * Created by peteryao on 2/19/20.
 * Tested by: CSLeadsRESTControllerV3Test
 */

public without sharing class CSLeadsRESTControllerV3 extends CSLeadsRESTControllerV2 {
    public void validateAuthorization(Id leadId, String email) {
        Lead lead = leadSelector.selectOne(leadId);
        if (lead == null || lead.Email != email) {
            throw new Util.AuthorizationBWException('Invalid authorization, the leadId ('+leadId+')does not match the email ('+email+')');
        }
    }

    public override void patchLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        validateAuthorization(requestLead.id, requestLead.email);
        super.patchLead(jsonRequest);
    }

    public override void patchPropertyAccount(String jsonRequest) {
        RestLead.RestPropertyAccount requestAccount = (RestLead.RestPropertyAccount) JSON.deserialize(jsonRequest, RestLead.RestPropertyAccount.class);
        validateAuthorization(requestAccount.leadId, requestAccount.email);
        super.patchPropertyAccount(jsonRequest);
    }

    public override void patchUtilityAccountLog(String jsonRequest) {
        RestLead.RestUtilityAccountLog requestUAL = (RestLead.RestUtilityAccountLog) JSON.deserialize(jsonRequest, RestLead.RestUtilityAccountLog.class);
        validateAuthorization(requestUAL.leadId, requestUAL.email);
        super.patchUtilityAccountLog(jsonRequest);
    }

    public override void patchApplication(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        validateAuthorization(requestLead.id, requestLead.email);
        super.patchApplication(jsonRequest);
    }

    public override void patchContract(String jsonRequest) {
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        if(requestMap.containsKey('leadId') && requestMap.containsKey('email')) {
            Id leadId = (Id) requestMap.get('leadId');
            String email = (String) requestMap.get('email');
            validateAuthorization(leadId, email);
        } else {
            throw new Util.AuthorizationBWException('Invalid authorization - the correct fields must be provided for authorization');
        }
        
        super.patchContract(jsonRequest);
    }

    public override void getLead(String leadId, String email) {
        // validation performed in V2
        super.getLead(leadId, email);
    }
}