public class createGL{

public static void GeneralLedgerIRBDIOAvidia (opportunity[] opp) {

   for (opportunity o : opp){
   
           Date today = date.today(); 
       
           general_ledger__c GL = new general_ledger__c(
            
                name = 'IRBD - IO' + ' ' + o.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'IRBD - IO',
                Description__c = 'IRBD - Interest Only',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1120016',
                Avidia_cost_center__c = '61',
                Code__c = '828',
                DDA__c = '34148718',
                Amount__c = o.IRBD_Interest_Only__c,
                opportunity__c = o.id );
                
                      insert GL;}}
           
public static void GeneralLedgerIRBDPIAvidia (opportunity[] opp) {

   for (opportunity o :opp){
           Date today = date.today();
           general_ledger__c GL = new general_ledger__c(
            
                name = 'IRBD - PI' + ' ' + o.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'IRBD - PI',
                Description__c = 'IRBD - Principal & Interest',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1120016',
                Avidia_cost_center__c = '61',
                Code__c = '828',
                DDA__c = '34148718',
                Amount__c = o.IRBD_Principal_Interest__c,
                opportunity__c = o.id );
                
                       insert GL;}}

public static void GeneralLedgerInterestPayment (loan_payment__c[] PMTS) {

   for (loan_payment__c LP : PMTS){
           Date today = date.today();
           general_ledger__c GL = new general_ledger__c(
            
                name = 'Loan Payment - Interest' + ' ' + LP.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'Loan Payment - Interest',
                Description__c = 'Interest Payment',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1300016',
                Avidia_cost_center__c = '61',
                Code__c = '828',
                DDA__c = '34148718',
                Amount__c = LP.interest_payment__c,
                loan_payment__c = LP.id,
                opportunity__c = LP.opportunity_id__c );
                
                       insert GL;}}
                       
public static void GeneralLedgerPrincipalPayment (loan_payment__c[] PMTS) {

   for (loan_payment__c LP : PMTS){
           Date today = date.today();  
           general_ledger__c GL = new general_ledger__c(
            
                name = 'Loan Payment - Principal' + ' ' + LP.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'Loan Payment - Principal',
                Description__c = 'Principal Payment',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1300016',
                Avidia_cost_center__c = '61',
                Code__c = '828',
                DDA__c = '34148718',
                Amount__c = LP.principal_payment__c,
                loan_payment__c = LP.id,
                opportunity__c = LP.opportunity_id__c );
                
                       insert GL;}}
                       
public static void GeneralLedgerContractDisbursal (opportunity [] opp) {

   for (opportunity o : opp){
           Date today = date.today();
           general_ledger__c GL = new general_ledger__c(
            
                name = 'Disbursal - Contract' + ' ' + o.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'Disbursal - Contract',
                Description__c = 'Disbursal',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1120016',
                Avidia_cost_center__c = '61',
                Code__c = '629',
                DDA__c = '34148718',
                Amount__c = o.Disbursal_1_Contract_Signature__c,
                opportunity__c = o.id);
                
                       insert GL;}}                                                                      

public static void GeneralLedgerMechanicalDisbursal (opportunity [] OPP) {

   for (opportunity o : OPP){
           Date today = date.today();
           general_ledger__c GL = new general_ledger__c(
            
                name = 'Disbursal - Mechanical' + ' ' + o.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'Disbursal - Mechanical',
                Description__c = 'Disbursal',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1120016',
                Avidia_cost_center__c = '61',
                Code__c = '629',
                DDA__c = '34148718',
                Amount__c = o.Disbursal_2_Mechanical_Installation__c,
                opportunity__c = o.id );
                
                       insert GL;}}
                       
public static void GeneralLedgerInterconnectionDisbursal (opportunity [] OPP) {

   for (opportunity o : OPP){
           Date today = date.today(); 
           general_ledger__c GL = new general_ledger__c(
            
                name = 'Disbursal - Interconnection' + ' ' + o.name + ' ' + today.month() + ' ' + today.year(),
                type__c = 'Disbursal - Interconnection',
                Description__c = 'Disbursal',
                Date_of_transaction__c = date.today(),
                Avidia_GL_Account__c = '1120016',
                Avidia_cost_center__c = '61',
                Code__c = '629',
                DDA__c = '34148718',
                Amount__c = o.Disbursal_3_Full_Install__c,
                opportunity__c = o.id );
                
                       insert GL;}}                                                                                                
                                              
                       
                       }