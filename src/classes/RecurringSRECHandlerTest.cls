@isTest
private class RecurringSRECHandlerTest{
    @testSetup public static void setupData() {
        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                    Total_Capital__c = 10000000,
                                                    Investor__c = 'The Bank',
                                                    Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
                    Name = 'Tranche Assignment Pending',
                    Tranche_Type__c = 'Holding',
                    Stage__c = 'Closed',
                    Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Product2 srecProduct = new Product2( Name = 'Market Price - $10 Fee',
            Family = 'Solar Loan',
            Product_Type__c = 'SREC',
            State__c = 'MA',
            ProductCode = 'SREC-2',
            SREC_Fee_Fixed_Rate__c = 10,
            IsActive = True);
        insert srecProduct;

        Partner__c partner = new Partner__c(Name = 'Installer Co');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'Joe Bob', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Active__c = True);
        insert chGateway;

        /* Only one Chargent Order to avoid error: No more than one executeBatch can be called from within a test method. 
        Please make sure the iterable returned from your start method matches the batch size, resulting in one executeBatch invocation */
        ChargentOrders__ChargentOrder__c alreadyReady = new ChargentOrders__ChargentOrder__c(
                                                        ChargentOrders__Bank_Account_Number__c = '00000000000',
                                                        ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                        ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                        ChargentOrders__Bank_Name__c = 'Originally Set to Ready',             
                                                        ChargentOrders__Bank_Account_Type__c = 'Checking',
                                                        ChargentOrders__Payment_Method__c = 'Check',
                                                        ChargentOrders__Gateway__c = chGateway.Id,
                                                        ChargentOrders__Credit_Amount__c = 0.03,
                                                        SREC_Status__c = 'Ready');
        ChargentOrders__ChargentOrder__c orderOne = new ChargentOrders__ChargentOrder__c(
                                                        ChargentOrders__Bank_Account_Number__c = '00000000000',
                                                        ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                        ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                        ChargentOrders__Bank_Name__c = 'Bank of Bank',             
                                                        ChargentOrders__Bank_Account_Type__c = 'Checking',
                                                        ChargentOrders__Payment_Method__c = 'Check',
                                                        ChargentOrders__Gateway__c = chGateway.Id,
                                                        ChargentOrders__Credit_Amount__c = 0,
                                                        SREC_Status__c = '');
        ChargentOrders__ChargentOrder__c orderTwo = new ChargentOrders__ChargentOrder__c(
                                                        ChargentOrders__Bank_Account_Number__c = '00000000000',
                                                        ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                        ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                        ChargentOrders__Bank_Name__c = 'Bank of Bank',             
                                                        ChargentOrders__Bank_Account_Type__c = 'Checking',
                                                        ChargentOrders__Payment_Method__c = 'Check',
                                                        ChargentOrders__Gateway__c = chGateway.Id,
                                                        ChargentOrders__Credit_Amount__c = 0,
                                                        SREC_Status__c = '');
        ChargentOrders__ChargentOrder__c orderThree = new ChargentOrders__ChargentOrder__c(
                                                        ChargentOrders__Bank_Account_Number__c = '00000000000',
                                                        ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                        ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                        ChargentOrders__Bank_Name__c = 'Bank of Bank',             
                                                        ChargentOrders__Bank_Account_Type__c = 'Checking',
                                                        ChargentOrders__Payment_Method__c = 'Check',
                                                        ChargentOrders__Gateway__c = chGateway.Id,
                                                        ChargentOrders__Credit_Amount__c = 0,
                                                        SREC_Status__c = '');
        insert new List<ChargentOrders__ChargentOrder__c>{alreadyReady, orderOne, orderTwo, orderThree};

        Lead leadOne = new Lead (   FirstName = 'One',
                                    LastName = 'Testcase',
                                    Company = 'Company one');
        Lead leadTwo = new Lead (   FirstName = 'Two',
                                    LastName = 'Testcase',
                                    Company = 'Company two');
        Lead leadThree = new Lead ( FirstName = 'Three',
                                    LastName = 'Testcase',
                                    Company = 'Company three');
        insert new List<Lead>{leadOne, leadTwo, leadThree};

