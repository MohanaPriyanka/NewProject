<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Interest_Only_End_Date</fullName>
        <field>Interest_only_End_Date__c</field>
        <formula>DATE (  

/*YEAR*/  YEAR(Date_of_disbursement__c) + FLOOR((MONTH(Date_of_disbursement__c) +  Interest_only_period__c  - 1)/12),  

/*MONTH*/  CASE(MOD(MONTH(Date_of_disbursement__c) + Interest_only_period__c, 12 ), 0, 12, MOD(MONTH(Date_of_disbursement__c)+ Interest_only_period__c, 12 )),  

/*DAY*/  MIN(DAY(Date_of_disbursement__c),  CASE(MOD(MONTH(Date_of_disbursement__c) + Interest_only_period__c,12), 9, 30, 4, 30, 6, 30, 11, 30, 2,  

/* return max days for February dependent on if end date is leap year */  

IF(MOD(YEAR(Date_of_disbursement__c) + FLOOR((MONTH(Date_of_disbursement__c) + Interest_only_period__c)/12), 400) = 0 || (MOD(YEAR(Date_of_disbursement__c) + FLOOR((MONTH(Date_of_disbursement__c) + Interest_only_period__c)/12), 4) = 0 &amp;&amp; MOD(YEAR(Date_of_disbursement__c) + FLOOR((MONTH(Date_of_disbursement__c) + Interest_only_period__c)/12), 100) &lt;&gt; 0  ), 29,28), 31))  )</formula>
        <name>Interest Only End Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Interest only End Date</fullName>
        <actions>
            <name>Interest_Only_End_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Loan_Traunch__c.Interest_only_period__c</field>
            <operation>greaterThan</operation>
            <value>0</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
