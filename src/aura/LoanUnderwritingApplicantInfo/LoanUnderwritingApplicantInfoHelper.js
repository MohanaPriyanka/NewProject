/**
 * Created by Sarah Renfro on 10/11/2018.
 */
({
    initHelper : function(component, event) {
        return new Promise(function(resolve, reject) {
            var pcrId = component.get("v.pcr").Id;
            var lead = component.get("v.lead");
            var isCoApp = component.get("v.isCoApp");
            var action = component.get("c.getPCRDebt");
            action.setParams({"pcrId" : pcrId});
            action.setCallback(this,function(resp) {
                if (resp.getState() == 'SUCCESS') {
                    var pcr = resp.getReturnValue();
                    component.set("v.alertMessage", pcr.LASERCA__TransUnion_Alert_Message__c);
                    if (!isCoApp) {
                        component.set("v.avidiaProv", lead.Avidia_Service_Provider__c);
                        component.set("v.otherExec", lead.Other_Bank_Executive__c);
                        component.set("v.typeExec", lead.Type_of_Avidia_Service_Provider__c);
                    }
                    resolve(pcr);
                } else {
                    helper.logError('LoanUnderwritingApplicantInfoController','initHelper', resp.getError());
                    reject(Error(resp.getError()));
                }
            });
            $A.enqueueAction(action);
        });
    },
    getCoAppContact : function(component) {
        return new Promise(function(resolve, reject) {
            var lead = component.get("v.lead");
            var action = component.get("c.getCoAppContact");
            action.setParams({"lead" : lead});
            action.setCallback(this,function(resp){
                if (resp.getState() == 'SUCCESS') {
                    var contact = resp.getReturnValue();
                    component.set("v.avidiaProv", contact.Avidia_Service_Provider__c);
                    component.set("v.otherExec", contact.Other_Bank_Executive__c);
                    component.set("v.typeExec", contact.Type_of_Avidia_Service_Provider__c);
                } else {
                    helper.logError('LoanUnderwritingApplicantInfoController','getCoAppContact', resp.getError());
                    reject(Error(resp.getError()));
                }
            });
            $A.enqueueAction(action);
        });
    },
    getOFAC : function(component) {
        return new Promise(function (resolve, reject) {
            var pcrId = component.get("v.pcr").Id;
            var action = component.get("c.getOFAC");
            action.setParams({"pcrId": pcrId});
            action.setCallback(this, function (resp) {
                if (resp.getState() == 'SUCCESS') {
                    var ofac = resp.getReturnValue();
                    component.set("v.ofac", ofac);
                } else {
                    helper.logError('LoanUnderwritingApplicantInfoController','getOFAC', resp.getError());
                    reject(Error(resp.getError()));
                }
            });
            $A.enqueueAction(action);
        });
    }
})