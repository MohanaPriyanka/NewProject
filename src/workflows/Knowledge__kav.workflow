<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_to_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Update to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_to_Pending_Approval</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Approval</literalValue>
        <name>Update to Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <knowledgePublishes>
        <fullName>Publish_Articles</fullName>
        <action>Publish</action>
        <label>Publish Article</label>
        <language>en_US</language>
        <protected>false</protected>
    </knowledgePublishes>
</Workflow>
