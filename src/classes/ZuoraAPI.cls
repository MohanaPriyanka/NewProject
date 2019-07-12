/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/

public with sharing class ZuoraAPI {
    // https://www.zuora.com/developer/api-reference/#tag/RSA-Signatures
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

    // https://www.zuora.com/developer/api-reference/#operation/Object_GETPaymentMethod
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

    // https://www.zuora.com/developer/api-reference/#operation/POST_Account
    public class ZuoraAccount {
        public String AccountNumber;
        public Boolean AllowInvoiceEdit;
        public String Id;
        @AuraEnabled
        public Boolean AutoPay;
        public Boolean InvoiceDeliveryPrefsPrint;
        public String UpdatedDate;
        public Integer CreditBalance;
        public Integer BillCycleDay;
        public String BcdSettingOption;
        public String PaymentTerm;
        public String Status;
        public Integer TotalInvoiceBalance;
        public String UpdatedById;
        public String Batch;
        public String CreatedById;
        public Boolean InvoiceDeliveryPrefsEmail;
        public String Name;
        public String SoldToId;
        public String Notes;
        @AuraEnabled
        public Decimal Balance;
        public String InvoiceTemplateId;
        public String CrmId;
        public String BillToId;
        public String CreatedDate;
        public String DefaultPaymentMethodId;
        public String Currency_Zreserved;
    }

    // https://www.zuora.com/developer/api-reference/#operation/Object_POSTContact
    public class ZuoraContact {
        public String AccountId;
        public String Address1;
        public String City;
        public String Country;
        public String Description;
        public String Fax;
        public String FirstName;
        public String HomePhone;
        public String LastName;
        public String MobilePhone;
        public String NickName;
        public String OtherPhone;
        public String OtherPhoneType;
        public String PersonalEmail;
        public String PostalCode;
        public String State;
        public String TaxRegion;
        public String WorkEmail;
        public String CRM_ID_Zcustom;
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

    // Used to create, but not to query for credit memos:
    public class CreditMemo {
        public String accountId;
        public List<CreditCharge> charges;
        public Date effectiveDate;
        public String reasonCode;
        public String Project_Zcustom;
        public String ClientOwner_Zcustom;
        public String CRM_ID_Zcustom;
    }

    // Used to query, but not to create credit memos:
    public class ZuoraCreditMemo {
        public String id;
        public String accountId;
        public Date creditMemoDate;
        public Decimal amount;
        public Decimal unappliedAmount;
        public String Project_Zcustom;
        public String ClientOwner_Zcustom;
        public String CRM_ID_Zcustom;
    }

    public class ZuoraCreditMemoItem {
        public String id;
        public String accountId;
        public Decimal amount;
        public Decimal unappliedAmount;
    }

    // ASSUMES CREDIT MEMOS ONLY HAVE 1 ITEM:
    public class CreditMemoWithItem{
        public ZuoraCreditMemo CreditMemo;
        public ZuoraCreditMemoItem Item;
    }

    public class CreditCharge {
        public Decimal amount;
        public String chargeId;
    }

    // https://www.zuora.com/developer/api-reference/#operation/Action_POSTcreate
    public class ActionItems {
        public String type;
        public List<Object> objects;
        public ActionItems() {
            objects = new List<Object>();
        }
    }

    // https://www.zuora.com/developer/api-reference/#operation/POST_Order
    public class Order {
        public String existingAccountNumber;
        public String orderDate;
        public String orderNumber;
        public ProcessingOptions processingOptions;
        public List<Subscription> subscriptions;
        public Order(String accountNumber, Date orderDate) {
            subscriptions = new List<Subscription>();
            this.existingAccountNumber = accountNumber;
            this.orderDate = String.valueOf(orderDate);
        }
        public Subscription addSubscription() {
            ZuoraAPI.Subscription subscription = new ZuoraAPI.Subscription();
            this.subscriptions.add(subscription);
            return subscription;
        }
        public Subscription addSubscription(String subscriptionNumber) {
            ZuoraAPI.Subscription subscription = new ZuoraAPI.Subscription(subscriptionNumber);
            this.subscriptions.add(subscription);
            return subscription;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (subscriptions == null || subscriptions.size() != 1) {
                throw new Util.BWException('Did not expect an Order without a single subscription');
            }
            return subscriptions[0].getClientProject();
        }
    }

    public class TriggerDate {
        public String name;
        public Date triggerDate;
    }

    public class Subscription {
        public List<OrderAction> orderActions;
        public String subscriptionNumber;
        public Integer baseVersion;
        public Integer newVersion;
        public Subscription() {
            orderActions = new List<OrderAction>();
        }
        public Subscription(String subscriptionNumber) {
            orderActions = new List<OrderAction>();
            this.subscriptionNumber = subscriptionNumber;
        }
        public OrderAction addOrderAction(String type, Date effectiveDate) {
            OrderAction orderAction = new OrderAction(type, effectiveDate);
            orderActions.add(orderAction);
            return orderAction;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (orderActions == null || orderActions.size() != 1) {
                throw new Util.BWException('Did not expect a Subscription without a single Order Action');
            }
            return orderActions[0].getClientProject();
        }
        public OrderAction getCreateSubscription() {
            for (OrderAction orderAction : orderActions) {
                if (orderAction.type_Zreserved == 'CreateSubscription') {
                    return orderAction;
                }
            }
            return null;
        }
    }

    public class ProcessingOptions {
        public Boolean applyCreditBalance;
        public BillingOptions billingOptions;
        public Boolean collectPayment;
        public Boolean runBilling;
    }

    public class OrderAction {
        public CreateSubscription createSubscription;
        public AddProduct addProduct;
        public List<TriggerDate> triggerDates;
        public String type_Zreserved;
        public Integer sequence;

        public OrderAction(String type, Date contractEffectiveDate) {
            this.triggerDates = new List<TriggerDate>();
            this.type_Zreserved = type;
            ZuoraAPI.TriggerDate triggerDate = new ZuoraAPI.TriggerDate();
            triggerDate.triggerDate = contractEffectiveDate;
            triggerDate.name = 'ContractEffective';
            this.triggerDates.add(triggerDate);
        }
        public CreateSubscription addCreateSubscription() {
            if (this.addProduct != null) {
                throw new Util.BWException('Tried to add a CreateSubscription object to an OrderAction with an existing AddProduct object');
            }
            CreateSubscription createSubscription = new CreateSubscription();
            this.createSubscription = createSubscription;
            return createSubscription;
        }
        public AddProduct addAddProduct(String productRatePlanId) {
            if (this.createSubscription != null) {
                throw new Util.BWException('Tried to add an AddProduct object to an OrderAction with an existing CreateSubscription object');
            }
            AddProduct addProduct = new AddProduct(productRatePlanId);
            this.addProduct = addProduct;
            return addProduct;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            ZuoraSubscriptionService.ClientProject clientProject;
            switch on type_Zreserved {
                when 'AddProduct' {
                    clientProject = addProduct.getClientProject();
                } when 'CreateSubscription' {
                    clientProject = createSubscription.getClientProject();
                } when else {
                    throw new Util.BWException('Unhandled order action type when getting client projects: ' + type_Zreserved);
                }
            }
            return clientProject;
        }
        public Date getContractEffective() {
            for (TriggerDate triggerDate : triggerDates) {
                if (triggerDate.name == 'ContractEffective') {
                    return triggerDate.triggerDate;
                }
            }
            return null;
        }
    }

    public class Terms {
        public Boolean autoRenew;
        public InitialTerm initialTerm;
        public String renewalSetting;
        public List<RenewalTerms> renewalTerms;
    }

    public class BillingOptions {
        public String targetDate;
    }

    public class SubscribeToRatePlan {
        public String productRatePlanId;
        public List<ChargeOverride> chargeOverrides;
        public SubscribeToRatePlan(String productRatePlanId) {
            this.productRatePlanId = productRatePlanId;
            chargeOverrides = new List<ChargeOverride>();
        }
        public ChargeOverride addChargeOverride(String productRatePlanChargeId, String clientName, String projectName) {
            ChargeOverride chargeOverride = new ChargeOverride(productRatePlanChargeId, clientName, projectName);
            chargeOverrides.add(chargeOverride);
            return chargeOverride;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (chargeOverrides == null || chargeOverrides.size() != 1) {
                throw new Util.BWException('Did not expect a SubscribeToRatePlan without a single Charge Override');
            }
            return chargeOverrides[0].getClientProject();
        }
    }

    public class ChargeOverride {
        public String chargeNumber;
        public ProductRatePlanCustomFields customFields;
        public String productRatePlanChargeId;
        public ChargeOverride(String productRatePlanChargeId, String clientName, String projectName) {
            customFields = new ProductRatePlanCustomFields(clientName, projectName);
            this.productRatePlanChargeId = productRatePlanChargeId;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (customFields == null || customFields.Project_Zcustom == null || customFields.ClientOwner_Zcustom == null) {
                throw new Util.BWException('Did not expect a Charge Override without customFields or null client/project');
            }

            return new ZuoraSubscriptionService.ClientProject(customFields.ClientOwner_Zcustom, customFields.Project_Zcustom, chargeNumber, productRatePlanChargeId);
        }
    }

    public class AddProduct {
        public String productRatePlanId;
        public List<ChargeOverride> chargeOverrides;
        public String newRatePlanId;

        public AddProduct(String productRatePlanId) {
            this.productRatePlanId = productRatePlanId;
            chargeOverrides = new List<ChargeOverride>();
        }
        public ChargeOverride addChargeOverride(String productRatePlanChargeId, String clientName, String projectName) {
            ChargeOverride chargeOverride = new ChargeOverride(productRatePlanChargeId, clientName, projectName);
            chargeOverrides.add(chargeOverride);
            return chargeOverride;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (chargeOverrides == null || chargeOverrides.size() != 1) {
                throw new Util.BWException('Did not expect an addProduct order action without a single charge override');
            }
            return chargeOverrides[0].getClientProject();
        }
    }

    public class CreateSubscription {
        public List<SubscribeToRatePlan> subscribeToRatePlans;
        public String subscriptionNumber;
        public Terms terms;
        public CreateSubscription() {
            subscribeToRatePlans = new List<SubscribeToRatePlan>();
        }
        public Terms addEvergreenTerm() {
            Terms terms = new Terms();
            ZuoraAPI.InitialTerm initialTerm = new ZuoraAPI.InitialTerm();
            initialTerm.termType = 'EVERGREEN';
            terms.initialTerm = initialTerm;
            this.terms = terms;
            return Terms;
        }
        public SubscribeToRatePlan addSubscribeToRatePlan(String productRatePlanId) {
            SubscribeToRatePlan subscribeToRatePlan = new SubscribeToRatePlan(productRatePlanId);
            subscribeToRatePlans.add(subscribeToRatePlan);
            return subscribeToRatePlan;
        }
        public ZuoraSubscriptionService.ClientProject getClientProject() {
            if (subscribeToRatePlans == null || subscribeToRatePlans.size() != 1) {
                throw new Util.BWException('Did not expect a create subscription order action without a single subscriptionToRatePlan');
            }
            return subscribeToRatePlans[0].getClientProject();
        }
    }

    public class InitialTerm {
        public Integer period;
        public String periodType;
        public String startDate;
        public String termType;
    }

    public class RenewalTerms {
        public Integer period;
        public String periodType;
    }

    public class ProductRatePlanCustomFields {
        public String ClientOwner_Zcustom;
        public String Project_Zcustom;
        public ProductRatePlanCustomFields(String clientName, String projectName) {
            ClientOwner_Zcustom = clientName;
            Project_Zcustom = projectName;
        }
    }

    public class OrderActionResult {
        public Boolean success;
        public String orderNumber;
        public String accountNumber;
        public String status;
        public String processId;
        public List<SubscriptionResult> subscriptions;
        public List<GenericResponseReason> reasons;
    }

    public class SubscriptionResult {
        public String subscriptionNumber;
        public String status;
    }

    // The SOAP response (wrapped around a REST API)
    // https://knowledgecenter.zuora.com/DC_Developers/G_SOAP_API/F_SOAP_API_Complex_Types/SaveResult
    public class SaveResult {
        public List<ErrorCode> Errors;
        public String Id;
        public Boolean Success;
    }

    // https://knowledgecenter.zuora.com/DC_Developers/G_SOAP_API/L_Error_Handling/Errors
    public class ErrorCode {
        public String Code;
        public String Message;
    }

    // https://www.zuora.com/developer/api-reference/#operation/Action_POSTquery
    public class ZuoraQuery {
        public String queryString;
    }

    // https://www.zuora.com/developer/api-reference/#operation/Action_POSTdelete
    public class ZuoraDelete {
        public List<String> ids;
        public String type;
    }

    // https://www.zuora.com/developer/api-reference/#operation/GET_OrdersBySubscriptionOwner
    public class OrderBySubscriptionOwner {
        public List<Order> orders;
        public Boolean success;

        public Boolean hasSubscription() {
            if (orders == null || orders.isEmpty()) {
                return false;
            }
            for (Order order : orders) {
                if (order.subscriptions != null && !order.subscriptions.isEmpty()) {
                    return true;
                }
            }
            return false;
        }

        public String getSubscriptionNumber() {
            for (Order order : orders) {
                if (order.subscriptions != null && !order.subscriptions.isEmpty()) {
                    return order.subscriptions[0].subscriptionNumber;
                }
            }
            throw new Util.BWException('Did not find a subscription in all of the orders');
        }

        public String getProductRatePlanChargeId(String clientName, String project) {
            for (ZuoraSubscriptionService.ClientProject cp : getClientProjectsFromOrders()) {
                if (cp.clientName == clientName && cp.projectName == project) {
                    return cp.productRatePlanChargeId;
                }
            }
            throw new Util.BWException('No client/project found for client: ' + clientName + ' and project '+ project);
        }

        public String getChargeNumber(String clientName, String project) {
            for (ZuoraSubscriptionService.ClientProject cp : getClientProjectsFromOrders()) {
                if (cp.clientName == clientName && cp.projectName == project) {
                    return cp.chargeNumber;
                }
            }
            throw new Util.BWException('No client/project found for client: ' + clientName + ' and project '+ project);
        }

        public Date getContractEffective() {
            for (Order order : orders) {
                if (order.subscriptions != null &&
                    !order.subscriptions.isEmpty() &&
                    order.subscriptions[0].getCreateSubscription() != null &&
                    order.subscriptions[0].getCreateSubscription().getContractEffective() != null) {
                    return order.subscriptions[0].getCreateSubscription().getContractEffective();
                }
            }
            throw new Util.BWException('Did not find a contract effective date in all of the orders');
        }

        public Set<ZuoraSubscriptionService.ClientProject> getClientProjectsFromOrders() {
            Set<ZuoraSubscriptionService.ClientProject> clientProjects = new Set<ZuoraSubscriptionService.ClientProject>();
            if (orders == null || orders.isEmpty()) {
                return clientProjects;
            }
            for (Order order : orders) {
                clientProjects.add(order.getClientProject());
            }
            return clientProjects;
        }
    }

    public class InvoiceWithItems {
        public Invoice invoice;
        public List<InvoiceItem> items;
    }

    public class Invoice {
        public String id;
        public String accountId;
        public Decimal amount;
        public Date invoiceDate;
        public Decimal balance;
        public String Body;
        public String InvoiceNumber;
    }

    public class InvoiceItem {
        public String id;
        public Decimal amount;
        public Decimal balance;
        public Decimal paymentAmount;
        public Decimal creditAmount;
        public String chargeDate;
        public String chargeId;
    }

    // Used to create, but not to query for credit memos:
    public class DebitMemo{
        public String accountId;
        public List<DebitMemoCharge> charges;
        public Date effectiveDate;
        public String reasonCode;
        public String CRM_ID_Zcustom;
        public String Project_Zcustom;
        public String ClientOwner_Zcustom;
    }

    public class DebitMemoCharge{
        public Decimal amount;
        public String chargeId;
    }

    // Used to query, but not to create credit memos:
    public class ZuoraDebitMemo {
        public String id;
        public String accountId;
        public Date debitMemoDate;
        public Decimal amount;
        public Decimal balance;
        public String Project_Zcustom;
        public String ClientOwner_Zcustom;
    }

    public class ZuoraDebitMemoItem {
        public String id;
        public Decimal balance;
    }

    public class DebitMemoWithItems {
        public ZuoraDebitMemo debitMemo;
        public List<ZuoraDebitMemoItem> items;
    }
}