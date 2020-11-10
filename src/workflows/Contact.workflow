<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Internal_RL_Co_Applicant_Added</fullName>
        <ccEmails>solarloans@bluewavesolar.com</ccEmails>
        <description>Internal - RL - Co Applicant Added</description>
        <protected>false</protected>
        <recipients>
            <recipient>vcoloma@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/New_RL_Joint_Applicant</template>
    </alerts>
    <fieldUpdates>
        <fullName>Contact_Record_Type_Co_Applicant</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Contact_Co_Applicant</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Contact - Record Type - Co-Applicant</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact_Record_Type_Community_Solar</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Community_Solar_Contact</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Contact - Record Type - Community Solar</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Contact - Record Type - Co-Applicant</fullName>
        <actions>
            <name>Contact_Record_Type_Co_Applicant</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <criteriaItems>
            <field>Contact.Application_Type__c</field>
            <operation>equals</operation>
            <value>Joint</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Contact - Record Type - Community Solar</fullName>
        <actions>
            <name>Contact_Record_Type_Community_Solar</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Account.Product_Line__c = &apos;Community Solar&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>Email_Account_is_3_Days_Past_Due</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>This email makes up for the 3 day warning that these customers should have gotten this month but did not</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email: Account is 3 Days Past Due</subject>
    </tasks>
</Workflow>