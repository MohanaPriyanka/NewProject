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
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
            } else {
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
    
    getGenericPage: function(page, component) { 
        $A.util.addClass(component.find('SrecInterconnectionPage'), 'noDisplay');                           
        $A.util.addClass(component.find('SrecGeneratorPage'), 'noDisplay'); 
        $A.util.addClass(component.find('SrecModulePage'), 'noDisplay');      
        $A.util.addClass(component.find('SrecInverterPage'), 'noDisplay'); 
        $A.util.addClass(component.find('SrecRemoteMonitoringPage'), 'noDisplay');       
        $A.util.addClass(component.find('SrecSolarMeterPage'), 'noDisplay'); 
        $A.util.addClass(component.find('SrecMiscPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecInstallationTimeLinePage'), 'noDisplay');

        $A.util.removeClass(component.find(page), 'noDisplay');
    },

    getDescribedFile: function(component, description) {
        var checkForPtoFile = component.get("c.getDescribedFile");
        var parentId = component.get("v.customerInformation.Id");

        checkForPtoFile.setParams({
            "parentId" : parentId,
            "description" : description,
        });

        checkForPtoFile.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue() != null) {
                    component.set("v.ptoFileAttached", true);
                    component.set("v.ptoFileName", resp.getReturnValue().Name);
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(checkForPtoFile);
    },

    MAX_FILE_SIZE: 750 000, /* 1 000 000 * 3/4 to account for base64 */
    saveFile : function(component, event) {
        var fileInput = event.getSource().get("v.files")[0];

        var file = fileInput;
        
        if (file.size > this.MAX_FILE_SIZE) {
            alert('File size cannot exceed ' + this.MAX_FILE_SIZE + ' bytes.\n' +
                  'Selected file size: ' + file.size);
            return;
        }
        
        var fr = new FileReader();

        var self = this;
        fr.onload = function() {
            var fileContents = fr.result;
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

            fileContents = fileContents.substring(dataStart);
            
            self.upload(component, file, fileContents);
        };

        fr.readAsDataURL(file);
    },
    
    upload: function(component, file, fileContents) {
        var action = component.get("c.savePTODocumentation");
        action.setParams({
            parentId: component.get("v.customerInformation.Id"),
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents),
            contentType: file.type
        });

        $A.enqueueAction(action);
        component.set("v.ptoFileName", file.name);
        component.set("v.ptoFileAttached", true);
    },

    openInterconnectionModal : function(component, event, helper) {
        $A.util.addClass(component.find('srecInformationModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');
        $A.util.removeClass(component.find('SrecInterconnectionPage'), 'noDisplay');
        $A.util.removeClass(component.find('SrecNextPageGeneratorButton'), 'noDisplay');
        $A.util.addClass(component.find('SrecNextPageModuleButton'), 'noDisplay');
        $A.util.addClass(component.find('SrecGeneratorPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecModulePage'), 'noDisplay');
        $A.util.addClass(component.find('SrecInverterPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecRemoteMonitoringPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecSolarMeterPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecMiscPage'), 'noDisplay');
        $A.util.addClass(component.find('SrecInstallationTimeLinePage'), 'noDisplay');

        helper.getDescribedFile(component, 'PTO Documentation');

        var slportalSettings = component.get("c.getSLPortalSettings");
        slportalSettings.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var srecQuarters = resp.getReturnValue().SREC_Opt_In_Quarters__c;
                var srecQuartersList = srecQuarters .split(",");
                component.set("v.srecQuarters", srecQuartersList);
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(slportalSettings);

        var customerInformation = component.get("v.customerInformation");
        if (customerInformation.Auto_Reporting_to_PTS__c) {
            if (customerInformation.Remote_Monitoring_System_Vendor__c == "SolarLog") {
                $A.util.removeClass(component.find("geSerialNumber"), 'noDisplay');
            } else {
                $A.util.addClass(component.find("geSerialNumber"), 'noDisplay');
            }
            if (customerInformation.Remote_Monitoring_System_Vendor__c == null) {
                component.set("v.vendorIdLabel", "Unique Identifier");
            } else if (customerInformation.Remote_Monitoring_System_Vendor__c == "Locus") {
                component.set("v.vendorIdLabel", "Mac Id");
            } else {
                component.set("v.vendorIdLabel", customerInformation.Remote_Monitoring_System_Vendor__c  + " " + "Unique Identifier");
            }
            $A.util.removeClass(component.find("vendorSelection"), 'noDisplay');
            $A.util.removeClass(component.find("vendorUniqueId"), 'noDisplay');
            component.set("v.equipmentUpdate.Interconnected__c  ", customerInformation.Interconnected__c);
            component.set("v.equipmentUpdate.Auto_Reporting_to_PTS__c", customerInformation.Auto_Reporting_to_PTS__c);
            component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c", customerInformation.Commonwealth_Solar_Rebate_Program__c);
            component.find("srecInterconnectionToggle").set("v.checked", "true");
        }
    },

    openCustomerModal : function(component, event, helper) {
        $A.util.addClass(component.find('generalSystemInformationModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');
    },


})
