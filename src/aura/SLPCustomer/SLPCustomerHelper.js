({
    getProgressBarDataMethod : function(component, event, helper) {     
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");                                
        var progressBarData = component.get("c.getProgressBarData");       
        var progressBarToggle = component.find("progressBar");    
        var i;   
        var j;    
        progressBarData.setParams({loanId : loanUpdateIdVar})
        progressBarData.setCallback(this,function(resp){                        
            if(resp.getState() == 'SUCCESS') {
                var progressBarPendingTaskName = resp.getReturnValue().pendingTaskName;
                var progressBarCompletedTasks = []; 
                var progressBarIncompleteTasks = [];                
                for (i = 0; i < resp.getReturnValue().completedTasks.length; i++) {
                    progressBarCompletedTasks.push(resp.getReturnValue().completedTasks[i]);
                }
                for (i = 0; i < resp.getReturnValue().incompleteTasks.length; i++) {
                    progressBarIncompleteTasks.push(resp.getReturnValue().incompleteTasks[j]);
                }                          
                if (resp.getReturnValue().pendingTaskName == 'Under BlueWave Review') {
                    component.set("v.blueWaveReviewAlert", true);                                                            
                } else {
                    component.set("v.blueWaveReviewAlert", false);                                                                                    
                }
                if (resp.getReturnValue().program == 'MSLP') {
                    progressBarPendingTaskName = progressBarPendingTaskName + 'ProgressBarMSLP';                    
                } else {
                   progressBarPendingTaskName = progressBarPendingTaskName + 'ProgressBar';                    
                }               
                
                progressBarPendingTaskName = progressBarPendingTaskName.replace(/\s+/g, ''); 

                $A.util.removeClass(progressBarToggle);
                $A.util.addClass(progressBarToggle, 'slds-wizard__progress-bar');                       
                $A.util.addClass(progressBarToggle, progressBarPendingTaskName); 

                for (i = 0; i < progressBarCompletedTasks.length; i++) {
                    $A.util.addClass(component.find(progressBarCompletedTasks[i]), 'slds-is-active');
                }
                for (i = 0; i < progressBarIncompleteTasks.length; i++) {
                    $A.util.removeClass(component.find(progressBarIncompleteTasks[i]), 'slds-is-active');
                }                                                       
            }
        });
        $A.enqueueAction(progressBarData);  
        
        var partnerTaskList = component.get("c.getLoanCustomerTasks");  
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : loanUpdateIdVar});       
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
    
    startSpinner : function(component, name) {
        var spinner = component.find(name);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },
    stopSpinner : function(component, spinnerName) {
        var spinner = component.find(spinnerName);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    },
})

                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(interconnectionToggle, 'slds-is-active'); 
                    $A.util.addClass(completeToggle, 'slds-is-active');    