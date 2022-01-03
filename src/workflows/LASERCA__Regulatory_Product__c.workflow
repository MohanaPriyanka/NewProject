<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>OFAC_Hit_Alert</fullName>
        <ccEmails>partnersupport@perchenergy.com</ccEmails>
        <description>OFAC Hit Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>api@bluewavesolar.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>BFG_Internal_Alerts/OFAC_Hit_Warning</template>
    </alerts>
</Workflow>