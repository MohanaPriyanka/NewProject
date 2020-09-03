<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <outboundMessages>
        <fullName>Conga_Generate_Doc</fullName>
        <apiVersion>39.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Id</fields>
        <fields>Quick_Sales_Sheet__c</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Conga Generate Doc</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Conga_Generate_Doc_With_State_Incentive</fullName>
        <apiVersion>40.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Id</fields>
        <fields>Quick_Sales_Sheet__c</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>jpentaleri@bluewavesolar.com</integrationUser>
        <name>Conga Generate Doc With State Incentive</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
</Workflow>