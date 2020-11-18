/**
 * Created by mstackhouse on 12/12/2018.
 * Description: Moving Logic for CS Subscriptions out of LeadTriggerHandler.
 * Dependencies: Leads, SharedSolarSystems, ChargentOrders (on leads)
 *
 * Outputs: Opportunities for leads, Utility Account Subscriptions for leads
 * Test: LeadTriggerHandlerTest, LeadServiceTestclass
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSSubscriptionEnroller {
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();

    private List<Lead> leads;
    private Map<Id, Lead> leadIdToLeadWithChildren;
    private List<Shared_Solar_System__c> sssList;
    private Map<Id, Product2> productsMap;
    private Map<Id, List<Shared_Solar_System__c>> leadIdToAvailableSSS;
    private Map<Id, List<Opportunity>> leadOppsMap;
    private Map<Id, Account> accountIdToAccountWithContacts;
    private List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders;


    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            ChargentOrders__ChargentOrder__c.SObjectType,
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
            if(lead.ConvertedAccountId != null) {
                parentAccountIds.add(lead.ConvertedAccountId);
            }
        }
        
        leadIdToLeadWithChildren = new Map<Id, Lead>([
            SELECT Id,
                (SELECT Id, Name, Annual_Cost_of_Electricity__c, Annual_kWh__c, Lead__c, 
                    Lead__r.Product__r.Customer_Subscription_Type__c, Name_on_Account__c, Proposed_kWh__c, 
                    Subsc_Annual_Cost_of_Electricity_Rollup__c, Subscribed_Annual_kWhs_Rollup__c, 
                    Subscribed_Annual_Cost_of_Electricity__c, Subscribed_Annual_kWhs__c, Utility__c, 
                    Utility_NMC_Tariff__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c
                FROM Utility_Account_Logs__r
                ORDER BY Annual_Cost_of_Electricity__c, Annual_kWh__c DESC),
                (SELECT Id FROM Accounts__r WHERE RecordType.Name = 'Property'),
                (SELECT Id, Lead__c, ChargentOrders__Payment_Method__c, ChargentOrders__Bank_Name__c,
                    ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Account_Type__c,
                    ChargentOrders__Bank_Account_Number__c, ChargentOrders__Bank_Account_Name__c,
                    ChargentOrders__Billing_Email__c, ChargentOrders__Card_Type__c,
                    ChargentOrders__Card_Number__c, ChargentOrders__Card_Expiration_Month__c,
                    ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Billing_Address__c,
                    ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c,
                    ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Billing_First_Name__c,
                    ChargentOrders__Billing_Last_Name__c, Autopay_Only__c
                FROM Chargent_Orders__r),
                (SELECT Id, AccountId, Contract_Type__c, Customer_Signature_Date_Time__c, Product__c
                FROM Contracts__r WHERE RecordTypeId = :CustomerContractService.RECORD_TYPE_ID
                ORDER BY CreatedDate DESC)
            FROM Lead
            WHERE Id = :leadIds
        ]);
        
        sssList = sssSelector.getSharedSolarSystemsForEnrollment();

        productsMap = new Map<Id, Product2>([
            SELECT Id, Program__c, Sizing_Method__c,
                (SELECT Id, Name, Size_Ratio__c, Utility_NMC_Tariff__r.Customer_Type__c,
                    Utility_NMC_Tariff__r.Minimum_kWh__c, Utility_NMC_Tariff__r.Maximum_kWh__c,
                    Utility_NMC_Tariff__r.Utility_Relationship__c, Utility_NMC_Tariff__c
                FROM Product_Tariffs__r)
            FROM Product2
            WHERE Product_Type__c = 'Community Solar'
        ]);

        accountIdToAccountWithContacts = new Map<Id, Account>([
            SELECT Id, (SELECT Id FROM Contacts)
            FROM Account WHERE Id = :parentAccountIds
        ]);


        leadOppsMap = new Map<Id, List<Opportunity>>();
        leadIdToAvailableSSS = new Map<Id, List<Shared_Solar_System__c>>();
        uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();
    }


    public void enroll() {
        for (Lead lead : leads) {
            if (!featureService.isEnabled('Sizing_Method')) {
                calculateProposedkWh(lead);
            }
            AnnualEnergyTotal annualTotals = getAnnualTotals(lead);
            if (annualTotals.cost != 0 || annualTotals.kWh != 0) {
                createOpportunityAndContactRoles(lead, annualTotals);
                createUAS(lead);
                moveChOrderToAccount(lead);
                if (lead.Zuora_Payment_Ref_Id__c != null) {
                    System.enqueueJob(new ZuoraAccountAsyncService(lead.Id));
                }
            }
        }
        
        try {
            uow.commitWork();
        } catch(Exception ex) {
            String exceptionMsg =  'Error creating enrollments for converted leads. Exception: ';
            if(ex.getTypeName() == 'DmlException') {
                for(Integer i=0; i<ex.getNumDml(); i++) {
                    exceptionMsg += '\nFor ID ' + ex.getDmlId(i) + ' the following fields caused a ' + ex.getDmlStatusCode(i) + ' error: ' + ex.getDmlFieldNames(i);
                }
            } else {
                exceptionMsg += ex.getMessage() + '\nCause: ' + ex.getCause();
            }
            
            Logger.logLater(
                'CSSubscriptionEnroller', 
                'enroll', 
                exceptionMsg + '\nStackTrace: ' + ex.getStackTraceString()
            );
        }

        Logger.flushLogs();
    }


    private void calculateProposedkWh(Lead lead) {
        Product2 product = productsMap.get(lead.Product__c);
        for (Utility_Account_Log__c ual : leadIdToLeadWithChildren.get(lead.Id).Utility_Account_Logs__r) {
            Product_Tariff__c tariff = assignUtilityTariff(ual, lead, product.Product_Tariffs__r);
            if (tariff != null && product != null && ual.Annual_kWh__c != null) {
                ual.Utility_NMC_Tariff__c = tariff.Utility_NMC_Tariff__c;
                ual.Product_Tariff__c = tariff.Id;
                // Currently, we only need to have a sizing ratio for SMART
                Decimal sizeRatio;
                if (tariff.Size_Ratio__c != null) {
                    sizeRatio = tariff.Size_Ratio__c;
                } else {
                    sizeRatio = 1.0;
                }
                ual.Proposed_kWh__c = ual.Annual_kWh__c * sizeRatio;
            } else {
                ual.Proposed_kWh__c = ual.Annual_kWh__c;
            }
            uow.registerDirty(ual);
        }
    }


    private Product_Tariff__c assignUtilityTariff(Utility_Account_Log__c ual, Lead lead, List<Product_Tariff__c> tariffs) {
        if (tariffs == null) {
            return null;
        }
        
        Product_Tariff__c assignedTariff;
        for (Product_Tariff__c tariff : tariffs) {
            if (lead.Customer_type__c == tariff.Utility_NMC_Tariff__r.Customer_type__c
                    && lead.Utility_relationship__c == tariff.Utility_NMC_Tariff__r.Utility_Relationship__c
                    && (tariff.Utility_NMC_Tariff__r.Maximum_kWh__c == null || ual.Annual_kWh__c < tariff.Utility_NMC_Tariff__r.Maximum_kWh__c)
                    && (tariff.Utility_NMC_Tariff__r.Minimum_kWh__c == null || ual.Annual_kWh__c >= tariff.Utility_NMC_Tariff__r.Minimum_kWh__c)) {
                if (assignedTariff == null) {
                    assignedTariff = tariff;
                } else {
                    String message = 'Lead ' + lead.Id + ' meets the criteria for multiple tariffs.';
                    message += ' Assigned Tariff: ' + assignedTariff;
                    message += ' Other Qualified Tariff: ' + tariff;
                    Logger.logLater('CSSubscriptionEnroller', 'assignUtilityTariff', message);
                }
            }
        }
        return assignedTariff;
    }


    private AnnualEnergyTotal getAnnualTotals(Lead lead) {
        Decimal totalAnnualCostOfElectricity = 0;
        Decimal totalAnnualkWhElectricity = 0;
        for (Utility_Account_Log__c ual : leadIdToLeadWithChildren.get(lead.Id).Utility_Account_Logs__r) {
            if (ual.Annual_Cost_of_Electricity__c == null && ual.Annual_kWh__c == null) {
                throw new Util.BWException('No Annual Usage populated on UALs. Please enter usage before converting');
            }
            if (featureService.isEnabled('Sizing_Method')) {
                totalAnnualCostOfElectricity += Util.nullToZero(ual.Annual_Cost_of_Electricity__c);
                if (productsMap.get(lead.Product__c).Sizing_Method__c == 'Rate Class Ratio' && ual.Utility_Rate_Class__c != null) {
                    totalAnnualkWhElectricity += Util.nullToZero((ual.Annual_kWh__c * ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c));
                } else {
                    totalAnnualkWhElectricity += Util.nullToZero(ual.Annual_kWh__c);
                }
            } else {
                totalAnnualCostOfElectricity += Util.nullToZero(ual.Annual_Cost_of_Electricity__c);
                totalAnnualkWhElectricity += Util.nullToZero(ual.Proposed_kWh__c);
            }

            if (featureService.isEnabled('Subscription_Orders')) {
                totalAnnualCostOfElectricity -= Util.nullToZero(ual.Subsc_Annual_Cost_of_Electricity_Rollup__c);
                totalAnnualkWhElectricity -= Util.nullToZero(ual.Subscribed_Annual_kWhs_Rollup__c);
            } else {
                totalAnnualCostOfElectricity -= Util.nullToZero(ual.Subscribed_Annual_Cost_of_Electricity__c);
                totalAnnualkWhElectricity -= Util.nullToZero(ual.Subscribed_Annual_kWhs__c);
            }
        }
        return new AnnualEnergyTotal(totalAnnualCostOfElectricity, totalAnnualkWhElectricity);
    }


    private void createOpportunityAndContactRoles(Lead lead, AnnualEnergyTotal annualTotals) {
        Id propertyAccountId = getPropertyAccount(lead);
        ChargentOrders__ChargentOrder__c chargentOrder = leadIdToLeadWithChildren.get(lead.Id).Chargent_Orders__r.isEmpty() ? null : leadIdToLeadWithChildren.get(lead.Id).Chargent_Orders__r[0];
        List<Shared_Solar_System__c> availableSSS = getSortedSharedSolarSystems(lead);
        leadIdToAvailableSSS.put(lead.Id, availableSSS);
        
        //Need to pass the property Account here (not converted Account)
        List<Opportunity> oppListToCreate = CSOpportunityFactory.generateCSOpportunities(lead, availableSSS, chargentOrder, annualTotals, propertyAccountId);
        leadOppsMap.put(lead.Id, oppListToCreate);
        for(Opportunity opp : oppListToCreate) {
            List<Contract> leadContracts = leadIdToLeadWithChildren.get(lead.Id).Contracts__r;
            if(!leadContracts.isEmpty()) {
                Contract parentContract = leadContracts[0];
                if(parentContract.Contract_Type__c == 'Generic') {
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
        
        if(accountIdToAccountWithContacts.containsKey(lead.ConvertedAccountId)) {
            for(Contact contact : accountIdToAccountWithContacts.get(lead.ConvertedAccountId).Contacts) {
                for(Opportunity opp : oppListToCreate) {
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


    private Id getPropertyAccount(Lead lead) {
        Id propAccountId;
        //If Switch lead, the property account will be in the list already. If CSAP Lead, will need to grab the Converted Account
        if (!leadIdToLeadWithChildren.get(lead.Id).Accounts__r.isEmpty()){
            return leadIdToLeadWithChildren.get(lead.Id).Accounts__r[0].Id;
        } else if (lead.IsConverted && lead.ConvertedAccountId != null) {
            propAccountId = lead.ConvertedAccountId;
        }
        return propAccountId;
    }
    

    private List<Shared_Solar_System__c> getSortedSharedSolarSystems(Lead lead) {
        List<SSSWrapper> sssWrappers = new List<SSSWrapper>();
        List<Shared_Solar_System__c> sortedSharedSolarSystems = new List<Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : sssList) {
            if (sss.Utility__c == lead.Utility_Relationship__c &&
                sss.Service_Territories__c != null && 
                sss.Service_Territories__c.contains(lead.LoadZone__c) &&
                SharedSolarSystems.isPartnerEligible(lead.Partner_Lookup__c, sss.Partner_Shared_Solar_System_Accesses__r) &&
                (lead.Product__c == null || sss.Product__c == lead.Product__c) &&
                (
                    (lead.Underwriting_Criteria__c == 'FICO' && sss.Available_SMB_Underwriting_Method_FICO__c && Decimal.valueOf(lead.LASER_Credit_Score__c) >= sss.Credit_Score_Requirement__c)
                    || (lead.Underwriting_Criteria__c == 'Financial Review' && sss.Available_SMB_Underwriting_Method_Docs__c)
                    || (lead.Underwriting_Criteria__c != 'FICO' && lead.Underwriting_Criteria__c != 'Financial Review')
                )
            ) {
                    sssWrappers.add(new SSSWrapper(sss, lead.System_Assignment__c));
            }
        }
        sssWrappers.sort();
        for (Integer wrapperIndex = 0; wrapperIndex < sssWrappers.size(); wrapperIndex++) {
            sortedSharedSolarSystems.add(sssWrappers[wrapperIndex].sss);
        }
        return sortedSharedSolarSystems;
    }


    private void createUAS(Lead lead) {
        List<Shared_Solar_System__c> sharedSolarSystems = leadIdToAvailableSSS.get(lead.Id);
        List<Opportunity> opportunities = leadOppsMap.get(lead.Id);
        List<Utility_Account_Log__c> uals = leadIdToLeadWithChildren.get(lead.Id).Utility_Account_Logs__r;

        // if UALs aren't sorted by the field matching their subscription type and both annual kwh and annual cost are populated,
        //  UASes aren't assigned appropriately
        if(lead.Product__r.Customer_Subscription_Type__c == 'kWh') {
            CollectionUtil.sort(uals, Comparators.sobjectFieldValueComparator(Utility_Account_Log__c.Annual_kWh__c).ascending(false).nullsFirst(false));
        } else {
            CollectionUtil.sort(uals, Comparators.sobjectFieldValueComparator(Utility_Account_Log__c.Annual_Cost_of_Electricity__c).ascending(false).nullsFirst(false));
        }
        
        CSUtilityAccountSubscriptionFactory.generateSubscriptions(uals, sharedSolarSystems, opportunities, uow);
    }

    
    private void moveChOrderToAccount(Lead lead) {
        //Link the chargent order to the property account, not the converted account
        Id propAccountId = getPropertyAccount(lead);

        for(ChargentOrders__ChargentOrder__c chargentOrder : leadIdToLeadWithChildren.get(lead.Id).Chargent_Orders__r) {
            chargentOrder.ChargentOrders__Account__c = propAccountId;
            uow.registerDirty(chargentOrder);
        }
    }



    public class AnnualEnergyTotal {
        public Decimal cost;
        public Decimal kWh;

        public AnnualEnergyTotal(Decimal cost, Decimal kWh) {
            this.cost = cost.setScale(0);
            this.kWh = kWh.setScale(0);
        }
    }

    private class SSSWrapper implements Comparable {
        public Shared_Solar_System__c sss;
        public String systemAssignment;
        public SSSWrapper(Shared_Solar_System__c sss, String systemAssignment) {
            this.sss = sss;
            this.systemAssignment = systemAssignment;
        }
        public Integer compareTo(Object compareTo) {
            SSSWrapper compareToSSS = (SSSWrapper) compareTo;
            Integer returnValue = 0;
            if (systemAssignment == 'Automatic - COD Date/Available Capacity' || systemAssignment == null) {
                if (sss.Estimated_COD_Date_Manual__c > compareToSSS.sss.Estimated_COD_Date_Manual__c) {
                    returnValue = 1;
                } else if (sss.Estimated_COD_Date_Manual__c < compareToSSS.sss.Estimated_COD_Date_Manual__c) {
                    returnValue = -1;
                } else {
                    if (sss.Project_Capacity_Available_kW_DC__c > compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = 1;
                    } else if (sss.Project_Capacity_Available_kW_DC__c < compareToSSS.sss.Project_Capacity_Available_kW_DC__c) {
                        returnValue = -1;
                    }
                }
            } else if (systemAssignment == 'Automatic - Assignment Order') {
                if (sss.Assignment_Order__c > compareToSSS.sss.Assignment_Order__c) {
                    return 1;
                } else if (sss.Assignment_Order__c < compareToSSS.sss.Assignment_Order__c) {
                    return -1;
                }
            }
            return returnValue;
        }
    }
}