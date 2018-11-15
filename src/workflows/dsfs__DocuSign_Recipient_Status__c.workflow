<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>CS_Customer_Contract_Expiration_Reminder</fullName>
        <description>CS Customer Contract Expiration Reminder used by DocuSign Void Envelopes Process Builder</description>
        <protected>false</protected>
        <recipients>
            <field>dsfs__DocuSign_Recipient_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/CS_Customer_Reminder_to_Sign_Contract</template>
    </alerts>
    <alerts>
        <fullName>RL_Customer_Contract_Expiration_Reminder</fullName>
        <description>RL Customer Contract Expiration Reminder used by DocuSign Void Envelopes Process Builder</description>
        <protected>false</protected>
        <recipients>
            <field>dsfs__DocuSign_Recipient_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>RS_Application_Email_Notifications/RS_Customer_Reminder_to_Sign_Contract</template>
    </alerts>
</Workflow>
