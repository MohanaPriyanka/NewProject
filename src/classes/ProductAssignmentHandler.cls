public with sharing class ProductAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public ProductAssignmentHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    /*public void OnBeforeLeadInsert(Lead[] newLeads){
        assignLoanProductToLead(newLeads);
        system.debug('The newLeads list: ' + newLeads);
    }*/
    public void onBeforeUpdate(List<Lead> newLeads, Map<ID, Lead> oldLeadsMap){
        System.debug('lead Trigger Check');
        assignLoanProductToLead(newLeads, oldLeadsMap);       
    }
    public void onBeforePCRUpdate(List<LASERCA__Personal_Credit_Report__c> newLeads){
        System.debug('OnBeforePCRUpdate Check');
        assignLoanProductToLeadViaPCR(newLeads);
    }    
    
    public List<Product2> getProductRecords(){
       List<Product2> productList = new List<Product2>();                                   
        //query for all of the products that are active | NOTE: will need to add queried fields as new product variations come into the system. Look for a way to return all fields.
        for(Product2 productRecord : [SELECT Id, Name, Program__c,IsActive, Loan_Financing_Fee_Terms__c, Loan_Term__c, Product_Type__c, State__c, Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c
                                        FROM Product2 
                                        WHERE isActive = TRUE]){
            productList.add(productRecord);
        }
        system.debug(productList);
        return productList;        
    }
 
    //assigns the appropriate product record to the triggered leads.
    public void assignLoanProductToLead(List<Lead> leadList, Map<ID, Lead> oldLeadsMap){
       List<Product2> productList = new List<Product2>(getProductRecords());
        for(Lead leadRecord : leadList){
            if(leadRecord.Automatic_Product_Assignment__c == true 
                && leadRecord.Product_Line__c == 'Residential Loan' 
                //&& (leadRecord.Status == 'Qualified' || leadRecord.Pre_Approval_form__c == true ) 
                && leadRecord.Loan_Term__c != null 
                && oldLeadsMap.get(leadRecord.Id).Status != 'Qualified'){
                    system.debug('checkResi/qual/term/status');
                    //run through all of the products per lead to find the specific product suitable for this customer.
                    if(productList.size() > 0){
                        system.debug('checkSize');
                        for(Product2 productRecord : productList){
                            //****Product Line could have issues as all leads, opps, etc. are set as Residential Loan and the Product is going to be Solar Loan. Also, home state is returned after credit.
                            if(productRecord.IsActive == true 
                                && productRecord.Product_Type__c == leadRecord.Product_Line__c 
                                && productRecord.Program__c == leadRecord.Product_Program__c 
                                && productRecord.Loan_Term__c == leadRecord.Loan_term__c 
                                && productRecord.State__c == leadRecord.LASERCA__Home_State__c ){
                                if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){
                                    system.debug('check2');
                                    //assign the product to the lead
                                    if(leadRecord.DOER_Solar_Loan__c == true && productRecord.Program__c == 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c;
                                            leadRecord.Loan_Financing_Fee__c = null;                                        
                                        }
                                    }
                                    if (leadRecord.DOER_Solar_Loan__c == false && productRecord.Program__c != 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;        
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c;
                                            leadRecord.Loan_Financing_Fee__c = null;
                                        }                                                                   
                                    }                                                                                                             
                                }
                            else{
                                continue;
                            }
                        }                    
                    }
                }
            }   
        } 
    }
    /*the following class is needed in order to follow sequencing with the Pre-Qualification process. 
    Interest rate is needed to calculate the monthly payment, which is needed to pre-qualify the customer. 
    the assignment at the lead level required an additional update. 
    This howver allows for the trade accounts to be factored in after the product has been assigned.*/
    public void assignLoanProductToLeadViaPCR(List<LASERCA__Personal_Credit_Report__c> pcrList){
       List<String> pcrLeadIdList = new List<String>();
       System.debug('pcrList check' + pcrList);
       for (LASERCA__Personal_Credit_Report__c pcrRecord : pcrList){
            pcrLeadIdList.add(pcrRecord.PCR_Lead_ID__c);
       }
       List<Lead> leadList = [SELECT Id, DOER_Solar_Loan__c, Product_Program__c, Name, Status, Product_Line__c, Product__c, Automatic_Product_Assignment__c,
                                    Loan_Term__c, LASERCA__Home_State__c, LASER_Credit_Score__c, Loan_Financing_Fee__c, 
                                    Pre_Approval_form__c, System_Cost__c, Product__r.Name
                                FROM Lead
                                WHERE Id IN : pcrLeadIdList
                                AND isConverted = false];

       List<Product2> productList = new List<Product2>(getProductRecords());
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan' && 
             leadRecord.Loan_Term__c != null){
                system.debug('checkResi/qual/term/status');
                //run through all of the products per lead to find the specific product suitable for this customer.
                if(productList.size() > 0){
                    system.debug('checkSize');
                    for(Product2 productRecord : productList){
                        //****Product Line could have issues as all leads, opps, etc. are set as Residential Loan and the Product is going to be Solar Loan. Also, home state is returned after credit.                      
                        if(leadRecord.Automatic_Product_Assignment__c == true && 
                            productRecord.Program__c == leadRecord.Product_Program__c &&
                            productRecord.Product_Type__c == leadRecord.Product_Line__c &&
                            productRecord.Loan_Term__c == leadRecord.Loan_term__c && 
                            productRecord.State__c == leadRecord.LASERCA__Home_State__c ){
                                if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && 
                                    leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){
                                    system.debug('check2');
                                    //assign the product to the lead
                                   if(leadRecord.DOER_Solar_Loan__c == true && productRecord.Program__c == 'MSLP'){
                                    leadRecord.Product__c = productRecord.Id;
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c;
                                            leadRecord.Loan_Financing_Fee__c = null;                                        
                                        }
                                    }
                                    if (leadRecord.DOER_Solar_Loan__c == false && productRecord.Program__c != 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;        
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.System_Cost__c;
                                            leadRecord.Loan_Financing_Fee__c = null;
                                        }                                                                   
                                    }                                                        
                                }
                        //break;                               
                        }
                        else{
                            continue;
                        }
                    }                    
                }
            }
        }
        System.debug(leadList);
        update leadList;       
    }    
} 



