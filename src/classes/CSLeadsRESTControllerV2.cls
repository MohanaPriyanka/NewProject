/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Test: CSLeadsRESTControllerV2Test
 */
@SuppressWarnings('PMD.TooManyFields')
public virtual without sharing class CSLeadsRESTControllerV2 extends RESTController {
    @TestVisible private LeadService leadService = new LeadService();
    @TestVisible private AccountService accountService = new AccountService();
    @TestVisible private UALService ualService = new UALService();
    @TestVisible private CSLeadsDuplicateService duplicateService = new CSLeadsDuplicateService();
    @TestVisible private CapacityService capacityService = new CapacityService();
    @TestVisible private CustomerContractService customerContractService = new CustomerContractService();
    @TestVisible private ContentService contentService = new ContentService();
    @TestVisible private CSQualificationService qualificationService = new CSQualificationService();
    @TestVisible protected LeadSelector leadSelector = new LeadSelector();
    @TestVisible private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private UALSelector ualSelector = new UALSelector();
    @TestVisible private ContentDocumentSelector contentSelector = new ContentDocumentSelector();
    @TestVisible private CustomerContractSelector customerContractSelector = new CustomerContractSelector();
    @TestVisible private String baseUrl = Util.getCommunitySiteURL('Apply') + '/s/switch';
    @TestVisible private Map<String, String> contractLeadFields = new Map<String, String>{
        'FirstName' => 'firstName',
        'LastName' => 'lastName',
        'Email' => 'email',
        'MobilePhone' => 'mobilePhone',
        'Business_Phone__c' => 'businessPhone',
        'Company' => 'businessName',
        'LASERCA__Home_Address__c' => 'streetAddress',
        'LASERCA__Home_City__c' => 'city',
        'LASERCA__Home_State__c' => 'state',
        'LASERCA__Home_Zip__c' => 'zipCode',
        'Business_Title__c' => 'businessTitle'
    };
    @TestVisible private Map<String, String> contractUALFields = new Map<String, String>{
        'Service_Address__c' => 'serviceStreet',
        'Service_City__c' => 'serviceCity',
        'Service_State__c' => 'serviceState',
        'Service_Zip_Code__c' => 'servicePostalCode'
    };
    @TestVisible private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            ContentVersion.SObjectType,
            Lead.SObjectType,
            Financial_Underwriting_Document__c.SObjectType,
            Account.SObjectType,
            Contract.SObjectType,
            Utility_Account_Log__c.SObjectType,
            ContentDocumentLink.SObjectType
        }
    );
    private FilesUnitOfWorkHelper customWork = new FilesUnitOfWorkHelper();
    public static final Map<String, String> APP_STATUS_TO_LOCATION = new Map<String, String>{
        'Started' => 'info',
        'Customer Info Completed' => 'agree',
        'Contracts Signed' => 'pay',
        'Application Completed' => 'complete'
    };
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
                RestLead responseLead = formatRestLeadFromLeadAndChildren(leadToReturn, false, null);
                envelope.setData(responseLead);
                response.statusCode = statusCode.ok;
            }
        }
        envelope.setJSONResponse(response);
    }
    /**
     * Called by (Aura) SSFApplication/SSFApplicationDTC on SSF application completion
     * <br><br>
     * Sets return envelope data to pass back to UI
     * @param jsonRequest Incoming PATCH request body
     */
    public virtual void patchLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;
        Lead leadToUpdate = leadSelector.selectOne(requestLead.id);
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        Boolean applicationNowComplete = false;
        if (leadToUpdate == null) {
            response.statusCode = statusCode.notFound;
            envelope.setJSONResponse(response);
            return;
        }
        if (requestMap.size() <= 1) { // if == 1, then only has "id", which is not enough fields for a PATCH
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
            envelope.setJSONResponse(response);
            return;
        }
        // Handle Application Complete state
        if (requestLead.applicationCompleteDate != null && leadToUpdate.Application_Complete_Date__c == null) {
            applicationNowComplete = true;
            if (requestLead.underwritingCriteria == 'FICO') {
                // pull credit, only once; on first time the app complete date is set
                leadToUpdate.Soft_Pull_Credit_Report__c = true;
            } else if (requestLead.underwritingCriteria == 'Financial Review') {
                leadToUpdate.Status = qualificationService.underwriteWithFinancialReview(leadToUpdate);
            }

            // Send Zuora callout
            List<Account> propertyAccounts = accountsSelector.selectPropertyAccountsByLeadIds(new Set<Id>{requestLead.Id});
            ZuoraAccountService.createAccounts(propertyAccounts);
        }
        // Update Lead with fields from PATCH
        requestLead.mergeFields(requestMap.keySet(), leadToUpdate);
        Lead lead = leadService.updateLead(leadToUpdate);
        // Check & Update "Application Status" if necessary
        updateLeadApplicationStatus(lead.Id);
        // Handle other non-Lead database changes if the application is newly marked as "Application Complete"
        // Placed last because we want to ensure Lead properly updates before queueing other object changes
        if (applicationNowComplete) {
            //UtilityDataRequestService.create(new List<Id>{requestLead.id});
            createAndSendCSPartnerEmail(lead.Id);
        }
        // Set return envelope
        RestLead responseLead = new RestLead(lead);
        envelope.setData(responseLead);
        response.statusCode = statusCode.ok;
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
            updateLeadApplicationStatus(account.Lead__c);
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
            updateLeadApplicationStatus(ual.Lead__c);
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
        RestResponse response = RestContext.response;
        Map<String, Object> requestLeadMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        Id leadId = (Id)requestLeadMap.get('id');
        Lead existingLead = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
        if (applicationValid(jsonRequest, response, existingLead)) {
            Savepoint sp = Database.setSavepoint();
            try {
                Set<Id> contractIdSet = new Set<Id>();
                for (Contract contract : existingLead.Contracts__r) {
                    contractIdSet.add(contract.Id);
                }
                List<ContentDocumentLink> existingDocs = new List<ContentDocumentLink>();
                if (!contractIdSet.isEmpty()) {
                    existingDocs = contentSelector.selectByLinkedEntities(contractIdSet);
                }
                Boolean regenerateDocs = existingDocs.isEmpty() || existingDocs[0].ContentDocument.CreatedDate.date() < Date.today().addDays(ContentDocLinkPrivacyScheduler.minDaysInPast) || contractFieldsUpdated(jsonRequest, existingLead);
                updateLeadAccountAndUALs(jsonRequest, existingLead);
                uow.commitWork();
                if (regenerateDocs) {
                    customerContractService.regenerateDocuments(leadId);
                }
                updateLeadApplicationStatus(leadId);
                Integer numberOfDocs;
                if (requestLeadMap.containsKey('numberOfContractDocs')) {
                    numberOfDocs = (Integer)requestLeadMap.get('numberOfContractDocs');
                }
                RestLead responseLead = formatRestLeadFromLeadAndChildren(leadId, regenerateDocs, numberOfDocs);
                responseLead.numberOfContractDocs = numberOfDocs;
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
    public virtual void patchContract(String jsonRequest) {
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        RestResponse response = RestContext.response;
        if(requestMap.containsKey('leadId') && requestMap.get('leadId') != null) {
            try {
                customerContractService.signCustomerContracts((Id)requestMap.get('leadId'));
                updateLeadApplicationStatus((Id)requestMap.get('leadId'));
                envelope.setData('OK');
                response.statusCode = statusCode.ok;
            } catch(System.StringException se) {
                envelope.addError('Bad lead ID; please provide a valid lead ID');
                response.statusCode = statusCode.badRequest;
            } catch(System.TypeException te) {
                envelope.addError('Bad lead ID; please provide a valid lead ID');
                response.statusCode = statusCode.badRequest;
            } catch (Exception e) {
                envelope.addError(e.getMessage());
                response.statusCode = statusCode.internalServerError;
            }
        } else {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
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
            uow.registerWork(customWork);
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
        List<Contract> associatedContracts = customerContractSelector.selectByRelatedLead(associatedLead.Id);
        if(associatedContracts.isEmpty()) {
            customerContractService.createContractFromLead(associatedLead.Id, null);
        }
        if (requestPropertyAccount.utilityAccountLogs != null && !requestPropertyAccount.utilityAccountLogs.isEmpty()) {
            responsePropertyAccount.utilityAccountLogs = insertUALs(newPropertyAccount, requestPropertyAccount.utilityAccountLogs);
        }
        updateLeadApplicationStatus(associatedLead.Id);
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
        updateLeadApplicationStatus(newUtilityAccountLog.Lead__c);
        envelope.setData(responseUtilityAccountLog);
        response.statusCode = statusCode.created;
        envelope.setJSONResponse(response);
    }
    public virtual void performZipCheck(String zipCode, String partnerId, String utilityId) {
        RestResponse response = RestContext.response;
        RestZipCode zipCodeResponse = new RestZipCode(capacityService.findCapacityByZipcode(zipCode, partnerId, utilityId));
        envelope.setData(zipCodeResponse);
        envelope.setJSONResponse(response);
    }
    private void insertLeadAccountAndUALs(RestLead requestLead, RestResponse response) {
        Lead newLead = requestLead.asLead();
        newLead = leadService.insertLead(newLead);
        newLead = duplicateService.checkLeadDuplicates(newLead);
        // Set continue application links
        String applicationStatus = getApplicationStatus(newLead);
        setContinueApplicationLinks(newLead, applicationStatus);
        newLead = leadService.updateLead(newLead);
        if (requestLead.financialDocs != null) {
            for (RestLead.RestContentDocument contentDoc : requestLead.financialDocs) {
                Financial_Underwriting_Document__c finDoc = new Financial_Underwriting_Document__c(Lead__c = newLead.Id);
                uow.registerNew(finDoc);
                registerNewContentDocs(new List<RestLead.RestContentDocument>{contentDoc}, finDoc);
            }
        }
        if (requestLead.propertyAccounts != null) {            
            for (RestLead.RestPropertyAccount requestPropertyAccount : requestLead.propertyAccounts) {
                Account newAccount = requestPropertyAccount.asAccount(newLead);
                uow.registerNew(newAccount);
                if (newLead.Product__c != null) {
                    Contract c = customerContractService.setContractFields(newLead, requestLead.numberOfContractDocs);
                    uow.registerNew(c, Contract.AccountId, newAccount);
                }
                if (requestPropertyAccount.utilityAccountLogs != null) {
                    registerNewUALs(requestPropertyAccount.utilityAccountLogs, newAccount);
                }
            }
        }
        uow.commitWork();
        updateLeadApplicationStatus(newLead.Id);
        RestLead responseLead = formatRestLeadFromLeadAndChildren(newLead.Id, true, requestLead.numberOfContractDocs);
        if (requestLead.numberOfContractDocs != null) {
            responseLead.numberOfContractDocs = requestLead.numberOfContractDocs;
        }
        envelope.setData(responseLead);
        response.statusCode = statusCode.created;
    }
    private void updateLeadAccountAndUALs(String jsonRequest, Lead existingLead) {
        Map<String, Object> requestLeadMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        requestLead.mergeFields(requestLeadMap.keySet(), existingLead);
        uow.registerDirty(existingLead);
        if (requestLead.propertyAccounts != null && !requestLead.propertyAccounts.isEmpty()) {
            List<RestLead.RestPropertyAccount> requestPropertyAccounts = requestLead.propertyAccounts;
            List<Object> requestAccountList = (List<Object>)requestLeadMap.get('propertyAccounts');
            updateAccount(existingLead, requestPropertyAccounts, requestAccountList);
        }
    }
    /**
     * @param reqUALs Utility Account Log's (UAL) to insert
     * @param propertyAccount Parent Property Account to which the UALs belong
     */
    private void registerNewUALs(List<RestLead.RestUtilityAccountLog> reqUALs, Account propertyAccount) {
        for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : reqUALs) {
            Utility_Account_Log__c newUal = requestUtilityAccountLog.asUAL(propertyAccount);
            uow.registerNew(newUal, Utility_Account_Log__c.Account__c, propertyAccount);
            if (requestUtilityAccountLog.utilityBills != null) {
                registerNewContentDocs(requestUtilityAccountLog.utilityBills, newUal);
            }
        }
    }
    private List<RestLead.RestUtilityAccountLog> insertUALs(Account newPropertyAccount, List<RestLead.RestUtilityAccountLog> restUtilityAccountLogs) {
        List<Utility_Account_Log__c> ualsToInsert = new List<Utility_Account_Log__c>();
        for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : restUtilityAccountLogs) {
            ualsToInsert.add(requestUtilityAccountLog.asUAL(newPropertyAccount));
        }
        List<Utility_Account_Log__c> newUALs = ualService.insertUALs(ualsToInsert);
        List<RestLead.RestUtilityAccountLog> ualsToReturn = new List<RestLead.RestUtilityAccountLog>();
        for (Utility_Account_Log__c newUAL : newUALs) {
            ualsToReturn.add(new RestLead.RestUtilityAccountLog(newUAL));
        }
        return ualsToReturn;
    }
    private Boolean applicationValid(String jsonRequest, RestResponse response, Lead existingLead) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        if(existingLead == null) {
            response.statusCode = statusCode.notFound;
            return false;
        }
        if(requestMap.size() <= 1 || !requestMap.containsKey('propertyAccounts') || requestLead.propertyAccounts.isEmpty()) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        RestLead.RestPropertyAccount requestAccount = requestLead.propertyAccounts.get(0);
        if(requestLead.propertyAccounts.size() > 1 || existingLead.Accounts__r.size() > 1 ||
            (!existingLead.Accounts__r.isEmpty() && existingLead.Accounts__r[0].Id != requestAccount.id)
        ) {
            envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        Map<String, Object> accountMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(requestAccount));
        if(accountMap.size() <= 1 || !accountMap.containsKey('utilityAccountLogs') || requestAccount.utilityAccountLogs == null || requestAccount.utilityAccountLogs.isEmpty()) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        return true;
    }
    private void updateAccount(Lead lead, List<RestLead.RestPropertyAccount> requestPropertyAccounts, List<Object> requestAccountList) {
        Map<Id, Utility_Account_Log__c> existingUtilityAccountLogMap = ualSelector.selectAllByLeadMap(new Set<Id>{lead.Id});
        Map<Id, Account> existingAccountMap = accountsSelector.selectPropertyAccountsByLeadIdsMap(new Set<Id>{lead.Id});
        for(Integer acctIndex = 0; acctIndex < requestPropertyAccounts.size(); acctIndex++) {
            Map<String, Object> accountMap = (Map<String, Object>) requestAccountList[acctIndex];
            RestLead.RestPropertyAccount requestPropertyAccount = requestPropertyAccounts[acctIndex];
            Account propAcct;
            if(existingAccountMap.containsKey(requestPropertyAccount.id)) {
                propAcct = requestPropertyAccount.mergeFields(accountMap.keySet(), existingAccountMap.get(requestPropertyAccount.id));
                uow.registerDirty(propAcct);
            } else {
                requestPropertyAccount.validateCreateFields();
                propAcct = requestPropertyAccount.asAccount(lead);
                uow.registerNew(propAcct);
            }
            if(requestPropertyAccount.utilityAccountLogs != null && !requestPropertyAccount.utilityAccountLogs.isEmpty()) {
                List<Object> requestUALList = (List<Object>)accountMap.get('utilityAccountLogs');
                List<RestLead.RestUtilityAccountLog> requestUtilityAccountLogs = requestPropertyAccount.utilityAccountLogs;
                updateUtilityAccountLogs(propAcct, requestUtilityAccountLogs, requestUALList, existingUtilityAccountLogMap);
            }
        }
    }
    private void updateUtilityAccountLogs(Account propertyAccount, List<RestLead.RestUtilityAccountLog> requestUtilityAccountLogs, List<Object> requestUALList, Map<Id, Utility_Account_Log__c> existingUtilityAccountLogMap) {
        for(Integer ualIndex = 0; ualIndex < requestUtilityAccountLogs.size(); ualIndex++) {
            Map<String, Object> ualMap = (Map<String, Object>) requestUALList[ualIndex];
            RestLead.RestUtilityAccountLog requestUtilityAccountLog = requestUtilityAccountLogs[ualIndex];
            Utility_Account_Log__c ual;
            if(ualMap.size() <= 1) { // if == 1, then only has "id", which is not enough fields for a PATCH
                continue;
            } else if(existingUtilityAccountLogMap.containsKey(requestUtilityAccountLog.id)) {
                ual = requestUtilityAccountLog.mergeFields(ualMap.keySet(), existingUtilityAccountLogMap.get(requestUtilityAccountLog.id));
                uow.registerDirty(ual);
            } else {
                requestUtilityAccountLog.validateCreateFields();
                ual = requestUtilityAccountLog.asUAL(propertyAccount);
                uow.registerNew(ual, Utility_Account_Log__c.Account__c, propertyAccount);
            }
            if(requestUtilityAccountLog.utilityBills != null && !requestUtilityAccountLog.utilityBills.isEmpty()) {
                List<RestLead.RestContentDocument> requestContentDocuments = requestUtilityAccountLog.utilityBills;
                registerNewContentDocs(requestContentDocuments, ual);
            }
        }
    }
    @TestVisible
    private Boolean contractFieldsUpdated(String jsonRequest, Lead existingLead) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonRequest);
        for(String leadFieldName : contractLeadFields.keySet()) {
            String restLeadFieldName = contractLeadFields.get(leadFieldName);
            if(String.valueOf(requestMap.get(restLeadFieldName)) != String.valueOf(existingLead.get(leadFieldName))) {
                return true;
            }
        }
        if(existingLead.Partner_Lookup__c != requestLead.partnerId) {
            if(requestLead.partnerId != null) {
                return true;
            } else if(existingLead.Partner_Lookup__c != PartnerSelector.selectDefaultCSPartner().Id){
                return true;
            }
        }
        if(existingLead.bs_Sales_ID__c != requestLead.salesRepId) {
            Partner__c partner = PartnerSelector.selectPartnerByPartnerId(existingLead.Partner_Lookup__c);
            if(requestLead.salesRepId != null) {
                return true;
            } else if(existingLead.bs_Sales_ID__c != partner.Default_Sales_Rep__c){
                return true;
            }
        }
        return checkUALsForChanges(requestMap, existingLead);
    }
    private Boolean checkUALsForChanges(Map<String, Object> requestMap, Lead existingLead) {
        List<Object> accountList = (List<Object>)requestMap.get('propertyAccounts');
        Map<String, Object> accountMap = (Map<String, Object>)accountList.get(0);
        List<Object> ualList = (List<Object>)accountMap.get('utilityAccountLogs');
        if(existingLead.Utility_Account_Logs__r.size() != ualList.size()) {
            return true;
        }
        Map<String, Map<String, Object>> restUALMap = new Map<String, Map<String, Object>>();
        for(Object ualObj : ualList) {
            Map<String, Object> restUAL = (Map<String, Object>)ualObj;
            restUALMap.put((String)restUAL.get('utilityAccountNumber'), restUAL);
        }
        for(Utility_Account_Log__c leadUAL : existingLead.Utility_Account_Logs__r) {
            if(!restUALMap.containsKey(leadUAL.Name)) {
                return true;
            } else {
                Map<String, Object> restUAL = restUALMap.get(leadUAL.Name);
                for(String ualFieldName : contractUALFields.keySet()){
                    String restUALFieldName = contractUALFields.get(ualFieldName);
                    if(String.valueOf(leadUAL.get(ualFieldName)) != String.valueOf(restUAL.get(restUALFieldName))) {
                        return true;
                    }
                }
                if(leadUAL.Utility_Rate_Class__r.Name != restUAL.get('rateClass')) {
                    return true;
            }
        }
        }
        return false;
    }
    @TestVisible
    private RestLead formatRestLeadFromLeadAndChildren(Id leadId, Boolean docsNewlyGenerated, Integer numberOfContractDocs) {
        Lead leadToReturn = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
        return formatRestLeadFromLeadAndChildren(leadToReturn, docsNewlyGenerated, numberOfContractDocs);
    }
    private RestLead formatRestLeadFromLeadAndChildren(
        Lead leadToReturn, Boolean docsNewlyGenerated, Integer numberOfContractDocs)
    {
        RestLead responseLead = new RestLead(leadToReturn);
        // map UALs to their parent property accounts
        MultiMap ualsByPropertyAccountId = CollectionUtil.multiMapByField(leadToReturn.Utility_Account_Logs__r, Utility_Account_Log__c.Account__c);
        Set<Id> linkedEntityIdSet = new Set<Id>{leadToReturn.Id};
        for(Contract contract : leadToReturn.Contracts__r) {
            linkedEntityIdSet.add(contract.Id);
        }
        for(Financial_Underwriting_Document__c finUnderwriteDoc : leadToReturn.Underwrite_Financial_Documents__r) {
            linkedEntityIdSet.add(finUnderwriteDoc.Id);
        }
        for(Object accountId : ualsByPropertyAccountId.keySet()) {
            for(Object ualObj : ualsByPropertyAccountId.getValues((Id) accountId)) {
                Utility_Account_Log__c ual = (Utility_Account_Log__c) ualObj;
                linkedEntityIdSet.add(ual.Id);
            }
        }
        // get all related content docs and sort by linked entity
        List<ContentDocumentLink> cdls = contentSelector.selectByLinkedEntities(linkedEntityIdSet);
        MultiMap contentDocLinksByLinkedEntityId = CollectionUtil.multiMapByField(cdls, ContentDocumentLink.LinkedEntityId);
        List<Object> contractCDLs = new List<Object>();
        for(Contract contract : leadToReturn.Contracts__r) {
            contractCDLs.addAll(contentDocLinksByLinkedEntityId.getValues(contract.Id));
        }
        if(numberOfContractDocs == null || numberOfContractDocs == 0) {
            numberOfContractDocs = 2;
        }
        if(contractCDLs.isEmpty()) {
            responseLead.mostRecentContractGen = Datetime.now();
        } else if(docsNewlyGenerated) {
            ContentDocumentLink cdl = (ContentDocumentLink) contractCDLs[0];
            responseLead.mostRecentContractGen = cdl.ContentDocument.CreatedDate;
        } else {
            responseLead.contentDocs = compileLeadContentDocs(leadToReturn.Id, contractCDLs, numberOfContractDocs);
        }
        // compile the financial underwriting documents and their uploads
        List<RestLead.RestContentDocument> returnFinDocs = new List<RestLead.RestContentDocument>();
        for(Financial_Underwriting_Document__c finUnderwriteDoc : leadToReturn.Underwrite_Financial_Documents__r) {
            for(Object cdl : contentDocLinksByLinkedEntityId.getValues(finUnderwriteDoc.Id)) {
                RestLead.RestContentDocument returnContentDoc = new RestLead.RestContentDocument((ContentDocumentLink) cdl);
                returnContentDoc.parentId = finUnderwriteDoc.Id;
                returnFinDocs.add(returnContentDoc);
            }
        }
        responseLead.financialDocs = returnFinDocs;
        // compile the property accounts, uals, and utility bill uploads
        List<RestLead.RestPropertyAccount> returnPropertyAccounts = new List<RestLead.RestPropertyAccount>();
        for(Account propertyAccount : leadToReturn.Accounts__r) {
            List<RestLead.RestUtilityAccountLog> returnUalList = new List<RestLead.RestUtilityAccountLog>();
            for(Object ual : ualsByPropertyAccountId.getValues(propertyAccount.Id)) {
                RestLead.RestUtilityAccountLog returnUal = new RestLead.RestUtilityAccountLog((Utility_Account_Log__c) ual);
                List<RestLead.RestContentDocument> utilityBillList = new List<RestLead.RestContentDocument>();
                for(Object cdl : contentDocLinksByLinkedEntityId.getValues(returnUal.id)) {
                    RestLead.RestContentDocument returnContentDoc = new RestLead.RestContentDocument((ContentDocumentLink) cdl);
                    utilityBillList.add(returnContentDoc);
                }
                returnUal.utilityBills = utilityBillList;
                returnUalList.add(returnUal);
            }
            RestLead.RestPropertyAccount returnPropertyAccount = new RestLead.RestPropertyAccount(propertyAccount);
            returnPropertyAccount.utilityAccountLogs = returnUalList;
            returnPropertyAccounts.add(returnPropertyAccount);
        }
        responseLead.propertyAccounts = returnPropertyAccounts;
        return responseLead;
    }
    private void registerNewContentDocs(List<RestLead.RestContentDocument> requestContentDocuments, SObject linkedEntity) {
        for(RestLead.RestContentDocument requestContentDocument : requestContentDocuments) {
            if(requestContentDocument.id == null) {
                requestContentDocument.body = String.escapeSingleQuotes(requestContentDocument.body);
                requestContentDocument.validateCreateFields();
                ContentVersion newContentVersion = requestContentDocument.asContentVersionForInsert();
                uow.registerNew(newContentVersion);
                customWork.registerContentDocumentLinkInsert(linkedEntity, newContentVersion, 'V', 'AllUsers');
            } else if(requestContentDocument.docLinkId == null){
                ContentDocumentLink newContentLink = requestContentDocument.asContentDocLinkForInsert();
                uow.registerNew(newContentLink, ContentDocumentLink.LinkedEntityId, linkedEntity);
            } else if(requestContentDocument.lastPublishedVersionId == null) {
                requestContentDocument.body = String.escapeSingleQuotes(requestContentDocument.body);
                requestContentDocument.validateCreateFields();
                ContentVersion newContentVersion = requestContentDocument.asContentVersionForInsert();
                newContentVersion.ContentDocumentId = requestContentDocument.id;
                uow.registerNew(newContentVersion);
            }
        }
    }
    private List<RestLead.RestContentDocument> compileLeadContentDocs(Id leadId, List<Object> contractCDLs, Integer numberOfContractDocs) {
        List<RestLead.RestContentDocument> restContentDocs = new List<RestLead.RestContentDocument>();
        Integer docCount = Math.min(numberOfContractDocs, contractCDLs.size());
        for(Integer i=0; i<docCount; i++) {
            RestLead.RestContentDocument rcd = new RestLead.RestContentDocument((ContentDocumentLink) contractCDLs[i]);
            rcd.publicUrl = contentSelector.getPublicDistributionLinkByDocId(rcd.docLinkId);
            restContentDocs.add(rcd);
        }
        return restContentDocs;
    }
    /**
     * Updates Lead Application Status based on Lead criteria and specific logic.
     * <br>
     * Operates similar to a Trigger on Lead.
     *
     * @param leadId Lead to update
     */
    @SuppressWarnings('PMD.ApexOpenRedirect')
    public void updateLeadApplicationStatus(Id leadId) {
        Lead lead = leadSelector.selectOneForStatusUpdate(leadId);
        String status = getApplicationStatus(lead);
        if (lead.Application_Status__c != status) {
            lead.Application_Status__c = status;
            setContinueApplicationLinks(lead, status);
            Util.updateAndLog(new List<SObject>{lead}, 'CSLeadsRESTControllerV2', 'updateLeadApplicationStatus');
        }
    }

    /**
     * Sets links on Lead to access application in SSF at a later state
     * @param lead Lead to set links for
     * @param applicationStatus Current application status of Lead
     */
    public void setContinueApplicationLinks(Lead lead, String applicationStatus) {
        String location = APP_STATUS_TO_LOCATION.get(applicationStatus);

        // Set Continue Application Link
        if (lead.Continue_Application_Link__c != null) {
            PageReference url = new PageReference(lead.Continue_Application_Link__c);
            // Set new location parameter based on where in the application the customer is
            url.getParameters().put('loc', location);
            // Ensure partnerId is filled in
            if (url.getParameters().get('partnerId') == null) {
                url.getParameters().put('partnerId', lead.Partner_Lookup__c);
            }
            lead.Continue_Application_Link__c = url.getUrl();
        } else {
            lead.Continue_Application_Link__c =
                baseUrl +
                '?leadid=' + lead.Id +
                '&email=' + lead.Email +
                '&partnerId=' + lead.Partner_Lookup__c +
                '&loc=' + location;
        }
        // Set Contract Re-Sign (Agree page) link, if empty and ever needed later (W-020708)
        if (lead.Contract_eSign_Link__c	== null) {
            lead.Contract_eSign_Link__c =
                baseUrl +
                '?leadid=' + lead.Id +
                '&email=' + lead.Email +
                '&partnerId=' + lead.Partner_Lookup__c +
                '&loc=' + location;
        }
    }
    public String getApplicationStatus(Lead lead) {
        if (lead.Application_Complete_Date__c != null) {
            return 'Application Completed';
        }
        Boolean contractsSigned = true;
        for (Contract contract : lead.Contracts__r) {
            if (contract.Customer_Signature_Date_Time__c == null) {
                contractsSigned = false;
                break;
            }
        }
        if (!lead.Contracts__r.isEmpty() && contractsSigned) {
            return 'Contracts Signed';
        }
        if (!lead.Accounts__r.isEmpty() && !lead.Utility_Account_Logs__r.isEmpty()) {
            return getUALStatus(lead.Utility_Account_Logs__r);
        }
        return 'Started';
    }
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private String getUALStatus(List<Utility_Account_Log__c> ualList) {
        List<Id> ualIds = new List<Id>();
        for(Utility_Account_Log__c ual : ualList) {
            if(ual.Utility_lookup__r.Utility_Data_Collection_Mechanism__c == 'File Upload') {
                ualIds.add(ual.Id);
            }
        }
        if(ualIds.isEmpty()) {
            return 'Customer Info Completed';
        }
        List<Utility_Account_Log__c> uploadUALs = [
            SELECT Id,
                (SELECT Id FROM ContentDocumentLinks 
                WHERE ContentDocument.LatestPublishedVersion.File_Category__c = 'Customer Utility Bill')
            FROM Utility_Account_Log__c
            WHERE Id IN :ualIds
        ];
        Boolean utilityBillsPresent = !uploadUALs.isEmpty();
        for(Utility_Account_Log__c ual : uploadUALs) {
            if(ual.ContentDocumentLinks.isEmpty()) {
                utilityBillsPresent = false;
                break;
            }
        }
        if(utilityBillsPresent) {
            return 'Customer Info Completed';
        }
        return 'Started';
    }

    @Future
    public static void createAndSendCSPartnerEmail(Id leadId) {
        Lead lead = new LeadSelector().selectOne(leadId);
        System_Default__mdt systemDefault = new FeatureSelector().getSystemDefaults();
        if (systemDefault.Application_Complete_Email_Template__c == null) {
            return;
        }

        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = systemDefault.Application_Complete_Email_Template__c;
        ee.orgWideEmail =  MessagingService.getCustomerCareEmail().Address;
        ee.addressList = new List<String>{lead.Partner_Email__c};
        ee.subjectLine = 'Application Completed for ' + lead.Name;
        MessagingService.ReplacementText partnerName = new MessagingService.ReplacementText('{!Lead.Partner_Account__r}', lead.Partner_Account__r.Name);
        MessagingService.ReplacementText leadName = new MessagingService.ReplacementText('{!Lead.Name}', lead.Name);
        ee.replacementTexts = new List<MessagingService.ReplacementText>{partnerName, leadName};
        ee.sobjectId = lead.Id;

        try {
            MessagingService.sendEmailTemplate(ee);
        } catch (Exception e) {
            Logger.logNow('CSLeadsRestControllerV2', 'createAndSendCSPartnerEmail', e.getMessage() +
                '; ' + e.getStackTraceString());
        }
    }
}