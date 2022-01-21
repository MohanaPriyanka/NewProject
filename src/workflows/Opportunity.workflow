<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>CS_Opportunity_Complete_Email</fullName>
        <description>CS Opportunity Complete Email</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@perchenergy.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CSCustOnboard_Auto_SF/CS_Customer_Executed_Survey</template>
    </alerts>
    <alerts>
        <fullName>CS_Partner_Contract_Complete</fullName>
        <description>CS Partner - Contract Complete - sent via the Portal_Activation flow</description>
        <protected>false</protected>
        <recipients>
            <field>Partner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Salesperson_Email_2__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@perchenergy.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CSPartnerEmails/Cust_Application_Finalized</template>
    </alerts>
    <fieldUpdates>
        <fullName>CS_RL_Stage_Update_Declined</fullName>
        <field>StageName</field>
        <literalValue>Cancelled</literalValue>
        <name>CS/RL Stage Update - Declined</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Email_Sent_Box</fullName>
        <field>CS_Application_Approval_Email_Sent__c</field>
        <literalValue>1</literalValue>
        <name>Check Email Sent Box</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_Stage_to_Contract_Pending</fullName>
        <field>StageName</field>
        <literalValue>Contract Pending</literalValue>
        <name>Opp Stage to Contract Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Name_Remove_Hyphen</fullName>
        <field>Name</field>
        <formula>SUBSTITUTE( Name , &apos;-&apos;, &apos;&apos;)</formula>
        <name>Opportunity Name - Remove Hyphen</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_BW_Signature</fullName>
        <field>StageName</field>
        <literalValue>Pending Perch Signature</literalValue>
        <name>Opportunity Stage - Perch Signature</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_Expired</fullName>
        <field>StageName</field>
        <literalValue>Expired</literalValue>
        <name>Opportunity Stage - Expired</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
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
        <reevaluateOnChange>false</reevaluateOnChange>
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
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_complete</fullName>
        <field>StageName</field>
        <literalValue>Complete</literalValue>
        <name>Opportunity Stage - Complete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_CC_Email</fullName>
        <field>Partner_Additional_Email__c</field>
        <formula>Partner_Additional_Email_Formula__c</formula>
        <name>Partner CC Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_Email_Update</fullName>
        <field>Partner_Email__c</field>
        <formula>Partner_Email_2__c</formula>
        <name>Partner Email Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Partner_additional_cc</fullName>
        <field>Partner_Additional_Email_2_of_2__c</field>
        <formula>Partner_Email_3__c</formula>
        <name>Partner additional cc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Contract_Close_Date</fullName>
        <field>Contract_Close_Date__c</field>
        <formula>TODAY()</formula>
        <name>Set Contract Close Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <flowActions>
        <fullName>Stage_is_change_to_complete</fullName>
        <flow>Update_Partner_Flow</flow>
        <label>Stage is change to complete</label>
        <language>en_US</language>
        <protected>false</protected>
    </flowActions>
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