/*

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

VERSION 4 | Created using Parameter mapping into the SOQL; however the problem was that it was hitting governor limits. Useful code for future APEX.

   private List<Product2> getLoanProductList(String state, Decimal term, String creditScore, String productType ){
        String query =      'Select Id, Name, Loan_Term__c, '+
                            '           Loan_Financing_Fee_Terms__c '+
                            ' From Product2 ';
        query += 'Where State__c = :state ';
        query += 'AND Product_Type__c = :productType ';        
        query += 'AND Loan_Term__c = :term ';
        query += 'AND Credit_Maximum__c >= :creditScore ';
        query += 'AND Credit_Minimum__c <= :creditScore ';        
        query += 'AND isActive = TRUE ';
        query += 'LIMIT 1';                         

        return Database.query(query);
    }
 
    private void assignLoanProductToLead(List<Lead> leadList, Map<ID, Lead> oldLeadsMap ){
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan' && leadRecord.Status == 'Qualified' && oldLeadsMap.get(leadRecord.Id).Status != 'Qualified' && leadRecord.Loan_Term__c != null){
                system.Debug('Product List Size = ' + getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.Loan_Term__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c).size());
                if(getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.Loan_Term__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c).size() > 0 ){
                    for(Product2 productRecord : getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.Loan_Term__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c)){
                        system.Debug('Product Record ID = ' + productRecord.Id);
                        leadRecord.Product__c = productRecord.Id;
                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                            leadRecord.Loan_Amount__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                            leadRecord.Loan_Financing_Fee__c = null;
                        }                     
                    }
                }
            }
        }
    }
  
  /*  

  ** THE BELOW CODE COULD BE USED TO RETURN A LIST OF QUALIFIED PRODUCTS FOR THIS CUSTOMER TO BE RETURNED AND SELECTED AFTER THE CUSTOMER HAS HAD THEIR CREDIT PULLED.

  private List<Product2> getQualifiedLoanProductList(String state, String creditScore, String productType ){
        String query =      'Select Id, Name, Family, '+
                            '           Loan_Term__c, '+
                            '           Loan_Financing_Fee_Terms__c, '+
                            ' From Product2 ';
        query += 'Where State__c = :state ';
        query += 'AND Product_Type__c = :productType ';        
        query += 'AND Loan_Term__c = :term ';
        query += 'AND Credit_Maximum__c >= :creditScore ';
        query += 'AND Credit_Minimum__c <= :creditScore ';        
        query += 'AND isActive = TRUE ';                       

        return Database.query(query);
    }
    
    private void returnQualifiedLoanProducts (List<Lead> leadList, Map<ID, Lead> oldLeadsMap ){
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan' && leadRecord.Status == 'Qualified' && oldLeadsMap.get(leadRecord.Id).Status != 'Qualified' && leadRecord.Loan_Term__c != null){
                system.Debug('Product List Size = ' + getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.Loan_Term__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c).size());
                if(getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c).size() > 0 ){
                    for(Product2 productRecord : getLoanProductList(leadRecord.LASERCA__Home_State__c, leadRecord.LASER_Credit_Score__c, leadRecord.Product_Line__c)){
                        leadRecord.Product__c = productRecord.Id;
                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                            leadRecord.Loan_Amount__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                            leadRecord.Loan_Financing_Fee__c = null;
                        }                     
                    }
                }
            }
        }
    } */   
 

