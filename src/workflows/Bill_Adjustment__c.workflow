<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Approve_Adjustment_Request</fullName>
        <description>Approve Adjustment Request</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Adjustment_Approval_Approved</template>
    </alerts>
    <alerts>
        <fullName>Reject_Approval_Request</fullName>
        <description>Reject Approval Request</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Adjustment_Approval_Rejected</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Approval_Status_To_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Set_Approval_Status_To_Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Approval_Status_To_Pending</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending</literalValue>
        <name>Set Approval Status To Pending</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Approval_Status_To_Rejected</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set Approval Status To Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Approval_Status_To_Unapproved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set Approval Status To Unapproved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
