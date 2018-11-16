({
   login : function(component, event, helper) {
        var action = component.get('c.getLeadWrapper');
        action.setParams({
            "leadId": component.get('v.leadId'),
            "email" : component.get('v.leadEmail')
        });
        action.setCallback(this, function(actionResult) {
            if (actionResult.getReturnValue() != null) {
                let lead = actionResult.getReturnValue().lead;
                lead.Attachments = actionResult.getReturnValue().attachments;
                let contractSent = actionResult.getReturnValue().contractSent;
                component.set('v.contractSent', contractSent);
                let systemInfoComplete = actionResult.getReturnValue().systemInfoComplete;
                component.set('v.systemInfoComplete', systemInfoComplete);
                component.set('v.warnOnMaxLoanAmount', actionResult.getReturnValue().warnOnMaxLoanAmount);
                if (lead.Product__c) {
                    if (lead.Product__r.Lender_of_Record__c !== 'BlueWave') {
                        helper.raiseNavEvent("LORCHANGE", {"lenderOfRecord": lead.Product__r.Lender_of_Record__c});
                    }
                } else {
                    var lorAction = component.get('c.getLenderOfRecord');
                    lorAction.setParams({'state': lead.LASERCA__Home_State__c});
                    lorAction.setCallback(this, function(result) {
                        var lor = result.getReturnValue();
                        if (lor !== 'BlueWave') {
                            helper.raiseNavEvent("LORCHANGE", {"lenderOfRecord": lor});
                        }
                    });
                    $A.enqueueAction(lorAction);
                }
                if (lead.Personal_Credit_Report__c) {
                    helper.raiseNavEvent('LOCKPI');
                }
                if (lead.Personal_Credit_Report_Co_Applicant__c) {
                    helper.raiseNavEvent('LOCKJOINT');
                }
                if (lead.Change_Order_Status__c === 'Requested') {
                    component.set('v.lead', lead);
                    helper.getSalesPartnerInfo(component, event, helper);
                    helper.showChangeConfirm(component, event, helper);
                } else {
                    if (lead.CAP_Stage__c !== '') {
                        component.set('v.page', '');
                        helper.raiseNavEvent('COMPLETED', {
                            'stageName': lead.CAP_Stage__c,
                            'lead': lead,
                            'contractSent': contractSent,
                            'systemInfoComplete': systemInfoComplete
                        });
                    } else {
                        component.set('v.page', 'LoanConfirmation');
                        component.set('v.lead', lead);
                    }
                }
            } else {
                alert('Incorrect email address. Please verify your email address.');
            }
        });

        $A.enqueueAction(action);
    },

    showChangeConfirm : function(component, event, helper) {
        const lead = component.get('v.lead');
        const getChangeInfo = component.get('c.getEquipment');
        getChangeInfo.setParams({'leadId': lead.Id});
        getChangeInfo.setCallback(this, function(result) {
            if (result.getState() === 'SUCCESS') {
                const equipment = result.getReturnValue();
                component.set('v.changeOrder', JSON.parse(lead.Loan_System_Information__c));
                component.set('v.equipment', equipment);
                component.set('v.maxLoanAmount', equipment.Lead__r.Maximum_monthly_Disbursement__c);
                if (equipment.Loan__r.Estimated_Completion_Date__c) {
                    component.set('v.completionDateString', helper.getFormattedDate(equipment.Loan__r.Estimated_Completion_Date__c));
                } else {
                    component.set('v.completionDateString', '');
                }
                //The value for grid hybrid is a Boolean in the database and a string ('Yes' or 'No') in the form
                if (component.get('v.changeOrder.Storage_Grid_Hybrid__change') === 'Yes') {
                    component.set('v.storageGridHybridStringToBoolean', true);
                }
                component.set('v.page', 'ChangeOrderConfirmation');
            } else {
                helper.logError('CAPStartHelper', 'showChangeConfirm', 'Couldn\'t get change order information');
            }
        });
        $A.enqueueAction(getChangeInfo);
    },

    getSalesPartnerInfo : function(component, event, helper) {
        const getSalesPartnerInfoAction = component.get('c.getSalesPartner');
        getSalesPartnerInfoAction.setParams({'bsstId': component.get('v.lead').bs_Sales_ID__c});
        getSalesPartnerInfoAction.setCallback(this, function(result) {
            if (result.getState() === 'SUCCESS' && result.getReturnValue() != null) {
                component.set('v.partnerPhone', result.getReturnValue().Phone);
                component.set('v.partnerMobilePhone', result.getReturnValue().MobilePhone);
            } else {
                helper.raiseError('CAPStartHelper', 'getSalesPartnerInfo', 'Couldn\'t get sales partner info', result, {suppressAlert: true});
            }
        });
        $A.enqueueAction(getSalesPartnerInfoAction);
    },

    approveChangeOrderInner : function(component, event, helper) {
        const lead = component.get('v.lead');
        const acceptChangeOrder = component.get('c.setApprovedChangeOrder');
        acceptChangeOrder.setParams({
            "leadId": lead.Id,
            "email": lead.Email
        });
        acceptChangeOrder.setCallback(this, function(result) {
            if (result.getState() === 'SUCCESS') {
                helper.showModal(component, 'changeOrderConfirmation');
            } else {
                helper.logError('CAPStartController', 'approveChangeOrder', 'Could not set Change Order Status, call BlueWave Customer Care', result.getError());
            }
        });
        $A.enqueueAction(acceptChangeOrder);
    },

    showModal : function(component, modalName) {
        $A.util.addClass(component.find(modalName), 'slds-fade-in-open');
        $A.util.addClass(component.find('modalBackDrop'), 'slds-backdrop');
    },

    hideModal : function(component, modalName) {
        $A.util.removeClass(component.find(modalName), 'slds-fade-in-open');
        $A.util.removeClass(component.find('modalBackDrop'), 'slds-backdrop');
    },
})