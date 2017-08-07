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
    handleCreditCheckResponse : function(component, divToShow) {
        $A.util.addClass(component.find("creditStatus"), 'noDisplay');
        $A.util.addClass(component.find("editPencil"), 'noDisplay');
        $A.util.removeClass(component.find(divToShow), 'noDisplay');
        this.stopSpinner(component, "creditSpinner");
        window.clearInterval(component.get("v.crefditStatusPoller"));
    },

    checkCreditStatus : function(component, helper) {
        var action = component.get("c.checkCreditStatus");
        action.setParams({"leadToQuery" : component.get("v.newLead")});
        action.setCallback(this, function(resp) {
                console.log(resp.getReturnValue());
                if (resp.getState() == "SUCCESS") {
                    if (resp.getReturnValue() == "Ready for Credit Check") {
                        // Don't do anything, credit check isn't done yet
                    } else if (resp.getReturnValue() == "Pre-Qualified") {
                        helper.handleCreditCheckResponse(component, 'creditResultPass');
                    } else if (resp.getReturnValue() == "Pending Credit Review") {
                        helper.handleCreditCheckResponse(component, 'creditResultPendingReview');
                    } else if (resp.getReturnValue() == "Unqualified") {
                        helper.handleCreditCheckResponse(component, 'creditResultUnqualified');
                    } else {
                        component.set("v.creditStatusErrorText", resp.getReturnValue());
                        helper.handleCreditCheckResponse(component, 'creditResultError');
                    }
                } else {
                    helper.logError("SLPAddCustomerHelper", "checkCreditStatus", resp.getError());
                    window.clearInterval(component.get("v.creditStatusPoller"));
                    $A.util.addClass(component.find("editPencil"), 'noDisplay');
                }
            });
        $A.enqueueAction(action);
    },

    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.FirstName, "firstNameElement", "shake", true, null, false, true, "Please enter the Applicants's First Name without any special characters.", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LastName, "lastNameElement", "shake", true, null, false, true, "Please enter the Applicants's Last Name without any special characters.", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "customerEmail", "shake", true, null, true, false, "Please enter a valid email address. The email you entered is: " + lead.Email, "email");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Birthdate__c, "dateOfBirth", "shake", false, null, null, null, "Please enter a Date of Birth in the format MM/DD/YYYY. Your date was entered as: " + lead.LASERCA__Birthdate__c, "date");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_Address__c, "homeAddressElement", "shake", true, null, false, true, "Please enter the Applicants's correct home address", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_City__c, "cityElement", "shake", true, null, false, true, "Please enter the Applicant's City", "standard");        
        if (lead.LASERCA__Home_State__c == "Select") {
            helper.setInputToError(component, "stateElement", "shake");
            errorMessage = errorMessage + "Please enter a valid State" + "\n" + "\n";                          
        } else {
            helper.setInputToCorrect(component, "stateElement" );
        }     
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_Zip__c, "zipCodeElement", "shake", false, 5, false, false, "Please enter a valid 5 digit Zip Code", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Requested_Loan_Amount__c, "loanAmountElement", "shake", false, null, false, false, "Please enter this Applicant's requested loan amount", "standard");        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.System_Cost__c, "systemCostElement", "shake", false, null, false, false, "Please enter this Applicant's system installation cost", "standard");                
        lead.LASERCA__SSN__c = lead.LASERCA__SSN__c.replace(/-/g,"");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__SSN__c, "ssnElement", "shake", false, 9, false, false, "Please enter a valid 9 digit Social Security Number without any special characters/symbols.", "standard");             
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Annual_Income_Currency__c, "incomeElement", "shake", false, null, false, false, "Please enter this Applicant's estimated annual income", "standard");             
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Credit_Check_Acknowledged__c, "creditHistoryElement", "shake", true, null, false, false, "Please have the Applicant give BlueWave and Avidia Bank permission to access their credit history.", "standard");             
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Privacy_Policy_Acknowledged__c, "privacyPolicyElement", "shake", true, null, false, false, "Please have the Applicant acknowledge BlueWave's Privacy Policy.", "standard");             
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Utility_Bill_Access_Acknowledged__c, "energyHistoryElement", "shake", true, null, false, false, "Please have the Applicant give BlueWave permission to access their energy billing history.", "standard");             

        if (errorMessage.length > 0) {
            return errorMessage;
        } 
    },    

    removeAddCustomerForm : function(component) {
        $A.util.addClass(component.find("applicationTabBar"), 'noDisplay');
        $A.util.addClass(component.find("bwApplicationHeader"), 'noDisplay');
        $A.util.addClass(component.find("inputForm"), 'noDisplay'); 
        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');    
        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplay');
        $A.util.addClass(component.find("customerEmailButton"), 'noDisplay'); 
    },    
   
    returnAddCustomerForm : function(component) {
        $A.util.removeClass(component.find("inputForm"), 'noDisplay'); 
    },    

    showCreditCheckPage : function(component) {
        $A.util.removeClass(component.find("pullCreditButtons"), 'noDisplay');
        $A.util.removeClass(component.find("addedCustomerConfirmCredit"), 'noDisplay');
    },  
    
    hideCreditCheckPage : function(component) {
        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay');
        $A.util.addClass(component.find("addedCustomerConfirmCredit"), 'noDisplay');
    },      

    showMSLPApplication : function(component) {
        $A.util.addClass(component.find("bwApplicationHeader"), 'noDisplay');      
        $A.util.removeClass(component.find("bwslAppTab"), 'slds-has-focus');      
        $A.util.addClass(component.find("mslpAppTab"), 'slds-has-focus'); 
        $A.util.removeClass(component.find("avidiaLogo"), 'noDisplay');  
        $A.util.removeClass(component.find("avidiaFooter"), 'noDisplay');
        $A.util.removeClass(component.find("mslpDisclaimer"), 'noDisplay');    
    },     

    showBWSLApplication : function(component) {
        $A.util.removeClass(component.find("bwApplicationHeader"), 'noDisplay');      
        $A.util.addClass(component.find("bwslAppTab"), 'slds-has-focus');      
        $A.util.removeClass(component.find("mslpAppTab"), 'slds-has-focus');
        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');  
        $A.util.addClass(component.find("avidiaFooter"), 'noDisplay');    
        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplay');     
    },         

})