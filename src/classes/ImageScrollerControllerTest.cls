@isTest
private class ImageScrollerControllerTest {
    private static testMethod void testImageScroller() {
    	Project_Scroller__c ps = new Project_Scroller__c(Name='Test', Description__c='test');
    	insert ps;
    	Attachment a = new Attachment(ParentId = ps.Id, name='test', Body=Blob.ValueOf('test'));
    	insert a;
    	ImageScrollerController.getImages('Project_Scroller__c', 'Name', 'Description__c');
    }
}