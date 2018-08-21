public without sharing class RecalculateUALCostController {
    
    public String ualId {get; set;}
    public String uasId {get; set;}
    
    public Utility_Account_Log__c ual {get; set;}

    public Decimal ualCostOfElectricity {get; set;}
    public Decimal subscribedCostOfElectricity {get; set;}
    public Decimal adjustmentAmount {get; set;}

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
        //Get id from the URL parameters
        this.ualId = ApexPages.currentPage().getParameters().get('id');

        //Uncomment this once we are in production. 
        adminMode = false;
        Profile userProfile = [Select Name from Profile where Id = :UserInfo.getProfileid()];
        if(userProfile.Name == 'System Administrator'){
            adminMode = true;
        }

        //Query data and check the total Annual Cost of Electricity
        for (Utility_Account_Log__c ual : [SELECT Id, Name, Annual_Cost_of_Electricity__c, Cost_not_yet_Allocated__c,
                                           (SELECT Id, Subscribed_Annual_Cost_of_Electricity__c
                                            FROM Utility_Account_Subscriptions__r
                                            ORDER BY UAS_Number__c DESC)
                                           FROM Utility_Account_Log__c
                                           WHERE Id = :ualId Limit 1]) {
            this.ual = ual;
            ualCostOfElectricity = ual.Annual_Cost_of_Electricity__c;
        }
         
        this.subscribedCostOfElectricity = 0;
        for (Utility_Account_Subscription__c uas : ual.Utility_Account_Subscriptions__r) {
            if (uas.Subscribed_Annual_Cost_of_Electricity__c > 0) {
                subscribedCostOfElectricity += uas.Subscribed_Annual_Cost_of_Electricity__c;
            }
        }
        adjustmentAmount = ualCostOfElectricity - subscribedCostOfElectricity;

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
            'Subscribed_Annual_Cost_of_Electricity__c, ' +
            'Custom_Deduction_Order__c, ' +
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
            'Opportunity__r.Shared_Solar_System__r.Estimated_COD_Date_QC__c ' +
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
        Decimal amountToDeduct = Math.abs(adjustmentAmount);
        Integer deductionOrder = 1;

        if(amountToDeduct > 0){
            for(Utility_Account_Subscription__c uas : getUASList(defaultSortOrder)){
                Decimal deductionAmount =  Math.min(amountToDeduct, uas.Subscribed_Annual_Cost_of_Electricity__c);
                if (defaultSortOrder) {
                    uas.Custom_Deduction_Order__c = deductionOrder;
                    deductionOrder++;
                }
                UASAction act = new UASAction(uas, deductionAmount);
                if (uas.Opportunity__r.Shared_Solar_System__r.Open__c &&
                    !uas.Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c) {
                    act.action = 'Auto deduct';
                }
                uasActionList.add(act);
                amountToDeduct -= deductionAmount;
            }
        }
        return null;
    }

    public PageReference processDeduction(){
        Decimal remainingBalance = Math.abs(adjustmentAmount);
        List<Utility_Account_Subscription__c> uasToUpdate = new List<Utility_Account_Subscription__c>();

        Map<Id, Shared_Solar_System__c> sssToUpdate = new Map<Id, Shared_Solar_System__c>();
        
        if(uasActionList.size() > 0){
            for(UASAction uasAction : uasActionList){
                if (uasAction.sss.Open__c &&
                    uasAction.action == 'Auto deduct' ||
                    uasAction.action == 'Deduct and mark as Closed') {
                    if(uasAction.deductionAmount > 0 && uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                        uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        remainingBalance -= uasAction.deductionAmount;

                        if (uasAction.action == 'Deduct and mark as Closed') {
                            uasAction.sss.Open__c = false;
                            sssToUpdate.put(uasAction.sss.Id, uasAction.sss);
                        }
                        uasToUpdate.add(uasAction.uas);
                    }
                } else {
                    if (adminMode &&
                        uasAction.deductionAmount > 0 && 
                        uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c > 0 &&
                        (uasAction.action == 'Deduct and mark as Open' || 
                         uasAction.action == 'Deduct and keep as Closed' ||
                         uasAction.action == 'Deduct from Schedule Z Filed')) {
                        uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        remainingBalance -= uasAction.deductionAmount;
                        uasToUpdate.add(uasAction.uas);
                        if (uasAction.action == 'Deduct and mark as Open') {
                            uasAction.sss.Open__c = true;
                            sssToUpdate.put(uasAction.sss.Id, uasAction.sss);
                        }
                    }
                }
            }
        }

        //Check if there is a difference on the cost not yet allocated
        if(remainingBalance != ual.Cost_not_yet_Allocated__c) {
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

    public class UASAction {
        public Utility_Account_Subscription__c uas {get; set;}
        public Shared_Solar_System__c sss {get; set;}
        public Decimal deductionAmount {get; set;}
        public String action {get; set;}
        public UASAction(Utility_Account_Subscription__c uas, Decimal deductionAmount){
            this.uas = uas;
            this.sss = uas.Opportunity__r.Shared_Solar_System__r;
            this.deductionAmount = deductionAmount;
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