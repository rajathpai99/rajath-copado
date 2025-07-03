<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>priority_update</fullName>
        <description>description good</description>
        <field>Priority</field>
        <literalValue>High</literalValue>
        <name>priority update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_update</fullName>
        <description>test desc</description>
        <field>Status</field>
        <literalValue>Working</literalValue>
        <name>status update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>%28New Hire Onboarding%29 at case create%2C all roles except IDT</fullName>
        <actions>
            <name>status_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.OwnerId</field>
            <operation>startsWith</operation>
            <value>Raj</value>
        </criteriaItems>
        <description>test describe</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>%28New Hire Onboarding%29Business Cards checkbox</fullName>
        <actions>
            <name>priority_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Reason</field>
            <operation>equals</operation>
            <value>Installation,Equipment Complexity,Equipment Design</value>
        </criteriaItems>
        <description>description exceptional</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
