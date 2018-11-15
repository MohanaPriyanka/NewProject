<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Loan_Record_Type_DOER</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Loan_DOER</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Loan - Record Type - DOER</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Loan_Update_Next_Due_Date</fullName>
        <field>Next_Due_Date__c</field>
        <formula>IF(NOT(ISBLANK(last_due_date__c)),
DATE (  

/*YEAR*/  YEAR(last_due_date__c) + FLOOR((MONTH(last_due_date__c) +  1  - 1)/12),  

/*MONTH*/  CASE(MOD(MONTH(last_due_date__c) + 1, 12 ), 0, 12, MOD(MONTH(last_due_date__c)+ 1, 12 )),  

/*DAY*/  MIN(DAY(last_due_date__c),  CASE(MOD(MONTH(last_due_date__c) + 1,12), 9, 30, 4, 30, 6, 30, 11, 30, 2,  

/* return max days for February dependent on if end date is leap year */  

IF(MOD(YEAR(last_due_date__c) + FLOOR((MONTH(last_due_date__c) + 1)/12), 400) = 0 || (MOD(YEAR(last_due_date__c) + FLOOR((MONTH(last_due_date__c) + 1)/12), 4) = 0 &amp;&amp; MOD(YEAR(last_due_date__c) + FLOOR((MONTH(last_due_date__c) + 1)/12), 100) &lt;&gt; 0  ), 29,28), 31))  ),

DATE (  

/*YEAR*/  YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) +  1  - 1)/12),  

/*MONTH*/  CASE(MOD(MONTH(Commencement_Date__c) + 1, 12 ), 0, 12, MOD(MONTH(Commencement_Date__c)+ 1, 12 )),  

/*DAY*/  MIN(DAY(Commencement_Date__c),  CASE(MOD(MONTH(Commencement_Date__c) + 1,12), 9, 30, 4, 30, 6, 30, 11, 30, 2,  

/* return max days for February dependent on if end date is leap year */  

IF(MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 400) = 0 || (MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 4) = 0 &amp;&amp; MOD(YEAR(Commencement_Date__c) + FLOOR((MONTH(Commencement_Date__c) + 1)/12), 100) &lt;&gt; 0  ), 29,28), 31))  ))</formula>
        <name>Loan - Update Next Due Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_TPF</fullName>
        <field>XXXTechnology_Platform_Fee__c</field>
        <formula>Product__r.Technology_Platform_Fee__c *System_Costt__c</formula>
        <name>Update TPF</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Loan - Record Type - DOER</fullName>
        <actions>
            <name>Loan_Record_Type_DOER</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Loan__c.DOER_Solar_Loann__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Loan - Update Next Due Date</fullName>
        <actions>
            <name>Loan_Update_Next_Due_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Loan__c.Principal__c</field>
            <operation>greaterThan</operation>
            <value>0</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>recalculate TPF</fullName>
        <actions>
            <name>Update_TPF</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISBLANK(PRIORVALUE(System_Costt__c ))) &amp;&amp;ISCHANGED(System_Costt__c) &amp;&amp;NOT(ISBLANK(PRIORVALUE(Product__c))) &amp;&amp;ISCHANGED(Product__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
