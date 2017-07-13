({
    switchToTransactions : function(component, event) {  
       $A.util.removeClass(component.find("transactionTable"), 'slds-hide');
       $A.util.removeClass(component.find("billTable"), 'slds-show');
       $A.util.addClass(component.find("transactionTable"), 'slds-show');
       $A.util.addClass(component.find("billTable"), 'slds-hide');
    },
    
    switchToNMCs : function(component, event) {    
       $A.util.removeClass(component.find("transactionTable"), 'slds-show');
       $A.util.removeClass(component.find("billTable"), 'slds-hide');
       $A.util.addClass(component.find("transactionTable"), 'slds-hide');
       $A.util.addClass(component.find("billTable"), 'slds-show');
    },
})