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
        var loanUpdateVar = component.get("v.loanUpdate");
        var loanUpdateIdVar = component.get("v.customerInformation.Loan__r.Id");

        var saveAction = component.get("c.saveCustomerInformation");
        saveAction.setParams({
            "equipmentFromComponent" : equipmentUpdateVar,
            "equipmentId" : equipmentIdVar,
            "loanId" : loanUpdateIdVar,
            "loan" : loanUpdateVar,
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

    getCustomerInformation : function(component, helper, loanId) {
        var ltg = helper;
        if (!loanId) {
            loanId = component.get('v.customerInformation.Loan__c');
        }
        var promise = new Promise(function(resolve) {
            //retrieve the customer's full information to display in the component
            var customerInformationAction = component.get("c.getCustomerInformation");
            customerInformationAction.setParams({loanId : loanId})
            customerInformationAction.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    const customer = resp.getReturnValue();
                    component.set("v.customerInformation", customer);
                    component.set("v.customer", customer);
                    // completion date is something like 2018-07-01, but BlueWaveDate needs 07/01/2018
                    component.set("v.completionDateString", helper.getFormattedDate(customer.Loan__r.Estimated_Completion_Date__c));
                    if (customer.Loan__r.Opportunity__r) {
                        if (customer.Loan__r.Total_Funds_Disbursed__c !== 0) {
                            component.set('v.disbursed', true);
                        }
                        if (customer.Opportunity__r.BlueWave_Signature_Status__c === 'Completed') {
                            component.set('v.bwExecuted', true);
                        }
                    }
                    helper.getDocuSignPresent(component, helper).then(
                        $A.getCallback(function() {
                            helper.setChangeOrder(component, customer, ltg)
                        })).then(
                        $A.getCallback(function() {
                            helper.parsePermitAttachments(component, ltg)
                        }));
                    resolve();
                } else {
                    ltg.logError('SLPCustomerHelper', 'getCustomerInformation', 'Couldn\'t get Residential Equipment information', resp);
                }
            });
            $A.enqueueAction(customerInformationAction);
        });
        return promise;
    },

    getDocuSignPresent : function(component, helper) {
        var docuSignPromise = new Promise(function(resolve) {
            const docuSignAction = component.get('c.docuSignPresent');
            docuSignAction.setParams({oppId: component.get('v.customerInformation.Loan__r.Opportunity__c')});
            docuSignAction.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set('v.docuSignPresent', resp.getReturnValue());
                    resolve();
                } else {
                    helper.logError('SLPCustomerHelper', 'getDocuSignPresent', 'Couldn\'t get DocuSign Statuses', resp);
                }
            });
            if (component.get('v.customerInformation.Loan__r.Opportunity__c')) {
                $A.enqueueAction(docuSignAction);
            } else {
                resolve();
            }
        });
        return docuSignPromise;
    },

    setChangeOrder : function(component, customer, helper) {
        var docuSignPromise = new Promise(function(resolve) {
            if (customer.Loan__r.Lead__r.Loan_System_Information__c) {
                const changeOrder = JSON.parse(customer.Loan__r.Lead__r.Loan_System_Information__c);
                helper.defaultChangeOrderLeadField(changeOrder, 'System_Cost', customer);
                helper.defaultChangeOrderLeadField(changeOrder, 'Requested_Loan_Amount', customer);
                helper.defaultChangeOrderLoanField(changeOrder, 'Estimated_Completion_Date', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Generator_Nameplate_Capacity', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Module_Manufacturer', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Module_Model_Number', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Number_of_Modules', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Inverter_Manufacturer', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Inverter_Model_Number', customer);
                helper.defaultChangeOrderEquipmentField(changeOrder, 'Number_of_Inverters', customer);
                if (!changeOrder.hasOwnProperty('Down_Payment__change')) {
                    changeOrder['Down_Payment__change'] = changeOrder.System_Cost__change - changeOrder.Requested_Loan_Amount__change;
                }
                component.set('v.changeOrder', changeOrder);
            }
            resolve();
        });
        return docuSignPromise;
    },

    defaultChangeOrderLeadField : function(changeOrder, field, customer) {
        if (!changeOrder.hasOwnProperty(field + '__change')) {
            changeOrder[field + '__change'] = customer.Loan__r.Lead__r[field + '__c'];
        }
    },

    defaultChangeOrderLoanField : function(changeOrder, field, customer) {
        if (!changeOrder.hasOwnProperty(field + '__change')) {
            // If Completion Date isn't set, we still should set the change order field
            changeOrder[field + '__change'] = customer.Loan__r[field + '__c']==null?'':customer.Loan__r[field + '__c'];
        }
    },

    defaultChangeOrderEquipmentField : function(changeOrder, field, customer) {
        if (!changeOrder.hasOwnProperty(field + '__change')) {
            changeOrder[field + '__change'] = customer[field + '__c'];
        }
    },

    getCustomerAttachments : function(component, helper) {
        const ltg = helper;
        const loanId = component.get('v.customerInformation.Loan__c');
        const promise = new Promise(function(resolve) {
            //retrieve the customer's full information to display in the component
            var customerInformationAction = component.get("c.getCustomerInformation");
            customerInformationAction.setParams({loanId : loanId})
            customerInformationAction.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    const customerInfo = resp.getReturnValue();
                    component.set("v.customerInformation.Attachments", customerInfo.Attachments);
                    helper.parsePermitAttachments(component, ltg);
                    helper.stopSpinner(component, "buildingPermitUploadSpinner");
                    resolve();
                } else {
                    helper.stopSpinner(component, "buildingPermitUploadSpinner");
                    ltg.logError('SLPCustomerHelper', 'getCustomerAttachments', 'Couldn\'t get Residential Equipment information', resp);
                }
            });
            $A.enqueueAction(customerInformationAction);
        });
        return promise;
    },

    openCustomerWindow : function(component, event, helper, loanId) {
        //remove the noDisplayBar class from the Component - bringing the page to display.
        var customerPage = component.find("customerPage");
        $A.util.removeClass(customerPage, 'noDisplayBar');

        var promise = helper.getCustomerInformation(component, helper, loanId);
        promise.then($A.getCallback(function resolve() {
            var i;
            var partnerTaskList = component.get("c.getLoanCustomerTasks");
            partnerTaskList.setParams({loanId : loanId});
            partnerTaskList.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set("v.partnerTaskList", resp.getReturnValue());
                    for (i=0; i<resp.getReturnValue().length; i++) {
                        if (resp.getReturnValue()[i].Name === "Interconnection") {
                            component.set("v.interconnectionTaskStatus", resp.getReturnValue()[i].Effective_Status__c);
                        } else if (resp.getReturnValue()[i].Name === 'Obtain Contract Signature') {
                            if (resp.getReturnValue()[i].Effective_Status__c === 'Pending' ||
                                resp.getReturnValue()[i].Effective_Status__c === 'Complete') {
                                component.set("v.contractSent", true);
                            } else {
                                component.set("v.contractSent", false);
                            }
                        }
                    }
                } else {
                    $A.log("Errors", resp.getError());
                }
            });
            $A.enqueueAction(partnerTaskList);

            var completeLoanDisbursals = component.get("c.getCompleteLoanDisbursals");
            completeLoanDisbursals.setParams({loanId : loanId});
            completeLoanDisbursals.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set("v.completeDisbursalList", resp.getReturnValue());
                } else {
                    $A.log("Errors", resp.getError());
                }
            });

            var incompleteLoanDisbursals = component.get("c.getIncompleteLoanDisbursals");
            incompleteLoanDisbursals.setParams({loanId : loanId});
            incompleteLoanDisbursals.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set("v.incompleteDisbursalList", resp.getReturnValue());
                } else {
                    $A.log("Errors", resp.getError());
                }
            });

            $A.enqueueAction(completeLoanDisbursals);
            $A.enqueueAction(incompleteLoanDisbursals);
        }));
    },

    openUploadWindow: function(component, dateLabelString, windowHeaderString, parentId, oppId, nameFile, helpText){
      var body = component.get("v.body");  
      component.set("v.body", []);  
      $A.createComponent(
      	"c:SLPFileUploadWindow", 
      	{"dateLabel": dateLabelString,
      	"windowHeader": windowHeaderString,
        "fileParentId": parentId,
        "oppId" : oppId,
        "helpText" : helpText,
        "fileName": nameFile }, 
                       
       	function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
            var body = component.get("v.body");
            body.push(newButton);
            component.set("v.body", body);
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
            component.find("srecInterconnectionToggle").set("v.checked", "true");
        }
    },

    openCustomerModal : function(component, event, helper) {
        $A.util.addClass(component.find('generalSystemInformationModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');
    },

    confirmSystemInformationSaved : function(component, confirmString) {
        if (!confirmString) {
            confirmString = 'The system information has been saved, thank you!'
        }
        $A.util.removeClass(component.find('generalSystemInformationModal'), 'slds-fade-in-open');
        component.set('v.confirmMessage', confirmString);
        $A.util.addClass(component.find('confirmModal'), 'slds-fade-in-open');
    },

    closeSystemInformationSaved : function(component) {
        $A.util.removeClass(component.find("systemInformationInputs"), 'noDisplay');
        $A.util.addClass(component.find("systemInformationSubmitConfirmation"), 'noDisplay');
        $A.util.addClass(component.find("changeOrderWithdrawnConfirmation"), 'noDisplay');
        $A.util.removeClass(component.find("saveCustomerModalButton"), 'noDisplay');
    },

    parsePermitAttachments : function(component, helper) {
        var docuSignPromise = new Promise(function(resolve) {
            const equipment = component.get('v.customerInformation');
            if (equipment.Attachments) {
                const permits = [];
                equipment.Attachments.forEach(function (attachment) {
                    const desc = attachment.Description;
                    if (desc === 'Building Permit') {
                        permits.push(attachment.Name);
                    }
                });
                component.set('v.buildingPermits', permits);
            }
            resolve();
        });
        return docuSignPromise;
    },

    openBuildingPermitModal : function(component, event, helper) {
        helper.parsePermitAttachments(component, helper);
        var disbursalPromise = new Promise(function(resolve) {
            var disbursalAction = component.get("c.getFirstDisbursal");
            disbursalAction.setParams({"loanId": component.get('v.customerInformation.Loan__r.Id')});
            disbursalAction.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    component.set('v.firstDisbursalAmount', resp.getReturnValue());
                    component.set('v.showBuildingPermitModal', true);
                    $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');
                    resolve(helper);
                } else {
                    helper.logError('SLPCustomerHelper', 'openBuildingPermitModal', 'Couldn\'t get first disbursal amount');
                }
            });
            $A.enqueueAction(disbursalAction);
        });
    },

    confirmBuildingPermitSaved : function(component, event, helper) {
        $A.util.removeClass(component.find("closeBuildingPermitModalButton"), 'noDisplay');
        $A.util.addClass(component.find("buildingPermitInputs"), 'noDisplay');
        $A.util.removeClass(component.find("buildingPermitSubmitConfirmation"), 'noDisplay');
    },
})