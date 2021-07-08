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
</Workflow>