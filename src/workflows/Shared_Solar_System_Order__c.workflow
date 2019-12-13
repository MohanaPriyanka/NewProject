<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Approval_Alert_SSSO</fullName>
        <description>Approval Alert: SSSO</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Final_Approval_SSSO</template>
    </alerts>
    <alerts>
        <fullName>Rejection_Alert_SSSO</fullName>
        <description>Rejection Alert: SSSO</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Final_Rejection_SSSO</template>
    </alerts>
    <fieldUpdates>
        <fullName>Reset_Status</fullName>
        <field>Approval_Status__c</field>
        <literalValue>New</literalValue>
        <name>Reset Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Date_Approved</fullName>
        <field>Date_Approved__c</field>
        <formula>Today()</formula>
        <name>Set Date Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Set Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Pending_Approval</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Approval</literalValue>
        <name>Set Status to Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Status_to_Rejected</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set Status to Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>