<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
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
        <template>CSPartnerEmails/CS_Partner_CS_Contract_Signed</template>
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