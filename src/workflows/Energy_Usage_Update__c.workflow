<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Date_Autpay_QCed</fullName>
        <field>Date_Autopay_QCed__c</field>
        <formula>TODAY()</formula>
        <name>Date: Autpay QCed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Bills_Generated</fullName>
        <field>Date_Credit_Transfers_QCed__c</field>
        <formula>TODAY()</formula>
        <name>Date Bills Generated</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Bills_QCed</fullName>
        <field>Date_Bills_QCed__c</field>
        <formula>TODAY()</formula>
        <name>Date Bills QCed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Email_Bills_Sent</fullName>
        <field>Date_Email_Bills_Sent__c</field>
        <formula>TODAY()</formula>
        <name>Date Email Bills Sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Paper_Bills_Sent</fullName>
        <field>Date_Letter_Bills_Sent__c</field>
        <formula>TODAY()</formula>
        <name>Date Paper Bills Sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Host_Account_Bill_QCed</fullName>
        <field>Date_Host_Account_Bill_QCed__c</field>
        <formula>TODAY()</formula>
        <name>Host Account Bill QCed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Production_Update_Record_Type_CS</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Production_Update_CS</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Production Update - Record Type - CS</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Production_Update_Record_Type_RL</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Production_Update_RL</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Production Update - Record Type - RL</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Host_Account_Bills_QCed</fullName>
        <field>Date_Host_Bill_Uploaded__c</field>
        <formula>TODAY()</formula>
        <name>Update Date Host Account Bills QCed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Date Autopay QCed</fullName>
        <actions>
            <name>Date_Autpay_QCed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Autopay QCed&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Bills QCed</fullName>
        <actions>
            <name>Date_Bills_QCed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Bills QCed&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Credit Transfers QCed</fullName>
        <actions>
            <name>Date_Bills_Generated</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND( 
ISCHANGED ( Bill_Status__c ) , 
ISPICKVAL( Bill_Status__c, &quot;Credit Transfers QCed&quot; ) 
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Email Bills Sent</fullName>
        <actions>
            <name>Date_Email_Bills_Sent</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Email Bills Sent&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Host Account Bill QCed</fullName>
        <actions>
            <name>Host_Account_Bill_QCed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Host Account Bill QCed&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Host Account Bill Uploaded</fullName>
        <actions>
            <name>Update_Date_Host_Account_Bills_QCed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Host Account Bill Uploaded&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Date Paper Bills Sent</fullName>
        <actions>
            <name>Date_Paper_Bills_Sent</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>AND(
ISCHANGED ( Bill_Status__c  ) , 
ISPICKVAL( Bill_Status__c, &quot;Letter Bills Sent&quot; )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Production Update - Record Type - CS</fullName>
        <actions>
            <name>Production_Update_Record_Type_CS</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Energy_Usage_Update__c.Product_LIne__c</field>
            <operation>equals</operation>
            <value>Community Solar</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Production Update - Record Type - RL</fullName>
        <actions>
            <name>Production_Update_Record_Type_RL</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Energy_Usage_Update__c.Product_LIne__c</field>
            <operation>equals</operation>
            <value>Residential Loan</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>