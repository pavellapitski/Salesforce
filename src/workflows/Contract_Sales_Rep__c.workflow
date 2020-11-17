<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_commission_from_formula</fullName>
        <field>Commission__c</field>
        <formula>Expected_commission__c</formula>
        <name>Copy commission from formula</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Copy commission from formula when user edited</fullName>
        <actions>
            <name>Copy_commission_from_formula</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ischanged( Commission_Profile__c ) &amp;&amp;  Contract__r.InvoicesPaid__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
