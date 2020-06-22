/*************************************************************************************
 * Created By: Peter Yao
 * Description: Controller for BlueWaveParent super component that can be used for all
 *              custom lightning components
 *
 * Tested By: LoanUnderwritingTest / SLPControllersTestclass
 *************************************************************************************/

public without sharing class BlueWaveParent {
    

    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    @AuraEnabled 
    public static SObject updateSObject(SObject sobj) {
        update sobj;
        return sobj;
    }

    @AuraEnabled 
    public static SObject insertSObject(SObject sobj) {
        insert sobj;
        return sobj;
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
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType, String description) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment a = new Attachment();
        a.parentId = parentId;
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;
        a.Description = description;
        insert a;
        return a.Id;
    }

    @AuraEnabled
    public static Id saveTheChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        String description = '';
        Id fileUploaded = saveTheChunkWithDescription(parentId, fileName, base64Data, contentType, description, null, fileId);
        return fileUploaded;
    }

    @AuraEnabled
    public static Id saveTheChunkWithDescription(Id parentId, String fileName, String base64Data, String contentType, String description,  String emailNotification, String fileId) {
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType, description);
            if (emailNotification != null){
                String emailBody = 'A file has been uploaded'+  
                                    + '<br>  Parent Id: ' + parentId 
                                    + '<br>  File Name: ' + fileName;
                List<String> addressList = new List<String>{};   
                addressList.add(emailNotification);
                MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'File Uploaded From Portal', addressList);
            }
        } else {
            appendToFile(fileId, base64Data);
        }
        return Id.valueOf(fileId);
    }

    @AuraEnabled
    public static Boolean checkIfDisbursalOnHold(Id oppId) {

        Loan__c loan = [
            SELECT Id,
            (SELECT Id, Status__c
             FROM Disbursals__r) 
            FROM Loan__c
            WHERE Opportunity__c =: oppId
        ];

        for (Disbursal__c disbursal : loan.Disbursals__r) {
            if (disbursal.Status__c == 'Hold') {
                return true;
            }
        }

        return false;
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

    public static Map<String, String> stateMap = new Map<String, String>{
        'Alabama' => 'AL','Alaska' => 'AK','Arizona' => 'AZ','Arkansas' => 'AR','California' => 'CA',
        'Colorado' => 'CO','Connecticut' => 'CT','Delaware' => 'DE','Florida' => 'FL','Georgia' => 'GA',
        'Hawaii' => 'HI','Idaho' => 'ID','Illinois' => 'IL','Indiana' => 'IN','Iowa' => 'IA','Kansas' => 'KS',
        'Kentucky' => 'KY','Louisiana' => 'LA','Maine' => 'ME','Maryland' => 'MD','Massachusetts' => 'MA',
        'Michigan' => 'MI','Minnesota' => 'MN','Mississippi' => 'MS','Missouri' => 'MO','Montana' => 'MT',
        'Nebraska' => 'NE','Nevada' => 'NV','New Hampshire' => 'NH','New Jersey' => 'NJ','New Mexico' => 'NM',
        'New York' => 'NY','North Carolina' => 'NC','North Dakota' => 'ND','Ohio' => 'OH','Oklahoma' => 'OK',
        'Oregon' => 'OR','Pennsylvania' => 'PA','Rhode Island' => 'RI','South Carolina' => 'SC',
        'South Dakota' => 'SD','Tennessee' => 'TN','Texas' => 'TX','Utah' => 'UT','Vermont' => 'VT',
        'Virginia' => 'VA','Washington' => 'WA','West Virginia' => 'WV','Wisconsin' => 'WI','Wyoming' => 'WY',
        'AL' => 'Alabama','AK' => 'Alaska','AZ' => 'Arizona','AR' => 'Arkansas','CA' => 'California',
        'CO' => 'Colorado','CT' => 'Connecticut','DE' => 'Delaware','FL' => 'Florida','GA' => 'Georgia',
        'HI' => 'Hawaii','ID' => 'Idaho','IL' => 'Illinois','IN' => 'Indiana','IA' => 'Iowa','KS' => 'Kansas',
        'KY' => 'Kentucky','LA' => 'Louisiana','ME' => 'Maine','MD' => 'Maryland','MA' => 'Massachusetts',
        'MI' => 'Michigan','MN' => 'Minnesota','MS' => 'Mississippi','MO' => 'Missouri','MT' => 'Montana',
        'NE' => 'Nebraska','NV' => 'Nevada','NH' => 'New Hampshire','NJ' => 'New Jersey','NM' => 'New Mexico',
        'NY' => 'New York','NC' => 'North Carolina','ND' => 'North Dakota','OH' => 'Ohio','OK' => 'Oklahoma',
        'OR' => 'Oregon','PA' => 'Pennsylvania','RI' => 'Rhode Island','SC' => 'South Carolina',
        'SD' => 'South Dakota','TN' => 'Tennessee','TX' => 'Texas','UT' => 'Utah','VT' => 'Vermont',
        'VA' => 'Virginia','WA' => 'Washington','WV' => 'West Virginia','WI' => 'Wisconsin','WY' => 'Wyoming'};


    public static String convertStateToAbbreviation(String stateName ) {
        if (stateMap.get(stateName) != null) {
            return stateMap.get(stateName);
        } else {
            return stateName;
        }
    }

    public static String convertAbbreviationToState(String abbreviation) {
        if (stateMap.get(abbreviation) != null) {
            return stateMap.get(abbreviation);
        } else {
            return abbreviation;
        }
    }

    @AuraEnabled
    public static List<String> getUSStates(Boolean abbreviated) {
        List<String> states = new List<String>();
        if (!abbreviated) {
            for (String s : stateMap.keySet()) {
                if (s.length() > 2) {
                    states.add(s);
                }
            }
        } else {
            for (String s : stateMap.values()) {
                if (s.length() == 2) {
                    states.add(s);
                }
            }
        }
        return states;
    }
}