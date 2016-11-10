global class Amortization {

        global Map<String, amRecord> mamr = new Map<String, amRecord> ();
        // Set initial values with default values
        public decimal systemSize;
        public decimal grossSystemPrice;
        public decimal loanAmount;
	public decimal itc_basis;
        public integer loanTerm;
        public integer loanTerm_IO;
        public decimal loanRateM;
        public decimal vSCRebate;
        public decimal stateTaxCredit;
        public decimal financingFee;
        // Variables with default values
        public decimal cost = 4;
        public decimal rebate = 0;
        public integer rebate_per = 2;
        public decimal itc = 0.3;
        public integer psd_per = 12;
        public boolean int_only = true;
        public string stateAbbr = 'MA';
        public decimal vSDAmount = 0;

        // ---------- Structure of the amortization schedule record
        public virtual class amRecord {
                public Integer mn { get; set; } // Month's number
                public Integer yn { get; set; } // Yars's number
                public Integer cm { get; set; } // Calendar month
                public Integer cy { get; set; } // Calendar year
                public decimal ip { get; set; } // Interest Payment ($)
                public decimal pp { get; set; } // Principal Payment ($)
                public decimal lb { get; set; } // Loan Balance ($)
                public decimal lp { get; set; } // Loan Payment ($)
                public Integer ct { get; set; } // Number of Opportunity ID
        }

        public class amRecords extends amRecord {
                private List<String> args = new String[]{'0','number','###,##0.000'};
                public String ips { get; set; } // Interest Payment ($)
                public String pps { get; set; } // Principal Payment ($)
                public String lbs { get; set; } // Loan Balance ($)
                public String lps { get; set; } // Loan Payment ($)
                public amRecords(amRecord rec){
                        mn = rec.mn;    yn = rec.yn;    cm = rec.cm;    cy = rec.cy;
                        ip = rec.ip;
                        if (ip == 0) ips = '-';
                        else{
                            ips = '$'+String.format((ip.abs()+0.001).format(), args); ips = ips.substring(0, ips.length()-1);
                            if (ip < 0) ips = '('+ips+')';
                        }
                        pp = rec.pp;
                        if (pp == 0) pps = '-';
                        else{
                            pps = '$'+String.format((pp.abs()+0.001).format(), args); pps = pps.substring(0, pps.length()-1);       
                            if (pp < 0) pps = '('+pps+')';
                        }
                        lb = rec.lb;
                        if (lb == 0) lbs = '-';
                        else{
                            lbs = '$'+String.format((lb.abs()+0.001).format(), args); lbs = lbs.substring(0, lbs.length()-1);
                            if (lb < 0) lbs = '('+lbs+')';
                        }
                        lp = rec.lp;
                        if (lp == 0) lps = '-';
                        else{
                            lps = '$'+String.format((lp.abs()+0.001).format(), args); lps = lps.substring(0, lps.length()-1);
                            if (lp < 0) lps = '('+lps+')';
                        }
                }
        }
        // ---------- 
        public string curForm(Decimal d){
                return d.format();
        }
        // ---------- 
        public List<amRecord> amPlan { get; set; }
        public List<amRecords> amPlans { get; set; }
        public List<amRecords> amPlanh { get; set; }
        // ----------
        public ApexPages.Pagereference currPage { get; private set; }
        public String currPageUrl { get; private set; }
        public Map<String, String> mp { get; private set; }
        private ID oppId;
        public Opportunity opp { get; private set; }

        // --- constructor of the class which initialized needed variables
        public Amortization() {
                        // ----- If class initialized not from Visual Page then exit
                        currPage = ApexPages.currentPage();
                        if (currPage == null) return;
                        currPageUrl = currPage.getUrl();
                        system.debug(logginglevel.INFO, 'Page URL: ' + currPageUrl);
                        mp = currPage.getParameters();
                        if (mp != null && mp.containsKey('id')) {
                                try {
                                        oppId = mp.get('id');
                                        Opportunity[] opl = [SELECT id, name, amortization_plan__c FROM Opportunity WHERE id = :oppId];
                                        prepareOutput(opl);
                                } catch(Exception e) {
                                        system.debug('Exception during selecting opportunity with ID=' + oppId);
                                        system.debug(e);
                                }
                        }
        }
                
                // --- simple fuction for prepeare output list
                public void prepareOutput(Opportunity[] opl){
                        if (opl != null && opl.size() > 0) {
                                opp = opl[0];
                if (opp != null && opp.amortization_plan__c != null)
                        loadFromOpp(opp);
                amPlans = new List<amRecords>();
                amPlanh = new List<amRecords>();
                for( amRecord r : amPlan ){
                        amPlans.add( new amRecords(r) );
                }
            }
                }

	// --- generate schedule into amPlan list of object amRecord
	public void generateAmPlan(Opportunity oppt) { //decimal months, decimal rate, decimal loanAmount
		if (oppt != null) opp = oppt;
		system.debug('\n Initial params from Opportunity:'
			+ '\n US State: ' + opp.State__c					// State. Will used if State Abbr is empty
			+ '\n US State abbr: ' + opp.State_ab__c			// State Abbr.
			+ '\n Starting Date: ' + opp.Commencement_Date__c	// Starting year and month
			+ '\n System size (kW DC): ' + opp.System_Size__c	// System size (kW DC)
			+ '\n Months: ' + opp.Number_of_Periods_Months__c	// Loan Term
			+ '\n Rate: ' + opp.Loan_Rate__c					// Loan Rate to Consumer (%)
			+ '\n Financing Fee: ' + opp.Financing_Fee__c		// Loan Closing Fee ($)
			+ '\n Loan Amount (Principal): '+opp.Loan_Principle__c		// Principal ($)
			+ '\n Loan Amount with Fee: '+opp.Loan_Amount_Financed__c	// Principal ($)
			+ '\n Principal Step Down Occurs: ' + opp.Principal_Step_Down_Occurs__c	// Principal Step Down Occurs
		);

		// Cost per W/DC
		// Rebate ($) - Applied at Step Down Period / Tax Filing
		// Period of Rebate Applied (SC Specific)
		// Investment Tax Credit (%)
		// Principal Step Down Occurs
		// Principal Step Down Period upon ITC Receipt
		// Interest Only on Full Loan During Step Down Period

		// store System Size to public variable
		systemSize = opp.System_Size__c;
		// store Financing Fee to public variable 'financingFee'
		financingFee = opp.Financing_Fee__c;

		// get state abbreviation to variable 'stateAbbr'
		getStateAbbr(opp.State_ab__c, opp.State__c);

		// Get initial values from custom settings
		getInitValues();

		// Get Loan Amount
		grossSystemPrice = cost * systemSize * 1000;
		loanAmount = opp.Loan_Amount_Financed__c;
		itc_basis = opp.Loan_Principle__c;

		// Get Loan Term + IO Period
		loanTerm = Integer.valueOf(opp.Number_of_Periods_Months__c);
		loanTerm_IO = loanTerm + psd_per;

		// Calculate monthly rate
		loanRateM = (opp.Loan_Rate__c / 1200); //*100).round(System.RoundingMode.CEILING) / 100;
		system.debug('Month rate is ' + loanRateM);

		// get SC Rebate from table
		getStateVariables();

		// calculate Step Down Amount to 'vSDAmount' variable
		if (opp.Principal_Step_Down_Occurs__c)
			calcSDAmount();

		amPlan = new List<amRecord> ();
		// Calculate schedule
		calculate_schedule();
	}

        // ********* Additional functions

        // --- Get state abbreviation
        public void getStateAbbr(String abbr, String state) {
                if (abbr != null && abbr.length() == 2) {
                        stateAbbr = abbr.toUpperCase();
                } else {
                        if (state != null && state != '') {
                                Map<String, String> stabbr = new Map<String, String> {
                                        'massachusetts' => 'MA',
                                        'north carolina' => 'NC',
                                        'south carolina' => 'SC'
                                };
                                if (stabbr.containsKey(state.toLowerCase()))
                                stateAbbr = stabbr.get(state.toLowerCase());
                        }
                }
        }

        // --- Get initial values from custom settings
        public void getInitValues() {
                List<init_vals__c> livals = init_vals__c.getAll().values();
                Integer idx = 0; Date cdate = Date.today();
                if (livals != null) {
                        for (integer i = 0; i < livals.size(); i++) {
                                if (livals[i] != null
                                    && livals[i].start_date__c < cdate
                                    && livals[i].start_date__c > livals[idx].start_date__c) {
                                        idx = i;
                                }
                        }
                        if (livals[idx].Cost_per_W_DC__c != null)
                                cost = livals[idx].Cost_per_W_DC__c;
                        if (livals[idx].Rebate_for_SDPeriod__c != null)
                                rebate = livals[idx].Rebate_for_SDPeriod__c;
                        if (livals[idx].Period_of_Rebate_Applied_SC_Specific__c != null)
                                rebate_per = integer.valueOf(livals[idx].Period_of_Rebate_Applied_SC_Specific__c);
                        if (livals[idx].Investment_Tax_Credit__c != null)
                                itc = livals[idx].Investment_Tax_Credit__c / 100;
                        if (livals[idx].Principal_SD_Period_upon_ITC_Receipt__c != null)
                                psd_per = integer.valueOf(livals[idx].Principal_SD_Period_upon_ITC_Receipt__c);
                        if (livals[idx].Interest_on_Full_Loan_During_SDPeriod__c != null)
                                int_only = livals[idx].Interest_on_Full_Loan_During_SDPeriod__c;
                }
        }

        // --- get SC Revate to the 'getSCRebate' variable and stateTaxCredit
        public void getStateVariables() {
                // Take params from State Incentives
                State_Incentives__c sinc = State_Incentives__c.getInstance(stateAbbr);
                system.debug(sinc);
                vSCRebate = sinc.Rebate_kW__c * systemSize;
                system.debug('SC Rebate = ' + vSCRebate);
                if (sinc.State_Tax_Credit_in_Year_1__c != null)
                        stateTaxCredit = sinc.State_Tax_Credit_in_Year_1__c;
                else {
                        stateTaxCredit = Math.min(sinc.Cap__c, sinc.State_Tax_Credit_Percent__c * grossSystemPrice);
                }
                system.debug('State Tax Credit = ' + stateTaxCredit);
        }

        // --- calculate Step Down Amount
        public void calcSDAmount() {
                //decimal itc_taxfil;
                //itc_basis = loanAmount - rebate - vSCRebate - financingFee;
                //itc_taxfil = itc_basis * itc;
                //vSDAmount = rebate + itc_taxfil + stateTaxCredit;
                vSDAmount = itc_basis * itc;
                system.debug('Step Down Amount = ' + vSDAmount);
        }

        // --- calculate schedule
        public void calculate_schedule() {
                amRecord rec;
                date dt;
                decimal ipt, ppt, pptf, lpt, loan_balance;
                // ----- initialize starting values
                loan_balance = loanAmount;
                // calculate date for this payment
                dt = opp.Commencement_Date__c;
                dt = dt.addDays(1 - dt.day());

                for (integer i = 0; i < loanTerm_IO; i++) {
                        rec = new amRecord();
                        // Store order numbers of months and years
                        rec.mn = i + 1;
                        rec.yn = (integer) (i / 12 + 1);
                        // Store the calculated month and year
                        rec.cm = dt.month();
                        rec.cy = dt.year();
                        dt = dt.addMonths(1);
                        // calculate interest payments
                        if (i < psd_per) {
                        	ipt = -loan_balance * loanRateM;
                        } else
                        	ipt = roundDC( IPMTwCheckPSD(loanRateM, rec.mn - psd_per, loanTerm, loanAmount), 5);
                        // calculate loan payments
                        if ( i >= psd_per ){
                        	pptf = roundDC( PPMTwCheckPSD( loanRateM, rec.mn - psd_per, loanTerm, loanAmount), 5);
                        }else{
                        	pptf = 0;
                        }
                        // other calculations
                        ppt = pptf;
                        if (rec.mn == psd_per) {
                        	ppt -= vSDAmount; system.debug('PPT at the end of PSD period: ' + ppt);
                        }
                        /*
                        if (rec.mn == rebate_per) {
                                ppt -= vSCRebate; system.debug('PPT with rebate period: ' + ppt);
                        }
                        if (int_only && rec.mn <= psd_per) {
                                ppt -= pptf; system.debug('PPT decreased: ' + ppt);
                        }
                        */
                        system.debug('PPT rounded: ' + ppt);
                        lpt = ppt + ipt;
                        // Store calculated loan payments
                        rec.ip = roundDC(ipt, 2);
                        rec.pp = roundDC(ppt, 2);
                        loan_balance = loan_balance + ppt;
                        rec.lb = roundDC(loan_balance, 2);
                        rec.lp = roundDC(lpt, 2);
                        rec.ct = 1; // Always only one Opportunity
                        amPlan.add(rec);
                        system.debug(rec);
                }
        }
                
                //
                public Decimal IPMTwCheckPSD(decimal rate, integer per, integer nper, decimal pv){
                        Decimal res;
                        if(opp.Principal_Step_Down_Occurs__c){
                                res = IPMT(rate, per, nper, pv - vSDAmount);
                        }else{
                                res = IPMT(rate, per, nper, pv);
                        }
                        return res;
                }

                //
                public Decimal PPMTwCheckPSD(decimal rate, integer per, integer nper, decimal pv){
                        Decimal res;
                        if(opp.Principal_Step_Down_Occurs__c){
                                res = PPMT(rate, per, nper, pv - vSDAmount);
                        }else{
                                res = PPMT(rate, per, nper, pv);
                        }
                        return res;
                }

        // --- function for rounded decimal values
        public decimal roundDC(decimal val, integer digs) {
                decimal res;
                integer decs = 10;
                for (integer i = 1; i < digs; i++) { decs *= 10; }
                res = (val * decs).round(System.RoundingMode.HALF_UP);
                return(res / decs);
        }

        // --- Addition function IPMT and PPMT like Excel function

        public decimal calculate_pvif(decimal rate, integer nper) {
                return(decimal) math.pow(1 + double.valueOf(rate), double.valueOf(nper));
        }
        /*      
          function _calculate_pvif($rate, $nper) {
          return (pow(1 + $rate, $nper));
          }
        */

        public decimal calculate_fvifa(decimal rate, integer nper) {
                if (rate == 0) {
                        return decimal.valueOf(nper);
                }
                return(decimal) ((math.pow(1 + double.valueOf(rate), double.valueOf(nper)) - 1) / rate);
        }
        /*
          function _calculate_fvifa($rate, $nper) {
          if ($rate == 0) {
          return $nper;
          } else {
          return (pow(1 + $rate, $nper) - 1) / $rate;
          }
          }
        */

        public decimal PMT(decimal rate, integer nper, decimal pv) {
                return calculate_pmt(rate, nper, pv);
        }
        /*
          function PMT($rate, $nper, $pv, $fv = 0.0, $type = 0) {
          $pmt = $this->_calculate_pmt($rate, $nper, $pv, $fv, $type);
          return (is_finite($pmt) ? $pmt : null);
          }
        */

        // --- find interest part
        public decimal calculate_interest_part(decimal pv, decimal pmt, decimal rate, integer per) {
                decimal pow_res = (decimal) math.pow(1 + double.valueOf(rate), double.valueOf(per));
                system.debug(' Calculate pow(1 + ' + rate + ', ' + per + ') = ' + pow_res);
                return - (pv * pow_res * rate + pmt * (pow_res - 1));
        }
        /*
          function _calculate_interest_part($pv, $pmt, $rate, $per) {
          return -($pv * pow(1 + $rate, $per) * $rate +
          $pmt * (pow(1 + $rate, $per) - 1));
          }
        */

        public decimal calculate_pmt(decimal rate, integer nper, decimal pv) {
                decimal pvif = calculate_pvif(rate, nper);
                decimal fvifa = calculate_fvifa(rate, nper);
                return((- pv * pvif) / fvifa);
        }
        /*
          function _calculate_pmt($rate, $nper, $pv, $fv, $type) {
          $pvif = $this->_calculate_pvif($rate, $nper);
          $fvifa = $this->_calculate_fvifa($rate, $nper);

          return ((-$pv * $pvif - $fv ) / ((1.0 + $rate * $type) * $fvifa));
          }
        */


        // --- IPMT(????????????; ????????????; ??????????_????????????????; ??????????????_????????????_????????????; [??????????????]; [??????????_??????_????????????])
        public decimal IPMT(decimal rate, integer per, integer nper, decimal pv) {
                system.debug('IPMT >> rate = ' + rate + '; per = ' + per + '; nper = ' + nper + '; pv = ' + pv);
                if ((per < 1) || (per >= (nper + 1))) {
                        return 0;
                }
                decimal pmt = calculate_pmt(rate, nper, pv);
                decimal ipmt = calculate_interest_part(pv, pmt, rate, per - 1);
                system.debug('IPMT >> result = ' + ipmt);
                return ipmt;
        }
        /*
          function IPMT($rate, $per, $nper, $pv, $fv = 0.0, $type = 0) {
          if (($per < 1) || ($per >= ($nper + 1))) {
          return null;
          } else {
          $pmt = $this->_calculate_pmt($rate, $nper, $pv, $fv, $type);
          $ipmt = $this->_calculate_interest_part($pv, $pmt, $rate, $per - 1);
          return (is_finite($ipmt) ? $ipmt : null);
          }
          }
        */

        // -- PPMT(????????????; ????????????; ??????????_????????????????; ??????????????_????????????_????????????; [??????????????]; [??????????_??????_????????????])
        public decimal PPMT(decimal rate, integer per, integer nper, decimal pv) {
                        system.debug('PPMT >> rate = ' + rate + '; per = ' + per + '; nper = ' + nper + '; pv = ' + pv);
                        if ((per < 1) || (per >= (nper + 1))) {
                                return 0;
                        }
                        decimal pmt = calculate_pmt(rate, nper, pv);
                        decimal ipmt = calculate_interest_part(pv, pmt, rate, per - 1);
                        system.debug('PPMT >> result = ' + (pmt - ipmt) + '; AS pmt = ' + pmt + ' - ipmt = ' + ipmt);
                        return(pmt - ipmt);
        }
        /*
          function PPMT($rate, $per, $nper, $pv, $fv = 0.0, $type = 0) {
          if (($per < 1) || ($per >= ($nper + 1))) {
          return null;
          } else {
          $pmt = $this->_calculate_pmt($rate, $nper, $pv, $fv, $type);
          $ipmt = $this->_calculate_interest_part($pv, $pmt, $rate, $per - 1);
          return ((is_finite($pmt) && is_finite($ipmt)) ? $pmt - $ipmt : null);
          }
          }
        */

        // ---------- 
        public boolean saveToOpp(Opportunity opp) {
                String JSONString = JSON.serialize(amPlan);
                opp.amortization_plan__c = JSONString;
                try {
                        update opp;
                        return true;
                } catch(Exception e) {
                        system.debug(e);
                }
                return false;
        }

        // ---------- 
        public boolean loadFromOpp(Opportunity opp) {
                String JSONString = opp.amortization_plan__c;
                try {
                        amPlan = (List<amRecord>) JSON.deserialize(JSONString, List<amRecord>.class);
                        return true;
                } catch(Exception e) {
                        system.debug(e);
                }
                return false;
        }

        // ---------- 
        public Opportunity loadOppById(ID oppID) {
                Opportunity opp;
                if (oppID == null) return null;
                try {
                        opp = [SELECT id, amortization_plan__c, State__c, State_ab__c, Commencement_Date__c,
                               System_Size__c, Number_of_Periods_Months__c, Loan_Rate__c, Financing_Fee__c,
                               Principal_Step_Down_Occurs__c, Loan_Amount_Financed__c, Loan_Principle__c
                               FROM Opportunity
                               WHERE id = :oppID limit 1];
                } catch(Exception e) {
                        system.debug(e);
                }
                return opp;
        }

        // ========== functions for use from trigger
        // ----- Generate Amortization Schedule and
        // ----- store in special Opportunity field
        global void storeAmPlanFromTriggerExample(Opportunity opp) {
                // ----- generate schedule into amPlan list of object amRecord
                generateAmPlan(opp);
                // ----- serialize amPlan list to JSON string
                String JSONString = JSON.serialize(amPlan);
                // ----- store JSON string to Opportunity field
                opp.amortization_plan__c = JSONString;
        }

        // ----- compare two maps of JSONs strings
        // -----  and make map for change records
        // ----- of Consolidated_Loan_Info__c object 
	global void changeAmPlanInConsolidateObject(Map<ID, String> amo, Map<ID, String> amn) {
		// --- input params are two maps Map<ID, String> where:
		// ----- ID     - id of Opportunity
		// ----- String - JSON string of amortization schedule (list of object)

		// --- initialize variables
		List<amRecord> lamr_old = new List<amRecord> (); // Old plan (list of object)
		List<amRecord> lamr_new = new List<amRecord> (); // New plan (list of object)
		Integer so, sn; // Counts of elements of old and new lamr-lists
		String JSo, JSn; // Strings for JSON old and new and for name of records
		amRecord amro; // Single record = object of old schedule
		amRecord amrn; // Single record = object of new schedule
		set<ID> opp_set = new set<ID> (); // Set for Opportunitt IDs
		// --- Main logic
		// ----- Take any map - count of elements (opportunities) is equal
		for (ID idx : amn.keySet()) {
			system.debug('Take index ' + idx + ' of ' + amn.size() + ' of input Map<ID, String> amn');
			// ----- take a JSON string from old and new snapshot of Opportunity
			JSo = amo.get(idx);
			JSn = amn.get(idx);
			// ----- check for empty old string: if insert opp or first request for plan
			if (JSo != null && JSo != '') {
				// ----- delete old data from JSON
				lamr_old = (List<amRecord>) JSON.deserialize(JSo, List<amRecord>.class);
				changeLocalMap(lamr_old, - 1);
			} // if(JSo
			if (JSn != null && JSn != '') {
				// ----- Insert new data to JSON
				lamr_new = (List<amRecord>) JSON.deserialize(JSn, List<amRecord>.class);
				changeLocalMap(lamr_new, 1);
			} // if(JSn
		} // for

		// ----- Get records from consolidate object and modify it
		if (mamr.size() > 0) {
			List<Consolidated_Loan_Info__c> clilst =
				[SELECT c.id, c.name, c.Year__c, c.Month__c,
						c.Interest_Payment__c, c.Principal_Payment__c, c.Loan_Balance__c, c.Loan_Payment__c,
						c.Opp_IDs__c, c.N_of_Opps__c
				 FROM Consolidated_Loan_Info__c c
				 WHERE c.name in : mamr.keySet()];
			if (clilst != null && clilst.size() > 0) {
				for (Consolidated_Loan_Info__c cli : clilst) {
					system.debug('Found record: ' + cli);
					amrn = mamr.remove(cli.name);
					system.debug(' -- add data: ' + amrn);
					cli.Interest_Payment__c += amrn.ip;
					cli.Principal_Payment__c += amrn.pp;
					cli.Loan_Balance__c += amrn.lb;
					cli.Loan_Payment__c += amrn.lp;
					// ----- use set for dedublicate IDs
					//opp_set.clear();
					//opp_set = (set<ID>)JSON.deserialize(JSn, set<ID>.class);
					//opp_set.add(oppID);
					// ----- store count of opportunities and IDs of them
					cli.N_of_Opps__c += amrn.ct; // opp_set.size();
					//cli.Opp_IDs__c = JSON.serialize(opp_set);
					system.debug('Result record: ' + cli);
				}
			}
			if (mamr.size() > 0) {
				for (String key : mamr.keySet()) {
					amrn = mamr.get(key);
					system.debug('Add new record: ' + amrn);
					clilst.add(new Consolidated_Loan_Info__c(name = key, Year__c = String.valueOf(amrn.cy), Month__c = String.valueOf(amrn.cm),
										Interest_Payment__c = amrn.ip, Principal_Payment__c = amrn.pp,
										Loan_Balance__c = amrn.lb, Loan_Payment__c = amrn.lp,
										N_of_Opps__c = amrn.ct)); //, Opp_IDs__c = JSON.serialize(new set<ID>{oppID})
				}
			} // if
			try {
				upsert(clilst);
			} catch(Exception e) {
				system.debug(e);
			}
		} // if global
	}

	public void changeLocalMap(List<amRecord> lamr, Integer sign) {
		system.debug('=== Enter to changeLocalMap with: ' + lamr);
		amRecord amro; // Single record = object of old schedule
		amRecord amrn; // Single record = object of new schedule
		String recName;
		// ----- Add/modify record in local map
		for (integer i = 0; i < lamr.size(); i++) {
			amrn = lamr.get(i);
			recName = String.valueOf(amrn.cy) + '-' + ('0' + String.valueOf(amrn.cm)).right(2);
			if (mamr.containsKey(recName)) {
				amro = mamr.get(recName);
				amro.ip += amrn.ip * sign;
				amro.pp += amrn.pp * sign;
				amro.lb += amrn.lb * sign;
				amro.lp += amrn.lp * sign;
				amro.ct += sign;
			} else {
				if (sign == - 1) {
					amrn.ip = - amrn.ip;
					amrn.pp = - amrn.pp;
					amrn.lb = - amrn.lb;
					amrn.lp = - amrn.lp;
					amrn.ct = - 1;
				}
				mamr.put(recName, amrn);
			}
			system.debug(mamr);
		}
	}

}