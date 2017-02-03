/* Class:       LoanPaymentJSON
 * Created On:  12/19/2016
 * Created by:  OpFocus Team
 * Description: Represents a single Loan Payment record
 *		in JSON. This class is used to deserialie the
 *		JSON payload into multiple instances.
 */
public class LoanPaymentJSON {

	public Integer yn {get; set;}
	public Decimal pp {get; set;} // principal payment
	public Integer mn {get; set;}
	public Decimal lp {get; set;} // loan payment
	public Decimal lb {get; set;}// loan balance
	public Decimal ip {get; set;} // interest payment
	public Integer cy {get; set;} // year
	public Integer ct {get; set;} // day
	public Integer cm {get; set;} // month

	public LoanPaymentJSON() {}
}