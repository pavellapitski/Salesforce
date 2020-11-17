<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Negative_Profit_MD</fullName>
        <ccEmails>salesforce@strikesocial.com</ccEmails>
        <description>Negative Profit MD</description>
        <protected>false</protected>
        <senderAddress>salesforce@strikesocial.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Contract_Templates/MD_Profit_negative</template>
    </alerts>
    <rules>
        <fullName>Negative Profit on MD</fullName>
        <actions>
            <name>Negative_Profit_MD</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Monthly_Distribution__c.Actual_Gross_Profit__c</field>
            <operation>lessThan</operation>
            <value>USD 0</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
