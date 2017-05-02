@isTest
public without sharing class SLPControllersTestclass {     
    @testSetup public static void setupTestUser(){  
        Test.startTest();
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name='Partner Community User (Custom)'];        

 		Account accountRecord = new Account(Name = 'BlueWave Customer Care');
 		insert accountRecord;

        List<String> partnerSetUpIds = new List<String>();  
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

		RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE Name = 'Partner Contact'];
 		Contact contactRecord = new Contact(
 			FirstName = 'User', 
 			LastName = 'Swain', 
 			AccountId = accountRecord.Id,
 			RecordType = partnerRecordType,
 			Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(1));
 		Insert contactRecord; 		

        Account accountRecordExec = new Account(Name = 'BlueWave Customer Care');
        insert accountRecordExec;

        Contact contactRecordExec = new Contact(
            FirstName = 'Executive', 
            LastName = 'Swain', 
            AccountId = accountRecordExec.Id,
            RecordType = partnerRecordType,
            Partner_Lookup__c = partnerSetUpIds.get(0),
            Sales_Representative__c = partnerSetUpIds.get(2));
        Insert contactRecordExec;           

 		User userRecord = new User(
                FirstName = 'User',
                Lastname ='Testing',                 
 				Alias = 'cswain', 
 				Email = 'tropicole34@aol.com', 
 				Emailencodingkey ='UTF-8',                 
                PortalRole = 'Manager',
 				Languagelocalekey ='en_US',
                Localesidkey ='en_US', 
                Profileid = profileRecord.Id, 
                Country ='United States',
                IsActive = true,
                ContactId = contactRecord.Id,
                Timezonesidkey='America/Los_Angeles', 
                Username='tropicole34@aol.com');
		Insert userRecord; 

        User executiveRecord = new User(
                FirstName = 'Executive',     
                Lastname ='Testing',                          
                Alias = 'cmswain', 
                Email = 'colematthewswain@gmail.com', 
                Emailencodingkey ='UTF-8', 
                PortalRole = 'Executive',
                Languagelocalekey ='en_US',
                Localesidkey ='en_US', 
                Profileid = profileRecord.Id, 
                Country ='United States',
                IsActive = true,
                ContactId = contactRecordExec.Id,
                Timezonesidkey='America/Los_Angeles', 
                Username='colematthewswain@gmail.com');
        Insert executiveRecord;         
		Test.stopTest();		                   
    }	

    @isTest static void testAddNewLeadRecord() {    	
        Test.startTest();
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
    	Lead newLead = new Lead(
    		FirstName = 'Cole',
    		LastName = 'Swain',
    		LASERCA__Home_Address__c = '55 Boston St.',
    		LASERCA__Home_City__c = 'Boston',
    		LASERCA__Home_State__c = 'MA',
    		LASERCA__Home_Zip__c = '02052',
    		Email = 'colemswain@gmail.com',
    		LASERCA__Social_Security_Number__c = '000000001',
    		System_Cost__c = 25000,
    		Annual_Income_Currency__c = 150000,
    		Credit_Check_Acknowledged__c = true,
    		Privacy_Policy_Acknowledged__c = true,
    		Automatic_Product_Assignment__c = true,
    		Loan_Term__c = 120,
    		Product_Program__c = 'BlueWave Solar Loan',
    		Pre_Approval_Form__c = true,
    		Unfinished_Lead__c = true,
    		Utility_Bill_Access_Acknowledged__c = true 		
    	);
        List<Lead> leadList;

        System.assertEquals(SLPAddCustomer.getCreditCheckTimeout(), 60000);
    	System.runAs(partnerUser) {
            SLPAddCustomer.addNewLeadRecord(newLead);

            leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
                        FROM Lead
                        WHERE LastName = 'Swain'];
            System.assertEquals(leadList.size(), 1);
            System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);

            SLPAddCustomer.pullCreditStatus(leadList[0]);
            
            // Laser Credit Access trigger should unset the pull credit report checkbox
            leadList = [SELECT Id, LASERCA__Pull_Credit_Report__c
                                   FROM Lead
                                   WHERE LastName = 'Swain'];            
            System.assertEquals(leadList[0].LASERCA__Pull_Credit_Report__c, false);
    	}
    	Test.stopTest();

        // LCA should set pull credit once the future method fires
        List<LASERCA__Personal_Credit_Report__c> pcrs = [SELECT Id
                                                         FROM LASERCA__Personal_Credit_Report__c
                                                         WHERE LASERCA__Lead__c = :leadList[0].Id];
        System.assertEquals(pcrs.size(), 1);

        System.assertEquals(SLPAddCustomer.checkCreditStatus(leadList[0]), 'Unqualified');
    }

    @isTest static void testAlertsHandlerUser() {
    	Test.startTest();
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
    	Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];     
    	List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
    	Partner_Alert__c partnerAlertRecord;
    	String partnerId;
    	String alertId;

    	Partner_Alert__c partnerAlert = new Partner_Alert__c(
    		Name = 'Test Alert', 
    		Active__c = true, 
    		Body__c = 'Test', 
            Audience__c = 'Managers',
    		Importance__c = '1');
    	insert partnerAlert;

    	Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
    		Name = 'BlueWave Customer Care',
    		Partner__c = partnerRecord.Id,
            Sales_Representative__c = salesRepRecord.Id,
    		Partner_Alert__c = partnerAlert.Id);
    	insert partnerAlertFilter;

    	List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

    	System.runAs(partnerUser) {
    		partnerId = String.valueOf(partnerRecord.Id);
    		partnerAlertList = SLPAlertsHandler.getPartnerAlerts(partnerId);

    		alertId = String.valueOf(partnerAlertList.get(0).Id);
    		partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
    	}
    	Test.stopTest();
    }

    @isTest static void testAlertsHandlerExecutive() {
        Test.startTest();
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];     
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        Partner_Alert__c partnerAlertRecord;
        String partnerId;
        String alertId;

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert', 
            Active__c = true, 
            Body__c = 'Test', 
            Audience__c = 'Executives',
            Importance__c = '1');
        insert partnerAlert;

        Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
            Name = 'BlueWave Customer Care',
            Partner__c = partnerRecord.Id,
            Sales_Representative__c = salesRepRecord.Id,
            Partner_Alert__c = partnerAlert.Id);
        insert partnerAlertFilter;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);
            partnerAlertList = SLPAlertsHandler.getPartnerAlerts(partnerId);

            alertId = String.valueOf(partnerAlertList.get(0).Id);
            partnerAlertRecord = SLPAlertsHandler.getPartnerAlert(alertId);
        }
        Test.stopTest();
    }     

    @isTest static void testCreditStatus1() {
    	Test.startTest();
    	List<Lead> leadList = new List<Lead>();
    	List<Product2> productList = new List<Product2>();
    	List<Product2> productReturnList = new List<Product2>();
    	List<Lead> leadReturnList = new List<Lead>();


    	String partnerId;
    	String leadId;
    	String searchValue = null;

        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];
    	Lead newLead = new Lead(
    		FirstName = 'Cole',
    		LastName = 'Swain',
    		Company = 'Cole Swain',
    		LASERCA__Home_Address__c = '55 Boston St.',
    		LASERCA__Home_City__c = 'Boston',
    		LASERCA__Home_State__c = 'MA',
    		LASERCA__Home_Zip__c = '02052',
    		Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,                                  
    		LASERCA__Social_Security_Number__c = '000000001',
    		System_Cost__c = 25000,
    		Annual_Income_Currency__c = 150000,
    		Credit_Check_Acknowledged__c = true,
    		Privacy_Policy_Acknowledged__c = true,
    		Automatic_Product_Assignment__c = true,
    		Loan_Term__c = 120,
    		Product_Program__c = 'BlueWave Solar Loan',
    		Pre_Approval_Form__c = true,
    		Unfinished_Lead__c = true,
    		Utility_Bill_Access_Acknowledged__c = true 		
    	);
    	insert newLead;

    	productList = LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
    	insert productList;

        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        Lead lead = [SELECT Id, LASER_Credit_Score__c, Email
                     FROM Lead 
                     WHERE FirstName = 'leadMALoanTerm10Rate699' LIMIT 1];
        System.assertEquals('710', lead.LASER_Credit_Score__c);

    	System.runAs(partnerUser) {
            productReturnList = SLPCreditStatus.getCustomerProducts(lead.Id);
            System.assertEquals(2, productReturnList.size());
            Product2 prod = SLPCreditStatus.getSelectedProduct(productReturnList[0].Id);
            SLPCreditStatus.sendApplication(lead.Id, prod, 12);
            System.assertEquals(1, MessagingService.emailsSent.size());
            
    	}
    	Test.stopTest();
    }

        @isTest static void testCreditStatus2() {
        Test.startTest();
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
            Company = 'Cole Swain',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,              
            LASERCA__Social_Security_Number__c = '000000001',
            System_Cost__c = 25000,
            Annual_Income_Currency__c = 150000,
            Credit_Check_Acknowledged__c = true,
            Privacy_Policy_Acknowledged__c = true,
            Automatic_Product_Assignment__c = true,
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true      
        );
        insert newLead;

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);           
            leadList = SLPCreditStatus.searchLeads(searchValue, newLead.Id);
            leadList.clear();   
            leadList = SLPCreditStatus.searchLeads('Test', newLead.Id);
            leadList.clear();        

        }
        Test.stopTest();
    }

    @isTest static void testCreditStatus1Exec() {
        Test.startTest();
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
            Company = 'Cole Swain',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,                                  
            LASERCA__Social_Security_Number__c = '000000001',
            System_Cost__c = 25000,
            Annual_Income_Currency__c = 150000,
            Credit_Check_Acknowledged__c = true,
            Privacy_Policy_Acknowledged__c = true,
            Automatic_Product_Assignment__c = true,
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true      
        );
        insert newLead;

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            LeadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);           
            leadList = SLPCreditStatus.getLeads(searchValue, partnerId);
            leadList.clear();
            partnerId = null;
            leadList = SLPCreditStatus.getLeads(searchValue, partnerId);
            leadList.clear();               

            leadId = String.valueOf(leadReturnList[0].Id);
            productReturnList = SLPCreditStatus.getCustomerProducts(leadId);

        }
        Test.stopTest();
    }

        @isTest static void testCreditStatus2Exec() {
        Test.startTest();
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();
        List<Product2> productReturnList = new List<Product2>();
        List<Lead> leadReturnList = new List<Lead>();


        String partnerId;
        String leadId;
        String searchValue = null;

        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
        BSST__c salesRepRecord = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave Executive'];
        Lead newLead = new Lead(
            FirstName = 'Cole',
            LastName = 'Swain',
            Company = 'Cole Swain',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Email = 'colemswain@gmail.com',
            Partner_Lookup__c = partnerRecord.Id,
            Bs_Sales_ID__c = salesRepRecord.Id,              
            LASERCA__Social_Security_Number__c = '000000001',
            System_Cost__c = 25000,
            Annual_Income_Currency__c = 150000,
            Credit_Check_Acknowledged__c = true,
            Privacy_Policy_Acknowledged__c = true,
            Automatic_Product_Assignment__c = true,
            Loan_Term__c = 120,
            Product_Program__c = 'BlueWave Solar Loan',
            Pre_Approval_Form__c = true,
            Unfinished_Lead__c = true,
            Utility_Bill_Access_Acknowledged__c = true      
        );
        insert newLead;

        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadReturnList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;
        System.runAs(partnerUser) {
            partnerId = String.valueOf(partnerRecord.Id);           
            leadList = SLPCreditStatus.searchLeads(searchValue, newLead.Id);
            leadList.clear();   
            leadList = SLPCreditStatus.searchLeads('Test', newLead.Id);
            leadList.clear();        

        }
        Test.stopTest();
    }    

    @isTest static void testCustomerHandlerPartOne() {
    	User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'tropicole34@aol.com'];

    	List<Lead> leadList = new List<Lead>();
    	List<Loan__c> loanReturnList = new List<Loan__c>();
    	List<Product2> productList = new List<Product2>();
    	List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

    	String loanId;
    	String progressBarString;
    	String nullString = null;

    	Loan__c loanRecord;
    	Residential_Equipment__c equipmentRecord;

    	Test.startTest();
    	productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
    	insert productList;

		leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords(); 
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

		List<Loan__c> loanList = [SELECT Id FROM Loan__c];
		loanId = String.valueOf(loanList.get(0).Id);
        update loanList;            
        System.debug('the re is ' + partnerUser.Partner_ID__c + partnerUser.Sales_Representative_Id__c);
        System.debug('the re is ' + [SELECT Id, Name, Loan__r.Partner__r.Id, Loan__r.Sales_Agent__r.Id  FROM Residential_Equipment__c  ]);
    	System.runAs(partnerUser) {
			loanReturnList = SLPCustomerHandler.getAllCustomers('Test');
			loanReturnList.clear();
			loanReturnList = SLPCustomerHandler.getAllCustomers(nullString);
			equipmentRecord = SLPCustomerHandler.getCustomerInformation(loanId);
		}
        Test.stopTest();        
	}

    @isTest static void testCustomerHandlerPartTwo() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'tropicole34@aol.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        String progressBarString;
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords(); 
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;            
        System.debug('the re is ' + partnerUser.Partner_ID__c + partnerUser.Sales_Representative_Id__c);
        System.debug('the re is ' + [SELECT Id, Name, Loan__r.Partner__r.Id, Loan__r.Sales_Agent__r.Id  FROM Residential_Equipment__c  ]);
        System.runAs(partnerUser) {
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loanId);
            partnerTaskList.clear();
            partnerTaskList = SLPCustomerHandler.getLoanParentSubTasks(loanId);
        }
        Test.stopTest();        
    }    

    @isTest static void testCustomerHandlerPartOneExec() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'colematthewswain@gmail.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        String progressBarString;
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords(); 
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;            
        System.debug('the re is ' + partnerUser.Partner_ID__c + partnerUser.Sales_Representative_Id__c);
        System.debug('the re is ' + [SELECT Id, Name, Loan__r.Partner__r.Id, Loan__r.Sales_Agent__r.Id  FROM Residential_Equipment__c  ]);
        System.runAs(partnerUser) {
            loanReturnList = SLPCustomerHandler.getAllCustomers('Test');
            loanReturnList.clear();
            loanReturnList = SLPCustomerHandler.getAllCustomers(nullString);
            equipmentRecord = SLPCustomerHandler.getCustomerInformation(loanId);
        }
        Test.stopTest();        
    }

    @isTest static void testCustomerHandlerPartTwoExec() {
        User partnerUser = [SELECT Id, ContactId, Partner_ID__c, Sales_Representative_Id__c FROM User WHERE Email = 'colematthewswain@gmail.com'];

        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();

        String loanId;
        SLPCustomerHandler.ProgressBarData pbData = new SLPCustomerHandler.ProgressBarData();
        String nullString = null;

        Loan__c loanRecord;
        Residential_Equipment__c equipmentRecord;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords(); 
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);
        update loanList;            
        System.debug('the re is ' + partnerUser.Partner_ID__c + partnerUser.Sales_Representative_Id__c);
        System.debug('the re is ' + [SELECT Id, Name, Loan__r.Partner__r.Id, Loan__r.Sales_Agent__r.Id  FROM Residential_Equipment__c  ]);
        System.runAs(partnerUser) {
            pbData = SLPCustomerHandler.getProgressBarData(loanId);
            partnerTaskList = SLPCustomerHandler.getLoanCustomerTasks(loanId);
            partnerTaskList.clear();
            partnerTaskList = SLPCustomerHandler.getLoanParentSubTasks(loanId);
        }
        Test.stopTest();        
    }    

	@isTest static void testCustomerHandlerPartThree() {
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];	
    	List<Lead> leadList = new List<Lead>();
    	List<Loan__c> loanReturnList = new List<Loan__c>();
    	List<Product2> productList = new List<Product2>();    		
    	List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    	
    	String nullString = null;    	
    	String loanId;

    	Test.startTest();
    	productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
    	insert productList;

		leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();

        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

		List<Loan__c> loanList = [SELECT Id FROM Loan__c];
		loanId = String.valueOf(loanList.get(0).Id);  


		System.runAs(partnerUser) {

			disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, 'Test');
			disbursalList.clear();
			disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, nullString);
			disbursalList.clear();		
			disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, null);
			disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, 'Test');
            disbursalList.clear();            
			disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(nullString, nullString);			
			disbursalList.clear();
			disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, nullString);
			disbursalList.clear();
			disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, 'Test');

			List<Disbursal__c> disbursalUpdateList = [SELECT Id FROM Disbursal__c LIMIT 1];

    	Test.stopTest();				
		}
    }

    @isTest static void testCustomerHandlerPartThreeExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];   
        List<Lead> leadList = new List<Lead>();
        List<Loan__c> loanReturnList = new List<Loan__c>();
        List<Product2> productList = new List<Product2>();          
        List<Disbursal__c> disbursalList = new List<Disbursal__c>();
        
        String nullString = null;       
        String loanId;

        Test.startTest();
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();

        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;

        List<Loan__c> loanList = [SELECT Id FROM Loan__c];
        loanId = String.valueOf(loanList.get(0).Id);  

        System.runAs(partnerUser) {

            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, 'Test');
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();      
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, null);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getCompleteLoanDisbursals(nullString, 'Test');
            disbursalList.clear();            
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(nullString, nullString);         
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, nullString);
            disbursalList.clear();
            disbursalList = SLPCustomerHandler.getIncompleteLoanDisbursals(loanId, 'Test');

            List<Disbursal__c> disbursalUpdateList = [SELECT Id FROM Disbursal__c LIMIT 1];

        Test.stopTest();                
        }
    }

    @isTest static void testSaveCustomerInformationMethod() {
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];	
    	List<Lead> leadList = new List<Lead>();
    	List<Product2> productList = new List<Product2>();    		
    	
    	String loanId;
    	String equipmentId;
    	Residential_Equipment__c equipment;

    	productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
    	insert productList;

		leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;        
		List<Loan__c> loanList = [SELECT Id, Name, Commencement_Datee__c, System_Costt__c  FROM Loan__c];

        List<Residential_Equipment__c> equipmentList = [SELECT Id, Lead__r.Id, Name, Generator_Nameplate_Capacity__c, Type_of_Module__c, Number_of_Modules__c,
                                                           Type_of_Inverter__c, Number_of_Inverters__c, Mechanical_Installation_Date__c, Interconnection_date__c,
                                                           Mechanically_Installed__c, Interconnected__c, Module_Model_Number__c, Module_Manufacturer__c, 
                                                           Inverter_Manufacturer__c, Inverter_Model_Number__c
                                                        FROM Residential_Equipment__c];
        //Set the equipment name to a value greater than 80 characters for code coverage                                                    
        equipmentList.get(0).Module_Manufacturer__c = 'SolarEdgeSolarEdgeSolarEdgeSolarEdgeSolarEdge';
        equipmentList.get(0).Inverter_Manufacturer__c = 'SolarWorldSolarWorldSolarWorld';
        update equipmentList.get(0);

		loanId = String.valueOf(loanList.get(0).Id);        	
		equipmentId = String.valueOf(equipmentList.get(0).Id);
    	Test.startTest();		
    	System.runAs(partnerUser) {
    		SLPCustomerHandler.saveCustomerInformation(equipmentList.get(0), equipmentId, loanId, loanList.get(0));
    	}
    	Test.stopTest();
    }

    @isTest static void testSaveCustomerInformationMethodExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];   
        List<Lead> leadList = new List<Lead>();
        List<Product2> productList = new List<Product2>();          
        
        String loanId;
        String equipmentId;
        Residential_Equipment__c equipment;


        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;        
        List<Loan__c> loanList = [SELECT Id, Name, Commencement_Datee__c, System_Costt__c  FROM Loan__c];

        List<Residential_Equipment__c> equipmentList = [SELECT Id, Lead__r.Id, Name, Generator_Nameplate_Capacity__c, Type_of_Module__c, Number_of_Modules__c,
                                                           Type_of_Inverter__c, Number_of_Inverters__c, Mechanical_Installation_Date__c, Interconnection_date__c,
                                                           Mechanically_Installed__c, Interconnected__c, Module_Model_Number__c, Module_Manufacturer__c, 
                                                           Inverter_Manufacturer__c, Inverter_Model_Number__c
                                                        FROM Residential_Equipment__c];

        loanId = String.valueOf(loanList.get(0).Id);            
        equipmentId = String.valueOf(equipmentList.get(0).Id);
        Test.startTest();       
        System.runAs(partnerUser) {
            SLPCustomerHandler.saveCustomerInformation(equipmentList.get(0), equipmentId, loanId, loanList.get(0));
        }
        Test.stopTest();
    }    

    @isTest static void testDashboardHandler() {
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
    	List<Decimal> dashboardWidgetsList = new List<Decimal>();
    	List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
    	Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c];
    	String alertId;    	

    	Partner_Alert__c partnerAlert = new Partner_Alert__c(
    		Name = 'Test Alert', 
            Audience__c = 'Users; Executives',
    		Active__c = true, 
    		Body__c = 'Test', 
    		Importance__c = '1');
    	insert partnerAlert;

    	Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
    		Name = 'BlueWave Customer Care',
    		Partner__c = partnerRecord.Id,
    		Partner_Alert__c = partnerAlert.Id);
    	insert partnerAlertFilter;

    	List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

    	Test.startTest();		
    	System.runAs(partnerUser) {
            SLPDashboardHandler.DashboardWidgets widgets = SLPDashboardHandler.getDashboardWidgets();
    		partnerTaskList = SLPDashboardHandler.getTasksByStage('All');
    		partnerTaskList.clear();
    		partnerTaskList = SLPDashboardHandler.getTasksByStage('Provide All Customer Information');

    		alertId = String.valueOf(partnerAlert.Id);
    		SLPDashboardHandler.getPartnerAlerts();
    		SLPDashboardHandler.acknowledgePartnerAlert(alertId);
    		SLPDashboardHandler.partnerAlertRemindLater(alertId);
    	}
    	Test.stopTest();
    }  

    @isTest static void testDashboardHandlerExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        List<Decimal> dashboardWidgetsList = new List<Decimal>();
        List<Partner_Task__c> partnerTaskList = new List<Partner_Task__c>();
        Partner__c partnerRecord = [SELECT Id, Name, Logo__c FROM Partner__c];
        String alertId;     

        Partner_Alert__c partnerAlert = new Partner_Alert__c(
            Name = 'Test Alert', 
            Audience__c = 'Users; Executives',
            Active__c = true, 
            Body__c = 'Test', 
            Importance__c = '1');
        insert partnerAlert;

        Partner_Alert_Filter__c partnerAlertFilter = new Partner_Alert_Filter__c(
            Name = 'BlueWave Customer Care',
            Partner__c = partnerRecord.Id,
            Partner_Alert__c = partnerAlert.Id);
        insert partnerAlertFilter;

        List<Partner_Alert_Filter__c> partnerAlertFilterList = [SELECT Id, Name, Partner__r.Name FROM Partner_Alert_Filter__c];

        Test.startTest();       
        System.runAs(partnerUser) {
            SLPDashboardHandler.DashboardWidgets widgets = SLPDashboardHandler.getDashboardWidgets();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('All');
            partnerTaskList.clear();
            partnerTaskList = SLPDashboardHandler.getTasksByStage('Provide All Customer Information');

            alertId = String.valueOf(partnerAlert.Id);
            SLPDashboardHandler.getPartnerAlerts();
            SLPDashboardHandler.acknowledgePartnerAlert(alertId);
            SLPDashboardHandler.partnerAlertRemindLater(alertId);
        }
        Test.stopTest();
    }  

    @isTest static void testDashboardStageChartHandler() {
    	User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
    	Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

    	SLPDashboardStageChartHandler.StageChartResult result = new SLPDashboardStageChartHandler.StageChartResult(); 
    	List<Product2> productList = new List<Product2>();    	
    	List<Lead> leadList = new List<Lead>();	
    	List<Lead> leadUpdateList = new List<Lead>();	

    	Test.startTest();		    	
    	productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
    	insert productList;

		leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;
    	Partner_Task__c partnerTask = new Partner_Task__c(
    		Name = 'Under BlueWave Review',
    		Status__c = 'Pending',
    		Lead__c = leadList.get(0).Id,
    		Partner__c = partnerRecord.Id    		
    	);
    	insert partnerTask;

    	System.runAs(partnerUser) {
    		List<Partner_Task__c> partnerTaskList = [SELECT Id FROM Partner_Task__c];
    		System.debug('partnerTaskListx' + partnerTaskList);
			result = SLPDashboardStageChartHandler.getAll();
    	}
    	Test.stopTest();
    }    

    @isTest static void testDashboardStageChartHandlerExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];

        SLPDashboardStageChartHandler.StageChartResult result = new SLPDashboardStageChartHandler.StageChartResult(); 
        List<Product2> productList = new List<Product2>();      
        List<Lead> leadList = new List<Lead>(); 
        List<Lead> leadUpdateList = new List<Lead>();   

        Test.startTest();               
        productList = LoanTestRecordWarehouse.getLoanHandlerProductRecords();
        insert productList;

        leadList = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        for (Lead leadRecord : leadList) {
            leadRecord.Unfinished_Lead__c = false;
            leadRecord.Status = 'Pending Information';
        }    
        update leadList;

        for (Lead leadRecord : leadList) {
            leadRecord.Status = 'Qualified';
        }    
        update leadList;
        Partner_Task__c partnerTask = new Partner_Task__c(
            Name = 'Under BlueWave Review',
            Status__c = 'Pending',
            Lead__c = leadList.get(0).Id,
            Partner__c = partnerRecord.Id           
        );
        insert partnerTask;

        System.runAs(partnerUser) {
            List<Partner_Task__c> partnerTaskList = [SELECT Id FROM Partner_Task__c];
            System.debug('partnerTaskListx' + partnerTaskList);
            result = SLPDashboardStageChartHandler.getAll();
        }
        Test.stopTest();
    }        

    @isTest static void testUserHelper() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        String testString;
        List<String> testStringList = new List<String>();
        Test.startTest();               

        System.runAs(partnerUser) {
            testString = SLPUserHelper.getPartnerId();
            testStringList = SLPUserHelper.getPartnerLogo();
            testString = SLPUserHelper.getBWCCId();
        }
        Test.stopTest();
    }           

    @isTest static void testUserHelperExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        String testString;
        List<String> testStringList = new List<String>();
        Test.startTest();               

        System.runAs(partnerUser) {
            testString = SLPUserHelper.getPartnerId();
            testStringList = SLPUserHelper.getPartnerLogo();
            testString = SLPUserHelper.getBWCCId();
        }
        Test.stopTest();
    }

    @isTest static void testSLPSendApplicationEmail() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        String emailTest;
        Test.startTest();               

        System.runAs(partnerUser) {
            SLPAddCustomer.sendApplication('colemswain@gmail.com', 'mslp');
            SLPAddCustomer.sendApplication('colemswain@gmail.com', 'bwsl');
        }
        Test.stopTest();
    }    

    @isTest static void testViewPreQualifiedRecordsExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        Test.startTest();               

        System.runAs(partnerUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        Test.stopTest();
    }  

    @isTest static void testViewPreQualifiedRecordsUser() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        Test.startTest();               

        System.runAs(partnerUser) {
            SLPCreditStatus.viewPreQualifiedRecords();
        }
        Test.stopTest();
    }         

    @isTest static void testGetAnyUnseenRecordsExec() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'colematthewswain@gmail.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        Test.startTest();               

        System.runAs(partnerUser) {
            SLPCustomerHandler.getAnyUnseenLeads();
        }
        Test.stopTest();
    }  

    @isTest static void testGetAnyUnseenRecordsUser() {
        User partnerUser = [SELECT Id FROM User WHERE Email = 'tropicole34@aol.com'];
        Partner__c partnerRecord = [SELECT Id, Name FROM Partner__c];  
        Test.startTest();               

        System.runAs(partnerUser) {
            SLPCustomerHandler.getAnyUnseenLeads();
        }
        Test.stopTest();
    }                                                         
}