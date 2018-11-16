<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Month_on_Overall_Loan_Data</fullName>
        <description>Updates the Month on Loan Data every Month to be Current for Avidia Reporting</description>
        <field>Month__c</field>
        <name>Update Month on Overall Loan Data</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>NextValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Loan Month</fullName>
        <active>true</active>
        <description>Updates the Loan Data month to be current with the current month for Avidia Reporting</description>
        <formula>Name != null</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Month_on_Overall_Loan_Data</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
