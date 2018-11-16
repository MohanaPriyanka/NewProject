<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>OFAC_Hit</fullName>
        <description>OFAC Hit</description>
        <protected>false</protected>
        <recipients>
            <recipient>customercare@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>jpentaleri@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>operations@bluewave-capital.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Emails_to_Delete/OFAC_Hit_Warning</template>
    </alerts>
    <rules>
        <fullName>OFAC Hit Warning</fullName>
        <actions>
            <name>OFAC_Hit</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>LASERCA__Regulatory_Product__c.LASERCA__Source_Type__c</field>
            <operation>equals</operation>
            <value>OFAC</value>
        </criteriaItems>
        <criteriaItems>
            <field>LASERCA__Regulatory_Product__c.LASERCA__Result_Status_Type__c</field>
            <operation>contains</operation>
            <value>Hit</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
