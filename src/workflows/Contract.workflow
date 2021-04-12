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
        <fullName>Conga_Generate_Review_Contract</fullName>
        <apiVersion>49.0</apiVersion>
        <description>Generates the Review version of the contract and attaches it to the contract.</description>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Review_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Conga Generate Review Contract</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Conga_Trigger_Generate_Signed_Contract</fullName>
        <apiVersion>49.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Signed_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Conga Trigger Generate Signed Contract</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Generate_Addendum_Documents</fullName>
        <apiVersion>51.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Addendum__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Generate Addendum Documents</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
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
        <fullName>Generate_and_Send_SSF_Documents_Counte</fullName>
        <apiVersion>48.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Countersigned_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Generate/Send SSF Docs (Countersigned)</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Generate_and_Send_SSF_Documents_Signed</fullName>
        <apiVersion>48.0</apiVersion>
        <endpointUrl>https://workflow.congamerge.com/OBMListener.ashx</endpointUrl>
        <fields>Conga_Signed_Contract__c</fields>
        <fields>Id</fields>
        <includeSessionId>true</includeSessionId>
        <integrationUser>api@bluewavesolar.com</integrationUser>
        <name>Generate and Send SSF Documents (Signed</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>Generate Review Version</fullName>
        <actions>
            <name>Conga_Generate_Review_Contract</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Generate_Review_Version__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Generates the review version of customer contracts</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
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
    <rules>
        <fullName>Generate Signed Version</fullName>
        <actions>
            <name>Conga_Trigger_Generate_Signed_Contract</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Generate_Signed_Version__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Generates the Signed version of customer contracts</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Generate and Send SSF Documents %28Countersigned Version%29</fullName>
        <actions>
            <name>Generate_and_Send_SSF_Documents_Counte</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract.Generate_Countersigned_Version__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>