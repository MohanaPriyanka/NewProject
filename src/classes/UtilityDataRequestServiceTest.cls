/**
 * @description Created by: Kristin White on 9/29/2020
 */
@IsTest
private class UtilityDataRequestServiceTest {

    private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();

    @TestSetup
    public static void setupData() {
        Partner__c testPartner = new Partner__c(
            Name = 'Default CS Partner',
            Email__c = 'default@email.com'
        );
        insert testPartner;
        TestFactory.setDefaultCSPartner(testPartner.Id);

        Utility__c testUtility = new Utility__c(
            Name = 'testUtility',
            Utility_DUNS_Number__c = '1234567890',
            Utility_Data_Collection_Mechanism__c = 'EDI',
            Collect_Customer_POD_Number__c = true,
            Auto_QC_Maximum_Demand__c = 25,
            Auto_QC_Minimum_kWH__c = 1000
        );
        insert testUtility;

        State__c stateMA = new State__c(
            Name = 'MA',
            Avg_Annual_Resi_kWh__c = 165200
        );
        insert stateMA;

        Product2 testProduct = new Product2(
            Name = 'testProduct',
            X4_month_sizing_method__c = 'State Average Annual Usage'
        );
        insert testProduct;

        Lead nonResiLead = new Lead(
            Product__c = testProduct.Id,
            Customer_type__c = 'Commercial',
            LastName = 'testLead1',
            Company = 'testBlueWave1',
            Partner_Lookup__c = testPartner.Id,
            Utility_relationship__c = testUtility.Id
        );
        Lead resiLead = new Lead(
            Product__c = testProduct.Id,
            Customer_type__c = 'Residential',
            LastName = 'testLead2',
            Company = 'testBlueWave2',
            Partner_Lookup__c = testPartner.Id
        );
        List<Lead> testLeadList = new List<Lead>{
            nonResiLead, resiLead
        };
        insert testLeadList;

        Utility_Account_Log__c testUAL1 = new Utility_Account_Log__c(
            Lead__c = resiLead.Id,
            Utility_lookup__c = testUtility.Id,
            Username__c = 'testUAL1',
            Name_on_Account__c = 'Tom',
            Service_Address__c = '66 Mass Ave',
            Service_City__c = 'Boston',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02115'
        );
        Utility_Account_Log__c testUAL2 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = resiLead.Id,
            Username__c = 'testUAL2',
            Name_on_Account__c = 'Tim',
            Service_Address__c = '32 Quincy St, apt 20',
            Service_City__c = 'Cambridge',
            Service_State__c = 'ma',
            Service_Zip_Code__c = '02138'
        );
        Utility_Account_Log__c testUAL3 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = nonResiLead.Id,
            Username__c = 'testUAL3',
            Name_on_Account__c = 'Jim',
            Service_Address__c = '249 Pearl St.',
            Service_City__c = 'Somerville',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02145'
        );
        Utility_Account_Log__c testUAL4 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = resiLead.Id,
            Username__c = 'testUAL4',
            Name_on_Account__c = 'Bill',
            Service_Address__c = '459  Broadway',
            Service_City__c = 'Everett',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02149'
        );
        Utility_Account_Log__c testUAL5 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = resiLead.Id,
            Username__c = 'testUAL5',
            Name_on_Account__c = 'Bob',
            Service_Address__c = '1 brighton ave, 20',
            Service_City__c = 'Allston',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02134'
        );
        Utility_Account_Log__c testUAL6 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = resiLead.Id,
            Username__c = 'testUAL6',
            Name_on_Account__c = 'Kris',
            Service_Address__c = '32 Quincy St, apt 20',
            Service_City__c = 'Cambridge',
            Service_State__c = 'ma',
            Service_Zip_Code__c = '02138'
        );
        Utility_Account_Log__c testUAL7 = new Utility_Account_Log__c(
            Utility_lookup__c = testUtility.Id,
            Lead__c = resiLead.Id,
            Username__c = 'testUAL7',
            Name_on_Account__c = 'Kristin',
            Service_Address__c = '30 Bow St',
            Service_City__c = 'Boston',
            Service_State__c = 'Ma',
            Service_Zip_Code__c = '02118'
        );
        insert new List<Utility_Account_Log__c>{
            testUAL1, testUAL2, testUAL3, testUAL4, testUAL5, testUAL6, testUAL7
        };

        Utility_Data_Request__c testUDR1 = getPendingTestUDR(testUAL1, 'testUDR1', testUtility, 'Tom', '#66 Mass. Ave. ', '', 'boston', 'Ma.', '   02115  ');
        Utility_Data_Request__c testUDR2 = getPendingTestUDR(testUAL2, 'testUDR2', testUtility, 'Tim', '32 Quincy St,', 'Apt 20', 'Combridge', 'MA', '02138 ');
        testUDR2.Header_Status__c = 'Complete';
        testUDR2.Detail_Status__c = 'Complete';
        Utility_Data_Request__c testUDR3 = getPendingTestUDR(testUAL3, 'testUDR3', testUtility, 'Jim', '249 Pearl St', '', 'Somerville', 'MA', '02145');
        testUDR3.LDC_Customer_Eligibility__c = 'Y';
        Utility_Data_Request__c testUDR4 = getPendingTestUDR(testUAL4, 'testUDR4', testUtility, 'Bill', '458 Broadway', '', 'Everett', 'MA', '02149');
        testUDR4.Government_Credit_Code__c = 'Y';
        Utility_Data_Request__c testUDR5 = getPendingTestUDR(testUAL5, 'testUDR5', testUtility, 'Bob', '1 Brighton Ave', 'Unit 20', 'Allston', 'Ma', '02134');
        testUDR5.Government_Credit_Code__c = 'Y';
        testUDR5.LDC_Customer_Eligibility__c = 'Y';
        Utility_Data_Request__c testUDR6 = getPendingTestUDR(testUAL6, 'testUDR6', testUtility, 'Kris', '32 Quincy St,', 'Apt 20', 'Combridge', 'MA', '02138 ');
        Utility_Data_Request__c testUDR7 = getPendingTestUDR(testUAL7, 'testUDR7', testUtility, 'kristin', '30 bow st,', '', ' boston', 'ma', '02118 ');
        insert new List<Utility_Data_Request__c>{
            testUDR1, testUDR2, testUDR3, testUDR4, testUDR5, testUDR6, testUDR7
        };

        Rate_Class__c testRateClass1 = new Rate_Class__c(
            EDI_Rate_Class__c = 'Test EDI Rate Class 1',
            Name = 'testRateClass1',
            Utility__c = testUtility.Id
        );
        Rate_Class__c testRateClass2 = new Rate_Class__c(
            EDI_Rate_Class__c = 'Test EDI Rate Class 2',
            Name = 'testRateClass2',
            Utility__c = testUtility.Id
        );
        List<Rate_Class__c> testRateClassList = new List<Rate_Class__c>{
            testRateClass1, testRateClass2
        };
        insert testRateClassList;

        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>();
        addUDRPsForUDR1(testUDRPList, testUDR1);
        addUDRPsForUDR2(testUDRPList, testUDR2);
        addUDRPsForUDR3(testUDRPList, testUDR3);
        addUDRPsForUDR4(testUDRPList, testUDR4);
        addUDRPsForUDR5(testUDRPList, testUDR5);
        addUDRPsForUDR7(testUDRPList, testUDR7);

        insert testUDRPList;
    }

    private static void addUDRPsForUDR7(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR7) {
        addTestUDRP(testUDRPList, testUDR7, 'testUDRP49', 'KH', '41', 25, Date.newInstance(2020, 1, 1), Date.newInstance(2020, 2, 1));
        addTestUDRP(testUDRPList, testUDR7, 'testUDRP50', 'KH', '42', 50, Date.newInstance(2020, 2, 2), Date.newInstance(2020, 3, 2));
        addTestUDRP(testUDRPList, testUDR7, 'testUDRP51', 'KH', '43', 75, Date.newInstance(2020, 3, 3), Date.newInstance(2020, 4, 3));
        addTestUDRP(testUDRPList, testUDR7, 'testUDRP52', 'K1', '42', 100, Date.newInstance(2020, 4, 3), Date.newInstance(2020, 4, 12));
        addTestUDRP(testUDRPList, testUDR7, 'testUDRP53', 'K1', '49', 100, Date.newInstance(2020, 5, 3), Date.newInstance(2020, 6, 12));
    }

    private static void addUDRPsForUDR5(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR5) {
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP11', 'KH', '51', 6789, Date.newInstance(2020, 10, 3), Date.newInstance(2020, 11, 4));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP12', 'KH', '51', 8311, Date.newInstance(2019, 2, 22), Date.newInstance(2019, 2, 24));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP13', 'KH', '51', 11111, Date.newInstance(2020, 9, 10), Date.newInstance(2020, 10, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP14', 'KH', '51', 53977, Date.newInstance(2020, 8, 3), Date.newInstance(2020, 9, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP15', 'KH', '51', 2525, Date.newInstance(2020, 7, 10), Date.newInstance(2020, 8, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP16', 'KH', '51', 9222, Date.newInstance(2020, 6, 28), Date.newInstance(2020, 7, 28));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP17', 'KH', '51', 88, Date.newInstance(2020, 5, 2), Date.newInstance(2020, 6, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP18', 'KH', '51', 417, Date.newInstance(2020, 4, 17), Date.newInstance(2020, 5, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP19', 'KH', '51', 4399, Date.newInstance(2020, 3, 20), Date.newInstance(2020, 4, 25));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP20', 'KH', '51', 2019, Date.newInstance(2020, 2, 19), Date.newInstance(2020, 3, 20));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP21', 'KH', '51', 334455, Date.newInstance(2020, 1, 1), Date.newInstance(2020, 2, 1));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP22', 'KH', '51', 19788, Date.newInstance(2020, 1, 2), Date.newInstance(2020, 2, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP23', 'KH', '51', 764655, Date.newInstance(2019, 2, 19), Date.newInstance(2019, 3, 20));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP24', 'KH', '51', 42789, Date.newInstance(2020, 4, 27), Date.newInstance(2020, 5, 25));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP35', 'K1', '51', 3322, Date.newInstance(2020, 10, 3), Date.newInstance(2020, 11, 4));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP36', 'K1', '51', 311, Date.newInstance(2019, 2, 22), Date.newInstance(2020, 3, 21));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP37', 'K1', '51', 1211, Date.newInstance(2020, 9, 10), Date.newInstance(2020, 10, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP38', 'K1', '51', 4181, Date.newInstance(2020, 8, 3), Date.newInstance(2020, 9, 4));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP39', 'K1', '51', 2626, Date.newInstance(2020, 7, 10), Date.newInstance(2020, 8, 11));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP40', 'K1', '51', 6565, Date.newInstance(2020, 6, 28), Date.newInstance(2020, 7, 28));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP41', 'K1', '51', 66, Date.newInstance(2020, 5, 2), Date.newInstance(2020, 6, 3));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP42', 'K1', '51', 400, Date.newInstance(2020, 4, 17), Date.newInstance(2020, 5, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP43', 'K1', '51', 582, Date.newInstance(2020, 3, 21), Date.newInstance(2020, 4, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP44', 'K1', '51', 2020, Date.newInstance(2020, 2, 20), Date.newInstance(2020, 3, 21));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP45', 'K1', '51', 345, Date.newInstance(2020, 1, 2), Date.newInstance(2020, 2, 1));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP46', 'K1', '51', 777, Date.newInstance(2020, 1, 2), Date.newInstance(2020, 2, 10));
        addTestUDRP(testUDRPList, testUDR5, 'testUDRP47', 'K1', '51', 10, Date.newInstance(2015, 1, 2), Date.newInstance(2015, 2, 3));
    }

    private static void addUDRPsForUDR4(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR4) {
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP8', 'KH', '51', 4387, Date.newInstance(2020, 5, 20), Date.newInstance(2020, 6, 20));
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP9', 'KH', '51', 999, Date.newInstance(2020, 5, 20), Date.newInstance(2020, 5, 19));
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP10', 'KH', '51', 9757, Date.newInstance(2020, 8, 28), Date.newInstance(2020, 9, 25));
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP32', 'K1', '51', 9122, Date.newInstance(2019, 5, 20), Date.newInstance(2020, 5, 25));
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP33', 'K1', '51', 429, Date.newInstance(2020, 5, 20), Date.newInstance(2020, 6, 20));
        addTestUDRP(testUDRPList, testUDR4, 'testUDRP34', 'K1', '51', 832, Date.newInstance(2020, 8, 28), Date.newInstance(2020, 9, 28));
    }

    private static void addUDRPsForUDR3(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR3) {
        addTestUDRP(testUDRPList, testUDR3, 'testUDRP7', 'KH', '51', 12099, Date.newInstance(2020, 9, 1), Date.newInstance(2020, 9, 10));
        addTestUDRP(testUDRPList, testUDR3, 'testUDRP30', 'K1', '51', 99, Date.newInstance(2020, 9, 2), Date.newInstance(2020, 10, 4));
        addTestUDRP(testUDRPList, testUDR3, 'testUDRP31', 'K1', '51', 999, Date.newInstance(2020, 9, 12), Date.newInstance(2020, 10, 13));
    }

    private static void addUDRPsForUDR2(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR2) {
        Utility_Data_Request_Period__c testUDRP6 = addTestUDRP(testUDRPList, testUDR2, 'testUDRP6', 'KH', '51', 1234, Date.newInstance(2020, 9, 14), Date.newInstance(2020, 10, 14));
        testUDRP6.Rate_Class__c = 'Test EDI Rate Class 2';
        testUDRP6.Rate_Subclass__c = 'Test EDI Rate Class 2';
    }

    private static void addUDRPsForUDR1(List<Utility_Data_Request_Period__c> testUDRPList, Utility_Data_Request__c testUDR1) {
        addTestUDRP(testUDRPList, testUDR1, 'testUDRP1', 'KH', '51', 25, Date.newInstance(2020, 5, 10), Date.newInstance(2020, 6, 10));
        Utility_Data_Request_Period__c testUDRP2 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP2', 'KH', '51', 101, Date.newInstance(2020, 7, 7), Date.newInstance(2020, 8, 7));
        testUDRP2.Rate_Class__c = 'Test EDI Rate Class 2';
        testUDRP2.Rate_Subclass__c = 'Test EDI Rate Class 2';
        Utility_Data_Request_Period__c testUDRP3 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP3', 'KH', '51', 6914, Date.newInstance(2020, 10, 12), Date.newInstance(2020, 11, 11));
        testUDRP3.Rate_Class__c = 'Test EDI Rate Class 2';
        testUDRP3.Rate_Subclass__c = 'Test EDI Rate Class 2';
        Utility_Data_Request_Period__c testUDRP4 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP4', 'KH', '51', 50, Date.newInstance(2020, 9, 15), Date.newInstance(2020, 10, 1));
        testUDRP4.Rate_Class__c = null;
        testUDRP4.Rate_Subclass__c = null;
        Utility_Data_Request_Period__c testUDRP5 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP5', 'KH', '51', 7003, Date.newInstance(2020, 2, 1), Date.newInstance(2020, 2, 10));
        testUDRP5.Rate_Class__c = 'Nonexistent/Misspelled EDI';
        testUDRP5.Rate_Subclass__c = 'Nonexistent/Misspelled EDI';
        addTestUDRP(testUDRPList, testUDR1, 'testUDRP25', 'K1', '51', 3690, Date.newInstance(2020, 5, 11), Date.newInstance(2020, 6, 10));
        addTestUDRP(testUDRPList, testUDR1, 'testUDRP26', 'K1', '51', 923, Date.newInstance(2020, 7, 7), Date.newInstance(2020, 8, 10));
        Utility_Data_Request_Period__c udrp27 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP27', 'K1', '51', 100, Date.newInstance(2020, 10, 12), Date.newInstance(2020, 11, 11));
        udrp27.Rate_Class__c = 'Test EDI Rate Class 2';
        udrp27.Rate_Subclass__c = 'Test EDI Rate Class 2';
        Utility_Data_Request_Period__c udrp28 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP28', 'K1', '51', 51, Date.newInstance(2020, 9, 16), Date.newInstance(2020, 10, 17));
        udrp28.Rate_Class__c = null;
        udrp28.Rate_Subclass__c = null;
        Utility_Data_Request_Period__c udrp29 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP29', 'K1', '51', 7000, Date.newInstance(2020, 2, 1), Date.newInstance(2020, 3, 2));
        udrp29.Rate_Class__c = 'Nonexistent/Misspelled EDI';
        udrp29.Rate_Subclass__c = 'Nonexistent/Misspelled EDI';
        Utility_Data_Request_Period__c udrp48 = addTestUDRP(testUDRPList, testUDR1, 'testUDRP48', 'KH', '51', 25, Date.newInstance(2018, 5, 1), Date.newInstance(2018, 6, 10));
        udrp48.Rate_Subclass__c = null;
    }

    private static Utility_Data_Request_Period__c addTestUDRP(List<Utility_Data_Request_Period__c> testUDRPList,
        Utility_Data_Request__c testUDR1, String loadProfileDescription,
        String measurementUnit, String significanceCode, Decimal quantity, Date serviceStart, Date serviceEnd) {
        Utility_Data_Request_Period__c testUDRP = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id,
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = loadProfileDescription,
            Service_Start_Date__c = serviceStart,
            Service_End_Date__c = serviceEnd,
            Measurement_Unit__c = measurementUnit,
            Quantity__c = quantity,
            Measurement_Significance_Code__c = significanceCode
        );
        testUDRPList.add(testUDRP);
        return testUDRP;
    }

    private static Utility_Data_Request__c getPendingTestUDR(Utility_Account_Log__c testUAL1, String oldAccountNumber,
        Utility__c testUtility, String name, String addressLine1, String addressLine2, String city, String state, String zip) {
        Utility_Data_Request__c testUDR1 = new Utility_Data_Request__c(
            Header_Status__c = 'Pending',
            Detail_Status__c = 'Pending',
            Old_Account_Number__c = oldAccountNumber,
            Utility_Account_Log__c = testUAL1.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'N',
            LDC_Customer_Eligibility__c = 'N',
            Customer_Name__c = name,
            Address_Line_1__c = addressLine1,
            Address_Line_2__c = addressLine2,
            City__c = city,
            State__c = state,
            Zip_Code__c = zip
        );
        return testUDR1;
    }

    private static Utility_Data_Request__c getTestUDR(String customerName) {
        return [
            SELECT Id, Request_Status_new__c, Header_Status__c, Detail_Status__c, Customer_Name__c, State__c, Utility__c, Annual_kWh__c, Average_Demand__c,
                Utility_Account_Log__c, Utility_Account_Log__r.Utility_Rate_Class__c, Old_Account_Number__c,
                Num_UDRPs_Annual_kWh__c, Num_UDRPs_Avg_Demand__c, Government_Credit_Code__c, LDC_Customer_Eligibility__c
            FROM Utility_Data_Request__c
            WHERE Old_Account_Number__c = :customerName
        ];
    }

    private static Utility_Account_Log__c getTestUAL(Id ualId) {
        return [
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Average_Demand__c, Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name,
                Num_UDRPs_Annual_kWh__c, Num_UDRPs_Avg_Demand__c, NYPA__c, RNY__c, Address_Update__c,
                Username__c, Previous_Name_on_Utility_Account__c, Previous_Service_Address__c, QC_Status__c,
                Previous_Service_City__c, Previous_Service_State__c, Previous_Service_Zip_Code__c,
                Auto_QC_Reject_Reason__c, Utility_lookup__r.Auto_QC_Maximum_Demand__c, Utility_lookup__r.Auto_QC_Minimum_kWH__c
            FROM Utility_Account_Log__c
            WHERE Id = :ualId
        ];
    }

    private static Utility_Data_Request_Period__c getTestUDRP(String udrp) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c,
                Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
                Rate_Subclass__c, Load_Profile_Description__c, Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c
            WHERE Load_Profile_Description__c = :udrp
        ];
    }

    private static List<Utility_Data_Request_Period__c> getTestUDRPList(Id udrId) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c,
                Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
                Rate_Subclass__c, Load_Profile_Description__c, Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c
            WHERE Utility_Data_Request__c = :udrId
        ];
    }

    private static Rate_Class__c getTestRateClass(String name) {
        return [
            SELECT Id, Name, EDI_Rate_Class__c, Utility__c
            FROM Rate_Class__c
            WHERE Name = :name
        ];
    }

    private static Lead getTestLead(String lastName) {
        return [
            SELECT Id, (
                SELECT Id, Name, Utility_lookup__c, Utility_lookup__r.Utility_DUNS_Number__c, Utility_lookup__r.Name
                FROM Utility_Account_Logs__r
            )
            FROM Lead
            WHERE LastName = 'testLead1'
        ];
    }

    private static Integer udrCount(Id ualId) {
        return [
            SELECT COUNT()
            FROM Utility_Data_Request__c
            WHERE Utility_Account_Log__c = :ualId
        ];
    }

    @IsTest
    static void testRateClass() {
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Method__c, Message__c, Severity__c
            FROM Error_Log__c
            WHERE Class__c = 'UtilityDataRequestService'
        ];
        System.assertEquals(0, errorLogs.size());

        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Header_Status__c = 'Complete';
        testUDR1.Detail_Status__c = 'Complete';
        update testUDR1;

        Utility_Account_Log__c testUAL1 = getTestUAL(testUDR1.Utility_Account_Log__c);
        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR1.Id);

        Rate_Class__c testRateClass1 = getTestRateClass('testRateClass1');
        Rate_Class__c testRateClass2 = getTestRateClass('testRateClass2');

        System.assertEquals(testRateClass1.Id, testUDRPList[0].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[0].Load_Profile_Description__c + ' should now be testRateClass1.');
        System.assertEquals(testRateClass2.Id, testUDRPList[1].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[1].Load_Profile_Description__c + ' should now be testRateClass2.');
        System.assertEquals(testRateClass2.Id, testUDRPList[2].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[2].Load_Profile_Description__c + ' should now be testRateClass2.');
        System.assertEquals(null, testUDRPList[3].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[3].Load_Profile_Description__c + ' should be null because '
                + 'the Rate_Class__c text was null, so no Rate Class object could be found for it.');
        System.assertEquals(null, testUDRPList[4].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[4].Load_Profile_Description__c + ' should be null because '
                + 'the Rate_Class__c text did not match any Rate_Class__c.EDI_Rate_Class__c fields');
        System.assertEquals(testUAL1.Utility_Rate_Class__c, testUDRPList[2].Rate_Class_Lookup__c,
            'The "Rate Class" (Utility_Rate_Class__c) for the UAL on testUDR1 should be the same as the Rate Class for testUDRP3,'
                + 'becuase testUDRP3 has the most recent Service Start Date of the all UDRPs for testUDR1.');
        System.assertEquals(testRateClass1.Id, testUDRPList[5].Rate_Class_Lookup__c,
            'The Rate_Class_Lookup__c for ' + testUDRPList[5].Load_Profile_Description__c + ' should now be testRateClass1.');
    }

    @IsTest
    static void updateStatusToNotComplete() {
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        System.assertEquals(testUDR1.Detail_Status__c, 'Pending', 'Expect detail status to be pending');
        testUDR1.Header_Status__c = 'Complete';
        update testUDR1;
        testUDR1 = [SELECT Id, Request_Status_new__c FROM Utility_Data_Request__c WHERE Id = :testUDR1.Id];
        System.assertEquals(testUDR1.Request_Status_new__c, 'Partial Data Received',
            'Expect request status to be partial data received because details have not been returned');

        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR1.Id);
        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, null,
            'The Rate_Class_Lookup__c for testUDRP1 should still be null becuase '
                + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[1].Rate_Class_Lookup__c, null,
            'The Rate_Class_Lookup__c for testUDRP2 should still be null becuase '
                + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[2].Rate_Class_Lookup__c, null,
            'The Rate_Class_Lookup__c for testUDRP3 should still be null becuase '
                + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[3].Rate_Class_Lookup__c, null,
            'The Rate_Class_Lookup__c for testUDRP4 should still be null becuase '
                + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[4].Rate_Class_Lookup__c, null,
            'The Rate_Class_Lookup__c for testUDRP5 should still be null becuase '
                + 'the status on the related UDR was not updated to Complete.');
    }

    @IsTest
    static void updateNotStatus() {
        Utility_Data_Request__c testUDR2 = getTestUDR('testUDR2');
        testUDR2.State__c = 'GA';
        update testUDR2;

        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR2.Id);

        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, null,
            'testUDRP6 is related to testUDR2, whose status was already Complete before the update,'
                + ' so the EDI_Rate_Class should still be null becuase the status did not update to complete,');
    }

    @IsTest
    static void testNullRecentUDRP() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c WHERE Class__c = 'UtilityDataRequestService'];
        System.assertEquals(0, errorLogs.size());

        Utility_Data_Request_Period__c testUDRP4 = getTestUDRP('testUDRP4');
        testUDRP4.Service_Start_Date__c = Date.newInstance(2020, 12, 20);
        update testUDRP4;

        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Header_Status__c = 'Complete';
        testUDR1.Detail_Status__c = 'Complete';
        update testUDR1;

        System.assertEquals(null, testUDR1.Utility_Account_Log__r.Utility_Rate_Class__c,
            'The most recent UDRP has a null Rate Class, so the Utility_Rate_Class__c on  UAL should still be null'
        );
    }

    @IsTest
    static void testUALUpdateForAboveMaxAvgDemand() {
        // Run test
        Utility_Data_Request__c udr = getTestUDR('testUDR1');
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify results
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);
        udr = getTestUDR('testUDR1');

        // Check UDR fields
        System.assertEquals(31613.93, udr.Annual_kWh__c, 'UDR1 has 5 KH UDRP so the Annual kWh should be '
            + 'the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 365.');
        System.assertEquals(2205.75, udr.Average_Demand__c, 'UDR1 has 5 K1 UDRP so the Average Demand should be '
            + 'the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 30.');
        System.assertEquals(6, udr.Num_UDRPs_Annual_kWh__c);
        System.assertEquals(5, udr.Num_UDRPs_Avg_Demand__c);

        // Check UAL fields
        System.assertEquals(31613.93, ual.Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(2205.75, ual.Average_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals(6, ual.Num_UDRPs_Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(5, ual.Num_UDRPs_Avg_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals('No', ual.NYPA__c, 'NYPA__c should be "No"');
        System.assertEquals('No', ual.RNY__c, 'RNY__c should be "No"');
        System.assertEquals(false, ual.Address_Update__c, 'Addresses should have matched');
        System.assertEquals('Pending BW Review', ual.QC_Status__c, 'Avg Demand is too high for Auto-QC to mark "Complete"');

        // Check Auto QC rejection reason field
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Above Max Avg Demand'), 'Reason should include Above Max Avg Demand');
    }

    @IsTest
    static void testUALUpdateForContainsDiscountRates() {
        // Run test
        Utility_Data_Request__c udr = getTestUDR('testUDR3');
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify Results
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);
        udr = getTestUDR('testUDR3');

        // Check UDR fields
        System.assertEquals(165200, udr.Annual_kWh__c, 'UDR3 has 1 KH UDRP, it is a non-Residential customer, and the '
            + 'Product.X4_month_sizing_method__c == State Average Annual Usage, so the Annual kWh should be the related '
            + 'State Avg Annual Resi kWh. Result should be 165200 since the test State Avg Annual Resi kWh is 165200.');
        System.assertEquals(506.77, udr.Average_Demand__c, 'UDR3 has 2 K1 UDRP so the Average Demand should be '
            + 'the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 30.'
            + 'In this case the answer should be 506.77.');
        System.assertEquals(1, udr.Num_UDRPs_Annual_kWh__c);
        System.assertEquals(2, udr.Num_UDRPs_Avg_Demand__c);

        // Check UAL fields
        System.assertEquals(165200, ual.Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(506.77, ual.Average_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals(1, ual.Num_UDRPs_Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(2, ual.Num_UDRPs_Avg_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals('No', ual.NYPA__c, 'NYPA__c should be "No"');
        System.assertEquals('Yes', ual.RNY__c, 'RNY__c should be "Yes"');
        System.assertEquals(false, ual.Address_Update__c, 'The addresses should have matched');
        System.assertEquals('Pending BW Review', ual.QC_Status__c, 'Avg Demand is too high, Discount Rates present');

        // Check Auto QC rejection reason field
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Has Discount Rates'), 'Reason should include Discount Rates');
    }

    @IsTest
    static void testUALUpdateAutoQCFailureMultipleReasons1() {
        // Run test
        Utility_Data_Request__c udr = getTestUDR('testUDR4');
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify results
        udr = getTestUDR('testUDR4');
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);

        // Check UDR fields
        System.assertEquals(90609.75, udr.Annual_kWh__c, 'UDR4 has 3 KH UDRP and is a Residential customer, so the Annual '
            + 'kWh should be the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 365.');
        System.assertEquals(714.43, udr.Average_Demand__c, 'UDR4 has 3 K1 UDRP, so the Average Demand is '
            + 'the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 30.');
        System.assertEquals(3, udr.Num_UDRPs_Annual_kWh__c);
        System.assertEquals(3, udr.Num_UDRPs_Avg_Demand__c);

        // Check UAL fields
        System.assertEquals(90609.75, ual.Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(714.43, ual.Average_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals(3, ual.Num_UDRPs_Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(3, ual.Num_UDRPs_Avg_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals('Yes', ual.NYPA__c, 'NYPA__c should be "Yes"');
        System.assertEquals('No', ual.RNY__c, 'RNY__c should be "No"');
        System.assertEquals(true, ual.Address_Update__c, 'The addresses should not have matched');
        System.assertEquals('Bill', ual.Previous_Name_on_Utility_Account__c, 'Address field invalid');
        System.assertEquals('459  Broadway', ual.Previous_Service_Address__c, 'Address field invalid');
        System.assertEquals('Everett', ual.Previous_Service_City__c, 'Address field invalid');
        System.assertEquals('MA', ual.Previous_Service_State__c, 'Address field invalid');
        System.assertEquals('02149', ual.Previous_Service_Zip_Code__c, 'Address field invalid');
        System.assertEquals('Bill', ual.Name_on_Account__c, 'Address field invalid');
        System.assertEquals('458 Broadway', ual.Service_Address__c, 'Address field invalid');
        System.assertEquals('Everett', ual.Service_City__c, 'Address field invalid');
        System.assertEquals('MA', ual.Service_State__c, 'Address field invalid');
        System.assertEquals('02149', ual.Service_Zip_Code__c, 'Address field invalid');
        System.assertEquals('Pending BW Review', ual.QC_Status__c, 'Auto QC should have failed');

        // Check Auto QC rejection reason field
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Has Discount Rates'), 'Reason should include Discount Rates');
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Address Change'), 'Reason should include Address Change');
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Above Max Avg Demand'), 'Reason should include Above Max Avg Demand');
    }

    @IsTest
    static void testUALUpdateAutoQCFailureMultipleReasons2() {
        // Run test
        Utility_Data_Request__c udr = getTestUDR('testUDR5');
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify results
        udr = getTestUDR('testUDR5');
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);

        // Check UDR fields
        System.assertEquals(152289.54, udr.Annual_kWh__c, 'UDR5 has 14 KH UDRP and is a Residential customer, '
            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 365.');
        System.assertEquals(1943.84, udr.Average_Demand__c, 'UDR5 has 12 K1 UDRP and is a Residential customer, '
            + 'so the Average Demand should be the sum of the UDRP.Quantity__c values divided by the number of days and multiplied by 30.');
        System.assertEquals(11, udr.Num_UDRPs_Annual_kWh__c);
        System.assertEquals(11, udr.Num_UDRPs_Avg_Demand__c);

        // Check UAL fields
        System.assertEquals(152289.54, ual.Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(1943.84, ual.Average_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals(11, ual.Num_UDRPs_Annual_kWh__c, 'UAL field value does not match UDR');
        System.assertEquals(11, ual.Num_UDRPs_Avg_Demand__c, 'UAL field value does not match UDR');
        System.assertEquals('Yes', ual.NYPA__c, 'NYPA__c should be "Yes"');
        System.assertEquals('Yes', ual.RNY__c, 'RNY__c should be "Yes"');
        System.assertEquals(true, ual.Address_Update__c, 'The addresses should not have matched');
        System.assertEquals('Bob', ual.Previous_Name_on_Utility_Account__c, 'Address field invalid');
        System.assertEquals('1 brighton ave, 20', ual.Previous_Service_Address__c, 'Address field invalid');
        System.assertEquals('Allston', ual.Previous_Service_City__c, 'Address field invalid');
        System.assertEquals('MA', ual.Previous_Service_State__c, 'Address field invalid');
        System.assertEquals('02134', ual.Previous_Service_Zip_Code__c, 'Address field invalid');
        System.assertEquals('Bob', ual.Name_on_Account__c, 'Address field invalid');
        System.assertEquals('1 Brighton Ave Unit 20', ual.Service_Address__c, 'Address field invalid');
        System.assertEquals('Allston', ual.Service_City__c, 'Address field invalid');
        System.assertEquals('Ma', ual.Service_State__c, 'Address field invalid');
        System.assertEquals('02134', ual.Service_Zip_Code__c, 'Address field invalid');
        System.assertEquals('Pending BW Review', ual.QC_Status__c, 'Auto QC should have failed');

        // Check Auto QC rejection reason
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Has Discount Rates'), 'Reason should include Discount Rates');
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Address Change'), 'Reason should indicate Address Change');
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Above Max Avg Demand'), 'Reason should indicate Above Max Avg Demand');
    }

    @IsTest
    static void testUALUpdateNoUDRPs() {
        // Run Test
        Utility_Data_Request__c udr = getTestUDR('testUDR6');
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify Results
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);

        // Check UAL fields
        System.assertEquals('No', ual.NYPA__c, 'NYPA__c should be "No"');
        System.assertEquals('No', ual.RNY__c, 'RNY__c should be "No"');
        System.assertEquals(true, ual.Address_Update__c, 'The addresses should not have matched');
        System.assertEquals('Pending BW Review', ual.QC_Status__c, 'Auto QC should have failed');

        // Check Auto QC rejection reason
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Address Change'), 'Reason should include Address Change');
        System.assert(ual.Auto_QC_Reject_Reason__c.contains('Missing Sizing Data'), 'Reason should indicate Missing Sizing Data');
    }

    @IsTest
    static void testUDRPUtilization() {
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        Utility_Data_Request__c testUDR3 = getTestUDR('testUDR3');
        Utility_Data_Request__c testUDR4 = getTestUDR('testUDR4');
        Utility_Data_Request__c testUDR5 = getTestUDR('testUDR5');
        Utility_Data_Request__c testUDR7 = getTestUDR('testUDR7');
        List<Utility_Data_Request__c> udrList = new List<Utility_Data_Request__c>{
            testUDR1, testUDR3, testUDR4, testUDR5, testUDR7
        };
        for (Utility_Data_Request__c udr : udrList) {
            udr.Header_Status__c = 'Complete';
            udr.Detail_Status__c = 'Complete';
        }
        update udrList;

        List<Utility_Data_Request_Period__c> khUDRPList = udrpSelector.selectTypeByUDR(udrList, 'KH', new List<String>{
            '51'
        });
        List<Utility_Data_Request_Period__c> k1UDRPList = udrpSelector.selectTypeByUDR(udrList, 'K1', new List<String>{
            '51', '41', '42', '43'
        });
        for (Utility_Data_Request_Period__c udrp : khUDRPList) {
            if (udrp.Load_Profile_Description__c == 'testUDRP12' ||
                udrp.Load_Profile_Description__c == 'testUDRP21' ||
                udrp.Load_Profile_Description__c == 'testUDRP23') {
                System.assertEquals(false, udrp.Used_in_Annual_kWh_Calculation__c, 'UDRP not used in kWh calculation, should be false. UDRP: ' + udrp);
            } else {
                System.assertEquals(true, udrp.Used_in_Annual_kWh_Calculation__c, 'UDRP used in kWh Calculation, should be true. UDRP: ' + udrp);
            }
        }
        for (Utility_Data_Request_Period__c udrp : k1UDRPList) {
            if (udrp.Load_Profile_Description__c == 'testUDRP36' ||
                udrp.Load_Profile_Description__c == 'testUDRP47') {
                System.assertEquals(false, udrp.Used_in_Average_Demand_Calculation__c, 'UDRP not used in avg demand calculation, should be false. UDRP: ' + udrp);
            } else {
                System.assertEquals(true, udrp.Used_in_Average_Demand_Calculation__c, 'UDRP used in avg demand Calculation, should be true. UDRP: ' + udrp);
            }
        }
    }

    @IsTest
    static void testUDRGenerationNoMatch() {
        // Retrieve data
        Lead lead = getTestLead('testLead1');
        Utility_Account_Log__c ualForLead = lead.Utility_Account_Logs__r;
        Integer udrCount = udrCount(ualForLead.Id);

        Test.startTest();
        UtilityDataRequestBuilder.createUDRs(new List<String>{
            lead.Id
        });
        Test.stopTest();

        // Check database to confirm no extra UDRs were generated for this UAL
        Integer udrCountNow = udrCount(ualForLead.Id);

        // Test lead already has one UDR already created (via @TestSetup method)
        // No new UDRs should have been created for this lead/UAL
        System.assertEquals(udrCount, udrCountNow, 'UDR generated when it should not have been. Duplicate UDR!');
    }

    @IsTest
    static void testUDRGeneration() {
        // Build data scenario
        Id utilityId = [SELECT Id FROM Utility__c WHERE Name = 'testUtility'].Id;
        Lead lead = new Lead (
            Product__c = [SELECT Id FROM Product2 WHERE Name = 'testProduct'].Id,
            Customer_type__c = 'Commercial',
            LastName = 'testLead1',
            Company = 'testBlueWave1',
            Utility_relationship__c = utilityId
        );
        insert lead;
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = lead.Id,
            Username__c = 'testUAL1',
            Utility_lookup__c = utilityId,
            Premise_Number__c = '129585012851'
        );
        insert ual;

        Test.startTest();
        System.assertEquals(0, udrCount(ual.Id), 'UDRs prior to create() method run should be 0');
        UtilityDataRequestBuilder.createUDRs(new List<String>{
            lead.Id
        });
        Test.stopTest();

        // Check results... Should have generated a new UDR with appropriate field vals, and updated UAL
        List<Utility_Data_Request__c> udrs = [
            SELECT Id, Account_Number__c, Utility__c, Utility_DUNS__c, Utility_Name__c, Request_Status_new__c,
                Utility_Account_Log__r.Name, Utility_Account_Log__r.Utility_lookup__c,
                Utility_Account_Log__r.Utility_lookup__r.Name, Utility_Account_Log__r.Utility_lookup__r.Utility_DUNS_Number__c,
                Utility_Account_Log__r.QC_Status__c,Premise_Number__c
            FROM Utility_Data_Request__c
            WHERE Utility_Account_Log__c = :ual.Id
        ];

        System.assert(!udrs.isEmpty(), 'No UDRs found after running create()');
        System.assertEquals(1, udrCount(ual.Id), '1 UDR should have been generated for UAL missing UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Name, udrs[0].Account_Number__c, 'Incorrect name for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__c, udrs[0].Utility__c, 'Incorrect utility for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__r.Utility_DUNS_Number__c, udrs[0].Utility_DUNS__c, 'Incorrect DUNS number for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__r.Name, udrs[0].Utility_Name__c, 'Incorrect utility name for generated UDR');
        System.assertEquals('Pending', udrs[0].Request_Status_new__c, 'Incorrect status for newly-generated UDR');
        System.assertEquals('Pending Utility Data', udrs[0].Utility_Account_Log__r.QC_Status__c, 'UAL status incorrect for pending UDR');
        System.assertEquals(ual.Premise_Number__c, udrs[0].Premise_Number__c, 'PoD ID not copied from UAL when it should be');
    }

    @IsTest
    static void testUALUpdateNoAddressChange() {
        // Run test
        Utility_Data_Request__c udr = getTestUDR('testUDR5');
        udr.Customer_Name__c = '';
        udr.Header_Status__c = 'Complete';
        udr.Detail_Status__c = 'Complete';
        update udr;

        // Verify results
        Utility_Account_Log__c ual = getTestUAL(udr.Utility_Account_Log__c);

        // Check UAL fields - address shouldn't change when UDR data doesn't provide a new address
        System.assertEquals('Bob', ual.Name_on_Account__c, 'UAL name on account should not have changed');
        System.assertEquals(false, ual.Address_Update__c, 'The addresses should not have been updated');
    }

    @IsTest
    static void systemTestInsertErrorCaseWithCaseMapping() {
        Utility_Data_Request__c udr = [SELECT Id FROM Utility_Data_Request__c LIMIT 1];
        System.assertEquals(0, [SELECT Id, QC_Case_Subject__c, Subject, Description FROM Case].size(),
            'No cases should exist in system before test run');
        Test.startTest();
        udr.Exception_Reason_Code__c = 'HUR';
        udr.Header_Status__c = 'Error';
        update udr; // trigger UtilityDataRequestTrigger -> udrService.openErrorCasesIfEncountered();
        Test.stopTest();
        List<Case> cases = [SELECT Id, QC_Case_Subject__c, Subject, Description FROM Case];
        System.debug([SELECT Message__c FROM Error_Log__c]);
        System.assertEquals(1, cases.size(), 'One case should have been inserted when UDR was marked as ERROR');
    }

    @IsTest
    static void systemTestInsertErrorCaseWithCaseAlreadyExisting() {
        Utility_Data_Request__c udr = [SELECT Id FROM Utility_Data_Request__c LIMIT 1];
        UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();
        udr = udrSelector.selectUdrsForErrorCase(new Set<Id>{udr.Id})[0];
        System.assertEquals(0, [SELECT Id, QC_Case_Subject__c, Subject, Description FROM Case].size(),
            'No cases should exist in system before test run');

        CaseFactory factory = new CaseFactory();
        factory.erroredUtilityDataRequestIds = new Set<Id>{
            udr.Id
        };
        factory.setQueueType('EDI Error');
        factory.getEDIErrorMappings();
        factory.insertEDIErrorCases();
        System.assertEquals(1, [SELECT Id, QC_Case_Subject__c, Subject, Description FROM Case].size(),
            'One case should have been inserted when UDR was marked as ERROR');

        Test.startTest();
        udr.Exception_Reason_Code__c = 'HUR';
        udr.Header_Status__c = 'Error';
        update udr; // trigger UtilityDataRequestTrigger, since a Case already exists, should not create a new Case
        Test.stopTest();
        System.assertEquals(1, [SELECT Id, QC_Case_Subject__c, Subject, Description FROM Case].size(),
            'Multiple cases should not have been created for a single UDR in error');
    }
}