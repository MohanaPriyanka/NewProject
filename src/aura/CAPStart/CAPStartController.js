({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, 'LoanConfirmation');
    },

    checkForEnter : function(component, event, helper) {
        if (event.getParams().keyCode == 13) {
            helper.login(component, event, helper);
        }
    },

    login : function(component, event, helper) {
        helper.login(component, event, helper);
    },

    confirmLoan : function(component, event, helper) {
        component.set('v.page', 'LoanDisclaimer');
    },

    approveChangeOrder : function(component, event, helper) {
        let rlaChange = component.get('v.changeOrder.Requested_Loan_Amount__change');
        component.set('v.approvedChange', true);
        if (component.get('v.warnOnMaxLoanAmount') &&
            !component.get('v.rlaOverMaxModalOpen') &&
            rlaChange &&
            rlaChange > component.get('v.maxLoanAmount')) {
            component.set('v.rlaOverMaxModalOpen', true);
            helper.showModal(component, 'rlaOverMaxModal');
        } else {
            helper.approveChangeOrderInner(component, event, helper);
            helper.hideModal(component, 'rlaOverMaxModal');
            component.set('v.rlaOverMaxModalOpen', false);
        }
    },

    cancelApprovalConfirmation : function(component, event, helper) {
        helper.hideModal(component, 'rlaOverMaxModal');
        component.set('v.rlaOverMaxModalOpen', false);
    },

    openRejectReason : function(component, event, helper) {
        component.set('v.rejectChangeOrder', true);
    },

    cancelRejection : function(component, event, helper) {
        component.set('v.rejectChangeOrder', false);
    },

    rejectChangeOrder : function(component, event, helper) {
        if (!component.get('v.changeOrder.Reject_Reason')) {
            alert('Please provide your installer information about why you are rejecting this change.');
            return;
        }
        const lead = component.get('v.lead');
        const rejectChangeOrder = component.get('c.setRejectedChangeOrder');
        rejectChangeOrder.setParams({
            "leadId": lead.Id,
            "email": lead.Email,
            "loanSystemInformation": JSON.stringify(component.get('v.changeOrder'), null, '  ')
        });
        rejectChangeOrder.setCallback(this, function(result) {
            if (result.getState() === 'SUCCESS') {
                component.set('v.approvedChange', false);
                component.set('v.rejectChangeOrder', false);
                component.set('v.rejectionConfirmed', true);
                helper.showModal(component, 'changeOrderConfirmation');
            } else {
                helper.logError('CAPStartController', 'rejectChangeOrder', 'Could not reject change order, call BlueWave Customer Care', result);
            }
        });
        $A.enqueueAction(rejectChangeOrder);
    },

    changeOrderFinished : function(component, event, helper) {
        let lead = component.get('v.lead');
        helper.hideModal(component, 'changeOrderConfirmation');
        if (lead.CAP_Stage__c === 'NAV_Income_Doc') {
            // Don't do anything, they should close the window
        } else if (lead.CAP_Stage__c !== '') {
            component.set('v.page', '');
            helper.raiseNavEvent("COMPLETED", {
                "stageName": lead.CAP_Stage__c,
                "lead": lead,
                "contractSent": component.get('v.contractSent'),
                "systemInfoComplete": component.get('v.systemInfoComplete')
            });
        } else {
            component.set('v.page', 'LoanConfirmation');
            component.set('v.lead', lead);
        }
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})