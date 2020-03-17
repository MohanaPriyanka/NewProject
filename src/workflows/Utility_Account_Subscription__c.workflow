<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Project_Co_Timestamp</fullName>
        <field>Project_Co_Assignment_Date__c</field>
        <formula>NOW()</formula>
        <name>Project Co Timestamp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Record_Type_to_Schedule_Z_Lock</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Utility_Account_Subscription_on_Schedule_Z</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Record Type to Schedule Z Lock</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Reset_Password</fullName>
        <field>Unlock_Password__c</field>
        <name>Reset Password</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Schedule_Z_Field_Unlock</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Utility_Account_Subscription_Editable</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Schedule Z Field Unlock</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UAS_Net_Metering_Credit_Update</fullName>
        <description>Updates the Net Metering Credit value on the UAS at point of sale.</description>
        <field>Net_Metering_Credit_Rate__c</field>
        <formula>Opportunity__r.NMC_Tariff__r.Value_of_Net_Metering_Credit__c</formula>
        <name>UAS - Net Metering Credit Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UAS_Update_Maximum_Cost</fullName>
        <field>calculated_annual_cost_of_electricity__c</field>
        <formula>Annual_Cost_of_Electricity__c</formula>
        <name>UAS - Update Maximum Cost</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UAS - Net Metering Credit Update</fullName>
        <actions>
            <name>UAS_Net_Metering_Credit_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Utility_Account_Subscription__c.Customer_Subscription_KW_DC__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UAS - Update Maximum Cost</fullName>
        <actions>
            <name>UAS_Update_Maximum_Cost</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Utility_Account_Subscription__c.UAS_Number__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UAS%3A Project Co Assignment Date</fullName>
        <actions>
            <name>Project_Co_Timestamp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Utility_Account_Subscription__c.Project_Company__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Timestamps when the UAS is assigned to a project co</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>