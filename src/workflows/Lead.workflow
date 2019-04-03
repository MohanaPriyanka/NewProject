<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Application_Receipt_Prequal</fullName>
        <description>Application Receipt - Prequal</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_PreQualification_App_Reciept</template>
    </alerts>
    <alerts>
        <fullName>Application_Receipt_Prequal_DOER</fullName>
        <description>Application Receipt - Prequal DOER</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/RS_DOER_PreQualification_App_Reciept</template>
    </alerts>
    <alerts>
        <fullName>BWOC_Alert_non_partner_preapproval_lead</fullName>
        <ccEmails>salesops@bluewavesolar.com</ccEmails>
        <description>BWOC Alert - non partner preapproval lead</description>
        <protected>false</protected>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Emails_to_Delete/Non_Partner_Prequal</template>
    </alerts>
    <alerts>
        <fullName>BWOC_EnergySage_Lead_Alert</fullName>
        <ccEmails>solarloans@bluewave-capital.com</ccEmails>
        <description>BWOC EnergySage Lead Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>jpentaleri@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>BFG_Internal_Alerts/EnergySage_Lead_Alert</template>
    </alerts>
    <alerts>
        <fullName>BlueWave_CS_Application_Receipt</fullName>
        <description>BlueWave - CS - Application Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Customer_Application_Received</template>
    </alerts>
    <alerts>
        <fullName>BlueWave_CS_Credit_Denied</fullName>
        <description>BlueWave - CS - Credit Denied</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Customer_Credit_Denied</template>
    </alerts>
    <alerts>
        <fullName>CS_24_Hour_Incomplete_Application_Email</fullName>
        <description>CS 24 Hour Incomplete Application Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Customer_24_Hour_Application_Notice</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Application_Submitted</fullName>
        <description>CS Partner: Application Submitted</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Partner_Application_Completed</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Appliction_Denied</fullName>
        <description>CS - Partner - Appliction Denied</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Application_Email_Notifications/CS_Partner_Credit_Denied</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Lead_has_been_Created</fullName>
        <description>CS - Partner - Lead has been Created</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CSPartnerEmails/CS_Partner_Lead_Created</template>
    </alerts>
    <alerts>
        <fullName>Co_Applicant_Link_Email</fullName>
        <description>Co-Applicant Link Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Please_Complete_CoApplicant_Form</template>
    </alerts>
    <alerts>
        <fullName>FICO_Disclosure_Joint_App</fullName>
        <description>FICO Disclosure Joint App</description>
        <protected>false</protected>
        <recipients>
            <field>Co_Applicant_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/FICO_Disclosure_Co_App</template>
    </alerts>
    <alerts>
        <fullName>FICO_Disclosure_Main_App</fullName>
        <description>FICO Disclosure Main App</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/FICO_Disclosure</template>
    </alerts>
    <alerts>
        <fullName>Lead_DOER_Co_Applicant_Credit_Denial_Email</fullName>
        <ccEmails>solarloans@bluewavesolar.com, Solarloans@avidiabank.com</ccEmails>
        <description>Lead - DOER - Co Applicant Credit Denial Email</description>
        <protected>false</protected>
        <recipients>
            <recipient>m.desai@avidiabank.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Co_App_Customer_Credit_Denial</template>
    </alerts>
    <alerts>
        <fullName>Lead_DOER_Credit_Denial_Email</fullName>
        <ccEmails>Solarloans@avidiabank.com</ccEmails>
        <description>Lead - DOER - Credit Denial Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <recipient>m.desai@avidiabank.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Customer_Credit_Denial</template>
    </alerts>
    <alerts>
        <fullName>NC_Pre_Qualified_Homeowner</fullName>
        <ccEmails>PartnerSupport@bluewavesolar.com</ccEmails>
        <description>NC Pre-Qualified Homeowner</description>
        <protected>false</protected>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/NC_Pre_Qualified_Homeowner</template>
    </alerts>
    <alerts>
        <fullName>Non_Partner_Installer_Email_Alert</fullName>
        <ccEmails>agarvin@bluewave-capital.com</ccEmails>
        <ccEmails>solarloans@bluewave-capital.com</ccEmails>
        <description>Non-Partner Installer Email Alert</description>
        <protected>false</protected>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Emails_to_Delete/Non_Partner_Installer_email</template>
    </alerts>
    <alerts>
        <fullName>RL_Customer_Credit_Approved</fullName>
        <description>RL Customer - Credit Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Application_Approved</template>
    </alerts>
    <alerts>
        <fullName>RL_Installer_Lead_has_been_Created</fullName>
        <description>RL - Installer - Lead has been Created</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/DOER_Installer_Application_is_pending_approval</template>
    </alerts>
    <alerts>
        <fullName>RL_Installer_Notification_Lead_Unqualified</fullName>
        <description>RL - Installer - Notification - Lead Unqualified</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Partner_Application_Credit_Denial</template>
    </alerts>
    <alerts>
        <fullName>RL_Lead_Qualified_Contract_Signed</fullName>
        <description>RL Lead Qualified, Contract Signed</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_application_approved_Contract_Sent_and_Signed</template>
    </alerts>
    <alerts>
        <fullName>RL_Lead_Qualified_Contract_Unsent</fullName>
        <description>RL Lead Qualified, Contract Unsent</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_application_approved_Contract_Not_Sent</template>
    </alerts>
    <alerts>
        <fullName>RL_Lead_Qualified_Contract_Unsigned</fullName>
        <description>RL Lead Qualified, Contract Unsigned</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_application_approved_Contract_Sent_and_Unsigned</template>
    </alerts>
    <alerts>
        <fullName>RS_Application_Receipt_W_Avidia_Bank_Account</fullName>
        <description>RS Application Receipt W/Avidia Bank Account</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewave-capital.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Application_Submitted_w_Avidia_Checking</template>
    </alerts>
    <alerts>
        <fullName>RS_Application_Receipt_W_O_Avidia_Bank_Account</fullName>
        <description>RS Application Receipt W/O Avidia Bank Account</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Application_Submitted_wo_Avidia_Checking</template>
    </alerts>
    <alerts>
        <fullName>RS_Change_Order_Rejected</fullName>
        <ccEmails>customerops@bluewavesolar.com.uat, partnersupport@bluewavesolar.com.uat</ccEmails>
        <description>RS - Change Order Rejected</description>
        <protected>false</protected>
        <recipients>
            <recipient>pyao@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>RS_Application_Email_Notifications/RS_Change_Order_Rejected</template>
    </alerts>
    <alerts>
        <fullName>RS_DOER_PreQualificationl_Application_Approved</fullName>
        <description>RS - DOER - Pre-Qualification Application Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>DOER/RS_DOER_PreQualification_Approval</template>
    </alerts>
    <alerts>
        <fullName>RS_Send_Co_App_Credit_Denial_Email1</fullName>
        <ccEmails>solarloans@bluewavesolar.com</ccEmails>
        <description>RS Send Co App Credit Denial Email</description>
        <protected>false</protected>
        <recipients>
            <field>Co_Applicant_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Co_App_Credit_Denial</template>
    </alerts>
    <alerts>
        <fullName>RS_Send_Credit_Denial_Email</fullName>
        <description>RS Send Credit Denial Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Credit_Denial</template>
    </alerts>
    <alerts>
        <fullName>SC_Pre_Qualified_Homeowner</fullName>
        <ccEmails>PartnerSupport@bluewavesolar.com</ccEmails>
        <description>SC Pre-Qualified Homeowner</description>
        <protected>false</protected>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/NC_Pre_Qualified_Homeowner</template>
    </alerts>
    <alerts>
        <fullName>Solar_Loans_Send</fullName>
        <ccEmails>vcoloma@bluewave-capital.com</ccEmails>
        <ccEmails>solarloans@bluewave-capital.com</ccEmails>
        <description>Solar Loans - Send</description>
        <protected>false</protected>
        <recipients>
            <recipient>jpentaleri@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>BFG_Internal_Alerts/File_Upload_Form_Notification</template>
    </alerts>
    <alerts>
        <fullName>Solstice_CS_Application_Receipt</fullName>
        <description>Solstice - CS - Application Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Emails_to_Delete/Solstice_CS_Application_Receipt</template>
    </alerts>
    <fieldUpdates>
        <fullName>BFG_DOER_Solar_Loan</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_DOER_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>BFG - DOER Solar Loan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Lead_Record_Type_Anchor</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_Community_Solar_Anchor</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>CS - Lead Record Type - BFG Community So</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Lead_Record_Type_BFG_Community_So</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_Community_Solar_Business</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>CS - Lead Record Type - BFG Community So</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Lead_Status_Uncontacted</fullName>
        <field>Status</field>
        <literalValue>Uncontacted</literalValue>
        <name>CS - Lead Status - Uncontacted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_Lead_Status_Unqualified</fullName>
        <field>Status</field>
        <literalValue>Unqualified</literalValue>
        <name>CS - Lead Status - Unqualified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_Status_to_Check_Load_Zone</fullName>
        <field>Status</field>
        <literalValue>Load Zone Check Needed</literalValue>
        <name>Change Status to Check Load Zone</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Credit_Partner_Alert_Text</fullName>
        <description>Puts Alert Text when a pre-approval credit check is denied</description>
        <field>Credit_Partner_Alert__c</field>
        <formula>&quot;NOTE: We offer pre-qualification for our lending customers and partners to facilitate the decision making process for purchasing a solar system. Our pre-qualification process is pre-programmed with our standard qualification criteria, but please know that just because a customer cannot be pre-qualified does not mean that we cannot ultimately qualify them with additional information or documentation. Please do not hesitate to give us a call to talk through the approval process.&quot;</formula>
        <name>Credit Partner Alert Text</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Duke_Lead_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Utility_Duke_Energy</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Duke Lead Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Financing_Fee_Override</fullName>
        <field>Financing_Fee_Override__c</field>
        <formula>IF(DOER_Solar_Loan__c == TRUE, 
0, 
IF(Number_of_Periods__c&gt;120, max(1250,0.07*Loan_Amount__c), max(1250,0.05*Loan_Amount__c) 
))</formula>
        <name>Lead Financing Fee Override</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Record_Type_NC_Co_App</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_NC_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Lead Record Type NC Co-App</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Record_Type_SC_Co_App</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_SC_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Lead Record Type SC Co-App</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status</fullName>
        <field>Status</field>
        <literalValue>Pending Credit Review</literalValue>
        <name>Lead Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Load_Zone_Check_Needed</fullName>
        <field>Status</field>
        <literalValue>Load Zone Check Needed</literalValue>
        <name>Lead Status - Load Zone Check Needed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_New</fullName>
        <field>Status</field>
        <literalValue>New</literalValue>
        <name>Lead Status - New</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Qualified</fullName>
        <field>Status</field>
        <literalValue>Qualified</literalValue>
        <name>Lead Status - Qualified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Ready_for_Credit_Check</fullName>
        <field>Status</field>
        <literalValue>Ready for Credit Check</literalValue>
        <name>Lead Status - Ready for Credit Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Ready_for_Credit_nonPortal</fullName>
        <field>Status</field>
        <literalValue>Ready for Credit Check</literalValue>
        <name>Lead Status Ready for Credit nonPortal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Uncontacted</fullName>
        <field>Status</field>
        <literalValue>Uncontacted</literalValue>
        <name>Lead Status - Uncontacted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Status_Unfinished</fullName>
        <field>Status</field>
        <literalValue>Unfinished</literalValue>
        <name>Lead Status - Unfinished</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_owner_is_CS_Application_Queue</fullName>
        <field>OwnerId</field>
        <lookupValue>CS_Applications</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Lead owner is CS Application Queue</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Number_of_Period</fullName>
        <field>Number_of_Periods__c</field>
        <formula>VALUE(TEXT(Loan_Term_Override__c))</formula>
        <name>Number of Periods</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Action_Manual_Credit_Decline</fullName>
        <field>Status</field>
        <literalValue>Unqualified</literalValue>
        <name>RL - Action - Manual Credit Decline</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
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
        <fullName>RL_Lead_Record_Type_NC_Solar_Loan</fullName>
        <description>Changes the Lead Record Type to NC Solar Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_NC_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Lead Record Type - NC Solar Loan</name>
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
        <fullName>RL_Lead_Record_Type_SC_Solar_Loan</fullName>
        <description>Changes the Lead Record Type to SC Solar Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_SC_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - Lead Record Type - SC Solar Loan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_Lead_Update_Status_Modified_Date</fullName>
        <description>Records the date that the Lead MCEC status was last modified.</description>
        <field>MCEC_Status_Last_Modified__c</field>
        <formula>Today()</formula>
        <name>RL - Lead Update Status Modified Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Record_Type_MA_Co_Applicant</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_MA_Solar_Loan_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Record Type MA Co Applicant</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SLP_Pending_Information</fullName>
        <field>Status</field>
        <literalValue>Pending Information</literalValue>
        <name>SLP: Pending Information</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SLP_Ready_for_Credit_Check</fullName>
        <field>Status</field>
        <literalValue>Ready for Credit Check</literalValue>
        <name>SLP - Ready for Credit Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SLP_Ready_for_Credit_notPortal</fullName>
        <field>Status</field>
        <literalValue>Ready for Credit Check</literalValue>
        <name>SLP Ready for Credit nonPortal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SLP_Unfinished</fullName>
        <field>Status</field>
        <literalValue>Unfinished</literalValue>
        <name>SLP Unfinished</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Solar_Loan_Record_Type</fullName>
        <description>Changes the Lead Record Type to Solar Loan if Product Line is Residential Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>BFG_Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Solar Loan Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Testcase</fullName>
        <field>MiddleName</field>
        <formula>&quot;Test&quot;</formula>
        <name>Testcase</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Record_Type_CS</fullName>
        <field>RecordTypeId</field>
        <lookupValue>BFG_Community_Solar</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update Record Type - CS</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Waitlist_Status</fullName>
        <field>Status</field>
        <literalValue>Waitlist</literalValue>
        <name>Waitlist Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_email_re_enter</fullName>
        <field>Email_Re_Enter__c</field>
        <formula>Email</formula>
        <name>update email re enter</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_partner_email</fullName>
        <field>Partner_Email__c</field>
        <formula>bs_Sales_ID__r.Email__c</formula>
        <name>update partner email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Additional File Upload Form Email</fullName>
        <actions>
            <name>Solar_Loans_Send</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.New_File_Upload__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Application Approved Email</fullName>
        <actions>
            <name>RL_Customer_Credit_Approved</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Email_Log_RL_Customer_Credit_Approved</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.IsConverted</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <description>This is the workflow to run when a residential loan (DOER) is converted to an opportunity.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>BWOC Alert PreApproval NonPartner</fullName>
        <actions>
            <name>BWOC_Alert_non_partner_preapproval_lead</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Custom_ID__c</field>
            <operation>equals</operation>
            <value>NOPARTNER</value>
        </criteriaItems>
        <description>Came in through preapproval form without a partner</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Application Waitlist Email</fullName>
        <actions>
            <name>Waitlist_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Customer_is_Waitlisted</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Ready for Credit Check</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Available_Capacity__c</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>CSAP</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>SLPortal</value>
        </criteriaItems>
        <description>Edited to reflect new changes to Available Capacity field calculations. Sets status to waitlist if available capacity is still zero even after they&apos;ve gone through full application</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - BlueWave - Application Receipt Email</fullName>
        <actions>
            <name>BlueWave_CS_Application_Receipt</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>CS_BlueWave_Application_Receipt_Email</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Electricity_Provider__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Sends BW CS Application Receipt email to lead acknowledging receipt</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - BlueWave - Credit Denied Email</fullName>
        <actions>
            <name>BlueWave_CS_Credit_Denied</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>CS_Partner_Appliction_Denied</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_BlueWave_Credit_Denied_Email</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3</booleanFilter>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Unqualified</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Credit_Approval_Status2__c</field>
            <operation>equals</operation>
            <value>Declined</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Installer - Notification Lead has been Created</fullName>
        <actions>
            <name>update_partner_email</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <description>Notify installer that a lead has been created</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Lead Status - Load Zone Check Needed</fullName>
        <actions>
            <name>Lead_Status_Load_Zone_Check_Needed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR(  AND(  CONTAINS(ZipCode__r.LZ__c,&quot;/&quot;),  ISBLANK(LoadZone__c)  ),  AND(  ZipCode__r.Utility_Junction_Count__c &gt; 1, ISBLANK(Utility_relationship__c)  )  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CS - Lead Status - Qualified</fullName>
        <actions>
            <name>Lead_Status_Qualified</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6</booleanFilter>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.load_zone_check_needed__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Contacted__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Available_Capacity__c</field>
            <operation>greaterThan</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>SLPortal</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>CSAP</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Lead Status - Ready for Credit Check</fullName>
        <actions>
            <name>Lead_Status_Ready_for_Credit_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.load_zone_check_needed__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Available_Capacity__c</field>
            <operation>greaterThan</operation>
            <value>1</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Contacted__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>CSAP</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Application_Source_Phase_1__c</field>
            <operation>notContain</operation>
            <value>SLPortal</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Lead Status - Uncontacted</fullName>
        <actions>
            <name>CS_Lead_Status_Uncontacted</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Leads_List__c</field>
            <operation>equals</operation>
            <value>Cotuit Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Contacted__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Lead Status - Unqualified</fullName>
        <actions>
            <name>CS_Lead_Status_Unqualified</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Credit_Approval_Status2__c</field>
            <operation>equals</operation>
            <value>Declined</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.load_zone_check_needed__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Solstice - Application Receipt Email</fullName>
        <actions>
            <name>Solstice_CS_Application_Receipt</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_Solstice_Application_Receipt_Email</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Partner_Name__c</field>
            <operation>equals</operation>
            <value>Solstice initiative</value>
        </criteriaItems>
        <description>Sends CS Application Receipt email to lead acknowledging receipt</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - Solstice - Credit Denied Email</fullName>
        <actions>
            <name>EMAIL_LOG_CS_Solstice_Credit_Denied_Email</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Manual_Credit_Decline__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Partner_Name__c</field>
            <operation>equals</operation>
            <value>Solstice Initiative</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS 24 Hour Notice</fullName>
        <actions>
            <name>CS_24_Hour_Incomplete_Application_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_CS_24_Hour_Notice</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Days_Since_App_Started__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <description>Sends email to CS lead that has yet to complete applicant within a 24 hr span.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Check Load Zone</fullName>
        <actions>
            <name>Change_Status_to_Check_Load_Zone</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND (3 OR 4)</booleanFilter>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.IsConverted</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Utility_1__c</field>
            <operation>includes</operation>
            <value>Eversource / MLP</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Utility_1__c</field>
            <operation>includes</operation>
            <value>National Grid/Eversource</value>
        </criteriaItems>
        <description>Changes status to check load zone if the utility from the application does not equal the utility field generated</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Credit Partner Alert Text</fullName>
        <actions>
            <name>Credit_Partner_Alert_Text</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Unqualified</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Alerts Partner with text if a pre-approval credit check is denied</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>EnergySage Lead Alert</fullName>
        <actions>
            <name>BWOC_EnergySage_Lead_Alert</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.EnergySage_Lead__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Internal Notification%3A CS%2FCL Duplicate Account</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Previous_BW_Applicant__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>When a CS Application comes in with the question &quot;Have you previously applied for a BW loan&quot; populated, send an email alert to Ops</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Lead Status - Record last modified Date</fullName>
        <actions>
            <name>RL_Lead_Update_Status_Modified_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Records the last modified date of the MCEC lead status.</description>
        <formula>or(isnew(),ischanged( Status_for_MCEC_Report__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Lead Status - Uncontacted %28ChooseEnergy%29</fullName>
        <actions>
            <name>Lead_Status_Uncontacted</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Partner_Name__c</field>
            <operation>equals</operation>
            <value>Choose Energy</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Lead Status - Unfinished</fullName>
        <actions>
            <name>Lead_Status_Unfinished</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>NC Pre-Qualified Homeowner</fullName>
        <actions>
            <name>SC_Pre_Qualified_Homeowner</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.LASERCA__Home_State__c</field>
            <operation>equals</operation>
            <value>NC</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>Pre-Qualified</value>
        </criteriaItems>
        <description>Send email alert to Partner Support to create task when lead is NC Pre-Qualified</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - BlueWave - PreQual Application Receipt Email</fullName>
        <actions>
            <name>Application_Receipt_Prequal</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_PreApproval_Application_Receipt</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <description>Sends BW CS Application Receipt email to lead acknowledging receipt</description>
        <formula>AND (  NOT(ISPICKVAL(Product_Program__c,&apos;MSLP&apos;)),  Unfinished_Lead__c = TRUE)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>RL - DOER - Non-Partner Installer email</fullName>
        <actions>
            <name>Non_Partner_Installer_Email_Alert</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3 AND 4 AND 5</booleanFilter>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Self_Reported_Partner__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.DOER_Solar_Loan__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Custom_ID__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Is_there_a_Partner_Record__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <description>Sends email when a new DOER lead comes through with an installer that does not have a referral code</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - DOER - PreQual Application Receipt Email</fullName>
        <actions>
            <name>Application_Receipt_Prequal_DOER</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_PreApproval_Application_Receipt_DOER</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <formula>AND ( ISPICKVAL(Product_Program__c,&apos;MSLP&apos;),  Unfinished_Lead__c = TRUE)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>RL - Email - Application Receipt W%2FAvidia Bank Account</fullName>
        <actions>
            <name>RS_Application_Receipt_W_Avidia_Bank_Account</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RL_Email_Application_Receipt_W_Avidia_Bank_Account</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Avidia_Checking_Account__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Sent to RS applicant after application complete AND Avidia Bank Account desired.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Email - Application Receipt W%2FO Avidia Bank Account</fullName>
        <actions>
            <name>RS_Application_Receipt_W_O_Avidia_Bank_Account</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RL_Email_Application_Receipt_W_O_Avidia_Bank_Account</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2 AND 3</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Avidia_Checking_Account__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Sent to RS applicant after application complete WITHOUT Avidia Bank Account desired.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Installer - Notification - Credit Denied</fullName>
        <actions>
            <name>RL_Installer_Notification_Lead_Unqualified</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>RL_Installer_Notification_Lead_Unqualified</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Manual_Credit_Decline__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Installer - Notification Lead has been Created</fullName>
        <actions>
            <name>RL_Installer_Lead_has_been_Created</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RL_Installer_Notification_Lead_has_been_Created</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2</booleanFilter>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <description>Notify installer that a lead has been created</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Period %28Months%29 Change</fullName>
        <actions>
            <name>Number_of_Period</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Loan_Term_Override__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - Avidia - Email - Manual Credit Decline</fullName>
        <actions>
            <name>Co_Applicant_Link_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Lead_DOER_Credit_Denial_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Lead_DOER_CoApplicant_Form_Link</name>
            <type>Task</type>
        </actions>
        <actions>
            <name>Lead_DOER_Credit_Denial_Email</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>Send email if: 
Manual credit is checked 
if it&apos;s DOER 
if it&apos;s Avidia (if product is populated) 

Products aren&apos;t selected upfront yet, so we need to check the state until we change the process</description>
        <formula>AND(Manual_Credit_Decline__c,       
Product_line__c = &apos;Residential Loan&apos;,
    OR(DOER_Solar_Loan__c,        
    ISPICKVAL(Product__r.Lender_of_Record__c, &apos;Avidia&apos;),
    LASERCA__Home_State__c = &apos;MA&apos;,         
    LASERCA__Home_State__c = &apos;FL&apos;, 
    LASERCA__Home_State__c = &apos;NY&apos;, 
    LASERCA__Home_State__c = &apos;SC&apos;,
    LASERCA__Home_State__c = &apos;NC&apos;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - Change Order Avidia Rejected</fullName>
        <actions>
            <name>RS_Change_Order_Rejected</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISPICKVAL(Change_Order_Status__c, &quot;Reviewed - Rejected&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RS - Non-Avidia - Email - Manual Credit Decline</fullName>
        <actions>
            <name>RS_Send_Credit_Denial_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_RS_Email_Manual_Credit_Decline</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <description>Send email if:
Manual credit is checked
if it&apos;s not DOER
if it&apos;s not an Avidia (if product is populated)

Products aren&apos;t selected upfront yet, so we need to check the state until we change the process</description>
        <formula>AND(Manual_Credit_Decline__c,       
Product_line__c = &apos;Residential Loan&apos;,
     NOT(DOER_Solar_Loan__c),
     NOT(ISPICKVAL(Product__r.Lender_of_Record__c, &apos;Avidia&apos;)), 
     NOT(LASERCA__Home_State__c = &apos;MA&apos;),    
     NOT(LASERCA__Home_State__c = &apos;FL&apos;), 
     NOT(LASERCA__Home_State__c = &apos;NY&apos;),      
     NOT(LASERCA__Home_State__c = &apos;SC&apos;),
     NOT(LASERCA__Home_State__c = &apos;NC&apos;))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>SLP - Pending Information</fullName>
        <actions>
            <name>SLP_Pending_Information</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(ISCHANGED(Unfinished_Lead__c),!Unfinished_Lead__c , NOT(ISNULL(Personal_Credit_Report__c)) , Product_line__c = &quot;Residential Loan&quot;, NOT(TEXT(Status) = &quot;Under BlueWave Review&quot;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>SLP - Ready for Credit Check</fullName>
        <actions>
            <name>SLP_Ready_for_Credit_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>deactivated since this was used as part of the form assembly process. Status is now set through the CAPPersonalInfoHelper and after credit reports have been pulled.</description>
        <formula>AND(
Unfinished_Lead__c, 
Product_line__c = &apos;Residential Loan&apos;
)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>SLP - Ready for Credit Check %28nonPortal%29</fullName>
        <actions>
            <name>SLP_Ready_for_Credit_notPortal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>SLP - Unfinished</fullName>
        <actions>
            <name>SLP_Unfinished</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Unfinished_Lead__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Lead.Product_line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <description>deactivated since this was used as part of the form assembly process. Status is now set through the CAPPersonalInfoHelper and after credit reports have been pulled.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>email updates</fullName>
        <actions>
            <name>update_email_re_enter</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( NOT(ISBLANK(Email))&amp;&amp; ISBLANK( Email_Re_Enter__c), ISCHANGED(Email))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Bluewave_CS_Application_Receipt</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Application Receipt Workflow has fired and email has been sent.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Bluewave - CS - Application Receipt</subject>
    </tasks>
    <tasks>
        <fullName>CS_BlueWave_Application_Receipt_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - BlueWave - Application Receipt Email to Customer using TEMPLATE &quot;CS Customer - Application Received&quot; and to Partner using TEMPLATE &quot;CS Partner Application Submitted&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - BlueWave - Application Receipt Email</subject>
    </tasks>
    <tasks>
        <fullName>Customer_is_Waitlisted</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Customer is Waitlisted</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_24_Hour_Notice</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS 24 Hour Notice using TEMPLATE: &quot;CS Customer - 24 Hour Application Notice&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS 24 Hour Notice</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_BlueWave_Credit_Denied_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - BlueWave - Credit Denied Email using TEMPLATE: &quot;CS Customer - Credit Denied&quot; and to Partner using template &quot;CS Partner - Credit Denied&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - BlueWave - Credit Denied Email</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_Lead_Created_Notification_to_Partner</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Low</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS Lead Created Notification to Partner</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_Solstice_Application_Receipt_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - Solstice - Application Receipt Email using TEMPLATE &quot;Solstice - CS - Application Receipt&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - Solstice - Application Receipt Email</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_CS_Solstice_Credit_Denied_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: CS - Solstice - Credit Denied Email using TEMPLATE: &quot;Solstice - CS - Credit Denied&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: CS - Solstice - Credit Denied Email</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Lead_DOER_CoApplicant_Form_Linik</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Lead - DOER - Credit Denial Email using TEMPLATE: &quot;DOER - Please Complete CoApplicant Form&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Lead - DOER - CoApplicant Form Linik</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Lead_DOER_CoApplicant_Form_Link</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Credit Denial with CoApplicant LInk</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Lead - DOER - CoApplicant Form Linik</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Lead_DOER_Co_Applicant_Credit_Denial_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Lead - DOER - Credit Denial Email using TEMPLATE: &quot;DOER Customer - Co Applicant Credit Denial&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Lead - DOER - Co Applicant Credit Denial Email</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_PreApproval_Application_Receipt</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>template: RS DOER - PreQualification App Reciept</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: PreApproval Application Receipt</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_PreApproval_Application_Receipt_DOER</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>template: RS DOER - PreQualification App Reciept</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: PreApproval Application Receipt DOER</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Email_Application_Receipt_W_Avidia_Bank_Account</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Email - Application Receipt W/Avidia Bank Account 
using TEMPLATE: &quot;RS Customer - Application Submitted w/Avidia Checking&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Email - Application Receipt W/Avidia Bank Account</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Email_Application_Receipt_W_O_Avidia_Bank_Account</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Email - Application Receipt W/O Avidia Bank Account using TEMPLATE: &quot;RS Customer - Application Submitted wo/Avidia Checking&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Email - Application Receipt W/O Avidia Bank Account</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RL_Installer_Notification_Lead_has_been_Created</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Installer - Notification Lead has been Created 
using TEMPLATE: DOER Installer - Application is pending approval</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Installer - Notification Lead has been Created</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RS_Email_Co_App_Manual_Credit_Decline</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RS - Email - Manual Co App Credit Decline 
using TEMPLATE: RS Customer Co App - Credit Denial</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RS - Email - Co App Manual Credit Decline</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_RS_Email_Manual_Credit_Decline</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RS - Email - Manual Credit Decline
using TEMPLATE: RS Customer - Credit Denial</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RS - Email - Manual Credit Decline</subject>
    </tasks>
    <tasks>
        <fullName>Email_Log_PreApproval_Application_Approved</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Customer notified using template RS DOER - PreQualification Approval</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Lead.Today__c</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email Log: PreQualification Application Approved</subject>
    </tasks>
    <tasks>
        <fullName>Email_Log_RL_Customer_Credit_Approved</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Customer and Installer notified using custom email template: 	RL Customer - Credit Approved</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Lead.Today__c</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email Log:  RL Customer - Credit Approved</subject>
    </tasks>
    <tasks>
        <fullName>Lead_DOER_Credit_Denial_Email</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Lead - DOER - Credit Denial Email using TEMPLATE: &quot;DOER Customer - Credit Denial&quot;</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Lead - DOER - Credit Denial Email</subject>
    </tasks>
    <tasks>
        <fullName>RL_Installer_Notification_Lead_Unqualified</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: RL - Installer - Notification - Credit Denied 

using template: RS Partner - Application Credit Denial</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: RL - Installer - Notification - Lead Unqualified</subject>
    </tasks>
</Workflow>
