<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Avidia_Email_Reserve_MCEC_Funds</fullName>
        <description>Avidia - Email - Reserve MCEC Funds</description>
        <protected>false</protected>
        <recipients>
            <recipient>nspeyer@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Emails_to_Delete/Avidia_MCEC_Fund_Reservation</template>
    </alerts>
    <alerts>
        <fullName>Avidia_MCEC_Loan_Ready_for_Review</fullName>
        <ccEmails>solarloans@avidiabank.com</ccEmails>
        <description>Avidia - MCEC Loan Ready for Review</description>
        <protected>false</protected>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Emails_to_Delete/Avidia_MCEC_Loan_Ready_for_Review</template>
    </alerts>
    <alerts>
        <fullName>Boarded_to_Sol_Email_A_and_B</fullName>
        <description>Boarded to Sol Email (A and B)</description>
        <protected>false</protected>
        <recipients>
            <field>Co_Applicant_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>SREC_Communication/Sept17Boarded_True_Quarterly</template>
    </alerts>
    <alerts>
        <fullName>Boarded_to_Sol_Email_C</fullName>
        <description>Boarded to Sol Email (C)</description>
        <protected>false</protected>
        <recipients>
            <field>Co_Applicant_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>SREC_Communication/Sept17Boarded_True_Monthly</template>
    </alerts>
    <alerts>
        <fullName>CS_Application_Approval</fullName>
        <description>CS Application Approval</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Customer_Application_Approval</template>
    </alerts>
    <alerts>
        <fullName>CS_Contract_Receipt_NGRID</fullName>
        <description>CS - Contract Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Welcome_Email</template>
    </alerts>
    <alerts>
        <fullName>CS_Opportunity_Complete_Email</fullName>
        <description>CS Opportunity Complete Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CSCustomerOnboardingEmails/CS_Customer_Executed_Survey</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Contract_Complete</fullName>
        <description>CS Partner - Contract Complete</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CSPartnerEmails/Cust_Application_Finalized</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Contract_Signed_by_Customer</fullName>
        <description>CS Partner - Contract Signed by Customer</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Partner_Contract_Signed_by_Customer</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Notification_Application_Approval</fullName>
        <description>CS Partner Notification - Application Approval</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Partner_Approved_Application_Notification</template>
    </alerts>
    <alerts>
        <fullName>CS_Referral_Program</fullName>
        <description>CS Referral Program</description>
        <protected>false</protected>
        <recipients>
            <field>Customer_Referral__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/x18_04CS_Customer_Referral_Success_2018_Update</template>
    </alerts>
    <alerts>
        <fullName>CS_Referral_Program_Referred_Customer</fullName>
        <description>CS Referral Program: Referred Customer</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/X18_04_Referee_Rewards_Success</template>
    </alerts>
    <alerts>
        <fullName>DOER_Customer_Contract_Fully_Executed</fullName>
        <description>DOER Customer - Contract Fully Executed</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Customer_Contract_FULLY_EXECUTED</template>
    </alerts>
    <alerts>
        <fullName>DOER_Customer_Contract_Received</fullName>
        <description>DOER Customer - Contract Received</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email_2_of_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Customer_Contract_Complete</template>
    </alerts>
    <alerts>
        <fullName>Internal_RL_Homeowner_s_insurance_submitted</fullName>
        <ccEmails>solarloans@bluewavesolar.com</ccEmails>
        <description>Internal - RL - Homeowner&apos;s insurance submitted</description>
        <protected>false</protected>
        <recipients>
            <recipient>lalexander@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Internal_RS_Homeowner_s_insurance_submitted_Alert</template>
    </alerts>
    <alerts>
        <fullName>PTS_Submittal_Email</fullName>
        <description>PTS Submittal Email</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RL_Partner_PTS_Submitted</template>
    </alerts>
    <alerts>
        <fullName>RL_Installer_Notification_Contract_Complete</fullName>
        <description>RL - Installer - Notification - Contract Complete</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Additional_Email_2_of_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RL_Installer_Completed_Loan</template>
    </alerts>
    <alerts>
        <fullName>RL_Installer_Notification_MAContract_Complete</fullName>
        <description>RL- Installer - Notification - Contract Complete</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Additional_Email_2_of_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RL_Installer_Completed_Loan</template>
    </alerts>
    <alerts>
        <fullName>RL_Installer_Ready_for_Disbursal_DOER</fullName>
        <description>RL - Installer - Ready for Disbursal - DOER</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Additional_Email_2_of_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/Doer_Installer_Contract_Complete</template>
    </alerts>
    <alerts>
        <fullName>RS_Customer_Signs_DOER_PendingInfo</fullName>
        <description>RS Customer Signs - DOER PendingInfo</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Signs_DOER_PendingInfo</template>
    </alerts>
    <alerts>
        <fullName>RS_Customer_Signs_Other</fullName>
        <description>RS Customer Signs - Other</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Signs_Other</template>
    </alerts>
    <alerts>
        <fullName>RS_Customer_Signs_PendingInfo</fullName>
        <description>RS Customer Signs - PendingInfo</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Signs_PendingInfo</template>
    </alerts>
    <alerts>
        <fullName>RS_Customer_Signs_Qualified</fullName>
        <description>RS Customer Signs - Qualified</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Signs_Qualfied</template>
    </alerts>
    <alerts>
        <fullName>RS_Internal_Alert_joint_application_expiration</fullName>
        <ccEmails>customercare@bluewavesolar.com</ccEmails>
        <description>RS Internal Alert - joint application expiration</description>
        <protected>false</protected>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Internal_Alert_Joint_App_Expiration</template>
    </alerts>
    <alerts>
        <fullName>RS_Partner_Contract_Sent_to_Opp</fullName>
        <description>RS Partner - Contract Sent to Opp</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Additional_Email_2_of_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Additional_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Partner_Contract_Sent_to_Opp</template>
    </alerts>
    <alerts>
        <fullName>RS_Send_Contract_Receipt</fullName>
        <description>RS Send Contract Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Contract_Receipt_Email</template>
    </alerts>
    <alerts>
        <fullName>RS_Send_Contract_ReceiptMA</fullName>
        <description>RS Send Contract Receipt MA</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Contract_Receipt_Email_MA2</template>
    </alerts>
    <alerts>
        <fullName>Sends_CS_Contract_Receipt_Email</fullName>
        <description>CS  - Contract Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Welcome_Email</template>
    </alerts>
    <fieldUpdates>
        <fullName>CS_RL_Stage_Update_Declined</fullName>
        <field>StageName</field>
        <literalValue>Cancelled</literalValue>
        <name>CS/RL Stage Update - Declined</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Email_Sent_Box</fullName>
        <field>CS_Application_Approval_Email_Sent__c</field>
        <literalValue>1</literalValue>
        <name>Check Email Sent Box</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Commencement_Date</fullName>
        <field>Commencement_Date__c</field>
        <formula>TODAY() + 45</formula>
        <name>Commencement Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Interconnected_Date</fullName>
        <field>Webform_3_Submittal_Date__c</field>
        <formula>Today()</formula>
        <name>Interconnected Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Interest_Only_Start_Date_Opp</fullName>
        <field>Interest_Only_Start_Date__c</field>
        <formula>DATE (  

/*YEAR*/  YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) +  Interest_Only_Period__c  - 1)/12),  

