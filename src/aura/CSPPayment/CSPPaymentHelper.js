({
    checkInputs : function(component, inputFields) { 
        var paymentMethod = component.get("v.SelectedPaymentMethod");
        component.set("v.ErrorText","Please fill out all required fields. ");
        component.set("v.showErrorText", false);

        if (paymentMethod === "ACH") {
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Bank_Name__c,'BankName',2, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Bank_Routing_Number__c,'BankRouting', 9, 'Your bank routing number should be 9 digits.');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Bank_Account_Type__c, 'BankAccountType', 7, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Bank_Account_Number__c, 'BankAccountNumber', 2, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Bank_Account_Name__c,'BankAccountName', 2, '');
        } else {
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Card_Type__c, 'CCType', 4, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Card_Number__c, 'CCNumber', 15, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Card_Expiration_Month__c, 'ExpyMonth', 1, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Card_Expiration_Year__c, 'ExpyYear', 4, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Billing_Zip_Postal__c, 'BillingZipcode', 5, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Billing_First_Name__c, 'FirstName', 2, '');
            this.checkFieldIsPopulated(component, inputFields.ChargentOrders__Billing_Last_Name__c, 'LastName', 2, '');
            if (inputFields.ChargentOrders__Card_Number__c.length > 16) {
                this.addErrorAnimation(component, 'CCNumber');
                this.unhideFieldsShowError(
                    component,
                    'Your ' + inputFields.ChargentOrders__Card_Type__c +
                    ' number is too long. Please use numbers only, no spaces');
            }
        }

        // Because it is a picklist, v.Autopay & v.ACH are stored as text:
        if (component.get("v.Autopay") === 'Select'){
            console.log('AUTOPAY');
            this.unhideFieldsShowError(component, component.get("v.ErrorText") + 'Please select if you would like to sign up for autopay.');
            this.addErrorAnimation(component,'mustAgree');
        } else if (!component.get("v.AutopayAcknowledgement") && component.get("v.Autopay") === 'true') {
            this.unhideFieldsShowError(component, component.get("v.ErrorText") + 'You must acknowledge the autopay disclaimer to sign up for Autopay.');
            this.addErrorAnimation(component,'mustAgree');
        }
        if ((component.get("v.StaticTotalDue") < component.get("v.DynamicTotalDue"))){
            this.unhideFieldsShowError(component, component.get("v.ErrorText") + ' Payment amount cannot be more than is due.');
            this.addErrorAnimation(component,'paymentAmount');
        } else {
            this.checkFieldIsPopulated(component, component.get("v.DynamicTotalDue"),'paymentAmount',1, '');
        }

        var errorsExist = component.get("v.showErrorText");
        return errorsExist; 
    },


    addErrorAnimation : function(component, fieldName) { 
        $A.util.addClass(component.find(fieldName), 'slds-has-error'); 
    },

    removeErrorAnimation : function(component, fieldName) { 
        $A.util.removeClass(component.find(fieldName), 'slds-has-error');
    },
    
    checkFieldIsPopulated : function(component, fieldValue, fieldName, minLength, additionalErrorText) { 
        if (fieldValue === null) {
            this.addErrorAnimation(component, fieldName);
            this.unhideFieldsShowError(component, component.get("v.ErrorText"));
        } else if (fieldValue.length < minLength) {
            this.addErrorAnimation(component, fieldName);
            this.unhideFieldsShowError(component, component.get("v.ErrorText"));
        } else {
            this.removeErrorAnimation(component, fieldName);
        }
    },

    unhideFieldsShowError : function(component, errorMessageText) { 
        // allows for resubmittal 
        component.set("v.ErrorText",  errorMessageText);   
        component.set("v.showErrorText", true);
        component.set("v.hideFields", false);
        component.set("v.Spinner", false);
    },

    showFinalError : function(component, errorMessageText) { 
        // does NOT allow for resubmittal 
        component.set("v.ResponseText",  'An error has occurred, but do not resubmit payment. We have been notified and will contact you with further instructions');   
        component.set("v.Spinner", false); 
    },

    showApproved : function(component) { 
        component.set("v.Spinner", false); 
        component.set("v.ResponseText",  'Payment approved. You will recieve an email from BlueWave momentarily.');   
    },

    showOrderCreated : function(component) {
        component.set("v.Spinner", false);
        component.set("v.ResponseText",  'Your payment data has been saved. You will receive an email from BlueWave momentarily.');
    },

    insertOrders : function(component, chargentFields, helper){
        return new Promise(function(resolve, reject) {
            component.set("v.readyToChargeOrders", []);
            component.set("v.showErrorText", false);
            component.set("v.hideFields", true);
            component.set("v.Spinner", true);
            var orderList = component.get("v.BillsToCharge"); 
            var paymentPercent = component.get("v.DynamicTotalDue")/component.get("v.StaticTotalDue");

            var ordersToInsertList = [];
            var orderStep;

            for (orderStep = 0; orderStep < orderList.length; orderStep++) {
                var paymentAmount = (orderList[orderStep].ChargentOrders__Subtotal__c * paymentPercent).toFixed(2);
                if(isNaN(paymentAmount)){
                    paymentAmount = 0;
                }
                if (paymentAmount >= 0) {
                    var chargentOrder = {
                        sobjectType : 'ChargentOrders__ChargentOrder__c',
                        Account_Bill__c : orderList[orderStep].Account_Bill__c,
                        ChargentOrders__Subtotal__c : paymentAmount,
                        Entity__c : orderList[orderStep].Entity__c
                    };
                    ordersToInsertList.push(chargentOrder);
                }
            }
              
            var actionSubmit = component.get("c.setChargeAmountAndInsert");  

            actionSubmit.setParams({
                "chargeAmounts": ordersToInsertList,
                "orderInput": chargentFields,
                "autopay" : component.get("v.AutopayAcknowledgement")

            });

            actionSubmit.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    resolve('continue');
                    component.set("v.readyToChargeOrders", resp.getReturnValue());
                } else {
                    component.set("v.Spinner", false);
                    chargentFields.ChargentOrders__Card_Number__c = '(removed)';
                    helper.raiseError(
                        'CSPPaymentHelper',
                        'insertOrders',
                        resp.getState() + ' caught: ' + JSON.stringify(resp.getError(), null, 2),
                        JSON.stringify(actionSubmit.getParams()),
                        {suppressAlert: true}
                    );
                    helper.showFinalError(component);
                }
            });   
            $A.enqueueAction(actionSubmit);  
        });
    },

    /*  The Chargent API will only allow the "Charge" functionality for one order passed at a time
        This submits one order to the database at a time so as to avoid that limit 
    */

    submitPayments : function(component, orderList, helper, isFirstOrder) {
        if (orderList[0].ChargentOrders__Subtotal__c === 0) {
            orderList.splice(0,1);
            if (orderList.length > 0) {
                helper.submitPayments(component, orderList, helper, false);
            } else {
                helper.postSubmitProcessing(component, helper, true);
            }
        } else {
            var chargePromise = this.submitPayment(component, orderList[0], helper, isFirstOrder);
            var self = this;
            chargePromise.then(
                $A.getCallback(function(result) {
                    orderList.splice(0,1);
                    if (orderList.length > 0) {
                        self.submitPayments(component, orderList, helper, false);
                    } else {
                        self.postSubmitProcessing(component, helper, true);
                    }
                })
            );
        }
    },

    submitPayment : function(component, orderToCharge, helper, isFirstOrder) {
        var self = this;

        return new Promise(function(resolve, reject) {
            var actionCharge = component.get("c.chargeOrder");  

            actionCharge.setParams({
                "chOrder": orderToCharge
            });        

            actionCharge.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    var listResponse = resp.getReturnValue().split(",",2);

                    // If the first transaction fails, show error so they can modify it.
                    // If the first transaction goes through but any subsequent transaction fails, don't allow resubmit.

                    if (listResponse[1] === 'Approved'){
                        resolve();
                        var transList = component.get("v.transactionsCreated");
                        transList.push(listResponse[0]);
                        component.set("v.transactionsCreated", transList);
                    } else if (isFirstOrder) {
                        component.set("v.ErrorText",  listResponse[1]);
                        component.set("v.showErrorText", true);
                        component.set("v.hideFields", false);
                        component.set("v.Spinner", false);
                        reject();
                    } else {
                        self.postSubmitProcessing(component, helper, false);
                        reject();
                    }
                } else {
                    // because of the try-catch block in apex, this is rare:
                    self.showFinalError(component);   
                }
            });   
            $A.enqueueAction(actionCharge); 
        });   
    },

    postSubmitProcessing : function(component, helper, showApproval) {
        var transactionIDList = component.get("v.transactionsCreated");  
        var updateRecords = component.get("c.processingPostSubmit");  

        updateRecords.setParams({
            "transactionIdList": transactionIDList
        });

        updateRecords.setCallback(this,function(resp){
            var self = this;

            if (resp.getState() === 'SUCCESS' && resp.getReturnValue() && showApproval) {
                self.showApproved(component);   
            } else {
                // because of the try-catch block in apex, this is rare:
                self.showFinalError(component);
            }
        });   
        $A.enqueueAction(updateRecords); 
    },
})