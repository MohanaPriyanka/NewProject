<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>De_Activate_Partner_Alert</fullName>
        <description>De-Activates the partner alert on the expiration date of that alert.</description>
        <field>Active__c</field>
        <literalValue>0</literalValue>
        <name>De-Activate Partner Alert</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Partner Alert - De-Activate on Expiration Date</fullName>
        <actions>
            <name>De_Activate_Partner_Alert</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Partner_Alert__c.Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Partner_Alert__c.Expiration_Date_Optional__c</field>
            <operation>equals</operation>
            <value>TODAY</value>
        </criteriaItems>
        <description>De-Activates the partner alert on the expiration date of that alert.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
