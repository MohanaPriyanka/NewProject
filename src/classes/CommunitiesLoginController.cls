/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class CommunitiesLoginController {

    global CommunitiesLoginController () {}
    
    // Code we will invoke on page load.
    global PageReference forwardToAuthPage() {
    	String startUrl = System.currentPageReference().getParameters().get('startURL');
    	String displayType = System.currentPageReference().getParameters().get('display');
        List<String> parts = startUrl.split('.*&');
        for (String str : parts) {
            if (str.contains('startURL')) {
                startURL = EncodingUtil.urlDecode(str.split('.*=')[1], 'UTF-8');
            }
        }
        Logger.logNow('CommunitiesLoginController', 'forwardToAuthPage', 'startUrl: ' + startUrl + ', displayType: ' + displayType);

        return new PageReference(startUrl);
        // return Network.forwardToAuthPage(startUrl, displayType);
    }
}