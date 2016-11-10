trigger createGLOpp on Opportunity (after update){ // trigger after insert

    opportunity[] opp = trigger.new;
    
    for(opportunity o : trigger.new){

    if(o.DOER_Solar_Loan__c == TRUE && trigger.IsUpdate && 
        o.IRBD_Interest_Only_Date_Received__c != null && 
        o.IRBD_Principal_Interest_Date_Received__c == null && 
        trigger.oldMap.get(o.id).IRBD_Interest_Only_Date_Received__c != o.IRBD_Interest_Only_Date_Received__c
 ){
    
        createGL.GeneralLedgerIRBDIOAvidia(opp);}  
   
    if(o.DOER_Solar_Loan__c == TRUE && trigger.IsUpdate &&
        o.IRBD_Interest_Only_Date_Received__c != null && 
        o.IRBD_Principal_Interest_Date_Received__c != null && 
        trigger.oldMap.get(o.id).IRBD_Principal_Interest_Date_Received__c != o.IRBD_Principal_Interest_Date_Received__c  ){
   
        createGL.GeneralLedgerIRBDPIAvidia(opp);}

    if(trigger.IsUpdate &&
        o.Disbursal_1_Contract_Signature_Checkbox__c != null && 
        trigger.oldMap.get(o.id).Disbursal_1_Contract_Signature_Checkbox__c != o.Disbursal_1_Contract_Signature_Checkbox__c ){
        
        createGL.GeneralLedgerContractDisbursal(opp);}

    if(trigger.IsUpdate &&
        o.Disbursal_2_Mechanical_Install_Checkbox__c != null && 
        trigger.oldMap.get(o.id).Disbursal_2_Mechanical_Install_Checkbox__c != o.Disbursal_2_Mechanical_Install_Checkbox__c){
          
        createGL.GeneralLedgerMechanicalDisbursal(opp);} 
        
    if(trigger.IsUpdate &&
        o.Disbursal_3_Full_Install_Checkbox__c != null &&
        trigger.oldMap.get(o.id).Disbursal_3_Full_Install_Checkbox__c != o.Disbursal_3_Full_Install_Checkbox__c){
        
        createGL.GeneralLedgerInterconnectionDisbursal(opp);}                 
              
               
    else{ return;}}}