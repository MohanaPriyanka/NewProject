({
    convertArrayOfObjectsToCSV : function(component,objectRecords,keys){
        var csvStringResult, counter, columnDivider, lineDivider;
       
        if (objectRecords == null || !objectRecords.length) {
            return null;
        }
        columnDivider = ',';
        lineDivider =  '\n';
        
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