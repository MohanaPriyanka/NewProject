/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Implementation of the financial functions pmt, fv, ppmt, ipmt.
 *              Derived from Apache POI
 * https://apache.googlesource.com/poi/+/trunk/src/java/org/apache/poi/ss/formula/functions/Finance.java
 * Test: LoanServicerTest and ExcelTest
 *************************************************************************************/

public with sharing class Excel {
    /**
     * Emulates Excel/Calc's PMT(interest_rate, number_payments, PV, FV, Type)
     * function, which calculates the payments for a loan or the future value of an investment
     * 
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>double</code> representing periodic payment amount.
     */
    // http://arachnoid.com/lutusp/finance.html
    static public Double pmt(Double r, Integer nper, Double pv, Double fv, Integer type) {
        Double pmt = -r * (pv * Math.pow(1 + r, nper) + fv) / ((1 + r*type) * (Math.pow(1 + r, nper) - 1));
        return pmt;
    }
    /**
     * Overloaded pmt() call omitting type, which defaults to 0.
     * 
     * @see #pmt(double, int, double, double, int)
     */
    static public Double pmt(Double r, Integer nper, Double pv, Double fv) {
        return pmt(r, nper, pv, fv, 0);
    }
	
    /**
     * Overloaded pmt() call omitting fv and type, which both default to 0.
     * 
     * @see #pmt(double, int, double, double, int)
     */
    static public Double pmt(Double r, Integer nper, Double pv) {
        return pmt(r, nper, pv, 0);
    }
	
	
    /**
     * Emulates Excel/Calc's IPMT(interest_rate, period, number_payments, PV,
     * FV, Type) function, which calculates the portion of the payment at a
     * given period that is the interest on previous balance.
     * 
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param per
     *            - period (payment number) to check value at.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>double</code> representing interest portion of payment.
     * 
     * @see #pmt(double, int, double, double, int)
     * @see #fv(double, int, double, double, int)
     */
    // http://doc.optadata.com/en/dokumentation/application/expression/functions/financial.html
    static public Double ipmt(Double r, Integer per, Integer nper, Double pv, Double fv, Integer type) {
        Double ipmt = fv(r, per - 1, pmt(r, nper, pv, fv, type), pv, type) * r;
        if (type==1) ipmt /= (1 + r);
        return ipmt;
    }
	
    static public Double ipmt(Double r, Integer per, Integer nper, Double pv, Double fv) {
        return ipmt(r, per, nper, pv, fv, 0);
    }
	
    static public Double ipmt(Double r, Integer per, Integer nper, Double pv) {
        return ipmt(r, per, nper, pv, 0);
    }

    /**
     * Emulates Excel/Calc's PPMT(interest_rate, period, number_payments, PV,
     * FV, Type) function, which calculates the portion of the payment at a
     * given period that will apply to principal.
     * 
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param per
     *            - period (payment number) to check value at.
     * @param nper
     *            - number of total payments / periods.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param fv
     *            - future value of loan or annuity.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>double</code> representing principal portion of payment.
     * 
     * @see #pmt(double, int, double, double, int)
     * @see #ipmt(double, int, int, double, double, int)
     */
    static public Double ppmt(Double r, Integer per, Integer nper, Double pv, Double fv, Integer type) {
        return pmt(r, nper, pv, fv, type) - ipmt(r, per, nper, pv, fv, type);
    }
	
    static public Double ppmt(Double r, Integer per, Integer nper, Double pv, Double fv) {
        return pmt(r, nper, pv, fv) - ipmt(r, per, nper, pv, fv);
    }
	
    static public Double ppmt(Double r, Integer per, Integer nper, Double pv) {
        return pmt(r, nper, pv) - ipmt(r, per, nper, pv);
    }

    /**
     * Emulates Excel/Calc's FV(interest_rate, number_payments, payment, PV,
     * Type) function, which calculates future value or principal at period N.
     * 
     * @param r
     *            - periodic interest rate represented as a decimal.
     * @param nper
     *            - number of total payments / periods.
     * @param pmt
     *            - periodic payment amount.
     * @param pv
     *            - present value -- borrowed or invested principal.
     * @param type
     *            - when payment is made: beginning of period is 1; end, 0.
     * @return <code>double</code> representing future principal value.
     */
    //http://en.wikipedia.org/wiki/Future_value
    static public Double fv(Double r, Integer nper, Double pmt, Double pv, Integer type) {
        Double fv = -(pv * Math.pow(1 + r, nper) + pmt * (1+r*type) * (Math.pow(1 + r, nper) - 1) / r);
        return fv;
    }

    /**
     * Calculates Internal Rate of Return for a list of irregular cashflows.
     * Uses Newton's method to approximate solution to a target error level.
     *
     * Usage:
     *     XIRR myXIRR = new XIRR();
     *     myXIRR.addCashflow(Date.newInstance(2012, 1, 1), 1500.0);
     *     myXIRR.addCashflow(Date.newInstance(2012, 2, 15), -500.0);
     *     myXIRR.addCashflow(Date.newInstance(2012, 3, 7), -1000.0);
     *     try {
     *         System.debug(myXIRR.calculate());
     *     } catch(Util.BWException e) {
     *         ApexPages.addMessage(e);
     *     }
     *
     * @author:      Luke McFarlane
     * @date:        Aug 2012
     * https://github.com/lukemcfarlane/xirr/blob/master/XIRR.cls
     *
     * Feb 2018, PY: Removed Plot functionality since it's not needed yet.
     */

    public static final Integer MAX_ITERATIONS = 1000;
    public static final Decimal TARGET_ERROR = 0.0000001;
    public with sharing class XIRR {
        public List<Cashflow> cashflows   { get; set; }

        /**
         * Construct a new XIRR instance with an empty list of cashflows.
         */
        public XIRR() {
            this.cashflows = new List<Cashflow>();
        }

        /**
         * Given a date & amount, add a new cashflow to the list of cashflows.
         * @param cashflowDate Date of the cashflow
         * @param amount       Amount as decimal. Can be negative or positive.
         */
        public void addCashflow(Date cashflowDate, Decimal amount) {
            addCashflow(new Cashflow(cashflowDate, amount));

        }

        /**
         * Add a cashflow to the list of cashflows.
         * @param c Cashflow to add
         */
        public void addCashflow(Cashflow c) {
            if(c.cashflowDate == null) throw new Util.BWException('Attempted to add a cashflow that doesn\'t have a date');
            if(c.amount == null) throw new Util.BWException('Attempted to add a cashflow that doesn\'t have an amount');
            this.cashflows.add(c);
        }

        /**
         * Performs a validation check on list of cashflows to ensure that they meet the criteria for calculating an
         * XIRR solution. If validation fails, throw an exception with list of failure reasons.
         */
        public void performValidation() {
            List<String> failureReasons = new List<String>();
            if(this.cashflows != null) {
                // There should be at least one positive and one negative cashflow
                Boolean hasPositive = false;
                Boolean hasNegative = false;
                for(Cashflow c : this.cashflows) {
                    if(c.amount > 0.0) hasPositive = true;
                    else if(c.amount < 0.0) hasNegative = true;
                }
                if(!(hasPositive && hasNegative)) {
                    failureReasons.add('At least one positive cash flow and one negative cash flow are required');
                }
            }

            if(failureReasons.size() > 0) {
                String exceptionMsg = String.join(failureReasons, ', ');
                throw new Util.BWException(exceptionMsg);
            }
        }

        /**
         * Approximate IRR for an simple interest APR calc by deannualizing XIRR and then annualizing
         */
        public Decimal estimateIRR(Decimal initialGuess) {
            Decimal xirr = calculate(initialGuess);
            Decimal deannualizedXIRR = (Decimal) System.Math.pow((Double) (1+xirr), (Double) (1.0/12))-1;
            Decimal reannualizedXIRR = 12*deannualizedXIRR;
            return reannualizedXIRR*100;
        }

        /**
         * Given an initial guess, use newton's iterative method to approximate solution.
         * @param  initialGuess A decimal value between 0 & 1. Value doesn't usually make a difference to calculation, but some value is required.
         * @return              The approximated solution.
         */
        public Decimal calculate(Decimal initialGuess) {
            performValidation(); // this will throw an exception if validation fails

            Decimal current = initialGuess;
            Decimal next = 0.0;
            Decimal prevDiff = 0.0;
            Decimal diff = 100.0;

            for(Integer i = 0; diff > TARGET_ERROR; i++) {
                if(i == MAX_ITERATIONS) {
                    throw new Util.BWException('Unable to find solution (maximum number of iterations reached)');
                }
                if(current < -1.0) {
                    throw new Util.BWException('Unable to find solution (next guess cannot be less than -1.0)');
                }
                Decimal f = calc_summed_f(current);
                Decimal df = calc_summed_df(current);
                next = current - (f/df);
                prevDiff = diff;
                diff = System.Math.abs(next - current);
                current = next;
            }

            return current;
        }

        /**
         * Perform calculation with a default initial guess value.
         * @return The approximated solution.
         */
        public Decimal calculate() {
            return calculate(0.1);
        }

        /**
         * Given a rate r, evaluate and return f(r):
         * @param  r The rate, a decimal between 0.0 & 1.0
         * @return   The result of evaluating f(r).
         */
        public Decimal calc_summed_f(Decimal r) {
            Decimal result = 0.0;
            Date d1 = cashflows[0].cashflowDate;
            for(Integer i = 0; i < cashflows.size(); i++) {
                Cashflow pi = cashflows[i];
                if(pi.amount == null) throw new Util.BWException('Found a cashflow with amount null');
                Decimal daysBetween = d1.daysBetween(pi.cashflowDate);
                Decimal base = 1.0+r;
                Decimal exp = daysBetween/365.0;
                Integer expInt = exp.intValue();
                /**
                 *         n          P(i)
                 * f(r) = SUM  -------------------
                 *        i=0   r^((di - d0)/365)
                 */
                result += pi.amount/System.Math.pow((Double)(1.0+r), (Double)(daysBetween/365.0));
            }
            return result;
        }

        /**
         * Given a rate r, evaluate and return f'(r) (the derivative of f(r)):
         * @param  r The rate, a decimal between 0.0 & 1.0
         * @return   The result of evaluating f'(r)
         */
        public Decimal calc_summed_df(Decimal r) {
            Decimal result = 0.0;
            Date d1 = cashflows[0].cashflowDate;
            for(Integer i = 0; i < cashflows.size(); i++) {
                Cashflow pi = cashflows[i];
                Decimal daysBetween = d1.daysBetween(pi.cashflowDate);
                /**
                 *          n      1                             ((di - d0)/365) - 1
                 * f'(r) = SUM   ---- (di - d0) * P(i) * (1 + r)
                 *         i=0    65
                 *
                 */
                result += (1.0/365.0) * daysBetween * pi.amount * System.Math.pow((Double)(1.0+r), (Double)((daysBetween/365.0) - 1.0));
            }
            return -result;
        }
    }

    /**
     * A cashflow consists of a date & decimal amount value, and can be sorted.
     */
    public class Cashflow implements Comparable {

        public Date cashflowDate { get; set; }
        public Decimal amount { get; set; }

        /**
         * Create a new cashflow instance given a date and amount.
         * @param  d Date
         * @param  a Amount as a decimal
         */
        public Cashflow(Date d, Decimal a) {
            cashflowDate = d;
            amount = a;
        }

        /**
         * Implement the compareTo method
         * @param  compareTo The cashflow to compare to
         * @return           -1, 0, or 1 depending on whether the date of cashflow comparing to is before, the same, or after this cashflow date (respectively).
         */
        public Integer compareTo(Object compareTo) {
            Cashflow compareToEmp = (Cashflow)compareTo;
            if (cashflowDate == compareToEmp.cashflowDate) return 0;
            if (cashflowDate > compareToEmp.cashflowDate) return 1;
            return -1;
        }
    }
}