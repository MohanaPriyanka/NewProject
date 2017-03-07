@isTest
public class LoanHandlerTestClass {
    @testSetup public static void setupTestData(){

        List<Product2> productList = new List<Product2>(LoanTestRecordWarehouse.getLoanHandlerProductRecords());
        insert productList;
        System.debug(productList);

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanHandlerLeadRecords());
        //insert leadList;
        System.debug(leadList);     

    }
    @isTest static void testLoanHandlerCreateLoan() {
 
        Test.startTest();
        //List<Product2> productList = [SELECT Id FROM Product2];
        for (Lead leadRecord : [SELECT Id, Name, Status, Update_Dummy__c FROM Lead]) {
        	//This update is not necessary, the insertion of the lead sets it as qualified do to the credit reports inserted with it.
        	leadRecord.Status = 'Qualified';
        	//leadRecord.Product__c = productList.get(0).Id;
        }
	    Test.stopTest();

	    for (Lead leadRecordAssertion : [SELECT Id, Name, (SELECT Id FROM Loans__r), 
	    									(SELECT Id FROM Partner_Tasks__r), 
	    									(SELECT Id FROM Residential_Equipment__r) 
	    								 FROM Lead]) {
		    //Assert that a loan was created when the lead was set to qualified.
		    System.Assert(leadRecordAssertion.Loans__r.size() == 1);
		    //Assert that six parent partner tasks were created when the lead was set to qualified. 
		    System.Assert(leadRecordAssertion.Partner_Tasks__r.size() == 7);	    	
	    }
	    //Assert that the equipment record mapped to the loan on creation
	    for (Loan__c loanRecordAssertion : [SELECT Id, (SELECT Id FROM Residential_Equipment__r) FROM Loan__c]) {
	    	System.Assert(loanRecordAssertion.ResidentiaL_Equipment__r.size() == 1);	    
	    }
    }
    @isTest static void testPartnerCustomerInformationTaskValidation() {
		Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();

        Test.startTest();    	
    	List<Lead> leadList = [SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name FROM Lead];
    	for (Lead leadRecord : leadList) {
	 		//test income documentation 

	 		//Insert the PayStub subTask 	    	
        	Attachment attachmentPaystub = new Attachment();
        	attachmentPaystub.Name =  String.valueOf('test.txt');
	        attachmentPaystub.body = bodyBlob;
        	attachmentPaystub.ParentId = leadRecord.Id;
        	attachmentPaystub.Description = 'PayStub' + ' ' + leadRecord.Id;
        	Insert attachmentPaystub;

	        if(leadRecord.Retired__c == true && leadRecord.Self_Employed__c == false) {
			    //Insert the SSN/Pension Award Letter or Bank Statement subTask 	    		    
	        	Attachment attachmentSSNAwardLetter = new Attachment();
	        	attachmentSSNAwardLetter.Name =  String.valueOf('test.txt');
		        attachmentSSNAwardLetter.body = bodyBlob;
	        	attachmentSSNAwardLetter.ParentId = leadRecord.Id;
	        	attachmentSSNAwardLetter.Description = 'SSN Award Letter' + ' ' + leadRecord.Id;
	        	Insert attachmentSSNAwardLetter;
	        }
			if(leadRecord.Retired__c == false && leadRecord.Self_Employed__c == true) {
			    //Insert the Tax Return 	    		    
	        	Attachment attachmentTaxReturnTwoYears = new Attachment();
	        	attachmentTaxReturnTwoYears.Name =  String.valueOf('test.txt');
		        attachmentTaxReturnTwoYears.body = bodyBlob;
	        	attachmentTaxReturnTwoYears.ParentId = leadRecord.Id;
	        	attachmentTaxReturnTwoYears.Description = 'Tax Return (Two Years Previous)' + ' ' + leadRecord.Id;
	        	Insert attachmentTaxReturnTwoYears;

		    	//Insert the Tax Return  		    
	        	Attachment attachmentOneYear = new Attachment();
	        	attachmentOneYear.Name =  String.valueOf('test.txt');
		        attachmentOneYear.body = bodyBlob;
	        	attachmentOneYear.ParentId = leadRecord.Id;
	        	attachmentOneYear.Description = 'Provide Tax Return (Previous Year)' + ' ' + leadRecord.Id;
	        	Insert attachmentOneYear;
			}	  

	    	//Insert the Sales agreement 	    		    
        	Attachment attachmentSalesAgreement = new Attachment();
        	attachmentSalesAgreement.Name =  String.valueOf('test.txt');
	        attachmentSalesAgreement.body = bodyBlob;
        	attachmentSalesAgreement.ParentId = leadRecord.Id;
        	attachmentSalesAgreement.Description = 'Sales Agreement' + ' ' + leadRecord.Id;
        	Insert attachmentSalesAgreement;
   		}
   		for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c]) {
   			loanRecord.Commencement_Datee__c = myDate;
   			loanListToUpdate.add(loanRecord);
   		}
   		update loanListToUpdate;
   		changeLeadUpdateDummy(leadList);

	    Test.stopTest();
	    for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c]) {
	    	if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}		    	
	    	if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Provide all System Information') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}
	    	if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Pending');	    		
	    	}		    		    		    			    				    				    			    		    	
		}    	    
    }

    @isTest static void testAfterLeadConversion() {
    	List<Lead> leadList = [SELECT Id FROM Lead];
    	List<Opportunity> oppListToUpdate = new List<Opportunity>();
    	List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        Test.startTest();
        for (Lead l :leadList){
            database.leadConvert lc = new database.leadConvert();
            lc.setLeadId(l.Id);

            leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);

            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());
        }
	    for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c]) {
	    	if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}		
	    	if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Pending');	    		
	    	}	    	    	
    	}
    	for (Opportunity oppRecord : [SELECT Id, 
    									(SELECT Id FROM Residential_Equipment__r), 
    									(SELECT Id FROM Partner_Tasks__r)
    								  FROM Opportunity]) {
    		//Assert that the Eqiupment carried over to the Opportunity on conversion
    		System.Assert(oppRecord.Residential_Equipment__r.size() == 1);
    		//Assert that the Partner Tasks carried over to the Opportunity on conversion.
    		System.Assert(oppRecord.Partner_Tasks__r.size() == 7);
    		oppRecord.StageName = 'Complete';
    		oppListToUpdate.add(oppRecord);
    	}
    	update oppListToUpdate;

    	for (Loan__c loanRecord : [SELECT Id, (SELECT Id FROM Disbursals__r) FROM Loan__c]) {
    		System.assert(loanRecord.Disbursals__r.size() == 3);
    	}

	    for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c]) {
	    	if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}		
	    	if(partnerTaskAssertion.Name == 'Mechanical Installation') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Pending');	    		
	    	}	    	    	
    	}
    	List<Residential_Equipment__c> equipmentList = [SELECT Id, Mechanically_Installed__c, Interconnected__c 
    													FROM Residential_Equipment__c];
    	for (Residential_Equipment__c equipment : equipmentList){
    		equipment.Mechanically_Installed__c = true;
    		equipmentListToUpdate.add(equipment);
    	}
    	update equipmentListToUpdate;
    	equipmentListToUpdate.clear();
	    
	    for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c]) {
	    	if(partnerTaskAssertion.Name == 'Mechanical Installation') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}		
	    	if(partnerTaskAssertion.Name == 'Interconnection') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Pending');	    		
	    	}	    	    	
    	}
    	for (Residential_Equipment__c equipment : equipmentList){
    		equipment.Interconnected__c = true;
    		equipmentListToUpdate.add(equipment);
    	}
    	update equipmentListToUpdate;
	    
	    for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c]) {
	    	if(partnerTaskAssertion.Name == 'Interconnection') {
	    		System.Assert(partnerTaskAssertion.Status__c == 'Complete');	    		
	    	}		    	    	
    	}      	    	
	    Test.stopTest();    	
    }

    public static void changeLeadUpdateDummy(List<Lead> leadList) {
    	List<Lead> leadListToUpdate = new List<Lead>();
    	for (Lead leadRecord : leadList) {
	    	if(leadRecord.Update_Dummy__c == true) {
	    		leadRecord.Update_Dummy__c = false;
	    	}else {
	    		leadRecord.Update_Dummy__c = true;
	    	}
	    	leadListToUpdate.add(leadRecord);
    	}
    	update leadListToUpdate;
    }    
}