        Account accountOne = new Account(Name = 'AccountOne');
        Account accountTwo = new Account(Name = 'AccountTwo');
        Account accountThree = new Account(Name = 'AccountThree');
        insert new List<Account>{accountOne, accountTwo, accountThree};

        Opportunity oppOne = new Opportunity (  Name = 'OppOne',
                                                AccountId = accountOne.Id,
                                                Email__c = 'jpentaleri@bluewavesolar.com',
                                                SREC_Product__c = srecProduct.Id, 
                                                StageName = 'Complete',
                                                CloseDate = Date.today().addYears(-1));
        Opportunity oppTwo = new Opportunity (  Name = 'OppTwo',
                                                AccountId = accountTwo.Id,
                                                Email__c = 'jpentaleri@bluewavesolar.com',
                                                SREC_Product__c = srecProduct.Id, 
                                                StageName = 'Complete',
                                                CloseDate = Date.today().addYears(-1));        
        Opportunity oppThree = new Opportunity (  Name = 'OppThree',
                                                AccountId = accountThree.Id,
                                                Email__c = 'jpentaleri@bluewavesolar.com',
                                                SREC_Product__c = srecProduct.Id, 
                                                StageName = 'Complete',
                                                CloseDate = Date.today().addYears(-1));
        insert new List<Opportunity>{oppOne, oppTwo, oppThree};

        Loan__c loanOne = new Loan__c ( Name = 'Jordan Testcase',
                                        Requested_Loan_Amount__c = 23000.00,
                                        Lead__c = leadOne.Id,
                                        Partner__c = partner.Id,
                                        Sales_Agent__c = salesRep.Id,
                                        Number_of_Days_Past_Due__c = 0,
                                        Opportunity__c = oppOne.Id,
                                        SREC_Direct_Deposit_Order__c = orderOne.Id,
                                        Loan_Tranche__c = loanTranchePending.Id);
        Loan__c loanTwo = new Loan__c ( Name = 'Jordan Testcase',
                                        Requested_Loan_Amount__c = 23000.00,
                                        Lead__c = leadTwo.Id,
                                        Partner__c = partner.Id,
                                        Sales_Agent__c = salesRep.Id,
                                        Number_of_Days_Past_Due__c = 0,
                                        Opportunity__c = oppTwo.Id,
                                        SREC_Direct_Deposit_Order__c = orderTwo.Id,
                                        Loan_Tranche__c = loanTranchePending.Id);        
        Loan__c loanThree = new Loan__c (Name = 'Jordan Testcase',
                                        Requested_Loan_Amount__c = 23000.00,
                                        Lead__c = leadThree.Id,
                                        Partner__c = partner.Id,
                                        Sales_Agent__c = salesRep.Id,
                                        Number_of_Days_Past_Due__c = 0,
                                        Opportunity__c = oppThree.Id,
                                        SREC_Direct_Deposit_Order__c = orderThree.Id,
                                        Loan_Tranche__c = loanTranchePending.Id);
        insert new List<Loan__c>{loanOne, loanTwo, loanThree};

        Residential_Equipment__c resiEquipOne = new Residential_Equipment__c(
                                    Name = 'One',
                                    Loan__c = loanOne.Id);
        Residential_Equipment__c resiEquipTwo = new Residential_Equipment__c(
                                    Name = 'Two',
                                    Loan__c = loanTwo.Id);
        Residential_Equipment__c resiEquipThree = new Residential_Equipment__c(
                                    Name = 'Three',
                                    Loan__c = loanThree.Id);
        insert new List<Residential_Equipment__c>{resiEquipOne, resiEquipTwo, resiEquipThree};

        Date mintDate = Date.newInstance(2018, 6, 6);

