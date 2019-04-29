@isTest
public class LoanHandlerTestClass {
    @testSetup public static void setupTestData(){
        Test.startTest();
        List<String> partnerSetUpIds = new List<String>();  
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanHandlerLeadRecords());
        LoanHandler.createResidentialEquipment(leadList);
        LoanHandler.createLoan(leadList);
        Test.stopTest();
    }
    @isTest static void testLoanHandlerCreateLoan() {
        // The insertion of the lead sets it as qualified due to the credit reports inserted with it.
        for (Lead leadRecordAssertion : [SELECT Id, Name, DOER_Solar_Loan__c, (SELECT Id, Product__r.Name, Commencement_Datee__c FROM Loans__r),
                                         (SELECT Id FROM Partner_Tasks__r), 
                                         (SELECT Id FROM Residential_Equipment__r) 
                                         FROM Lead
                                         WHERE DOER_Solar_Loan__c = false
                                         AND LASERCA__Home_State__c = 'MA']) {
            //Assert that a loan was created when the lead was set to qualified.
            System.assertEquals(1, leadRecordAssertion.Loans__r.size());
            //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified.
            System.assertEquals(8, leadRecordAssertion.Partner_Tasks__r.size());
        }
        //Assert that the equipment record mapped to the loan on creation
        for (Loan__c loanRecordAssertion : [SELECT Id, (SELECT Id FROM Residential_Equipment__r) FROM Loan__c]) {
            System.assertEquals(1, loanRecordAssertion.ResidentiaL_Equipment__r.size());
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
      for (Lead leadRecord : leadList) {
            //test income documentation

            //Insert the PayStub subTask
            Attachment attachmentPaystub = new Attachment();
            attachmentPaystub.Name =  String.valueOf('test.txt');
            attachmentPaystub.body = bodyBlob;
            attachmentPaystub.ParentId = leadRecord.Id;
            attachmentPaystub.Description = 'PayStub' + ' ' + leadRecord.Id;
            insert attachmentPaystub;

            if(leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                //Insert the SSN/Pension Award Letter or Bank Statement subTask
                Attachment attachmentSSNAwardLetter = new Attachment();
                attachmentSSNAwardLetter.Name =  String.valueOf('test.txt');
                attachmentSSNAwardLetter.body = bodyBlob;
                attachmentSSNAwardLetter.ParentId = leadRecord.Id;
                attachmentSSNAwardLetter.Description = 'SSN Award Letter' + ' ' + leadRecord.Id;
                insert attachmentSSNAwardLetter;
            }
            if(!leadRecord.Retired__c && leadRecord.Self_Employed__c) {
                //Insert the Tax Return
                Attachment attachmentTaxReturnTwoYears = new Attachment();
                attachmentTaxReturnTwoYears.Name =  String.valueOf('test.txt');
                attachmentTaxReturnTwoYears.body = bodyBlob;
                attachmentTaxReturnTwoYears.ParentId = leadRecord.Id;
                attachmentTaxReturnTwoYears.Description = 'Tax Return (Two Years Previous)' + ' ' + leadRecord.Id;
                insert attachmentTaxReturnTwoYears;

                //Insert the Tax Return          
                Attachment attachmentOneYear = new Attachment();
                attachmentOneYear.Name =  String.valueOf('test.txt');
                attachmentOneYear.body = bodyBlob;
                attachmentOneYear.ParentId = leadRecord.Id;
                attachmentOneYear.Description = 'Provide Tax Return (Previous Year)' + ' ' + leadRecord.Id;
                insert attachmentOneYear;
            }    

            //Insert the Sales agreement               
            Attachment attachmentSalesAgreement = new Attachment();
            attachmentSalesAgreement.Name =  String.valueOf('test.txt');
            attachmentSalesAgreement.body = bodyBlob;
            attachmentSalesAgreement.ParentId = leadRecord.Id;
            attachmentSalesAgreement.Description = 'Sales Agreement' + ' ' + leadRecord.Id;
            insert attachmentSalesAgreement;

        }
        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = false]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
        loanListToUpdate[0].Requested_Loan_Amount__c = 10000;
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
        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if(partnerTaskAssertion.Child_MSLP_Identifier__c == false) {
                if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
            if(partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c == false) {
                System.debug(LoggingLevel.ERROR, partnerTaskAssertion);
                if(partnerTaskAssertion.Name == 'Provide Income Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide all System Information') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }
            }
        }
    }

    @isTest static void testVeteranPartnerTask() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User' LIMIT 1];
        Lead veteran = new Lead(
            FirstName = 'Veteran',
            LastName = 'Testcase',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            Veteran_Disability__c = true,
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 25000,
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product_Program__c = 'BlueWave Solar Loan',
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        insert veteran;
        LoanHandler.createLoan(new List<Lead>{veteran});

        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();

        Test.startTest();
        //Insert the Veteran documentation
        Attachment attachmentPaystub = new Attachment();
        attachmentPaystub.Name =  String.valueOf('test.txt');
        attachmentPaystub.body = bodyBlob;
        attachmentPaystub.ParentId = veteran.Id;
        attachmentPaystub.Description = 'Veteran Income Documentation' + ' ' + veteran.Id;
        insert attachmentPaystub;

        changeLeadUpdateDummy(new List<Lead>{veteran});
        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id,
            Loan__r.DOER_Solar_Loann__c, Child_MSLP_Identifier__c, Unique_id__c
            FROM Partner_Task__c
            WHERE Parent_Task__r.Parent_Task__r.Lead__r.Id = :veteran.Id
            AND Name = 'Provide All Income Documentation'
        ];

        System.debug(LoggingLevel.ERROR, partnerTasks);
        System.assertEquals(1, partnerTasks.size());
        System.assertEquals('Complete', partnerTasks[0].Status__c);
    }

    @isTest static void testPaystubPartnerTask() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User' LIMIT 1];
        Lead employed = new Lead(
            FirstName = 'Veteran',
            LastName = 'Testcase',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            Employed__c = true,
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 25000,
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product_Program__c = 'BlueWave Solar Loan',
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        insert employed;
        LoanHandler.createLoan(new List<Lead>{employed});

        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();

        Test.startTest();
        //Insert the PayStub documentation
        Attachment attachmentPaystub = new Attachment();
        attachmentPaystub.Name =  String.valueOf('test.txt');
        attachmentPaystub.body = bodyBlob;
        attachmentPaystub.ParentId = employed.Id;
        attachmentPaystub.Description = 'PayStub' + ' ' + employed.Id;
        insert attachmentPaystub;

        changeLeadUpdateDummy(new List<Lead>{employed});
        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id,
                Loan__r.DOER_Solar_Loann__c, Child_MSLP_Identifier__c, Unique_id__c
            FROM Partner_Task__c
            WHERE Parent_Task__r.Parent_Task__r.Lead__r.Id = :employed.Id
            AND Name = 'Provide PayStub Documentation'
        ];

        System.debug(LoggingLevel.ERROR, partnerTasks);
        System.assertEquals(1, partnerTasks.size());
        System.assertEquals('Complete', partnerTasks[0].Status__c);
    }

    @isTest static void testAfterLeadConversionCustomerSignature() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id, Name, Application_Type__c FROM Lead WHERE DOER_Solar_Loan__c = FALSE AND LASERCA__Home_State__c = 'MA'];
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        Opportunity jointOpp = new Opportunity();

        convertLeads(leadlist, 0);
        Test.startTest();
        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = FALSE AND Lead__r.LASERCA__Home_State__c = 'MA'
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assert(partnerTaskAssertion.Status__c == 'Incomplete');
            }
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assert(partnerTaskAssertion.Status__c == 'Incomplete');
            }
        }

        LoanUnderwriting.approveLeads(leadList);

        partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c, Opportunity__r.Name
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = FALSE AND Lead__r.LASERCA__Home_State__c = 'MA'
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
            }
        }
        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Name, Application_Type__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = FALSE
                                      AND (State_ab__c = 'MA' OR Community_Solar_State__c ='MA')]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.assertEquals(1, oppRecord.Residential_Equipment__r.size());
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            if (!oppRecord.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.assertEquals(8, oppRecord.Partner_Tasks__r.size());
            } else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.assertEquals(5, oppRecord.Partner_Tasks__r.size());
            }
            oppRecord.Contract_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);

            //Assert that Joint Application Co_Applicant_Status is null (while Contract_Status is Completed)
            //Story jointOpp for testing later
            if (oppRecord.Application_Type__c == 'Joint') {
                System.assertNotEquals('Completed', oppRecord.Co_Applicant_Signature_Status__c);
                jointOpp = oppRecord;
            }
        }

        update oppListToUpdate;

        partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c, Opportunity__r.Name, Opportunity__r.Co_Applicant_Signature_Status__c,
                Opportunity__r.Contract_Status__c, Opportunity__r.Application_Type__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = FALSE AND Lead__r.LASERCA__Home_State__c = 'MA'
        ];

        //Partner Task of "Obtain Contract Signature" should be Pending for Joint Application
        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                if (partnerTaskAssertion.Opportunity__r.Application_Type__c == 'Joint') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                } else {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
            if (partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals( 'Pending', partnerTaskAssertion.Status__c);
                }
            } else {
                if (partnerTaskAssertion.Opportunity__r.Application_Type__c == 'Joint' && partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                    System.assertEquals( 'Incomplete', partnerTaskAssertion.Status__c);
                } else if (partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                    System.assertEquals( 'Pending', partnerTaskAssertion.Status__c);
                }                 
            }                
        }

        jointOpp.Co_Applicant_Signature_Status__c = 'Completed';
        update jointOpp;

        Partner_Task__c jointPartnerTask = [
            SELECT Name, Status__c, Opportunity__r.Id
            FROM Partner_Task__c
            WHERE Opportunity__r.Id = :jointOpp.Id
            AND Name = 'Obtain Contract Signature'
        ];

        System.assertEquals('Complete', jointPartnerTask.Status__c);

        Test.stopTest();
    }

    @isTest static void testAfterLeadConversionCounterSignature() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = false];
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        convertLeads(leadList, 0);

        Test.startTest();
        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = FALSE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Incomplete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Incomplete', partnerTaskAssertion.Status__c);
            }
        }

        LoanUnderwriting.approveLeads(leadList);

        partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = FALSE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
            }
        }

        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c, Product__c, Application_Type__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r),
                                      (SELECT Id, Product__r.Disbursal_Terms__c FROM Loans__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = FALSE
                                      AND (State_ab__c = 'MA' OR Community_Solar_State__c ='MA')]) {
            //Assert that the Eqiupment carried over to the Opportunity on conversion
            System.assertEquals(1, oppRecord.Residential_Equipment__r.size());
            //Assert that the Partner Tasks carried over to the Opportunity on conversion.
            System.assertEquals(8, oppRecord.Partner_Tasks__r.size());

            oppRecord.Contract_Status__c = 'Completed';
            if (oppRecord.Application_Type__c == 'Joint'){
                oppRecord.Co_Applicant_Signature_Status__c = 'Completed';
            }
            oppRecord.BlueWave_Signature_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);
        }

        update oppListToUpdate;

        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.DOER_Solar_Loann__c = FALSE
                                                     AND Loan__r.State__c = 'MA']) {
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c );
            }
            if (!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Mechanical Installation') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }   
            } else {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
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
        Date myDate = Date.newInstance(2015, 2, 17);

        convertLeads(leadList, 0);
        Test.startTest();

      List<Residential_Equipment__c> equipmentList = [SELECT Id, Mechanically_Installed__c, Interconnected__c, DOER_Solar_Loan__c 
                                                        FROM Residential_Equipment__c];
      for (Residential_Equipment__c equipment : equipmentList){
            if (!equipment.DOER_Solar_Loan__c) {
                equipment.Mechanically_Installed__c = true;
                equipmentListToUpdate.add(equipment);
            }
      }
      update equipmentListToUpdate;
      equipmentListToUpdate.clear();
      
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c 
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.DOER_Solar_Loann__c = FALSE
                                                     AND Loan__r.State__c = 'MA']) {
            if (partnerTaskAssertion.Name == 'Mechanical Installation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }    
            if (partnerTaskAssertion.Name == 'Interconnection') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
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
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.State__c = 'MA']) {
            if(!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Interconnection') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }   
            }else {
                if(partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
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
            System.assertEquals(1, leadRecordAssertion.Loans__r.size());
            if(!leadRecordAssertion.DOER_Solar_Loan__c) {
                //Assert that six parent partner tasks were created for the standard loan when the lead was set to qualified. 
                System.assertEquals(6, leadRecordAssertion.Partner_Tasks__r.size());
            }else {
                //Assert that six parent partner tasks were created for the MSLP loan when the lead was set to qualified. 
                System.assertEquals(6, leadRecordAssertion.Partner_Tasks__r.size());
            }       
        }    
        //Assert that the equipment record mapped to the loan on creation
        for (Loan__c loanRecordAssertion : [SELECT Id, (SELECT Id FROM Residential_Equipment__r) FROM Loan__c]) {
            System.assertEquals(1, loanRecordAssertion.ResidentiaL_Equipment__r.size());
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

        List<Attachment> attachments = new List<Attachment>();

        for (Lead leadRecord : leadList) {
            //test income documentation 

            //Insert the PayStub subTask            
            Attachment attachmentPaystub = new Attachment();
            attachmentPaystub.Name =  String.valueOf('test.txt');
            attachmentPaystub.body = bodyBlob;
            attachmentPaystub.ParentId = leadRecord.Id;
            attachmentPaystub.Description = 'PayStub' + ' ' + leadRecord.Id;
            attachments.add(attachmentPaystub);

            if(leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                //Insert the SSN/Pension Award Letter or Bank Statement subTask                     
                Attachment attachmentSSNAwardLetter = new Attachment();
                attachmentSSNAwardLetter.Name =  String.valueOf('test.txt');
                attachmentSSNAwardLetter.body = bodyBlob;
                attachmentSSNAwardLetter.ParentId = leadRecord.Id;
                attachmentSSNAwardLetter.Description = 'SSN Award Letter' + ' ' + leadRecord.Id;
                attachments.add(attachmentSSNAwardLetter);
            }
            if(!leadRecord.Retired__c&& leadRecord.Self_Employed__c) {
                //Insert the Tax Return                     
                Attachment attachmentTaxReturnTwoYears = new Attachment();
                attachmentTaxReturnTwoYears.Name =  String.valueOf('test.txt');
                attachmentTaxReturnTwoYears.body = bodyBlob;
                attachmentTaxReturnTwoYears.ParentId = leadRecord.Id;
                attachmentTaxReturnTwoYears.Description = 'Tax Return (Two Years Previous)' + ' ' + leadRecord.Id;
                attachments.add(attachmentTaxReturnTwoYears);

                //Insert the Tax Return             
                Attachment attachmentOneYear = new Attachment();
                attachmentOneYear.Name =  String.valueOf('test.txt');
                attachmentOneYear.body = bodyBlob;
                attachmentOneYear.ParentId = leadRecord.Id;
                attachmentOneYear.Description = 'Provide Tax Return (Previous Year)' + ' ' + leadRecord.Id;
                attachments.add(attachmentOneYear);
            }     

            //Insert the Sales agreement                    
            Attachment attachmentSalesAgreement = new Attachment();
            attachmentSalesAgreement.Name =  String.valueOf('test.txt');
            attachmentSalesAgreement.body = bodyBlob;
            attachmentSalesAgreement.ParentId = leadRecord.Id;
            attachmentSalesAgreement.Description = 'Sales Agreement' + ' ' + leadRecord.Id;
            attachments.add(attachmentSalesAgreement);

            if(leadRecord.DOER_Solar_Loan__c) {
                //Insert the Sales agreement                    
                Attachment attachmentTechnicalApplication = new Attachment();
                attachmentTechnicalApplication.Name =  String.valueOf('test.txt');
                attachmentTechnicalApplication.body = bodyBlob;
                attachmentTechnicalApplication.ParentId = leadRecord.Id;
                attachmentTechnicalApplication.Description = 'MSLP Technical Confirmation' + ' ' + leadRecord.Id;
                attachments.add(attachmentTechnicalApplication);
            }
        }

        insert attachments;


        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = true]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
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


        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if(partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Income Documentation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide all System Information') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Provide all Customer Information') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if(partnerTaskAssertion.Name == 'Provide Technical Confirmation Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
        }           
    }

    @isTest static void testAfterLeadConversionMSLP() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = TRUE];
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        convertLeads(leadList, 0);
        Test.startTest();

        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = TRUE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assert(partnerTaskAssertion.Status__c == 'Incomplete');
            }
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assert(partnerTaskAssertion.Status__c == 'Incomplete');
            }
        }

        LoanUnderwriting.approveLeads(leadList);

        partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = TRUE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if(partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if(partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
            }
        }

        for (Opportunity oppRecord : [SELECT Id, DOER_Solar_Loan__c,
                                      (SELECT Id FROM Residential_Equipment__r), 
                                      (SELECT Id FROM Partner_Tasks__r)
                                      FROM Opportunity
                                      WHERE DOER_Solar_Loan__c = TRUE]) {
            System.assertEquals(1, oppRecord.Residential_Equipment__r.size());
            if (!oppRecord.DOER_Solar_Loan__c) {
                System.assertEquals(6, oppRecord.Partner_Tasks__r.size());
            } else {
                System.assertEquals(6, oppRecord.Partner_Tasks__r.size());
            }              

            oppRecord.Contract_Status__c = 'Completed';
            oppRecord.Bluewave_Signature_Status__c = 'Completed';
            oppListToUpdate.add(oppRecord);
        }

        update oppListToUpdate;

        partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.DOER_Solar_Loann__c = TRUE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (partnerTaskAssertion.Name == 'Obtain Contract Signature') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Mechanical Installation') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }   
            } else {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }                 
            }
        }
        Test.stopTest();
    }

    @isTest static void testEquipmentUpdatesMSLP() {
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = FALSE AND LASERCA__Home_State__c = 'MA'];
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Attachment> attachList = new List<Attachment>();        
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        Date myDate = Date.newInstance(2015, 2, 17);

        convertLeads(leadList, 0);
        Test.startTest();

        List<Residential_Equipment__c> equipmentList = [SELECT Id, Mechanically_Installed__c, Interconnected__c, DOER_Solar_Loan__c 
                                                        FROM Residential_Equipment__c
                                                        WHERE Loan__r.State__c = 'MA'
                                                        AND DOER_Solar_Loan__c = FALSE
                                                        AND Lead__r.Retired__c = TRUE];
        for (Residential_Equipment__c equipment : equipmentList){
            equipment.Mechanically_Installed__c = true;
            equipmentListToUpdate.add(equipment);
        }
        update equipmentListToUpdate;
        equipmentListToUpdate.clear();
        
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c 
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.DOER_Solar_Loann__c = TRUE
                                                     AND Loan__r.State__c = 'MA'
                                                     AND Lead__r.Retired__c = TRUE]) {
            if (partnerTaskAssertion.Name == 'Mechanical Installation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }       
            if (partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
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

        if (equipmentListToUpdate.size() > 0) {
            update equipmentListToUpdate;           
        }
        
        for (Partner_Task__c partnerTaskAssertion : [SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c 
                                                     FROM Partner_Task__c
                                                     WHERE Loan__r.State__c = 'MA'
                                                     AND Lead__r.Retired__c = TRUE]) {
            if (!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Interconnection') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }   
            } else {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }                       
            }                   
        }               
        Test.stopTest();
    }

    @isTest static void testInterconnectionTaskRollback() {
        List<Lead> leadList = [SELECT Id FROM Lead WHERE DOER_Solar_Loan__c = FALSE AND LASERCA__Home_State__c = 'MA'];
        List<Attachment> attachList = new List<Attachment>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();
        Date myDate = Date.newInstance(2015, 2, 17);

        convertLeads(leadList, 0);
        Test.startTest();

        List<Residential_Equipment__c> equipmentList = [
            SELECT Id, Mechanically_Installed__c, Interconnected__c, DOER_Solar_Loan__c
            FROM Residential_Equipment__c
            WHERE Loan__r.State__c = 'MA'
            AND DOER_Solar_Loan__c = FALSE
            AND Lead__r.Retired__c = TRUE
        ];


        for (Residential_Equipment__c equipment : equipmentList){
            equipment.Mechanically_Installed__c = true;
            equipmentListToUpdate.add(equipment);
        }
        update equipmentListToUpdate;
        equipmentListToUpdate.clear();

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

        if (equipmentListToUpdate.size() > 0) {
            update equipmentListToUpdate;
        }

        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.State__c = 'MA'
            AND Lead__r.Retired__c = TRUE
        ];

        for (Partner_Task__c partnerTaskAssertion : partnerTasks) {
            if (!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Interconnection') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            } else {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
        }

        List<Residential_Equipment__c> equipsToUpdate = new List<Residential_Equipment__c>();

        for (Residential_Equipment__c resiEquip : equipmentList){
            resiEquip.Interconnected__c = false;
            equipsToUpdate.add(resiEquip);

        }
        update equipsToUpdate;


        List<Partner_Task__c> updatedPartnerTasks = [
            SELECT Id, Name, Status__c, Loan__r.DOER_Solar_Loann__c
            FROM Partner_Task__c
            WHERE Loan__r.State__c = 'MA'
            AND Lead__r.Retired__c = TRUE];

        for (Partner_Task__c partnerTaskAssertion : updatedPartnerTasks) {
            if (!partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Interconnection') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }
            } else {
                if (partnerTaskAssertion.Name == 'Report Interconnection to MCEC') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }
            }
        }

        Test.stopTest();
    }

    public static void convertLeads(List<Lead> leadList){
        convertLeads(leadList, 0);
    }

    public static void convertLeads(List<Lead> leadList, Integer counter) {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=true LIMIT 1];
        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }
        update leadList;
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead l :leadList){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);
        }
        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        for (Database.LeadConvertResult lcr : lcrs)  {
            if (!lcr.isSuccess() && counter < 3) {
                Lead failedLead = new Lead (id = lcr.getLeadId());
                convertLeads( new List<Lead>{failedLead}, counter+1);
            } else if (!lcr.isSuccess()) {
                System.assertEquals(null, System.JSON.serializePretty(lcr.getErrors()));
            }
        }
    }

    public static void changeLeadUpdateDummy(List<Lead> leadList) {
      for (Lead leadRecord : leadList) {
          leadRecord.Update_Dummy__c = !leadRecord.Update_Dummy__c;
      }
      update leadList;
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

    @isTest static void testNYApprovedBuildingPermit() {
        Lead nyLead = [SELECT Id FROM Lead WHERE FirstName = 'NY' LIMIT 1];
        List<Partner_Task__c> partnerTasks = [
            SELECT Id, Name, Status__c
            FROM Partner_Task__c
            WHERE Name = 'Building Permit'
            AND Lead__c = :nyLead.Id
        ];
        System.assertEquals(1, partnerTasks.size());
        System.assertEquals('Incomplete', partnerTasks[0].Status__c);

        List<Residential_Equipment__c> res = [SELECT Id FROM Residential_Equipment__c WHERE Lead__c = :nyLead.Id];
        System.assertEquals(1, res.size());
        Residential_Equipment__c re = res[0];
        re.Labor_Performed__c = 'Other';
        re.Materials_Supplied__c = 'Other';

        Attachment permit = new Attachment();
        permit.Name =  String.valueOf('test.txt');
        permit.body = Blob.valueOf('Unit Test Attachment Body');
        permit.ParentId = re.Id;
        permit.Description = 'Building Permit';
        insert permit;
        update re;

        partnerTasks = [
            SELECT Id, Name, Status__c
            FROM Partner_Task__c
            WHERE Name = 'Building Permit'
            AND Lead__c = :nyLead.Id
        ];
        System.assertEquals('Complete', partnerTasks[0].Status__c);
    }

    @IsTest static void testAttachmentUploadsAfterConversion() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        List<Lead> leadList = [
            SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c, ConvertedContactId
            FROM Lead
            WHERE DOER_Solar_Loan__c = FALSE];
        convertLeads(leadList, 0);
        Test.startTest();
        leadList = [
            SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c, ConvertedContactId
            FROM Lead
            WHERE DOER_Solar_Loan__c = FALSE];
        List<Attachment> attachments = new List<Attachment>();
        for (Lead leadRecord : leadList) {
            attachments.add(getAttachment(leadRecord.ConvertedContactId, 'PayStub' + ' ' + leadRecord.Id));

            if (leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'SSN Award Letter' + ' ' + leadRecord.Id));
            }
            if (!leadRecord.Retired__c && leadRecord.Self_Employed__c) {
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Tax Return (Two Years Previous)' + ' ' + leadRecord.Id));
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Tax Return (Previous Year)' + ' ' + leadRecord.Id));
            }
            attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Sales Agreement' + ' ' + leadRecord.Id));
        }
        insert attachments;

        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = FALSE]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
        loanListToUpdate[0].Requested_Loan_Amount__c = 10000;
        update loanListToUpdate;

        for (Residential_Equipment__c equipmentRecord : [
            SELECT Id, Lead__c, Generator_Nameplate_Capacity__c, Type_of_Module__c, Type_of_Inverter__c,
                Number_of_Inverters__c, Module_Manufacturer__c, Module_Model_Number__c, Number_of_Modules__c,
                Inverter_Manufacturer__c, Inverter_Model_Number__c
            FROM Residential_Equipment__c
            WHERE DOER_Solar_Loan__c = FALSE]) {
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
        leadList = [
            SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c, ConvertedContactId
            FROM Lead
            WHERE DOER_Solar_Loan__c = FALSE];
        changeLeadUpdateDummy(leadList);
        Test.stopTest();
        List<Partner_Task__c> partnerTaskList = [
            SELECT Id, Name, Status__c, Parent_Task__r.Lead__r.Name, Parent_Task__r.Id,
                Loan__r.DOER_Solar_Loann__c, Child_MSLP_Identifier__c
            FROM Partner_Task__c
        ];
        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if (partnerTaskAssertion.Child_MSLP_Identifier__c == false) {
                if (partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
            if (partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c == false) {
                if (partnerTaskAssertion.Name == 'Provide Income Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Provide all System Information') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Provide all Customer Information') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
                if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                    System.assertEquals('Pending', partnerTaskAssertion.Status__c);
                }
            }
        }
    }

    @IsTest static void testMSLPAttachmentUploadsAfterConversion() {
        Date myDate = Date.newInstance(2015, 2, 17);
        List<Loan__c> loanListToUpdate = new List<Loan__c>();
        List<Residential_Equipment__c> equipmentListToUpdate = new List<Residential_Equipment__c>();

        List<Lead> leadList = [
            SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c, ConvertedContactId
            FROM Lead
            WHERE DOER_Solar_Loan__c = TRUE
        ];
        convertLeads(leadList, 0);
        Test.startTest();
        leadList = [
            SELECT Id, Update_Dummy__c, Retired__c, Self_Employed__c, Product__r.Name, DOER_Solar_Loan__c, ConvertedContactId
            FROM Lead
            WHERE DOER_Solar_Loan__c = TRUE
        ];
        List<Attachment> attachments = new List<Attachment>();
        for (Lead leadRecord : leadList) {
            attachments.add(getAttachment(leadRecord.ConvertedContactId, 'PayStub' + ' ' + leadRecord.Id));

            if (leadRecord.Retired__c && !leadRecord.Self_Employed__c) {
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'SSN Award Letter' + ' ' + leadRecord.Id));
            }
            if (!leadRecord.Retired__c && leadRecord.Self_Employed__c) {
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Tax Return (Two Years Previous)' + ' ' + leadRecord.Id));
                attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Tax Return (Previous Year)' + ' ' + leadRecord.Id));
            }
            attachments.add(getAttachment(leadRecord.ConvertedContactId, 'Sales Agreement' + ' ' + leadRecord.Id));
            attachments.add(getAttachment(leadRecord.ConvertedContactId, 'MSLP Technical Confirmation' + ' ' + leadRecord.Id));
        }
        insert attachments;

        for (Loan__c loanRecord : [SELECT Id, Commencement_Datee__c, Product__r.Name FROM Loan__c WHERE DOER_Solar_Loann__c = TRUE]) {
            loanRecord.Commencement_Datee__c = myDate;
            loanListToUpdate.add(loanRecord);
        }
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
        WHERE Loan__r.DOER_Solar_Loann__c = TRUE];

        Test.stopTest();

        for (Partner_Task__c partnerTaskAssertion : partnerTaskList) {
            if (partnerTaskAssertion.Name == 'Provide PayStub Documentation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide SSN/Pension Award Letter or Bank Statement') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide Tax Return (Previous Year)') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide Tax Return (Two Years Previous)') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide Income Documentation') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide Sales Agreement') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide all System Information') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Provide all Customer Information') {
                System.assertEquals('Complete', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Name == 'Under BlueWave Review') {
                System.assertEquals('Pending', partnerTaskAssertion.Status__c);
            }
            if (partnerTaskAssertion.Loan__r.DOER_Solar_Loann__c) {
                if (partnerTaskAssertion.Name == 'Provide Technical Confirmation Documentation') {
                    System.assertEquals('Complete', partnerTaskAssertion.Status__c);
                }
            }
        }
    }

    private static Attachment getAttachment(Id parentId, String description) {
        Attachment attachment = new Attachment();
        attachment.Name = 'test.txt';
        attachment.Body = Blob.valueOf('Unit Test Attachment Body');
        attachment.ParentId = parentId;
        attachment.Description = description;
        return attachment;
    }

    @IsTest static void testDaysPastDue() {
        List<Loan__c> loans = [SELECT Id, Days_Past_Due__c, Number_of_Days_Past_Due__c FROM Loan__c];
        System.assertEquals(5, loans.size());

        Map<Integer, String> expectedDPD = new Map<Integer, String>();
        expectedDPD.put(null, null);
        expectedDPD.put(0, null);
        expectedDPD.put(1, '1-30');
        expectedDPD.put(30, '1-30');
        expectedDPD.put(31, '31-60');
        expectedDPD.put(60, '31-60');
        expectedDPD.put(61, '61-90');
        expectedDPD.put(90, '61-90');
        expectedDPD.put(91, '91+');
        expectedDPD.put(101, '91+');

        Integer loanIndex = 0, loansChecked = 0;
        for (Integer nDPD : expectedDPD.keySet()) {
            if (loanIndex < loans.size()) {
                loans[loanIndex].Number_of_Days_Past_Due__c = nDPD;
                loanIndex++;
            } else {
                LoanHandler.resetTriggerContext();
                update loans;
                checkDaysPastDue(expectedDPD);
                loanIndex = 0;
                loansChecked += loans.size();
            }
        }
        LoanHandler.resetTriggerContext();
        update loans;
        checkDaysPastDue(expectedDPD);
        loansChecked += loans.size();
        System.assert(loansChecked >= expectedDPD.keySet().size(), 'We should check ' + expectedDPD.keySet().size() + ' + Days Past Due combinations, but only checked ' + loansChecked);
    }

    private static void checkDaysPastDue(Map<Integer, String> expectedDPD) {
        List<Loan__c> loans = [SELECT Id, Days_Past_Due__c, Number_of_Days_Past_Due__c FROM Loan__c];
        for (Loan__c loan : loans) {
            System.assertEquals(expectedDPD.get((Integer) loan.Number_of_Days_Past_Due__c), loan.Days_Past_Due__c);
        }
    }
}