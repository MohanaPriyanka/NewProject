<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Unique_SREC_Name_2</fullName>
        <field>Unique_SREC_Name2__c</field>
        <formula>Unique_SREC_Name__c</formula>
        <name>Update Unique SREC Name 2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Unique SREC Name Update</fullName>
        <actions>
            <name>Update_Unique_SREC_Name_2</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Unique_SREC_Name__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
