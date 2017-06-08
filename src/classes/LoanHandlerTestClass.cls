@isTest
public class LoanHandlerTestClass {
    @testSetup public static void setupTestData(){
        List<String> partnerSetUpIds = new List<String>();  
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();
        
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

        for (Lead leadRecordAssertion : [SELECT Id, Name, DOER_Solar_Loan__c, (SELECT Id, Product__r.Name, Technology_Platform_Fee__c FROM Loans__r), 
                                         (SELECT Id FROM Partner_Tasks__r), 
                                         (SELECT Id FROM Residential_Equipment__r) 
                                         FROM Lead
                                         WHERE DOER_Solar_Loan__c = false]) {
            //Assert that a loan was created when the lead was set to qualified.
            System.AssertEquals(1, leadRecordAssertion.Loans__r.size());
            //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
            System.AssertEquals(8, leadRecordAssertion.Partner_Tasks__r.size());     

            //Assert that Platform Fee got mapped from Lead
            for(Loan__c lond: leadRecordAssertion.Loans__r){
                System.assertEquals(lond.Technology_Platform_Fee__c, 1750);
            }
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
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        Test.startTest();    	
    	List<Lead> leadList = [SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c 
                               FROM Lead
                               WHERE DOER_Solar_Loan__c = false];
        System.debug('the lead list is ' + leadList);                               
    	for (Lead leadRecord : leadList) {
            //test income documentation 

            //Insert the PayStub subTask 	    	
            Attachment attachmentPaystub = new Attachment();
            attachmentPaystub.Name =  String.valueOf('test.txt');
            attachmentPaystub.body = bodyBlob;
            attachmentPaystub.ParentId = leadRecord.Id;
            attachmentPaystub.Description = 'PayStub' + ' ' + leadRecord.Id;
            Insert attachmentPaystub;

            if(leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                //Insert the SSN/Pension Award Letter or Bank Statement subTask 	    		    
                Attachment attachmentSSNAwardLetter = new Attachment();
                attachmentSSNAwardLetter.Name =  String.valueOf('test.txt');
                attachmentSSNAwardLetter.body = bodyBlob;
                attachmentSSNAwardLetter.ParentId = leadRecord.Id;
                attachmentSSNAwardLetter.Description = 'SSN Award Letter' + ' ' + leadRecord.Id;
                Insert attachmentSSNAwardLetter;
            }
            if(!leadRecord.Retired__c && leadRecord.Self_Employed__c) {
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
        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = false]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
        loanListToUpdate[0].System_Costt__c = null;
        update loanListToUpdate;

        for (Residential_Equipment__c equipmentRecord : [SELECT Id, Lead__c, Generator_Nameplate_Capacity__c, Type_of_Module__c, Type_of_Inverter__c, 
        												Number_of_Inverters__c, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,  
        												Inverter_Manufacturer__c, Inverter_Model_Number__c
        												FROM Residential_Equipment__c
                                                        WHERE DOER_Solar_Loan__c = false]) {
        	equipmentRecord.Generator_Nameplate_Capacity__c = 5;
        	equipmentRecord.Module_Manufacturer__c = 'SolarWorld';
        	equipmentRecord.Module_Model_Number__c = 'SW400';
        	equipmentRecord.Number_of_Modules__c = 16;
        	equipmentRecord.Inverter_Manufacturer__c = 'SolarEdge';
        	equipmentRecord.Inverter_Model_Number__c = 'SE500';
        	equipmentRecord.Number_of_Inverters__c = 16;
        	equipmentListToUpdate.add(equipmentRecord);
        }
        update equipmentListToUpdate;
        changeLeadUpdateDummy(leadList);
        List<Partner_Task__c> partnerTaskList = [SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id, 
                                                        Loan__r.DOER_Solar_Loann__c, Child_MSLP_Identifier__c 
                                                 FROM Partner_Task__c];
        Test.stopTest(); 
        System.debug('the partnerTaskList is ' + partnerTasklist);
        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if(partnerTaskAssertion.Child_MSLP_Identifier__c == false) {
                if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
            if(partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c == false) {
                if(partnerTaskAssertion.Name == 'Provide Income Documentation') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide all System Information') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                    System.AssertEquals('Pending', partnerTaskAssertion.Status__c);
                }
            }
        }   	    
    }

    @isTest static void testAfterLeadConversionCustomerSignature() {
        Date myDate = Date.newInstance(2015, 2, 17);
    	List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = false];
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
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                    FROM Partner_Task__c 
                                                    WHERE Loan__r.DOER_Solar_Loann__c = false]) {
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);	    		
            }		
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.AssertEquals('Pending', partnerTaskAssertion.Status__c);	    		
            }	    	    	
    	}
    	for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Disbursal_1_Contract_Signature_Checkbox__c, Disbursal_3_Full_Install_Checkbox__c, Disbursal_Type_Contract__c, Disbursal_Type_Interconnect__c, Disbursal_2_Mechanical_Install_Checkbox__c, 
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = false]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.AssertEquals(1, oppRecord.Residential_Equipment__r.size());
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            if(!oppRecord.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.AssertEquals(8, oppRecord.Partner_Tasks__r.size());    
            }else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.AssertEquals(5, oppRecord.Partner_Tasks__r.size());     
            }                       

            oppRecord.Contract_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);
    	}

    	update oppListToUpdate;    

        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c WHERE Loan__r.DOER_Solar_Loann__c = false]) {
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);	    		
            }
            if(partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.AssertEquals( 'Pending', partnerTaskAssertion.Status__c);             
                }                 
            } else {
                if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                    System.AssertEquals( 'Pending', partnerTaskAssertion.Status__c);             
                }                 
            }		    	    	
    	}
        Test.stopTest();
    }

    @isTest static void testAfterLeadConversionCounterSignature() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = false];
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
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                    FROM Partner_Task__c 
                                                    WHERE Loan__r.DOER_Solar_Loann__c = false]) {
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
            }       
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
            }                   
        }
        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Disbursal_1_Contract_Signature_Checkbox__c, Disbursal_3_Full_Install_Checkbox__c, Disbursal_Type_Contract__c, Disbursal_Type_Interconnect__c, Disbursal_2_Mechanical_Install_Checkbox__c, 
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = false]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.AssertEquals(1, oppRecord.Residential_Equipment__r.size());
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            if(!oppRecord.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.AssertEquals(8, oppRecord.Partner_Tasks__r.size());    
            }else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.AssertEquals(5, oppRecord.Partner_Tasks__r.size());     
            }                       

            oppRecord.Contract_Status__c = 'Completed';
            oppRecord.BlueWave_Signature_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);
        }

        update oppListToUpdate;

    	for (Loan__c loanRecord : [SELECT Id, DOER_Solar_Loann__c, (SELECT Id, Date_of_Disbursal__c, Status__c, Disbursal_Method__c FROM Disbursals__r) 
                                  FROM Loan__c
                                   WHERE DOER_Solar_Loann__c = false]) {
            if (!loanRecord.DOER_Solar_Loann__c){
                System.AssertEquals(3, loanRecord.Disbursals__r.size());
            }else {
                System.AssertEquals(2, loanRecord.Disbursals__r.size());
            }          
    	}

        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c WHERE Loan__r.DOER_Solar_Loann__c = false]) {
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c );                
            }
            if(!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Mechanical Installation') {
                    System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
                }   
            }else {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
                }                 
            }                       
        }
        Test.stopTest();
    }

    @isTest static void testEquipmentUpdates() {
    	List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = false];
    	List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Attachment> attachList = new List<Attachment>();

    	List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        List<Loan__c> loanListToRemoveSystemCost = new List<Loan__c>();
        Date myDate = Date.newInstance(2015, 2, 17);
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

    	List<Residential_Equipment__c> equipmentList = [SELECT Id, Mechanically_Installed__c, Interconnected__c, DOER_Solar_Loan__c 
                                                        FROM Residential_Equipment__c];
    	for (Residential_Equipment__c equipment : equipmentList){
            if(!equipment.DOER_Solar_Loan__c) {
                equipment.Mechanically_Installed__c = true;
                equipmentListToUpdate.add(equipment);
            }
    	}
    	update equipmentListToUpdate;
    	equipmentListToUpdate.clear();
	    
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c 
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.DOER_Solar_Loann__c = false]) {
            if(partnerTaskAssertion.Name == 'Mechanical Installation') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);	    		
            }		
            if(partnerTaskAssertion.Name == 'Interconnection') {
                System.AssertEquals('Pending', partnerTaskAssertion.Status__c);	    		
            }	    	    	
    	}
    	for (Residential_Equipment__c equipment : equipmentList){
            equipment.Interconnected__c = true;
            equipment.Annual_Production_kWh_kW__c = 1400;
            equipment.Interconnection_Date__c = mydate;
            equipment.Estimated_On_Site_Behind_the_Meter_Load__c = 4500;
            equipment.Percentage_of_System_Shaded__c = 4;
            equipment.SREC_Opt_In_Calendar_Quarter__c = 'Q1';
            equipment.Generator_Type__c = 'SolarWorld';
            equipment.MA_Facility_Sector__c = 'Residential';
            equipment.MA_Facility_Type__c = 'Residential';
            equipment.Generator_Nameplate_Capacity__c = 5;
            equipment.Contract_Execution_Date__c = myDate;
            equipment.Generator_Interconnection_Date__c = myDate;
            equipment.Generator_Installation_Date__c = myDate;
            equipment.Generator_Energized_Online_Date__c = myDate;
            equipment.Module_Manufacturer__c = 'SolarWorld';
            equipment.Module_Model_Number__c = 'SW500';
            equipment.Module_Power_Rating__c = 'A';
            equipment.Number_of_Modules__c = 5;
            equipment.Module_Array_Mounting_Type__c = 'SolarWorld';
            equipment.Module_Array_Azimuth__c = '5';
            equipment.Module_Array_Tilt__c = 5;
            equipment.Module_Mounting_Location__c = 'Roof';
            equipment.Inverter_Manufacturer__c = 'Enphase';
            equipment.Inverter_Model_Number__c = 'ENPH340';
            equipment.Remote_Monitoring_System_Vendor__c = 'SolarEdge';
            equipment.Remote_Monitorin_Systegm_Identifier__c = '302948';
            equipment.Number_of_Meters__c = 3;
            equipment.Solar_Meter_Manufacturer__c = 'Eversource';
            equipment.Solar_Meter_Model__c = 'EV200'; 
            equipment.Solar_Meter_Serial_Number__c = '2304938';
            equipment.Initial_Solar_Meter_Reading__c = 45000;
            equipment.Initial_Solar_Meter_Reading_Date__c = myDate;            
            equipmentListToUpdate.add(equipment);

            Attachment attach=new Attachment();     
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.Body=bodyBlob;
            attach.ParentId=equipment.id;
            attach.Description = 'PTO Documentation';
            attachList.add(attach);            
        }
        
        insert attachList;            

    	if(equipmentListToUpdate.size() > 0 ) {
            update equipmentListToUpdate;    		
    	}
	    
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c]) {
            if(!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Interconnection') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
                }   
            }else {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
                }                       
            }	    	    	
    	}      	    	
        Test.stopTest();
    }

    @isTest static void testLoanHandlerCreateLoanMSLP() {
        // The insertion of the lead sets it as qualified due to the credit reports inserted with it.

        for (Lead leadRecordAssertion : [SELECT Id, Name, DOER_Solar_Loan__c, (SELECT Id FROM Loans__r), 
                                         (SELECT Id FROM Partner_Tasks__r), 
                                         (SELECT Id FROM Residential_Equipment__r) 
                                         FROM Lead
                                         WHERE DOER_Solar_Loan__c = true]) {
            //Assert that a loan was created when the lead was set to qualified.
            System.AssertEquals(1, leadRecordAssertion.Loans__r.size());
            if(!leadRecordAssertion.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.AssertEquals(6, leadRecordAssertion.Partner_Tasks__r.size());    
            }else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.AssertEquals(6, leadRecordAssertion.Partner_Tasks__r.size());    
            }       
        }    
        //Assert that the equipment record mapped to the loan on creation
        for (Loan__c loanRecordAssertion : [SELECT Id, (SELECT Id FROM Residential_Equipment__r) FROM Loan__c]) {
            System.AssertEquals(1, loanRecordAssertion.ResidentiaL_Equipment__r.size());
        }
    }

    @isTest static void testPartnerCustomerInformationTaskValidationMSLP() {
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        Test.startTest();       
        List<Lead> leadList = [SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c 
                               FROM Lead
                               WHERE DOER_Solar_Loan__c = true];
        for (Lead leadRecord : leadList) {
            //test income documentation 

            //Insert the PayStub subTask            
            Attachment attachmentPaystub = new Attachment();
            attachmentPaystub.Name =  String.valueOf('test.txt');
            attachmentPaystub.body = bodyBlob;
            attachmentPaystub.ParentId = leadRecord.Id;
            attachmentPaystub.Description = 'PayStub' + ' ' + leadRecord.Id;
            Insert attachmentPaystub;

            if(leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                //Insert the SSN/Pension Award Letter or Bank Statement subTask                     
                Attachment attachmentSSNAwardLetter = new Attachment();
                attachmentSSNAwardLetter.Name =  String.valueOf('test.txt');
                attachmentSSNAwardLetter.body = bodyBlob;
                attachmentSSNAwardLetter.ParentId = leadRecord.Id;
                attachmentSSNAwardLetter.Description = 'SSN Award Letter' + ' ' + leadRecord.Id;
                Insert attachmentSSNAwardLetter;
            }
            if(!leadRecord.Retired__c&& leadRecord.Self_Employed__c) {
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

            if(leadRecord.DOER_Solar_Loan__c) {
                //Insert the Sales agreement                    
                Attachment attachmentTechnicalApplication = new Attachment();
                attachmentTechnicalApplication.Name =  String.valueOf('test.txt');
                attachmentTechnicalApplication.body = bodyBlob;
                attachmentTechnicalApplication.ParentId = leadRecord.Id;
                attachmentTechnicalApplication.Description = 'MSLP Technical Confirmation' + ' ' + leadRecord.Id;
                Insert attachmentTechnicalApplication;                
            }
        }
        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = true]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
        loanListToUpdate[0].System_Costt__c = null;
        update loanListToUpdate;
        for (Residential_Equipment__c equipmentRecord : [SELECT Id, Lead__c, Generator_Nameplate_Capacity__c, Type_of_Module__c, Type_of_Inverter__c, 
                                                        Number_of_Inverters__c, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,  
                                                        Inverter_Manufacturer__c, Inverter_Model_Number__c
                                                        FROM Residential_Equipment__c]) {
            equipmentRecord.Generator_Nameplate_Capacity__c = 5;
            equipmentRecord.Module_Manufacturer__c = 'SolarWorld';
            equipmentRecord.Module_Model_Number__c = 'SW400';
            equipmentRecord.Number_of_Modules__c = 16;
            equipmentRecord.Inverter_Manufacturer__c = 'SolarEdge';
            equipmentRecord.Inverter_Model_Number__c = 'SE500';
            equipmentRecord.Number_of_Inverters__c = 16;
            equipmentListToUpdate.add(equipmentRecord);
        }
        update equipmentListToUpdate;
        changeLeadUpdateDummyMSLP(leadList);
        // DOER Solar Loans have an extra task (Technical Approval Documentation) which isn't yet handled, so
        // we'll only check non-DOER loans
        List<Partner_Task__c> partnerTaskList = [SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id, Loan__r.DOER_Solar_Loann__c 
                                                 FROM Partner_Task__c
                                                 WHERE Loan__r.DOER_Solar_Loann__c = true];

        Test.stopTest();

        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Income Documentation') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide all System Information') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.AssertEquals('Pending', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Provide Technical Confirmation Documentation') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
                }
            }
        }           
    }

    @isTest static void testAfterLeadConversionMSLP() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = true];
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
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c FROM Partner_Task__c WHERE Loan__r.DOER_Solar_Loann__c = true]) {
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.Assert(partnerTaskAssertion.Status__c == 'Complete');                
            }       
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.Assert(partnerTaskAssertion.Status__c == 'Pending');             
            }                   
        }
        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Disbursal_1_Contract_Signature_Checkbox__c, Disbursal_3_Full_Install_Checkbox__c, Disbursal_Type_Contract__c, Disbursal_Type_Interconnect__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = true]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.AssertEquals(1, oppRecord.Residential_Equipment__r.size());
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            if(!oppRecord.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.AssertEquals(6, oppRecord.Partner_Tasks__r.size());    
            }else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.AssertEquals(6, oppRecord.Partner_Tasks__r.size());     
            }              

            oppRecord.Contract_Status__c = 'Completed';
            oppRecord.Bluewave_Signature_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);
        }

        update oppListToUpdate;

        for (Opportunity opp : oppListToUpdate) {
            opp.Disbursal_1_Contract_Signature_Checkbox__c = myDate;
            opp.Disbursal_3_Full_Install_Checkbox__c = myDate;
            opp.Disbursal_Type_Contract__c = 'ACH Disbursal';
            opp.Disbursal_Type_Interconnect__c = 'ACH Disbursal';
        }

        update oppListToUpdate;

        for (Loan__c loanRecord : [SELECT Id, DOER_Solar_Loann__c, (SELECT Id,Date_of_Disbursal__c, Status__c, Disbursal_Method__c FROM Disbursals__r) 
                                   FROM Loan__c 
                                   WHERE DOER_Solar_Loann__c = true]) {
            if (!loanRecord.DOER_Solar_Loann__c){
                System.AssertEquals(3, loanRecord.Disbursals__r.size());
            }else {
                System.AssertEquals(2, loanRecord.Disbursals__r.size());
            }
            for (Disbursal__c disbursal : loanRecord.Disbursals__r) {
                System.AssertEquals(disbursal.Date_of_Disbursal__c, myDate);
                System.AssertEquals(disbursal.Status__c, 'Complete');
                System.AssertEquals(disbursal.Disbursal_Method__c, 'ACH');
            }
        }

        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c 
                                                     WHERE Loan__r.DOER_Solar_Loann__c = true]) {
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
            }
            if(!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Mechanical Installation') {
                    System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
                }   
            }else {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
                }                 
            }                       
        }
        Test.stopTest();
    }

    @isTest static void testDisbursalUpdateMSLP() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = true];
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
        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Disbursal_1_Contract_Signature_Checkbox__c, Disbursal_3_Full_Install_Checkbox__c, Disbursal_Type_Contract__c, Disbursal_Type_Interconnect__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = true]) {          
            oppRecord.StageName = 'Complete';
            oppListToUpdate.add(oppRecord);
        }
        update oppListToUpdate;
        for (Opportunity opp : oppListToUpdate) {
            opp.Disbursal_1_Contract_Signature_Checkbox__c = myDate;
            opp.Disbursal_3_Full_Install_Checkbox__c = myDate;
            opp.Disbursal_Type_Contract__c = 'ACH Disbursal';
            opp.Disbursal_Type_Interconnect__c = 'ACH Disbursal';
        }
        update oppListToUpdate;

        for (Loan__c loanRecord : [SELECT Id, DOER_Solar_Loann__c, (SELECT Id,Date_of_Disbursal__c, Status__c, Disbursal_Method__c FROM Disbursals__r) 
                                   FROM Loan__c 
                                   WHERE DOER_Solar_Loann__c = true]) {
            for (Disbursal__c disbursal : loanRecord.Disbursals__r) {
                System.AssertEquals(disbursal.Date_of_Disbursal__c, myDate);
                System.AssertEquals(disbursal.Status__c, 'Complete');
                System.AssertEquals(disbursal.Disbursal_Method__c, 'ACH');
            }
        }
        Test.stopTest();
    }

    @isTest static void testEquipmentUpdatesMSLP() {
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = false];
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Attachment> attachList = new List<Attachment>();        
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        List<Loan__c> loanListToRemoveSystemCost = new List<Loan__c>();
        Date myDate = Date.newInstance(2015, 2, 17);
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

        List<Residential_Equipment__c> equipmentList = [SELECT Id, Mechanically_Installed__c, Interconnected__c, DOER_Solar_Loan__c 
                                                        FROM Residential_Equipment__c];
        for (Residential_Equipment__c equipment : equipmentList){
            if(!equipment.DOER_Solar_Loan__c) {
                equipment.Mechanically_Installed__c = true;
                equipmentListToUpdate.add(equipment);
            }
        }
        update equipmentListToUpdate;
        equipmentListToUpdate.clear();
        
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c 
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.DOER_Solar_Loann__c = true]) {
            if(partnerTaskAssertion.Name == 'Mechanical Installation') {
                System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
            }       
            if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.AssertEquals('Pending', partnerTaskAssertion.Status__c);             
            }                   
        }
        for (Residential_Equipment__c equipment : equipmentList){
            equipment.Interconnected__c = true;
            equipment.Interconnected__c = true;
            equipment.Annual_Production_kWh_kW__c = 1400;
            equipment.Interconnection_Date__c = mydate;
            equipment.Estimated_On_Site_Behind_the_Meter_Load__c = 4500;
            equipment.Percentage_of_System_Shaded__c = 4;
            equipment.SREC_Opt_In_Calendar_Quarter__c = 'Q1';
            equipment.Generator_Type__c = 'SolarWorld';
            equipment.MA_Facility_Sector__c = 'Residential';
            equipment.MA_Facility_Type__c = 'Residential';
            equipment.Generator_Nameplate_Capacity__c = 5;
            equipment.Contract_Execution_Date__c = myDate;
            equipment.Generator_Interconnection_Date__c = myDate;
            equipment.Generator_Installation_Date__c = myDate;
            equipment.Generator_Energized_Online_Date__c = myDate;
            equipment.Module_Manufacturer__c = 'SolarWorld';
            equipment.Module_Model_Number__c = 'SW500';
            equipment.Module_Power_Rating__c = 'A';
            equipment.Number_of_Modules__c = 5;
            equipment.Module_Array_Mounting_Type__c = 'SolarWorld';
            equipment.Module_Array_Azimuth__c = '5';
            equipment.Module_Array_Tilt__c = 5;
            equipment.Module_Mounting_Location__c = 'Roof';
            equipment.Inverter_Manufacturer__c = 'Enphase';
            equipment.Inverter_Model_Number__c = 'ENPH340';
            equipment.Remote_Monitoring_System_Vendor__c = 'SolarEdge';
            equipment.Remote_Monitorin_Systegm_Identifier__c = '302948';
            equipment.Number_of_Meters__c = 3;
            equipment.Solar_Meter_Manufacturer__c = 'Eversource';
            equipment.Solar_Meter_Model__c = 'EV200'; 
            equipment.Solar_Meter_Serial_Number__c = '2304938';
            equipment.Initial_Solar_Meter_Reading__c = 45000;
            equipment.Initial_Solar_Meter_Reading_Date__c = myDate;             
            equipmentListToUpdate.add(equipment);

            Attachment attach=new Attachment();     
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.Body=bodyBlob;
            attach.ParentId=equipment.id;
            attach.Description = 'PTO Documentation';
            attachList.add(attach);            
        }
        
        insert attachList; 

        if(equipmentListToUpdate.size() > 0 ) {
            update equipmentListToUpdate;           
        }
        
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c]) {
            if(!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Interconnection') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
                }   
            }else {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.AssertEquals('Complete', partnerTaskAssertion.Status__c);                
                }                       
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
    public static void changeLeadUpdateDummyMSLP(List<Lead> leadList) {
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