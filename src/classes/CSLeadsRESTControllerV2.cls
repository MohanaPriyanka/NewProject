/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test
 */


global without sharing class CSLeadsRESTControllerV2 extends RESTController {

    @TestVisible private LeadService leadService = new LeadService();
    @TestVisible private AccountService accountService = new AccountService();
    @TestVisible private UALService ualService = new UALService();

    @TestVisible private LeadSelector leadSelector = new LeadSelector();
    @TestVisible private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private UALSelector ualSelector = new UALSelector();

    public void patchLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;

        Lead leadToUpdate = leadSelector.selectOne(requestLead.id);
        if (leadToUpdate == null) {
            response.statusCode = statusCode.notFound;
        } else if (requestLead.applicationCompleteDate != null ) {
            if (leadToUpdate.Application_Complete_Date__c == null) {
                //pull credit, only once; on first time the app complete date is set
                leadToUpdate.Soft_Pull_Credit_Report__c = true;
            }
            leadToUpdate.Application_Complete_Date__c = requestLead.applicationCompleteDate;

            Lead lead = leadService.updateLead(leadToUpdate);

            // TODO: need to respond with full data structure to UI (e.g. include property accts and UALs)
            RestLead responseLead = new RestLead(lead);
            envelope.setData(responseLead);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }
        envelope.setJSONResponse(response);
    }

    public void patchPropertyAccount(String jsonRequest) {
        RestLead.RestPropertyAccount requestAccount = (RestLead.RestPropertyAccount) JSON.deserialize(jsonRequest, RestLead.RestPropertyAccount.class);
        RestResponse response = RestContext.response;

        Account accountToUpdate = accountsSelector.selectOne(requestAccount.id);

        if (accountToUpdate == null) {
            response.statusCode = statusCode.notFound;
        } else if (!String.isEmpty(requestAccount.zuoraPaymentRefId) && requestAccount.zuoraPaymentRefIdExpirationDate != null) {
            accountToUpdate.Zuora_Payment_Ref_Id__c = requestAccount.zuoraPaymentRefId;
            accountToUpdate.Zuora_Payment_Ref_Id_Expiration_Date__c = requestAccount.zuoraPaymentRefIdExpirationDate;

            Account account = accountService.updateAccount(accountToUpdate);

            // TODO: need to respond with full data structure to UI (e.g. include  UALs)
            RestLead.RestPropertyAccount responseAccount = new RestLead.RestPropertyAccount(account);
            envelope.setData(responseAccount);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public void patchUtilityAccountLog(String jsonRequest) {
        RestLead.RestUtilityAccountLog requestUAL = (RestLead.RestUtilityAccountLog) JSON.deserialize(jsonRequest, RestLead.RestUtilityAccountLog.class);
        RestResponse response = RestContext.response;

        Utility_Account_Log__c ualToUpdate = ualSelector.selectOne(requestUAL.id);

        if (ualToUpdate == null) {
            response.statusCode = statusCode.notFound;
        } else if (requestUAL.annualKWh != null) {
            ualToUpdate.Annual_kWh__c = requestUAL.annualKWh;

            Utility_Account_Log__c ual = ualService.updateUAL(ualToUpdate);

            RestLead.RestUtilityAccountLog responseUAL = new RestLead.RestUtilityAccountLog(ual);
            envelope.setData(responseUAL);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public void postLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;

        Boolean validRequest = false;
        try {
            requestLead.validateCreateFields();
            // We can only handle one (and only one) property account, right now.
            // Remove this once the unit-of-work approach is implemented in in the blocks towards the end of this method
            if (requestLead.propertyAccounts != null && requestLead.propertyAccounts.size() == 1) {
                validRequest = true;
            } else {
                validRequest = false;
                envelope.addError('Currently, only one propertyAccount per lead is supported in the API.');
                response.statusCode = statusCode.badRequest;
            }
        } catch (Util.BWException e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.badRequest;
        }

        if (validRequest) {
            Lead newLead = requestLead.asLead();

            newLead = leadService.insertLead(newLead);

            RestLead responseLead = new RestLead(newLead);

            responseLead.propertyAccounts = new List<RestLead.RestPropertyAccount>();

            // TODO: the following logic only handles (1) propertyAccount [e.g. 1:(1):many], until we incorporate
            // unit-of-work (uow) approach.
            // The commented code after this block is the "loop" logic that salesforce/pyao advises against using, but is a
            // reference implementation (that we could verify against) for when we use the uow approach
            // to support more than one propertyAccount.
            Account newAccount = requestLead.propertyAccounts.get(0).asAccount(newLead);
            newAccount = accountService.insertAccount(newAccount);
            RestLead.RestPropertyAccount responsePropertyAccount = new RestLead.RestPropertyAccount(newAccount);
            responseLead.propertyAccounts.add(responsePropertyAccount);

            List<Utility_Account_Log__c> ualsToInsert = new List<Utility_Account_Log__c>();
            for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : requestLead.propertyAccounts.get(0).utilityAccountLogs) {
                ualsToInsert.add(requestUtilityAccountLog.asUAL(newAccount));
            }

            List<Utility_Account_Log__c> newUALs = ualService.insertUALs(ualsToInsert);
            responsePropertyAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>();
            for (Utility_Account_Log__c newUAL : newUALs) {
                responsePropertyAccount.utilityAccountLogs.add(new RestLead.RestUtilityAccountLog(newUAL));
            }

            // DON'T USE THIS COMMENTED OUT CODE IN PRODUCTION!
            //  - This is only a reference implementation for when we implement the unit-of-work approach.
            //  - See comments earlier in this method for more context.

//            for (RestLead.RestPropertyAccount requestPropertyAccount : requestLead.propertyAccounts) {
//                Account newAccount = requestPropertyAccount.asAccount(newLead);
//                newAccount = accountService.insertAccount(newAccount);
//                RestLead.RestPropertyAccount responsePropertyAccount = new RestLead.RestPropertyAccount(newAccount);
//                responseLead.propertyAccounts.add(responsePropertyAccount);
//
//                responsePropertyAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>();
//                for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : requestPropertyAccount.utilityAccountLogs) {
//                    Utility_Account_Log__c newUAL = requestUtilityAccountLog.asUAL(newAccount);
//                    newUAL = ualService.insertUAL(newUAL);
//                    responsePropertyAccount.utilityAccountLogs.add(new RestLead.RestUtilityAccountLog(newUAL));
//                }
//            }

            envelope.setData(responseLead);
            response.statusCode = statusCode.created;

        }
        envelope.setJSONResponse(response);

    }


}