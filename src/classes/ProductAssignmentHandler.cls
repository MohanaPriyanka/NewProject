public with sharing class ProductAssignmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public ProductAssignmentHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    /*public void OnBeforeLeadInsert(Lead[] newLeads){
        assignLoanProductToLead(newLeads);
    }*/
    public void onBeforeUpdate(List<Lead> newLeads, Map<ID, Lead> oldLeadsMap){
        assignLoanProductToLead(newLeads, oldLeadsMap);       
    }
    public void onBeforePCRUpdate(List<LASERCA__Personal_Credit_Report__c> pcrList){
        assignLoanProductToLeadViaPCR(pcrList);
    }    
    
    public List<Product2> getProductRecords(){
       List<Product2> productList = new List<Product2>();                                   
        //query for all of the products that are active | NOTE: will need to add queried fields as new product variations come into the system. Look for a way to return all fields.
        for(Product2 productRecord : [SELECT Id, Name, Program__c,IsActive, Loan_Financing_Fee_Terms__c, Loan_Term__c, Technology_Platform_Fee__c,
                                        Product_Type__c, State__c, Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c
                                        FROM Product2 
                                        WHERE isActive = TRUE]){
            productList.add(productRecord);
        }
        return productList;        
    }
 
    //assigns the appropriate product record to the triggered leads.
    public void assignLoanProductToLead(List<Lead> leadList, Map<ID, Lead> oldLeadsMap){
        Boolean runProductAssignment;
        List<Product2> productList = new List<Product2>();
        for (Lead leadRecord : leadList) {
            if (!leadRecord.Automatic_Product_Assignment__c) {
                runProductAssignment = false;
            } else {
                runProductAssignment = true;
                break;
            }
        }     
        if (runProductAssignment) {
           productList = getProductRecords();            
        }
        for(Lead leadRecord : leadList){
            if(leadRecord.Automatic_Product_Assignment__c == true 
                && leadRecord.Product_Line__c == 'Residential Loan' 
                //&& (leadRecord.Status == 'Qualified' || leadRecord.Pre_Approval_form__c == true ) 
                && leadRecord.Loan_Term__c != null 
                && oldLeadsMap.get(leadRecord.Id).Status != 'Qualified'){
                    //run through all of the products per lead to find the specific product suitable for this customer.
                    if(productList.size() > 0){
                        for(Product2 productRecord : productList){
                            //****Product Line could have issues as all leads, opps, etc. are set as Residential Loan and the Product is going to be Solar Loan. Also, home state is returned after credit.
                            if(productRecord.IsActive == true 
                                && productRecord.Product_Type__c == leadRecord.Product_Line__c 
                                && productRecord.Program__c == leadRecord.Product_Program__c 
                                && productRecord.Loan_Term__c == leadRecord.Loan_term__c 
                                && productRecord.State__c == leadRecord.LASERCA__Home_State__c ){
                                if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){
                                    //assign the product to the lead
                                    if(leadRecord.DOER_Solar_Loan__c == true && productRecord.Program__c == 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;
                                        if (productRecord.Technology_Platform_Fee__c != 0 && productRecord.Technology_Platform_Fee__c != null){
                                            LeadRecord.Technology_Platform_Fee__c = (productRecord.Technology_Platform_Fee__c)/100 * leadRecord.Requested_Loan_Amount__c;
                                        } else {LeadRecord.Technology_Platform_Fee__c = 0;}
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c;
                                            leadRecord.Loan_Financing_Fee__c = null;                                        
                                        }
                                    }
                                    if (leadRecord.DOER_Solar_Loan__c == false && productRecord.Program__c != 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;  
                                        if (productRecord.Technology_Platform_Fee__c != 0 && productRecord.Technology_Platform_Fee__c != null){
                                            LeadRecord.Technology_Platform_Fee__c = (productRecord.Technology_Platform_Fee__c)/100 * leadRecord.Requested_Loan_Amount__c;
                                        } else {LeadRecord.Technology_Platform_Fee__c = 0;}      
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c;
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
       for (LASERCA__Personal_Credit_Report__c pcrRecord : pcrList){
            pcrLeadIdList.add(pcrRecord.PCR_Lead_ID__c);
       }
       List<Lead> leadList = [SELECT Id, DOER_Solar_Loan__c, Product_Program__c, Name, Status, Product_Line__c, Product__c, Automatic_Product_Assignment__c,
                                    Loan_Term__c, LASERCA__Home_State__c, LASER_Credit_Score__c, Loan_Financing_Fee__c, 
                                    Pre_Approval_form__c, Requested_Loan_Amount__c, Product__r.Name
                                FROM Lead
                                WHERE Id IN : pcrLeadIdList
                                AND isConverted = false];

       List<Product2> productList = new List<Product2>(getProductRecords());
        for(Lead leadRecord : leadList){
            if(leadRecord.Product_Line__c == 'Residential Loan' && 
             leadRecord.Loan_Term__c != null){
                //run through all of the products per lead to find the specific product suitable for this customer.
                if(productList.size() > 0){
                    for(Product2 productRecord : productList){
                        //****Product Line could have issues as all leads, opps, etc. are set as Residential Loan and the Product is going to be Solar Loan. Also, home state is returned after credit.                      
                        if(leadRecord.Automatic_Product_Assignment__c == true && 
                            productRecord.Program__c == leadRecord.Product_Program__c &&
                            productRecord.Product_Type__c == leadRecord.Product_Line__c &&
                            productRecord.Loan_Term__c == leadRecord.Loan_term__c && 
                            productRecord.State__c == leadRecord.LASERCA__Home_State__c ){
                                if(leadRecord.LASER_Credit_Score__c >= productRecord.Credit_Minimum__c && 
                                    leadRecord.LASER_Credit_Score__c <= productRecord.Credit_Maximum__c){
                                    //assign the product to the lead
                                   if(leadRecord.DOER_Solar_Loan__c == true && productRecord.Program__c == 'MSLP'){
                                    leadRecord.Product__c = productRecord.Id;
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c;
                                            leadRecord.Loan_Financing_Fee__c = null;                                        
                                        }
                                    }
                                    if (leadRecord.DOER_Solar_Loan__c == false && productRecord.Program__c != 'MSLP'){
                                        leadRecord.Product__c = productRecord.Id;        
                                        if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (5%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .05, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'Maximum (7%, $1,250)'){
                                            leadRecord.Loan_Financing_Fee__c = Math.Max(leadRecord.Requested_Loan_Amount__c * .07, 1250);
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c + leadRecord.Loan_Financing_Fee__c;
                                        }else if(productRecord.Loan_Financing_Fee_Terms__c == 'No Financing Fee'){
                                            //leadRecord.Loan_Principal__c = leadRecord.Requested_Loan_Amount__c;
                                            leadRecord.Loan_Financing_Fee__c = null;
                                        }                                                                   
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
        update leadList;       
    }    
} 
