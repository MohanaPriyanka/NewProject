@isTest
private class createGLOppTest{

Static testMethod void addReservedCapacity(){

Date myDate = Date.newInstance(2015, 2, 17);
Date myDate2 = Date.newInstance(2015, 4, 17);

Opportunity newOpportunity = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='New',
    DOER_Solar_Loan__c = TRUE,
    IRBD_Interest_Only_Date_Received__c = myDate,
    IRBD_Principal_Interest_Date_Received__c = null,
    Disbursal_1_Contract_Signature_Checkbox__c = myDate,
    Disbursal_3_Full_Install_Checkbox__c = myDate); 

insert newOpportunity;
newOpportunity.IRBD_Interest_Only_Date_Received__c = myDate2;
newOpportunity.Disbursal_1_Contract_Signature_Checkbox__c = myDate2;
newOpportunity.Disbursal_3_Full_Install_Checkbox__c = myDate2;
Update newOpportunity;

Opportunity newOpportunity2 = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='New',
    DOER_Solar_Loan__c = TRUE,
    IRBD_Interest_Only_Date_Received__c = myDate,
    IRBD_Principal_Interest_Date_Received__c = myDate,
    Disbursal_2_Mechanical_Install_Checkbox__c = myDate); 

insert newOpportunity2;
newOpportunity2.IRBD_Principal_Interest_Date_Received__c = myDate2;
newOpportunity.Disbursal_2_Mechanical_Install_Checkbox__c = myDate2;
Update newOpportunity2;
 


 
 
}
}