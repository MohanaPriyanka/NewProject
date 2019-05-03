/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/

public with sharing class ZuoraAPI {
    public class RSASignature {
        @AuraEnabled
        public String signature;
        @AuraEnabled
        public String token;
        @AuraEnabled
        public String tenantId;
        @AuraEnabled
        public String key;
        @AuraEnabled
        public Boolean success;
    }

    public class PaymentMethod {
        @AuraEnabled
        public String Id; // 2c92c0f96a0c48bf016a1f3ac74f6a7a
        @AuraEnabled
        public Boolean Active; // false
        @AuraEnabled
        public String PaymentMethodStatus; // Active
        @AuraEnabled
        public String Type;  // CreditCard (in json: Type)
        @AuraEnabled
        public Boolean IsCompany; // false
        @AuraEnabled
        public String CreatedById; // 3
        @AuraEnabled
        public String CreatedDate; // 2019-04-15T04:21:46.000+00:00
        @AuraEnabled
        public String UpdatedById; // 3
        @AuraEnabled
        public String UpdatedDate; // 2019-04-15T04:21:46.000+00:00
        @AuraEnabled
        public String LastTransactionStatus; // Approved
        @AuraEnabled
        public Integer TotalNumberOfProcessedPayments; // 0
        @AuraEnabled
        public Integer NumConsecutiveFailures; // 0
        @AuraEnabled
        public Integer TotalNumberOfErrorPayments; // 0
        @AuraEnabled
        public String LastTransactionDateTime;
        @AuraEnabled
        public Boolean UseDefaultRetryRule; // 2019-04-15T04:21:46.000+00:00
        @AuraEnabled
        public String CreditCardType; // AmericanExpress
        @AuraEnabled
        public String CreditCardHolderName; // Test
        @AuraEnabled
        public String CreditCardMaskNumber; // ***********0002
        @AuraEnabled
        public String BankIdentificationNumber; // 370000
        @AuraEnabled
        public Integer CreditCardExpirationMonth; // 5
        @AuraEnabled
        public Integer CreditCardExpirationYear; // 2022
        @AuraEnabled
        public String CreditCardPostalCode; // 12345
        @AuraEnabled
        public String AchAccountName;
        @AuraEnabled
        public String AchAccountNumberMask;
        @AuraEnabled
        public String AchAbaCode;
        @AuraEnabled
        public String AchAccountType;
        @AuraEnabled
        public String AchBankName;
    }

    public class GenericResponse {
        public Boolean success;
        public String Id;
        public String processId;
        public List<GenericResponseReason> reasons;
    }

    public class GenericResponseReason {
        public Integer code;
        public String message;
    }

    public class CreditMemo {
        public String accountId;
        public List<CreditCharge> charges;
        public Date effectiveDate;
        public String reasonCode;
        public String Project_Zcustom;
        public String CRM_ID_Zcustom;
    }

    public class CreditCharge {
        public Decimal amount;
        public String chargeId;
    }
}