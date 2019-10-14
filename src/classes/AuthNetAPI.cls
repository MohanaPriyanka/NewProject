/**
 * Created by joeychan on 2019-07-27.
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class AuthNetAPI {
    public GetSettledBatchListRequest getSettledBatchListRequest;
    public GetTransactionListRequest getTransactionListRequest;
    public List<BatchList> batchList { get; set; }
    public List<Transactions> transactions { get; set; }
    public Integer totalNumInResultSet;

    public class Transactions {
        public Boolean hasReturnedItems { get; set; }
        public String transId { get; set; }
        public Decimal settleAmount { get; set; }
    }
    public class BatchList {
        public String batchId { get; set; }
        public String paymentMethod { get; set; }
    }
    public class MerchantAuthentication {
        public String Zname;
        public String transactionKey;
    }
    public class GetSettledBatchListRequest {
        public MerchantAuthentication merchantAuthentication;
        public String MAfirstSettlementDate;
        public String lastSettlementDate;
    }
    public class GetTransactionListRequest {
        public MerchantAuthentication DmerchantAuthentication;
        public String CbatchId;
        public Sorting Bsorting;
        public Paging Apaging;
    }
    public class Paging {
        public String Zlimit_Z;
        public String offset;
    }
    public class Sorting {
        public String ZorderBy;
        public String orderDescending;
    }
}