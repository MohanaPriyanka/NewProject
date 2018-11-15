<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>LASERCA__Trade_Account_Name_Update</fullName>
        <field>Name</field>
        <formula>(LASERCA__Name_of_the_Institution__c  )</formula>
        <name>Trade Account Name Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>LASERCA__Trade Account Name Update</fullName>
        <actions>
            <name>LASERCA__Trade_Account_Name_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>LASERCA__Trade_Accounts__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Creates the trade account name</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
