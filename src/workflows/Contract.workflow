<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Status_to_Activated</fullName>
        <description>This is one of the automatic final approval actions, which set the Status field to &apos;Activated&apos;.</description>
        <field>Status</field>
        <literalValue>Activated</literalValue>
        <name>Set Status to Activated</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_In_Approval_Process</fullName>
        <description>This is one of the automatic initial submission actions, which set the Status field to &apos;In Approval Process&apos;.</description>
        <field>Status</field>
        <literalValue>In Approval Process</literalValue>
        <name>Set Status to In Approval Process</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
