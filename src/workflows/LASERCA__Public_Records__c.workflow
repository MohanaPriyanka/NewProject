<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>LASERCA__Public_Records_Name_Update</fullName>
        <field>Name</field>
        <formula>(  LASERCA__Type__c  )</formula>
        <name>Public Records Name Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>true</protected>
    </fieldUpdates>
    <rules>
        <fullName>LASERCA__Public Records Name Update</fullName>
        <actions>
            <name>LASERCA__Public_Records_Name_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>LASERCA__Public_Records__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
