@isTest
private class mapPCRTestClass {

Static testMethod void mapPCRTest(){

Load_U__c newLZU = new Load_U__c (  name = '02052', 
                                    Load_zone__c= 'NEMA Eversource', 
                                    LZ__c = 'NEMA', 
                                    Utility__C = 'Eversource', 
                                    town__c= 'Medfield');

Insert newLZU;

Product2 productVar = new Product2( name = 'BlueWave Solar Loan - MA',
                                    State__c = 'MA',
                                    Family = 'Solar Loan',
                                    IsActive = TRUE,
                                    ProductCode = 'x',
                                    Loan_Term__c = 120,
                                    Loan_Interest_Rate__c = .0599,
                                    Loan_Interest_Only_Period__c = 12,
                                    Loan_Base_Rate__c = .0625,
                                    Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                    Loan_Financing_Fee_Terms__c ='Maximum (5%, $1,250)');
insert productVar;                                      
                             
lead newLead = new lead(LastName = 'Swain',
                        FirstName = 'Cole',
                        Automatic_Product_Assignment__c = false,
                        Email = 'test@email.com',
                        Product_Line__c = 'Residential Loan',
                        Company = 'Cloud Jedi',
                        Status = 'Pending Information',
                        Annual_Income_Currency__c = 50000,
                        Loan_Amount__c = 45000,
                        Product__c = productVar.Id,
                        DOER_Solar_Loan__c = TRUE,
                        Pre_Approval_Form__c = TRUE) ;

insert newLead;
newLead.Status = 'Qualified';
update newLead;

LASERCA__Personal_Credit_Report__c newPCR = new LASERCA__Personal_Credit_Report__c (name = 'TestCase' , 
                                                                                    LASERCA__Total_High_Credit__c = 50000, 
                                                                                    LASERCA__Credit_Score__c= '715', 
                                                                                    LASERCA__Credit_Score_TransUnion__c = '715',
                                                                                    LASERCA__Lead__c = newLead.id);
Insert newPCR;

LASERCA__Trade_Accounts__c  tradeacct = new LASERCA__Trade_Accounts__c ( LASERCA__Personal_Credit_Report__c = newPCR.id,
                                                                         LASERCA__Monthly_Payment__c = 500);
                                                                                         
insert tradeacct;  
update tradeacct;   

test.startTest();
integer j;
List <Lead> updatedlead = [ SELECT id, Personal_Credit_Report__c 
                            FROM Lead
                            WHERE lastName = 'Swain'];

for(j = 0; j < updatedlead.size(); j++){
system.debug(updatedlead.get(j).Personal_Credit_Report__c);
system.assert(updatedlead.get(j).Personal_Credit_Report__c == newPCR.id);
}

test.stopTest();

}
}