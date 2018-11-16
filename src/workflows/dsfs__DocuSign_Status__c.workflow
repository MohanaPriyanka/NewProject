<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>DS_Partner_Status</fullName>
        <field>DS_Partner__c</field>
        <formula>dsfs__Opportunity__r.OwnerId</formula>
        <name>DS - Partner (Status)</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>void_reason</fullName>
        <field>dsfs__Voided_Reason__c</field>
        <formula>&quot;Co App didn&apos;t sign in 3 days&quot;</formula>
        <name>void reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <outboundMessages>
        <fullName>Void_Envelope</fullName>
        <apiVersion>40.0</apiVersion>
        <endpointUrl>https://dsfs.cs52.visual.force.com/apex/dsfs__DocuSignVoidEnvelopeStandAlone?e=</endpointUrl>
        <fields>Id</fields>
        <fields>dsfs__DocuSign_Envelope_ID__c</fields>
        <fields>dsfs__Voided_Reason__c</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>lalexander@bluewavesolar.com</integrationUser>
        <name>Void Envelope</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>DS - Partner %28Status%29</fullName>
        <actions>
            <name>DS_Partner_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>dsfs__DocuSign_Status__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Void Envelope</fullName>
        <actions>
            <name>void_reason</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Void_Envelope</name>
            <type>OutboundMessage</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>dsfs__DocuSign_Status__c.Auto_Voided__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
