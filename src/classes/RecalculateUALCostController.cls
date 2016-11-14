public with sharing class RecalculateUALCostController {
    
    public String ualId {get; set;}
    public String uasId {get; set;}
    public String deductionMethod {get; set;}
    
    public Utility_Account_Log__c ual {get; set;}

    public Decimal ualCostOfElectricity {get; set;}
    public Decimal subscribedCostOfElectricity {get; set;}
    public Decimal adjustmentAmount {get; set;}

    public List<UASAction> openUASActionList;
    public List<UASAction> closedUASActionList {get; set;}
    public List<UASAction> scheduleZFiledUASActionList {get; set;}

    public Boolean adminMode {get; set;}
    public String selectedOrder {get; set;}


    /*
        https://c.cs2.visual.force.com/apex/RecalculateUALCost?id=a1bR0000004t8F3&adminMode=1
    */

    //Go through each UAS and check the following:
    //Check the Open == true Schedule_Z_Filed__c = false records if we are able to deduct the difference then allow the user to process it.
    //If there are still remaining balance:
        //Check the Open == false Schedule_Z_Filed__c = false records if we are able to deduct the difference then allow the user to process it but with the option of asking the user:
        //- Deduct and mark as Open
        //- Deduct and keep as Closed
    
    //If there are still remaining balance:
        //Check the Open == false Schedule_Z_Filed__c = true records if we are able to deduct the difference then allow the user to process it but with the option of asking the user:


    //Shared Solar System Name, Open, Scheduled Z Filed,Available Capacity, COD Date,Customer Group,Customer Ratio, Amount to be deducted, Action

    //if (all records already have Schedule_Z_Filed__c == true){
    //    //If the user does not have "System Administrator" Profile
    //    //Error message: "Please contact one of Bluewave's Administrator to make this change as all systems have had a Schedule Z filed."

    //    //For the System Administrator profile:
    //    // Allow the user to continue processing even if the Schedule_Z_Filed__c = true
    //}

    //Give the option of not deducting it for open systems
    //Picklist options: 
        //- Deduct and mark as Open
        //- Deduct and keep as Closed
        //-  Potential scenario on possibly not deducting it

        //If Schedule_Z_Filed__c == true
        //    - Checkbox to mark (Confirm deduction to Schedule Z Filed System)


    public RecalculateUALCostController(){
        //Get id from the URL parameters
        this.ualId = ApexPages.currentPage().getParameters().get('id');


        //Uncomment this once we are in production. 
        Profile userProfile = [Select Name from Profile where Id = :UserInfo.getProfileid()];
        if(userProfile.Name == 'System Administrator'){
            adminMode = true;
        }

        //Sample override during testing:
        if(ApexPages.currentPage().getParameters().get('adminMode') == '0'){
            this.adminMode = false;
        }

        //Set default values
        deductionMethod = 'Assignment Order'; 
        openUASActionList = new List<UASAction>();
        closedUASActionList = new List<UASAction>();
        scheduleZFiledUASActionList = new List<UASAction>();

        //Query data and check the total Annual Cost of Electricity
        for(Utility_Account_Log__c ual : [Select Id, Name, Annual_Cost_of_Electricity__c, Cost_not_yet_Allocated__c,
                                                    (Select Id, Subscribed_Annual_Cost_of_Electricity__c
                                                     From Utility_Account_Subscriptions__r
                                                     Order By UAS_Number__c DESC)
                                              From Utility_Account_Log__c
                                              Where Id = :ualId Limit 1]){
            this.ual = ual;
            ualCostOfElectricity = ual.Annual_Cost_of_Electricity__c;
        }
         
        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Initial UAL Data:' + ual));

        this.subscribedCostOfElectricity = 0;
        for(Utility_Account_Subscription__c uas : ual.Utility_Account_Subscriptions__r){
            if(uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                subscribedCostOfElectricity += uas.Subscribed_Annual_Cost_of_Electricity__c;
                //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Adding ' + uas));
            }
        }
        adjustmentAmount = ualCostOfElectricity - subscribedCostOfElectricity;

        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'adjustmentAmount ' + adjustmentAmount));
        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'subscribedCostOfElectricity ' + subscribedCostOfElectricity));
        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'ualCostOfElectricity ' + ualCostOfElectricity));

    }

    // Handles the case where the list is reordered
    public List<UASAction> getOpenUASActionList() {
      if (openUASActionList != null) {
        openUASActionList.sort();
        return (openUASActionList);
      } else {
        return (null);
      }
    }

    public void setOpenUASActionList(List<UASAction> uasAction) {
      openUASActionList = uasAction;
    }

    public PageReference customDeductionOrder(){
        System.debug(selectedOrder);
        List<Utility_Account_Subscription__c> customDeductionUASList = new List<Utility_Account_Subscription__c>();
        for (UASAction uasAction : openUASActionList) {
          if (uasAction.uas.Id == uasId) {
            Utility_Account_Subscription__c uas = 
              new Utility_Account_Subscription__c(Id = uasAction.uas.Id,
                                                  Custom_Deduction_Order__c = uasAction.uas.Custom_Deduction_Order__c);
            customDeductionUASList.add(uas);
          }
        }
        update customDeductionUASList;
        return null;
    }

    private List<Utility_Account_Subscription__c> getUASList(Boolean open, Boolean scheduleZFiled){
        String query =      'Select Id, Name, Calculated_Annual_Cost_of_Electricity__c, '+
                            '           Subscribed_Annual_Cost_of_Electricity__c, '+
                            '           Custom_Deduction_Order__c, '+
                            '           Opportunity__c, '+
                            '           Opportunity__r.Project_Assignment__c, '+
                            '           Opportunity__r.stageName, '+                            
                            '           Opportunity__r.Service_Territory__c, '+
                            '           Opportunity__r.UtilityMapper__c, '+
                            '           Opportunity__r.Shared_Solar_System__r.Assignment_Order__c, '+                
                            '           Opportunity__r.Shared_Solar_System__r.Id, '+
                            '           Opportunity__r.Shared_Solar_System__r.Name, '+
                            '           Opportunity__r.Shared_Solar_System__r.Open__c, '+
                            '           Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c, '+
                            '           Opportunity__r.Shared_Solar_System__r.Capacity_Available_to_be_Reserved__c, '+
                            '           Opportunity__r.Shared_Solar_System__r.Estimated_COD_Date_QC__c '+
                            ' From Utility_Account_Subscription__c ';
        query += 'Where Opportunity__r.Shared_Solar_System__r.Open__c = :open ';
        query += 'AND Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c = :scheduleZFiled ';
        query += 'AND Utility_Account_Log__c = :ualId ';
        if(deductionMethod == 'Assignment Order'){
            query += 'Order By Opportunity__r.Shared_Solar_System__r.Assignment_Order__c DESC ';
        }else if(deductionMethod == 'COD Date'){
            query += 'Order By Opportunity__r.Shared_Solar_System__r.Estimated_COD_Date_QC__c DESC ';
        }
        else if(deductionMethod == 'Custom Deduction Order'){
            query += 'Order By Custom_Deduction_Order__c ASC ';
        }
        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Querying: ' + query));
        return Database.query(query);
    }

    public PageReference setDeductionMethod(){

        openUASActionList = new List<UASAction>();
        closedUASActionList = new List<UASAction>();
        scheduleZFiledUASActionList = new List<UASAction>();
        
        System.debug('ualid: ' + ualId);
        System.debug('getuaslist size: ' + getUASList(true, false).size());
        
        Decimal amountToDeduct = Math.abs(adjustmentAmount);
        
        //Deduct from Open and Non-Schedule Z
        if(amountToDeduct > 0){
            //Check the Open == true Schedule_Z_Filed__c = false records if we are able to deduct the difference then allow the user to process it.
            for(Utility_Account_Subscription__c uas : getUASList(true, false)){
                System.debug('open and non-szed uas: ' + uas.Subscribed_Annual_Cost_of_Electricity__c);
                if(amountToDeduct > 0 && uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                    Decimal deductionAmount =  Math.min(amountToDeduct, uas.Subscribed_Annual_Cost_of_Electricity__c);
                    UASAction act = new UASAction(uas, deductionAmount);
                    act.action = 'Auto deduct';
                    openUASActionList.add(act);
                    amountToDeduct -= deductionAmount;
                    //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Deducting from Open : ' + uas));
                }
            }
        }

        //Check if there are any remaining balance to deduct from Closed and non-schedule Z
        if(amountToDeduct > 0){
            //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Querying Closed ' + getUASList(false, false)));
            for(Utility_Account_Subscription__c uas : getUASList(false, false)){
                if(amountToDeduct > 0 && uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                    Decimal deductionAmount =  Math.min(amountToDeduct, uas.Subscribed_Annual_Cost_of_Electricity__c);
                    closedUASActionList.add(new UASAction(uas, deductionAmount));
                    amountToDeduct -= deductionAmount;
                    //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Deducting from Closed : ' + uas));
                }
            }
        }

        //Deduct from Schedule Z records
        if(amountToDeduct > 0){
            //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Querying Schedule Z ' + getUASList(false, true)));
            for(Utility_Account_Subscription__c uas : getUASList(false, true)){
                if(amountToDeduct > 0 && uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                    Decimal deductionAmount =  Math.min(amountToDeduct, uas.Subscribed_Annual_Cost_of_Electricity__c);
                    scheduleZFiledUASActionList.add(new UASAction(uas, deductionAmount));
                    amountToDeduct -= deductionAmount;
                    //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Deducting from Schedule Z : ' + uas));
                }
            }
        }
        return null;
    }

    public PageReference processDeduction(){
        Decimal remainingBalance = Math.abs(adjustmentAmount);
        List<Utility_Account_Subscription__c> uasToUpdate = new List<Utility_Account_Subscription__c>();

        List<Shared_Solar_System__c> sssListToUpdate = new List<Shared_Solar_System__c>();
        
        //Process open
        if(openUASActionList.size() > 0){
            for(UASAction uasAction : openUASActionList){
                if(uasAction.deductionAmount > 0 && uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c > 0){
                    uasAction.uas.Calculated_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                    uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                    remainingBalance -= uasAction.deductionAmount;
                    uasToUpdate.add(uasAction.uas);
                }
            }
        }
        if(adminMode){//this only needs to be for the scheduleZFiledUASActionList.
            if(closedUASActionList.size() > 0){
                for(UASAction uasAction : closedUASActionList){
                    if(uasAction.deductionAmount > 0 && uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c > 0 
                        && (uasAction.action == 'Deduct and mark as Open' || uasAction.action == 'Deduct and mark as Closed')){
                        uasAction.uas.Calculated_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        remainingBalance -= uasAction.deductionAmount;

                        if(uasAction.action == 'Deduct and mark as Open'){
                            uasAction.sss.Open__c = true;
                            sssListToUpdate.add(uasAction.sss);
                        }
                        uasToUpdate.add(uasAction.uas);
                    }
                }
            }
            if(scheduleZFiledUASActionList.size() > 0){
                for(UASAction uasAction : scheduleZFiledUASActionList){
                    if(uasAction.deductionAmount > 0 && uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c > 0 
                        && uasAction.action == 'Deduct from Schedule Z Filed'){
                        uasAction.sss.Open__c = true;
                        uasAction.uas.Calculated_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c -= uasAction.deductionAmount;
                        remainingBalance -= uasAction.deductionAmount;
                        uasToUpdate.add(uasAction.uas);
                    }
                }
            }
        }

        //Check if there is a difference on the cost not yet allocated
        if(remainingBalance != ual.Cost_not_yet_Allocated__c){
            ual.Cost_not_yet_Allocated__c = remainingBalance;
            update ual;
        }

        if(uasToUpdate.size() > 0) update uasToUpdate;
        if(sssListToUpdate.size() > 0) update sssListToUpdate;

        //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'Adjustment implemented successfully.'));
        return new PageReference('/' + ualId);
    }

    public class UASAction implements Comparable {
        public Utility_Account_Subscription__c uas{get; set;}
        public Shared_Solar_System__c sss{get; set;}
        public Decimal deductionAmount {get; set;}
        public String action {get; set;}
        public UASAction(Utility_Account_Subscription__c uas, Decimal deductionAmount){
            this.uas = uas;
            this.sss = uas.Opportunity__r.Shared_Solar_System__r;
            this.deductionAmount = deductionAmount;
        }
        public Integer compareTo(Object compareTo) {
          UASAction compareToUASA = (UASAction) compareTo;
          if (compareToUASA.uas.Id == uas.Id) {
            return 0;
          } else if (compareToUASA.uas.Custom_Deduction_Order__c < uas.Custom_Deduction_Order__c) {
            return 1;
          } else {
            return -1;
          }
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