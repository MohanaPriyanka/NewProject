global class AuthNetGetTransactionMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        // Create a fake response
        String responseBody = '{ \"transactions\": [ { \"transId\": \"40034118357\", \"submitTimeUTC\": \"2019-07-02T14:19:03Z\", \"submitTimeLocal\": \"2019-07-02T07:19:03\", \"transactionStatus\": \"settledSuccessfully\", \"accountType\": \"eCheck\", \"accountNumber\": \"XXXX1312\", \"settleAmount\": 12.04, \"hasReturnedItems\": true }, { \"transId\": \"40034118312\", \"submitTimeUTC\": \"2019-07-02T14:14:51Z\", \"submitTimeLocal\": \"2019-07-02T07:14:51\", \"transactionStatus\": \"settledSuccessfully\", \"accountType\": \"eCheck\", \"accountNumber\": \"XXXX2321\", \"settleAmount\": 12.02, \"hasReturnedItems\": false }, { \"transId\": \"40034118307\", \"submitTimeUTC\": \"2019-07-02T14:14:22Z\", \"submitTimeLocal\": \"2019-07-02T07:14:22\", \"transactionStatus\": \"settledSuccessfully\", \"accountType\": \"eCheck\", \"accountNumber\": \"XXXX1321\", \"settleAmount\": 12.01, \"hasReturnedItems\": false }, { \"transId\": \"40034118300\", \"submitTimeUTC\": \"2019-07-02T14:12:57Z\", \"submitTimeLocal\": \"2019-07-02T07:12:57\", \"transactionStatus\": \"settledSuccessfully\", \"accountType\": \"eCheck\", \"accountNumber\": \"XXXX1232\", \"settleAmount\": 1, \"hasReturnedItems\": false } ], \"totalNumInResultSet\": 4, \"messages\": { \"resultCode\": \"Ok\", \"message\": [ { \"code\": \"I00001\", \"text\": \"Successful.\" } ] } }';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        res.setStatusCode(200);
        return res;
    }
}