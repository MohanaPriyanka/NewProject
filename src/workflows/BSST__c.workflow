<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Salesperson_Setup_Email_Northeast</fullName>
        <ccEmails>whowe@bluewavesolar.com, jmallaghan@bluewavesolar.com</ccEmails>
        <description>Salesperson Setup Email Northeast</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>All_Email_Templates/Salesperson_Onboarding</template>
    </alerts>
    <alerts>
        <fullName>Salesperson_Setup_Email_Southeast</fullName>
        <ccEmails>jotis@bluewavesolar.com</ccEmails>
        <description>Salesperson Setup Email Southeast</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>All_Email_Templates/Salesperson_Onboardingsoutheast</template>
    </alerts>
</Workflow>
