/**
 * Created by joeychan on 2019-07-27.
 */

public with sharing class AuthNetAPI {
    public GetSettledBatchListRequest getSettledBatchListRequest;
    public GetTransactionListRequest getTransactionListRequest;
    public List<BatchList> batchList { get; set; }
    public List<Transactions> transactions { get; set; }

    public class Transactions {
        public Boolean hasReturnedItems { get; set; }
    }
    public class BatchList {
        public String batchId { get; set; }
    }
    public class MerchantAuthentication {
        public String name;
        public String transactionKey;
    }
    public class GetSettledBatchListRequest {
        public MerchantAuthentication merchantAuthentication;
        public String firstSettlementDate;
        public String lastSettlementDate;
    }
    public class GetTransactionListRequest {
        public MerchantAuthentication merchantAuthentication;
        public String batchId;
        public Sorting sorting;
        public Paging paging;
    }
    public class Paging {
        public String limit_Z;
        public String offset;
    }
    public class Sorting {
        public String orderBy;
        public String orderDescending;
    }
}