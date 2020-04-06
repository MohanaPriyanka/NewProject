public without sharing class RecalculateUALCostController {
    
    public String ualId {get; set;}
    public String uasId {get; set;}
    
    public Utility_Account_Log__c ual {get; set;}

    public Decimal ualCostOfElectricity {get; set;}
    public Decimal ualkWhOfElectricity {get; set;}
    public Decimal subscribedCostOfElectricity {get; set;}
    public Decimal subscribedkWhOfElectricity {get; set;}
    public Decimal adjustmentAmount {get; set;}
    public String sizeBy {get; set;}

    public List<UASAction> uasActionList {get; set;}

    public Boolean adminMode {get; set;}

    /*
        https://c.cs2.visual.force.com/apex/RecalculateUALCost?id=a1bR0000004t8F3&adminMode=1
    */

    //Go through each UAS and check the following:
    //Check the Open == true ScheduleZ_Filed__c = false records if we are able to deduct the difference then allow the user to process it.
    //If there are still remaining balance:
        //Check the Open == false ScheduleZ_Filed__c = false records if we are able to deduct the difference then allow the user to process it but with the option of asking the user:
        //- Deduct and mark as Open
        //- Deduct and keep as Closed
    
    //If there are still remaining balance:
        //Check the Open == false ScheduleZ_Filed__c = true records if we are able to deduct the difference then allow the user to process it but with the option of asking the user:


    //Shared Solar System Name, Open, Scheduled Z Filed,Available Capacity, COD Date,Customer Group,Customer Ratio, Amount to be deducted, Action

    //if (all records already have ScheduleZ_Filed__c == true){
    //    //If the user does not have "System Administrator" Profile
    //    //Error message: "Please contact one of Bluewave's Administrator to make this change as all systems have had a Schedule Z filed."

    //    //For the System Administrator profile:
    //    // Allow the user to continue processing even if the ScheduleZ_Filed__c = true
    //}

    //Give the option of not deducting it for open systems
    //Picklist options: 
        //- Deduct and mark as Open
        //- Deduct and keep as Closed
        //-  Potential scenario on possibly not deducting it

        //If ScheduleZ_Filed__c == true
        //    - Checkbox to mark (Confirm deduction to Schedule Z Filed System)


    public RecalculateUALCostController(){
        uasActionList = new List<UASAction>();
        this.ualId = ApexPages.currentPage().getParameters().get('id');

        adminMode = false;
        Profile userProfile = [Select Name from Profile where Id = :UserInfo.getProfileid()];
        if(userProfile.Name == 'System Administrator'){
            adminMode = true;
        }

        //Query data and check the total Annual Cost of Electricity
        Utility_Account_Log__c ual = [
            SELECT Id, Name, Annual_Cost_of_Electricity__c, Cost_not_yet_Allocated__c, Annual_kWh__c,
                Subscribed_Annual_kWhs__c, Lead__r.Product__r.Customer_Subscription_Type__c, Proposed_kWh__c,
                Subscribed_Annual_kWhs_Rollup__c,
                (SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Annual_kwh_subscription_future__c,
                    Opportunity__r.Product__r.Customer_Subscription_Type__c
                FROM Utility_Account_Subscriptions__r
                ORDER BY UAS_Number__c DESC)
           FROM Utility_Account_Log__c
           WHERE Id = :ualId Limit 1
        ];
        this.ual = ual;
        if (ual.Utility_Account_Subscriptions__r[0].Opportunity__r.Product__r != null
            && ual.Utility_Account_Subscriptions__r[0].Opportunity__r.Product__r.Customer_Subscription_Type__c != null) {
            sizeBy = ual.Utility_Account_Subscriptions__r[0].Opportunity__r.Product__r.Customer_Subscription_Type__c;
        } else {
            throw new Util.BWException('There is no customer subcription type for this Subscription. Subscriptions cannot be sized with this tool');
        }
        checkSubscriptionType(ual.Utility_Account_Subscriptions__r);

        ualCostOfElectricity = ual.Annual_Cost_of_Electricity__c;
        if (ual.Proposed_kWh__c == null) {
            ualkWhOfElectricity = ual.Annual_kWh__c;
        } else {
            ualkWhOfElectricity = ual.Proposed_kWh__c;
        }

        this.subscribedCostOfElectricity = 0;
        this.subscribedkWhOfElectricity = 0;
        for (Utility_Account_Subscription__c uas : ual.Utility_Account_Subscriptions__r) {
            if (sizeBy == 'Electricity Cost ($)') {
                subscribedCostOfElectricity += uas.Subscribed_Annual_Cost_of_Electricity__c;
            } else if (sizeBy == 'kWh') {
                subscribedkWhOfElectricity += uas.Annual_kwh_subscription_future__c;            }
        }
        if (sizeBy == 'Electricity Cost ($)') {
            adjustmentAmount = ualCostOfElectricity - subscribedCostOfElectricity;
        } else if (sizeBy == 'kWh') {
            adjustmentAmount = ualkWhOfElectricity - subscribedkWhOfElectricity;
        }

        // Query Utility Account Subscription Lists
        getSubscriptionLists(true);
    }

    public PageReference updateCustomDeductionOrder() {
        List<Utility_Account_Subscription__c> customDeductionUASList = new List<Utility_Account_Subscription__c>();
        for (UASAction uasAction : uasActionList) {
            if (uasAction.uas.Id == uasId) {
                Utility_Account_Subscription__c uas = 
                    new Utility_Account_Subscription__c(Id = uasAction.uas.Id,
                                                        Custom_Deduction_Order__c = uasAction.uas.Custom_Deduction_Order__c);
                customDeductionUASList.add(uas);
            }
        }
        update customDeductionUASList;
        // Re-query subscriptions to reorder lists using the Custom Deduction Order
        getSubscriptionLists(false);
        return null;
    }

    // defaultSortOrder is:
    // 1. Open/Closed (Open first)
    // 2. Subscription Size (Smallest First)
    // 3. COD Date (Blanks and farthest away first)
    // 5. System Capacity Available (Largest Capacity Available First)
    // If system is Closed, Order By Subscription size (Smallest First), then randomize for equal subscriptions.
    // 
    // If not sorting by the default sort order, sort by Custom Deduction Order

    private List<Utility_Account_Subscription__c> getUASList(boolean defaultSortOrder){
        String query = 
            'SELECT Id, Name, ' +
            'Subscribed_Annual_Cost_of_Electricity__c, Annual_kwh_subscription_future__c,' +
            'Custom_Deduction_Order__c, Maximum_Annual_kWh__c,' +
            'Opportunity__c, ' +
            'Opportunity__r.Project_Assignment__c, ' +
            'Opportunity__r.stageName, ' +
            'Opportunity__r.Service_Territory__c, ' +
            'Opportunity__r.UtilityMapper__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Assignment_Order__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Id, ' +
            'Opportunity__r.Shared_Solar_System__r.Name, ' +
            'Opportunity__r.Shared_Solar_System__r.Open__c, ' +
            'Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Capacity_Available_to_be_Reserved__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Estimated_COD_Date_QC__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Maximum_Subscription_Cost__c, ' +
            'Opportunity__r.Shared_Solar_System__r.NMC_Value__c, ' +
            'Opportunity__r.Shared_Solar_System__r.Expected_Yield_kWh_kW__c ' +
            'FROM Utility_Account_Subscription__c ' +
            'WHERE Utility_Account_Log__c =: ualId ';
        if (defaultSortOrder) {
            query += 
                'ORDER BY Opportunity__r.Shared_Solar_System__r.Open__c DESC, ' +
                'Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c ASC, ' +
                'Subscribed_Annual_Cost_of_Electricity__c ASC, ' +
                'Opportunity__r.Shared_Solar_System__r.Estimated_COD_Date_QC__c DESC NULLS LAST,' +
                'Opportunity__r.Shared_Solar_System__r.Capacity_Available_to_be_Reserved__c DESC ';
        } else {
            query += 
                'ORDER BY Custom_Deduction_Order__c ASC NULLS LAST';
        }

        return Database.query(query);
    }

    public PageReference getSubscriptionLists(boolean defaultSortOrder) {
        uasActionList = new List<UASAction>();
        Decimal amountToAdjust = adjustmentAmount;
        Integer deductionOrder = 1;

        List<Utility_Account_Subscription__c> uasList = getUASList(defaultSortOrder);

        for (Utility_Account_Subscription__c uas : uasList) {
            Decimal subscriptionAdjustment = 0;

            if(amountToAdjust < 0) {
                if (sizeBy == 'Electricity Cost ($)') {
                    subscriptionAdjustment = -1 * Math.min(Math.abs(amountToAdjust), uas.Subscribed_Annual_Cost_of_Electricity__c);
                } else if (sizeBy == 'kWh') {
                    subscriptionAdjustment = -1 * Math.min(Math.abs(amountToAdjust), uas.Annual_kwh_subscription_future__c);
                }
            } else if (amountToAdjust > 0) {
                if (sizeBy == 'Electricity Cost ($)') {
                    Decimal spaceToMaximum = uas.Opportunity__r.Shared_Solar_System__r.Maximum_Subscription_Cost__c - uas.Subscribed_Annual_Cost_of_Electricity__c;
                    Decimal availableCapacity = calculateAvailableCostCapacity(uas.Opportunity__r.Shared_Solar_System__r);
                    List<Decimal> possibleIncreases = new List<Decimal>{amountToAdjust, spaceToMaximum, availableCapacity};
                    subscriptionAdjustment = Util.min(possibleIncreases);
                } else if (sizeBy == 'kWh') {
                    Decimal spaceToMaximum = uas.Maximum_Annual_kWh__c - uas.Annual_kwh_subscription_future__c;
                    Decimal availableCapacity = calculateAvailablekWhCapacity(uas.Opportunity__r.Shared_Solar_System__r);
                    List<Decimal> possibleIncreases = new List<Decimal>{amountToAdjust, spaceToMaximum, availableCapacity};
                    subscriptionAdjustment = Util.min(possibleIncreases);
                }
            }

            if (defaultSortOrder) {
                uas.Custom_Deduction_Order__c = deductionOrder;
                deductionOrder++;
            }
            UASAction act = new UASAction(uas, subscriptionAdjustment);
            if (uas.Opportunity__r.Shared_Solar_System__r.Open__c &&
                !uas.Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c) {
                act.action = 'Auto deduct';
            }
            uasActionList.add(act);
            amountToAdjust -= subscriptionAdjustment;
        }

        return null;
    }

    public Decimal calculateAvailablekWhCapacity(Shared_Solar_System__c sss) {
        Decimal availableCapacity = sss.Capacity_Available_to_be_Reserved__c;
        availableCapacity *= sss.Expected_Yield_kWh_kW__c;
        return availableCapacity;
    }

    public Decimal calculateAvailableCostCapacity(Shared_Solar_System__c sss) {
        Decimal availableCapacity = sss.Capacity_Available_to_be_Reserved__c;
        availableCapacity *= sss.NMC_Value__c;
        availableCapacity *= sss.Expected_Yield_kWh_kW__c;
        return availableCapacity;
    }

    public PageReference processDeduction(){
        Decimal remainingBalance = adjustmentAmount;
        List<Utility_Account_Subscription__c> uasToUpdate = new List<Utility_Account_Subscription__c>();

        Map<Id, Shared_Solar_System__c> sssToUpdate = new Map<Id, Shared_Solar_System__c>();
        System.debug(uasActionList);
        for(UASAction uasAction : uasActionList){
            if (uasAction.sss.Open__c && isNonAdminAction(uasAction.action)) {
                if (sizeBy == 'Electricity Cost ($)') {
                    uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c += uasAction.adjustmentAmount;
                } else if (sizeBy == 'kWh') {
                    uasAction.uas.Annual_kwh_subscription_future__c += uasAction.adjustmentAmount;
                }
                remainingBalance += uasAction.adjustmentAmount;

                if (uasAction.action == 'Deduct and mark as Closed') {
                    uasAction.sss.Open__c = false;
                    sssToUpdate.put(uasAction.sss.Id, uasAction.sss);
                }
                uasToUpdate.add(uasAction.uas);
            } else if (adminMode && isAdminAction(uasAction.action)) {
                if (sizeBy == 'Electricity Cost ($)') {
                    uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c += uasAction.adjustmentAmount;
                } else if (sizeBy == 'kWh') {
                    uasAction.uas.Annual_kwh_subscription_future__c += uasAction.adjustmentAmount;
                }
                uasToUpdate.add(uasAction.uas);
                if (uasAction.action == 'Deduct and mark as Open') {
                    uasAction.sss.Open__c = true;
                    sssToUpdate.put(uasAction.sss.Id, uasAction.sss);
                }
            }
        }

        //Check if there is a difference on the cost not yet allocated
        if(remainingBalance != ual.Cost_not_yet_Allocated__c && sizeBy == 'Electricity Cost ($)') {
            ual.Cost_not_yet_Allocated__c = remainingBalance;
            update ual;
        }

        for (Utility_Account_Subscription__c uas : uasToUpdate) {
            System.debug('processDeduction: ' + uas);
        }
        if (uasToUpdate.size() > 0) update uasToUpdate;
        if (sssToUpdate.size() > 0) update sssToUpdate.values();

        return new PageReference('/' + ualId);
    }

    public Boolean isNonAdminAction(String action) {
        Set<String> nonAdminActions = new Set<String>{
            'Auto deduct',
            'Deduct and mark as Closed'
        };
        return nonAdminActions.contains(action);
    }

    public Boolean isAdminAction(String action) {
        Set<String> adminActions = new Set<String>{
            'Deduct and mark as Open',
            'Deduct and keep as Closed',
            'Deduct from Schedule Z Filed'
        };
        return adminActions.contains(action);
    }

    public class UASAction {
        public Utility_Account_Subscription__c uas {get; set;}
        public Shared_Solar_System__c sss {get; set;}
        public Decimal adjustmentAmount {get; set;}
        public String action {get; set;}
        public UASAction(Utility_Account_Subscription__c uas, Decimal adjustmentAmount){
            this.uas = uas;
            this.sss = uas.Opportunity__r.Shared_Solar_System__r;
            this.adjustmentAmount = adjustmentAmount;
        }
    }

    public void checkSubscriptionType(List<Utility_Account_Subscription__c> uasesToCheck) {
        Boolean hasDifferentSizing = false;
        for (Utility_Account_Subscription__c uas : uasesToCheck) {
            if (uas.Opportunity__r.Product__r.Customer_Subscription_Type__c != sizeBy) {
                hasDifferentSizing = true;
            }
        }
        if (hasDifferentSizing) {
            throw new Util.BWException('Not all subscriptions have the same sizing method. Please review Opportunities and their Products');
        }
    }
/*
Confirmation: "Are you sure you want to recalculate this Utility Account Log?"

//Consider other Utility Account Subscriptions to make sure its not exceeding the 25kwh limit when adding a new UAS.
//There was an increase in the value
//if(totalSubscribedCost < ualCostOfElectricity){
//    //Check to see if there are frozen opportunities
//    //Modify the non-frozen (Open and not scheduled Z filed) ones to add more to the cost assigned to them

//    //Check if there are remaining cost to be assigned and then create a new opportunity if needed (clone the opportunity with all of the fields in it - We will need to implement a very deep clone to clone all fields not just the ones that we query)
//    //http://www.oyecode.com/2012/08/utility-class-how-to-get-all-fields-for.html
//    //If there is a need to add an opportunity - Use the SSS search feature similar to the lead Trigger handler
//    //Add more opportunities and utility account subscription as necessary:

//}

//Clarification:
// - In the case where we added a new opportunity, do we also need to add UAS records to the other Utility Account Logs??

*/
}