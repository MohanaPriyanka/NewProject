/**
 * @description Created by mstackhouse on 12/12/2018.
 * Dependencies: Leads, SharedSolarSystems
 *
 * Outputs: Opportunities for leads, Utility Account Subscriptions for leads
 * Tested by: CSOpportunityFactoryTest, LeadServiceTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSSubscriptionEnroller {

    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private SharedSolarSystems sssList;
    private List<Lead> leads;
    private Map<Id, Lead> leadsWithChildren;
    private Map<Id, Product2> productsMap;
    private Map<Id, List<Shared_Solar_System__c>> availableSystemsByLeadId;
    private Map<Id, List<Opportunity>> leadOppsMap;
    private Map<Id, Account> accountsWithContacts;
    private List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders;

    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType>{
            Utility_Account_Log__c.SObjectType,
            Contract.SObjectType,
            Opportunity.SObjectType,
            OpportunityContactRole.SObjectType,
            Utility_Account_Subscription__c.SObjectType,
            Subscription_Order__c.SObjectType
        }
    );

    public CSSubscriptionEnroller(List<Lead> leads) {
        this.leads = leads;

        Set<Id> leadIds = new Set<Id>();
        Set<Id> parentAccountIds = new Set<Id>();
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
            if (lead.ConvertedAccountId != null) {
                parentAccountIds.add(lead.ConvertedAccountId);
            }
        }

        leadsWithChildren = new LeadSelector().getLeadsForSubscriptionCreation(leadIds);
        sssList = new SharedSolarSystems(sssSelector.getSharedSolarSystemsForEnrollment());
        productsMap = new ProductSelector().selectProductsForSubscriptionCreation();
        accountsWithContacts = new AccountsSelector().selectParentAccountWithContacts(parentAccountIds);
        leadOppsMap = new Map<Id, List<Opportunity>>();
        availableSystemsByLeadId = new Map<Id, List<Shared_Solar_System__c>>();
        uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();
    }

    public void enroll() {
        for (Lead lead : leads) {
            AnnualEnergyTotal annualTotals = getAnnualTotals(lead);
            if (annualTotals.cost != 0 || annualTotals.kWh != 0) {
                createOpportunityAndContactRoles(lead, annualTotals);
                createUAS(lead);
                if (lead.Zuora_Payment_Ref_Id__c != null) {
                    System.enqueueJob(new ZuoraAccountAsyncService(lead.Id));
                }
            }
        }
        try {
            uow.commitWork();
        } catch (Exception ex) {
            Logger.logLater(
                'CSSubscriptionEnroller',
                'enroll',
                ex.getMessage() + '\n' + ex.getStackTraceString()
            );
        }
        Logger.flushLogs();
    }

    private AnnualEnergyTotal getAnnualTotals(Lead lead) {
        Decimal totalAnnualCostOfElectricity = 0;
        Decimal totalAnnualkWhElectricity = 0;
        for (Utility_Account_Log__c ual : leadsWithChildren.get(lead.Id).Utility_Account_Logs__r) {
            if (ual.QC_Status__c == 'Pending BW Review' || ual.QC_Status__c == 'Pending Utility Data') {
                throw new Util.BWException('Utility Account Logs are in QC Pending. Please review the UALs and set the status to Complete before converting.');
            }
            if ((ual.Annual_Cost_of_Electricity__c == null && productsMap.get(lead.Product__c).Customer_Subscription_Type__c == 'Electricity Cost ($)')
                || (ual.Annual_kWh__c == null && productsMap.get(lead.Product__c).Customer_Subscription_Type__c == 'kWh')) {
                throw new Util.BWException('No Annual Usage populated on UALs. Please enter usage before converting');
            }

            totalAnnualCostOfElectricity += Util.nullToZero(ual.Annual_Cost_of_Electricity__c);
            totalAnnualCostOfElectricity -= Util.nullToZero(ual.Subsc_Annual_Cost_of_Electricity_Rollup__c);
            totalAnnualkWhElectricity -= Util.nullToZero(ual.Subscribed_Annual_kWhs_Rollup__c);

            if (productsMap.get(lead.Product__c).Sizing_Method__c == 'Rate Class Ratio' && productsMap.get(lead.Product__c).Customer_Subscription_Type__c == 'kWh') {
                try {
                    totalAnnualkWhElectricity += Util.nullToZero((ual.Annual_kWh__c * ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c));
                } catch (System.NullPointerException e) {
                    throw new Util.BWException('Utility Account Log is missing required information for sizing. Confirm that the UAL has: ' + '\n' +
                        '1. Rate Class on UAL' + '\n' +
                        '2. Rate Class has a Sizing Method with a Size Ratio'
                    );
                }
            } else {
                totalAnnualkWhElectricity += Util.nullToZero(ual.Annual_kWh__c);
            }
        }
        return new AnnualEnergyTotal(totalAnnualCostOfElectricity, totalAnnualkWhElectricity);
    }

    private void createOpportunityAndContactRoles(Lead lead, AnnualEnergyTotal annualTotals) {
        Id propertyAccountId = leadsWithChildren.get(lead.Id).Accounts__r[0].Id;
        List<Shared_Solar_System__c> availableSSS = sssList.getQualifiedForLead(lead);
        availableSystemsByLeadId.put(lead.Id, availableSSS);

        //Need to pass the property Account here (not converted Account)
        List<Opportunity> oppListToCreate = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, annualTotals, propertyAccountId);
        leadOppsMap.put(lead.Id, oppListToCreate);
        for (Opportunity opp : oppListToCreate) {
            List<Contract> leadContracts = leadsWithChildren.get(lead.Id).Contracts__r;
            if (!leadContracts.isEmpty()) {
                Contract parentContract = leadContracts[0];
                if (parentContract.Contract_Type__c == 'Generic') {
                    Contract oppContract = CustomerContractService.createForOpportunity(opp, parentContract);
                    uow.registerNew(oppContract);
                    uow.registerNew(opp, Opportunity.ContractId, oppContract);
                } else {
                    uow.registerNew(opp, Opportunity.ContractId, parentContract);
                }
            } else {
                uow.registerNew(opp);
            }
        }

        if (accountsWithContacts.containsKey(lead.ConvertedAccountId)) {
            for (Contact contact : accountsWithContacts.get(lead.ConvertedAccountId).Contacts) {
                for (Opportunity opp : oppListToCreate) {
                    uow.registerNew(
                        new OpportunityContactRole(
                            ContactId = contact.Id,
                            Role = 'Customer',
                            IsPrimary = true
                        ),
                        OpportunityContactRole.OpportunityId,
                        opp
                    );
                }
            }
        }
    }

    private void createUAS(Lead lead) {
        List<Shared_Solar_System__c> sharedSolarSystems = availableSystemsByLeadId.get(lead.Id);
        List<Opportunity> opportunities = leadOppsMap.get(lead.Id);
        List<Utility_Account_Log__c> uals = leadsWithChildren.get(lead.Id).Utility_Account_Logs__r;

        // if UALs aren't sorted by the field matching their subscription type and both annual kwh and annual cost are populated,
        //  UASes aren't assigned appropriately
        if (lead.Product__r.Customer_Subscription_Type__c == 'kWh') {
            CollectionUtil.sort(uals, Comparators.sobjectFieldValueComparator(Utility_Account_Log__c.Annual_kWh__c).ascending(false).nullsFirst(false));
        } else {
            CollectionUtil.sort(uals, Comparators.sobjectFieldValueComparator(Utility_Account_Log__c.Annual_Cost_of_Electricity__c).ascending(false).nullsFirst(false));
        }

        CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities, uow);
    }

    public class AnnualEnergyTotal {
        public Decimal cost;
        public Decimal kWh;

        public AnnualEnergyTotal(Decimal cost, Decimal kWh) {
            this.cost = cost.setScale(0);
            this.kWh = kWh.setScale(0);
        }
    }
}