<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>MM_spend_out_of_flight_dates</fullName>
        <ccEmails>clientservices@strikesocial.com,salesforce@strikesocial.com</ccEmails>
        <description>MM spend out of flight dates -ae</description>
        <protected>false</protected>
        <senderAddress>salesforce@strikesocial.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Contract_Templates/MM_spend_out_of_flight_dates</template>
    </alerts>
    <fieldUpdates>
        <fullName>Uncheck_BypassValidationRule</fullName>
        <field>BypassValidationRule__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck BypassValidationRule</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>MM spend out of flight dates</fullName>
        <actions>
            <name>MM_spend_out_of_flight_dates</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>(Date__c &lt; Contract__r.Start_Date__c || Date__c &gt; Contract__r.End_Date__c) &amp;&amp;  (Delivered__c &gt; 0 || Media_Spend__c &gt; 0)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Uncheck BypassValidationRule</fullName>
        <actions>
            <name>Uncheck_BypassValidationRule</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>MM_Spendings__c.BypassValidationRule__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
