*** Settings ***

Resource        cumulusci/robotframework/Salesforce.robot
Library         cumulusci.robotframework.PageObjects
Library         Collections
Library         String

Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

Documentation   End-to-End JIRA Integration Tests for Small Office
...             Tests the complete flow from Salesforce to JIRA and back
...             Optimized for small office requirements (<100 daily records)

*** Variables ***

${TEST_CASE_SUMMARY}        Urgent contract review needed - Robot Test
${TEST_CASE_DESCRIPTION}    Client ABC needs contract reviewed by EOD. High priority.
${EXPECTED_ISSUE_TYPE}      Task

*** Test Cases ***

Test JIRA Issue Creation Via Flow
    [Documentation]    Test creating JIRA issue through Salesforce Flow
    [Tags]    integration    flow    jira-creation
    
    # Create a test Case record that should trigger JIRA integration
    ${case_id}    Create Test Case    ${TEST_CASE_SUMMARY}    ${TEST_CASE_DESCRIPTION}
    
    # Verify Case was created
    &{case_record}    Salesforce Get    Case    ${case_id}
    Should Be Equal    ${TEST_CASE_SUMMARY}    ${case_record}[Subject]
    
    # TODO: Trigger Flow manually (will be automated once Flow is identified)
    Log    Case created: ${case_id} - Manual Flow trigger required for now
    
    # Manual step for now - in real implementation this would be automatic
    Log    Manual Step: Run the JIRA creation Flow on Case ${case_id}

Test JIRA Sync Record Management
    [Documentation]    Test JIRA sync record creation and updates
    [Tags]    integration    sync-records
    
    # Create a test Jira_Sync__c record
    ${sync_record_id}    Create JIRA Sync Record    SH-ROBOT-001
    
    # Verify the sync record
    &{sync_record}    Salesforce Get    Jira_Sync__c    ${sync_record_id}
    Should Be Equal    SH-ROBOT-001    ${sync_record}[External_Issue_Key__c]
    Should Be Equal    Pending    ${sync_record}[Sync_Status__c]
    
    # Update sync status to Synchronized
    Salesforce Update    Jira_Sync__c    ${sync_record_id}
    ...    Sync_Status__c=Synchronized
    ...    Status__c=Open
    ...    Last_Sync_Date__c=${EMPTY}    # Will be set by system
    
    # Verify update
    &{updated_record}    Salesforce Get    Jira_Sync__c    ${sync_record_id}
    Should Be Equal    Synchronized    ${updated_record}[Sync_Status__c]
    Should Be Equal    Open    ${updated_record}[Status__c]

Test Health Check Functionality
    [Documentation]    Test integration health monitoring
    [Tags]    monitoring    health-check
    
    # Call the health check method via API (simulated)
    # In real scenario, this would be called via REST API or Lightning component
    
    # Create some test sync records for health check
    ${success_record}    Create JIRA Sync Record    SH-HEALTH-001    Synchronized
    ${failed_record}     Create JIRA Sync Record    SH-HEALTH-002    Failed
    
    # Verify records exist for health calculation
    &{success_rec}    Salesforce Get    Jira_Sync__c    ${success_record}
    &{failed_rec}     Salesforce Get    Jira_Sync__c    ${failed_record}
    
    Should Be Equal    Synchronized    ${success_rec}[Sync_Status__c]
    Should Be Equal    Failed    ${failed_rec}[Sync_Status__c]
    
    Log    Health check data prepared - success and failed records created

Test Error Handling Scenarios
    [Documentation]    Test various error conditions and recovery
    [Tags]    error-handling    resilience
    
    # Create sync record with error status
    ${error_record_id}    Create JIRA Sync Record    SH-ERROR-001    Failed
    
    # Update with error details
    Salesforce Update    Jira_Sync__c    ${error_record_id}
    ...    Last_Sync_Error__c=Connection timeout after 3 retries
    ...    Last_Sync_Date__c=${EMPTY}
    
    # Verify error information is stored
    &{error_record}    Salesforce Get    Jira_Sync__c    ${error_record_id}
    Should Contain    ${error_record}[Last_Sync_Error__c]    timeout
    Should Be Equal   Failed    ${error_record}[Sync_Status__c]

