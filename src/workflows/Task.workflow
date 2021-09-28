<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Record_Type_to_Customer_Care</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Customer_Care_Task</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Record Type to Customer Care</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Task_Status_to_New</fullName>
        <description>Sets task Status to &apos;New&apos;</description>
        <field>Status</field>
        <literalValue>New</literalValue>
        <name>Set Task Status to &apos;New&apos;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Task_Complete_Date</fullName>
        <description>Populates TASK field: Actual Complete Date to the date on which the record is marked complete.</description>
        <field>Actual_Complete_Date__c</field>
        <formula>today()</formula>
        <name>Update Task Complete Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Actual Complete Date</fullName>
        <actions>
            <name>Task_Complete_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Status</field>
            <operation>equals</operation>
            <value>Completed,Unsuccesful</value>
        </criteriaItems>
        <description>Populates TASK field: Actual Complete Date upon task completion</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Ring Central Call</fullName>
        <actions>
            <name>Record_Type_to_Customer_Care</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>(1 OR 2) AND (3 OR 4 OR 5 OR 6 OR 7 OR 8)</booleanFilter>
        <criteriaItems>
            <field>Task.Subject</field>
            <operation>contains</operation>
            <value>Outbound to</value>
        </criteriaItems>
        <criteriaItems>
            <field>Task.Subject</field>
            <operation>contains</operation>
            <value>Inbound from</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>operations@bluewave-capital.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>info@bluewave-capital.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>arand@bluewavesolar.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>agarvin@bluewavesolar.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>aschulte@bluewavesolar.com</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.Username</field>
            <operation>equals</operation>
            <value>vcoloma@bluewavesolar.com</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Status on New Prodcut Tasks</fullName>
        <actions>
            <name>Set_Task_Status_to_New</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Category__c</field>
            <operation>equals</operation>
            <value>Product Team</value>
        </criteriaItems>
        <criteriaItems>
            <field>Task.OwnerId</field>
            <operation>notEqual</operation>
            <value>BlueWave Customer Care</value>
        </criteriaItems>
        <criteriaItems>
            <field>Task.Status</field>
            <operation>equals</operation>
            <value>New Submittal</value>
        </criteriaItems>
        <description>When Product tasks are assigned to someone other than BlueWave Customer Care</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>