<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_QSS_Via_Email</fullName>
        <description>Send QSS Via Email</description>
        <protected>false</protected>
        <recipients>
            <field>Send_to_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/Loan_Sales_Sheet_Email_to_Customer</template>
    </alerts>
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
    <rules>
        <fullName>Conga Workflow%3A Generate Doc</fullName>
        <actions>
            <name>Conga_Generate_Doc</name>
            <type>OutboundMessage</type>
        </actions>
        <actions>
            <name>Workflow_Fired</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Quick_Sales_Sheet__c.Generate_Doc__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Link is Populated</fullName>
        <actions>
            <name>Send_QSS_Via_Email</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Email_LOG_Loan_Sales_Sheet_Sent</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <formula>AND( 
ISCHANGED( Link_to_File__c ) , 
Link_to_File__c != &quot;notgenerated&quot; ,
NOT(ISBLANK(Send_to_Email__c))
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>Email_LOG_Loan_Sales_Sheet_Sent</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: Loan Sales Sheet Sent via workflow: 01Q0a0000000fvD</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Email LOG: Loan Sales Sheet Sent</subject>
    </tasks>
    <tasks>
        <fullName>Workflow_Fired</fullName>
        <assignedTo>jpentaleri@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>Conga Fired</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Workflow Fired</subject>
    </tasks>
    <tasks>
        <fullName>Workflow_Fired_with_State_Incentive_Template</fullName>
        <assignedTo>jpentaleri@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>Workflow Fired with State Incentive Template</subject>
    </tasks>
</Workflow>
