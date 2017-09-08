/*************************************************************************************
 * Created By: Peter Yao
 * Description: Controller for BlueWaveParent super component that can be used for all
 *              custom lightning components
 *
 * Tested By: LoanUnderwritingTest
 *************************************************************************************/

public without sharing class BlueWaveParent {
    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    @AuraEnabled 
    public static void updateSObject(SObject sobj) {
        update sobj;
    }

    @AuraEnabled 
    public static void insertSObject(SObject sobj) {
        insert sobj;
    }

    @AuraEnabled 
    public static List<String> getPicklistFields(String objectName, String fieldName){
        Schema.SObjectType ctype = globalDescribe.get(objectName); 
        Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();

        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = fmap.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }

        return options;
    }

    @AuraEnabled
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment a = new Attachment();
        a.parentId = parentId;
 
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;
        
        insert a;
        
        return a.Id;
    }

    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
        
        return Id.valueOf(fileId);
    }    

    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id = :fileId
            ];
        
     	String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data); 
        
        update a;
    }    

    public static String convertStateToAbbreviation(String stateName) {
        String abbreviation;
            if(stateName ==  'Alabama') {
                abbreviation = 'AL';            
            }
            else if(stateName == 'Alaska') {
                abbreviation = 'AK';            
            }
            else if(stateName == 'Arizona') {
                abbreviation = 'AZ';            
            }
            else if(stateName == 'Arkansas') {
                abbreviation = 'AR';            
            }
            else if(stateName == 'California') {
                abbreviation = 'CA';            
            }
            else if(stateName == 'Colorado') {
                abbreviation = 'CO';            
            }
            else if(stateName == 'Connecticut') {
                abbreviation = 'CT';            
            }
            else if(stateName == 'Delaware') {
                abbreviation = 'DE';            
            }
            else if(stateName == 'Florida') {
                abbreviation = 'FL';            
            }
            else if(stateName == 'Georgia') {
                abbreviation = 'GA';            
            }
            else if(stateName == 'Hawaii') {
                abbreviation = 'HI';            
            }
            else if(stateName == 'Idaho') {
                abbreviation = 'ID';            
            }
            else if(stateName == 'Illinois') {
                abbreviation = 'IL';            
            }
            else if(stateName == 'Indiana') {
                abbreviation = 'IN';            
            }
            else if(stateName == 'Iowa') {
                abbreviation = 'IA';            
            }
            else if(stateName == 'Kansas') {
                abbreviation = 'KS';            
            }
            else if(stateName == 'Kentucky') {
                abbreviation = 'KY';            
            }
            else if(stateName == 'Louisiana') {
                abbreviation = 'LA';            
            }
            else if(stateName == 'Maine') {
                abbreviation = 'ME';            
            }
            else if(stateName == 'Maryland') {
                abbreviation = 'MD';            
            }
            else if(stateName == 'Massachusetts') {
                abbreviation = 'MA';            
            }
            else if(stateName == 'Michigan') {
                abbreviation = 'MI';            
            }
            else if(stateName == 'Minnesota') {
                abbreviation = 'MN';            
            }
            else if(stateName == 'Mississippi') {
                abbreviation = 'MS';            
            }
            else if(stateName == 'Missouri') {
                abbreviation = 'MO';            
            }
            else if(stateName == 'Montana') {
                abbreviation = 'MT';            
            }
            else if(stateName == 'Nebraska') {
                abbreviation = 'NE';            
            }
            else if(stateName == 'Nevada') {
                abbreviation = 'NV';            
            }
            else if(stateName == 'New Hampshire') {
                abbreviation = 'NH';            
            }
            else if(stateName == 'New Jersey') {
                abbreviation = 'NJ';            
            }
            else if(stateName == 'New Mexico') {
                abbreviation = 'NM';            
            }
            else if(stateName == 'New York') {
                abbreviation = 'NY';            
            }
            else if(stateName == 'North Carolina') {
                abbreviation = 'NC';            
            }
            else if(stateName == 'North Dakota') {
                abbreviation = 'ND';            
            }
            else if(stateName == 'Ohio') {
                abbreviation = 'OH';            
            }
            else if(stateName == 'Oklahoma') {
                abbreviation = 'OK';            
            }
            else if(stateName == 'Oregon') {
                abbreviation = 'OR';            
            }
            else if(stateName == 'Pennsylvania') {
                abbreviation = 'PA';            
            }
            else if(stateName == 'RhodeIsland') {
                abbreviation = 'RI';            
            }
            else if(stateName == 'South Carolina') {
                abbreviation = 'SC';            
            }
            else if(stateName == 'South Dakota') {
                abbreviation = 'SD';            
            }
            else if(stateName == 'Tennessee') {
                abbreviation = 'TN';            
            }
            else if(stateName == 'Texas') {
                abbreviation = 'TX';            
            }
            else if(stateName == 'Utah') {
                abbreviation = 'UT';            
            }
            else if(stateName == 'Vermont') {
                abbreviation = 'VT';            
            }
            else if(stateName == 'Virginia') {
                abbreviation = 'VA';            
            }
            else if(stateName == 'Washington') {
                abbreviation = 'WA';            
            }
            else if(stateName == 'West Virginia') {
                abbreviation = 'WV';            
            }
            else if(stateName == 'Wisconsin') {
                abbreviation = 'WI';            
            }
            else if(stateName == 'Wyoming') {
                abbreviation = 'WY';            
            } else {
                abbreviation = stateName;  
            }    
        return abbreviation;   
    }      
}
