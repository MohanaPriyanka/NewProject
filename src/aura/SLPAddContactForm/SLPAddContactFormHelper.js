({  
    errorCheck : function(component, helper, newContact) {
        var errorMessage = "";  
        helper.removeErrorAnimationFromAll(component);
        
        if(helper.invalidField(component, newContact.FirstName, null, true, false, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's First Name without any special characters." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputFirstName");
            
        } else if (helper.invalidField(component, newContact.LastName, null, true, false, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's Last Name without any special characters." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputLastName");
            
        } else if (helper.invalidField(component, newContact.Email, null, true, true, false, "email")) {
            errorMessage = "Please enter a valid email address." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputEmail");
            
        } else if (helper.invalidField(component, newContact.LASERCA__Home_Address__c, null, true, true, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's correct home address." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputStreet");
        
        } else if (helper.invalidField(component, newContact.LASERCA__Home_City__c, null, true, true, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's City" + "\n" + "\n";
            helper.addErrorAnimation(component, "inputCity");

        } else if (newContact.LASERCA__Home_State__c == "Select") {
            errorMessage = "Please enter a valid State" + "\n" + "\n";
            helper.addErrorAnimation(component, "inputState");

        } else if (helper.invalidField(component, newContact.LASERCA__Home_Zip__c, 5, false, false, false, "standard")) {
            errorMessage = "Please enter a valid 5 digit Zip Code"+ "\n" + "\n";
            helper.addErrorAnimation(component, "inputZip");
            
        } else if (helper.invalidField(component, newContact.LASERCA__Co_Applicant_DOB__c, null, false, false, false, "date")) {
            errorMessage = "Please enter a Date of Birth in the format MM/DD/YYYY." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputDOB");

        } else if (helper.invalidField(component, newContact.LASERCA__Social_Security_Number__c, 9, false, false, false, "standard")) {
            errorMessage = "Please enter a valid 9 digit Social Security Number without any special characters/symbols." + "\n" + "\n";
            helper.addErrorAnimation(component, "inputSSN");
            
        } else if (helper.invalidField(component, newContact.Income__c, null, false, false, false, "standard")) {
            errorMessage = "Please enter the Co-Signer's estimated annual income" + "\n" + "\n";
            helper.addErrorAnimation(component, "inputIncome");
        
        } else if (newContact.Privacy_Policy_Acknowledged__c != true ) {
            errorMessage = "Please have the Co-Signer acknowledge BlueWave's Privacy Policy." + "\n" + "\n";
            helper.addErrorAnimation(component, "privacyPolicy");

        } else if (newContact.Credit_Check_Acknowledged__c != true){    
            errorMessage = "Please have the Co-Signer give BlueWave and Avidia Bank permission to access their credit history." + "\n" + "\n";
            helper.addErrorAnimation(component, "accessToCredit");

        } else {
           errorMessage = ""; 
           $A.util.removeClass(component.find("accessToCredit"), 'shake slds-has-error'); 
        }
               
        return errorMessage;     
    },
    
    addErrorAnimation : function(component, fieldName) { 
        $A.util.addClass(component.find(fieldName), 'shake slds-has-error'); 
    },
    
    removeErrorAnimationFromAll : function(component) {
        $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
        $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
        $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
        $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');    
        $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');       
        $A.util.removeClass(component.find("inputState"), 'shake slds-has-error');    
        $A.util.removeClass(component.find("inputZip"), 'shake slds-has-error');    
        $A.util.removeClass(component.find("inputDOB"), 'shake slds-has-error');
        $A.util.removeClass(component.find("inputSSN"), 'shake slds-has-error');
        $A.util.removeClass(component.find("inputIncome"), 'shake slds-has-error');
        $A.util.removeClass(component.find("privacyPolicy"), 'shake slds-has-error');
        $A.util.removeClass(component.find("accessToCredit"), 'shake slds-has-error'); 
    },
})