/****** VERSION 3 | 

created to fit the custom object - Product__c before there was knowledge of the Standard Object - Product2. It was built to fit the needs of the product/tier hierarchy


    //Returns a map with a list of product records filtered by their lowest tier and grouped by their product line.
    private Map<String, Product__c> getAssignmentTierProductRecords(){
        Map<String, Product__c> productTieredMap = new Map<String, Product__c>();
        Map<String, String> maxProductTierMap = new Map<String,String>();
        List<Lead> updateLeadList = new List<Lead>();
        //Identify the lowest tier (Max tier value) of the products where that are active - group them by Product line to have the lowest tier per line.
        aggregateResult[] productTierMax = [SELECT Product_Line__c, max(Product_tier__c)maxTier
                                      FROM Product__c
                                      WHERE Active__c = TRUE 
                                      GROUP BY Product_Line__c];                                     
        //Place all lowest level tiers per product line into a map as these are the only products that should get assigned.
        for(AggregateResult tierMaxVar : productTierMax){
              maxProductTierMap.put((String)tierMaxVar.get('Product_Line__c'), (String)tierMaxVar.get('maxTier'));
            }
        system.Debug('The maxProductTierMap = ' + maxProductTierMap);                                      
        //query for all of the products that are active | NOTE: will need to add queried fields as new product variations come into the system. Look for a way to return all fields.
        for(Product__c productQueryRecord : [SELECT Id, Name, Product_Line__c, Opportunity_Record_Type_ID__c, Loan_Term__c, Loan_Internal_Lender_Rate__c, State__c,
                                        Loan_Interest_Rate__c, Loan_Interest_Only_Period__c, Loan_Base_Rate__c, Lead_Record_Type_ID__c, 
                                        Income_Based_Loan_Support__c, Financing_Fee_Terms__c, Disbursal_Terms__c, Credit_Minimum__c, Credit_Maximum__c, Product_Tier__c
                                        FROM Product__c 
                                        WHERE Active__c = TRUE]){
            //filter through the queried records to load in the lowest tier products into a map relative to their product line.
            if(productQueryRecord.Product_Tier__c == maxProductTierMap.get(productQueryRecord.Product_Line__c)){
                productTieredMap.put(productQueryRecord.Name, productQueryRecord);
            }
        }
        system.Debug('The productTieredMap = ' + productTieredMap);
        return productTieredMap;        
    }
 
    //assigns the appropriate product record to the triggered leads.
    private void assignLoanProductToLead(List<Lead> leadList){
        Map<String, Product__c> productMap = new Map<String, Product__c>(getAssignmentTierProductRecords());
        system.Debug('The productMap = ' + productMap);
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan' && leadRecord.Status == 'Qualified' && leadRecord.Loan_Term__c != null){
                //run through all of the products per lead to find the specific product suitable for this customer.
                for(Product__c productRecord : productMap.values()){
                    //****Product Line could have issues as all leads, opps, etc. are set as Residential Loan and the Product is going to be Solar Loan. Also, home state is returned after credit.
                    if(/*productRecord.Product_Line__c == leadRecord.Product_Line__c && productRecord.Loan_Term__c == leadRecord.Loan_term__c && productRecord.State__c == leadRecord.LASERCA__Home_State__c ){
                        /*if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){
                            //assign the product to the lead
                            leadRecord.Product__c = productRecord.Id;
                            leadRecord.Loan_Interest_Rate__c = productRecord.Loan_Interest_Rate__c;
                            leadRecord.Loan_Term__c = productRecord.Loan_Term__c;
                            leadRecord.Loan_Interest_Only_Period__c = productRecord.Loan_Interest_Only_Period__c;
                            leadRecord.Loan_Financing_Fee_Terms__c = productRecord.Financing_Fee_Terms__c;
                            leadRecord.Loan_Disbursement_Terms__c = productRecord.Disbursal_Terms__c;
                            if(productRecord.Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                                leadRecord.Loan_Amount__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
                            }
                            else if(productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c == 'No Finacing Fee'){
                                leadRecord.Loan_Financing_Fee__c = null;
                            }                                                        
                        }                        
                    }
                    else{
                        continue;
                    }
                }
            }
        }
    }
}      
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/****VERSION 2 |

 81-170 is the code above, with everything done until the product assignment code; however it is not divided into two method. 


    private void assignProductToLead(List<Lead> leadList){
        Map<String, Product__c> productMap = new Map<String, Product__c>();
        Map<String, Integer> maxProductTierMap = new Map<Id,Integer>();
        List<Lead> updateLeadList = new List<Lead>();
        //Identify the lowest tier (Max tier value) of the products where that are active - group them by Product line to have the lowest tier per line.
        aggregateResult[] productTierMax = [SELECT Product_Line__c, max(Product_tier__c)maxTier
                                      FROM Product__c
                                      WHERE Active__c = TRUE 
                                      GROUP BY Product_Line__c];                                     
        //Place all lowest level tiers per product line into a map as these are the only products that should get assigned.
        for(AggregateResult tierMaxVar : productTierMax){
              maxProductTierMap.put((String)tierMaxVar.get('Product_Line__c'), (Integer)tierMaxVar.get('maxTier'));
            }                                      
        //query for all of the products that are active | NOTE: will need to add queried fields as new product variations come into the system. Look for a way to return all fields.
        for(Product__c productQueryRecord : [SELECT Id, Name, Product_Line__c, Opportunity_Record_Type_ID__c, Loan_Term__c, Loan_Internal_Lender_Rate__c,
                                        Loan_Interest_Rate__c, Loan_Interest_Only_Period__c, Loan_Base_Rate__c, Lead_Record_Type_ID__c, 
                                        Income_Based_Loan_Support__c, Financing_Fee_Terms__c, Disbursal_Terms__c, Credit_Minimum__c, Credit_Maximum__c 
                                        FROM Product__c 
                                        WHERE Active__c = TRUE]){
            //filter through the queried records to load in the lowest tier products into a map relative to their product line.
            if(productQueryRecord.Product_Tier__c = maxProductTierMap.get(productQueryRecord.Product_Line__c)){
                productMap.put(productQueryRecord.Name, productQueryRecord);
            }
        }
        //run through the list of triggered leads to assign products.
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan'){
                //run through all of the products per lead to find the specific product suitable for this customer.
                for(Product__c productRecord : productMap.values()){
                    if(productRecord.Product_Line__c == 'Solar Loan'){
                        if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){

                        }                        
                    }
                    else{
                        continue;
                    }
                }
                leadRecord.Product__c = productMap.get(leadRecord.Product_Identifier__c).Id;
                leadRecord.Loan_Interest_Rate__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Interest_Rate__c;
                leadRecord.Loan_Term__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Term__c;
                leadRecord.Loan_Interest_Only_Period__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Interest_Only_Period__c;
                leadRecord.Loan_Financing_Fee_Terms__c = productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c;
                leadRecord.Loan_Disbursement_Terms__c = productMap.get(leadRecord.Product_Identifier__c).Disbursal_Terms__c;
            }
            if(productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                leadRecord.Loan_Amount__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
            }
            else if(productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c == 'No Finacing Fee'){
                leadRecord.Loan_Financing_Fee__c = null;
            }

        }

    }

    /*private void assignProductToOpportunity(List<Opportunity> oppList){
        for(Opportunity oppRecord : oppList){
            if(oppRecord.Product__r.Product_Type__c == 'Solar Loan' && oppRecord.Product__r.Status__c == 'Active'){
                if(oppRecord.Product__r.Variant__c == FALSE){
                    oppRecord.Record_type_id__c = oppRecord.Product__r.Opportunity_Record_Type_ID__c;
                    oppRecord.Interest_Rate__c = oppRecord.Product__r.Interest_Rate__c;
                    oppRecord.Loan_Term__c = oppRecord.Product__r.Loan_Term__c;
                    oppRecord.Interest_Only_Period__c = oppRecord.Product__r.Interest_Only_Period__c;
                    if(oppRecord.Product__r.Financing_fee_rules__c = 'Maximum (5%, $1,250)'){
                        oppRecord.Financing_fee__c = Math.Max(oppRecord.System_Cost__c * .05, 1250);     
                    }
                    if(oppRecord.Product__r.Financing_fee_rules__c = 'No Financing Fee'){
                        oppRecord.Financing_fee__c = null;     
                    }                    
                }
                if(oppRecord.Product__r.Variant__c == TRUE){
                    if(oppRecord.Product__r.Product_Line__c = 'DOER Solar Loan'){
                        oppRecord.Record_type_id__c = oppRecord.Product__r.Opportunity_Record_Type_ID__c;
                        oppRecord.Interest_Rate__c = oppRecord.Product__r.Interest_Rate__c;
                        oppRecord.Loan_Term__c = oppRecord.Product__r.Loan_Term__c;
                        oppRecord.Interest_Only_Period__c = oppRecord.Product__r.Interest_Only_Period__c;
                        if(oppRecord.Product__r.Financing_fee_rules__c = 'Maximum (5%, $1,250)'){
                            oppRecord.Financing_fee__c = Math.Max(oppRecord.System_Cost__c * .05, 1250);     
                        }
                        if(oppRecord.Product__r.Financing_fee_rules__c = 'No Financing Fee'){
                            oppRecord.Financing_fee__c = null;     
                        }                            
                    }
                }
            }
        }
    }*/

