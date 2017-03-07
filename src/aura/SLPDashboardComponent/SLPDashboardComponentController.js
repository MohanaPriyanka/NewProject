({
	doInit : function(component, event, helper) {
        var partnerTaskList = component.get("c.getTasksByStage");        
        
        partnerTaskList.setParams({stageName : "All"});

        partnerTaskList.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(partnerTaskList);     
              
	},

    filterStageList : function(component, event, helper) {
		var label = event.getParam("stageName"); 
        var partnerTaskList = component.get("c.getTasksByStage");
        
        partnerTaskList.setParams({stageName : label});
        
        partnerTaskList.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(partnerTaskList);        
    },
        
    openCustomerWindow : function(component, event, helper) {          
        //hide the task table on the dashboard
        //var customerWindowToggle = component.get("v.eventToggle");
        var taskTable = component.find("taskTable");   
        $A.util.addClass(taskTable, 'noDisplayBar');
        
        //if(customerWindowToggle == true){
        //send the id of the selected customer to the customer component and bring it to display
        //hide the stageChart and disbursal widgets on the dashboard on 
        //the view click of customer record.
        var source = event.getSource();
        var customerLoanId = source.get("v.class");
        var evtCustomerWindow = $A.get("e.c:SLPDashboardEvent");
        evtCustomerWindow.setParams({"customerLoanId": customerLoanId});
        evtCustomerWindow.fire(); 
	    //}   
    }, 
    
    closeCustomerWindow : function(component, event, helper) {          
        //hide the task table on the dashboard
        var  eventHelper = event.getParam("attributeAssignmentHelper"); 
        component.set("v.eventToggle", eventHelper);
        
        var taskTable = component.find("taskTable");   
        $A.util.removeClass(taskTable, 'noDisplayBar');           
    },     
    
})