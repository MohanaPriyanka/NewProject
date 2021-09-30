<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Close_SSS_on_Full</fullName>
        <field>Open__c</field>
        <literalValue>0</literalValue>
        <name>Close SSS on Full</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SSS_Update</fullName>
        <field>SSS_Update__c</field>
        <literalValue>2</literalValue>
        <name>SSS Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SSS_Update_to_1</fullName>
        <field>SSS_Update__c</field>
        <literalValue>1</literalValue>
        <name>SSS Update to 1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SSS_Update_to_one</fullName>
        <field>SSS_Update__c</field>
        <literalValue>1</literalValue>
        <name>SSS Update to one</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>SSS_Update_to_two</fullName>
        <field>SSS_Update__c</field>
        <literalValue>2</literalValue>
        <name>SSS Update to two</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_SSS_on_Customer_Reservation</fullName>
        <description>Updates the Shared Solar System&apos;s Reserved Capacity when the Customer Reservation field is changed on the Opportunity.</description>
        <field>Update_Dummy__c</field>
        <literalValue>1</literalValue>
        <name>Update SSS on Customer Reservation</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Close SSS on Full</fullName>
        <actions>
            <name>Close_SSS_on_Full</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c</field>
            <operation>lessThan</operation>
            <value>1</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>SSS Update</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Shared_Solar_System__c.SSS_Update__c</field>
            <operation>equals</operation>
            <value>2</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>SSS_Update_to_one</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>SSS Update II</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Shared_Solar_System__c.SSS_Update__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>SSS_Update_to_two</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>4</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>