global class AuthNetGetSettledBatchMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        // Create a fake response
        String responseBody = '{ \"batchList\": [ { \"batchId\": \"9498645\", \"settlementTimeUTC\": \"2019-07-03T15:21:40Z\", \"settlementTimeLocal\": \"2019-07-03T08:21:40\", \"settlementState\": \"settledSuccessfully\", \"paymentMethod\": \"eCheck\" } ], \"messages\": { \"resultCode\": \"Ok\", \"message\": [ { \"code\": \"I00001\", \"text\": \"Successful.\" } ] } }';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        res.setStatusCode(200);
        return res;
    }
}