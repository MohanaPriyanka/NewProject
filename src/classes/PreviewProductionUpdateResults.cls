/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is used with the ProductionUpdateHelper lightning component (used on the VF page ShowUASes)
 + * When the "Preview Bills" button is hit on a Production Update, this finds all related UASes and 
 + * calculates what their bill will be (NMCs allocated and then with 10% discount)
 + * 
 + * Tested By: TestBillCreationandPayment, ZuoraPaymentSelectorTest
 + *************************************************************************************/

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PreviewProductionUpdateResults{
    @AuraEnabled
    public static List<Schedule_Z__c> getScheduleZs (Id transferId) {
        Transfer__c transfer = [
          SELECT Id, Shared_Solar_System__c
          FROM Transfer__c
            WHERE Id = :transferId
            LIMIT 1
        ];

        List<Schedule_Z__c> scheduleZList = [
            SELECT Id, Name, Status__c
            FROM Schedule_Z__c
            WHERE Shared_Solar_System__c = : transfer.Shared_Solar_System__c
            AND (Status__c = 'Enacted By Utility' OR Status__c = 'Billing')
        ];

        return scheduleZList;
    }

    public static List<UASB__c> getCancelledBills (Id transferId, List<String> alreadyGeneratedList) {
        return getCancelledBills(transferId, alreadyGeneratedList, null);
    }

    @AuraEnabled
    public static List<UASB__c> getCancelledBills (Id transferId, List<String> alreadyGeneratedList, Id scheduleZId) {
        Map<Id, UASB__c> cancelledUASBs = new Map<Id, UASB__c>();

        Transfer__c transfer = [
            SELECT Id, Name, Date_of_Transfer__c, Shared_Solar_System__c, Allocation_Schedule__c, Default_Credit_Value__c,
                Attempted_Transfer__c, Total_kWh_Transferred__c, Bills_Generated__c, Bill_Period__r.Bill_Date__c
            FROM Transfer__c
            WHERE Id = :transferId
            LIMIT 1
        ];

        if (scheduleZId == null) {
            scheduleZId = transfer.Allocation_Schedule__c;
        }

        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal collectionsWindowDec = sysProp.Days_Generate_Bills_For_Cancelled__c;
        Decimal minimumBalance = sysProp.Minimum_Balance_Bills_for_Cancelled__c;
        Integer collectionsWindow = Integer.valueOf(Util.nullToZero(collectionsWindowDec));
        minimumBalance = Util.nullToZero(minimumBalance);

        Date todaysDate = transfer.Bill_Period__r.Bill_Date__c;
        Date maxPastDueDate = todaysDate.addDays(collectionsWindow * -1);

        for (UASB__c uasb : [
            SELECT Id, System_Bill__r.Unique_ID__c, System_Bill__r.Opportunity__r.Id, Utility_Account_Subscription__c,
                System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c,
                Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Utility_Account_Subscription__r.Name,
                Utility_Account_Subscription__r.Utility_Account_Log__r.Name,
                Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c,
                System_Bill__r.Account_Bill__r.Parent_Account__r.Account_Balance__c
            FROM UASB__c
            WHERE System_Bill__r.Shared_Solar_System__c = : transfer.Shared_Solar_System__c
            AND System_Bill__r.Balance_Net_Late_Payments__c > : minimumBalance
            AND System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c >= : maxPastDueDate
            AND Utility_Account_Subscription__r.Id NOT IN : alreadyGeneratedList
        ]) {
            UASB__c mockBill = new UASB__c(
                PreGen_IsPreGen__c = true,
                PreGen_Discounted_Bill__c = 0,
                PreGen_NMCs_Allocated__c = 0,
                PreGen_Name_on_Account__c = 'Cancelled: ' + uasb.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Transfer__c = null,
                PreGen_Schedule_Z_Status__c = uasb.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                PreGen_System_Share__c = 0,
                Utility_Account_Subscription__c = uasb.Utility_Account_Subscription__c,
                PreGen_Additional_Id__c = null,
                PreGen_Utility_Acct__c = uasb.Utility_Account_Subscription__r.Utility_Account_Log__r.Name
            );

            if (uasb.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c != null) {
                mockBill.PreGen_Additional_Id__c = uasb.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c;
            }

            Date dateOfLastCredit = uasb.System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c;
            mockBill.PreGen_CreditOnBillPeriod__c = String.valueOf(dateOfLastCredit);
            cancelledUASBs.put(mockBill.Utility_Account_Subscription__c, mockBill);
        }

        // Stop Credit Transfer subscriptions aren't cancelled, but they might not be billed if there's no balance so we
        // should show them here.
        String whereClause = 'Schedule_Z__c = :scheduleZId ' +
            ' AND Stop_Credit_Transfer__c = TRUE ';
        List<Schedule_Z_Subscription__c> stoppedSZS =
            Database.query(ScheduleZSubscriptionSelector.getQueryString(whereClause, null));
        for (Schedule_Z_Subscription__c szs : stoppedSZS) {
            UASB__c mockBill = new UASB__c(
                PreGen_IsPreGen__c = true,
                PreGen_Discounted_Bill__c = 0,
                PreGen_NMCs_Allocated__c = 0,
                PreGen_Name_on_Account__c = 'Stopped Credit Transfer: ' + szs.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                PreGen_Schedule_Z_Status__c = szs.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                PreGen_System_Share__c = 0,
                Utility_Account_Subscription__c = szs.Utility_Account_Subscription__c,
                PreGen_Additional_Id__c = null,
                PreGen_Utility_Acct__c = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Name
            );

            if (szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c != null) {
                mockBill.PreGen_Additional_Id__c = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c;
            }

            if (!szs.Utility_Account_Subscription_Bills__r.isEmpty()) {
                Date dateOfLastCredit = szs.Utility_Account_Subscription_Bills__r[0].System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c;
                mockBill.PreGen_CreditOnBillPeriod__c = String.valueOf(dateOfLastCredit);
            }
            cancelledUASBs.put(mockBill.Utility_Account_Subscription__c, mockBill);
        }

        return cancelledUASBs.values();
    }

    @AuraEnabled
    public static List<Account> getProperties (String parentAcctId, Boolean isParentAcct) {
        if ( isParentAcct ) {
            List<Account> accountList = [ SELECT Id, Name
            FROM Account
            WHERE Parent_Account_ID__c = : parentAcctId];
            return accountList;
        } else {
            List<Account> accountList = [ SELECT Id, Name
            FROM Account
            WHERE Id = : parentAcctId];
            return accountList;
        }
    }

    @AuraEnabled
    public static List<UASB__c> getUASes (String parentId, Boolean isTransfer, String scheduleZId) {
        List<UASB__c> newBillList = new List<UASB__c> ();
        if (isTransfer) {
            Transfer__c transfer = TransferSelector.getTransferById(parentId);

            Schedule_Z__c scheduleZ = [
                SELECT Id, Shared_Solar_System__r.Billing_Anchors__c, Shared_Solar_System__r.Count_of_Transfers__c

                FROM Schedule_Z__c
                WHERE Id = : scheduleZId
                AND Shared_Solar_System__c = : transfer.Shared_Solar_System__c
                LIMIT 1
            ];

            List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(new Set<Id>{scheduleZ.Id});
            for (Schedule_Z_Subscription__c szs: szsList) {
                if (szs.Customer_Subscription_kW_DC__c != NULL) {
                    UASB__c newBill = getUASB(szs, transfer, 1, transfer.Attempted_Transfer__c, transfer.Attempted_kWh_Transfer__c, transfer.Default_Credit_Value__c);
                    newBillList.add(newBill);
                }
            }
            return newBillList;
        } else {
            List<Id> sssList = new List<Id>();
            String whereClause = 'Utility_Account_Subscription__r.Utility_Account_Log__r.Account__r.Id = : parentId';
            List<Schedule_Z_Subscription__c> szsListFromAcct =
                Database.query(ScheduleZSubscriptionSelector.getQueryString(whereClause, null));
            for (Schedule_Z_Subscription__c szs : szsListFromAcct) {
                sssList.add(szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c);
            }

            List<Transfer__c> transferList = TransferSelector.getAllTransfersBySSS(sssList);
            Integer transferCount = 0;
            for (Schedule_Z_Subscription__c szs : szsListFromAcct) {
                for (Transfer__c transfer : transferList) {
                    transferCount += 1;
                    if (szs.Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Id == transfer.Shared_Solar_System__r.Id
                        && !transfer.Bills_Generated__c) {

                        UASB__c newBill = getUASB(szs, transfer, transferCount, transfer.Attempted_Transfer__c, transfer.Attempted_kWh_Transfer__c, transfer.Default_Credit_Value__c);
                        newBill.PreGen_Production_Update__c =  transfer.Name;
                        newBillList.add(newBill);
                    }
                }
            }
            List<UASB__c> oldBillList = new List<UASB__c> ();
            List<UASB__C> uasbList = [  SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
                Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Utility_Account_Subscription__r.Share_of_System__c, Externally_Serviced__c,
                Transfer__r.Name, Credits_on_Bill_Period__c,
                Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
                Subscription_Production_kWh__c, Transfer__c
            FROM UASB__c
            WHERE System_Bill__r.Property_Account_ID__c = : parentId
            ORDER BY Date__c DESC];

            for (UASB__c oldBill : uasbList) {
                UASB__c modifiedBill = new UASB__c (
                    PreGen_IsPreGen__c = True,
                    PreGen_Discounted_Bill__c = oldBill.Discounted_Bill__c,
                    PreGen_NMCs_Allocated__c = oldBill.Net_Metering_Credits_Allocated__c,
                    PreGen_Subscription_Production__c = oldBill.Subscription_Production_kWh__c,
                    PreGen_Name_on_Account__c = oldBill.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                    PreGen_Production_Update__c = oldBill.Transfer__r.Name,
                    Utility_Account_Subscription__c = oldBill.Id,
                    Externally_Serviced__c = oldBill.Externally_Serviced__c,
                    PreGen_CreditOnBillPeriod__c = oldBill.Credits_on_Bill_Period__c,
                    PreGen_Schedule_Z_Status__c = oldBill.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                    PreGen_System_Share__c =  oldBill.Utility_Account_Subscription__r.Share_of_System__c.setScale(4),
                    PreGen_Utility_Acct__c = oldBill.Utility_Account_Subscription__r.Name
                );
                if (oldBill.Externally_Serviced__c) {
                    modifiedBill.PreGen_Name_on_Account__c = 'Externally Serviced: ' + oldBill.Utility_Account_Subscription__r.Name_on_Account_From_Log__c;
                } else {
                    modifiedBill.PreGen_Name_on_Account__c = oldBill.Utility_Account_Subscription__r.Name_on_Account_From_Log__c;

                }
                newBillList.add(modifiedBill);
            }
            return newBillList;
        }
    }

    public class TransactionDetail {
        @AuraEnabled
        public Id SFRecordId;
        @AuraEnabled
        public String TransactionNumber;
        @AuraEnabled
        public Date PaymentDate;
        @AuraEnabled
        public Decimal PaymentAmount;
        @AuraEnabled
        public String PaymentMethod;
    @AuraEnabled
        public String PaymentType;
        @AuraEnabled
        public String ResponseStatus;
        @AuraEnabled
        public String AutopayStatus;
    }

    @AuraEnabled
    public static List<TransactionDetail> getTransactions (List<Account> accountLookup) {
        List<Id> propertyAccountIds = new List<Id>();
        List<TransactionDetail> transactionDetailList = new List<TransactionDetail>();
        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();

        for (Account propAccount : accountLookup){
            propertyAccountIds.add(propAccount.Id);
        }

        if (zuoraSetting.Zuora_Is_Live__c) {
            List<Zuora__Payment__c> zuoraPayments = ZuoraPaymentSelector.selectByAccount(propertyAccountIds);

            for (Zuora__Payment__c zPayment : zuoraPayments){
                TransactionDetail zuoraPayment = new TransactionDetail();
                zuoraPayment.SFRecordId = zPayment.Id;
                zuoraPayment.TransactionNumber = zPayment.Name;
                zuoraPayment.PaymentDate = Date.valueOf(zPayment.Zuora__Effective_Date__c);
                zuoraPayment.PaymentAmount = zPayment.Zuora__Amount__c;
                zuoraPayment.PaymentMethod = zPayment.Zuora__PaymentMethod__c;
                zuoraPayment.PaymentType = zPayment.Zuora__Type__c;
                zuoraPayment.ResponseStatus = zPayment.Zuora__Status__c;
                zuoraPayment.AutopayStatus = 'Account: ' + String.valueOf(zPayment.Zuora__BillingAccount__r.Zuora__AutoPay__c);
                transactionDetailList.add(zuoraPayment);
            }
        } else {
            List<ChargentOrders__Transaction__c> transactionList = [
                SELECT Name, Id, ChargentOrders__Gateway_Date__c,
            ChargentOrders__Amount__c,
            ChargentOrders__Response_Status__c,
            ChargentOrders__Gateway__r.Name,
            ChargentOrders__Order__r.Name,
            ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
                    ChargentOrders__Order__r.ChargentOrders__Payment_Method__c,
                    ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id
        FROM ChargentOrders__Transaction__c
                WHERE ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id IN : propertyAccountIds
        ORDER BY  ChargentOrders__Gateway_Date__c DESC];

            for (ChargentOrders__Transaction__c chTransaction : transactionList){
                TransactionDetail chargentTransaction = new TransactionDetail();
                chargentTransaction.SFRecordId = chTransaction.Id;
                chargentTransaction.TransactionNumber = chTransaction.Name;
                chargentTransaction.PaymentDate = Date.valueOf(chTransaction.ChargentOrders__Gateway_Date__c);
                chargentTransaction.PaymentAmount = chTransaction.ChargentOrders__Amount__c;
                chargentTransaction.PaymentMethod = chTransaction.ChargentOrders__Order__r.Name;
                chargentTransaction.PaymentType = chTransaction.ChargentOrders__Order__r.ChargentOrders__Payment_Method__c;
                chargentTransaction.ResponseStatus = chTransaction.ChargentOrders__Response_Status__c;
                chargentTransaction.AutopayStatus = chTransaction.ChargentOrders__Order__r.ChargentOrders__Payment_Status__c;
                transactionDetailList.add(chargentTransaction);
            }
        }
        return transactionDetailList;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static UASB__c getUASB(Schedule_Z_Subscription__c szs, Transfer__c transfer, Decimal productionCount, Decimal totalNMCs, Decimal totalProduction, Decimal nmcRate){
        UASB__c billFields = UtilityAccountBillTriggerHandler.setUASBFields(transfer, szs, productionCount, nmcRate, totalProduction, totalNMCs);

        Decimal discountedBill = 0;
        if (szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c == 'Use Solar Electric Rate'){
            discountedBill = (szs.Percent_Share__c.setScale(4)/100 * totalProduction)*szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c;
        } else {
            discountedBill = (szs.Percent_Share__c.setScale(4)/100 * totalNMCs)*(1-(szs.Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c/100));
        }

        UASB__c newBill = new UASB__c (
            PreGen_IsPreGen__c = transfer.Bills_Generated__c,
            PreGen_Discounted_Bill__c = discountedBill.setScale(2),
            PreGen_Subscription_Production__c = billFields.Subscription_Production_kWh_Static__c,
            PreGen_NMCs_Allocated__c = billFields.Credits_Allocated__c,
            Utility_Account_Subscription__c = szs.Utility_Account_Subscription__c,
            Schedule_Z_Subscription__c = szs.Id,
            Externally_Serviced__c = billFields.Externally_Serviced__c,
            PreGen_Production_Update__c = transfer.Bill_Period__r.Name,
            PreGen_Schedule_Z_Status__c = szs.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
            PreGen_System_Share__c = billFields.Share_of_System__c,
            PreGen_Utility_Acct__c = szs.Utility_Account_Subscription__r.Name
        );
        if (billFields.Externally_Serviced__c){
            newBill.PreGen_Name_on_Account__c = 'Externally Serviced: ' + szs.Utility_Account_Subscription__r.Name_on_Account_From_Log__c;
        } else{
            newBill.PreGen_Name_on_Account__c = szs.Utility_Account_Subscription__r.Name_on_Account_From_Log__c;

        }

        if (szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c != null) {
            newBill.PreGen_Additional_Id__c = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c;
        }
        return newBill;
    }

    @AuraEnabled
    public static void saveAllocationScheduleToTransfer(Id scheduleZId, String transferId) {
        Transfer__c transfer = [
            SELECT Id, Allocation_Schedule__c, Shared_Solar_System__c
            FROM Transfer__c
            WHERE Id = :transferId
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = [
            SELECT Id, Status__c
            FROM Schedule_Z__c
            WHERE Id = : scheduleZId
            AND Shared_Solar_System__c = : transfer.Shared_Solar_System__c
            LIMIT 1
        ];

        if (scheduleZ != null) {
            transfer.Allocation_Schedule__c = scheduleZ.Id;

            update transfer;

            if (scheduleZ.Status__c != 'Billing') {
                List<Schedule_Z__c> scheduleZs = [
                    SELECT Id, Status__c
                    FROM Schedule_Z__c
                    WHERE Shared_Solar_System__c = : transfer.Shared_Solar_System__c
                    AND Id != : scheduleZ.Id
                    AND Status__c = 'Billing'
                ];
                for (Schedule_Z__c schedZ : scheduleZs) {
                    schedZ.Status__c = 'Replaced';
                }
                scheduleZ.Status__c = 'Billing';
                scheduleZs.add(scheduleZ);
                update scheduleZs;
            }
        }
    }
}