/*
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

***** VERSION 1 | 

lines 178-257 is an operation version of the productAssigmentHandler that assigned without the Product Hierachy in mind. This is fucntional based off the idea that there is one 
product record for every variation. It does not consider credit and is not divided into two methods.

public with sharing class ProductAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public ProductAssignmentHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeLeadInsert(Lead[] newLeads){
        assignProductToLead(newLeads);
        system.debug('The newLeads list: ' + newLeads);
    }
    /*public void OnAfterOpportunityInsert(Opportunity[] newOpps){
        assignProductToOpportunity(newOpps);
    }

    private void assignProductToLead(List<Lead> leadList){
        Map<String, Product__c> productMap = new Map<String, Product__c>();    
        List<Lead> updateLeadList = new List<Lead>();
        for(Product__c productRecord : [SELECT Id, Name, Product_Line__c, Opportunity_Record_Type_ID__c, Loan_Term__c, Loan_Internal_Lender_Rate__c,
                                        Loan_Interest_Rate__c, Loan_Interest_Only_Period__c, Loan_Base_Rate__c, Lead_Record_Type_ID__c, 
                                        Income_Based_Loan_Support__c, Financing_Fee_Terms__c, Disbursal_Terms__c 
                                        FROM Product__c WHERE Active__c = TRUE]){
            productMap.put(productRecord.Name, productRecord);
        }
        system.debug('The productMap: ' + productMap);
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan'){
                leadRecord.Product__c = productMap.get(leadRecord.Product_Identifier__c).Id;
                leadRecord.Loan_Interest_Rate__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Interest_Rate__c;
                leadRecord.Loan_Term__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Term__c;
                leadRecord.Loan_Interest_Only_Period__c = productMap.get(leadRecord.Product_Identifier__c).Loan_Interest_Only_Period__c;
                leadRecord.Loan_Financing_Fee_Terms__c = productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c;
                leadRecord.Loan_Disbursement_Terms__c = productMap.get(leadRecord.Product_Identifier__c).Disbursal_Terms__c;
            }
            if(productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.System_Cost__c * .05, 1250);
                leadRecord.Loan_Amount__c = leadRecord.System_Cost__c + leadRecord.Loan_Financing_Fee__c;
            }
            else if(productMap.get(leadRecord.Product_Identifier__c).Financing_Fee_Terms__c == 'No Finacing Fee'){
                leadRecord.Loan_Financing_Fee__c = null;
            }

        }

    }

    /*private void assignProductToOpportunity(List<Opportunity> oppList){
        for(Opportunity oppRecord : oppList){
            if(oppRecord.Product__r.Product_Type__c == 'Solar Loan' && oppRecord.Product__r.Status__c == 'Active'){
                if(oppRecord.Product__r.Variant__c == FALSE){
                    oppRecord.Record_type_id__c = oppRecord.Product__r.Opportunity_Record_Type_ID__c;
                    oppRecord.Interest_Rate__c = oppRecord.Product__r.Interest_Rate__c;
                    oppRecord.Loan_Term__c = oppRecord.Product__r.Loan_Term__c;
                    oppRecord.Interest_Only_Period__c = oppRecord.Product__r.Interest_Only_Period__c;
                    if(oppRecord.Product__r.Financing_fee_rules__c = 'Maximum (5%, $1,250)'){
                        oppRecord.Financing_fee__c = Math.Max(oppRecord.System_Cost__c * .05, 1250);     
                    }
                    if(oppRecord.Product__r.Financing_fee_rules__c = 'No Financing Fee'){
                        oppRecord.Financing_fee__c = null;     
                    }                    
                }
                if(oppRecord.Product__r.Variant__c == TRUE){
                    if(oppRecord.Product__r.Product_Line__c = 'DOER Solar Loan'){
                        oppRecord.Record_type_id__c = oppRecord.Product__r.Opportunity_Record_Type_ID__c;
                        oppRecord.Interest_Rate__c = oppRecord.Product__r.Interest_Rate__c;
                        oppRecord.Loan_Term__c = oppRecord.Product__r.Loan_Term__c;
                        oppRecord.Interest_Only_Period__c = oppRecord.Product__r.Interest_Only_Period__c;
                        if(oppRecord.Product__r.Financing_fee_rules__c = 'Maximum (5%, $1,250)'){
                            oppRecord.Financing_fee__c = Math.Max(oppRecord.System_Cost__c * .05, 1250);     
                        }
                        if(oppRecord.Product__r.Financing_fee_rules__c = 'No Financing Fee'){
                            oppRecord.Financing_fee__c = null;     
                        }                            
                    }
                }
            }
        }
    }*/