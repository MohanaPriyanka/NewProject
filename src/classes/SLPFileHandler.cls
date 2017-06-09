public class SLPFileHandler {
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
    public static Attachment[] getRecordFiles (Id parentId) { 
    	Attachment[] Attachments = [SELECT Id, Name, ParentId, Description, CreatedDate FROM Attachment WHERE ParentId = : parentId];
    	return attachments;		
    }    

    @AuraEnabled
    public static Attachment[] getDescribedFile (String parentId, String description) { 
    	String descriptionQueryHelper = '%'+description+'%';
    	return [SELECT Id, Name, ParentId, Description, CreatedDate FROM Attachment WHERE ParentId = :parentId AND Description LIKE :descriptionQueryHelper ORDER BY CreatedDate DESC LIMIT 1];
    }       
}