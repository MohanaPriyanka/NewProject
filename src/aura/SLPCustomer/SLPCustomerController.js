({
	doInit : function(component, event, helper) {
	    var closeButton = component.find("closeButton");   
        $A.util.addClass(closeButton, 'noDisplay');  

        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    if(resp.getReturnValue() == 'Executive')
                    component.set("v.licenseType", true);
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);                            
	},
    
    openCustomerWindow : function(component, event, helper) {
        //remove the noDisplayBar class from the Component - brining the page to display.
        var customerPage = component.find("customerPage");
        $A.util.removeClass(customerPage, 'noDisplayBar');        

		//retrieve the loan Id to set the record for the component to display.        
        var label = event.getParam("customerLoanId"); 
            
        //retrieve the customer's full information to display in the component
        var customerInformationAction = component.get("c.getCustomerInformation"); 
        customerInformationAction.setParams({loanId : label})
        customerInformationAction.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.customerInformation", resp.getReturnValue());
                component.set("v.customer", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });                
        $A.enqueueAction(customerInformationAction);
              
        
        //progress bar status - removes/adds classes based on returned value of last completed task.       
        var progressBarData = component.get("c.getProgressBarData");	      
        progressBarData.setParams({loanId : label})
        progressBarData.setCallback(this,function(resp){            
            var creditToggle = component.find("credit");
            var systemInfoToggle = component.find("systemInfo");
            var reviewToggle = component.find("bwReview");
            var contractToggle = component.find("contract");
            var mechInstallToggle = component.find("mechInstall");            
            var progressBarToggle = component.find("progressBar");
            var interconnectionToggle = component.find("interconnection");            
            var completeToggle = component.find("complete");       
            var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");        

            if(resp.getState() == 'SUCCESS') {                  
                helper.getProgressBarDataMethod(component, event, helper);
            }
            else {
                $A.log("Errors", resp.getError());
                alert("There was an issue loading the progress bar");
            }
        });
		$A.enqueueAction(progressBarData);  
        
        var partnerTaskList = component.get("c.getLoanCustomerTasks");  
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : label});       
        partnerTaskList.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(partnerTaskList);  
        
        var completeLoanDisbursals = component.get("c.getCompleteLoanDisbursals");        
        completeLoanDisbursals.setParams({loanId : label});        
		completeLoanDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.completeDisbursalList", resp.getReturnValue());                                         
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });   
        
        var incompleteLoanDisbursals = component.get("c.getIncompleteLoanDisbursals");        
        incompleteLoanDisbursals.setParams({loanId : label});        
		incompleteLoanDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.incompleteDisbursalList", resp.getReturnValue());                                         
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });         
        
        $A.enqueueAction(completeLoanDisbursals);       
                  
        $A.enqueueAction(incompleteLoanDisbursals);          
    },
    
	exitCustomerWindow : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    
	openTaskInformation : function(component, event, helper) {
        
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");        
        var taskTableToggle = component.find("taskTable");
        var customerInformationToggle1 = component.find("customerInformation1");
        var customerInformationToggle2 = component.find("customerInformation2");

        var disbursalCompleteTableToggle = component.find("disbursalCompleteTable");
        var disbursalIncompleteTableToggle = component.find("disbursalIncompleteTable");
        var pendingDisbursalsToggle = component.find("pendingDisbursals");
        var completedDisbursalsToggle = component.find("completeDisbursals");
        var mslpCustomerInfoTextToggle = component.find("cusomterInformationTextMSLP");

        $A.util.addClass(mslpCustomerInfoTextToggle, 'noDisplay');           
        $A.util.removeClass(taskTableToggle, 'noDisplay');
        $A.util.addClass(customerInformationToggle1, 'noDisplay');
        $A.util.addClass(customerInformationToggle2, 'noDisplay');

        $A.util.addClass(disbursalCompleteTableToggle, 'noDisplay');
        $A.util.addClass(disbursalIncompleteTableToggle, 'noDisplay');
        var subTaskHeaderToggle = component.find("subTaskHeader");           
        var subTaskTableToggle = component.find("subTaskTable");
        $A.util.addClass(subTaskTableToggle, 'noDisplay');
        $A.util.addClass(subTaskHeaderToggle, 'noDisplay');
        $A.util.addClass(pendingDisbursalsToggle, 'noDisplay');
        $A.util.addClass(completedDisbursalsToggle, 'noDisplay');         

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
        
        var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");        
        helper.getProgressBarDataMethod(component, event, helper);
                
	},  
    
	openCustomerInformation : function(component, event, helper) {
        var loanId = component.get("v.customerInformation.Loan__r.Id");
        var taskTableToggle = component.find("taskTable");
        var customerInformationToggle1 = component.find("customerInformation1");
        var customerInformationToggle2 = component.find("customerInformation2");
        var disbursalCompleteTableToggle = component.find("disbursalCompleteTable");
        var disbursalIncompleteTableToggle = component.find("disbursalIncompleteTable");
        var pendingDisbursalsToggle = component.find("pendingDisbursals");
        var completedDisbursalsToggle = component.find("completeDisbursals");
        var mslpCustomerInfoTextToggle = component.find("cusomterInformationTextMSLP");

        $A.util.removeClass(mslpCustomerInfoTextToggle, 'noDisplay');                         
        $A.util.addClass(taskTableToggle, 'noDisplay'); 
        $A.util.removeClass(customerInformationToggle1, 'noDisplay');
        $A.util.removeClass(customerInformationToggle2, 'noDisplay');
        $A.util.addClass(disbursalCompleteTableToggle, 'noDisplay');
        $A.util.addClass(disbursalIncompleteTableToggle, 'noDisplay');
        component.set("v.blueWaveReviewAlert", false);
        $A.util.addClass(pendingDisbursalsToggle, 'noDisplay');
        $A.util.addClass(completedDisbursalsToggle, 'noDisplay');         

        var subTaskHeaderToggle = component.find("subTaskHeader");           
        var subTaskTableToggle = component.find("subTaskTable");
        $A.util.addClass(subTaskTableToggle, 'noDisplay');
        $A.util.addClass(subTaskHeaderToggle, 'noDisplay');   

        var customerInformationAction = component.get("c.getCustomerInformation"); 
        customerInformationAction.setParams({loanId : loanId})
        customerInformationAction.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.customerInformation", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });                
        $A.enqueueAction(customerInformationAction);
        
        var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");        
        helper.getProgressBarDataMethod(component, event, helper);
	},      
    
	openDisbursalInformation : function(component, event, helper) {
        var loanId = component.get("v.customerInformation.Loan__r.Id");
        var taskTableToggle = component.find("taskTable");
        var customerInformationToggle1 = component.find("customerInformation1");
        var customerInformationToggle2 = component.find("customerInformation2");
        var disbursalCompleteTableToggle = component.find("disbursalCompleteTable");
        var disbursalIncompleteTableToggle = component.find("disbursalIncompleteTable");
        var pendingDisbursalsToggle = component.find("pendingDisbursals");
        var mslpCustomerInfoTextToggle = component.find("cusomterInformationTextMSLP");
        var completedDisbursalsToggle = component.find("completeDisbursals");

        component.set("v.blueWaveReviewAlert", false);

        $A.util.addClass(taskTableToggle, 'noDisplay');
        $A.util.addClass(customerInformationToggle1, 'noDisplay');
        $A.util.addClass(customerInformationToggle2, 'noDisplay');
        $A.util.addClass(mslpCustomerInfoTextToggle, 'noDisplay');        
        $A.util.removeClass(disbursalCompleteTableToggle, 'noDisplay');
        $A.util.removeClass(disbursalIncompleteTableToggle, 'noDisplay');
        $A.util.removeClass(pendingDisbursalsToggle, 'noDisplay');
        $A.util.removeClass(completedDisbursalsToggle, 'noDisplay');        
        

        var subTaskHeaderToggle = component.find("subTaskHeader");           
        var subTaskTableToggle = component.find("subTaskTable");
        $A.util.addClass(subTaskTableToggle, 'noDisplay');
        $A.util.addClass(subTaskHeaderToggle, 'noDisplay'); 
        
        var completeLoanDisbursals = component.get("c.getCompleteLoanDisbursals");        
        completeLoanDisbursals.setParams({loanId : loanId});        
		completeLoanDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.completeDisbursalList", resp.getReturnValue());                                         
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });   
        $A.enqueueAction(completeLoanDisbursals);  

        var incompleteLoanDisbursals = component.get("c.getIncompleteLoanDisbursals");        
        incompleteLoanDisbursals.setParams({loanId : loanId});        
		incompleteLoanDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.incompleteDisbursalList", resp.getReturnValue());                                         
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });                      
                  
        $A.enqueueAction(incompleteLoanDisbursals);    
        
        var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");        
        helper.getProgressBarDataMethod(component, event, helper);        
	},
    
    saveEquipmentInformation : function(component, event, helper) {
        helper.startSpinner(component, "emailSpinner");
        $A.util.addClass(component.find("saveEquipment"), 'noDisplay');
		var equipmentUpdateVar = component.get("v.equipmentUpdate");
        var equipmentIdVar = component.get("v.customerInformation.Id");
        var loanUpdateVar = component.get("v.loanUpdate");
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");
	
        var saveAction = component.get("c.saveCustomerInformation");
        saveAction.setParams({
            "equipment" : equipmentUpdateVar,
            "equipmentId" : equipmentIdVar,
            "loanId" : loanUpdateIdVar,
            "loan" : loanUpdateVar,
        });
        
        saveAction.setCallback(this, function(resp) {
            if(resp.getState() == "SUCCESS") {
                helper.stopSpinner(component, "emailSpinner");
                $A.util.removeClass(component.find("saveEquipment"), 'noDisplay');
                alert("The information has been updated");
            }else {
                $A.log("Errors", resp.getError());                
            }
        }); 
        
        var customerInformationAction = component.get("c.getCustomerInformation"); 
        customerInformationAction.setParams({loanId : loanUpdateIdVar})
        customerInformationAction.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.customerInformation", resp.getReturnValue());
                var mslpVar = resp.getReturnValue().DOER_Solar_Loann__c;
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });           
        
		$A.enqueueAction(saveAction);
                     
        $A.enqueueAction(customerInformationAction);     
        helper.getProgressBarDataMethod(component, event, helper);

    /*    //save the files
        var fileInput = component.find("mechInstallFile").getElement();
    	var file = fileInput.files[0];
   
        if (fileInput.size > this.MAX_FILE_SIZE) {
            alert('File size cannot exceed ' + this.MAX_FILE_SIZE + ' bytes.\n' +
    	          'Selected file size: ' + fileInput.size);
    	    return;
        }
    
        var fr = new FileReader();
        fr.onloadend = function(e) { 
        console.log("loaded"); 
        };         
        
        var self = this;
       	fr.onload = function() {
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

            fileContents = fileContents.substring(dataStart);
        
    	    self.upload(component, file, fileContents);
        };

        fr.readAsDataURL(file);     */                   
    },
    
  /*  upload: function(component, file, fileContents) {
        var action = component.get("c.saveTheFile"); 

        action.setParams({
            parentId: component.get("v.customerInformation.Loan__r.Id"),
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents), 
            contentType: file.type
        });

        action.setCallback(this, function(a) {
            attachId = a.getReturnValue();
            console.log(attachId);
        });
            
        $A.run(function() {
            $A.enqueueAction(action); 
        });
    },*/
    
    updateDisbursal : function(component, event, helper) { 
        var source = event.getSource();
        var disbursalId = source.get("v.name");
        var disbursalVal = source.get("v.value");
        var actionUpdateDisbursals = component.get("c.updateDisbursals");
        
        actionUpdateDisbursals.setParams({disbursalId : disbursalId,
                                          disbursalValue : disbursalVal});
        $A.enqueueAction(actionUpdateDisbursals); 
    },    
    
    fieldChanges : function(component, event, helper) {   		     
        
        var mechDate = component.get("v.customerInformation.Mechanical_Installation_Date__c");
        if(mechDate != null){
        	component.set("v.equipmentUpdate.Mechanical_Installation_Date__c", mechDate);            
        }
        
        var interconnectDate = component.get("v.customerInformation.Interconnection_Date__c");
        if(interconnectDate != null){
        	component.set("v.equipmentUpdate.Interconnection_Date__c", interconnectDate);
        }        
        
        var commencementDate = component.get("v.customerInformation.Loan__r.Commencement_Datee__c");
        if(commencementDate != null){
        	component.set("v.loanUpdate.Commencement_Datee__c", commencementDate);        
        }  
        
        var mechInstallCheck = component.get("v.customerInformation.Mechanically_Installed__c");
        if(mechInstallCheck != null){
        	component.set("v.equipmentUpdate.Mechanically_Installed__c", mechInstallCheck);            
        }
        
        var interconnectChange = component.get("v.customerInformation.Interconnected__c");
        if(interconnectChange != null){
        	component.set("v.equipmentUpdate.Interconnected__c", interconnectChange);            
        }           
    },
        
    openParentSubTasks : function(component, event, helper) {
        var source = event.getSource();
        var taskId = source.get("v.labelClass");   
        //var viewButton = component.find("viewButton");    
        //var closeButton = component.find("closeButton");           
		
		var subTaskTableToggle = component.find("subTaskTable");
        var subTaskHeaderToggle = component.find("subTaskHeader");
        
        var parentSubTaskList = component.get("c.getLoanParentSubTasks");  
        parentSubTaskList.setParams({taskId : taskId});
        parentSubTaskList.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                //component.set("v.taskType", resp.getReturnValue()[0].Task_Type__c);
                component.set("v.parentSubTaskList", resp.getReturnValue());
                $A.util.removeClass(subTaskHeaderToggle, 'noDisplay');
                $A.util.removeClass(subTaskTableToggle, 'noDisplay');
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(parentSubTaskList);   
    
    },
    
    openSubTasks : function(component, event, helper) {
        var source = event.getSource();
        var taskId = source.get("v.labelClass");   
        //var parentSubTaskToggle = component.find("parentSubTasks");
        //var subTaskTypeToggle = component.find("subTaskType");        

        var subTaskList = component.get("c.getLoanParentSubTasks");  		
        subTaskList.setParams({taskId : taskId});
        
        subTaskList.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.subTaskList", resp.getReturnValue());
                if(resp.getReturnValue() != null){
                    //$A.util.removeClass(closeButton, 'noDisplay');
                    //$A.util.addClass(viewButton, 'noDisplay');                	                    
                    $A.util.removeClass(parentSubTaskToggle, 'noDisplay'); 
        			$A.util.removeClass(subTaskTypeToggle, 'noDisplay');
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(subTaskList);          
    },     
        
    exitParentSubTasks : function(component, event, helper) {   
        var parentSubTaskToggle = component.find("parentSubTasks");
        component.set("v.parentSubTaskButton", true);    
		component.set("v.parentSubTaskList", null);  
        var subTaskTypeToggle = component.find("subTaskType");
        var taskTableToggle = component.find("taskTable");
        //var exitParentSubTasksButton = component.find("exitParentSubTasksTable");
        //var viewButton = component.find("viewButton");    
        //var closeButton = component.find("closeButton");
        var subTaskHeaderToggle = component.find("subTaskHeader");           
        var subTaskTableToggle = component.find("subTaskTable");
         $A.util.addClass(subTaskTableToggle, 'noDisplay');
         $A.util.addClass(subTaskHeaderToggle, 'noDisplay');
        //$A.util.addClass(parentSubTaskToggle, 'noDisplay');          
        //$A.util.addClass(subTaskTypeToggle, 'noDisplay'); 
        //$A.util.addClass(exitParentSubTasksButton, 'noDisplay'); 
        //$A.util.addClass(closeButton, 'noDisplay');
        //$A.util.removeClass(viewButton, 'noDisplay');                          
    }, 
    
    exitSubTasks : function(component, event, helper) {   
		component.set("v.subTaskList", null);   
    },
    
    navigateInstallationDocs : function(component, event, helper) {
        var leadId = component.get("v.customerInformation.Loan__r.Lead__r.Id");                        
        var equipmentId = component.get("v.customerInformation.Id"); 
        var updateDummy = component.get("v.customerInformation.Loan__r.Lead__r.Update_Dummy__c");
        if(updateDummy == true){
            updateDummy = false;
        }else{
            updateDummy = true;
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": 'https://forms.bluewaverenewables.com/381585?tfa_814=' + leadId 
            + '&' + 'tfa_821=' + equipmentId
            + '&' + 'tfa_828=' + updateDummy

        });
        urlEvent.fire();                
    },

    navigateInterconnectionDocs : function(component, event, helper) {
        var leadId = component.get("v.customerInformation.Loan__r.Lead__r.Id");                        
        var equipmentId = component.get("v.customerInformation.Id"); 
        var updateDummy = component.get("v.customerInformation.Loan__r.Lead__r.Update_Dummy__c");
        if(updateDummy == true){
            updateDummy = false;
        }else{
            updateDummy = true;
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": 'https://forms.bluewaverenewables.com/381589?tfa_814=' + leadId 
            + '&' + 'tfa_821=' + equipmentId
            + '&' + 'tfa_828=' + updateDummy

        });
        urlEvent.fire();                
    },    
    
    navigateIncomeDocs : function(component, event, helper) {
        var leadId = component.get("v.customerInformation.Loan__r.Lead__r.Id");  
        var mslp = component.get("v.customerInformation.Loan__r.DOER_Solar_Loann__c");                      
        var equipmentId = component.get("v.customerInformation.Id"); 
        var updateDummy = component.get("v.customerInformation.Loan__r.Lead__r.Update_Dummy__c");
        var income = component.get("v.customerInformation.Loan__r.Lead__r.Annual_Income_Currency__c");
        if(updateDummy == true){
            updateDummy = false;
        }else{
            updateDummy = true;
        }        
        var urlEvent = $A.get("e.force:navigateToURL");
        if(mslp == false) {
            urlEvent.setParams({
              "url": 'https://forms.bluewaverenewables.com/381611?tfa_526=' + leadId 
                + '&' + 'tfa_1180=' + updateDummy 
                + '&' + 'tfa_390=' + income                  
            });
        }else {
            urlEvent.setParams({
              "url": 'https://forms.bluewaverenewables.com/381611?tfa_526=' + leadId 
                + '&' + 'tfa_1180=' + updateDummy 
                + '&' + 'tfa_390=' + income   
            });            
        }
        urlEvent.fire();                
    },  
    
    navigateSalesAgreementDoc : function(component, event, helper) {
        var leadId = component.get("v.customerInformation.Opportunity__r.Id");                        
        var updateDummy = component.get("v.customerInformation.Loan__r.Opportunity__r.Update_Dummy__c");
        if(updateDummy == true){
            updateDummy = false;
        }else{
            updateDummy = true;
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": 'https://forms.bluewaverenewables.com/381616?tfa_814=' + leadId 
            + '&' + 'tfa_828=' + updateDummy

        });
        urlEvent.fire();                
    },        
    
})