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
                if (progressBarPendingTaskName == null) {
                    var completedLoan = true;
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
                if (completedLoan) {
                    $A.util.addClass(progressBarToggle, 'CompleteProgressBar');                                                                          
                } else {
                    $A.util.addClass(progressBarToggle, progressBarPendingTaskName);                                                                          
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
