<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
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