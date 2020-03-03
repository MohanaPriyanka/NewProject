/**
 * Created by peteryao on 2/19/20.
 * Tested by: RESTRouterV3Test
 */

@RestResource(UrlMapping='/v3/*')

global without sharing class RESTRouterV3 {
    static {
        RESTRouterV2.controller = new CSLeadsRESTControllerV3();
    }

    @HttpPatch
    global static void patchRequest() {
        RESTRouterV2.patchRequest();
    }

    @HttpPost
    global static void postRequest() {
        RESTRouterV2.postRequest();
    }

    @HttpGet
    global static void getRequest() {
        RESTRouterV2.getRequest();
    }
}