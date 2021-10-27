<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Lead_Assignment_Notification</fullName>
        <description>Lead Assignment Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>CS_Application_Email_Notifications/Lead_Assignment_Notification</template>
    </alerts>
    <fieldUpdates>
        <fullName>Lead_Status_Load_Zone_Check_Needed</fullName>
        <field>Status</field>
        <literalValue>Load Zone Check Needed</literalValue>
        <name>Lead Status - Load Zone Check Needed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>CS - Lead Status - Load Zone Check Needed</fullName>
        <actions>
            <name>Lead_Status_Load_Zone_Check_Needed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR(  AND(  CONTAINS(ZipCode__r.LZ__c,&quot;/&quot;),  ISBLANK(LoadZone__c)  ),  AND(  ZipCode__r.Utility_Junction_Count__c &gt; 1, ISBLANK(Utility_relationship__c)  )  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>