/*MONTH*/  CASE(MOD(MONTH(Commencement_Date__c) + Interest_Only_Period__c, 12 ), 0, 12, MOD(MONTH(Commencement_Date__c)+ Interest_Only_Period__c, 12 )),  

/*DAY*/  MIN(DAY(Commencement_Date__c),  CASE(MOD(MONTH(Commencement_Date__c) + Interest_Only_Period__c,12), 9, 30, 4, 30, 6, 30, 11, 30, 2,  

/* return max days for February dependent on if end date is leap year */  

IF(MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + Interest_Only_Period__c)/12), 400) = 0 || (MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + Interest_Only_Period__c)/12), 4) = 0 &amp;&amp; MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + Interest_Only_Period__c)/12), 100) &lt;&gt; 0  ), 29,28), 31))  )</formula>
        <name>Interest Only Start Date (Opp)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Interest_Rate_Field_Calc_Non_DOER</fullName>
        <field>Interest_Rate_Picklist__c</field>
        <literalValue>5.99</literalValue>
        <name>Interest Rate Field Calc Non DOER</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Interest_Update</fullName>
        <field>Interest_Rate_Picklist__c</field>
        <literalValue>3.99</literalValue>
        <name>Interest Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Mechanical_Install_Date</fullName>
        <field>Webform_2_Submittal_Date__c</field>
        <formula>TODAY()</formula>
        <name>Mechanical Install Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_Stage_to_Contract_Pending</fullName>
        <field>StageName</field>
        <literalValue>Contract Pending</literalValue>
        <name>Opp Stage to Contract Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_DOER_Reserve_MCEC_TRUE</fullName>
        <field>Ready_to_Reserve_MCEC_Funds__c</field>
        <literalValue>1</literalValue>
        <name>Opportunity - DOER - Reserve MCEC(TRUE)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Name_Remove_Hyphen</fullName>
        <field>Name</field>
        <formula>SUBSTITUTE( Name , &apos;-&apos;, &apos;&apos;)</formula>
        <name>Opportunity Name - Remove Hyphen</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Record_Type_DOER_Solar_L</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_DOER_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Opportunity - Record Type - DOER Solar L</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_BW_Signature</fullName>
        <field>StageName</field>
        <literalValue>Pending BlueWave Signature</literalValue>
        <name>Opportunity Stage - BW Signature</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_Expired</fullName>
        <field>StageName</field>
        <literalValue>Expired</literalValue>
        <name>Opportunity Stage - Expired</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_QC_Signature_Pending</fullName>
        <description>Sets Opportunity Stage to &apos;Pending QC Signature&apos;</description>
        <field>StageName</field>
        <literalValue>Pending Quality Control Signature</literalValue>
        <name>Opportunity Stage - QC Signature Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_QC_in_Process</fullName>
        <description>Set stage to QC in process as soon as customer contract is received.</description>
        <field>StageName</field>
        <literalValue>QC In Process</literalValue>
        <name>Opportunity Stage - QC in Process</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_Utility_Information</fullName>
        <field>StageName</field>
        <literalValue>Utility Account Information Needed</literalValue>
        <name>Opportunity Stage - Utility Information</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_complete</fullName>
        <field>StageName</field>
        <literalValue>Complete</literalValue>
        <name>Opportunity Stage - Complete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Update_Dummy</fullName>
        <field>Update_Dummy__c</field>
        <literalValue>1</literalValue>
        <name>Opportunity - Update Dummy</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_CC_Email</fullName>
        <field>Partner_Additional_Email__c</field>
        <formula>Partner_Additional_Email_Formula__c</formula>
        <name>Partner CC Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_Email_Update</fullName>
        <field>Partner_Email__c</field>
        <formula>Partner_Email_2__c</formula>
        <name>Partner Email Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_additional_cc</fullName>
        <field>Partner_Additional_Email_2_of_2__c</field>
        <formula>Partner_Email_3__c</formula>
        <name>Partner additional cc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Perio</fullName>
        <field>Number_of_Periods_Months__c</field>
        <formula>VALUE(TEXT(Interest_Rate_Picklist__c))</formula>
        <name>Perio</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Period_120</fullName>
        <field>Number_of_Periods_Months__c</field>
        <formula>120</formula>
        <name>Period (120)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Periods_Formula_to_Field</fullName>
        <field>Number_of_Periods_Months__c</field>
        <formula>Period_months_Formula__c</formula>
        <name>Periods Formula to Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_DOER_Lead_Record_Type_DOER_Co_A</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_DOER_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - DOER - Lead Record Type - DOER Co-A</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Lead_Record_Type_MA_SL_Co_App</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_MA_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Lead Record Type - MA SL (Co-App)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Lead_Record_Type_NC_Co_App</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_NC_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Lead Record Type - NC (Co-App)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Lead_Record_Type_SC_Co_App</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_SC_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Lead Record Type - SC (Co-App)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_OPP_Record_Type_NC_Solar_Loan</fullName>
        <description>Changes the Record Type to NC Solar loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_NC_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - OPP Record Type - NC Solar Loan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Opportunity_Record_Type_SC_Solar</fullName>
        <description>Changes the Opportunity Record Type to SC Solar Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_SC_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Opportunity Record Type - SC Solar</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Opportunity_Status_Modified_Date</fullName>
        <description>Records the date that the Opportunity MCEC status was last modified.</description>
        <field>MCEC_Status_Last_Modified__c</field>
        <formula>Today()</formula>
        <name>RL - Opportunity Status Modified Datead</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RS_Commencement_Date_Update</fullName>
        <field>Commencement_Date__c</field>
        <formula>DATE ( 

/*YEAR*/ YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1 - 1)/12), 

