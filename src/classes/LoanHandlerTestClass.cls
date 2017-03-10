@isTest
public class LoanHandlerTestClass {
    @testSetup public static void setupTestData(){

        List<Product2> productList = new List<Product2>(LoanTestRecordWarehouse.getLoanHandlerProductRecords());
        insert productList;
        System.debug(productList);

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanHandlerLeadRecords());
        for (Lead leadRecord : leadList) {
        	leadRecord.Unfinished_Lead__c = false;
        	LeadRecord.Status = 'Pending Information';
        }
        update leadList;
        //insert leadList;
        System.debug(leadList);     
    }
    @isTest static void testLoanHandlerCreateLoan() {
        // The insertion of the lead sets it as qualified due to the credit reports inserted with it.

        for (Lead leadRecordAssertion : [SELECT Id, Name, (SELECT Id FROM Loans__r), 
                                         (SELECT Id FROM Partner_Tasks__r), 
                                         (SELECT Id FROM Residential_Equipment__r) 
                                         FROM Lead
                                         WHERE DOER_Solar_Loan__c = false]) {
            //Assert that a loan was created when the lead was set to qualified.
            System.Assert(leadRecordAssertion.Loans__r.size() == 1);
            //Assert that six parent partner tasks were created when the lead was set to qualified. 
            System.Assert(leadRecordAssertion.Partner_Tasks__r.size() == 6);	    	
        }    
        //Assert that the equipment record mapped to the loan on creation
        for (Loan__c loanRecordAssertion : [SELECT Id, (SELECT Id FROM Residential_Equipment__r) FROM Loan__c]) {
            System.AssertEquals(1, loanRecordAssertion.ResidentiaL_Equipment__r.size());
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
        loanListToUpdate[0].System_Costt__c = null;
        update loanListToUpdate;
        changeLeadUpdateDummy(leadList);

        // DOER Solar Loans have an extra task (Technical Approval Documentation) which isn't yet handled, so
        // we'll only check non-DOER loans
        List<Partner_Task__c> partnerTaskList = [SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id 
                                                 FROM Partner_Task__c
                                                 WHERE Loan__r.DOER_Solar_Loann__c = false];

        Test.stopTest();

        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide Income Documentation') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide all System Information') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Complete');
            }
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.AssertEquals(partnerTaskAssertion.Status__c, 'Pending');
            }
        }    	    
    }

    @isTest static void testAfterLeadConversion() {
    	List<Lead> leadList = [SELECT Id FROM Lead];
    	List<Opportunity> oppListToUpdate = new List<Opportunity>();
    	List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        List<Loan__c> loanListToRemoveSystemCost = new List<Loan__c>();
        Test.startTest();
        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
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
    	for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = false]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.Assert(oppRecord.Residential_Equipment__r.size() == 1);
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            System.Assert(oppRecord.Partner_Tasks__r.size() == 6);
            oppRecord.StageName = 'Complete';
            oppListToUpdate.add(oppRecord);
    	}

    	update oppListToUpdate;

    	for (Loan__c loanRecord : [SELECT Id, DOER_Solar_Loann__c, (SELECT Id FROM Disbursals__r) FROM Loan__c]) {
            if (!loanRecord.DOER_Solar_Loann__c){
                System.assertEquals(loanRecord.Disbursals__r.size(), 3);
            }
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
    	if(equipmentListToUpdate.size() > 0 ) {
            update equipmentListToUpdate;    		
    	}
	    
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