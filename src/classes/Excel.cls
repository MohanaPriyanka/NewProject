/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Implementation of the financial functions pmt, fv, ppmt, ipmt.
 *              Derived from Apache POI
 * https://apache.googlesource.com/poi/+/trunk/src/java/org/apache/poi/ss/formula/functions/Finance.java
 * Test: LoanServicerTest
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

    static public Decimal ipmtRounded(Double r, Integer per, Integer nper, Double pv) {
        Decimal d = (Decimal) ipmt(r, per, nper, pv, 0);
        return d.setScale(2, RoundingMode.HALF_UP);
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

    static public Decimal ppmtRounded(Double r, Integer per, Integer nper, Double pv) {
        Decimal d = (Decimal) pmt(r, nper, pv) - ipmt(r, per, nper, pv);
        return d.setScale(2, RoundingMode.HALF_UP);
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
     * Overloaded fv() call omitting type, which defaults to 0.
     * 
     * @see #fv(double, int, double, double, int)
     */
    static public Double fv(Double r, Integer nper, Double c, Double pv) {
        return fv(r, nper, c, pv, 0);
    }
}