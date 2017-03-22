({
getProgressBarData : function(component, event, helper) {     

		//retrieve the loan Id to set the record for the component to display.        
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");
                                 
        //progress bar status - removes/adds classes based on returned value of last completed task.       
        var progressBarData = component.get("c.getProgressBarData");	      
        progressBarData.setParams({loanId : loanUpdateIdVar})
        progressBarData.setCallback(this,function(resp){            
            var creditToggle = component.find("credit");
            var systemInfoToggle = component.find("systemInfo");
            var reviewToggle = component.find("bwReview");
            var contractToggle = component.find("contract");
            var mechInstallToggle = component.find("mechInstall");            
            var progressBarToggle = component.find("progressBar");
            var interconnectionToggle = component.find("interconnection");            
            var completeToggle = component.find("complete");       
            
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue() == 'Run Credit Check'){
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active ');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit');                     
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthSystemInfo'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                                         
                }else if(resp.getReturnValue() == 'Provide All Customer Information'){
                    component.set("v.blueWaveReviewAlert", false);                	
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.addClass(progressBarToggle, 'progressBarWidthSystemInfo'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                     
                }else if(resp.getReturnValue() == 'Under BlueWave Review'){
                    component.set("v.blueWaveReviewAlert", true);
                	$A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                                         
                }else if(resp.getReturnValue() == 'Obtain Contract Signature'){
                    component.set("v.blueWaveReviewAlert", false);                  
                	$A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');                    
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                     
                }else if(resp.getReturnValue() == 'Mechanical Installation'){
                    component.set("v.blueWaveReviewAlert", false);                  
                	$A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');                    
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.addClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                     
                }else if(resp.getReturnValue() == 'Interconnection'){
                    component.set("v.blueWaveReviewAlert", false);                  
                	$A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
					$A.util.addClass(reviewToggle, 'slds-is-active');                                        
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(mechInstallToggle, 'slds-is-active');
                    $A.util.addClass(interconnectionToggle, 'slds-is-active');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                     
                }else{
                    component.set("v.blueWaveReviewAlert", false);                  
                	$A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                	$A.util.addClass(reviewToggle, 'slds-is-active');
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(mechInstallToggle, 'slds-is-active');
                    $A.util.addClass(interconnectionToggle, 'slds-is-active'); 
                    $A.util.addClass(completeToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                	$A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                                         
                }
            }
            else {
                $A.log("Errors", resp.getError());
                    component.set("v.blueWaveReviewAlert", false);                  
                	$A.util.removeClass(creditToggle, 'slds-is-active');
                    $A.util.removeClass(systemInfoToggle, 'slds-is-active');
                	$A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(mechInstallToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.addClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                	$A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstallMSLP');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');                     
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

getProgressBarDataMSLP : function(component, event, helper) {     

        //retrieve the loan Id to set the record for the component to display.        
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");
                                 
        //progress bar status - removes/adds classes based on returned value of last completed task.       
        var progressBarData = component.get("c.getProgressBarData");          
        progressBarData.setParams({loanId : loanUpdateIdVar})
        progressBarData.setCallback(this,function(resp){            
            var creditToggle = component.find("credit");
            var systemInfoToggle = component.find("systemInfo");
            var reviewToggle = component.find("bwReview");
            var contractToggle = component.find("contract");
            var progressBarToggle = component.find("progressBar");
            var interconnectionToggle = component.find("interconnection");            
            var completeToggle = component.find("complete");       
            
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue() == 'Run Credit Check'){
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active ');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(completeToggle, 'slds-is-active');                      
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP');                     
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                       
                     
                }else if(resp.getReturnValue() == 'Provide All Customer Information'){
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(completeToggle, 'slds-is-active');                      
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.addClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                       
 
                }else if(resp.getReturnValue() == 'Under BlueWave Review'){
                    component.set("v.blueWaveReviewAlert", true);
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(completeToggle, 'slds-is-active');                      
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                       
                     
                }else if(resp.getReturnValue() == 'Obtain Contract Signature'){
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');                    
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(completeToggle, 'slds-is-active');                      
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                       
 
                }else if(resp.getReturnValue() == 'Report Interconnection to MCEC'){
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');                                        
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(interconnectionToggle, 'slds-is-active');
                    $A.util.removeClass(completeToggle, 'slds-is-active');                      
                    $A.util.removeClass(completeToggle, 'slds-is-active');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.addClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                       
 
                }else{
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.addClass(creditToggle, 'slds-is-active');
                    $A.util.addClass(systemInfoToggle, 'slds-is-active');
                    $A.util.addClass(reviewToggle, 'slds-is-active');
                    $A.util.addClass(contractToggle, 'slds-is-active');
                    $A.util.addClass(interconnectionToggle, 'slds-is-active'); 
                    $A.util.addClass(completeToggle, 'slds-is-active');                    
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP');                                        
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.addClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');                                            
                }
            }
            else {
                $A.log("Errors", resp.getError());
                    component.set("v.blueWaveReviewAlert", false);                  
                    $A.util.removeClass(creditToggle, 'slds-is-active');
                    $A.util.removeClass(systemInfoToggle, 'slds-is-active');
                    $A.util.removeClass(reviewToggle, 'slds-is-active');
                    $A.util.removeClass(contractToggle, 'slds-is-active');
                    $A.util.removeClass(interconnectionToggle, 'slds-is-active');                    
                    $A.util.addClass(progressBarToggle, 'progressBarWidthCreditMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfoMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReviewMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContractMSLP'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnectionMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCompleteMSLP');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthCredit'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthSystemInfo');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthReview');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthContract'); 
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthMechanicalInstall');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthInterconnection');
                    $A.util.removeClass(progressBarToggle, 'progressBarWidthComplete');
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
})