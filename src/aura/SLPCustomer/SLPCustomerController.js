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
        helper.getStorageEnabled(component);
        var leadId = sessionStorage.getItem('loanId');
        helper.openCustomerWindow(component, event, helper, leadId);
        helper.setListAttributeWithPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Manufacturer__c', "v.availableStorageManufacturers");
        helper.setListAttributeWithPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Inverter_Manufacturer__c', "v.availableStorageInverterManufacturers");
        helper.setListAttributeWithPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Full_or_Partial_Home__c', "v.homeBackupOptions");
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

    setFacilitySector : function(component, event, helper) {
        component.set("v.equipmentUpdate.MA_Facility_Sector__c", event.currentTarget.value);
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
        helper.saveDataPreActionFormatting(component, event, helper);
        var isSuccess = helper.saveCustomerData(component, event, helper);
        if (isSuccess === 'SUCCESS') {
            helper.saveDataSuccessFormatting(component, event, helper);
        }
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
        helper.refreshPartnerTasks(component);
        var mslpVar = component.get("v.customer.Loan__r.DOER_Solar_Loann__c");
    },

    closeConfirmModal : function(component, event, helper) {
        $A.util.removeClass(component.find('confirmModal'), 'slds-fade-in-open');
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');
        helper.closeSystemInformationSaved(component);
        helper.refreshPartnerTasks(component);
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

        var completionDate = component.get("v.customerInformation.Loan__r.Estimated_Completion_Date__c");
        if (completionDate != null) {
            component.set("v.loanUpdate.Estimated_Completion_date__c", completionDate);
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

        var maFacilitySector = component.get("v.customerInformation.MA_Facility_Sector__c");
        if (maFacilitySector != null) {
            component.set("v.equipmentUpdate.MA_Facility_Sector__c", maFacilitySector);
        }

        var autoReportingVendor = component.get("v.customerInformation.Remote_Monitoring_System_Vendor__c");
        if (autoReportingVendor != null) {
            component.set("v.equipmentUpdate.Remote_Monitoring_System_Vendor__c", autoReportingVendor);
        }

        var autoReport = component.get("v.customerInformation.Auto_Reporting_to_PTS__c");
        if (autoReport != null) {
            component.set("v.equipmentUpdate.Auto_Reporting_to_PTS__c", autoReport);
        }
    },

    openAdditionalFileUpload : function(component, event, helper) {
        let oppId = component.get("v.customerInformation.Opportunity__r.Id");
        let parentId = component.get("v.customerInformation.Loan__r.Lead__r.ConvertedContactId");
        let leadId = component.get("v.customerInformation.Lead__c");
        helper.openUploadWindow(component,"hideAndFileOption","Upload Documents", parentId, oppId, leadId, component.get("v.equipmentUpdate"), "Additional Doc", "");
    },

    handleTaskAction : function(component, event, helper) {
        var equipmentId = component.get("v.customerInformation.Id");
        var equipmentObject = component.get("v.equipmentUpdate");
        var oppId = component.get("v.customerInformation.Opportunity__r.Id");
        var equipmentUpdateDummy = component.get("v.customerInformation.Interconnection_Update_Dummy__c");
        var urlEvent = $A.get("e.force:navigateToURL");
        var taskName = event.getSource().get("v.class");
        var taskHelpText = event.getSource().get("v.labelClass");

        switch (taskName) {
            case 'Provide all System Information':
            case 'Provide All System Information':
                helper.openCustomerModal(component, event, helper);
                return;

            case 'Building Permit':
                helper.openBuildingPermitModal(component, event, helper);
                return;

            case 'Mechanical Installation':
                helper.openUploadWindow(component,"Date of Mechanical Installation:","Upload Proof of Mechanical Installation", equipmentId, oppId, null, "Mechanical Installation Documentation", taskHelpText);
                return;

            case 'Interconnection':
            case 'Report Interconnection to MCEC':
                if (component.get('v.customerInformation.Loan__r.State__c') === 'MA') {
                    urlEvent.setParams(
                    //SREC Form - more than a simple file upload (openUploadWindow), should be its own window or SREC onboarding component
                       {'url': 'https://forms.bluewaverenewables.com/381637'
                               + '?tfa_117=' + equipmentId
                               + '&tfa_118=' + !equipmentUpdateDummy
                               + '&tfa_107=' + oppId});
                    break;
                } else {
                    helper.openUploadWindow(component,"Date of Interconnection:","Upload Proof of Interconnection", equipmentId, oppId, null, "Interconnection Documentation", taskHelpText);
                    return;
                }
            case 'Provide Sales Agreement':
              helper.openUploadWindow(component,"hide","Upload Sales Agreement", oppId, oppId, null, "Sales Agreement", taskHelpText);
              return;
            default:
              break;
        }
        urlEvent.fire();
    },
    
    handleAfterFileUpload : function(component, event, helper) {
        helper.refreshPartnerTasks(component)                               
    },

    setInterconnectedTrue : function(component, event, helper) {
    },

    setInterconnectedFalse : function(component, event, helper) {
    },

    checkForOtherLabor : function(component, event, helper) {
        var laborPerformed = component.get('v.customerInformation.Labor_Performed__c');
        if (laborPerformed && laborPerformed.indexOf('Other') >= 0) {
            component.set('v.otherLaborPerformed', true);
        } else {
            component.set('v.otherLaborPerformed', false);
        }
    },

    checkForOtherMaterials : function(component, event, helper) {
        var materialsSupplied = component.get('v.customerInformation.Materials_Supplied__c');
        if (materialsSupplied && materialsSupplied.indexOf('Other') >= 0) {
            component.set('v.otherMaterialsSupplied', true);
        } else {
            component.set('v.otherMaterialsSupplied', false);
        }
    },

    handlePermitUpload : function(component, event, helper) {
        const equipment = component.get('v.customerInformation');
        helper.startSpinner(component, "buildingPermitUploadSpinner");
        helper.uploadFiles(component,
            event.getSource().get('v.files'),
            component.get('v.customerInformation.Id'),
            helper.getCustomerAttachments,
            'Building Permit',
            helper);
    },

    saveBuildingPermit : function(component, event, helper) {
        var re = component.get('v.customerInformation');
        if (!re.Labor_Performed__c  ||
            !re.Materials_Supplied__c ||
            !component.get('v.buildingPermits')) {
            alert('You must specify Labor Performed, Materials Supplied, and upload a building permit');
            return;
        }
        if ((component.get('v.otherLaborPerformed') &&
             !component.get('v.customerInformation.Other_Labor_Performed__c')) ||
            component.get('v.otherMaterialsSupplied') &&
            !component.get('v.customerInformation.Other_Materials_Supplied__c')) {
            alert('If selecting "Other", please describe the other Labor Performed or Materials Supplied');
            return;
        }
        helper.startSpinner(component, "buildingPermitSaveSpinner");
        $A.util.addClass(component.find("saveBuildingPermitModalButton"), 'noDisplay');
        $A.util.addClass(component.find("closeBuildingPermitModalButton"), 'noDisplay');

        var equipment = {
            sobjectType: 'Residential_Equipment__c',
            Id: re.Id,
            Labor_Performed__c: re.Labor_Performed__c,
            Other_Labor_Performed__c: component.get('v.otherLaborPerformed')?re.Other_Labor_Performed__c:'',
            Materials_Supplied__c: re.Materials_Supplied__c,
            Other_Materials_Supplied__c: component.get('v.otherMaterialsSupplied')?re.Other_Materials_Supplied__c:''
        };
        var updateAction = component.get("c.updateBuildingPermit");
        updateAction.setParams({
            "equipment" : equipment
        });

        updateAction.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.stopSpinner(component, "buildingPermitSaveSpinner");
                helper.confirmBuildingPermitSaved(component);
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(updateAction);
    },

    closeBuildingPermitModal : function(component, event, helper) {
        component.set('v.showBuildingPermitModal', false);
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');
        helper.refreshPartnerTasks(component);
    },

    enableRequestButton : function(component, event, helper) {
        const changeOrder = component.get('v.changeOrder');
        const equipment = component.get('v.customerInformation');
        if (component.get('v.docuSignPresent')) { // docusign already sent
            component.set('v.requestButtonText', 'Request Customer Authorization');
        } else {
            component.set('v.requestButtonText', 'Save');
        }
        if (equipment.Loan__r.Lead__r.System_Cost__c !== changeOrder.System_Cost__change ||
            equipment.Loan__r.Lead__r.System_Cost__c - equipment.Loan__r.Lead__r.Requested_Loan_Amount__c !== changeOrder.Down_Payment__change) {
            component.set('v.requestButtonText', 'Request Customer Authorization');
            component.set('v.requestButtonEnabled', true);
        } else if (equipment.Generator_Nameplate_Capacity__c != changeOrder.Generator_Nameplate_Capacity__change ||
                   equipment.Module_Manufacturer__c != changeOrder.Module_Manufacturer__change ||
                   equipment.Module_Model_Number__c != changeOrder.Module_Model_Number__change ||
                   equipment.Number_of_Modules__c != changeOrder.Number_of_Modules__change ||
                   equipment.Inverter_Manufacturer__c != changeOrder.Inverter_Manufacturer__change ||
                   equipment.Inverter_Model_Number__c != changeOrder.Inverter_Model_Number__change ||
                   equipment.Number_of_Inverters__c != changeOrder.Number_of_Inverters__change ||
                   equipment.Storage_Grid_Hybrid__c != changeOrder.Storage_Grid_Hybrid__change ||
                   equipment.Storage_Full_or_Partial_Home__c != changeOrder.Storage_Full_or_Partial_Home__change ||
                   equipment.Storage_Capacity__c != changeOrder.Storage_Capacity__change ||
                   equipment.Storage_Manufacturer__c != changeOrder.Storage_Manufacturer__change ||
                   equipment.Storage_Model__c != changeOrder.Storage_Model__change ||
                   equipment.Storage_Inverter_Manufacturer__c != changeOrder.Storage_Inverter_Manufacturer__change ||
                   equipment.Storage_Inverter_Model__c != changeOrder.Storage_Inverter_Model__change ||
                   (!equipment.Loan__r.Estimated_Completion_Date__c?'':helper.getFormattedDate(equipment.Loan__r.Estimated_Completion_Date__c)) != changeOrder.Estimated_Completion_date__change) {
            // Ignore types above so that undefined == null
            component.set('v.requestButtonEnabled', true);
        } else {
            component.set('v.requestButtonEnabled', false);
        }
    },

    saveAndRequestChangeOrder : function(component, event, helper) {
        const saveAction = component.get("c.saveChangeOrder");
        const changeOrder = component.get('v.changeOrder');
        changeOrder['Requested_Loan_Amount__change'] = changeOrder.System_Cost__change - changeOrder.Down_Payment__change;
        helper.startSpinner(component, "customerInformationSpinner");
        saveAction.setParams({
            "loanId" : component.get('v.customer.Loan__c'),
            "loanSystemInformation" : JSON.stringify(changeOrder)
        });

        saveAction.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                component.set('v.customerInformation', resp.getReturnValue());
                component.set('v.changeOrder', JSON.parse(resp.getReturnValue().Loan__r.Lead__r.Loan_System_Information__c));
                component.set("v.completionDateString", helper.getFormattedDate(resp.getReturnValue().Loan__r.Estimated_Completion_Date__c));
                helper.stopSpinner(component, "customerInformationSpinner");
                if (component.get('v.requestButtonText') === 'Request Customer Authorization') {
                    helper.confirmSystemInformationSaved(component, 'We have sent your request to ' + resp.getReturnValue().Loan__r.Lead__r.FirstName + ', thank you!');
                } else {
                    helper.confirmSystemInformationSaved(component, 'We have saved your System Information updates, thank you!');
                }
            } else {
                helper.logError('SLPCustomerController', 'saveChangeOrder', resp.getError(), component.get('v.customer'));
            }
        });
        $A.enqueueAction(saveAction);
    },
    
    withdrawChange : function(component, event, helper) {
        helper.startSpinner(component, "customerInformationSpinner");
        const withdrawAction = component.get("c.withdrawChangeOrder");
        withdrawAction.setParams({
            "loanId" : component.get('v.customer.Loan__c')
        });

        withdrawAction.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                component.set('v.customerInformation', resp.getReturnValue());
                helper.setChangeOrder(component, component.get('v.customerInformation'), helper);
                helper.stopSpinner(component, "customerInformationSpinner");
                helper.confirmSystemInformationSaved(component, "The Change Order has been withdrawn, and we've sent " + resp.getReturnValue().Loan__r.Lead__r.FirstName + " a notification.");b
            } else {
                helper.logError('SLPCustomerController', 'withdrawChangeOrder', resp.getError(), component.get('v.customer'));
            }
        });
        $A.enqueueAction(withdrawAction);
    },
})