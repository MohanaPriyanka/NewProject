<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Approval_Alert_SSSO</fullName>
        <description>Approval Alert: SSSO</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Final_Approval_SSSO</template>
    </alerts>
    <alerts>
        <fullName>Rejection_Alert_SSSO</fullName>
        <description>Rejection Alert: SSSO</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Final_Rejection_SSSO</template>
    </alerts>
</Workflow>
