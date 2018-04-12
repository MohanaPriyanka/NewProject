global class DisbursalStatusProcessor implements Database.Batchable<sObject> {

	global Integer recordsProcessed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, DOER_Solar_Loan__c, Disbursal_1_Contract_Signature_Checkbox__c, Disbursal_2_Mechanical_Install_Checkbox__c, Disbursal_3_Full_Install_Checkbox__c, Disbursal_Due_Contract_del__c,' +
            'Ready_for_Disbursal_Contract__c, FBO_Funded_Contract_Signature__c, Disbursal_Type_Contract__c, Disbursal_Due_Mechanical_Completion__c, Ready_for_Disbursal__c,' +
            'FBO_Funded_Mech_Completion__c, Disbursal_Type_Mech_Completion__c, Disbursal_Due_System_Operation__c, Ready_for_Disbursal_Intercon__c, FBO_Funded_System_Op__c,' +
            'Disbursal_Type_Interconnect__c, Manual_Hold_on_Disbursal__c, Reason_for_Manual_Hold_if_Checked__c, Disbursal_1_Contract_Signature__c, Disbursal_2_Mechanical_Installation__c,' +
            'Disbursal_3_Full_Install__c, Anticipated_Disbursal_Date_Contract__c, Anticipated_Disbursal_Date_Mechanical__c, Anticipated_Disbursal_Date_Full__c, Lender_of_Record__c ' +
            'FROM Opportunity ' +
            'WHERE Product_Line__c = \'Residential Loan\'' + 'AND StageName =\'Complete\''
        );
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
		Date CONTRACTDATE;
		Date CONTRACTADATE;
		Boolean CONTRACTDUE;
		Boolean CONTRACTREADY;
		Boolean CONTRACTFBO;
		String CONTRACTTYPE;
		Date MECHDATE;
		Date MECHADATE;
		Boolean MECHDUE;
		Boolean MECHREADY;
		Boolean MECHFBO;
		String MECHTYPE;
		Date IXDATE;
		Date IXADATE;
		Boolean IXDUE;
		Boolean IXREADY;
		Boolean IXFBO;
		String IXTYPE;
		Boolean MANUALHOLD;
		String MANUALHOLDREASON;
		Boolean DOER;
		String LOR;
        Disbursal__c CONTRACTDISBURSAL = new Disbursal__c();
        Disbursal__c MECHDISBURSAL = new Disbursal__c();
        Disbursal__c IXDISBURSAL = new Disbursal__c();
        List<Disbursal__c> disbursalsToUpdate = new List<Disbursal__c>();
        Map<String, Disbursal__c> disbursalMap = new Map<String, Disbursal__c>();

        for (Disbursal__c disbursal : [SELECT Id, Type__c, Status__c, Funds_in_FBO_Account__c, Loan__r.Opportunity__r.Id FROM Disbursal__c]) {
            String mapKey = disbursal.Loan__r.Opportunity__r.Id + disbursal.Type__c;
            disbursalMap.put(mapKey, disbursal);
        }
        for (Opportunity opp : opportunities) {
            DOER = opp.DOER_Solar_Loan__c;
            LOR = opp.Lender_of_Record__c;
            CONTRACTDATE = opp.Disbursal_1_Contract_Signature_Checkbox__c;
            CONTRACTADATE = opp.Anticipated_Disbursal_Date_Contract__c;
            CONTRACTDUE = opp.Disbursal_Due_Contract_del__c;
            CONTRACTREADY = opp.Ready_for_Disbursal_Contract__c;
            CONTRACTFBO = opp.FBO_Funded_Contract_Signature__c;
            CONTRACTTYPE = opp.Disbursal_Type_Contract__c;
            if (!DOER) {
                MECHDATE = opp.Disbursal_2_Mechanical_Install_Checkbox__c;
                MECHADATE = opp.Anticipated_Disbursal_Date_Mechanical__c;
                MECHDUE = opp.Disbursal_Due_Mechanical_Completion__c;
                MECHREADY = opp.Ready_for_Disbursal__c;
                MECHFBO = opp.FBO_Funded_Mech_Completion__c;
                MECHTYPE = opp.Disbursal_Type_Mech_Completion__c;
            }
            IXDATE = opp.Disbursal_3_Full_Install_Checkbox__c;
            IXADATE = opp.Anticipated_Disbursal_Date_Full__c;
            IXDUE = opp.Disbursal_Due_System_Operation__c;
            IXREADY = opp.Ready_for_Disbursal_Intercon__c;
            IXFBO = opp.FBO_Funded_System_Op__c;
            IXTYPE = opp.Disbursal_Type_Interconnect__c;
            MANUALHOLD = opp.Manual_Hold_on_Disbursal__c;
            MANUALHOLDREASON = opp.Reason_for_Manual_Hold_if_Checked__c;

            if(CONTRACTTYPE == 'ACH Disbursal') {
                CONTRACTTYPE = 'ACH';
            }
            if (CONTRACTTYPE == 'Check Disbursal') {
                CONTRACTTYPE = 'Check';
            }
            if (!DOER) {
                if(MECHTYPE == 'ACH Disbursal') {
                    MECHTYPE = 'ACH';
                }
                if (MECHTYPE == 'Check Disbursal') {
                    MECHTYPE = 'Check';
                }
            }
            if(IXTYPE == 'ACH Disbursal') {
                IXTYPE = 'ACH';
            }
            if (IXTYPE == 'Check Disbursal') {
                IXTYPE = 'Check';
            }

            CONTRACTDISBURSAL = disbursalMap.get(opp.Id + 'Contract Signature');
            if (!DOER) {
                MECHDISBURSAL = disbursalMap.get(opp.Id + 'Mechanical Installation');
            }
            IXDISBURSAL = disbursalMap.get(opp.Id + 'Interconnection');

            if((!DOER && CONTRACTDISBURSAL != null && MECHDISBURSAL != null && IXDISBURSAL != null) || (DOER && CONTRACTDISBURSAL != null && IXDISBURSAL != null)) {
                //Set all disbursals to Pending
                CONTRACTDISBURSAL.Status__c = 'Pending';
                if (!DOER) {
                    MECHDISBURSAL.Status__c = 'Pending';
                }
                IXDISBURSAL.Status__c = 'Pending';

                //Set disbursals that are due, not ready, and awaiting QC
                if (CONTRACTDUE) {
                    CONTRACTDISBURSAL.Status__c = 'Due';
                }
                if (!DOER) {
                    if (MECHDUE) {
                        MECHDISBURSAL.Status__c = 'Due';
                    }
                }
                if (IXDUE) {
                    IXDISBURSAL.Status__c = 'Due';
                }

                //set the disbursals to ready after BW had QC'd them. 
                if (!DOER) {
                    if (CONTRACTREADY) {
                        if (LOR != 'Bluewave') {
                            CONTRACTDISBURSAL.Status__c = 'Ready for FBO Funding';
                        } else {
                            CONTRACTDISBURSAL.Status__c = 'Ready for Disbursement';
                        }
                    }
                    if (MECHDUE) {
                        if (LOR != 'Bluewave') {
                            MECHDISBURSAL.Status__c = 'Ready for FBO Funding';
                        } else {
                            MECHDISBURSAL.Status__c = 'Ready for Disbursement';
                        }
                    }
                    if (IXDUE) {
                        if (LOR != 'Bluewave') {
                            IXDISBURSAL.Status__c = 'Ready for FBO Funding';
                        } else {
                            IXDISBURSAL.Status__c = 'Ready for Disbursement';
                        }
                    }
                } else {
                    if (CONTRACTDATE == null && CONTRACTDUE && !MANUALHOLD) {
                        if (CONTRACTFBO) {
                            CONTRACTDISBURSAL.Status__c = 'Ready for Disbursement';
                        } else {
                            CONTRACTDISBURSAL.Status__c = 'Ready for FBO Funding';
                        }
                    }
                    if (IXDATE == null && IXDUE && !MANUALHOLD) {
                        if (IXFBO) {
                            IXDISBURSAL.Status__c = 'Ready for Disbursement';
                        } else {
                            IXDISBURSAL.Status__c = 'Ready for FBO Funding';
                        }
                    }
                }

                // set the disbursals to Ready for Disbursement if their opportunity shows that they have had FBO funding.
                if (CONTRACTFBO) {
                    CONTRACTDISBURSAL.Funds_in_FBO_Account__c = CONTRACTFBO;
                    CONTRACTDISBURSAL.Status__c = 'Ready for Disbursement';
                }
                if (!DOER) {
                    if (MECHFBO) {
                        MECHDISBURSAL.Funds_in_FBO_Account__c = MECHFBO;
                        MECHDISBURSAL.Status__c = 'Ready for Disbursement';
                    }
                }
                if (IXFBO) {
                    IXDISBURSAL.Funds_in_FBO_Account__c = IXFBO;
                    IXDISBURSAL.Status__c = 'Ready for Disbursement';
                }

                //set disbursal to disbursed if their opportunity's date value is not blank
                if (CONTRACTDATE != null) {
                    CONTRACTDISBURSAL.Status__c = 'Disbursed';
                    CONTRACTDISBURSAL.Date_of_Disbursal__c = CONTRACTDATE;
                    CONTRACTDISBURSAL.Disbursal_Method__c = CONTRACTTYPE;
                }
                if (!DOER) {
                    if (MECHDATE != null) {
                        MECHDISBURSAL.Status__c = 'Disbursed';
                        MECHDISBURSAL.Date_of_Disbursal__c = MECHDATE;
                        MECHDISBURSAL.Disbursal_Method__c = MECHTYPE;
                    }
                }
                if (IXDATE != null) {
                    IXDISBURSAL.Status__c = 'Disbursed';
                    IXDISBURSAL.Date_of_Disbursal__c = IXDATE;
                    IXDISBURSAL.Disbursal_Method__c = IXTYPE;
                }

                //set disbursal to manual hold
                if (MANUALHOLD) {
                    if (!DOER) {
                        if (CONTRACTDATE == null) {
                            CONTRACTDISBURSAL.Status__c = 'Hold';
                            CONTRACTDISBURSAL.Reason_for_Hold__c = MANUALHOLDREASON;
                        }
                        if (CONTRACTDATE != null && MECHDATE == null) {
                            MECHDISBURSAL.Status__c = 'Hold';
                            MECHDISBURSAL.Reason_for_Hold__c = MANUALHOLDREASON;
                        }
                        if (CONTRACTDATE != null && MECHDATE != null && IXDATE == null) {
                            IXDISBURSAL.Status__c = 'Hold';
                            IXDISBURSAL.Reason_for_Hold__c = MANUALHOLDREASON;
                        }
                    } else {
                        if (CONTRACTDATE == null) {
                            CONTRACTDISBURSAL.Status__c = 'Hold';
                            CONTRACTDISBURSAL.Reason_for_Hold__c = MANUALHOLDREASON;
                        }
                        if (CONTRACTDATE != null && IXDATE == null) {
                            IXDISBURSAL.Status__c = 'Hold';
                            IXDISBURSAL.Reason_for_Hold__c = MANUALHOLDREASON;
                        }
                    }
                }
                
                disbursalsToUpdate.add(CONTRACTDISBURSAL);
                if (!DOER) {
                    disbursalsToUpdate.add(MECHDISBURSAL);
                }
                disbursalsToUpdate.add(IXDISBURSAL);
            }
        }
        update disbursalsToUpdate;
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    

}