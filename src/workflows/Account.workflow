<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Recurring_Billing_Reciept</fullName>
        <description>Recurring Billing Reciept</description>
        <protected>false</protected>
        <recipients>
            <field>Send_Bills_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <recipient>jpentaleri@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Billing_Emails/CS_Recurring_Payments</template>
    </alerts>
    <alerts>
        <fullName>Sales_Partner_Application_Submitted_Notification</fullName>
        <description>Sales Partner Application Submitted Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>Partner_Application_QC_Team</recipient>
            <type>group</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Partner_App_Submitted_Alert_Internal</template>
    </alerts>
    <fieldUpdates>
        <fullName>Account_Partner_Name_Update_Sharing</fullName>
        <field>Partner_Name_Text__c</field>
        <formula>Partner_Name__c</formula>
        <name>Account - Partner Name Update - Sharing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Account_Record_Type_Residential_Loan</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Residential_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Account Record Type - Residential Loan</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Email_Sent</fullName>
        <field>Date_Cancellation_Email_Sent__c</field>
        <formula>TODAY()</formula>
        <name>Date Email Sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Invoiced_Amount</fullName>
        <field>Cancellation_Fees_Invoiced__c</field>
        <formula>1250* Number_of_Contracts_to_Cancel__c</formula>
        <name>Invoiced Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account - Partner Name Update - Sharing</fullName>
        <actions>
            <name>Account_Partner_Name_Update_Sharing</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Partner_Name__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Cancellation Date Email Sent</fullName>
        <actions>
            <name>Date_Email_Sent</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Invoiced_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.Cancellation_Notice_Type__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Number_of_Contracts_to_Cancel__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - Account Record Type</fullName>
        <actions>
            <name>Account_Record_Type_Residential_Loan</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <description>Changes the Account Record Type to Residential Loan</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>EMAIL_LOG_Recurring_Billing_Receipt</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Recurring Billing email via this workflow https://na16.salesforce.com/01Qj0000000Eesk</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Recurring Billing Receipt</subject>
    </tasks>
    <tasks>
        <fullName>Email_Account_is_3_Days_Past_Due</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Sent manually because these customers did not get 3 day warning before due date</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email: Account is 3 Days Past Due</subject>
    </tasks>
    <tasks>
        <fullName>emailis3dayspastude</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email: Account is 3 Days Past Due</subject>
    </tasks>
</Workflow>