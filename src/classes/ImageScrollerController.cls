public with sharing class ImageScrollerController {
    
    @AuraEnabled
    public static ImageObject[] getImages(String objectSource, String titleSource, String descriptionSource) {
    	ImageObject[] returnList = new ImageObject[0];
    	Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    	if(gd.containsKey(objectSource)) {
    		Set<Schema.SObjectType> attachableTypes =  new Set<Schema.SObjectType>(Schema.SObjectType.attachment.fields.parentId.getReferenceTo());
			if(attachableTypes.contains(gd.get(objectSource))) {
				Schema.DescribeSObjectResult dsr = gd.get(objectSource).getDescribe();
	    		if(dsr.isAccessible() && dsr.isQueryable()) {
    				Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
    				if(fieldMap.containsKey(titleSource) && fieldMap.containsKey(descriptionSource)) {
    					Schema.DescribeFieldResult title = fieldMap.get(titleSource).getDescribe();
    					if(title.isAccessible() && title.getSOAPType() == Schema.SOAPType.String) {
    						Schema.DescribeFieldResult description = fieldMap.get(descriptionSource).getDescribe();
    						if(description.isAccessible() && description.getSOAPType() == Schema.SOAPType.String) {
    							for(SObject s : Database.query('SELECT Id, ' + titleSource + ', ' + descriptionSource + ', (Select Id from Attachments) FROM ' + objectSource)) {
    								SObject[] atts = s.getSObjects('Attachments');
    								if(atts.size() > 0) {
    									returnList.add(new ImageObject((String)atts[0].get('Id'), (String) s.get(titleSource), (String) s.get(descriptionSource)));
    								}
    							}
    						} 
    					}
    				}
	    		}
			}
    	}
    	return returnList;
    }
    
    public class ImageObject {
    	@AuraEnabled
    	public String image {get;set;}
    	@AuraEnabled
    	public String title {get;set;}
    	@AuraEnabled
    	public String body {get;set;}
    	
    	public ImageObject(String image, String title, String body) {
    		this.image = image;
    		this.title = title;
    		this.body = body;
    	}
    } 
}