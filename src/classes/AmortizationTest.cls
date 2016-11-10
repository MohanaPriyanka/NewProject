@isTest(SeeAllData=true)
public class AmortizationTest{

    Static testMethod void triggerOppMethodTest(){
    	Account ac = new Account(name = 'test');
    	insert ac;
        Opportunity opp = new Opportunity(accountid = ac.id, name = 'Example', State_ab__c = 'MA', Commencement_Date__c = Date.Today(),
        	System_Size__c = 7, Number_of_Periods_Months__c = 2, Loan_Rate__c = 5.99, Principal_Step_Down_Occurs__c = true,
        	Added_Expenditures__c = 1300, Loan_Principle__c = 25000, stageName = 'New', closeDate = Date.today().addMonths(1));
        insert opp;
        Amortization am = new Amortization();
        opp = am.loadOppById(opp.id);
        if(opp == null)
             opp = new Opportunity();
        am.storeAmPlanFromTriggerExample(opp);
    }

    Static testMethod void triggerMapsMethodTest(){
        Amortization am = new Amortization();
        Map<ID, String> amo = new Map<ID, String>{'0061100000BDMd1' => '[{"yn":1,"pp":0,"mn":1,"lp":-181.19,"lb":36300,"ip":-181.19,"cy":2015,"ct":1,"cm":11}]'};
        Map<ID, String> amn = new Map<ID, String>{'0061100000BDMd1' => '[{"yn":1,"pp":-18195.18,"mn":12,"lp":-18286.01,"lb":0.01,"ip":-90.82,"cy":2016,"ct":1,"cm":10},{"yn":1,"pp":0,"mn":1,"lp":-1.19,"lb":300,"ip":-1.19,"cy":2015,"ct":1,"cm":11}]'};
        am.changeAmPlanInConsolidateObject(amo, amn);
        amo = new Map<ID, String>{'0061100000BDMd1' => '[{"yn":1,"pp":-18195.18,"mn":12,"lp":-18286.01,"lb":0.01,"ip":-90.82,"cy":2016,"ct":1,"cm":10},{"yn":1,"pp":0,"mn":1,"lp":-181.19,"lb":36300,"ip":-181.19,"cy":2015,"ct":1,"cm":11}]'};
        amn = new Map<ID, String>{'0061100000BDMd1' => '[{"yn":1,"pp":0,"mn":1,"lp":-1.19,"lb":300,"ip":-1.19,"cy":2015,"ct":1,"cm":11}]'};
        am.changeAmPlanInConsolidateObject(amo, amn);
    }

    Static testMethod void restAmortizationTest(){
		PageReference pageRef = Page.AmortizationSchedule;
		Test.setCurrentPage(pageRef);
		// --- check with wrong ID
		ApexPages.currentPage().getParameters().put('id', 'hello');
		Amortization am = new Amortization();
		// --- check with real ID
		ApexPages.currentPage().getParameters().put('id', '0061100000BDMd1');
		am = new Amortization();
		// --- for prepare output list for page
		Opportunity op1 = new Opportunity(Name = 'test', amortization_plan__c = '[{"yn":1,"pp":0,"mn":1,"lp":-146.76,"lb":29400,"ip":-146.76,"cy":2015,"ct":1,"cm":11}]');
		Opportunity[] opl1 = new Opportunity[]{op1};
		am.prepareOutput(opl1);
		// --- for function curForm
		Decimal d = -12.125;
		String tempstr = am.curForm(d);
		// --- for function getStateAbbr
		tempstr = 'massachusetts';
		am.getStateAbbr(null, tempstr);
		tempstr = 'north carolina';
		am.getStateAbbr(null, tempstr);
		tempstr = 'south carolina';
		am.getStateAbbr(null, tempstr);
		// --- for getStateVariables with state 'SC'
		am.systemSize = 1;
		am.vSCRebate = 0;
		am.grossSystemPrice = 1;
		am.getStateVariables();
		// --- for function calculate_fvifa
		d = am.calculate_fvifa(0, 1);
		// --- for function PMT
		d = am.PMT(0, 1, 1);
		// --- for function IPMT
		d = am.IPMT(0, 0, 0, 0);
		// --- for function PPMT
		d = am.PPMT(0, 0, 0, 0);
		// --- for functions 
		am.opp.Principal_Step_Down_Occurs__c = false;
		d = am.IPMTwCheckPSD(0, 1, 1, 1000);
		d = am.PPMTwCheckPSD(0, 1, 1, 1000);
		// --- for function saveToOpp
		am.saveToOpp(op1);
		am.saveToOpp(am.opp);
		// --- for function loadFromOpp
		op1.amortization_plan__c = '["h":"hello", "yn":"first"]';
		Boolean b = am.loadFromOpp(op1);
		// --- for function loadOppById
		op1 = am.loadOppById('0010000000BDMd1');
    }
}