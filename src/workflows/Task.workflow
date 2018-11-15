<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Internal_Product_Team_Task_is_Complete</fullName>
        <description>Internal_Product_Team_Task_is_Complete</description>
        <protected>false</protected>
        <recipients>
            <field>Requested_By__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>BFG_Internal_Alerts/Requestor_Product_Team_Task_Complete</template>
    </alerts>
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
        <fullName>Set_Task_Start_Date_for_Product_team</fullName>
        <description>Sets the start date of a new task as the date on which that task is created. Set to only apply to product group tasks.</description>
        <field>Start_Date__c</field>
        <formula>today()</formula>
        <name>Set Task Start Date for Product Team</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
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
        <fullName>Product Team Task is Complete</fullName>
        <actions>
            <name>Internal_Product_Team_Task_is_Complete</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Category__c</field>
            <operation>equals</operation>
            <value>Product Team</value>
        </criteriaItems>
        <criteriaItems>
            <field>Task.Status</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <description>Runs when a Product Team Task is complete</description>
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
        <fullName>Set Task Start Date for Product Team</fullName>
        <actions>
            <name>Set_Task_Start_Date_for_Product_team</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Task.Category__c</field>
            <operation>equals</operation>
            <value>Product Team</value>
        </criteriaItems>
        <description>Sets the Task Start Date for Product Team Tasks as the date on which the task was created.</description>
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