/*MONTH*/ CASE(MOD(MONTH(Commencement_Date__c) + 1, 12 ), 0, 12, MOD(MONTH(Commencement_Date__c)+ 1, 12 )), 

/*DAY*/ MIN(DAY(Commencement_Date__c), CASE(MOD(MONTH(Commencement_Date__c) + 1,12), 9, 30, 4, 30, 6, 30, 11, 30, 2, 

/* return max days for February dependent on if end date is leap year */ 

IF(MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 400) = 0 || (MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 4) = 0 &amp;&amp; MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 100) &lt;&gt; 0 ), 29,28), 31)) )</formula>
        <name>RS - Commencement Date (Update)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RS_Mechanical_Installation_Date</fullName>
        <field>Webform_2_Submittal_Date__c</field>
        <formula>today()</formula>
        <name>RS - Mechanical Installation Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Contract_Close_Date</fullName>
        <field>Contract_Close_Date__c</field>
        <formula>TODAY()</formula>
        <name>Set Contract Close Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Record_Type_to_Solar_Loan</fullName>
        <description>Sets the Opportunity Record Type to BFG - Solar Loan when Product Line is Solar Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Set Record Type to Solar Loan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Salesperson_Email_2</fullName>
        <field>Salesperson_Email_2__c</field>
        <formula>Salesperson_Email__c</formula>
        <name>Update Salesperson Email 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>updates_underwriting_queue_duration</fullName>
        <field>RL_Underwriting_Queue_Duration__c</field>
        <formula>TODAY()- RL_Underwriting_Start_Date__c</formula>
        <name>RL - updates underwriting queue duration</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <flowActions>
        <fullName>Stage_is_change_to_complete</fullName>
        <flow>Update_Partner_Flow</flow>
        <label>Stage is change to complete</label>
        <language>en_US</language>
        <protected>false</protected>
    </flowActions>
    <rules>
        <fullName>Avidia - Email - Loan Ready for Avidia Review</fullName>
        <actions>
            <name>Avidia_MCEC_Loan_Ready_for_Review</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Avidia_Email_Loan_Ready_for_Avidia_Review</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Contract Pending</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <description>Sends and email to Avidia when a contract is sent, letting Avidia know that a loan is ready for review.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Application Approval Email Opp Creation</fullName>
        <actions>
            <name>CS_Application_Approval</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Check_Email_Sent_Box</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_Application_Approval</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <formula>AND( OR( Annual_Electricity_Cost2__c &gt; 0, Annual_Electricity_Cost__c &gt; 0),   Disable_Emails__c == FALSE, NOT(ISPICKVAL(StageName,&quot;Complete&quot;)),  !CS_Application_Approval_Email_Sent__c,  Product_Line__c =&quot;Community Solar&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - BlueWave - Contract Receipt %28Eversource%29</fullName>
        <actions>
            <name>Sends_CS_Contract_Receipt_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_BlueWave_Contract_Reciept</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND (4 OR 5)</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.UtilityMapper__c</field>
            <operation>equals</operation>
            <value>Eversource</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Opportunity_Order__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Opportunity_Order__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Triggers sending of CS contract receipt email when CS opportunity is closed as won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - BlueWave - Contract Receipt %28National Grid%29</fullName>
        <actions>
            <name>CS_Contract_Receipt_NGRID</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_NGrid_Contract_Execution</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND (3 OR 5) AND 4</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Opportunity_Order__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.UtilityMapper__c</field>
            <operation>equals</operation>
            <value>National Grid</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Opportunity_Order__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Triggers sending of CS contract receipt email when CS opportunity is closed as won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Partner - Opportunity Complete Notification</fullName>
        <actions>
            <name>CS_Partner_Contract_Complete</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_Opportunity_Complete_Email_to_Partner</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>Triggers sending of CS contract complete email to partner when CS opportunity is closed as won</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS Opportunity Stage - Expired</fullName>
        <active>true</active>
        <booleanFilter>(1 OR 2 ) AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Sent</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Delivered</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Pending BlueWave Signature,Complete,QC In Process,Pending Quality Control Signature</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.BlueWave_Signature_Status__c</field>
            <operation>notEqual</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Update_Dummy</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>15</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Stage_Expired</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>CS%2FRL - Contract Pending Stage</fullName>
        <actions>
            <name>Opp_Stage_to_Contract_Pending</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>updates_underwriting_queue_duration</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Sent</value>
        </criteriaItems>
        <description>Sets the Stage to Contract Pending when the customer recipient status = sent</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS%2FRL - Partner Email Field Update</fullName>
        <actions>
            <name>Partner_CC_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Partner_Email_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Partner_additional_cc</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1</booleanFilter>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>New</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>DOER 35%25 Disbursal ACH</fullName>
        <actions>
            <name>EMAIL_LOG_DOER_Customer_35_disbursal_ACH</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Contract__c</field>
            <operation>equals</operation>
            <value>ACH Disbursal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>DOER 35%25 Disbursal Check</fullName>
        <actions>
            <name>EMAIL_LOG_DOER_Customer_35_disbursal_check</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Contract__c</field>
            <operation>equals</operation>
            <value>Check Disbursal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>DOER 65%25 Disbursal ACH</fullName>
        <actions>
            <name>EMAIL_LOG_DOER_Customer_65_disbursal_ach</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Interconnect__c</field>
            <operation>equals</operation>
            <value>ACH Disbursal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>DOER 65%25 Disbursal Check</fullName>
        <actions>
            <name>EMAIL_LOG_DOER_Customer_65_disbursal_check</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Interconnect__c</field>
            <operation>equals</operation>
            <value>Check Disbursal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>DOER Customer - Contract Received</fullName>
        <actions>
            <name>DOER_Customer_Contract_Received</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_DOER_Customer_Contract_Received</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.BlueWave_Signature_Status__c</field>
            <operation>notEqual</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Notifies RL customer that the BWOC has received their contract and they will receive their fully executed contract shortly</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Interest Only Start Date</fullName>
        <actions>
            <name>Interest_Only_Start_Date_Opp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Interest_Only_Period__c</field>
            <operation>greaterThan</operation>
            <value>0</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Internal - RS - Joint App Expiration</fullName>
        <active>true</active>
        <description>This is used to notify the BWOC when the 1 signer of a joint RL app has signer, but the 2nd did not sign within 24 hours. They have to go in and void the contract and resend it since signers must sign within 24 hrs of eachother</description>
        <formula>AND( Contract_Status__c=&quot;Completed&quot;, Co_Applicant_Signature_Status__c!=&quot;Completed&quot;,
 CONTAINS(Application_Type__c,&quot;Joint&quot;)=true,
 OR(Product_Line__c =&quot;residential loan&quot;,Product_Line__c=&quot;Residential Loan&quot;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>RS_Internal_Alert_joint_application_expiration</name>
                <type>Alert</type>
            </actions>
            <timeLength>24</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity Name - Remove Hyphen</fullName>
        <actions>
            <name>Opportunity_Name_Remove_Hyphen</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>IF 
( 
CONTAINS(Name,&apos;-&apos;),true,false 
)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Stage - BW Signature</fullName>
        <actions>
            <name>Opportunity_Stage_BW_Signature</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3 AND 4</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.All_QC_Boxes_True__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Quality_Check_Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Pending Quality Control Signature</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Stage - Complete %2F Contract Close Date</fullName>
        <actions>
            <name>Opportunity_Stage_complete</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_Contract_Close_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.BlueWave_Signature_Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Dead,Expired,Cancelled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Stage - Expired %28CS%29</fullName>
        <active>false</active>
        <booleanFilter>(1 OR 2 ) AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Sent</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Delivered</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Pending BlueWave Signature,Complete,QC In Process,Pending Quality Control Signature</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.BlueWave_Signature_Status__c</field>
            <operation>notEqual</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Stage_Expired</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>14</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Opportunity_Update_Dummy</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>13</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Opportunity Stage - QC Signature Pending</fullName>
        <actions>
            <name>Opportunity_Stage_QC_Signature_Pending</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2</booleanFilter>
        <criteriaItems>
            <field>Opportunity.All_QC_Boxes_True__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <description>Changes stage to &apos;QC Signature Pending&apos; when QC is complete, and when Customer has signed.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Stage - QC in Process</fullName>
        <actions>
            <name>Opportunity_Stage_QC_in_Process</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.BlueWave_Signature_Status__c</field>
            <operation>notEqual</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.All_QC_Boxes_True__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>notEqual</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>Changes stage to &apos;QC in Process&apos; when QC is not yet complete, and when Customer has signed. Updated with rule 5 to prevent expiring docusign envelopes from people with paper contracts going back to QC</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity Stage - Utility Information Needed</fullName>
        <actions>
            <name>Opportunity_Stage_Utility_Information</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Utility_Account__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Multiple_Utility_Accounts__c</field>
            <operation>equals</operation>
            <value>No</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Partner - Email - Loan Contract Sent</fullName>
        <actions>
            <name>RS_Partner_Contract_Sent_to_Opp</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Update_Salesperson_Email_2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RL_Installer_Notified_Contract_was_Sent</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Contract Pending</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <description>Sends an email to Sales Partner when a contract is sent.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Interest Rate Field Calc</fullName>
        <actions>
            <name>Interest_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.CreatedDate</field>
            <operation>greaterThan</operation>
            <value>10/16/2016</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>RL - Interest Rate Field Calc Non DOER</fullName>
        <actions>
            <name>Interest_Rate_Field_Calc_Non_DOER</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.CreatedDate</field>
            <operation>greaterThan</operation>
            <value>10/16/2016</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Loan_Term_Override__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>RL - Opportunity Status Modified Date</fullName>
        <actions>
            <name>RL_Opportunity_Status_Modified_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates Opportunity field MCEC status last modified date</description>
        <formula>AND( Product_Line__c = &quot;Residential Loan&quot;, or(isnew(),ischanged( MCEC_Status__c )))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>RL - Periods Formula to Static</fullName>
        <actions>
            <name>Periods_Formula_to_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Loan_Term_Override__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL%2FCS - Opportunity Stage - Contract Declined</fullName>
        <actions>
            <name>CS_RL_Stage_Update_Declined</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Contract_Status__c</field>
            <operation>equals</operation>
            <value>Declined</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - DOER - Origination Date</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - Interconnection Complete</fullName>
        <actions>
            <name>Interconnected_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Interconnected__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - Mechanical Installation Complete</fullName>
        <actions>
            <name>Mechanical_Install_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Mechanically_Installed__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS MA %28Non DOER%29 - 10%25 Disbursal</fullName>
        <actions>
            <name>EMAIL_LOG_Customer_10_Disbursal_MA_non_DOER</name>
            <type>Task</type>
        </actions>
        <actions>
            <name>Email_Log_RS_Partner_10_Disbursal</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Disbursal_3_Full_Install_Checkbox__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.State__c</field>
            <operation>equals</operation>
            <value>Massachusetts</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Interconnect__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS Partner - 10%25 Disbursal</fullName>
        <actions>
            <name>EMAIL_LOG_Customer_10_Disbursal</name>
            <type>Task</type>
        </actions>
        <actions>
            <name>Email_Log_RS_Partner_10_Disbursal</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Disbursal_3_Full_Install_Checkbox__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.State__c</field>
            <operation>notEqual</operation>
            <value>Massachusetts</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Interconnect__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS Partner - 30%25 Disbursal</fullName>
        <actions>
            <name>EMAIL_LOG_Customer_30_Disbursal</name>
            <type>Task</type>
        </actions>
        <actions>
            <name>Email_Log_RS_Partner_30_Disbursal</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_1_Contract_Signature_Checkbox__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Contract__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS Partner - 60%25 Disbursal</fullName>
        <actions>
            <name>EMAIL_LOG_Customer_60_disbursal</name>
            <type>Task</type>
        </actions>
        <actions>
            <name>Email_Log_RS_Partner_60_Disbursal</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Disbursal_2_Mechanical_Install_Checkbox__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disbursal_Type_Mech_Completion__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS Partner - PTS Submitted</fullName>
        <actions>
            <name>PTS_Submittal_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RS_Partner_PTS_has_been_Submitted</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.Submitted_to_Sol_Systems__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Used to send notification to partners that PTS submitted on their behalf to Sol Systems</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Reserve MCEC Funds</fullName>
        <actions>
            <name>Avidia_Email_Reserve_MCEC_Funds</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Opportunity_DOER_Reserve_MCEC_TRUE</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Reserve_MCEC_Funds</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Ready_to_Reserve_MCEC_Funds__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Disable_Emails__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <description>Sets Field:MCEC Funds Requested  to value: TRUE
Sends Email to Avidia to Reserve Funds</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>EMAIL_LOG_60_Disbursal_for_Non_MA_States</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: 60% Disbursal for Non-MA States</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Avidia_Email_Loan_Ready_for_Avidia_Review</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Avidia - Email - Loan Ready for Avidia Review
using TEMPLATE: Avidia - MCEC Loan Ready for Review</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Avidia - Email - Loan Ready for Avidia Review</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_Application_Approval</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - Application Approval using template https://na16.salesforce.com/00Xj00000010Euq</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - Application Approval</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_BlueWave_Contract_Reciept</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - BlueWave - Contract Receipt using TWO TEMPLATES &quot;CS Customer - Contract Received&quot; and &quot;CS Customer - Welcome to BlueWave&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - BlueWave - Contract Reciept</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_Opportunity_Complete_Email_to_Partner</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Email notification that CS Opportunity = complete email sent to partner</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Low</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS Opportunity Complete Email to Partner</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Customer_10_Disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Customer 10% Disbursal</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Customer 10% Disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Customer_10_Disbursal_MA_non_DOER</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Customer 10% Disbursal using MA Non DOER Template</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Customer 10% Disbursal (MA non DOER)</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Customer_30_Disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Customer 30% Disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Customer_60_Disbursal_II</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Customer 10% Disbursal</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Customer 60% Disbursal II</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Customer_60_disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Customer 60% disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_DOER_Customer_35_disbursal_ACH</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>ACH DOER Disbursal using template:

https://na16.salesforce.com/00Xj0000000aJb3?setupid=CommunicationTemplatesEmail


AND https://na16.salesforce.com/00Xj0000000Fpkf?setupid=CommunicationTemplatesEmail</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: DOER Customer 35% disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_DOER_Customer_35_disbursal_check</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>CHECK 35% disbursal for DOER

using template: https://na16.salesforce.com/00Xj0000000Ftxe?setupid=CommunicationTemplatesEmail

and https://na16.salesforce.com/00Xj0000000Ftx5?setupid=CommunicationTemplatesEmail</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: DOER Customer 35% disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_DOER_Customer_65_disbursal_ach</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>ACH DOER 65% disbursal 

using template: https://na16.salesforce.com/00Xj0000000FUUq?setupid=CommunicationTemplatesEmail

using template: https://na16.salesforce.com/00Xj0000000Fpkk?setupid=CommunicationTemplatesEmail</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: DOER Customer 65% disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_DOER_Customer_65_disbursal_check</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Check 65% disbursal 

using template: https://na16.salesforce.com/00Xj0000000Ftxj?setupid=CommunicationTemplatesEmail

and https://na16.salesforce.com/00Xj0000000FtxZ?setupid=CommunicationTemplatesEmail</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: DOER Customer 65% disbursal</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_DOER_Customer_Contract_Received</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: DOER Customer - Contract Received using TEMPLATE: &quot;DOER Customer - Contract Receipt&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: DOER Customer - Contract Received</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_NGrid_Contract_Execution</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: using template NGrid Customer Billing + Timing Note</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: NGrid Contract Execution</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_DOER_Email_Completed</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - DOER - Email - Completed Opportunity using TEMPLATE: DOER Customer - Contract FullyExecuted</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - DOER - Email - Completed</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Email_Completed_Opportunity</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Email - Completed Opportunity using two TEMPLATES: &quot;RL - Installer - Notification - Completed Loan&quot; (to installer) &quot;RS - Contract Receipt&quot; (to homeowner)</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Email - Completed Opportunity</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Email_Completed_OpportunityMA</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Email - Completed Opportunity using two TEMPLATES: &quot;RL - Installer - Notification - Completed Loan&quot; (to installer) &quot;RS - Contract Receipt MA&quot; (to homeowner)</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Email - Completed MA Opportunity</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Installer_Notified_Contract_was_Sent</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Installer - Notified Contract was Sent using TEMPLATE: 
EMAIL LOG: RS Partner - Contract Sent to Opp</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Installer - Notified Contract was Sent</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Installer_Qualified_Update_Form</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Installer - Notification - Qualified/Update Form using TEMPLATE: Doer Installer - Contract Complete</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Installer - Qualified/Update Form</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RS_Partner_PTS_has_been_Submitted</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Email sent to Partner with this template: RS Partner - PTS Submitted</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RS Partner PTS has been Submitted</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Reserve_MCEC_Funds</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Reserve MCEC Funds
using TEMPLATE: Avidia - MCEC Fund Reservation</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Reserve MCEC Funds</subject>
    </tasks>
    <tasks>
        <fullName>Email_Log_RS_Partner_10_Disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email Log: RS Partner - 10% Disbursal</subject>
    </tasks>
    <tasks>
        <fullName>Email_Log_RS_Partner_30_Disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email Log: RS Partner - 30% Disbursal</subject>
    </tasks>
    <tasks>
        <fullName>Email_Log_RS_Partner_60_Disbursal</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email Log: RS Partner - 60% Disbursal</subject>
    </tasks>
</Workflow>
