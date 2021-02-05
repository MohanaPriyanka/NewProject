<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>CFD_Approval_Rejected</fullName>
        <description>CFD Approval Rejected</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Product_Team/CFD_Approval_Rejection</template>
    </alerts>
    <alerts>
        <fullName>CFD_Approved</fullName>
        <description>CFD Approved</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Product_Team/CFD_Approval_Approved</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Status_to_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Set Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_status_to_Draft</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Draft</literalValue>
        <name>Set status to &quot;Draft&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_status_to_In_Approval</fullName>
        <field>Approval_Status__c</field>
        <literalValue>In Approvals</literalValue>
        <name>Set status to &quot;In Approval&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>