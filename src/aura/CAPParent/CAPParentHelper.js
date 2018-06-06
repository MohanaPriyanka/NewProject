({
    getStage : function(stageName) {
        var stageMap = new Map();
        stageMap.set('NAV_Getting_Started', 0);
        stageMap.set('NAV_Personal_Information', 1);
        stageMap.set('NAV_Credit_Check', 2);
        stageMap.set('NAV_Confirmations', 3);
        stageMap.set('NAV_Income_Doc', 4);
        stageMap.set('NAV_Complete', 5);
        stageMap.set(0, 'NAV_Getting_Started');
        stageMap.set(1, 'NAV_Personal_Information');
        stageMap.set(2, 'NAV_Credit_Check');
        stageMap.set(3, 'NAV_Confirmations');
        stageMap.set(4, 'NAV_Income_Doc');
        stageMap.set(5, 'NAV_Complete');
        if (stageMap.get(stageName) != undefined) {
            return stageMap.get(stageName);
        } else {
            return -1;;
        }
    },

    raiseNavEvent : function(eventType, options) {
        var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
        stageChangeEvent.setParams({"eventType": eventType});
        if (options) {
            if (options.hasOwnProperty("stageName")) {
                stageChangeEvent.setParams({"stageName": options.stageName});
            }
            if (options.hasOwnProperty("lead")) {
                stageChangeEvent.setParams({"lead": options.lead});
            }
            if (options.hasOwnProperty("lenderOfRecord")) {
                stageChangeEvent.setParams({"lenderOfRecord": options.lenderOfRecord});
            }
            if (options.hasOwnProperty("contractSent") || options.hasOwnProperty("systemInfoComplete")) {
                let eventOptions = {};
                if (options.hasOwnProperty("contractSent")) {
                    eventOptions.contractSent = options.contractSent;
                }
                if (options.hasOwnProperty("systemInfoComplete")) {
                    eventOptions.systemInfoComplete = options.systemInfoComplete;
                }
                stageChangeEvent.setParams({"options": eventOptions});
            }
        }
        stageChangeEvent.fire();
    },

    handleNavEvent : function(component, event, helper, defaultPage) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            component.set('v.page', defaultPage);
            component.set('v.supressWaiting', false);
            if (event.getParam('options') && event.getParam('options').hasOwnProperty('contractSent')) {
                component.set('v.contractSent', event.getParam('options').contractSent);
            }
            if (event.getParam('options') && event.getParam('options').hasOwnProperty('systemInfoComplete')) {
                component.set('v.systemInfoComplete', event.getParam('options').systemInfoComplete);
            }
        } else if ((event.getParam("eventType") === "INITIATED" &&
                    event.getParam("stageName") !== component.get("v.STAGENAME")) || 
                   event.getParam("eventType") === "COMPLETED") {
            component.set('v.page', '');
            component.set('v.supressWaiting', true);
        } else if (event.getParam("eventType") === "LORCHANGE") {
            component.set('v.lenderOfRecord', event.getParam('lenderOfRecord'));
        }
    },

    getNextStageIndex : function(stageName, helper) {
        return helper.getStage(stageName) + 1;
    },

    getNextStageName : function(stageName, helper) {
        return helper.getStage(helper.getNextStageIndex(stageName));
    },

    setAppType : function(component, event, helper) {
        const self = this;
        return new Promise(function(resolve, reject) {
            const lead = helper.cleanLead(component);
            const action = component.get('c.setAppType');
            action.setParams({'capLead': lead});
            action.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    if (lead.Application_Type__c === 'Individual') {
                        self.removeCoAppInfo(component.get('v.lead'));
                    }
                    component.set('v.page', 'PrimaryPI');
                    resolve();
                } else {
                    self.logError('CAPParentHelper', 'setAppType', 'Error saving application type', resp);
                    reject();
                }
            });
            $A.enqueueAction(action);
        });
    },

    removeCoAppInfo : function(lead, leadClone) {
        if (leadClone) {
            leadClone.CoApplicant_Contact__c = null;
            leadClone.Co_Applicant_First_Name__c = null;
            leadClone.Co_Applicant_Last_Name__c = null;
            leadClone.Co_Applicant_Phone__c = null;
            leadClone.Co_Applicant_Email__c = null;
            leadClone.Co_Applicant_Date_of_Birth__c = null;
            leadClone.Co_Applicant_Income__c = null;
            leadClone.Co_Applicant_Address__c = null;
            leadClone.Co_Applicant_Income__c = null;
        }
        if (lead) {
            delete lead['CoApplicant_Contact__c'];
            delete lead['CoApplicant_Contact__r'];
            delete lead['CoApplicant_Contact__c'];
            delete lead['Co_Applicant_First_Name__c'];
            delete lead['Co_Applicant_Last_Name__c'];
            delete lead['Co_Applicant_Phone__c'];
            delete lead['Co_Applicant_Email__c'];
            delete lead['Co_Applicant_Date_of_Birth__c'];
            delete lead['Co_Applicant_Income__c'];
            delete lead['Co_Applicant_Address__c'];
            delete lead['Co_Applicant_Income__c'];
        }
    },

    cleanLead : function(component) {
        const lead = component.get('v.lead');
        const leadClone = JSON.parse(JSON.stringify(lead));
        if (lead.Residence_Owner__c) {
            leadClone.Residence_Owner__c = 'true';
        } else {
            leadClone.Residence_Owner__c = 'false';
        }
        delete leadClone['CoApplicant_Contact__r'];
        delete leadClone['Product__r'];
        delete leadClone['SREC_Product__r'];
        if (lead.LASERCA__Birthdate__c) {
            leadClone.LASERCA__Birthdate__c = lead.LASERCA__Birthdate__c.replace(/T00:00:00.000Z/,"");
        }
        return leadClone;
    },

    finishStage : function(component, event, helper) {
        var lead = component.get('v.lead');
        var stageName = component.get("v.STAGENAME");
        var currentMaxStage = lead.CAP_Stage__c;
        if (currentMaxStage == null ||
            helper.getStage(stageName) > helper.getStage(currentMaxStage)) {
            lead.CAP_Stage__c = stageName;
            var promise = helper.saveSObject(component, lead.Id, 'Lead', 'CAP_Stage__c', stageName);
            promise.then($A.getCallback(function resolve(value) {
                helper.closePageFireComplete(component, helper, stageName, lead);
            }));
        } else {
            helper.closePageFireComplete(component, helper, stageName, lead);
        }
    },

    closePageFireComplete : function(component, helper, stageName, lead) {
        component.set('v.page', 'Done');
        var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
        stageChangeEvent.setParams({"stageName": stageName});
        stageChangeEvent.setParams({"eventType": "COMPLETED"});
        stageChangeEvent.setParams({"lead": lead});
        stageChangeEvent.setParams({"options": {"systemInfoComplete": component.get('v.systemInfoComplete')}});
        stageChangeEvent.fire();
    },

    // We want to go to the database to get whether there's a contract out, since
    // the contract might have been sent out between pre-qual and completion
    setContractSent : function(component, event, helper) {
        const self = this;
        return new Promise(function(resolve, reject) {
            const lead = component.get('v.lead');
            const action = component.get('c.getLead');
            action.setParams({
                'leadId': lead.Id,
                'email': lead.Email
            });
            action.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    resp.getReturnValue().Partner_Tasks__r.forEach(function(task) {
                        if (task.Name === 'Obtain Contract Signature') {
                            if (task.Status__c === 'Incomplete') {
                                component.set('v.contractSent', false);
                            } else {
                                component.set('v.contractSent', true);
                            }
                        }
                    });
                    resolve();
                } else {
                    self.logError('CAPParentHelper', 'setContractSent', 'Error getting lead', resp.getError());
                    reject();
                }
            });
            $A.enqueueAction(action);
        });
    },
})
