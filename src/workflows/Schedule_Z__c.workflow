<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Date_Enacted_by_Utility</fullName>
        <field>Date_Enacted_by_Utility__c</field>
        <formula>TODAY()</formula>
        <name>Date Enacted by Utility</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Executed_by_Asset_Owner</fullName>
        <field>Date_Executed_by_Asset_Owner__c</field>
        <formula>TODAY()</formula>
        <name>Date Executed by Asset Owner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Rejected_by_Utility</fullName>
        <field>Date_Rejected_by_Utility__c</field>
        <formula>TODAY()</formula>
        <name>Date Rejected by Utility</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Replaced_with_Newly_Enacted_Sch_Z</fullName>
        <field>Date_Replaced_with_Newly_Enacted_Sch_Z__c</field>
        <formula>TODAY()</formula>
        <name>Date Replaced with newly Enacted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Stamp_QC</fullName>
        <field>Date_QC_Complete__c</field>
        <formula>TODAY()</formula>
        <name>Date Stamp QC</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Submitted_to_Utility</fullName>
        <field>Date_Submitted_to_Utility__c</field>
        <formula>TODAY()</formula>
        <name>Date Submitted to Utility</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Next_Schedule_Z_Date</fullName>
        <field>Next_Schedule_Z_Date__c</field>
        <formula>DATE( 

YEAR(TODAY() ) + FLOOR((MONTH(TODAY() ) + 6 - 1)/12), 

CASE(MOD(MONTH(TODAY() ) + 6, 12 ), 0, 12, MOD(MONTH(TODAY() )+ 6, 12 )), 


MIN(DAY(TODAY() ), CASE(MOD(MONTH(TODAY() ) + 6,12), 9, 30, 4, 30, 6, 30, 11, 30, 2, 

IF(MOD(YEAR(TODAY() ) + FLOOR((MONTH(TODAY() ) + 6)/12), 400) = 0 || (MOD(YEAR(TODAY() ) + FLOOR((MONTH(TODAY() ) + 6)/12), 4) = 0 &amp;&amp; MOD(YEAR(TODAY() ) + FLOOR((MONTH(TODAY() ) + 6)/12), 100) &lt;&gt; 0 ), 29,28), 31)))</formula>
        <name>Next Schedule Z Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Schedule_Z_Id</fullName>
        <field>Schedule_Z_Id__c</field>
        <formula>Shared_Solar_System__r.Name&amp;&quot; #&quot;&amp; TEXT(Shared_Solar_System__r.Count_of_Schedule_Zs__c + 1)</formula>
        <name>Schedule Z Id</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Date_Billing</fullName>
        <field>Date_Billing__c</field>
        <formula>TODAY()</formula>
        <name>Set Date Billing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Timestamp_QC_Start_Date_field</fullName>
        <field>QC_Start_Date__c</field>
        <formula>TODAY()</formula>
        <name>Timestamp QC Start Date field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Date Enacted by Utility</fullName>
        <actions>
            <name>Date_Enacted_by_Utility</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Enacted by Utility</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Date Executed by Asset Owner</fullName>
        <actions>
            <name>Date_Executed_by_Asset_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Executed by Asset Owner</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Date QC Complele</fullName>
        <actions>
            <name>Date_Stamp_QC</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>QC Complete</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Date Rejected by Utility</fullName>
        <actions>
            <name>Date_Rejected_by_Utility</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Rejected by Utility</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Date Replaced with newly Enacted</fullName>
        <actions>
            <name>Date_Replaced_with_Newly_Enacted_Sch_Z</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Replaced with newly Enacted Schedule Z</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Date Submitted to Utility</fullName>
        <actions>
            <name>Date_Submitted_to_Utility</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Submitted to Utility</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Next Schedule Z Date and Schedule Z ID</fullName>
        <actions>
            <name>Schedule_Z_Id</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Schedule_Z__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>QC Start Date</fullName>
        <actions>
            <name>Timestamp_QC_Start_Date_field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>QC in Process</value>
        </criteriaItems>
        <description>timestamp</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Schedule Z Billing Date</fullName>
        <actions>
            <name>Set_Date_Billing</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Schedule_Z__c.Status__c</field>
            <operation>equals</operation>
            <value>Billing</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Status updated</fullName>
        <active>false</active>
        <formula>OR( TEXT(Status__c) == &quot;QC in Process&quot;, TEXT(Status__c) == &quot;QC Complete&quot;)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
