<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Account_Reassigned</fullName>
        <description>Account Reassigned</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <recipient>cwallin@strikesocial.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>dholly@strikesocial.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>pskotnicki@strikesocial.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <field>Previous_Account_Owner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Account_Templates/Account_Reassigned</template>
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
        <fullName>Uncheck BypassValidationRule</fullName>
        <actions>
            <name>Uncheck_BypassValidationRule</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.BypassValidationRule__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
