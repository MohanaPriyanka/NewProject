<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Alert_CS_CL_Duplicate_Account</fullName>
        <ccEmails>customerops@bluewavesolar.com</ccEmails>
        <description>Alert: CS/CL Duplicate Account (UAL)</description>
        <protected>false</protected>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Duplicate_Account_CS_CL</template>
    </alerts>
    <fieldUpdates>
        <fullName>Partner</fullName>
        <field>Partner__c</field>
        <formula>Lead__r.Partner_Lookup__c</formula>
        <name>Partner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Internal Alert%3A Duplicate CL%2FCS</fullName>
        <actions>
            <name>Alert_CS_CL_Duplicate_Account</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Utility_Account_Log__c.Previous_BW_CL_Applicant__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>UAL_Partner</fullName>
        <actions>
            <name>Partner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Utility_Account_Log__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
