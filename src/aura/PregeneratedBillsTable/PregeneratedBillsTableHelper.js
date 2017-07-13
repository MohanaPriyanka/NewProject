({
    convertArrayOfObjectsToCSV : function(component,objectRecords){
        var csvStringResult, counter, keys, columnDivider, lineDivider;
       
        if (objectRecords == null || !objectRecords.length) {
            return null;
         }
        columnDivider = ',';
        lineDivider =  '\n';
 
        keys = ['Name','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c', 'PreGen_Name_on_Account__c', 
               'PreGen_Production_Update__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        
        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;
 
        for (var i=0; i < objectRecords.length; i++){   
            counter = 0;
           
             for (var sTempkey in keys) {
                var skey = keys[sTempkey] ;  
 
              // add , [comma] after every String value,. [except first]
                  if (counter > 0){ 
                      csvStringResult += columnDivider; 
                   }   
               
               csvStringResult += '"'+ objectRecords[i][skey]+'"'; 
               
               counter++;
 
            } 
             csvStringResult += lineDivider;
          } 
       
       // return the CSV formate String 
        return csvStringResult;        
    },
})