<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Contract_Approvals_Final_Approval</fullName>
        <description>Email template which is sent at the end of the Contracts Approval Process to notify for approval.</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Submitted_By__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Contract_Approvals_Final_Approval</template>
    </alerts>
    <alerts>
        <fullName>Contract_Approvals_Final_Rejection</fullName>
        <description>Email template which is sent at the end of the Contracts Approval Process to notify for rejection.</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>Submitted_By__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/Contract_Approvals_Final_Rejection</template>
    </alerts>
</Workflow>