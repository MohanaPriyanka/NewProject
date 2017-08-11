({
    doInit : function(component, event, helper) {
	var closeButton = component.find("closeButton");
        $A.util.addClass(closeButton, 'noDisplay');

        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");
        actionLicenseType.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue() && resp.getReturnValue() == 'Executive') {
                        component.set("v.licenseType", true);
                }
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionLicenseType);
        component.set("v.vendorIdLabel", "Unique Identifier");
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
        customerInformationAction.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.customerInformation", resp.getReturnValue());
                component.set("v.customer", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(customerInformationAction);

        var i;
        var i;
        var partnerTaskList = component.get("c.getLoanCustomerTasks");
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : label});
        partnerTaskList.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
                for (i=0; i<resp.getReturnValue().length; i++) {
                    if (resp.getReturnValue()[i].Name == "Interconnection") {
                        component.set("v.interconnectionTaskStatus", resp.getReturnValue()[i].Status__c);
                    } else {
                        continue;
                    }
                }
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(partnerTaskList);

        var completeLoanDisbursals = component.get("c.getCompleteLoanDisbursals");
        completeLoanDisbursals.setParams({loanId : label});
	completeLoanDisbursals.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.completeDisbursalList", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        var incompleteLoanDisbursals = component.get("c.getIncompleteLoanDisbursals");
        incompleteLoanDisbursals.setParams({loanId : label});
	incompleteLoanDisbursals.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.incompleteDisbursalList", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });

        $A.enqueueAction(completeLoanDisbursals);
        $A.enqueueAction(incompleteLoanDisbursals);
    },

    exitCustomerWindow : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    openDisbursalInformation : function(component, event, helper) {
        $A.util.addClass(component.find('disbursalModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');

        var loanId = component.get("v.customerInformation.Loan__r.Id");
        var disbursalCompleteTableToggle = component.find("disbursalCompleteTable");
        var disbursalIncompleteTableToggle = component.find("disbursalIncompleteTable");
        var pendingDisbursalsToggle = component.find("pendingDisbursals");
        var mslpCustomerInfoTextToggle = component.find("cusomterInformationTextMSLP");
        var completedDisbursalsToggle = component.find("completeDisbursals");

        component.set("v.blueWaveReviewAlert", false);

        $A.util.removeClass(disbursalCompleteTableToggle, 'noDisplay');
        $A.util.removeClass(disbursalIncompleteTableToggle, 'noDisplay');
        $A.util.removeClass(pendingDisbursalsToggle, 'noDisplay');
        $A.util.removeClass(completedDisbursalsToggle, 'noDisplay');

        var completeLoanDisbursals = component.get("c.getCompleteLoanDisbursals");
        completeLoanDisbursals.setParams({loanId : loanId});
	completeLoanDisbursals.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.completeDisbursalList", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(completeLoanDisbursals);

        var incompleteLoanDisbursals = component.get("c.getIncompleteLoanDisbursals");
        incompleteLoanDisbursals.setParams({loanId : loanId});
	incompleteLoanDisbursals.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
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

    closeDisbursalModal : function(component, event, helper) {
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');
        $A.util.removeClass(component.find('disbursalModal'), 'slds-fade-in-open');
    },

    //The use of the event.currentTarget.value is taken from the below link. Event.getSource was not working with lightning buttons.
    //https://salesforce.stackexchange.com/questions/144129/winter-17-release-event-getsource-is-not-a-function-on-lightningbutton/14718
    setSrecOptInCalendarQuarter : function(component, event, helper) {
        var srecOptInCQ = event.currentTarget.value;
        component.set("v.equipmentUpdate.SREC_Opt_In_Calendar_Quarter__c", srecOptInCQ);
    },

    setEquipmentAsInterconnected : function(component, event, helper) {
        var source = event.getSource();
        component.set("v.equipmentUpdate.Interconnected__c",  source.get("v.value"));
    },

    setEquipmentCommonwealthProgram : function(component, event, helper) {
        var source = event.getSource();
        component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c",  source.get("v.value"));
    },

    setInterconnectedTrue : function(component, event, helper) {
        component.set("v.equipmentUpdate.Interconnected__c", "true");
    },

    setInterconnectedFalse : function(component, event, helper) {
        component.set("v.equipmentUpdate.Interconnected__c", "false");
    },

    setCwProgramTrue : function(component, event, helper) {
        component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c", "true");
    },

    setCwProgramFalse : function(component, event, helper) {
        component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c", "false");
    },

    setFacilitySector : function(component, event, helper) {
        component.set("v.equipmentUpdate.MA_Facility_Sector__c", event.currentTarget.value);
    },

    setFacilityType : function(component, event, helper) {
        component.set("v.equipmentUpdate.MA_Facility_Type__c", event.currentTarget.value);
    },

    setAutoPTSFalse : function(component, event, helper) {
        component.set("v.equipmentUpdate.Auto_Reporting_to_PTS__c", "FALSE");
        $A.util.addClass(component.find("vendorSelection"), 'noDisplay');
        $A.util.addClass(component.find("vendorUniqueId"), 'noDisplay');
        $A.util.addClass(component.find("geSerialNumber"), 'noDisplay');
    },

    setAutoPTSTrue : function(component, event, helper) {
        var customerInformation = component.get("v.customerInformation");
        component.set("v.equipmentUpdate.Auto_Reporting_to_PTS__c", "TRUE");
        $A.util.removeClass(component.find("vendorSelection"), 'noDisplay');
        if (customerInformation.Remote_Monitoring_System_Vendor__c == "SolarLog") {
            $A.util.removeClass(component.find("geSerialNumber"), 'noDisplay');
        }
        if (customerInformation.Remote_Monitoring_System_Vendor__c == "Locus") {
            component.set("v.vendorIdLabel", "Mac Id");
        } else {
            component.set("v.vendorIdLabel", customerInformation.Remote_Monitoring_System_Vendor__c  + " " + "Unique Identifier");
        }
        $A.util.removeClass(component.find("vendorUniqueId"), 'noDisplay');
    },

    setAutoReportingVendor : function(component, event, helper) {
        var vendor = event.currentTarget.value;
        component.set("v.equipmentUpdate.Remote_Monitoring_System_Vendor__c", vendor);
        if (vendor == "Locus") {
            component.set("v.vendorIdLabel", "Mac Id");
        } else {
            component.set("v.vendorIdLabel", vendor + " " + "Unique Identifier");
        }
        if (vendor == "SolarLog") {
            $A.util.removeClass(component.find("geSerialNumber"), 'noDisplay');
        } else {
            $A.util.addClass(component.find("geSerialNumber"), 'noDisplay');
        }
        $A.util.removeClass(component.find("vendorUniqueId"), 'noDisplay');
    },

    saveSystemInformation : function(component, event, helper) {       
        helper.startSpinner(component, "customerInformationSpinner");
        $A.util.addClass(component.find("saveCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeCustomerModalButton"), 'noDisplay');

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
                helper.stopSpinner(component, "customerInformationSpinner");
                helper.confirmSystemInformationSaved(component);             
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(saveAction);

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
        $A.enqueueAction(customerInformationAction);
    },    

    saveEquipmentInformation : function(component, event, helper) {
        helper.startSpinner(component, "srecSaveSpinner");
        helper.startSpinner(component, "customerInformationSpinner");
        $A.util.addClass(component.find("saveCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeCustomerModalButton"), 'noDisplay');
        $A.util.addClass(component.find("saveSrecModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeSrecModalButton"), 'noDisplay');

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
                helper.stopSpinner(component, "srecSaveSpinner");
                helper.stopSpinner(component, "customerInformationSpinner");
                $A.util.removeClass(component.find("saveCustomerModalButton"), 'noDisplay');
                $A.util.removeClass(component.find("closeCustomerModalButton"), 'noDisplay');
                $A.util.removeClass(component.find("saveSrecModalButton"), 'noDisplay');
                $A.util.removeClass(component.find("closeSrecModalButton"), 'noDisplay');
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

	$A.enqueueAction(saveAction);

        $A.enqueueAction(customerInformationAction);
        helper.getProgressBarDataMethod(component, event, helper);
    },

    savePtoDoc : function(component, event, helper) {
        helper.saveFile(component, event);
    },

    openCustomerModal : function(component, event, helper) { 
        helper.openCustomerModal(component, event, helper);
    },        

    openInterconnectionModal : function(component, event, helper) { 
        helper.openInterconnectionModal(component, event, helper);
    },

    closeInterconnectionModal : function(component, event, helper) {
        $A.util.removeClass(component.find('srecInformationModal'), 'slds-fade-in-open');
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');

        var label = component.get("v.customerInformation.Loan__r.Id");

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
            var interconnectionToggle = component.find("intemodalrconnection");
            var completeToggle = component.find("complete");
            var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");

            if (resp.getState() == 'SUCCESS') {
                helper.getProgressBarDataMethod(component, event, helper);
            } else {
                $A.log("Errors", resp.getError());
                alert("There was an issue loading the progress bar");
            }
        });
        $A.enqueueAction(progressBarData);

        var i;
        var partnerTaskList = component.get("c.getLoanCustomerTasks");
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : label});
        partnerTaskList.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
                for (i=0; i<resp.getReturnValue().length; i++) {
                    if (resp.getReturnValue()[i].Name == "Interconnection") {
                        component.set("v.interconnectionTaskStatus", resp.getReturnValue()[i].Status__c);
                    } else {
                        continue;
                    }
                }
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(partnerTaskList);
    },

    closeCustomerModal : function(component, event, helper) {
        $A.util.removeClass(component.find('generalSystemInformationModal'), 'slds-fade-in-open');
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');
        helper.closeSystemInformationSaved(component);

        var i;
        var partnerTaskList = component.get("c.getLoanCustomerTasks");
        var componentCustomerId = component.get("v.customer");
        partnerTaskList.setParams({loanId : componentCustomerId.Loan__r.Id});
        partnerTaskList.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerTaskList", resp.getReturnValue());
                for (i=0; i<resp.getReturnValue().length; i++) {
                    if (resp.getReturnValue()[i].Name == "Interconnection") {
                        component.set("v.interconnectionTaskStatus", resp.getReturnValue()[i].Status__c);
                    } else {
                        continue;
                    }
                }
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(partnerTaskList);

        var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");
    },

    getSrecInterconnectionPage: function(component, event, helper) {
        helper.getGenericPage('SrecInterconnectionPage', component);
    },
    getGeneratorInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecGeneratorPage', component);
    },
    getModuleInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecModulePage', component);
    },
    getInverterInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecInverterPage', component);
    },
    getRemoteMonitoringInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecRemoteMonitoringPage', component);
    },
    getSolarMeterInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecSolarMeterPage', component);
    },
    getMiscInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecMiscPage', component);
    },
    getInstallationTimeLineInformationPage: function(component, event, helper) {
        helper.getGenericPage('SrecInstallationTimeLinePage', component);
    },

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
        if (mechDate != null) {
        	component.set("v.equipmentUpdate.Mechanical_Installation_Date__c", mechDate);
        }

        var interconnectDate = component.get("v.customerInformation.Interconnection_Date__c");
        if (interconnectDate != null) {
        	component.set("v.equipmentUpdate.Interconnection_Date__c", interconnectDate);
        }

        var commencementDate = component.get("v.customerInformation.Loan__r.Commencement_Datee__c");
        if (commencementDate != null) {
        	component.set("v.loanUpdate.Commencement_Datee__c", commencementDate);
        }

        var solarMeterReadDate = component.get("v.customerInformation.Initial_Solar_Meter_Reading_Date__c");
        if (solarMeterReadDate != null) {
            component.set("v.equipmentUpdate.Initial_Solar_Meter_Reading_Date__c", solarMeterReadDate);
        }

        var contractExecutionDate = component.get("v.customerInformation.Contract_Execution_Date__c");
        if (contractExecutionDate != null) {
            component.set("v.equipmentUpdate.Contract_Execution_Date__c", contractExecutionDate);
        }

        var generatorInterconnectionDate = component.get("v.customerInformation.Generator_Interconnection_Date__c");
        if (generatorInterconnectionDate != null) {
            component.set("v.equipmentUpdate.Generator_Interconnection_Date__c", generatorInterconnectionDate);
        }

        var generatorInstallationDate = component.get("v.customerInformation.Generator_Installation_Date__c");
        if (generatorInstallationDate != null) {
            component.set("v.equipmentUpdate.Generator_Installation_Date__c", generatorInstallationDate);
        }

        var generatorOnlineDate = component.get("v.customerInformation.Generator_Energized_Online_Date__c");
        if (generatorOnlineDate != null) {
            component.set("v.equipmentUpdate.Generator_Energized_Online_Date__c", generatorOnlineDate);
        }

        var mechInstallCheck = component.get("v.customerInformation.Mechanically_Installed__c");
        if (mechInstallCheck != null) {
        	component.set("v.equipmentUpdate.Mechanically_Installed__c", mechInstallCheck);
        }

        var interconnectChange = component.get("v.customerInformation.Interconnected__c");
        if (interconnectChange != null) {
        	component.set("v.equipmentUpdate.Interconnected__c", interconnectChange);
        }

        var commonwealthSolarRebateProgram = component.get("v.customerInformation.Commonwealth_Solar_Rebate_Program__c");
        if (interconnectChange != null) {
            component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c", commonwealthSolarRebateProgram);
        }

        var maFacilityType = component.get("v.customerInformation.MA_Facility_Type__c");
        if (maFacilityType != null) {
            component.set("v.equipmentUpdate.MA_Facility_Type__c", maFacilityType);
        }

        var maFacilitySector = component.get("v.customerInformation.MA_Facility_Sector__c");
        if (maFacilitySector != null) {
            component.set("v.equipmentUpdate.MA_Facility_Sector__c", maFacilitySector);
        }

        var autoReportingVendor = component.get("v.customerInformation.Remote_Monitoring_System_Vendor__c");
        if (autoReportingVendor != null) {
            component.set("v.equipmentUpdate.Remote_Monitoring_System_Vendor__c", autoReportingVendor);
        }

        var commonWealthProgram = component.get("v.customerInformation.Commonwealth_Solar_Rebate_Program__c");
        if (commonWealthProgram != null) {
            component.set("v.equipmentUpdate.Commonwealth_Solar_Rebate_Program__c", commonWealthProgram);
        }

        var autoReport = component.get("v.customerInformation.Auto_Reporting_to_PTS__c");
        if (autoReport != null) {
            component.set("v.equipmentUpdate.Auto_Reporting_to_PTS__c", autoReport);
        }
    },

    handleTaskAction : function(component, event, helper) {
        var leadId = component.get("v.customerInformation.Loan__r.Lead__r.Id");
        var oppId = component.get("v.customerInformation.Opportunity__r.Id");                
        var leadUpdateDummy = component.get("v.customerInformation.Loan__r.Lead__r.Update_Dummy__c");
        var oppUpdateDummy = component.get("v.customerInformation.Loan__r.Opportunity__r.Update_Dummy__c");        
        var taskName = event.getSource().get("v.class");
        switch (taskName) {
            case "Provide all System Information":
            case "Provide All System Information":
                helper.openCustomerModal(component, event, helper);
                return;
            case "Mechanical Installation":
                var formId = "381585";
                break;
            case "Interconnection":
            case "Report Interconnection to MCEC":
                if (component.get("v.customerInformation.Loan__r.State__c") === "MA") {
                    var formId = "381637";
                    break;
                } else {
                    var formId = "381589";
                    break;
                }
            case "Provide PayStub Documentation":
            case "Provide SSN/Pension Award Letter or Bank Statement":
            case "Provide Tax Return (Previous Year)":
            case "Provide Tax Return (Two Years Previous)":
                var formId = "381611";
                break;
            case "Provide Sales Agreement":
                var formId = "381606";
                break;
            default:
                var formId = "";
        }
        var equipmentId = component.get("v.customerInformation.Id");
        var urlEvent = $A.get("e.force:navigateToURL");
        if (formId === "381611") {
            var income = component.get("v.customerInformation.Loan__r.Lead__r.Annual_Income_Currency__c");
            urlEvent.setParams(
                {"url": 'https://forms.bluewaverenewables.com/381611?tfa_526=' + leadId
                 + '&' + 'tfa_1180=' + !leadUpdateDummy
                 + '&' + 'tfa_390=' + income
            });
        } else if (formId === "381637") {
            var equipmentUpdateDummy = component.get("v.customerInformation.Interconnection_Update_Dummy__c");
            var opportunityId = component.get("v.customerInformation.Opportunity__r.Id");
            urlEvent.setParams(
                {"url": "https://forms.bluewaverenewables.com/" + formId + "?" +
                 "tfa_117=" + equipmentId
                 + '&' + 'tfa_118=' + !equipmentUpdateDummy
                 + '&' + 'tfa_107=' + opportunityId
            });
        } else if (formId === "381606") {
            urlEvent.setParams(
                {"url": "https://forms.bluewaverenewables.com/" + formId + "?" +
                 "tfa_814=" + oppId
                 + '&' + 'tfa_828=' + !oppUpdateDummy
            }); 
        }else {
            urlEvent.setParams(
                {"url": "https://forms.bluewaverenewables.com/" + formId + "?" +
                 "tfa_814=" + leadId
                 + '&' + 'tfa_828=' + !oppUpdateDummy
                 + '&' + 'tfa_821=' + equipmentId
                });
        }
        urlEvent.fire();
    },
})

