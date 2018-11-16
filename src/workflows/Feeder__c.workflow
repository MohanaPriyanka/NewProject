<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Unique_Feeder_Name_Check</fullName>
        <field>Unique_Feeder_Name__c</field>
        <formula>Name</formula>
        <name>Unique Feeder Name Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Unique Feeder Name Check</fullName>
        <actions>
            <name>Unique_Feeder_Name_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This Workflow prevents duplicate Feeder Designation names from being created</description>
        <formula>OR(
  ISNEW(),
  ISCHANGED(Name)
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
