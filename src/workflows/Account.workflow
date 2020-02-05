<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Payment_Receipt</fullName>
        <description>Payment Receipt</description>
        <protected>false</protected>
        <recipients>
            <field>Send_Bills_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Billing_Emails/CS_Customer_Payment_Received</template>
    </alerts>
    <alerts>
        <fullName>Payment_Received_AmpRed</fullName>
        <description>Payment Received AmpRed</description>
        <protected>false</protected>
        <recipients>
            <field>Additional_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Send_Bills_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Billing_Emails/CS_Customer_Payment_Received_AmpRed</template>
    </alerts>
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
        <fullName>X3_Days_Past_Due</fullName>
        <description>3 Days Past Due</description>
        <protected>false</protected>
        <recipients>
            <field>Send_Bills_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Billing_Emails/Bill_Late_3_Days</template>
    </alerts>
    <alerts>
        <fullName>x3dayspastdue</fullName>
        <description>3 Days Past Due</description>
        <protected>false</protected>
        <recipients>
            <field>Send_Bills_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>CS_Billing_Emails/Bill_Late_3_Days</template>
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
        <fullName>CS %3A Recurring Billing Receipt Email</fullName>
        <actions>
            <name>Recurring_Billing_Reciept</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Recurring_Billing_Receipt</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <formula>AND(ISCHANGED(Recurring_Billing__c), Recurring_Billing__c=TRUE, RecordTypeId!=&apos;012j00000010Ha3&apos;,  Total_Billed__c &gt; 0)</formula>
        <triggerType>onAllChanges</triggerType>
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
        <fullName>Payment Receipt %28AmpRed%29</fullName>
        <actions>
            <name>Payment_Received_AmpRed</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Payment_Receipt_AmpRed</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <formula>AND(ISPICKVAL(Client_Brand_Key__c, &quot;AmpRed&quot;), 
ISCHANGED(Date_of_Last_Payment__c))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Payment Receipt %28Bluewave Logo%29</fullName>
        <actions>
            <name>Payment_Receipt</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>EMAIL_LOG_Payment_Receipt</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <formula>AND(NOT(ISPICKVAL(Client_Brand_Key__c, &quot;AmpRed&quot;)), 
ISCHANGED(Date_of_Last_Payment__c))</formula>
        <triggerType>onAllChanges</triggerType>
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
        <fullName>EMAIL_LOG_Payment_Receipt</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Using workflow: https://na16.salesforce.com/01Qj0000000Ed3M</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Payment Receipt</subject>
    </tasks>
    <tasks>
        <fullName>EMAIL_LOG_Payment_Receipt_AmpRed</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: Payment Receipt AmpRed</subject>
    </tasks>
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