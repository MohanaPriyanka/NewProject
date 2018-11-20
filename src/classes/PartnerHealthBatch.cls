public class PartnerHealthBatch implements Database.Batchable<SObject>,Schedulable {
    public String query { get; set; }

    public PartnerHealthBatch() {
    }

    public void execute(SchedulableContext sc) {
        PartnerHealthBatch partnerHealthBatchRun = new PartnerHealthBatch();
        partnerHealthBatchRun.query =
            'SELECT Id, Name, ' +
                '(SELECT Id FROM Accounts__r WHERE RecordTypeId = \'0120a000000uhu2\') ' +
                'FROM Partner__c ' +
                'WHERE Products__c INCLUDES (\'Residential Loan\') ' +
                'OR Products__c = null';
        Database.executeBatch(partnerHealthBatchRun, 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Partner__c> scope) {
        Map<Id, Partner_Health__c> partnerIdToHealthMap = new Map<Id, Partner_Health__c>();
        Map<Id, Partner__c> partnerMap = new Map<Id, Partner__c>(scope);

        processLeads(partnerIdToHealthMap, partnerMap);

        processOpportunities(partnerIdToHealthMap, partnerMap);

        processLoans(partnerIdToHealthMap, partnerMap);

        List<Partner_Health__c> partnerHealthList = calculateHealths(partnerIdToHealthMap);

        List<Database.UpsertResult> saveResults = Database.upsert(partnerHealthList, Partner_Health__c.fields.Unique_ID__c, false);
        for (Database.UpsertResult result : saveResults) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    Logger.logLater('PartnerHealthBatch', 'execute',
                        'Database error ' + err.getStatusCode() + ': ' + err.getMessage() + ' on ' + err.getFields());
                }
            }
        }
        Logger.flushLogs();
    }


    public void finish(Database.BatchableContext bc) {
    }

    private void processLeads(Map<Id, Partner_Health__c> partnerIdToHealthMap, Map<Id, Partner__c> partnerMap) {
        List<AggregateResult> leadAggregates = [
            SELECT Partner_Lookup__c, Status, COUNT(Id) numLeads,
                SUM(Annual_Income_Currency__c) annualIncome, SUM(Co_Applicant_Income__c) coAppIncome, SUM(Average_Debt_to_Income_After__c) avgDTI
            FROM Lead
            WHERE Partner_Lookup__c IN :partnerMap.keySet()
            AND Product_line__c = 'Residential Loan'
            AND Lead.LastName != 'Testcase'
            GROUP BY Partner_Lookup__c, Status
        ];
        for (AggregateResult leadAggregate : leadAggregates) {
            Partner_Health__c partnerHealth = getPartnerHealth(partnerMap.get((Id) leadAggregate.get('Partner_Lookup__c')), partnerIdToHealthMap);
            partnerHealth.Total_Leads__c += (Integer) leadAggregate.get('numLeads');
            if (leadAggregate.get('Status') == 'Qualified') {
                partnerHealth.Qualified_Leads__c += (Integer) leadAggregate.get('numLeads');
            } else if (leadAggregate.get('Status') == 'Unqualified') {
                partnerHealth.Unqualified_Leads__c += (Integer) leadAggregate.get('numLeads');
            } else if (leadAggregate.get('Status') == 'Pre-Qualified') {
                partnerHealth.Num_Pre_Qualified_Leads__c += (Integer) leadAggregate.get('numLeads');
            }
            if (leadAggregate.get('Status') == 'Ready for Credit Check' || leadAggregate.get('Status') == 'Unfinished') {
                partnerHealth.Unfinished_Leads_Ready_for_Credit_Check__c += (Integer) leadAggregate.get('numLeads');
            } else {
                partnerHealth.Finished_Leads_Ready_for_Credit_Check__c += (Integer) leadAggregate.get('numLeads');
                partnerHealth.Average_Annual_Income__c += Util.nullToZero((Decimal) leadAggregate.get('annualIncome'));
                partnerHealth.Average_Annual_Income__c += Util.nullToZero((Decimal) leadAggregate.get('coAppIncome'));
                partnerHealth.Average_DTI__c += Util.nullToZero((Decimal) leadAggregate.get('avgDTI'));
            }
        }
    }

    private void processOpportunities(Map<Id, Partner_Health__c> partnerIdToHealthMap, Map<Id, Partner__c> partnerMap) {
        List<Opportunity> opps = [
            SELECT CreatedDate, Partner_tag_lookup__c,StageName, Max_FICO__c, Installation_Queue_Duration__c, Time_to_Close__c
            FROM Opportunity
            WHERE Partner_tag_lookup__c IN :partnerMap.keySet()
            AND StageName = 'Complete'
            AND Product_Line__c = 'Residential Loan'
            AND (NOT Name LIKE '%Testcase%')
        ];
        for (Opportunity opp : opps) {
            Partner_Health__c ph = getPartnerHealth(partnerMap.get(opp.Partner_tag_lookup__c), partnerIdToHealthMap);

            ph.Completed_Opportunities__c += 1;
            if (opp.Installation_Queue_Duration__c > 100) {
                ph.Num_of_Installations_over_100_Days__c += 1;
            }
            if (opp.Time_to_Close__c != null) {
                ph.Average_App_to_Close__c += opp.Time_to_Close__c;
            }
            if (opp.Max_FICO__c != null) {
                ph.Average_Max_FICO__c += opp.Max_FICO__c;
            }
        }
    }

    private void processLoans(Map<Id, Partner_Health__c> partnerIdToHealthMap, Map<Id, Partner__c> partnerMap) {
        List<Loan__c> loans = [
            SELECT CreatedDate, Partner__c, Days_Past_Due__c,Date_Contract_Signature_Disbursed__c, Date_Interconnection_Disbursed__c
            FROM Loan__c
            WHERE Partner__c IN :partnerMap.keySet()
            AND Opportunity__r.StageName = 'Complete'
        ];
        for (Loan__c loan : loans) {
            Partner_Health__c partnerHealth = getPartnerHealth(partnerMap.get(loan.Partner__c), partnerIdToHealthMap);
            partnerHealth.Perc_of_Delinquent_Loans__c += 1;
            if (loan.Days_Past_Due__c != null && loan.Days_Past_Due__c != '1-30') {
                partnerHealth.Num_Delinquent_Loans__c += 1;
            }
            if (loan.Date_Contract_Signature_Disbursed__c != null && loan.Date_Interconnection_Disbursed__c != null) {
                partnerHealth.Average_Construction_Period__c += loan.Date_Contract_Signature_Disbursed__c.daysBetween(loan.Date_Interconnection_Disbursed__c);
                partnerHealth.Total_Loans_with_Construction_Period__c += 1;
            }
        }
    }

    private List<Partner_Health__c> calculateHealths(Map<Id, Partner_Health__c> partnerIdToHealthMap) {
        List<Partner_Health__c> partnerHealthList = new List<Partner_Health__c>();
        for (Id partnerId : partnerIdToHealthMap.keySet()) {
            Partner_Health__c partnerHealth = partnerIdToHealthMap.get(partnerId);
            if (partnerHealth.Completed_Opportunities__c != 0) {
                partnerHealth.Average_Max_FICO__c =
                    partnerHealth.Average_Max_FICO__c / partnerHealth.Completed_Opportunities__c;
                partnerHealth.Average_App_to_Close__c =
                    partnerHealth.Average_App_to_Close__c / partnerHealth.Completed_Opportunities__c;
            }
            if (partnerHealth.Completed_Opportunities__c != 0) {
                partnerHealth.Perc_Installation_over_100_Days__c =
                    (partnerHealth.Num_of_Installations_over_100_Days__c / partnerHealth.Completed_Opportunities__c) * 100;
            }
            if (partnerHealth.Perc_of_Delinquent_Loans__c != 0) {
                partnerHealth.Perc_of_Delinquent_Loans__c =
                    (partnerHealth.Num_Delinquent_Loans__c / partnerHealth.Perc_of_Delinquent_Loans__c) * 100;
            }
            if (partnerHealth.Finished_Leads_Ready_for_Credit_Check__c != 0) {
                partnerHealth.Approval_Rate__c =
                    (partnerHealth.Qualified_Leads__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c) * 100;
                partnerHealth.Average_DTI__c =
                    (partnerHealth.Average_DTI__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c) * 100;
                partnerHealth.Conversion_Rate__c =
                    (partnerHealth.Completed_Opportunities__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c) * 100;
                partnerHealth.Decline_Rate__c =
                    (partnerHealth.Unqualified_Leads__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c) * 100;
                partnerHealth.Pre_Qualified_Rate__c =
                    (partnerHealth.Num_Pre_Qualified_Leads__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c) * 100;
                partnerHealth.Average_Annual_Income__c =
                    partnerHealth.Average_Annual_Income__c / partnerHealth.Finished_Leads_Ready_for_Credit_Check__c;
            }
            if (partnerHealth.Total_Loans_with_Construction_Period__c > 0) {
                partnerHealth.Average_Construction_Period__c =
                    partnerHealth.Average_Construction_Period__c / partnerHealth.Total_Loans_with_Construction_Period__c;
            }
            partnerHealthList.add(partnerHealth);
        }
        return partnerHealthList;
    }

    public Partner_Health__c getPartnerHealth(Partner__c partner, Map<Id, Partner_Health__c> partnerIdToPartnerHealthMap) {
        if (!partnerIdToPartnerHealthMap.containsKey(partner.Id)) {
            partnerIdToPartnerHealthMap.put(partner.Id, buildPartnerHealth(partner));
        }
        return partnerIdToPartnerHealthMap.get(partner.Id);
    }
    
    private Partner_Health__c buildPartnerHealth(Partner__c p) {
        Datetime now = Datetime.now();
        Date dateKey = Date.newInstance(now.year(), now.month(), now.day()).toStartOfMonth();
        Id partnerAccountId;
        if (!p.Accounts__r.isEmpty()) {
            partnerAccountId = p.Accounts__r[0].Id;
        }
        if (p.Accounts__r.size() != 1) {
            Logger.logNow('PartnerHealthBatch', 'buildPartnerHealth', p.Name + ' (' + p.Id +' ) has ' + p.Accounts__r.size() +
                ' related Accounts of Partner record type, but they should have 1');
        }
        return new Partner_Health__c(
            Name = p.Name + ' - ' + now.format('MMM yyyy'),
            Num_Delinquent_Loans__c = 0,
            Num_of_Installations_over_100_Days__c = 0,
            Perc_Installation_over_100_Days__c = 0,
            Perc_of_Delinquent_Loans__c = 0,
            Approval_Rate__c = 0,
            Average_Annual_Income__c = 0,
            Average_App_to_Close__c = 0,
            Average_Construction_Period__c = 0,
            Total_Loans_with_Construction_Period__c = 0,
            Average_DTI__c = 0,
            Average_Max_FICO__c = 0,
            Completed_Opportunities__c = 0,
            Conversion_Rate__c = 0,
            Date__c = dateKey,
            Decline_Rate__c = 0,
            Finished_Leads_Ready_for_Credit_Check__c = 0,
            Partner__c = p.Id,
            Partner_Account__c = partnerAccountId,
            Qualified_Leads__c = 0,
            Total_Leads__c = 0,
            Unfinished_Leads_Ready_for_Credit_Check__c = 0,
            Unqualified_Leads__c = 0,
            Num_Pre_Qualified_Leads__c = 0,
            Unique_ID__c = p.Id + '' + dateKey
        );
    }
}