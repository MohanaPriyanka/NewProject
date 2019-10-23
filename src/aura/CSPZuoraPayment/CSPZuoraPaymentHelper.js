({
    doInItHelper : function(component, event, helper) {
        let actionGetBalance = component.get("c.getAccountAndPayMethodFromZuora");

        actionGetBalance.setParams({
            "sfAccountId" : component.get("v.sfAccountId")
        });

        actionGetBalance.setCallback(this,function(resp) {
            let errorMessage;
            if (resp.getState() === 'SUCCESS') {
                let zuoraAcct = resp.getReturnValue();
                component.set("v.zuoraAccountAndPayMethod", zuoraAcct);

                let accountBalance = Math.max(zuoraAcct.account.Balance,0);
                component.set("v.paymentAmount", accountBalance);

                let ButtonOptions = component.get("v.RadioOptions");
                let fullBalanceLabel = ButtonOptions[0].label.replace('$$', '$' + accountBalance);
                ButtonOptions[0].label = fullBalanceLabel;
                component.set("v.RadioOptions", ButtonOptions);

                this.pickCardToOpenOn(component, event, helper, zuoraAcct.account.AutoPay);

                if (zuoraAcct.account.AutoPay === false) {
                    component.set("v.currentPaymentMethod", 'Enter new');
                    component.set("v.forceAutopaySelection", true);
                    component.set("v.newAutopaySelection", false);
                } else if (zuoraAcct.paymentMethod.Type === 'CreditCard' && zuoraAcct.account.AutoPay === true) {
                    component.set("v.currentPaymentMethod", zuoraAcct.paymentMethod.CreditCardMaskNumber);
                    component.set("v.newPaymentMethodId",zuoraAcct.paymentMethod.Id);
                    component.set("v.AutopayAgree", true);
                    component.set("v.newAutopaySelection", true);
                } else if (zuoraAcct.paymentMethod.Type === 'ACH' && zuoraAcct.account.AutoPay === true){
                    component.set("v.currentPaymentMethod", zuoraAcct.paymentMethod.AchAccountNumberMask);
                    component.set("v.newPaymentMethodId",zuoraAcct.paymentMethod.Id);
                    component.set("v.AutopayAgree", true);
                    component.set("v.newAutopaySelection", true);
                } else {
                    errorMessage = 'A system error occurred while loading your account. Please try again.';
                    this.finishAndShowMessage(component, event, helper, errorMessage);
                }
                this.checkAllRequiredFields(component, event, helper);
            } else {
                errorMessage = 'A system error occurred while loading your account. Please try again.';
                this.finishAndShowMessage(component, event, helper, errorMessage);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(actionGetBalance);
    },

    pickCardToOpenOn : function(component, event, helper, autopayBoolean) {
        let pageType = component.get("v.makePaymentOrManageAutopay");
        if (autopayBoolean === true && pageType){
            // if already on autopay and making a payment, don't give option to go off
            // start on payment amount card
            component.set("v.showAutopaySection", false);
            component.set("v.showCardPaymentAmount", true);
        } else if (autopayBoolean === false){
            // if not on autopay, start on autopay card
            component.set("v.showCardAutopay", true);
        } else {
            this.openPaymentMethodCard(component, event, helper);
        }
    },

    handleAutopayChange : function(component, event, helper) {
        let selectedOption = component.find("autopayOption").get("v.value");
        if (selectedOption === 'Yes'){
            component.set("v.newAutopaySelection", true);
            component.set("v.forceAutopaySelection", false);
        } else if (selectedOption === 'No'){
            component.set("v.newAutopaySelection", false);
            component.set("v.forceAutopaySelection", false);
            component.set("v.AutopayAgree",false);
        } else {
            component.set("v.forceAutopaySelection", true);
        }
        this.checkAllRequiredFields(component, event, helper);
    },

    handlePaymentAmountChange : function(component, event, helper) {
        let ratioButtons = component.find("radioButtonPaymentAmount").get("v.value");
        let zAcctBalance = component.get("v.zuoraAccountAndPayMethod").account.Balance;
        component.set("v.customPaymentAmountMessage", '');

        if (ratioButtons === 'customAmount'){
            let customPaymentAmount = component.get("v.customChargeAmount");
            component.set("v.paymentAmount", Math.max(0,Math.min(customPaymentAmount,zAcctBalance)));
            if (customPaymentAmount < 0) {
                component.set("v.customPaymentAmountMessage", 'Payment amount must be greater than zero.');
            } else if (customPaymentAmount > zAcctBalance) {
                component.set("v.customPaymentAmountMessage", 'Payment amount can not be more than your current outstanding balance.');
            }
        } else {
            component.set("v.paymentAmount", Math.max(0,zAcctBalance));
        }
        this.checkAllRequiredFields(component, event, helper);
    },

    checkAllRequiredFields : function(component, event, helper) {
        let check_ForceAutopaySelection = component.get("v.forceAutopaySelection");
        let check_AutopayDisclaimerAgree = component.get("v.AutopayAgree");
        let check_AutopaySelection = component.get("v.autopayAsText");
        let check_PaymentAmount = component.get("v.paymentAmount");
        let check_PaymentMethodId = component.get("v.newPaymentMethodId");
        let check_MakeAPaymentPage = component.get("v.makePaymentOrManageAutopay");
        let check_AutopayIsOn = component.get("v.newAutopaySelection");

        this.disableButton(component, event, helper);

        if (check_ForceAutopaySelection === true) {
            component.set("v.missingFieldsMessage", 'You must indicate if you would like to enroll in autopay.');
        } else if (check_AutopayDisclaimerAgree === false && check_AutopaySelection === 'Yes') {
            component.set("v.missingFieldsMessage", 'You must agree to the terms if you would like to be enrolled in autopay');
        } else if (check_MakeAPaymentPage === true && check_PaymentAmount < 0.01){
            // We do not expect a customer to see this error. The make a payment button should be hidden if balance = $0
            component.set("v.missingFieldsMessage", 'You can not make a payment for $0. If you would like to modify your autopay method, please do so from the My Account page.');
        } else if (typeof check_PaymentMethodId === 'undefined' && check_MakeAPaymentPage === true){
            component.set("v.missingFieldsMessage", 'You must supply a payment method to make a payment.');
        } else if (typeof check_PaymentMethodId === 'undefined' && check_MakeAPaymentPage === false && check_AutopayIsOn === true){
            component.set("v.missingFieldsMessage", 'You must supply a new payment method to change autopay');
        } else {
            component.set("v.missingFieldsMessage", '');
            this.closeMethodEnableButton(component, event, helper);
        }
    },

    sendToZuoraHelper : function(component, event, helper) {
        component.set("v.showSpinner", true);
        let payPageOrManageAuto = component.get("v.makePaymentOrManageAutopay");

        if (payPageOrManageAuto === true){
            this.makeZPayment(component, event, helper);
        } else {
            this.modifyAutopay(component, event, helper, 'Your account has been updated successfully.');
        }
        component.set("v.showSpinner", false);
    },

    finishAndShowMessage : function(component, event, helper, message) {
        component.set("v.showPostSubmitPage", true);
        component.set("v.responseMessage", message);
    },

    modifyAutopay : function(component, event, helper, successMessage) {
        let actionUpdateZuoraAccount = component.get("c.toggleAutopayAndPaymentMethod");

        actionUpdateZuoraAccount.setParams({
            "zuoraAccountId" : component.get("v.zuoraAccountAndPayMethod.account.Id"),
            "autopaySelection" : component.get("v.newAutopaySelection"),
            "paymentMethodId" : component.get("v.newPaymentMethodId")
        });

        actionUpdateZuoraAccount.setCallback(this,function(resp) {
            let responseMessage;
            if (resp.getState() === 'SUCCESS') {
                let booleanSuccess = resp.getReturnValue();
                if (booleanSuccess === true) {
                    responseMessage = successMessage;
                } else {
                    responseMessage = 'An error has occurred, we were unable to update your account. We have been notified and will contact you with further instructions.';
                }
            } else {
                responseMessage = 'An error has occurred, we were unable to update your account. We have been notified and will contact you with further instructions.';
            }
            this.finishAndShowMessage(component, event, helper, responseMessage);
        });
        $A.enqueueAction(actionUpdateZuoraAccount);
    },

    makeZPayment : function(component, event, helper) {
        let actionMakePayment = component.get("c.makePayment");
        let oldAutopayValue = component.get("v.zuoraAccountAndPayMethod.account.AutoPay");
        let newAutopayValue = component.get("v.newAutopaySelection");

        actionMakePayment.setParams({
            "zuoraAcctId" : component.get("v.zuoraAccountAndPayMethod.account.Id"),
            "gatewayId" : component.get("v.zuoraAccountAndPayMethod.account.PaymentGateway"),
            "paymentMethodId" : component.get("v.newPaymentMethodId"),
            "paymentAmount" : component.get("v.paymentAmount")
        });

        actionMakePayment.setCallback(this,function(resp) {
            let responseMessage;

            if (resp.getState() === 'SUCCESS') {
                let paymentResponse = resp.getReturnValue();
                if (paymentResponse.status === 'Processed') {
                    if (oldAutopayValue === false && newAutopayValue === true){
                        /*
                            If also signing up for autopay, update default payment method on account
                            Only want to do this if the payment went through
                            Also ensures that if they are already on autopay, we don't change default payment method
                            ie, they can make a one-time payment with a different pay method
                        */
                        this.modifyAutopay(component, event, helper, 'Your payment has been approved.');
                    } else {
                        responseMessage = 'Your payment has been approved.';
                    }
                } else {
                    responseMessage = 'Payment Failed: ' + paymentResponse.gatewayResponse;
                }
            } else {
                responseMessage = 'A system error has occurred, we were unable to submit your payment. We have been notified and will contact you with further instructions.';
            }
            this.finishAndShowMessage(component, event, helper, responseMessage);
        });
        $A.enqueueAction(actionMakePayment);
    },

    linkPayMethodToAccount : function(component, event, helper) {
        let actionLinkMethod = component.get("c.linkPaymentMethodToAccount");

        actionLinkMethod.setParams({
            "zuoraAccountId" : component.get("v.zuoraAccountAndPayMethod.account.Id"),
            "paymentMethodId" : component.get("v.newPaymentMethodId")
        });

        actionLinkMethod.setCallback(this,function(resp) {
            let errorMessage;
            if (resp.getState() === 'SUCCESS') {
                let booleanSuccess = resp.getReturnValue();
                if (booleanSuccess === false) {
                    errorMessage = 'A system error occurred while submitting your payment method. We have been notified and will contact you with further instructions.';
                    this.finishAndShowMessage(component, event, helper, errorMessage);
                }
            } else {
                errorMessage = 'A system error occurred while submitting your payment method. We have been notified and will contact you with further instructions.';
                this.finishAndShowMessage(component, event, helper, errorMessage);
            }
        });

        $A.enqueueAction(actionLinkMethod);
    },

    closeMethodEnableButton : function(component, event, helper) {
        component.set("v.showEnabledButton", true);
    },

    disableButton : function(component, event, helper) {
        component.set("v.showEnabledButton", false);
    },

    openPaymentMethodCard : function(component, event, helper) {
        component.set("v.showCardPaymentMethod",true);
        let unSelected = component.get("v.currentPaymentMethod");
        if (unSelected === 'Enter new'){
            component.set("v.userSelectedPaymentMethod",'ACH');
            this.generateIFrame(component, event, helper);
        }
    },

    // Closing and Opening the payment method card has the same effect as re-creating the ZuoraPaymentPage component.
    // Do this to prevent the bug where a customer switches between ACH and CC and the I frame doesn't reload:
    refreshIFrame : function(component, event, helper) {
        component.set("v.showCardPaymentMethod",false);
        component.set("v.showCardPaymentMethod",true);
        this.generateIFrame(component, event, helper);
    },

    generateIFrame : function(component, event, helper) {
        component.set("v.zuoraIsLoading",true);

        // Gives time for the Zuora Payment Page I-Frame to load. Ideally the timeout would not be a hard coded:
        window.setTimeout(function() {
            component.set("v.newPaymentMethodType", component.get("v.userSelectedPaymentMethod"));
        }, 2000);
        window.setTimeout(function() {
            component.set("v.zuoraIsLoading",false);
        }, 2500);
    },
})