        SREC__c srecOne = new SREC__c(  Name = 'SREC one',
                                        Residential_Equipment__c = resiEquipOne.Id,
                                        Minted_Date__c = mintDate);
        SREC__c srecTwo = new SREC__c(  Name = 'SREC two',
                                        Residential_Equipment__c = resiEquipTwo.Id,
                                        Minted_Date__c = mintDate);
        SREC__c srecThree = new SREC__c(  Name = 'SREC three',
                                        Residential_Equipment__c = resiEquipThree.Id,
                                        Minted_Date__c = mintDate);
        insert new List<SREC__c>{srecOne, srecTwo, srecThree};

        SREC_Invoice__c invoice = new SREC_Invoice__c(  Name = 'SREC Invoice #1',
                                                        SREC__c = srecOne.Id,
                                                        Residential_Equipment__c = resiEquipOne.Id);
        SREC_Invoice__c invoiceTwo = new SREC_Invoice__c(   Name = 'SREC Invoice #2',
                                                            SREC__c = srecTwo.Id,
                                                            Residential_Equipment__c = resiEquipTwo.Id);
        SREC_Invoice__c invoiceThree = new SREC_Invoice__c( Name = 'SREC Invoice #3',
                                                            SREC__c = srecThree.Id,
                                                            Residential_Equipment__c = resiEquipThree.Id);
        insert new List<SREC_Invoice__c>{invoice, invoiceTwo, invoiceThree};


