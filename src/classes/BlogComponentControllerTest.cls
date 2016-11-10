@isTest
private class BlogComponentControllerTest {
    public static testMethod void testBlogComponent() {
    	BlueWave_Blog__c bb = new BlueWave_Blog__c(Blog_Type__c = 'General');
    	insert bb;
    	BlogComponentController.getBlogs('General');
    } 
}