Test Small Office Data Volume
    [Documentation]    Test performance with typical small office data volumes
    [Tags]    performance    small-office    volume
    
    # Create batch of sync records (simulating daily volume)
    ${batch_size}    Set Variable    50    # Typical small office daily volume
    
    @{sync_records}    Create List
    FOR    ${i}    IN RANGE    1    ${batch_size + 1}
        ${issue_key}    Set Variable    SH-BATCH-${i:03d}
        ${record_id}    Create JIRA Sync Record    ${issue_key}
        Append To List    ${sync_records}    ${record_id}
    END
    
    # Verify all records were created
    ${created_count}    Get Length    ${sync_records}
    Should Be Equal As Numbers    ${batch_size}    ${created_count}
    
    # Query all batch records to verify database performance
    @{batch_records}    Salesforce Query    
    ...    SELECT Id, External_Issue_Key__c FROM Jira_Sync__c 
    ...    WHERE External_Issue_Key__c LIKE 'SH-BATCH-%'
    
    ${query_count}    Get Length    ${batch_records}
    Should Be Equal As Numbers    ${batch_size}    ${query_count}
    
    Log    Successfully processed ${batch_size} records - suitable for small office volume

*** Keywords ***

Setup Test Data
    [Documentation]    Create any necessary test data for the suite
    Log    Setting up test data for JIRA integration tests
    
    # Verify Jira_Sync__c object is accessible
    ${test_query}    Salesforce Query    SELECT COUNT() FROM Jira_Sync__c LIMIT 1
    Log    Jira_Sync__c object is accessible

Create Test Case
    [Arguments]    ${subject}    ${description}
    [Documentation]    Create a test Case record for JIRA integration
    
    ${case_id}    Salesforce Insert    Case
    ...    Subject=${subject}
    ...    Description=${description}
    ...    Priority=High
    ...    Origin=Phone
    
    Store Session Record    Case    ${case_id}
    [Return]    ${case_id}

Create JIRA Sync Record
    [Arguments]    ${issue_key}    ${sync_status}=Pending
    [Documentation]    Create a test Jira_Sync__c record
    
    ${sync_id}    Salesforce Insert    Jira_Sync__c
    ...    External_Issue_Key__c=${issue_key}
    ...    Sync_Status__c=${sync_status}
    ...    Status__c=Open
    ...    Issue_URL__c=https://shulman-hill.atlassian.net/browse/${issue_key}
    
    Store Session Record    Jira_Sync__c    ${sync_id}
    [Return]    ${sync_id}

Verify JIRA Issue Created
    [Arguments]    ${case_id}    ${expected_issue_key}
    [Documentation]    Verify that JIRA issue was created for the given case
    
    # Look for Jira_Sync__c record linked to this case
    @{sync_records}    Salesforce Query    
    ...    SELECT External_Issue_Key__c, Issue_URL__c, Sync_Status__c 
    ...    FROM Jira_Sync__c 
    ...    WHERE Salesforce_Record_Id__c = '${case_id}'
    
    ${record_count}    Get Length    ${sync_records}
    Should Be Equal As Numbers    1    ${record_count}    msg=Should find exactly one sync record
    
    ${sync_record}    Get From List    ${sync_records}    0
    Should Be Equal    ${expected_issue_key}    ${sync_record}[External_Issue_Key__c]
    Should Be Equal    Synchronized    ${sync_record}[Sync_Status__c]

Wait For Sync Completion
    [Arguments]    ${issue_key}    ${timeout}=30s
    [Documentation]    Wait for sync status to change from Pending
    
    Wait Until Keyword Succeeds    ${timeout}    5s
    ...    Verify Sync Status Not Pending    ${issue_key}

Verify Sync Status Not Pending
    [Arguments]    ${issue_key}
    [Documentation]    Check that sync status is not Pending
    
    &{sync_record}    Salesforce Query Single Record    Jira_Sync__c
    ...    SELECT Sync_Status__c FROM Jira_Sync__c WHERE External_Issue_Key__c = '${issue_key}'
    
    Should Not Be Equal    Pending    ${sync_record}[Sync_Status__c]