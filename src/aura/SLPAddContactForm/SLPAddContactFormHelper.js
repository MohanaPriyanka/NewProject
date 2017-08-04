({  
    errorCheck : function(component, helper, newContact) {
        var errorMessage = "";  
        
        if(helper.invalidField(component, newContact.FirstName, null, true, false, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's First Name without any special characters." + "\n" + "\n";
            $A.util.addClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            
        } else if (helper.invalidField(component, newContact.LastName, null, true, false, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's Last Name without any special characters." + "\n" + "\n";
            $A.util.addClass(component.find("inputLastName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            
        } else if (helper.invalidField(component, newContact.Email, null, true, true, false, "email")) {
            errorMessage = "Please enter a valid email address." + "\n" + "\n";
            $A.util.addClass(component.find("inputEmail"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error'); 
            
        } else if (helper.invalidField(component, newContact.LASERCA__Home_Address__c, null, true, true, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's correct home address." + "\n" + "\n";
            $A.util.addClass(component.find("inputStreet"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');     
        
        } else if (helper.invalidField(component, newContact.LASERCA__Home_City__c, null, true, true, true, "standard")) {
            errorMessage = "Please enter the Co-Signer's City" + "\n" + "\n";
            $A.util.addClass(component.find("inputCity"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');   
            
        } else if (newContact.LASERCA__Home_State__c == "Select") {
            errorMessage = "Please enter a valid State" + "\n" + "\n";
            $A.util.addClass(component.find("inputState"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');  
            $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');   

        } else if (helper.invalidField(component, newContact.LASERCA__Home_Zip__c, 5, false, false, false, "standard")) {
            errorMessage = "Please enter a valid 5 digit Zip Code"+ "\n" + "\n";
            $A.util.addClass(component.find("inputZip"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');       
            $A.util.removeClass(component.find("inputState"), 'shake slds-has-error');  
            
        } else if (helper.invalidField(component, newContact.LASERCA__Co_Applicant_DOB__c, null, false, false, false, "date")) {
            errorMessage = "Please enter a Date of Birth in the format MM/DD/YYYY." + "\n" + "\n";
            $A.util.addClass(component.find("inputDOB"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');       
            $A.util.removeClass(component.find("inputState"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputZip"), 'shake slds-has-error');    
            
        } else if (helper.invalidField(component, newContact.LASERCA__Social_Security_Number__c, 9, false, false, false, "standard")) {
            errorMessage = "Please enter a valid 9 digit Social Security Number without any special characters/symbols." + "\n" + "\n";
            $A.util.addClass(component.find("inputSSN"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');       
            $A.util.removeClass(component.find("inputState"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputZip"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputDOB"), 'shake slds-has-error');    
            
        } else if (helper.invalidField(component, newContact.Income__c, null, false, false, false, "standard")) {
            errorMessage = "Please enter the Co-Signer's estimated annual income" + "\n" + "\n";
            $A.util.addClass(component.find("inputIncome"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputFirstName"), 'shake slds-has-error'); 
            $A.util.removeClass(component.find("inputLastName"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputEmail"), 'shake slds-has-error');   
            $A.util.removeClass(component.find("inputStreet"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputCity"), 'shake slds-has-error');       
            $A.util.removeClass(component.find("inputState"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputZip"), 'shake slds-has-error');    
            $A.util.removeClass(component.find("inputDOB"), 'shake slds-has-error');
            $A.util.removeClass(component.find("inputSSN"), 'shake slds-has-error');
        
    	} else if (newContact.Privacy_Policy_Acknowledged__c != true ) {
            errorMessage = "Please have the Co-Signer acknowledge BlueWave's Privacy Policy." + "\n" + "\n";
            $A.util.addClass(component.find("privacyPolicy"), 'shake slds-has-error'); 
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
    
        } else if (newContact.Credit_Check_Acknowledged__c != true){    
            errorMessage = "Please have the Co-Signer give BlueWave and Avidia Bank permission to access their credit history." + "\n" + "\n";
            $A.util.addClass(component.find("accessToCredit"), 'shake slds-has-error'); 
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
        
        } else {
           errorMessage = ""; 
           $A.util.removeClass(component.find("accessToCredit"), 'shake slds-has-error'); 
        }
               
        return errorMessage;     
	},
})