@IsTest
private class PartnerHealthBatchTest {
    static testMethod void unitTest() {
        Product2 prd = new Product2(
            Name = 'Loan Product',
            Disbursal_Terms__c = '30% Building Permit Approved, 60% Mechanical Installation, 10% Interconnection',
            Loan_Interest_Only_Period__c = 12
        );
        insert prd;
        Partner__c prt = new Partner__c(
            Name = 'Partner',
            Products__c = 'Residential Loan');
        insert prt;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            Name = 'Cersei Lannister', 
            Adjusted_DTI__c = 1020,
            LASERCA__Credit_Score_TransUnion__c = '500'
        );
        LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Brendan Hartley', 
            Adjusted_DTI__c = 1020,
            LASERCA__Credit_Score_TransUnion__c = '500'
        );
        LASERCA__Personal_Credit_Report__c pcr2 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Kimi Raikkonen', 
            Adjusted_DTI__c = 1020,
            LASERCA__Credit_Score_TransUnion__c = '500'
        );
        LASERCA__Personal_Credit_Report__c pcr3 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Lewis Hamilton', 
            Adjusted_DTI__c = 1020,
            LASERCA__Credit_Score_TransUnion__c = '500'
        );
        insert new List<LASERCA__Personal_Credit_Report__c>{
            pcr,pcr1,pcr2,pcr3
        };
        Lead ld = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Jane',
            LastName = 'Doe',
            Company = 'Unknown',
            Status = 'Unqualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100
        );
        Lead ld1 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Unknown for Grown Ups',
            Status = 'Pre-Qualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100
        );
        Lead ld2 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Cersei',
            LastName = 'Lannister',
            Company = 'King\' Landing',
            Status = 'Qualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100,
            Co_Applicant_Income__c = 200,
            Personal_Credit_Report__c = pcr.Id
        );
        Lead ld5 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Kimi',
            LastName = 'Raikkonen',
            Company = 'Scuderia Ferrari',
            Status = 'Qualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100,
            Co_Applicant_Income__c = 200,
            Personal_Credit_Report__c = pcr2.Id
        );
        Lead ld6 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Lewis',
            LastName = 'Hamilton',
            Company = 'Mercedes AMG',
            Status = 'Qualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100,
            Co_Applicant_Income__c = 200,
            Personal_Credit_Report__c = pcr3.Id
        );
        Lead ld7 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Brendan',
            LastName = 'Hartley',
            Company = 'Toro Rosso',
            Status = 'Qualified',
            Partner_Lookup__c = prt.Id,
            Annual_Income_Currency__c = 100,
            Co_Applicant_Income__c = 200,
            Personal_Credit_Report__c = pcr1.Id
        );
        Lead ld3 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'Jamie',
            LastName = 'Lannister',
            Company = 'Golden Arm',
            Status = 'Ready for Credit Check',
            Partner_Lookup__c = prt.Id
        );
        Lead ld4 = new Lead(
            Unfinished_Lead__c = true,
            Product_line__c = 'Residential Loan',
            FirstName = 'John',
            LastName = 'Snow',
            Company = 'The North',
            Status = 'Unfinished',
            Partner_Lookup__c = prt.Id
        );
        insert new List<SObject>{
            ld1, ld2, ld3, ld4, ld, ld5, ld6, ld7
        };
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld2.Id);
        lc.setConvertedStatus('Qualified');
        Database.convertLead(lc);
        Database.LeadConvert lc1 = new Database.LeadConvert();
        lc1.setLeadId(ld5.Id);
        lc1.setConvertedStatus('Qualified');
        Database.convertLead(lc1);
        Database.LeadConvert lc2 = new Database.LeadConvert();
        lc2.setLeadId(ld6.Id);
        lc2.setConvertedStatus('Qualified');
        Database.convertLead(lc2);
        Database.LeadConvert lc3 = new Database.LeadConvert();
        lc3.setLeadId(ld7.Id);
        lc3.setConvertedStatus('Qualified');
        Database.convertLead(lc3);
        List<Opportunity> oppList = [SELECT Name, StageName, Partner_tag_lookup__c, Max_FICO__c, Installation_Queue_Duration__c,Time_to_Close__c,Lead__c
                                     FROM Opportunity];
        Set<id> oppIds = new Set<Id>();
        for (Opportunity opp : oppList) {
            oppIds.add(opp.Id);
            opp.StageName = 'Completed';
            opp.Product_line__c = 'Residential Loan';
            opp.Partner_tag_lookup__c = prt.Id;
            opp.Personal_Credit_Report2__c = pcr.Id;
            opp.Disbursal_3_Full_Install_Checkbox__c = Date.today();
            opp.Contract_Close_Date__c = Date.today().addMonths(-5);
            opp.Date_of_Application__c = Datetime.newInstance(Date.today().addMonths(-4), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
            opp.Disbursal_1_Contract_Signature_Checkbox__c = Date.today().addMonths(-4);
            opp.Disbursal_2_Mechanical_Install_Checkbox__c = Date.today();
            opp.Disbursal_3_Full_Install_Checkbox__c = Date.today();
            opp.Product__c=prd.Id;
        }
        update oppList;
        Loan_Data__c cp = new Loan_Data__c(
            Interest_Rate__c = 5,
            Investor__c = 'GOT',
            Month__c = Datetime.newInstance(Date.today().addMonths(-7), Time.newInstance(0, 0, 0, 0)).format('MMMM'),
            Pool_Type__c = 'Revolving Credit Line',
            Total_Capital__c = 10000000,
            Year__c = Datetime.newInstance(Date.today().addMonths(-7), Time.newInstance(0, 0, 0, 0)).format('yyyy')
        );
        insert cp;
        Loan_Traunch__c lt = new Loan_Traunch__c(
            Loan_Data__c = cp.Id,
            Stage__c = 'Open'
        );
        insert lt;
        Test.startTest();
        List<Loan__c> loanList = new List<Loan__c>();
        for (Opportunity opp : oppList) {
            loanList.add(new Loan__c(Partner__c = prt.Id,
                                     Name = prt.Name,
                                     Days_Past_Due__c = '1-30',
                                     Loan_Tranche__c = lt.Id,
                                     Lead__c = opp.Lead__c,
                                     Opportunity__c = opp.Id,
                                     Requested_Loan_Amount__c=100000,
                                     Product__c=prd.Id
                                    ));
        }
        insert loanList;
        for (Opportunity opp : oppList) {
            opp.StageName = 'Complete';
        }
        update oppList;

        String jobId = System.schedule('TestPartnerHealthBatch', '0 0 * * * ?', new PartnerHealthBatch());
        PartnerHealthBatch partnerHealthBatchRun = new PartnerHealthBatch();
        partnerHealthBatchRun.query = 'SELECT Name FROM Partner__c WHERE Products__c INCLUDES (\'Residential Loan\') OR Products__c = null';
        Database.executeBatch(partnerHealthBatchRun, 200);
        Test.stopTest();

        List<Partner_Health__c> pHealthList = [
            SELECT Id, Name, Unique_ID__c,
                Num_Delinquent_Loans__c,
                Num_of_Installations_over_100_Days__c,
                Perc_Installation_over_100_Days__c,
                Perc_of_Delinquent_Loans__c,
                Approval_Rate__c,
                Average_Annual_Income__c,
                Average_App_to_Close__c,
                Average_Construction_Period__c,
                Average_DTI__c,
                Average_Max_FICO__c,
                Completed_Opportunities__c,
                Conversion_Rate__c,
                Date__c,
                Decline_Rate__c,
                Finished_Leads_Ready_for_Credit_Check__c,
                Partner__c,
                Qualified_Leads__c,
                Total_Leads__c,
                Unfinished_Leads_Ready_for_Credit_Check__c,
                Unqualified_Leads__c,
                Num_Pre_Qualified_Leads__c
            FROM Partner_Health__c
        ];

        Opportunity opp = [SELECT Time_to_Close__c, Max_FICO__c FROM Opportunity WHERE Id = :oppList[0].Id];
        ld = [SELECT Average_Debt_to_Income_After__c, Status FROM Lead WHERE Id = :ld2.Id];
        
        Decimal finishedLeads = 6;
        Decimal unfinishedLeads = 2;
        System.assertEquals(1, pHealthList.size(), 1);
        System.assertEquals(prt.Name + ' - ' + Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('MMM yyyy'), pHealthList[0].Name);
        System.assertEquals(prt.Id + '' + Date.today().toStartOfMonth(), pHealthList[0].Unique_ID__c);
        System.assertEquals(0, pHealthList[0].Num_Delinquent_Loans__c);
        System.assertEquals(4, pHealthList[0].Num_of_Installations_over_100_Days__c);
        System.assertEquals(100, pHealthList[0].Perc_Installation_over_100_Days__c);
        System.assertEquals(0, pHealthList[0].Perc_of_Delinquent_Loans__c);
        System.assertEquals((Decimal.valueOf(4) / finishedLeads)*100, pHealthList[0].Approval_Rate__c);
        System.assertEquals(Decimal.valueOf(1400) / finishedLeads, pHealthList[0].Average_Annual_Income__c);
        System.assertEquals(opp.Time_to_Close__c, pHealthList[0].Average_App_to_Close__c);
        System.assertEquals(0, pHealthList[0].Average_Construction_Period__c);
        System.assertEquals(opp.Max_FICO__c, pHealthList[0].Average_Max_FICO__c);
        System.assertEquals(4, pHealthList[0].Completed_Opportunities__c);
        System.assertEquals((Decimal.valueOf(4) / finishedLeads)*100, pHealthList[0].Conversion_Rate__c);
        System.assertEquals(finishedLeads, pHealthList[0].Finished_Leads_Ready_for_Credit_Check__c);
        System.assertEquals(8, pHealthList[0].Total_Leads__c);
        System.assertEquals(4, pHealthList[0].Qualified_Leads__c);
        System.assertEquals(unfinishedLeads, pHealthList[0].Unfinished_Leads_Ready_for_Credit_Check__c);
        System.assertEquals(1, pHealthList[0].Unqualified_Leads__c);
        System.assertEquals(1, pHealthList[0].Num_Pre_Qualified_Leads__c);
    }
}