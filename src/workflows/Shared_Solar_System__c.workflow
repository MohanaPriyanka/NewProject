<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Close_SSS_on_Full</fullName>
        <field>Open__c</field>
        <literalValue>0</literalValue>
        <name>Close SSS on Full</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Close SSS on Full</fullName>
        <actions>
            <name>Close_SSS_on_Full</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c</field>
            <operation>lessThan</operation>
            <value>1</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>