        alreadyReady.SREC_Invoice__c = invoice.Id;
        update alreadyReady;
    }

    static testMethod void updateSRECandOrder() {
        // Mocks quarterly process, where Orders are updated by the SREC trigger:
        List<ChargentOrders__ChargentOrder__c> prelimReadyForSend = [  SELECT Id, Name
                                                                        FROM ChargentOrders__ChargentOrder__c
                                                                        WHERE SREC_Status__c = 'Ready'];

        List<ChargentOrders__ChargentOrder__c> prelimNotReadyForSend = [SELECT Id, Name 
                                                                        FROM ChargentOrders__ChargentOrder__c
                                                                        WHERE SREC_Status__c != 'Ready'];
        System.assertEquals(1,prelimReadyForSend.size());
        System.assertEquals(3,prelimNotReadyForSend.size());                                                                                                                      

        List<SREC__c> srecToUpdateList = new List<SREC__c>();

        test.startTest();
        for (SREC__c srecToUpdate : [SELECT Id, Name 
                                    FROM SREC__c]){
            srecToUpdate.Number_of_SRECs__c = 2;
            srecToUpdate.Clearing_Price__c = 260.09;
            srecToUpdate.Payment_SREC__c = 247.09;
            srecToUpdate.Total_Payment__c = 494.18;
            srecToUpdateList.add(srecToUpdate);
        }
        System.assertEquals(3,srecToUpdateList.size());
        update srecToUpdateList;
        test.stopTest();
      
        List<ChargentOrders__ChargentOrder__c> choReadyForSend = [  SELECT Id, Name,
                                                                    Related_SREC__r.Total_SREC_Value_to_Customer__c,
                                                                    ChargentOrders__Credit_Amount__c
                                                                    FROM ChargentOrders__ChargentOrder__c
                                                                    WHERE SREC_Status__c = 'Ready'
                                                                    ORDER BY ChargentOrders__Bank_Name__c];

        List<ChargentOrders__ChargentOrder__c> choNotReadyForSend = [SELECT Id, Name
                                                                    FROM ChargentOrders__ChargentOrder__c
                                                                    WHERE SREC_Status__c != 'Ready'];
                                                                    
        // 4 Chargent Orders: 3 should have been updated by above, and changed to Ready. The final one should not have been affected, since it 
        // already had SREC Status = Ready

        System.assertEquals(4,choReadyForSend.size());
        System.assertEquals(0,choNotReadyForSend.size());  
        System.assertEquals(choReadyForSend[0].Related_SREC__r.Total_SREC_Value_to_Customer__c, choReadyForSend[0].ChargentOrders__Credit_Amount__c);
        System.assertEquals(choReadyForSend[1].Related_SREC__r.Total_SREC_Value_to_Customer__c, choReadyForSend[1].ChargentOrders__Credit_Amount__c);
        System.assertEquals(choReadyForSend[2].Related_SREC__r.Total_SREC_Value_to_Customer__c, choReadyForSend[2].ChargentOrders__Credit_Amount__c);
        System.assertNotEquals(0, choReadyForSend[0].ChargentOrders__Credit_Amount__c);
        System.assertNotEquals(0, choReadyForSend[1].ChargentOrders__Credit_Amount__c);
        System.assertNotEquals(0, choReadyForSend[2].ChargentOrders__Credit_Amount__c);
        System.assertEquals(0.03, choReadyForSend[3].ChargentOrders__Credit_Amount__c);
    }

    static testMethod void runBatchofOne() {
        // Outside tests, batch size = 1 because Chargent only accepts 1 order at a time in callout:
        Test.startTest();
        BatchCreditSRECHandler.executeBatch();
        Test.stopTest();

        ChargentOrders__ChargentOrder__c updatedCho = [ SELECT Id, Name, 
                                                        SREC_Status__c, 
                                                        ChargentOrders__Credit_Amount__c, 
                                                        ChargentOrders__Bank_Routing_Number__c, 
                                                        ChargentOrders__Bank_Account_Number__c, 
                                                        ChargentOrders__Bank_Account_Type__c, 
                                                        ChargentOrders__Bank_Name__c,  
                                                        ChargentOrders__Subtotal__c, 
                                                        ChargentOrders__Bank_Account_Name__c 
                                                        FROM ChargentOrders__ChargentOrder__c
                                                        WHERE ChargentOrders__Bank_Name__c = 'Originally Set to Ready'
                                                        LIMIT 1];

        System.assertEquals('Success', updatedCho.SREC_Status__c);
    }

    static testMethod void runBatchofFour() {
        // Outside tests, batch size = 1 but we want to test with > 1 so that finish method is tested
        // with > 1 record. We won't hit callout exception in a test because Chargent callout is mocked
        List<ChargentOrders__ChargentOrder__c> prelimOrderList = [SELECT Id, Name
                                                                  FROM ChargentOrders__ChargentOrder__c];

        List<SREC_Invoice__c> prelimInvoiceList = [ SELECT Id, Name, Date_Paid__c
                                                    FROM SREC_Invoice__c];

        // For monthly SRECs, the SREC Status is set by a flow, not by a trigger. This mocks that:
        Integer count = 0;
        Integer numberOfInvoices = prelimInvoiceList.size();

        for (ChargentOrders__ChargentOrder__c choOrder : prelimOrderList){
            choOrder.SREC_Status__c = 'Ready';
            if (count < numberOfInvoices) {
                choOrder.SREC_Invoice__c = prelimInvoiceList[count].Id;
            }
            count ++;
        }
        update prelimOrderList;
        System.assertEquals(4,prelimOrderList.size());
        System.assertEquals(3,numberOfInvoices);

        Test.startTest();
            BatchCreditSRECHandler batchJob = new BatchCreditSRECHandler();
            Database.executeBatch(batchJob, 4);
        Test.stopTest();

        for (SREC_Invoice__c updatedInvoice : [ SELECT Id, Name, Date_Paid__c
                                                FROM SREC_Invoice__c]){
            System.AssertEquals(System.Today(), updatedInvoice.Date_Paid__c);
        }

        List<ChargentOrders__ChargentOrder__c> postBatchList = [SELECT Id, Name, SREC_Invoice__c
                                                                FROM ChargentOrders__ChargentOrder__c
                                                                WHERE SREC_Status__c = 'Success'];
        System.AssertEquals(4, postBatchList.size());
    }
}
