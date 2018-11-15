<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Ops_Alert_New_Partner</fullName>
        <ccEmails>salesops@bluewavesolar.com</ccEmails>
        <description>Ops Alert New Partner</description>
        <protected>false</protected>
        <senderType>DefaultWorkflowUser</senderType>
        <template>BFG_Internal_Alerts/Ops_Email_Alert_New_Partner</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_Partner</fullName>
        <field>Update_Trigger__c</field>
        <literalValue>1</literalValue>
        <name>Update Partner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Ops Email Alert New Partner</fullName>
        <actions>
            <name>Ops_Alert_New_Partner</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Partner__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Sends email to Ops team when new partner is created.</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
