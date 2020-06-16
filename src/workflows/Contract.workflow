<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Contract_Approvals_Final_Approval</fullName>
        <description>Email template which is sent at the end of the Contracts Approval Process to notify for approval.</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Submitted_By__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Contract_Approvals_Final_Approval</template>
    </alerts>
    <alerts>
        <fullName>Contract_Approvals_Final_Rejection</fullName>
        <description>Email template which is sent at the end of the Contracts Approval Process to notify for rejection.</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Submitted_By__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Contract_Approvals_Final_Rejection</template>
    </alerts>
    <fieldUpdates>
        <fullName>Set_Contract_Status_to_Draft</fullName>
        <field>Status</field>
        <literalValue>Draft</literalValue>
        <name>Set Contract Status to Draft</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
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
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <outboundMessages>
        <fullName>Generate_Review_Version</fullName>
        <apiVersion>48.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Review_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Generate Review Version</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Generate_and_Send_SSF_Documents_Signed</fullName>
        <apiVersion>48.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Signed_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Generate and Send SSF Documents (Signed</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>Generate SSF Documents %28Review Version%29</fullName>
        <actions>
            <name>Generate_Review_Version</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Generate_Review_Version__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Generate SSF Documents %28SignedVersion%29</fullName>
        <actions>
            <name>Generate_and_Send_SSF_Documents_Signed</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Generate_Signed_Version__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>