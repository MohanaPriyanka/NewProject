<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Alert_Ops_Avidia_Approval</fullName>
        <ccEmails>solarloans@bluewave-capital.com</ccEmails>
        <description>Alert Ops Avidia Approval</description>
        <protected>false</protected>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>BFG_Internal_Alerts/Solar_Loans_Avidia_Approval_Alert</template>
    </alerts>
    <fieldUpdates>
        <fullName>Avidia_Approval_Override</fullName>
        <field>Solar_Loan_Manual_Approval__c</field>
        <literalValue>1</literalValue>
        <name>Avidia Approval Override</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Avidia_Declined_Override</fullName>
        <field>Solar_Loan_Manual_Decline__c</field>
        <literalValue>1</literalValue>
        <name>Avidia Declined Override</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CS_PCR_Record_Type</fullName>
        <description>Changes the PCR Record Type to Community Solar when the product line is equal to Community Solar</description>
        <field>RecordTypeId</field>
        <lookupValue>Community_Solar</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>CS - PCR Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Credit_Report_Name_to_Include_First_Name</fullName>
        <description>Update Personal Credit Report Name to include the individual&apos;s first name.</description>
        <field>Name</field>
        <formula>Name &amp; &quot;.&quot; &amp; LASERCA__Lead__r.FirstName</formula>
        <name>Credit Report Name to Include First Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>RL_PCR_Record_Type</fullName>
        <description>Changes the PCR Record Type to Solar Loan</description>
        <field>RecordTypeId</field>
        <lookupValue>Solar_Loan</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>RL - PCR Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Add First Name to Personal Credit Report Title</fullName>
        <actions>
            <name>Credit_Report_Name_to_Include_First_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Adds first name to the end of the personal credit report name so as to make these more easily identifiable by record name.</description>
        <formula>isblank(CreatedDate) = false</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Avidia Approval Override</fullName>
        <actions>
            <name>Avidia_Approval_Override</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Avidia_Review_Status__c</field>
            <operation>equals</operation>
            <value>Reviewed - Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Solar_Loan_Approval_Status__c</field>
            <operation>equals</operation>
            <value>,Declined,Pending Review</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Avidia Declined Override</fullName>
        <actions>
            <name>Avidia_Declined_Override</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Avidia_Review_Status__c</field>
            <operation>equals</operation>
            <value>Reviewed - Declined</value>
        </criteriaItems>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Solar_Loan_Approval__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>CS - PCR Record Type</fullName>
        <actions>
            <name>CS_PCR_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Product_Line__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>PCR - Preapproval Email Log</fullName>
        <actions>
            <name>EMAIL_LOG_PreApproval_Email_Sent</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Credit_PreApproval_Email_Sent__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>PCR%3A Avidia Alerts - Reviewed Approved</fullName>
        <actions>
            <name>Alert_Ops_Avidia_Approval</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Avidia_Review_Status__c</field>
            <operation>equals</operation>
            <value>Reviewed - Approved,Reviewed - Pre-Approved,Reviewed - Declined</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>RL - PCR Record Type</fullName>
        <actions>
            <name>RL_PCR_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Personal_Credit_Report__c.Product_Line__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <description>Changes the Personal Credit Report Type to Solar Loan when the product line is Residential Loan</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>EMAIL_LOG_PreApproval_Email_Sent</fullName>
        <assignedTo>api@bluewavesolar.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>EMAIL LOG: PreApproval Email sent via PCRapproval trigger with template 00Xj0000000FYD</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Completed</status>
        <subject>EMAIL LOG: PreApproval Email Sent</subject>
    </tasks>
</Workflow>
