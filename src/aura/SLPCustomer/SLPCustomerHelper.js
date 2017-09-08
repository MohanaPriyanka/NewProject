({
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
    
    saveDataPreActionFormatting : function(component, event, helper) {
        this.startSpinner(component, "srecSaveSpinner");
        this.startSpinner(component, "customerInformationSpinner");
        $A.util.addClass(component.find("saveCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("saveSrecModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeSrecModalButton"), 'noDisplay');
    },
    
    saveDataSuccessFormatting : function(component, event, helper) {
        this.stopSpinner(component, "srecSaveSpinner");
        this.stopSpinner(component, "customerInformationSpinner");
        $A.util.removeClass(component.find("saveCustomerModalButton"), 'noDisplay');
        $A.util.removeClass(component.find("closeCustomerModalButton"), 'noDisplay');
        $A.util.removeClass(component.find("saveSrecModalButton"), 'noDisplay');
        $A.util.removeClass(component.find("closeSrecModalButton"), 'noDisplay');
    },
    
    saveCustomerData : function(component, event, helper) {
		var equipmentUpdateVar = component.get("v.equipmentUpdate");
        var equipmentIdVar = component.get("v.customerInformation.Id");
        var opportunityId = component.get("v.oppId");
        var loanUpdateVar = component.get("v.loanUpdate");
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");

        var saveAction = component.get("c.saveCustomerInformation");
        saveAction.setParams({
            "equipmentFromComponent" : equipmentUpdateVar,
            "equipmentId" : equipmentIdVar,
            "loanId" : loanUpdateIdVar,
            "loan" : loanUpdateVar,
            "opportunityUpdateId" : opportunityId
        });

        saveAction.setCallback(this, function(resp) {
            if (resp.getState() == "SUCCESS") {
              	return 'SUCCESS';
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        var customerInformationAction = component.get("c.getCustomerInformation");
        customerInformationAction.setParams({loanId : loanUpdateIdVar})
        customerInformationAction.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.customerInformation", resp.getReturnValue());
                var mslpVar = resp.getReturnValue().DOER_Solar_Loann__c;
            } else {
                $A.log("Errors", resp.getError());
            }
        });
		$A.enqueueAction(saveAction)
        $A.enqueueAction(customerInformationAction);
    },
    
    refreshPartnerTasks : function (component) {
     	var i;
        var partnerTaskList = component.get("c.getLoanCustomerTasks");
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : componentCustomerId.Loan__r.Id});
        partnerTaskList.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(partnerTaskList);
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

    openUploadWindow: function(component, dateLabelString, windowHeaderString, parentId, equipmentObject, nameFile){
      var body = component.get("v.body");  
      component.set("v.body", []);  
      $A.createComponent(
      	"c:SLPFileUploadWindow", 
      	{"dateLabel": dateLabelString,
      	"windowHeader": windowHeaderString,
        "fileParentId": parentId,
        "resiEquipment" : equipmentObject,
        "fileName": nameFile }, 
                       
       	function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
            var body = component.get("v.body");
            body.push(newButton);
            component.set("v.body", body);
          }
          else {
            console.log("Error: " + errorMessage);
          }
       	}
      );       
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

    confirmSystemInformationSaved : function(component, event, helper) {
        $A.util.removeClass(component.find("closeCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("systemInformationInputs"), 'noDisplay');
        $A.util.removeClass(component.find("systemInformationSubmitConfirmation"), 'noDisplay');
    }, 

    closeSystemInformationSaved : function(component, event, helper) {
        $A.util.removeClass(component.find("systemInformationInputs"), 'noDisplay');
        $A.util.addClass(component.find("systemInformationSubmitConfirmation"), 'noDisplay');
        $A.util.removeClass(component.find("saveCustomerModalButton"), 'noDisplay');    
    },     
})