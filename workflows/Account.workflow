<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Country</fullName>
        <description>Update to US</description>
        <field>ShippingCountry</field>
        <formula>BillingCountry</formula>
        <name>Update Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Update Country</fullName>
        <actions>
            <name>Update_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.Name</field>
            <operation>startsWith</operation>
            <value>Raj</value>
        </criteriaItems>
        <description>Test</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>