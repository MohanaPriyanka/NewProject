/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test
 */

public virtual without sharing class CSLeadsRESTControllerV2 extends RESTController {
    @TestVisible private LeadService leadService = new LeadService();
    @TestVisible private AccountService accountService = new AccountService();
    @TestVisible private UALService ualService = new UALService();
    @TestVisible private CSLeadsDuplicateService duplicateService = new CSLeadsDuplicateService();
    @TestVisible private CapacityService capacityService = new CapacityService();

    @TestVisible protected LeadSelector leadSelector = new LeadSelector();
    @TestVisible private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private UALSelector ualSelector = new UALSelector();
    @TestVisible private String baseUrl = Util.getCommunitySiteURL('Apply') + '/s/switch';

    
    public virtual void getLead(String leadId, String email) {
        RestResponse response = RestContext.response;
        if(leadId == null || email == null) {
            envelope.addError('Request did not include correct fields to retrieve lead');
            response.statusCode = statusCode.badRequest;
        } else {
            Lead leadToReturn = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
            if (leadToReturn == null || leadToReturn.Email != email) {
                throw new Util.AuthorizationBWException('Invalid authorization, the leadId (' + leadId + ') does not match the email (' + email + ')');
            } else if(leadToReturn.Accounts__r.size() > 1) {
                envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
                response.statusCode = statusCode.badRequest;
            } else {
                RestLead responseLead = new RestLead(leadToReturn);
                List<RestLead.RestUtilityAccountLog> ualList = new List<RestLead.RestUtilityAccountLog>();
                for(Utility_Account_Log__c ual : leadToReturn.Utility_Account_Logs__r) {
                    ualList.add(new RestLead.RestUtilityAccountLog(ual));
                }
                RestLead.RestPropertyAccount propAcct = new RestLead.RestPropertyAccount(leadToReturn.Accounts__r[0]);
                propAcct.utilityAccountLogs = ualList;
                responseLead.propertyAccounts = new List<RestLead.RestPropertyAccount>{propAcct};
                
                envelope.setData(responseLead);
                response.statusCode = statusCode.ok;
            }
        }

        envelope.setJSONResponse(response);
    }
    
    public virtual void patchLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;

        Lead leadToUpdate = leadSelector.selectOne(requestLead.id);
        if (leadToUpdate == null) {
            response.statusCode = statusCode.notFound;
        } else {
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
            if (requestMap.size() <= 1) { // if == 1, then only has "id", which is not enough fields for a PATCH
                envelope.addError('Request did not include correct fields to update');
                response.statusCode = statusCode.badRequest;
            } else {
                if (requestLead.applicationCompleteDate != null && leadToUpdate.Application_Complete_Date__c == null) {
                    //pull credit, only once; on first time the app complete date is set
                    leadToUpdate.Soft_Pull_Credit_Report__c = true;
                    List<Account> propertyAccounts =  accountsSelector.selectPropertyAccountsByLeadIds(new Set<Id> {requestLead.Id});
                    ZuoraAccountService.createAccounts(propertyAccounts);
                }
                requestLead.mergeFields(requestMap.keySet(), leadToUpdate);

                Lead lead = leadService.updateLead(leadToUpdate);

                // TODO: should eventually respond with full data structure to UI (e.g. include property accts and UALs).  Maybe when unit-of-work is implemented?
                RestLead responseLead = new RestLead(lead);
                envelope.setData(responseLead);
                response.statusCode = statusCode.ok;
            }
        }
        envelope.setJSONResponse(response);
    }

    public virtual void patchPropertyAccount(String jsonRequest) {
        RestLead.RestPropertyAccount requestAccount = (RestLead.RestPropertyAccount) JSON.deserialize(jsonRequest, RestLead.RestPropertyAccount.class);
        RestResponse response = RestContext.response;

        Account accountToUpdate = accountsSelector.selectOne(requestAccount.id);

        if (accountToUpdate == null) {
            response.statusCode = statusCode.notFound;
        } else if (!String.isEmpty(requestAccount.zuoraPaymentRefId) && requestAccount.zuoraPaymentRefIdExpirationDate != null) {
            accountToUpdate.Zuora_Payment_Ref_Id__c = requestAccount.zuoraPaymentRefId;
            accountToUpdate.Zuora_Payment_Ref_Id_Expiration_Date__c = requestAccount.zuoraPaymentRefIdExpirationDate;

            Account account = accountService.updateAccount(accountToUpdate);

            // TODO: should eventually respond with full data structure to UI (e.g. include  UALs).  Maybe when unit-of-work is implemented?
            RestLead.RestPropertyAccount responseAccount = new RestLead.RestPropertyAccount(account);
            envelope.setData(responseAccount);
            response.statusCode = statusCode.ok;
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
        }

        envelope.setJSONResponse(response);
    }

    public virtual void patchUtilityAccountLog(String jsonRequest) {
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

    public virtual void patchApplication(String jsonRequest) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;

        if (applicationValid(jsonRequest, response)) { // check for null, propertyAccount.size(), etc. 
            Savepoint sp = Database.setSavepoint();
            try {
                updateLead(jsonRequest);
                updateAccount(jsonRequest);
                updateUtilityAccountLogs(jsonRequest);

                Lead leadToReturn = leadSelector.selectOneWithPropertiesAndUtilities(requestLead.id);
                RestLead responseLead = new RestLead(leadToReturn);
                responseLead.propertyAccounts = new List<RestLead.RestPropertyAccount>{new RestLead.RestPropertyAccount(leadToReturn.Accounts__r[0])};
                List<RestLead.RestUtilityAccountLog> ualForReturn = new List<RestLead.RestUtilityAccountLog>();
                for(Utility_Account_Log__c ual : leadToReturn.Utility_Account_Logs__r) {
                    ualForReturn.add(new RestLead.RestUtilityAccountLog(ual));
                }
                responseLead.propertyAccounts.get(0).utilityAccountLogs = ualForReturn;
                envelope.setData(responseLead);
                response.statusCode = statusCode.ok;
            } catch (Util.BWException bwe) {
                envelope.addError(bwe.getMessage());
                response.statusCode = statusCode.badRequest;
                Database.rollback(sp);
            } catch (Exception e) {
                envelope.addError(e.getMessage());
                response.statusCode = statusCode.internalServerError;
                Database.rollback(sp);
            }
        }
        
        envelope.setJSONResponse(response);
    }

    public virtual void postLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;

        Boolean validRequest = false;
        try {
            requestLead.validateCreateFields();
            // We can only handle one (and only one) property account, right now.
            // Remove this once the unit-of-work approach is implemented in in the blocks towards the end of this method
            validRequest = true;
            if (requestLead.propertyAccounts != null && requestLead.propertyAccounts.size() > 1) {
                validRequest = false;
                envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
                response.statusCode = statusCode.badRequest;
            }
        } catch (Util.BWException e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.badRequest;
        }

        if (validRequest) {
            insertLeadAccountAndUALs(requestLead, response);
        }
        envelope.setJSONResponse(response);

    }

    public virtual void postPropertyAccount(String jsonRequest) {
        RestLead.RestPropertyAccount requestPropertyAccount = (RestLead.RestPropertyAccount) JSON.deserialize(jsonRequest, RestLead.RestPropertyAccount.class);
        RestResponse response = RestContext.response;

        Boolean validRequest = false;
        try {
            requestPropertyAccount.validateCreateFields();
            validRequest = true;
        } catch (Util.BWException e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.badRequest;
            envelope.setJSONResponse(response);
            return;
        }

        Lead associatedLead = leadSelector.selectOne(requestPropertyAccount.leadId);
        if (associatedLead == null) {
            response.statusCode = statusCode.notFound;
            envelope.addError('Lead not found');
            envelope.setJSONResponse(response);
            return;
        }

        List<Account> existingPropertyAccounts = accountsSelector.selectPropertyAccountsByLeadIds(new Set<Id>{requestPropertyAccount.leadId});
        if (existingPropertyAccounts != null && !existingPropertyAccounts.isEmpty()) {
            response.statusCode = statusCode.badRequest;
            envelope.addError('Cannot POST additional Property Accounts to this Lead, since currently only <=1 propertyAccount per lead is supported, and one already exists for this Lead.');
            envelope.setJSONResponse(response);
            return;
        }

        Account newPropertyAccount = requestPropertyAccount.asAccount(associatedLead);

        newPropertyAccount = accountService.insertAccount(newPropertyAccount);

        RestLead.RestPropertyAccount responsePropertyAccount = new RestLead.RestPropertyAccount(newPropertyAccount);

        if (requestPropertyAccount.utilityAccountLogs != null && !requestPropertyAccount.utilityAccountLogs.isEmpty()) {
            List<Utility_Account_Log__c> ualsToInsert = new List<Utility_Account_Log__c>();
            for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : requestPropertyAccount.utilityAccountLogs) {
                ualsToInsert.add(requestUtilityAccountLog.asUAL(newPropertyAccount));
            }

            List<Utility_Account_Log__c> newUALs = ualService.insertUALs(ualsToInsert);
            responsePropertyAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>();
            for (Utility_Account_Log__c newUAL : newUALs) {
                responsePropertyAccount.utilityAccountLogs.add(new RestLead.RestUtilityAccountLog(newUAL));
            }
        }

        envelope.setData(responsePropertyAccount);
        response.statusCode = statusCode.created;
        envelope.setJSONResponse(response);

    }

    public virtual void postUtilityAccountLog(String jsonRequest) {
        RestLead.RestUtilityAccountLog restUtilityAccountLog = (RestLead.RestUtilityAccountLog) JSON.deserialize(jsonRequest, RestLead.RestUtilityAccountLog.class);
        RestResponse response = RestContext.response;

        Boolean validRequest = false;
        try {
            restUtilityAccountLog.validateCreateFields();
            validRequest = true;
        } catch (Util.BWException e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.badRequest;
            envelope.setJSONResponse(response);
            return;
        }

        Account associatedAccount = accountsSelector.selectOne(restUtilityAccountLog.propertyAccountId);
        if (associatedAccount == null) {
            response.statusCode = statusCode.notFound;
            envelope.addError('PropertyAccount not found');
            envelope.setJSONResponse(response);
            return;
        }

        Utility_Account_Log__c newUtilityAccountLog = restUtilityAccountLog.asUAL(associatedAccount);

        newUtilityAccountLog = ualService.insertUAL(newUtilityAccountLog);

        RestLead.RestUtilityAccountLog responseUtilityAccountLog = new RestLead.RestUtilityAccountLog(newUtilityAccountLog);

        envelope.setData(responseUtilityAccountLog);
        response.statusCode = statusCode.created;
        envelope.setJSONResponse(response);

    }

    public virtual void performZipCheck(String zipCode, String partnerId) {
        RestResponse response = RestContext.response;
        RestZipCode zipCodeResponse = new RestZipCode(capacityService.findCapacityByZipcode(zipCode, partnerId));
        envelope.setData(zipCodeResponse);
        envelope.setJSONResponse(response);
    }


    /********************   HELPER METHODS  ********************/
    private void insertLeadAccountAndUALs(RestLead requestLead, RestResponse response) {
        Lead newLead = requestLead.asLead();
        newLead = leadService.insertLead(newLead);
        newLead = duplicateService.checkLeadDuplicates(newLead);
        if(String.isBlank(newLead.Continue_Application_Link__c)) {
            newLead.Continue_Application_Link__c = baseUrl + '?leadid=' + newLead.Id + '&email=' + newLead.Email;
        }
        newLead = leadService.updateLead(newLead);
        RestLead responseLead = new RestLead(newLead);

        if (requestLead.propertyAccounts != null && !requestLead.propertyAccounts.isEmpty()) {
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

            if (requestLead.propertyAccounts.get(0).utilityAccountLogs != null && !requestLead.propertyAccounts.get(0).utilityAccountLogs.isEmpty()) {
                List<Utility_Account_Log__c> ualsToInsert = new List<Utility_Account_Log__c>();
                for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : requestLead.propertyAccounts.get(0).utilityAccountLogs) {
                    ualsToInsert.add(requestUtilityAccountLog.asUAL(newAccount));
                }

                List<Utility_Account_Log__c> newUALs = ualService.insertUALs(ualsToInsert);
                responsePropertyAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>();
                for (Utility_Account_Log__c newUAL : newUALs) {
                    responsePropertyAccount.utilityAccountLogs.add(new RestLead.RestUtilityAccountLog(newUAL));
                }
            }
        }
        envelope.setData(responseLead);
        response.statusCode = statusCode.created;
    }

    private Boolean applicationValid(String jsonRequest, RestResponse response) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        Lead lead = leadSelector.selectOneWithPropertiesAndUtilities(requestLead.id);
        if(lead == null) {
            response.statusCode = statusCode.notFound;
            return false;
        }
        
        if(requestMap.size() <= 1 || !requestMap.containsKey('propertyAccounts') || requestLead.propertyAccounts.isEmpty()) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        
        RestLead.RestPropertyAccount requestAccount = requestLead.propertyAccounts.get(0);
        Map<String, Object> accountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(requestAccount));
        if(accountMap.size() <= 1 || !accountMap.containsKey('utilityAccountLogs') || requestAccount.utilityAccountLogs == null || requestAccount.utilityAccountLogs.isEmpty()) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }

        if(requestLead.propertyAccounts.size() > 1 || lead.Accounts__r.size() > 1 ||
            (!lead.Accounts__r.isEmpty() && lead.Accounts__r[0].Id != requestAccount.id)
        ) {
            envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
            response.statusCode = statusCode.badRequest;
            return false;
        }

        return true;
    }

    private void updateLead(String jsonRequest) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonRequest);
        Lead leadToUpdate = leadSelector.selectOne(requestLead.id);
        requestLead.mergeFields(requestMap.keySet(), leadToUpdate);
        Lead lead = leadService.updateLead(leadToUpdate);
    }

    private void updateAccount(String jsonRequest) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        RestLead.RestPropertyAccount requestPropertyAccount = requestLead.propertyAccounts.get(0);

        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonRequest);
        List<Object> accountList = (List<Object>)requestMap.get('propertyAccounts');
        Map<String, Object> accountMap = (Map<String, Object>)accountList.get(0);

        Account requestAccount = accountsSelector.selectOne(requestPropertyAccount.id);

        if(requestAccount != null) {
            requestAccount = requestPropertyAccount.mergeFields(accountMap.keySet(), requestAccount);
            Account a = accountService.updateAccount(requestAccount);
        } else {
            requestPropertyAccount.validateCreateFields();
            Lead parentLead = leadSelector.selectOne(requestLead.id);
            requestAccount = requestPropertyAccount.asAccount(parentLead);
            Account a = accountService.insertAccount(requestAccount);
        }
    }

    private void updateUtilityAccountLogs(String jsonRequest) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        RestLead.RestPropertyAccount requestPropertyAccount = requestLead.propertyAccounts.get(0);
        List<RestLead.RestUtilityAccountLog> requestUALs = requestPropertyAccount.utilityAccountLogs;

        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonRequest);
        List<Object> accountList = (List<Object>)requestMap.get('propertyAccounts');
        Map<String, Object> accountMap = (Map<String, Object>)accountList.get(0);
        List<Object> ualList = (List<Object>)accountMap.get('utilityAccountLogs');

        Account parentPropertyAccount = accountsSelector.selectOne(requestPropertyAccount.id);
        Set<Id> ualIdSet = new Set<Id>();
        for(RestLead.RestUtilityAccountLog ual : requestUALs) {
            ualIdSet.add(ual.id);
        }
        Map<Id, Utility_Account_Log__c> requestUalMap = ualSelector.selectAllMap(ualIdSet);
        List<Utility_Account_Log__c> ualForUpsert = new List<Utility_Account_Log__c>();
        
        for(Integer i=0; i<requestUALs.size(); i++) {
            RestLead.RestUtilityAccountLog ual = requestUALs.get(i);
            Map<String, Object> ualMap = (Map<String, Object>)ualList.get(i);
            if(ualMap.size() <= 1) { // if == 1, then only has "id", which is not enough fields for a PATCH
                continue;
            } else if(requestUalMap.containsKey(ual.id)) {
                Utility_Account_Log__c ualToUpdate = requestUalMap.get(ual.id);
                ual.mergeFields(ualMap.keySet(), ualToUpdate);
                ualForUpsert.add(ualToUpdate);
            } else {
                ual.validateCreateFields();
                Utility_Account_Log__c ualToInsert = ual.asUAL(parentPropertyAccount);
                ualForUpsert.add(ualToInsert);
            }
        }
        ualService.upsertUALs(ualForUpsert);
    }

    

}