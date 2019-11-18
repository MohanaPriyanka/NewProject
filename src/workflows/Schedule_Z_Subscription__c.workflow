<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Add_Number_of_Decimals</fullName>
        <field>Number_of_Decimal_Places__c</field>
        <formula>Schedule_Z__r.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c</formula>
        <name>Add Number of Decimals</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Add_System_Size</fullName>
        <field>System_Size_kW_DC__c</field>
        <formula>Schedule_Z__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c</formula>
        <name>Add System Size</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Schedule Z Subscription Created</fullName>
        <actions>
            <name>Add_Number_of_Decimals</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Add_System_Size</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISBLANK(System_Size_kW_DC__c) || ISBLANK(Number_of_Decimal_Places__c)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>