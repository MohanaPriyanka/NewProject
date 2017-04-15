/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Tests LoanService and Excel classes
 *************************************************************************************/
@isTest
public with sharing class LoanServicerTest {
    @testSetup static void setupTestData() {
        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                    Total_Capital__c = 10000000,
                                                    Investor__c = 'The Bank',
                                                    Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(Name = 'Tranche Assignment Pending',
                                                                 Tranche_Type__c = 'Holding',
                                                                 Stage__c = 'Closed',
                                                                 Loan_Data__c = capitalPool.id);
        insert loanTranchePending;                  

        Partner__c partner = new Partner__c(Name = 'Partner');
        insert partner;

        Lead testLead = new Lead(FirstName = 'Test',
                                 LastName = 'Testerson',
                                 Company = 'Testco');
        insert testLead;

        Account account = new Account(Name = 'Testerson');
        insert account;

        Opportunity opp = new Opportunity(AccountId = account.Id,
                                          Name = 'Testerson Loan',
                                          StageName = 'New',
                                          CloseDate = Date.today().addYears(1));
        insert opp;

        List<Product2> products = new List<Product2>();
        Product2 productLoanMATerm10Rate599 = 
            new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                         Family = 'Solar Loan',
                         Product_Type__c = 'Residential Loan',
                         State__c = 'MA',
                         Loan_Interest_Rate__c = 5.99,
                         Loan_Term__c = 120,
                         Loan_Interest_Only_Period__c = 12,
                         Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                         Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                         ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                         Loan_base_rate__c = .0625,
                         Loan_Internal_Lender_rate__c = .0499,
                         Credit_Maximum__c = '999',
                         Credit_Minimum__c = '750',
                         Loan_Capital_Pool__c = capitalPool.Id,
                         Loan_Tranche_Type__c = 'Standard',
                         Program__c = 'BlueWave Solar Loan',
                         isActive = TRUE);
        products.add(productLoanMATerm10Rate599);
        Product2 mslp20Yr = 
            new Product2(Name = 'MSLP - MA - 20 Year - 3.25%',
                         Family = 'Solar Loan',
                         Product_Type__c = 'Residential Loan',
                         State__c = 'MA',
                         Loan_Interest_Rate__c = 3.25,
                         Loan_Term__c = 220,
                         Loan_Interest_Only_Period__c = 12,
                         Loan_Financing_Fee_Terms__c = 'No Financing Fee',
                         Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection',
                         ProductCode = 'MSLP - MA - 20 Year - 3.25%',
                         Loan_Capital_Pool__c = capitalPool.Id,
                         Loan_Tranche_Type__c = 'Standard',
                         Program__c = 'BlueWave Solar Loan',
                         isActive = TRUE);
        products.add(mslp20Yr);
        insert products;
                                      
    }

    static testMethod void testLoanCreationAndUpdate() {
        Product2 ma10Yr = [SELECT Id, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c
                           FROM Product2
                           WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%' LIMIT 1];
        System.assertEquals(5.99,ma10Yr.Loan_Interest_Rate__c);
        System.assertEquals(120,ma10Yr.Loan_Term__c);
        System.assertEquals(12,ma10Yr.Loan_Interest_Only_Period__c);
        
        Loan_Traunch__c loanTraunch = [SELECT Id
                                       FROM Loan_Traunch__c
                                       WHERE Name = 'Tranche Assignment Pending'
                                       LIMIT 1];
        Lead testLead = [SELECT Id
                         FROM Lead
                         WHERE LastName = 'Testerson'
                         LIMIT 1];
        Opportunity opp = [SELECT Id
                           FROM Opportunity
                           WHERE Name = 'Testerson Loan'
                           LIMIT 1];
        Partner__c partner = [SELECT Id
                              FROM Partner__c
                              WHERE Name = 'Partner'
                              LIMIT 1];

        Test.startTest();
        Loan__c loan = new Loan__c(Product__c = ma10Yr.Id,
                                   Lead__c = testLead.Id,
                                   Partner__c = partner.Id,
                                   Opportunity__c = opp.Id,
                                   Loan_Tranche__c = loanTraunch.Id,
                                   System_Costt__c = 50000,
                                   Commencement_Datee__c = Date.today());
        insert loan;
        
        List<Loan_Payment__c> loanPayments = [SELECT Id, Period__c,
                                              Funds_Distributed__c, Interest_Due__c, Principal_Due__c
                                              FROM Loan_Payment__c
                                              WHERE Loan__c = : loan.Id];
        System.assertEquals(132, loanPayments.size());

        Map<Integer, LoanServicerTest.MonthlyPayment> answerMap = getAnswerMap(ma10YrJSON50k);
        Integer period;
        for (Loan_Payment__c loanPayment : loanPayments) {
            period = loanPayment.Period__c.intValue();
            System.assertEquals(answerMap.get(period).FundsDistributed, loanPayment.Funds_Distributed__c);
            System.assertEquals(answerMap.get(period).PrincipalDue, loanPayment.Principal_Due__c);
            System.assertEquals(answerMap.get(period).InterestDue, loanPayment.Interest_Due__c);
        }

        Product2 mslp20Yr = [SELECT Id, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c
                             FROM Product2
                             WHERE Name = 'MSLP - MA - 20 Year - 3.25%' LIMIT 1];
        loan.Product__c = mslp20Yr.Id;
        loan.System_Costt__c = 45000;
        update loan;

        loanPayments = [SELECT Id, Period__c,
                        Funds_Distributed__c, Interest_Due__c, Principal_Due__c
                        FROM Loan_Payment__c
                        WHERE Loan__c = : loan.Id];
        System.assertEquals(232, loanPayments.size());

        answerMap = getAnswerMap(mslp20YrJSON45k);
        for (Loan_Payment__c loanPayment : loanPayments) {
            period = loanPayment.Period__c.intValue();
            System.assertEquals(answerMap.get(period).FundsDistributed, loanPayment.Funds_Distributed__c);
            System.assertEquals(answerMap.get(period).InterestDue, loanPayment.Interest_Due__c);
            System.assertEquals(answerMap.get(period).PrincipalDue, loanPayment.Principal_Due__c);
        }

        Test.stopTest();
    }

    static Map<Integer, LoanServicerTest.MonthlyPayment> getAnswerMap(String json) {
        Map<Integer, LoanServicerTest.MonthlyPayment> answerMap = 
            new Map<Integer, LoanServicerTest.MonthlyPayment>();

        LoanServicerTest.LoanSched sched = parse(json);
        
        for (LoanServicerTest.MonthlyPayment payment : sched.monthlyPayments) {
            answerMap.put(payment.Period, payment);
        }
        return answerMap;
    }

    // Used csvjson: http://www.csvjson.com/csv2json
    static String ma10YrJSON50k = 
        '{"monthlyPayments":[ ' +
        '  {"Period": 0,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 1,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 2,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 3,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 4,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 5,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 6,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 7,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 8,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 9,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 10,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 11,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": 0  }, ' +
        '  {"Period": 12,"FundsDistributed": 50000,"InterestDue": -249.58,"PrincipalDue": -305.27  }, ' +
        '  {"Period": 13,"FundsDistributed": 50000,"InterestDue": -248.06,"PrincipalDue": -306.79  }, ' +
        '  {"Period": 14,"FundsDistributed": 50000,"InterestDue": -246.53,"PrincipalDue": -308.32  }, ' +
        '  {"Period": 15,"FundsDistributed": 50000,"InterestDue": -244.99,"PrincipalDue": -309.86  }, ' +
        '  {"Period": 16,"FundsDistributed": 50000,"InterestDue": -243.44,"PrincipalDue": -311.41  }, ' +
        '  {"Period": 17,"FundsDistributed": 50000,"InterestDue": -241.89,"PrincipalDue": -312.96  }, ' +
        '  {"Period": 18,"FundsDistributed": 50000,"InterestDue": -240.33,"PrincipalDue": -314.53  }, ' +
        '  {"Period": 19,"FundsDistributed": 50000,"InterestDue": -238.76,"PrincipalDue": -316.1  }, ' +
        '  {"Period": 20,"FundsDistributed": 50000,"InterestDue": -237.18,"PrincipalDue": -317.67  }, ' +
        '  {"Period": 21,"FundsDistributed": 50000,"InterestDue": -235.59,"PrincipalDue": -319.26  }, ' +
        '  {"Period": 22,"FundsDistributed": 50000,"InterestDue": -234,"PrincipalDue": -320.85  }, ' +
        '  {"Period": 23,"FundsDistributed": 50000,"InterestDue": -232.4,"PrincipalDue": -322.45  }, ' +
        '  {"Period": 24,"FundsDistributed": 50000,"InterestDue": -230.79,"PrincipalDue": -324.06  }, ' +
        '  {"Period": 25,"FundsDistributed": 50000,"InterestDue": -229.17,"PrincipalDue": -325.68  }, ' +
        '  {"Period": 26,"FundsDistributed": 50000,"InterestDue": -227.54,"PrincipalDue": -327.31  }, ' +
        '  {"Period": 27,"FundsDistributed": 50000,"InterestDue": -225.91,"PrincipalDue": -328.94  }, ' +
        '  {"Period": 28,"FundsDistributed": 50000,"InterestDue": -224.27,"PrincipalDue": -330.58  }, ' +
        '  {"Period": 29,"FundsDistributed": 50000,"InterestDue": -222.62,"PrincipalDue": -332.23  }, ' +
        '  {"Period": 30,"FundsDistributed": 50000,"InterestDue": -220.96,"PrincipalDue": -333.89  }, ' +
        '  {"Period": 31,"FundsDistributed": 50000,"InterestDue": -219.29,"PrincipalDue": -335.56  }, ' +
        '  {"Period": 32,"FundsDistributed": 50000,"InterestDue": -217.62,"PrincipalDue": -337.23  }, ' +
        '  {"Period": 33,"FundsDistributed": 50000,"InterestDue": -215.93,"PrincipalDue": -338.92  }, ' +
        '  {"Period": 34,"FundsDistributed": 50000,"InterestDue": -214.24,"PrincipalDue": -340.61  }, ' +
        '  {"Period": 35,"FundsDistributed": 50000,"InterestDue": -212.54,"PrincipalDue": -342.31  }, ' +
        '  {"Period": 36,"FundsDistributed": 50000,"InterestDue": -210.83,"PrincipalDue": -344.02  }, ' +
        '  {"Period": 37,"FundsDistributed": 50000,"InterestDue": -209.12,"PrincipalDue": -345.73  }, ' +
        '  {"Period": 38,"FundsDistributed": 50000,"InterestDue": -207.39,"PrincipalDue": -347.46  }, ' +
        '  {"Period": 39,"FundsDistributed": 50000,"InterestDue": -205.66,"PrincipalDue": -349.19  }, ' +
        '  {"Period": 40,"FundsDistributed": 50000,"InterestDue": -203.91,"PrincipalDue": -350.94  }, ' +
        '  {"Period": 41,"FundsDistributed": 50000,"InterestDue": -202.16,"PrincipalDue": -352.69  }, ' +
        '  {"Period": 42,"FundsDistributed": 50000,"InterestDue": -200.4,"PrincipalDue": -354.45  }, ' +
        '  {"Period": 43,"FundsDistributed": 50000,"InterestDue": -198.63,"PrincipalDue": -356.22  }, ' +
        '  {"Period": 44,"FundsDistributed": 50000,"InterestDue": -196.85,"PrincipalDue": -358  }, ' +
        '  {"Period": 45,"FundsDistributed": 50000,"InterestDue": -195.07,"PrincipalDue": -359.78  }, ' +
        '  {"Period": 46,"FundsDistributed": 50000,"InterestDue": -193.27,"PrincipalDue": -361.58  }, ' +
        '  {"Period": 47,"FundsDistributed": 50000,"InterestDue": -191.47,"PrincipalDue": -363.39  }, ' +
        '  {"Period": 48,"FundsDistributed": 50000,"InterestDue": -189.65,"PrincipalDue": -365.2  }, ' +
        '  {"Period": 49,"FundsDistributed": 50000,"InterestDue": -187.83,"PrincipalDue": -367.02  }, ' +
        '  {"Period": 50,"FundsDistributed": 50000,"InterestDue": -186,"PrincipalDue": -368.85  }, ' +
        '  {"Period": 51,"FundsDistributed": 50000,"InterestDue": -184.16,"PrincipalDue": -370.7  }, ' +
        '  {"Period": 52,"FundsDistributed": 50000,"InterestDue": -182.31,"PrincipalDue": -372.55  }, ' +
        '  {"Period": 53,"FundsDistributed": 50000,"InterestDue": -180.45,"PrincipalDue": -374.41  }, ' +
        '  {"Period": 54,"FundsDistributed": 50000,"InterestDue": -178.58,"PrincipalDue": -376.27  }, ' +
        '  {"Period": 55,"FundsDistributed": 50000,"InterestDue": -176.7,"PrincipalDue": -378.15  }, ' +
        '  {"Period": 56,"FundsDistributed": 50000,"InterestDue": -174.81,"PrincipalDue": -380.04  }, ' +
        '  {"Period": 57,"FundsDistributed": 50000,"InterestDue": -172.91,"PrincipalDue": -381.94  }, ' +
        '  {"Period": 58,"FundsDistributed": 50000,"InterestDue": -171.01,"PrincipalDue": -383.84  }, ' +
        '  {"Period": 59,"FundsDistributed": 50000,"InterestDue": -169.09,"PrincipalDue": -385.76  }, ' +
        '  {"Period": 60,"FundsDistributed": 50000,"InterestDue": -167.17,"PrincipalDue": -387.69  }, ' +
        '  {"Period": 61,"FundsDistributed": 50000,"InterestDue": -165.23,"PrincipalDue": -389.62  }, ' +
        '  {"Period": 62,"FundsDistributed": 50000,"InterestDue": -163.29,"PrincipalDue": -391.57  }, ' +
        '  {"Period": 63,"FundsDistributed": 50000,"InterestDue": -161.33,"PrincipalDue": -393.52  }, ' +
        '  {"Period": 64,"FundsDistributed": 50000,"InterestDue": -159.37,"PrincipalDue": -395.48  }, ' +
        '  {"Period": 65,"FundsDistributed": 50000,"InterestDue": -157.39,"PrincipalDue": -397.46  }, ' +
        '  {"Period": 66,"FundsDistributed": 50000,"InterestDue": -155.41,"PrincipalDue": -399.44  }, ' +
        '  {"Period": 67,"FundsDistributed": 50000,"InterestDue": -153.42,"PrincipalDue": -401.44  }, ' +
        '  {"Period": 68,"FundsDistributed": 50000,"InterestDue": -151.41,"PrincipalDue": -403.44  }, ' +
        '  {"Period": 69,"FundsDistributed": 50000,"InterestDue": -149.4,"PrincipalDue": -405.45  }, ' +
        '  {"Period": 70,"FundsDistributed": 50000,"InterestDue": -147.37,"PrincipalDue": -407.48  }, ' +
        '  {"Period": 71,"FundsDistributed": 50000,"InterestDue": -145.34,"PrincipalDue": -409.51  }, ' +
        '  {"Period": 72,"FundsDistributed": 50000,"InterestDue": -143.3,"PrincipalDue": -411.56  }, ' +
        '  {"Period": 73,"FundsDistributed": 50000,"InterestDue": -141.24,"PrincipalDue": -413.61  }, ' +
        '  {"Period": 74,"FundsDistributed": 50000,"InterestDue": -139.18,"PrincipalDue": -415.68  }, ' +
        '  {"Period": 75,"FundsDistributed": 50000,"InterestDue": -137.1,"PrincipalDue": -417.75  }, ' +
        '  {"Period": 76,"FundsDistributed": 50000,"InterestDue": -135.02,"PrincipalDue": -419.84  }, ' +
        '  {"Period": 77,"FundsDistributed": 50000,"InterestDue": -132.92,"PrincipalDue": -421.93  }, ' +
        '  {"Period": 78,"FundsDistributed": 50000,"InterestDue": -130.81,"PrincipalDue": -424.04  }, ' +
        '  {"Period": 79,"FundsDistributed": 50000,"InterestDue": -128.7,"PrincipalDue": -426.15  }, ' +
        '  {"Period": 80,"FundsDistributed": 50000,"InterestDue": -126.57,"PrincipalDue": -428.28  }, ' +
        '  {"Period": 81,"FundsDistributed": 50000,"InterestDue": -124.43,"PrincipalDue": -430.42  }, ' +
        '  {"Period": 82,"FundsDistributed": 50000,"InterestDue": -122.28,"PrincipalDue": -432.57  }, ' +
        '  {"Period": 83,"FundsDistributed": 50000,"InterestDue": -120.12,"PrincipalDue": -434.73  }, ' +
        '  {"Period": 84,"FundsDistributed": 50000,"InterestDue": -117.95,"PrincipalDue": -436.9  }, ' +
        '  {"Period": 85,"FundsDistributed": 50000,"InterestDue": -115.77,"PrincipalDue": -439.08  }, ' +
        '  {"Period": 86,"FundsDistributed": 50000,"InterestDue": -113.58,"PrincipalDue": -441.27  }, ' +
        '  {"Period": 87,"FundsDistributed": 50000,"InterestDue": -111.38,"PrincipalDue": -443.47  }, ' +
        '  {"Period": 88,"FundsDistributed": 50000,"InterestDue": -109.17,"PrincipalDue": -445.69  }, ' +
        '  {"Period": 89,"FundsDistributed": 50000,"InterestDue": -106.94,"PrincipalDue": -447.91  }, ' +
        '  {"Period": 90,"FundsDistributed": 50000,"InterestDue": -104.71,"PrincipalDue": -450.15  }, ' +
        '  {"Period": 91,"FundsDistributed": 50000,"InterestDue": -102.46,"PrincipalDue": -452.39  }, ' +
        '  {"Period": 92,"FundsDistributed": 50000,"InterestDue": -100.2,"PrincipalDue": -454.65  }, ' +
        '  {"Period": 93,"FundsDistributed": 50000,"InterestDue": -97.93,"PrincipalDue": -456.92  }, ' +
        '  {"Period": 94,"FundsDistributed": 50000,"InterestDue": -95.65,"PrincipalDue": -459.2  }, ' +
        '  {"Period": 95,"FundsDistributed": 50000,"InterestDue": -93.36,"PrincipalDue": -461.49  }, ' +
        '  {"Period": 96,"FundsDistributed": 50000,"InterestDue": -91.05,"PrincipalDue": -463.8  }, ' +
        '  {"Period": 97,"FundsDistributed": 50000,"InterestDue": -88.74,"PrincipalDue": -466.11  }, ' +
        '  {"Period": 98,"FundsDistributed": 50000,"InterestDue": -86.41,"PrincipalDue": -468.44  }, ' +
        '  {"Period": 99,"FundsDistributed": 50000,"InterestDue": -84.07,"PrincipalDue": -470.78  }, ' +
        '  {"Period": 100,"FundsDistributed": 50000,"InterestDue": -81.72,"PrincipalDue": -473.13  }, ' +
        '  {"Period": 101,"FundsDistributed": 50000,"InterestDue": -79.36,"PrincipalDue": -475.49  }, ' +
        '  {"Period": 102,"FundsDistributed": 50000,"InterestDue": -76.99,"PrincipalDue": -477.86  }, ' +
        '  {"Period": 103,"FundsDistributed": 50000,"InterestDue": -74.6,"PrincipalDue": -480.25  }, ' +
        '  {"Period": 104,"FundsDistributed": 50000,"InterestDue": -72.21,"PrincipalDue": -482.65  }, ' +
        '  {"Period": 105,"FundsDistributed": 50000,"InterestDue": -69.8,"PrincipalDue": -485.05  }, ' +
        '  {"Period": 106,"FundsDistributed": 50000,"InterestDue": -67.38,"PrincipalDue": -487.48  }, ' +
        '  {"Period": 107,"FundsDistributed": 50000,"InterestDue": -64.94,"PrincipalDue": -489.91  }, ' +
        '  {"Period": 108,"FundsDistributed": 50000,"InterestDue": -62.5,"PrincipalDue": -492.35  }, ' +
        '  {"Period": 109,"FundsDistributed": 50000,"InterestDue": -60.04,"PrincipalDue": -494.81  }, ' +
        '  {"Period": 110,"FundsDistributed": 50000,"InterestDue": -57.57,"PrincipalDue": -497.28  }, ' +
        '  {"Period": 111,"FundsDistributed": 50000,"InterestDue": -55.09,"PrincipalDue": -499.76  }, ' +
        '  {"Period": 112,"FundsDistributed": 50000,"InterestDue": -52.59,"PrincipalDue": -502.26  }, ' +
        '  {"Period": 113,"FundsDistributed": 50000,"InterestDue": -50.09,"PrincipalDue": -504.77  }, ' +
        '  {"Period": 114,"FundsDistributed": 50000,"InterestDue": -47.57,"PrincipalDue": -507.29  }, ' +
        '  {"Period": 115,"FundsDistributed": 50000,"InterestDue": -45.03,"PrincipalDue": -509.82  }, ' +
        '  {"Period": 116,"FundsDistributed": 50000,"InterestDue": -42.49,"PrincipalDue": -512.36  }, ' +
        '  {"Period": 117,"FundsDistributed": 50000,"InterestDue": -39.93,"PrincipalDue": -514.92  }, ' +
        '  {"Period": 118,"FundsDistributed": 50000,"InterestDue": -37.36,"PrincipalDue": -517.49  }, ' +
        '  {"Period": 119,"FundsDistributed": 50000,"InterestDue": -34.78,"PrincipalDue": -520.07  }, ' +
        '  {"Period": 120,"FundsDistributed": 50000,"InterestDue": -32.18,"PrincipalDue": -522.67  }, ' +
        '  {"Period": 121,"FundsDistributed": 50000,"InterestDue": -29.57,"PrincipalDue": -525.28  }, ' +
        '  {"Period": 122,"FundsDistributed": 50000,"InterestDue": -26.95,"PrincipalDue": -527.9  }, ' +
        '  {"Period": 123,"FundsDistributed": 50000,"InterestDue": -24.32,"PrincipalDue": -530.54  }, ' +
        '  {"Period": 124,"FundsDistributed": 50000,"InterestDue": -21.67,"PrincipalDue": -533.18  }, ' +
        '  {"Period": 125,"FundsDistributed": 50000,"InterestDue": -19.01,"PrincipalDue": -535.85  }, ' +
        '  {"Period": 126,"FundsDistributed": 50000,"InterestDue": -16.33,"PrincipalDue": -538.52  }, ' +
        '  {"Period": 127,"FundsDistributed": 50000,"InterestDue": -13.64,"PrincipalDue": -541.21  }, ' +
        '  {"Period": 128,"FundsDistributed": 50000,"InterestDue": -10.94,"PrincipalDue": -543.91  }, ' +
        '  {"Period": 129,"FundsDistributed": 50000,"InterestDue": -8.23,"PrincipalDue": -546.62  }, ' +
        '  {"Period": 130,"FundsDistributed": 50000,"InterestDue": -5.5,"PrincipalDue": -549.35  }, ' +
        '  {"Period": 131,"FundsDistributed": 50000,"InterestDue": -2.76,"PrincipalDue": -552.1  } ' +
        ']}';

    static String mslp20YrJSON45k =
        '{"monthlyPayments":[ ' +
        '  {"Period": 0,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 1,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 2,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 3,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 4,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 5,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 6,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 7,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 8,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 9,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 10,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 11,"FundsDistributed": 15750,"InterestDue": -42.66,"PrincipalDue": 0  }, ' +
        '  {"Period": 12,"FundsDistributed": 45000,"InterestDue": -121.88,"PrincipalDue": -149.89  }, ' +
        '  {"Period": 13,"FundsDistributed": 45000,"InterestDue": -121.47,"PrincipalDue": -150.3  }, ' +
        '  {"Period": 14,"FundsDistributed": 45000,"InterestDue": -121.06,"PrincipalDue": -150.71  }, ' +
        '  {"Period": 15,"FundsDistributed": 45000,"InterestDue": -120.65,"PrincipalDue": -151.11  }, ' +
        '  {"Period": 16,"FundsDistributed": 45000,"InterestDue": -120.24,"PrincipalDue": -151.52  }, ' +
        '  {"Period": 17,"FundsDistributed": 45000,"InterestDue": -119.83,"PrincipalDue": -151.93  }, ' +
        '  {"Period": 18,"FundsDistributed": 45000,"InterestDue": -119.42,"PrincipalDue": -152.35  }, ' +
        '  {"Period": 19,"FundsDistributed": 45000,"InterestDue": -119.01,"PrincipalDue": -152.76  }, ' +
        '  {"Period": 20,"FundsDistributed": 45000,"InterestDue": -118.6,"PrincipalDue": -153.17  }, ' +
        '  {"Period": 21,"FundsDistributed": 45000,"InterestDue": -118.18,"PrincipalDue": -153.59  }, ' +
        '  {"Period": 22,"FundsDistributed": 45000,"InterestDue": -117.77,"PrincipalDue": -154  }, ' +
        '  {"Period": 23,"FundsDistributed": 45000,"InterestDue": -117.35,"PrincipalDue": -154.42  }, ' +
        '  {"Period": 24,"FundsDistributed": 45000,"InterestDue": -116.93,"PrincipalDue": -154.84  }, ' +
        '  {"Period": 25,"FundsDistributed": 45000,"InterestDue": -116.51,"PrincipalDue": -155.26  }, ' +
        '  {"Period": 26,"FundsDistributed": 45000,"InterestDue": -116.09,"PrincipalDue": -155.68  }, ' +
        '  {"Period": 27,"FundsDistributed": 45000,"InterestDue": -115.67,"PrincipalDue": -156.1  }, ' +
        '  {"Period": 28,"FundsDistributed": 45000,"InterestDue": -115.25,"PrincipalDue": -156.52  }, ' +
        '  {"Period": 29,"FundsDistributed": 45000,"InterestDue": -114.82,"PrincipalDue": -156.95  }, ' +
        '  {"Period": 30,"FundsDistributed": 45000,"InterestDue": -114.4,"PrincipalDue": -157.37  }, ' +
        '  {"Period": 31,"FundsDistributed": 45000,"InterestDue": -113.97,"PrincipalDue": -157.8  }, ' +
        '  {"Period": 32,"FundsDistributed": 45000,"InterestDue": -113.54,"PrincipalDue": -158.22  }, ' +
        '  {"Period": 33,"FundsDistributed": 45000,"InterestDue": -113.11,"PrincipalDue": -158.65  }, ' +
        '  {"Period": 34,"FundsDistributed": 45000,"InterestDue": -112.69,"PrincipalDue": -159.08  }, ' +
        '  {"Period": 35,"FundsDistributed": 45000,"InterestDue": -112.25,"PrincipalDue": -159.51  }, ' +
        '  {"Period": 36,"FundsDistributed": 45000,"InterestDue": -111.82,"PrincipalDue": -159.95  }, ' +
        '  {"Period": 37,"FundsDistributed": 45000,"InterestDue": -111.39,"PrincipalDue": -160.38  }, ' +
        '  {"Period": 38,"FundsDistributed": 45000,"InterestDue": -110.95,"PrincipalDue": -160.81  }, ' +
        '  {"Period": 39,"FundsDistributed": 45000,"InterestDue": -110.52,"PrincipalDue": -161.25  }, ' +
        '  {"Period": 40,"FundsDistributed": 45000,"InterestDue": -110.08,"PrincipalDue": -161.69  }, ' +
        '  {"Period": 41,"FundsDistributed": 45000,"InterestDue": -109.64,"PrincipalDue": -162.12  }, ' +
        '  {"Period": 42,"FundsDistributed": 45000,"InterestDue": -109.21,"PrincipalDue": -162.56  }, ' +
        '  {"Period": 43,"FundsDistributed": 45000,"InterestDue": -108.77,"PrincipalDue": -163  }, ' +
        '  {"Period": 44,"FundsDistributed": 45000,"InterestDue": -108.32,"PrincipalDue": -163.44  }, ' +
        '  {"Period": 45,"FundsDistributed": 45000,"InterestDue": -107.88,"PrincipalDue": -163.89  }, ' +
        '  {"Period": 46,"FundsDistributed": 45000,"InterestDue": -107.44,"PrincipalDue": -164.33  }, ' +
        '  {"Period": 47,"FundsDistributed": 45000,"InterestDue": -106.99,"PrincipalDue": -164.78  }, ' +
        '  {"Period": 48,"FundsDistributed": 45000,"InterestDue": -106.55,"PrincipalDue": -165.22  }, ' +
        '  {"Period": 49,"FundsDistributed": 45000,"InterestDue": -106.1,"PrincipalDue": -165.67  }, ' +
        '  {"Period": 50,"FundsDistributed": 45000,"InterestDue": -105.65,"PrincipalDue": -166.12  }, ' +
        '  {"Period": 51,"FundsDistributed": 45000,"InterestDue": -105.2,"PrincipalDue": -166.57  }, ' +
        '  {"Period": 52,"FundsDistributed": 45000,"InterestDue": -104.75,"PrincipalDue": -167.02  }, ' +
        '  {"Period": 53,"FundsDistributed": 45000,"InterestDue": -104.3,"PrincipalDue": -167.47  }, ' +
        '  {"Period": 54,"FundsDistributed": 45000,"InterestDue": -103.84,"PrincipalDue": -167.92  }, ' +
        '  {"Period": 55,"FundsDistributed": 45000,"InterestDue": -103.39,"PrincipalDue": -168.38  }, ' +
        '  {"Period": 56,"FundsDistributed": 45000,"InterestDue": -102.93,"PrincipalDue": -168.84  }, ' +
        '  {"Period": 57,"FundsDistributed": 45000,"InterestDue": -102.47,"PrincipalDue": -169.29  }, ' +
        '  {"Period": 58,"FundsDistributed": 45000,"InterestDue": -102.02,"PrincipalDue": -169.75  }, ' +
        '  {"Period": 59,"FundsDistributed": 45000,"InterestDue": -101.56,"PrincipalDue": -170.21  }, ' +
        '  {"Period": 60,"FundsDistributed": 45000,"InterestDue": -101.1,"PrincipalDue": -170.67  }, ' +
        '  {"Period": 61,"FundsDistributed": 45000,"InterestDue": -100.63,"PrincipalDue": -171.13  }, ' +
        '  {"Period": 62,"FundsDistributed": 45000,"InterestDue": -100.17,"PrincipalDue": -171.6  }, ' +
        '  {"Period": 63,"FundsDistributed": 45000,"InterestDue": -99.71,"PrincipalDue": -172.06  }, ' +
        '  {"Period": 64,"FundsDistributed": 45000,"InterestDue": -99.24,"PrincipalDue": -172.53  }, ' +
        '  {"Period": 65,"FundsDistributed": 45000,"InterestDue": -98.77,"PrincipalDue": -173  }, ' +
        '  {"Period": 66,"FundsDistributed": 45000,"InterestDue": -98.3,"PrincipalDue": -173.46  }, ' +
        '  {"Period": 67,"FundsDistributed": 45000,"InterestDue": -97.83,"PrincipalDue": -173.93  }, ' +
        '  {"Period": 68,"FundsDistributed": 45000,"InterestDue": -97.36,"PrincipalDue": -174.41  }, ' +
        '  {"Period": 69,"FundsDistributed": 45000,"InterestDue": -96.89,"PrincipalDue": -174.88  }, ' +
        '  {"Period": 70,"FundsDistributed": 45000,"InterestDue": -96.42,"PrincipalDue": -175.35  }, ' +
        '  {"Period": 71,"FundsDistributed": 45000,"InterestDue": -95.94,"PrincipalDue": -175.83  }, ' +
        '  {"Period": 72,"FundsDistributed": 45000,"InterestDue": -95.47,"PrincipalDue": -176.3  }, ' +
        '  {"Period": 73,"FundsDistributed": 45000,"InterestDue": -94.99,"PrincipalDue": -176.78  }, ' +
        '  {"Period": 74,"FundsDistributed": 45000,"InterestDue": -94.51,"PrincipalDue": -177.26  }, ' +
        '  {"Period": 75,"FundsDistributed": 45000,"InterestDue": -94.03,"PrincipalDue": -177.74  }, ' +
        '  {"Period": 76,"FundsDistributed": 45000,"InterestDue": -93.55,"PrincipalDue": -178.22  }, ' +
        '  {"Period": 77,"FundsDistributed": 45000,"InterestDue": -93.07,"PrincipalDue": -178.7  }, ' +
        '  {"Period": 78,"FundsDistributed": 45000,"InterestDue": -92.58,"PrincipalDue": -179.19  }, ' +
        '  {"Period": 79,"FundsDistributed": 45000,"InterestDue": -92.1,"PrincipalDue": -179.67  }, ' +
        '  {"Period": 80,"FundsDistributed": 45000,"InterestDue": -91.61,"PrincipalDue": -180.16  }, ' +
        '  {"Period": 81,"FundsDistributed": 45000,"InterestDue": -91.12,"PrincipalDue": -180.65  }, ' +
        '  {"Period": 82,"FundsDistributed": 45000,"InterestDue": -90.63,"PrincipalDue": -181.14  }, ' +
        '  {"Period": 83,"FundsDistributed": 45000,"InterestDue": -90.14,"PrincipalDue": -181.63  }, ' +
        '  {"Period": 84,"FundsDistributed": 45000,"InterestDue": -89.65,"PrincipalDue": -182.12  }, ' +
        '  {"Period": 85,"FundsDistributed": 45000,"InterestDue": -89.16,"PrincipalDue": -182.61  }, ' +
        '  {"Period": 86,"FundsDistributed": 45000,"InterestDue": -88.66,"PrincipalDue": -183.11  }, ' +
        '  {"Period": 87,"FundsDistributed": 45000,"InterestDue": -88.17,"PrincipalDue": -183.6  }, ' +
        '  {"Period": 88,"FundsDistributed": 45000,"InterestDue": -87.67,"PrincipalDue": -184.1  }, ' +
        '  {"Period": 89,"FundsDistributed": 45000,"InterestDue": -87.17,"PrincipalDue": -184.6  }, ' +
        '  {"Period": 90,"FundsDistributed": 45000,"InterestDue": -86.67,"PrincipalDue": -185.1  }, ' +
        '  {"Period": 91,"FundsDistributed": 45000,"InterestDue": -86.17,"PrincipalDue": -185.6  }, ' +
        '  {"Period": 92,"FundsDistributed": 45000,"InterestDue": -85.67,"PrincipalDue": -186.1  }, ' +
        '  {"Period": 93,"FundsDistributed": 45000,"InterestDue": -85.16,"PrincipalDue": -186.61  }, ' +
        '  {"Period": 94,"FundsDistributed": 45000,"InterestDue": -84.66,"PrincipalDue": -187.11  }, ' +
        '  {"Period": 95,"FundsDistributed": 45000,"InterestDue": -84.15,"PrincipalDue": -187.62  }, ' +
        '  {"Period": 96,"FundsDistributed": 45000,"InterestDue": -83.64,"PrincipalDue": -188.13  }, ' +
        '  {"Period": 97,"FundsDistributed": 45000,"InterestDue": -83.13,"PrincipalDue": -188.64  }, ' +
        '  {"Period": 98,"FundsDistributed": 45000,"InterestDue": -82.62,"PrincipalDue": -189.15  }, ' +
        '  {"Period": 99,"FundsDistributed": 45000,"InterestDue": -82.11,"PrincipalDue": -189.66  }, ' +
        '  {"Period": 100,"FundsDistributed": 45000,"InterestDue": -81.6,"PrincipalDue": -190.17  }, ' +
        '  {"Period": 101,"FundsDistributed": 45000,"InterestDue": -81.08,"PrincipalDue": -190.69  }, ' +
        '  {"Period": 102,"FundsDistributed": 45000,"InterestDue": -80.56,"PrincipalDue": -191.2  }, ' +
        '  {"Period": 103,"FundsDistributed": 45000,"InterestDue": -80.05,"PrincipalDue": -191.72  }, ' +
        '  {"Period": 104,"FundsDistributed": 45000,"InterestDue": -79.53,"PrincipalDue": -192.24  }, ' +
        '  {"Period": 105,"FundsDistributed": 45000,"InterestDue": -79.01,"PrincipalDue": -192.76  }, ' +
        '  {"Period": 106,"FundsDistributed": 45000,"InterestDue": -78.48,"PrincipalDue": -193.28  }, ' +
        '  {"Period": 107,"FundsDistributed": 45000,"InterestDue": -77.96,"PrincipalDue": -193.81  }, ' +
        '  {"Period": 108,"FundsDistributed": 45000,"InterestDue": -77.44,"PrincipalDue": -194.33  }, ' +
        '  {"Period": 109,"FundsDistributed": 45000,"InterestDue": -76.91,"PrincipalDue": -194.86  }, ' +
        '  {"Period": 110,"FundsDistributed": 45000,"InterestDue": -76.38,"PrincipalDue": -195.39  }, ' +
        '  {"Period": 111,"FundsDistributed": 45000,"InterestDue": -75.85,"PrincipalDue": -195.92  }, ' +
        '  {"Period": 112,"FundsDistributed": 45000,"InterestDue": -75.32,"PrincipalDue": -196.45  }, ' +
        '  {"Period": 113,"FundsDistributed": 45000,"InterestDue": -74.79,"PrincipalDue": -196.98  }, ' +
        '  {"Period": 114,"FundsDistributed": 45000,"InterestDue": -74.26,"PrincipalDue": -197.51  }, ' +
        '  {"Period": 115,"FundsDistributed": 45000,"InterestDue": -73.72,"PrincipalDue": -198.05  }, ' +
        '  {"Period": 116,"FundsDistributed": 45000,"InterestDue": -73.18,"PrincipalDue": -198.58  }, ' +
        '  {"Period": 117,"FundsDistributed": 45000,"InterestDue": -72.65,"PrincipalDue": -199.12  }, ' +
        '  {"Period": 118,"FundsDistributed": 45000,"InterestDue": -72.11,"PrincipalDue": -199.66  }, ' +
        '  {"Period": 119,"FundsDistributed": 45000,"InterestDue": -71.57,"PrincipalDue": -200.2  }, ' +
        '  {"Period": 120,"FundsDistributed": 45000,"InterestDue": -71.02,"PrincipalDue": -200.74  }, ' +
        '  {"Period": 121,"FundsDistributed": 45000,"InterestDue": -70.48,"PrincipalDue": -201.29  }, ' +
        '  {"Period": 122,"FundsDistributed": 45000,"InterestDue": -69.94,"PrincipalDue": -201.83  }, ' +
        '  {"Period": 123,"FundsDistributed": 45000,"InterestDue": -69.39,"PrincipalDue": -202.38  }, ' +
        '  {"Period": 124,"FundsDistributed": 45000,"InterestDue": -68.84,"PrincipalDue": -202.93  }, ' +
        '  {"Period": 125,"FundsDistributed": 45000,"InterestDue": -68.29,"PrincipalDue": -203.48  }, ' +
        '  {"Period": 126,"FundsDistributed": 45000,"InterestDue": -67.74,"PrincipalDue": -204.03  }, ' +
        '  {"Period": 127,"FundsDistributed": 45000,"InterestDue": -67.19,"PrincipalDue": -204.58  }, ' +
        '  {"Period": 128,"FundsDistributed": 45000,"InterestDue": -66.63,"PrincipalDue": -205.13  }, ' +
        '  {"Period": 129,"FundsDistributed": 45000,"InterestDue": -66.08,"PrincipalDue": -205.69  }, ' +
        '  {"Period": 130,"FundsDistributed": 45000,"InterestDue": -65.52,"PrincipalDue": -206.25  }, ' +
        '  {"Period": 131,"FundsDistributed": 45000,"InterestDue": -64.96,"PrincipalDue": -206.8  }, ' +
        '  {"Period": 132,"FundsDistributed": 45000,"InterestDue": -64.4,"PrincipalDue": -207.36  }, ' +
        '  {"Period": 133,"FundsDistributed": 45000,"InterestDue": -63.84,"PrincipalDue": -207.93  }, ' +
        '  {"Period": 134,"FundsDistributed": 45000,"InterestDue": -63.28,"PrincipalDue": -208.49  }, ' +
        '  {"Period": 135,"FundsDistributed": 45000,"InterestDue": -62.71,"PrincipalDue": -209.05  }, ' +
        '  {"Period": 136,"FundsDistributed": 45000,"InterestDue": -62.15,"PrincipalDue": -209.62  }, ' +
        '  {"Period": 137,"FundsDistributed": 45000,"InterestDue": -61.58,"PrincipalDue": -210.19  }, ' +
        '  {"Period": 138,"FundsDistributed": 45000,"InterestDue": -61.01,"PrincipalDue": -210.76  }, ' +
        '  {"Period": 139,"FundsDistributed": 45000,"InterestDue": -60.44,"PrincipalDue": -211.33  }, ' +
        '  {"Period": 140,"FundsDistributed": 45000,"InterestDue": -59.87,"PrincipalDue": -211.9  }, ' +
        '  {"Period": 141,"FundsDistributed": 45000,"InterestDue": -59.29,"PrincipalDue": -212.47  }, ' +
        '  {"Period": 142,"FundsDistributed": 45000,"InterestDue": -58.72,"PrincipalDue": -213.05  }, ' +
        '  {"Period": 143,"FundsDistributed": 45000,"InterestDue": -58.14,"PrincipalDue": -213.63  }, ' +
        '  {"Period": 144,"FundsDistributed": 45000,"InterestDue": -57.56,"PrincipalDue": -214.21  }, ' +
        '  {"Period": 145,"FundsDistributed": 45000,"InterestDue": -56.98,"PrincipalDue": -214.79  }, ' +
        '  {"Period": 146,"FundsDistributed": 45000,"InterestDue": -56.4,"PrincipalDue": -215.37  }, ' +
        '  {"Period": 147,"FundsDistributed": 45000,"InterestDue": -55.82,"PrincipalDue": -215.95  }, ' +
        '  {"Period": 148,"FundsDistributed": 45000,"InterestDue": -55.23,"PrincipalDue": -216.54  }, ' +
        '  {"Period": 149,"FundsDistributed": 45000,"InterestDue": -54.65,"PrincipalDue": -217.12  }, ' +
        '  {"Period": 150,"FundsDistributed": 45000,"InterestDue": -54.06,"PrincipalDue": -217.71  }, ' +
        '  {"Period": 151,"FundsDistributed": 45000,"InterestDue": -53.47,"PrincipalDue": -218.3  }, ' +
        '  {"Period": 152,"FundsDistributed": 45000,"InterestDue": -52.88,"PrincipalDue": -218.89  }, ' +
        '  {"Period": 153,"FundsDistributed": 45000,"InterestDue": -52.28,"PrincipalDue": -219.48  }, ' +
        '  {"Period": 154,"FundsDistributed": 45000,"InterestDue": -51.69,"PrincipalDue": -220.08  }, ' +
        '  {"Period": 155,"FundsDistributed": 45000,"InterestDue": -51.09,"PrincipalDue": -220.67  }, ' +
        '  {"Period": 156,"FundsDistributed": 45000,"InterestDue": -50.5,"PrincipalDue": -221.27  }, ' +
        '  {"Period": 157,"FundsDistributed": 45000,"InterestDue": -49.9,"PrincipalDue": -221.87  }, ' +
        '  {"Period": 158,"FundsDistributed": 45000,"InterestDue": -49.3,"PrincipalDue": -222.47  }, ' +
        '  {"Period": 159,"FundsDistributed": 45000,"InterestDue": -48.69,"PrincipalDue": -223.07  }, ' +
        '  {"Period": 160,"FundsDistributed": 45000,"InterestDue": -48.09,"PrincipalDue": -223.68  }, ' +
        '  {"Period": 161,"FundsDistributed": 45000,"InterestDue": -47.48,"PrincipalDue": -224.28  }, ' +
        '  {"Period": 162,"FundsDistributed": 45000,"InterestDue": -46.88,"PrincipalDue": -224.89  }, ' +
        '  {"Period": 163,"FundsDistributed": 45000,"InterestDue": -46.27,"PrincipalDue": -225.5  }, ' +
        '  {"Period": 164,"FundsDistributed": 45000,"InterestDue": -45.66,"PrincipalDue": -226.11  }, ' +
        '  {"Period": 165,"FundsDistributed": 45000,"InterestDue": -45.04,"PrincipalDue": -226.72  }, ' +
        '  {"Period": 166,"FundsDistributed": 45000,"InterestDue": -44.43,"PrincipalDue": -227.34  }, ' +
        '  {"Period": 167,"FundsDistributed": 45000,"InterestDue": -43.81,"PrincipalDue": -227.95  }, ' +
        '  {"Period": 168,"FundsDistributed": 45000,"InterestDue": -43.2,"PrincipalDue": -228.57  }, ' +
        '  {"Period": 169,"FundsDistributed": 45000,"InterestDue": -42.58,"PrincipalDue": -229.19  }, ' +
        '  {"Period": 170,"FundsDistributed": 45000,"InterestDue": -41.96,"PrincipalDue": -229.81  }, ' +
        '  {"Period": 171,"FundsDistributed": 45000,"InterestDue": -41.33,"PrincipalDue": -230.43  }, ' +
        '  {"Period": 172,"FundsDistributed": 45000,"InterestDue": -40.71,"PrincipalDue": -231.06  }, ' +
        '  {"Period": 173,"FundsDistributed": 45000,"InterestDue": -40.08,"PrincipalDue": -231.68  }, ' +
        '  {"Period": 174,"FundsDistributed": 45000,"InterestDue": -39.46,"PrincipalDue": -232.31  }, ' +
        '  {"Period": 175,"FundsDistributed": 45000,"InterestDue": -38.83,"PrincipalDue": -232.94  }, ' +
        '  {"Period": 176,"FundsDistributed": 45000,"InterestDue": -38.2,"PrincipalDue": -233.57  }, ' +
        '  {"Period": 177,"FundsDistributed": 45000,"InterestDue": -37.56,"PrincipalDue": -234.2  }, ' +
        '  {"Period": 178,"FundsDistributed": 45000,"InterestDue": -36.93,"PrincipalDue": -234.84  }, ' +
        '  {"Period": 179,"FundsDistributed": 45000,"InterestDue": -36.29,"PrincipalDue": -235.47  }, ' +
        '  {"Period": 180,"FundsDistributed": 45000,"InterestDue": -35.66,"PrincipalDue": -236.11  }, ' +
        '  {"Period": 181,"FundsDistributed": 45000,"InterestDue": -35.02,"PrincipalDue": -236.75  }, ' +
        '  {"Period": 182,"FundsDistributed": 45000,"InterestDue": -34.38,"PrincipalDue": -237.39  }, ' +
        '  {"Period": 183,"FundsDistributed": 45000,"InterestDue": -33.73,"PrincipalDue": -238.04  }, ' +
        '  {"Period": 184,"FundsDistributed": 45000,"InterestDue": -33.09,"PrincipalDue": -238.68  }, ' +
        '  {"Period": 185,"FundsDistributed": 45000,"InterestDue": -32.44,"PrincipalDue": -239.33  }, ' +
        '  {"Period": 186,"FundsDistributed": 45000,"InterestDue": -31.79,"PrincipalDue": -239.97  }, ' +
        '  {"Period": 187,"FundsDistributed": 45000,"InterestDue": -31.14,"PrincipalDue": -240.62  }, ' +
        '  {"Period": 188,"FundsDistributed": 45000,"InterestDue": -30.49,"PrincipalDue": -241.28  }, ' +
        '  {"Period": 189,"FundsDistributed": 45000,"InterestDue": -29.84,"PrincipalDue": -241.93  }, ' +
        '  {"Period": 190,"FundsDistributed": 45000,"InterestDue": -29.18,"PrincipalDue": -242.58  }, ' +
        '  {"Period": 191,"FundsDistributed": 45000,"InterestDue": -28.53,"PrincipalDue": -243.24  }, ' +
        '  {"Period": 192,"FundsDistributed": 45000,"InterestDue": -27.87,"PrincipalDue": -243.9  }, ' +
        '  {"Period": 193,"FundsDistributed": 45000,"InterestDue": -27.21,"PrincipalDue": -244.56  }, ' +
        '  {"Period": 194,"FundsDistributed": 45000,"InterestDue": -26.54,"PrincipalDue": -245.22  }, ' +
        '  {"Period": 195,"FundsDistributed": 45000,"InterestDue": -25.88,"PrincipalDue": -245.89  }, ' +
        '  {"Period": 196,"FundsDistributed": 45000,"InterestDue": -25.21,"PrincipalDue": -246.55  }, ' +
        '  {"Period": 197,"FundsDistributed": 45000,"InterestDue": -24.55,"PrincipalDue": -247.22  }, ' +
        '  {"Period": 198,"FundsDistributed": 45000,"InterestDue": -23.88,"PrincipalDue": -247.89  }, ' +
        '  {"Period": 199,"FundsDistributed": 45000,"InterestDue": -23.21,"PrincipalDue": -248.56  }, ' +
        '  {"Period": 200,"FundsDistributed": 45000,"InterestDue": -22.53,"PrincipalDue": -249.24  }, ' +
        '  {"Period": 201,"FundsDistributed": 45000,"InterestDue": -21.86,"PrincipalDue": -249.91  }, ' +
        '  {"Period": 202,"FundsDistributed": 45000,"InterestDue": -21.18,"PrincipalDue": -250.59  }, ' +
        '  {"Period": 203,"FundsDistributed": 45000,"InterestDue": -20.5,"PrincipalDue": -251.27  }, ' +
        '  {"Period": 204,"FundsDistributed": 45000,"InterestDue": -19.82,"PrincipalDue": -251.95  }, ' +
        '  {"Period": 205,"FundsDistributed": 45000,"InterestDue": -19.14,"PrincipalDue": -252.63  }, ' +
        '  {"Period": 206,"FundsDistributed": 45000,"InterestDue": -18.45,"PrincipalDue": -253.31  }, ' +
        '  {"Period": 207,"FundsDistributed": 45000,"InterestDue": -17.77,"PrincipalDue": -254  }, ' +
        '  {"Period": 208,"FundsDistributed": 45000,"InterestDue": -17.08,"PrincipalDue": -254.69  }, ' +
        '  {"Period": 209,"FundsDistributed": 45000,"InterestDue": -16.39,"PrincipalDue": -255.38  }, ' +
        '  {"Period": 210,"FundsDistributed": 45000,"InterestDue": -15.7,"PrincipalDue": -256.07  }, ' +
        '  {"Period": 211,"FundsDistributed": 45000,"InterestDue": -15.01,"PrincipalDue": -256.76  }, ' +
        '  {"Period": 212,"FundsDistributed": 45000,"InterestDue": -14.31,"PrincipalDue": -257.46  }, ' +
        '  {"Period": 213,"FundsDistributed": 45000,"InterestDue": -13.61,"PrincipalDue": -258.15  }, ' +
        '  {"Period": 214,"FundsDistributed": 45000,"InterestDue": -12.91,"PrincipalDue": -258.85  }, ' +
        '  {"Period": 215,"FundsDistributed": 45000,"InterestDue": -12.21,"PrincipalDue": -259.55  }, ' +
        '  {"Period": 216,"FundsDistributed": 45000,"InterestDue": -11.51,"PrincipalDue": -260.26  }, ' +
        '  {"Period": 217,"FundsDistributed": 45000,"InterestDue": -10.8,"PrincipalDue": -260.96  }, ' +
        '  {"Period": 218,"FundsDistributed": 45000,"InterestDue": -10.1,"PrincipalDue": -261.67  }, ' +
        '  {"Period": 219,"FundsDistributed": 45000,"InterestDue": -9.39,"PrincipalDue": -262.38  }, ' +
        '  {"Period": 220,"FundsDistributed": 45000,"InterestDue": -8.68,"PrincipalDue": -263.09  }, ' +
        '  {"Period": 221,"FundsDistributed": 45000,"InterestDue": -7.97,"PrincipalDue": -263.8  }, ' +
        '  {"Period": 222,"FundsDistributed": 45000,"InterestDue": -7.25,"PrincipalDue": -264.52  }, ' +
        '  {"Period": 223,"FundsDistributed": 45000,"InterestDue": -6.54,"PrincipalDue": -265.23  }, ' +
        '  {"Period": 224,"FundsDistributed": 45000,"InterestDue": -5.82,"PrincipalDue": -265.95  }, ' +
        '  {"Period": 225,"FundsDistributed": 45000,"InterestDue": -5.1,"PrincipalDue": -266.67  }, ' +
        '  {"Period": 226,"FundsDistributed": 45000,"InterestDue": -4.37,"PrincipalDue": -267.39  }, ' +
        '  {"Period": 227,"FundsDistributed": 45000,"InterestDue": -3.65,"PrincipalDue": -268.12  }, ' +
        '  {"Period": 228,"FundsDistributed": 45000,"InterestDue": -2.92,"PrincipalDue": -268.84  }, ' +
        '  {"Period": 229,"FundsDistributed": 45000,"InterestDue": -2.2,"PrincipalDue": -269.57  }, ' +
        '  {"Period": 230,"FundsDistributed": 45000,"InterestDue": -1.47,"PrincipalDue": -270.3  }, ' +
        '  {"Period": 231,"FundsDistributed": 45000,"InterestDue": -0.73,"PrincipalDue": -271.03  } ' +
        ']} ';
    
    // Used json2apex: https://json2apex.herokuapp.com/
    public class LoanSched {
        public List<LoanServicerTest.MonthlyPayment> monthlyPayments;
	
    }

    public class MonthlyPayment {
        public Integer Period;
        public Integer FundsDistributed;
        public Double InterestDue;
        public Double PrincipalDue;
    }

    public static LoanServicerTest.LoanSched parse(String json) {
        return (LoanServicerTest.LoanSched) System.JSON.deserialize(json, LoanServicerTest.LoanSched.class);
    }
}