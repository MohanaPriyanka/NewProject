/**
 * Created by jlugo on 7/3/2019.
 * Description: REST Controller for sending CS Leads to Salesforce
 * Tested By: CSLeadsRESTControllerV2Test
 */
@SuppressWarnings('PMD.TooManyFields')
public virtual without sharing class CSLeadsRESTControllerV2 extends RESTController {
    
    public static final Map<String, String> APP_STATUS_TO_LOCATION = new Map<String, String>{
        'Started' => 'info',
        'Customer Info Completed' => 'agree',
        'Contracts Signed' => 'pay',
        'Application Completed' => 'complete'
    };
    public LeadService leadService = new LeadService();
    @TestVisible private AccountService accountService = new AccountService();
    @TestVisible private UALService ualService = new UALService();
    public CSLeadsDuplicateService duplicateService = new CSLeadsDuplicateService();
    @TestVisible private CapacityService capacityService = new CapacityService();
    public CustomerContractService customerContractService = new CustomerContractService();
    @TestVisible private RateClassesSelector rcSelector = new RateClassesSelector();
    @TestVisible private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private UALSelector ualSelector = new UALSelector();
    @TestVisible private ContentDocumentSelector contentSelector = new ContentDocumentSelector();
    @TestVisible private FilesUnitOfWorkHelper customWork = new FilesUnitOfWorkHelper();
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
    public fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
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
    @TestVisible protected LeadSelector leadSelector = new LeadSelector();

    public void setEnvelopeData(Object data) {
        envelope.setData(data);
    }

    public virtual void getZipcodeCapacity(String zipCode, String partnerId, String utilityId) {
        RestResponse response = RestContext.response;
        RestZipCode zipCodeResponse = new RestZipCode(capacityService.findCapacityByZipcode(zipCode, partnerId, utilityId));
        envelope.setData(zipCodeResponse);
        envelope.setJSONResponse(response);
    }

    public virtual void postLead(String jsonRequest) {
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;
        try {
            requestLead.validateCreateFields();
        } catch (Util.BWException e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.badRequest;
            envelope.setJSONResponse(response);
            return;
        }
        uow.registerWork(customWork);
        requestLead.insertLeadAccountAndUALs(response, this);
        envelope.setJSONResponse(response);
    }

    public virtual void getLead(String leadId, String email) {
        RestResponse response = RestContext.response;
        if (leadId == null || email == null) {
            envelope.addError('Request did not include correct fields to retrieve lead');
            response.statusCode = statusCode.badRequest;
        } else {
            Lead leadToReturn = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
            if (leadToReturn == null || leadToReturn.Email != email) {
                throw new Util.AuthorizationBWException('Invalid authorization, the leadId (' + leadId + ') does not match the email (' + email + ')');
            } else if (leadToReturn.Accounts__r.size() > 1) {
                envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
                response.statusCode = statusCode.badRequest;
            } else {
                RestLead responseLead = formatRestLeadFromLeadAndChildren(leadToReturn, false);
                envelope.setData(responseLead);
                response.statusCode = statusCode.ok;
            }
        }
        envelope.setJSONResponse(response);
    }

    /**
     * @description Called by (Aura) SSFApplication/SSFApplicationDTC on SSF application completion
     * Sets return envelope data to pass back to UI
     * @param jsonRequest Incoming PATCH request body
     */
    public virtual void patchLead(String jsonRequest) {
        Boolean applicationNowComplete = false;
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        RestResponse response = RestContext.response;
        Lead leadToUpdate = leadSelector.selectOne(requestLead.id);
        Map<String,Object> requestMap = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);

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
        if (requestLead.applicationCompleteDate != null && leadToUpdate.Application_Complete_Date__c == null) {
            // Request has application complete date, but database does not - this means it's now a completed application
            applicationNowComplete = true;
        }

        // Update Lead with JSON data from API, e.g. fill Application_Complete_Date__c set by SSF JS
        new RestLead.MergeService(requestLead).mergeFields(requestMap.keySet(), leadToUpdate);
        Lead lead = leadService.updateLead(leadToUpdate);

        // Check & Update "Application Status" field on Lead if necessary
        updateLeadApplicationStatus(lead.Id);

        // Handle actions when the application is newly marked as "Application Complete"
        // Placed last because we want to ensure Lead properly updates from SSF UI before enqueueing other actions
        if (applicationNowComplete) {
            CSApplicationFinisher appFinisher = new CSApplicationFinisher(lead.Id, null);
            System.enqueueJob(appFinisher);
        }

        RestLead responseLead = new RestLead(lead);
        envelope.setData(responseLead);
        response.statusCode = statusCode.ok;
        envelope.setJSONResponse(response);
    }

    public virtual void patchPropertyAccount(String jsonRequest) {
        RestLead.RestPropertyAccount requestAccount = (RestLead.RestPropertyAccount)
            JSON.deserialize(jsonRequest, RestLead.RestPropertyAccount.class);
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

    public virtual void patchApplication(String jsonRequest) {
        RestResponse response = RestContext.response;
        Map<String,Object> requestLeadMap = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);
        Id leadId = (Id)requestLeadMap.get('id');
        Lead existingLead = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
        if (applicationValid(jsonRequest, response, existingLead)) {
            Savepoint sp = Database.setSavepoint();
            try {
                // Assess state of contract documents
                Set<Id> contractIdSet = new Set<Id>();
                for (Contract contract : existingLead.Contracts__r) {
                    contractIdSet.add(contract.Id);
                }
                List<ContentDocumentLink> existingDocs = new List<ContentDocumentLink>();
                if (!contractIdSet.isEmpty()) {
                    existingDocs = contentSelector.selectByLinkedEntities(contractIdSet);
                }
                Boolean regenerateDocs =
                    existingDocs.isEmpty() ||
                    existingDocs[0].ContentDocument.CreatedDate.date() < Date.today().addDays(ContentDocLinkPrivacyScheduler.minDaysInPast) ||
                    contractFieldsUpdated(jsonRequest, existingLead);

                // Commit application data to database
                updateLeadAccountAndUALs(jsonRequest, existingLead);
                uow.commitWork();

                // Regenerate contract files if required
                if (regenerateDocs) {
                    customerContractService.regenerateDocuments(leadId);
                }

                // Update lead application status
                updateLeadApplicationStatus(leadId);

                RestLead responseLead = formatRestLeadFromLeadAndChildren(leadId, regenerateDocs);
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
        Boolean suppressAppCompleteActions = false;
        Map<String,Object> requestMap = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);
        RestResponse response = RestContext.response;
        Id leadId;
        Id signatureId;
        if (!requestMap.containsKey('leadId') || requestMap.get('leadId') == null) {
            envelope.addError('Request did not include correct fields to update');
            response.statusCode = statusCode.badRequest;
            envelope.setJSONResponse(response);
            return;
        }
        if (requestMap.containsKey('suppressAppComplete') && (Boolean) requestMap.get('suppressAppComplete') == true) {
            suppressAppCompleteActions = true;
        }
        try {
            leadId = (Id) requestMap.get('leadId');
            signatureId = (Id) requestMap.get('signatureId');
            customerContractService.signCustomerContracts(leadId, signatureId);
            updateLeadApplicationStatus(leadId);
            envelope.setData('OK');
            response.statusCode = statusCode.ok;
        } catch (System.StringException se) {
            envelope.addError('Bad lead ID; please provide a valid lead ID');
            response.statusCode = statusCode.badRequest;
        } catch (System.TypeException te) {
            envelope.addError('Bad lead ID; please provide a valid lead ID');
            response.statusCode = statusCode.badRequest;
        } catch (Exception e) {
            envelope.addError(e.getMessage());
            response.statusCode = statusCode.internalServerError;
        }
        if (!suppressAppCompleteActions) {
            CSApplicationFinisher appFinisher = new CSApplicationFinisher(leadId, Datetime.now());
            System.enqueueJob(appFinisher);
        }
        envelope.setJSONResponse(response);
    }

    private void updateLeadAccountAndUALs(String jsonRequest, Lead existingLead) {
        Map<String,Object> requestLeadMap = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);
        RestLead requestLead = (RestLead) JSON.deserialize(jsonRequest, RestLead.class);
        new RestLead.MergeService(requestLead).mergeFields(requestLeadMap.keySet(), existingLead);
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
    public void registerNewUALs(List<RestLead.RestUtilityAccountLog> reqUALs, Account propertyAccount) {
        for (RestLead.RestUtilityAccountLog requestUtilityAccountLog : reqUALs) {
            Utility_Account_Log__c newUal = requestUtilityAccountLog.asUAL(propertyAccount);
            uow.registerNew(newUal, Utility_Account_Log__c.Account__c, propertyAccount);
            if (requestUtilityAccountLog.utilityBills != null) {
                registerNewContentDocs(requestUtilityAccountLog.utilityBills, newUal);
            }
        }
    }

    private Boolean applicationValid(String jsonRequest, RestResponse response, Lead existingLead) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String,Object> requestMap = (Map<String,Object>) JSON.deserializeUntyped(jsonRequest);
        if (existingLead == null) {
            response.statusCode = statusCode.notFound;
            return false;
        }
        if (missingPropertyAccounts(requestMap, requestLead)) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        RestLead.RestPropertyAccount requestAccount = requestLead.propertyAccounts.get(0);
        if (tooManyOrWrongPropertyAccount(requestLead, existingLead, requestAccount)) {
            envelope.addError('Currently, only <=1 propertyAccount per lead is supported in the API.');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        Map<String,Object> accountMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(requestAccount));
        if (missingUtilityAccountLogs(accountMap, requestAccount)) {
            envelope.addError('Request did not include correct objects/fields to update');
            response.statusCode = statusCode.badRequest;
            return false;
        }
        return true;
    }
    
    private Boolean missingPropertyAccounts(Map<String,Object> requestMap, RestLead requestLead) {
        return requestMap.size() <= 1 || !requestMap.containsKey('propertyAccounts') || requestLead.propertyAccounts.isEmpty();
    }
    
    private Boolean tooManyOrWrongPropertyAccount(RestLead requestLead, Lead existingLead, RestLead.RestPropertyAccount requestAccount) {
        return requestLead.propertyAccounts.size() > 1 || existingLead.Accounts__r.size() > 1 ||
            (!existingLead.Accounts__r.isEmpty() && existingLead.Accounts__r[0].Id != requestAccount.id);
    }
    
    private Boolean missingUtilityAccountLogs(Map<String,Object> accountMap, RestLead.RestPropertyAccount requestAccount) {
        return accountMap.size() <= 1 ||
            !accountMap.containsKey('utilityAccountLogs') ||
            requestAccount.utilityAccountLogs == null ||
            requestAccount.utilityAccountLogs.isEmpty();
    }

    private void updateAccount(Lead lead, List<RestLead.RestPropertyAccount> requestPropertyAccounts, List<Object> requestAccountList) {
        Map<Id, Utility_Account_Log__c> existingUtilityAccountLogMap = ualSelector.selectAllByLeadMap(new Set<Id>{lead.Id});
        Map<Id, Account> existingAccountMap = accountsSelector.selectPropertyAccountsByLeadIdsMap(new Set<Id>{lead.Id});
        for (Integer acctIndex = 0; acctIndex < requestPropertyAccounts.size(); acctIndex++) {
            Map<String,Object> accountMap = (Map<String,Object>) requestAccountList[acctIndex];
            RestLead.RestPropertyAccount requestPropertyAccount = requestPropertyAccounts[acctIndex];
            Account propAcct;
            if (existingAccountMap.containsKey(requestPropertyAccount.id)) {
                propAcct = requestPropertyAccount.mergeFields(accountMap.keySet(), existingAccountMap.get(requestPropertyAccount.id));
                uow.registerDirty(propAcct);
            } else {
                requestPropertyAccount.validateCreateFields();
                propAcct = requestPropertyAccount.asAccount(lead);
                uow.registerNew(propAcct);
            }
            if (requestPropertyAccount.utilityAccountLogs != null && !requestPropertyAccount.utilityAccountLogs.isEmpty()) {
                List<Object> requestUALList = (List<Object>)accountMap.get('utilityAccountLogs');
                List<RestLead.RestUtilityAccountLog> requestUtilityAccountLogs = requestPropertyAccount.utilityAccountLogs;
                updateUtilityAccountLogs(propAcct, requestUtilityAccountLogs, requestUALList, existingUtilityAccountLogMap);
            }
        }
    }

    private void updateUtilityAccountLogs(
        Account propertyAccount, List<RestLead.RestUtilityAccountLog> requestUtilityAccountLogs, List<Object> requestUALList,
        Map<Id, Utility_Account_Log__c> existingUtilityAccountLogMap)
    {
        for (Integer ualIndex = 0; ualIndex < requestUtilityAccountLogs.size(); ualIndex++) {
            Map<String,Object> ualMap = (Map<String,Object>) requestUALList[ualIndex];
            RestLead.RestUtilityAccountLog requestUtilityAccountLog = requestUtilityAccountLogs[ualIndex];
            Utility_Account_Log__c ual;
            if (ualMap.size() <= 1) { // if == 1, then only has "id", which is not enough fields for a PATCH
                continue;
            } else if (existingUtilityAccountLogMap.containsKey(requestUtilityAccountLog.id)) {
                ual = requestUtilityAccountLog.mergeFields(ualMap.keySet(), existingUtilityAccountLogMap.get(requestUtilityAccountLog.id));
                uow.registerDirty(ual);
            } else {
                requestUtilityAccountLog.validateCreateFields();
                ual = requestUtilityAccountLog.asUAL(propertyAccount);
                uow.registerNew(ual, Utility_Account_Log__c.Account__c, propertyAccount);
            }
            if (requestUtilityAccountLog.utilityBills != null && !requestUtilityAccountLog.utilityBills.isEmpty()) {
                List<RestLead.RestContentDocument> requestContentDocuments = requestUtilityAccountLog.utilityBills;
                registerNewContentDocs(requestContentDocuments, ual);
            }
        }
    }

    @TestVisible
    private Boolean contractFieldsUpdated(String jsonRequest, Lead existingLead) {
        RestLead requestLead = (RestLead)JSON.deserialize(jsonRequest, RestLead.class);
        Map<String,Object> requestMap = (Map<String,Object>)JSON.deserializeUntyped(jsonRequest);
        for (String leadFieldName : contractLeadFields.keySet()) {
            String restLeadFieldName = contractLeadFields.get(leadFieldName);
            if (String.valueOf(requestMap.get(restLeadFieldName)) != String.valueOf(existingLead.get(leadFieldName))) {
                return true;
            }
        }
        if (existingLead.Partner_Lookup__c != requestLead.partnerId) {
            if (requestLead.partnerId != null) {
                return true;
            } else if (existingLead.Partner_Lookup__c != PartnerSelector.selectDefaultCSPartner().Id){
                return true;
            }
        }
        if (existingLead.bs_Sales_ID__c != requestLead.salesRepId) {
            Partner__c partner = PartnerSelector.selectPartnerByPartnerId(existingLead.Partner_Lookup__c);
            if (requestLead.salesRepId != null) {
                return true;
            } else if (existingLead.bs_Sales_ID__c != partner.Default_Sales_Rep__c){
                return true;
            }
        }
        return checkUALsForChanges(requestMap, existingLead);
    }

    private Boolean checkUALsForChanges(Map<String,Object> requestMap, Lead existingLead) {
        List<Object> accountList = (List<Object>)requestMap.get('propertyAccounts');
        Map<String,Object> accountMap = (Map<String,Object>)accountList.get(0);
        List<Object> ualList = (List<Object>)accountMap.get('utilityAccountLogs');
        if (existingLead.Utility_Account_Logs__r.size() != ualList.size()) {
            return true;
        }
        Map<String, Map<String,Object>> restUALMap = new Map<String, Map<String,Object>>();
        for (Object ualObj : ualList) {
            Map<String,Object> restUAL = (Map<String,Object>)ualObj;
            restUALMap.put((String)restUAL.get('utilityAccountNumber'), restUAL);
        }
        for (Utility_Account_Log__c leadUAL : existingLead.Utility_Account_Logs__r) {
            if (restUALDifferentFromLeadUAL(restUALMap, leadUAL)) {
                return true;
            }
        }
        return false;
    }

    private Boolean restUALDifferentFromLeadUAL(Map<String, Map<String,Object>> restUALMap, Utility_Account_Log__c leadUAL) {
        if (!restUALMap.containsKey(leadUAL.Name)) {
            return true;
        }
        Map<String,Object> restUAL = restUALMap.get(leadUAL.Name);
        for (String ualFieldName : contractUALFields.keySet()) {
            String restUALFieldName = contractUALFields.get(ualFieldName);
            if (String.valueOf(leadUAL.get(ualFieldName)) != String.valueOf(restUAL.get(restUALFieldName))) {
                return true;
            }
        }
        if (leadUAL.Utility_Rate_Class__r.Name != restUAL.get('rateClass')) {
            return true;
        }
        return false;
    }

    public RestLead formatRestLeadFromLeadAndChildren(Id leadId, Boolean docsNewlyGenerated) {
        Lead leadToReturn = leadSelector.selectOneWithPropertiesAndUtilities(leadId);
        return formatRestLeadFromLeadAndChildren(leadToReturn, docsNewlyGenerated);
    }

    private RestLead formatRestLeadFromLeadAndChildren(Lead leadToReturn, Boolean docsNewlyGenerated) {
        RestLead responseLead = new RestLead(leadToReturn);
        MultiMap ualsByPropertyAccountId = CollectionUtil.multiMapByField(leadToReturn.Utility_Account_Logs__r, Utility_Account_Log__c.Account__c);
        MultiMap leadUALandFUDCDLMap = getLeadUALandFUDCDLMap(leadToReturn, ualsByPropertyAccountId);

        setResponseLeadPropertyAccountsAndChildren(leadToReturn, ualsByPropertyAccountId, leadUALandFUDCDLMap, responseLead);
        setResponseLeadContentDocs(leadToReturn, responseLead, docsNewlyGenerated);
        setResponseLeadFinancialDocs(leadToReturn, leadUALandFUDCDLMap, responseLead);

        return responseLead;
    }

    private void setResponseLeadPropertyAccountsAndChildren(
        Lead leadToReturn, MultiMap ualsByPropertyAccountId, MultiMap leadUALandFUDCDLMap, RestLead responseLead)
    {
        List<RestLead.RestPropertyAccount> returnPropertyAccounts = new List<RestLead.RestPropertyAccount>();
        for (Account propertyAccount : leadToReturn.Accounts__r) {
            List<RestLead.RestUtilityAccountLog> returnUalList = new List<RestLead.RestUtilityAccountLog>();
            for (Object ual : ualsByPropertyAccountId.getValues(propertyAccount.Id)) {
                RestLead.RestUtilityAccountLog returnUal = new RestLead.RestUtilityAccountLog((Utility_Account_Log__c) ual);
                List<RestLead.RestContentDocument> utilityBillList = new List<RestLead.RestContentDocument>();
                for (Object cdl : leadUALandFUDCDLMap.getValues(returnUal.id)) {
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
    }
      
    private void setResponseLeadFinancialDocs(Lead leadToReturn, MultiMap leadUALandFUDCDLMap, RestLead responseLead) {
        List<RestLead.RestContentDocument> returnFinDocs = new List<RestLead.RestContentDocument>();
        for (Financial_Underwriting_Document__c finUnderwriteDoc : leadToReturn.Underwrite_Financial_Documents__r) {
            for (Object cdl : leadUALandFUDCDLMap.getValues(finUnderwriteDoc.Id)) {
                RestLead.RestContentDocument returnContentDoc = new RestLead.RestContentDocument((ContentDocumentLink) cdl);
                returnContentDoc.parentId = finUnderwriteDoc.Id;
                returnFinDocs.add(returnContentDoc);
            }
        }
        responseLead.financialDocs = returnFinDocs;
    }

    @TestVisible
    private void setResponseLeadContentDocs(Lead leadToReturn, RestLead responseLead, Boolean docsNewlyGenerated) {
        List<ContentDocumentLink> contractCDLs =
            contentSelector.selectByLinkedEntities(CollectionUtil.getIdSet(leadToReturn.Contracts__r));

        // Determine number of documents to instruct SSF to wait for
        responseLead.numberOfContractDocs = calcNumberOfContractDocuments(leadToReturn, responseLead);

        if (contractCDLs.isEmpty()) {
            responseLead.mostRecentContractGen = Datetime.now();
        } else if (docsNewlyGenerated) {
            ContentDocumentLink cdl = (ContentDocumentLink) contractCDLs[0];
            responseLead.mostRecentContractGen = cdl.ContentDocument.CreatedDate;
        } else {
            responseLead.contentDocs = compileLeadContentDocs(responseLead, contractCDLs);
        }
    }
    
    private MultiMap getLeadUALandFUDCDLMap(Lead leadToReturn, MultiMap ualsByPropertyAccountId) {
        Set<Id> linkedEntityIdSet = new Set<Id>{
            leadToReturn.Id
        };
        linkedEntityIdSet.addAll(CollectionUtil.getIdSet(leadToReturn.Underwrite_Financial_Documents__r));
        for (Object accountId : ualsByPropertyAccountId.keySet()) {
            for (Object ualObj : ualsByPropertyAccountId.getValues((Id) accountId)) {
                Utility_Account_Log__c ual = (Utility_Account_Log__c) ualObj;
                linkedEntityIdSet.add(ual.Id);
            }
        }
        List<ContentDocumentLink> leadUALandFUDCDLs = contentSelector.selectByLinkedEntitiesWithoutData(linkedEntityIdSet);
        MultiMap leadUALandFUDCDLMap = CollectionUtil.multiMapByField(leadUALandFUDCDLs, ContentDocumentLink.LinkedEntityId);
        return leadUALandFUDCDLMap;
    }

    public void registerNewContentDocs(List<RestLead.RestContentDocument> requestContentDocuments, SObject linkedEntity) {
        for (RestLead.RestContentDocument requestContentDocument : requestContentDocuments) {
            if (requestContentDocument.id == null) {
                requestContentDocument.body = String.escapeSingleQuotes(requestContentDocument.body);
                requestContentDocument.validateCreateFields();
                ContentVersion newContentVersion = requestContentDocument.asContentVersionForInsert();
                uow.registerNew(newContentVersion);
                customWork.registerContentDocumentLinkInsert(linkedEntity, newContentVersion, 'V', 'AllUsers');
            } else if (requestContentDocument.docLinkId == null){
                ContentDocumentLink newContentLink = requestContentDocument.asContentDocLinkForInsert();
                uow.registerNew(newContentLink, ContentDocumentLink.LinkedEntityId, linkedEntity);
            } else if (requestContentDocument.lastPublishedVersionId == null) {
                requestContentDocument.body = String.escapeSingleQuotes(requestContentDocument.body);
                requestContentDocument.validateCreateFields();
                ContentVersion newContentVersion = requestContentDocument.asContentVersionForInsert();
                newContentVersion.ContentDocumentId = requestContentDocument.id;
                uow.registerNew(newContentVersion);
            }
        }
    }

    /**
     * @description Retrieves formatted Contract files for response to SSF client
     * @param responseLead Formatted lead submitted to SSF, from which application details are retrieved
     * @param contractCDLs Contract ContentDocumentLinks (CDLs)
     * @return List of RestContentDocuments to provide back to client in SSF
     */
    private List<RestLead.RestContentDocument> compileLeadContentDocs(RestLead responseLead, List<Object> contractCDLs) {
        List<RestLead.RestContentDocument> restContentDocs = new List<RestLead.RestContentDocument>();
        Integer docCount = Math.min(responseLead.numberOfContractDocs, contractCDLs.size());

        for (Integer i=0; i < docCount; i++) {
            RestLead.RestContentDocument rcd = new RestLead.RestContentDocument((ContentDocumentLink) contractCDLs[i]);
            rcd.publicUrl = contentSelector.getPublicDistributionLinkByDocId(rcd.docLinkId);
            restContentDocs.add(rcd);
        }
        return restContentDocs;
    }

    /**
     * @description Assesses number of contract files that should be retrieved from server for contract signature
     * <p></p>
     * Logic moved from ssfBasicInfoShared.js to this class
     * @param lead Lead retrieved from database
     * @param restLead Formatted lead for SSF
     * @return Integer number of contract files to retrieve and send to SSF client
     */
    public Integer calcNumberOfContractDocuments(Lead lead, RestLead restLead) {
        // ONE Contract file needed if selected Product specifies a standalone disclosure form
        if (lead.Product__r.Disclosure_Form_Conga_Template__c == null) {
            return 1;
        }

        // Determine number of Contract files based on rate class specifics
        List<String> rateClassNames = new List<String>();
        for (RestLead.RestUtilityAccountLog ual : restLead.propertyAccounts[0]?.utilityAccountLogs) {
            if (ual.rateClass == null) {
                // Null rate class on any UAL, don't suppress disclosure and provide 2 contract files
                return 2;
            } else {
                rateClassNames.add(ual.rateClass);
            }
        }

        Integer rateClassesInApplication = rateClassNames.size();
        Integer rateClassesWithSuppressedDisclosure = 0;

        Map<String,Rate_Class__c> rateClasses = rcSelector.selectByNameAndUtility(rateClassNames,restLead.utilityId);
        for (String name : rateClassNames) {
            Rate_Class__c rateClass = rateClasses.get(name);
            if (rateClass?.Suppress_Disclosure_Form__c == true) {
                rateClassesWithSuppressedDisclosure++;
            }
            if (rateClassesWithSuppressedDisclosure == rateClassesInApplication) {
                return 1;
            }
        }

        // Default to 2 contract file retrieval
        return 2;
    }

    /**
     * @description Updates Lead Application Status based on Lead criteria and specific logic.
     * Operates similar to a Trigger on Lead.
     * @param leadId Lead to update
     */
    @SuppressWarnings('PMD.ApexOpenRedirect')
    public void updateLeadApplicationStatus(Id leadId) {
        Lead lead = leadSelector.selectOneForStatusUpdate(leadId);
        String status = getApplicationStatus(lead);
        if (lead.Application_Status__c != status) {
            lead.Application_Status__c = status;
            pullCreditForSignedLead(lead, status);
            setContinueApplicationLinks(lead, status);
            Util.updateAndLog(new List<SObject>{lead}, 'CSLeadsRESTControllerV2', 'updateLeadApplicationStatus');
        }
    }

    /**
     * Separate method to potentially be used by SSF directly when resolving "No Match" credit reports
     *
     * @param lead Lead to be updated
     * @param status String to check if Contracts have been signed by customer (ie Contracts Signed);
     */
    private void pullCreditForSignedLead(Lead lead, String status) {
        if (status == 'Contracts Signed' && lead.Underwriting_Criteria__c == 'FICO') {
            lead.Soft_Pull_Credit_Report__c = true;
        }
    }

    /**
     * @description Sets links on Lead to access application in SSF at a later state
     * @param lead Lead to set links for
     * @param applicationStatus Current application status of Lead
     */
    public static void setContinueApplicationLinks(Lead lead, String applicationStatus) {
        if (applicationStatus == null) {
            applicationStatus = getApplicationStatus(lead);
        }
        String location = APP_STATUS_TO_LOCATION.get(applicationStatus);

        // Set Continue Application link with all mandatory fields
        PageReference continueUrl = new PageReference(Util.getCommunitySiteURL('Apply') + '/s/switch');
        continueUrl.getParameters().put('leadid', lead.Id);
        continueUrl.getParameters().put('email', lead.Email);
        continueUrl.getParameters().put('partnerId', lead.Partner_Lookup__c);
        continueUrl.getParameters().put('loc', location);
        lead.Continue_Application_Link__c = continueUrl.getUrl();

        // Set Contract Re-Sign (Agree page) link based on current Lead info
        PageReference resignUrl = new PageReference(continueUrl.getUrl());
        resignUrl.getParameters().put('loc', 'agree');
        lead.Contract_eSign_Link__c = resignUrl.getUrl();
    }

    public static String getApplicationStatus(Lead lead) {
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
    private static String getUALStatus(List<Utility_Account_Log__c> ualList) {
        List<Id> ualIds = new List<Id>();
        for (Utility_Account_Log__c ual : ualList) {
            if (ual.Utility_lookup__r.Utility_Data_Collection_Mechanism__c == 'File Upload') {
                ualIds.add(ual.Id);
            }
        }
        if (ualIds.isEmpty()) {
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
        for (Utility_Account_Log__c ual : uploadUALs) {
            if (ual.ContentDocumentLinks.isEmpty()) {
                utilityBillsPresent = false;
                break;
            }
        }
        if (utilityBillsPresent) {
            return 'Customer Info Completed';
        }
        return 'Started';
    }
}