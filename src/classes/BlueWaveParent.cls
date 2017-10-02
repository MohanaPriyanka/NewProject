/*************************************************************************************
 * Created By: Peter Yao
 * Description: Controller for BlueWaveParent super component that can be used for all
 *              custom lightning components
 *
 * Tested By: LoanUnderwritingTest
 *************************************************************************************/

public without sharing class BlueWaveParent {
    @AuraEnabled
    public static String getLicenseType() {
        SLPUserHelper.PartnerProfile profile = SLPUserHelper.getPartnerProfile();
        return profile.LicenseType;
    }

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

    public static String convertStateToAbbreviation(String stateName ) {
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
            else if(stateName == 'Rhode Island') {
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

    public static String convertAbbreviationToState(String abbreviation) {
        String stateName;
            if(abbreviation  ==  'AL') {
                stateName = 'Alabama';            
            }
            else if(abbreviation == 'AK') {
                stateName = 'Alaska';            
            }
            else if(abbreviation == 'AZ') {
                stateName = 'Arizona';            
            }
            else if(abbreviation == 'AR') {
                stateName = 'Arkansas';            
            }
            else if(abbreviation == 'CA') {
                stateName = 'California';            
            }
            else if(abbreviation == 'CO') {
                stateName = 'Colorado';            
            }
            else if(abbreviation == 'CT') {
                stateName = 'Connecticut';            
            }
            else if(abbreviation == 'DE') {
                stateName = 'Delaware';            
            }
            else if(abbreviation == 'FL') {
                stateName = 'Florida';            
            }
            else if(abbreviation == 'GA') {
                stateName = 'Georgia';            
            }
            else if(abbreviation == 'HI') {
                stateName = 'Hawaii';            
            }
            else if(abbreviation == 'ID') {
                stateName = 'Idaho';            
            }
            else if(abbreviation == 'IL') {
                stateName = 'Illinois';            
            }
            else if(abbreviation == 'IN') {
                stateName = 'Indiana';            
            }
            else if(abbreviation == 'IA') {
                stateName = 'Iowa';            
            }
            else if(abbreviation == 'KS') {
                stateName = 'Kansas';            
            }
            else if(abbreviation == 'KY') {
                stateName = 'Kentucky';            
            }
            else if(abbreviation == 'LA') {
                stateName = 'Louisiana';            
            }
            else if(abbreviation == 'ME') {
                stateName = 'Maine';            
            }
            else if(abbreviation == 'MD') {
                stateName = 'Maryland';            
            }
            else if(abbreviation == 'MA') {
                stateName = 'Massachusetts';            
            }
            else if(abbreviation == 'MI') {
                stateName = 'Michigan';            
            }
            else if(abbreviation == 'MN') {
                stateName = 'Minnesota';            
            }
            else if(abbreviation == 'MS') {
                stateName = 'Mississippi';            
            }
            else if(abbreviation == 'MO') {
                stateName = 'Missouri';            
            }
            else if(abbreviation == 'MT') {
                stateName = 'Montana';            
            }
            else if(abbreviation == 'NE') {
                stateName = 'Nebraska';            
            }
            else if(abbreviation == 'NV') {
                stateName = 'Nevada';            
            }
            else if(abbreviation == 'NH') {
                stateName = 'New Hampshire';            
            }
            else if(abbreviation == 'NJ') {
                stateName = 'New Jersey';            
            }
            else if(abbreviation == 'NM') {
                stateName = 'New Mexico';            
            }
            else if(abbreviation == 'NY') {
                stateName = 'New York';            
            }
            else if(abbreviation == 'NC') {
                stateName = 'North Carolina';            
            }
            else if(abbreviation == 'ND') {
                stateName = 'North Dakota';            
            }
            else if(abbreviation == 'OH') {
                stateName = 'Ohio';            
            }
            else if(abbreviation == 'OK') {
                stateName = 'Oklahoma';            
            }
            else if(abbreviation == 'OR') {
                stateName = 'Oregon';            
            }
            else if(abbreviation == 'PA') {
                stateName = 'Pennsylvania';            
            }
            else if(abbreviation == 'RI') {
                stateName = 'Rhode Island';            
            }
            else if(abbreviation == 'SC') {
                stateName = 'South Carolina';            
            }
            else if(abbreviation == 'SD') {
                stateName = 'South Dakota';            
            }
            else if(abbreviation == 'TN') {
                stateName = 'Tennessee';            
            }
            else if(abbreviation == 'TX') {
                stateName = 'Texas';            
            }
            else if(abbreviation == 'UT') {
                stateName = 'Utah';            
            }
            else if(abbreviation == 'VT') {
                stateName = 'Vermont';            
            }
            else if(abbreviation == 'VA') {
                stateName = 'Virginia';            
            }
            else if(abbreviation == 'WA') {
                stateName = 'Washington';            
            }
            else if(abbreviation == 'WV') {
                stateName = 'West Virginia';            
            }
            else if(abbreviation == 'WI') {
                stateName = 'Wisconsin';            
            }
            else if(abbreviation == 'WY') {
                stateName = 'Wyoming';            
            } else {
                stateName = stateName ;  
            }    
        return stateName;   
    }      
}
