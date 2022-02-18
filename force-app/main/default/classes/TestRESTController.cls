/**
 * Created by max stackhouse under the MIT License, https://github.com/Maxscores/sfdc-rest-controller-framework
 * Description: Used to test the RESTController class and should be used as an example for implementation
 *
 *
 * Test: RESTControllerTest
 */


@RestResource(UrlMapping='/tests')
global class TestRESTController extends RESTController {
    private static TestRESTController controller = new TestRESTController();

    @HttpGet
    global static void getRequest() {
        controller.getRecords();
    }

    @HttpPost
    global static void postRequest() {
        controller.postRecords();
    }

    @HttpPatch
    global static void patchRequest() {
        controller.patchRecords();
    }

    @HttpPut
    global static void putRequest() {
        controller.putRecords();
    }

    @HttpDelete
    global static void deleteRequest() {
        controller.deleteRecords();
    }

    public override void postRecords() {
        envelope.setData('post records');

        envelope.setJSONResponse(response);
    }
    public override void patchRecords() {
        envelope.setData('patch records');

        envelope.setJSONResponse(response);
    }
    public override void getRecords() {
        String requestType = request.params.get('Type');
        if (requestType == 'error') {
            envelope.addError('error');
        } else if (requestType == 'message') {
            envelope.addMessage('message');
        }
        envelope.setData('get records');

        envelope.setJSONResponse(response);
    }
    public override void putRecords() {
        envelope.setData('put records');

        envelope.setJSONResponse(response);
    }
    public override void deleteRecords() {
        envelope.setData('delete records');

        envelope.setJSONResponse(response);
    }
}