/**
 * Created by PeterYao on 5/2/2021.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class StandardPostSandboxRefresher implements SandboxPostCopy {
    public void runApexClass(SandboxContext context) {
        Logger.logNow('StandardPostSandboxRefresher', 'runApexClass', 'Starting method', Logger.ERROR);
        String stepToRun = Util.getSystemPropertyString('Last_Lease_Dimensions_File_Processed__c');
        Logger.logNow('StandardPostSandboxRefresher', 'runApexClass', 'Running ' + stepToRun, Logger.ERROR);
        try {
            switch on stepToRun {
                when 'LetterStream' {
                    updateLetterStreamToTestConfig();
                } when 'DocuSign' {
                    updateDocusignToDemoConfig();
                } when 'Scheduled' {
                    schedulePostSandboxJob();
                } when else {
                    updateLetterStreamToTestConfig();
                    updateDocusignToDemoConfig();
                }
            }
        } catch (Exception e) {
            Logger.logNow('PostSandboxRefresher', 'runApexClass for ' + stepToRun, e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    @TestVisible
    private static void updateLetterStreamToTestConfig() {
        if (!Util.isSandboxOrTest()) {
            throw new Util.BWException('Dont\'t update LetterStream config in production this way');
        }
        List<LetterStream_Settings__c> letterStreamSettings = [
            SELECT Id, API_Id__c, API_Key__c
            FROM LetterStream_Settings__c
        ];
        LetterStream_Settings__c newLetterStreamSetting = new LetterStream_Settings__c();
        if (!letterStreamSettings.isEmpty()) {
            newLetterStreamSetting.Id = letterStreamSettings[0].Id;
        }
        // credentials for bluewavetestAPI (see wiki)
        newLetterStreamSetting.Name = 'Test Config';
        newLetterStreamSetting.API_Id__c = 'ft5eh41g_test';
        newLetterStreamSetting.API_Key__c = 'fhv4d7bèv9v6n7_test';
        newLetterStreamSetting.API_Endpoint__c = 'https://secure.letterstream.com/apis/';
        upsert newLetterStreamSetting;
    }

    public static void setupBWTestPartner() {
        Partner__c partner = new Partner__c(Name = 'Solar Test Partner');
        insert partner;
        BSST__c salesRep = new BSST__c(Name = 'Joe Bob', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@bluewavesolar.com.test');
        insert salesRep;
        BSST__c salesRepExec = new BSST__c(Name = 'Mr Executive', Partner__c = partner.Id, Custom_ID__c = 'exec', Email__c = 'executive@bluewavesolar.com.test');
        insert salesRepExec;
        String states = 'AK;AL;AR;AZ;CA;CO;CT;DE;FL;GA;HI;IA;ID;IL;IN;KS;KY;LA;MA;MD;ME;MI;MN;MO;MS;MT;NC;ND;NE;NH;NJ;NM;NV;NY;OH;OK;OR;PA;RI;SC;SD;TN;TX;UT;VA;VT;WA;WI;WV;WY';
        partner.Default_Sales_Rep__c = salesRepExec.Id;
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        sysProp.Default_CS_Partner__c = partner.Id;
        update partner;
        update sysProp;
        Account partnerAccount = new Account(
            Name='Solar Test Partner',
            Partner__c = partner.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId(),
            State_Market__c = states,
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP'
        );
        insert partnerAccount;
        partner.Account__c = partnerAccount.Id;
        update partnerAccount;
        Contact execContact = new Contact(  FirstName='Joe',
            LastName='Bob',
            AccountId = partnerAccount.Id,
            Partner_Lookup__c = partner.Id,
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Contact').getRecordTypeId(),
            Sales_Representative__c = salesRep.Id);
        insert execContact;
        Contact salesRepContact = new Contact(  FirstName='Mr',
            LastName='Executive',
            AccountId = partnerAccount.Id,
            Partner_Lookup__c = partner.Id,
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner Contact').getRecordTypeId(),
            Sales_Representative__c = salesRepExec.Id);
        insert salesRepContact;
    }
    @TestVisible
    private static void updateDocusignToDemoConfig() {
        if (!Util.isSandboxOrTest()) {
            throw new Util.BWException('Don\'t update DocuSign config in production this way');
        }
        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.isEmpty()) {
            return;
        }
        systemProperties[0].DocuSign_API_Account_ID__c = '2255b4dd-7d4f-425a-bcc9-d53328055381';
        systemProperties[0].DocuSign_Customer_Care_User__c = 'pyao@bluewavesolar.com';
        systemProperties[0].DocuSign_Guest_User__c = 'pyao@bluewave-capital.com';
        systemProperties[0].DocuSign_Guest_User_Credential__c = '137Newbury';
        systemProperties[0].DocuSign_Integrator_Key__c = '2ceabed4-3a84-4220-9a76-9b1f9f0cf6ed';
        update systemProperties[0];

        List<Product2> docuSignEnabledProducts = [
            SELECT Id
            FROM Product2
            WHERE Contract_Docusign_Template__c != NULL
        ];
        for (Product2 product2 : docuSignEnabledProducts) {
            // All products will point to a valid template in the demo docusign environment so DocuSign will at least
            // produce some document by default
            product2.Contract_Docusign_Template__c = 'e03c7f33-0754-4abb-9d8e-42a46923e512';
        }
        update docuSignEnabledProducts;
    }

    @TestVisible
    private void schedulePostSandboxJob() {
        Integer minute = Datetime.now().addMinutes(30).minute();
        // Starting 30m from now to allow the queueable CS job to finish. Job will self-cancel once successful.
        String cronString = '0 ' + minute + ' * * * ?';
        String cronId = System.schedule(PostSandboxSchedulable.POST_SANDBOX_SCHEDULED_JOB_NAME, cronString, new PostSandboxSchedulable());
        Logger.logLater('PostSandboxRefresher', 'schedulePostSandboxJob', 'Created ' + cronId + ' for post post sandbox actions', Logger.ERROR);
    }
}