<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Case_Close_Email_Alert_to_Customer</fullName>
        <description>Case Close Email Alert to Customer</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Customer_Care_Cases/Customer_Care_Case_CloseII</template>
    </alerts>
    <alerts>
        <fullName>Case_Close_Email_Alert_to_Customer_Phone</fullName>
        <description>Case Close Email Alert to Customer (Phone)</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Customer_Care_Cases/Customer_Care_Case_CloseII</template>
    </alerts>
    <alerts>
        <fullName>Case_Open_Email_Alert</fullName>
        <description>Case Open Email Alert</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderAddress>customercare@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Customer_Care_Cases/Customer_Care_Case_Open_Phone</template>
    </alerts>
    <alerts>
        <fullName>New_Product_Support_Case</fullName>
        <description>New Product Support Case</description>
        <protected>false</protected>
        <recipients>
            <field>ContactEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>productsupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Product_Team/New_Product_Support_Case</template>
    </alerts>
    <alerts>
        <fullName>Partner_Case_Close_Email</fullName>
        <description>Partner Case Close Email</description>
        <protected>false</protected>
        <recipients>
            <field>SuppliedEmail</field>
            <type>email</type>
        </recipients>
        <senderAddress>partnersupport@bluewavesolar.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Customer_Care_Cases/Partner_Care_Case_CloseII</template>
    </alerts>
    <rules>
        <fullName>Case Close %3A Response to Customer Email</fullName>
        <actions>
            <name>Case_Close_Email_Alert_to_Customer</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <formula>AND( ISCHANGED(IsClosed),        IsClosed = TRUE,        OR( ISPICKVAL(Origin,  &quot;Email&quot;),           ISPICKVAL(Origin,  &quot;Web&quot;)),      CreatedDate &gt; DATETIMEVALUE(DATE(2017,05,09)),      RecordType.Id !=&quot;012j00000000HA8AAM&quot;,       Disable_Followup_Email__c = true,      SuppliedEmail != &apos;mailer-daemon@salesforce.com&apos;  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Close %3A Response to Customer Phone</fullName>
        <actions>
            <name>Case_Close_Email_Alert_to_Customer_Phone</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <formula>AND( ISCHANGED(IsClosed), IsClosed = TRUE,  ISPICKVAL(Origin,  &quot;Phone&quot;), NOT(ISNULL(ContactId)),  CreatedDate &gt; DATETIMEVALUE(DATE(2017,05,09)) , RecordType.Id!=&quot;0120a0000004XZw&quot;, Disable_Followup_Email__c!=true)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Close %3A Response to Partner</fullName>
        <actions>
            <name>Partner_Case_Close_Email</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <formula>AND( ISCHANGED(IsClosed), 
     IsClosed = TRUE,  
     ISPICKVAL(Origin,  &quot;Email&quot;),   
     RecordType.Id=&quot;0120a0000004XZw&quot;, 
     Disable_Followup_Email__c!=true,
     SuppliedEmail != &apos;mailer-daemon@salesforce.com&apos; 
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Case Open %3A Response to Customer Phone</fullName>
        <actions>
            <name>Case_Open_Email_Alert</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <formula>AND( ISCHANGED(ContactId), IsClosed = FALSE,  ISPICKVAL(Origin,  &quot;Phone&quot;), NOT(ISNULL(ContactId)),  CreatedDate &gt; DATETIMEVALUE(DATE(2017,05,09)))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
