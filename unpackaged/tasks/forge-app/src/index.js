// Salesforce-JIRA Bridge - Small Office Simplified
// Single file implementation for minimal complexity

import api, { route } from '@forge/api';
import { storage } from '@forge/api';

const configStore = storage.encrypted('salesforce-config');

// Handle requests from Salesforce External Service
export const handleSalesforceRequest = async (req) => {
  console.log('Salesforce request received');
  
  try {
    const { action, data } = JSON.parse(req.body);
    
    if (action === 'CREATE_ISSUE') {
      return await createJiraIssue(data);
    }
    
    throw new Error(`Unknown action: ${action}`);
    
  } catch (error) {
    console.error('Request failed:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};

// Create Jira issue (replace current Named Credentials approach)
const createJiraIssue = async (data) => {
  const { summary, description, issueType, recordId } = data;
  
  const config = await configStore.get('default');
  if (!config) throw new Error('Configuration not found');
  
  try {
    // Use Forge's built-in Jira API access
    const response = await api.asApp().requestJira('/rest/api/3/issue', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        fields: {
          project: { key: config.jiraProjectKey || 'SH' },
          summary: summary,
          description: {
            type: 'doc',
            version: 1,
            content: [{
              type: 'paragraph',
              content: [{
                type: 'text',
                text: description + (recordId ? `\n\nSalesforce: ${recordId}` : '')
              }]
            }]
          },
          issuetype: { name: issueType || 'Task' }
        }
      })
    });
    
    if (response.ok) {
      const issue = await response.json();
      
      // Update Salesforce record with issue key
      await updateSalesforceRecord(recordId, issue.key);
      
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: true,
          issueKey: issue.key,
          issueUrl: `${config.jiraInstanceUrl || 'https://shulman-hill.atlassian.net'}/browse/${issue.key}`
        })
      };
    }
    
    throw new Error(`Jira API error: ${response.status}`);
    
  } catch (error) {
    console.error('Failed to create issue:', error);
    throw error;
  }
};

// Handle Jira issue updates (replace webhook)
export const handleJiraUpdate = async (event, context) => {
  console.log('Jira issue updated:', event.issue.key);
  
  const MAX_RETRIES = 3;
  let retryCount = 0;
  
  while (retryCount < MAX_RETRIES) {
    try {
      const issue = event.issue;
      
      // Simple field extraction
      const updateData = {
        Status__c: issue.fields.status?.name,
        Assignee__c: issue.fields.assignee?.displayName,
        Last_Sync_Date__c: new Date().toISOString(),
        Sync_Status__c: 'Synchronized'
      };
      
      // Update Salesforce using stored credentials
      await updateSalesforceByIssueKey(issue.key, updateData);
      
      console.log(`Updated Salesforce for ${issue.key}`);
      return; // Success - exit retry loop
      
    } catch (error) {
      retryCount++;
      console.error(`Sync failed (attempt ${retryCount}/${MAX_RETRIES}):`, error);
      
      if (retryCount >= MAX_RETRIES) {
        // Final failure - update sync status to failed
        try {
          await updateSalesforceByIssueKey(event.issue.key, {
            Sync_Status__c: 'Failed',
            Last_Sync_Error__c: error.message,
            Last_Sync_Date__c: new Date().toISOString()
          });
        } catch (statusUpdateError) {
          console.error('Failed to update sync status:', statusUpdateError);
        }
        throw error;
      }
      
      // Wait before retry (exponential backoff)
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, retryCount) * 1000));
    }
  }
};

// Update Salesforce record
const updateSalesforceRecord = async (recordId, issueKey) => {
  if (!recordId) return;
  
  const config = await configStore.get('default');
  if (!config) throw new Error('Salesforce not configured');
  
  const token = await getSalesforceToken(config);
  
  await api.fetch(`${config.instanceUrl}/services/data/v64.0/sobjects/Jira_Sync__c`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      External_Issue_Key__c: issueKey,
      Salesforce_Record_Id__c: recordId,
      Status__c: 'Open',
      Sync_Status__c: 'Synchronized',
      Issue_URL__c: `${config.jiraInstanceUrl || 'https://shulman-hill.atlassian.net'}/browse/${issueKey}`
    })
  });
};

const updateSalesforceByIssueKey = async (issueKey, updateData) => {
  const config = await configStore.get('default');
  if (!config) return;
  
  const token = await getSalesforceToken(config);
  
  // Use External ID for efficient update
  await api.fetch(`${config.instanceUrl}/services/data/v64.0/sobjects/Jira_Sync__c/External_Issue_Key__c/${issueKey}`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(updateData)
  });
};

// Enhanced OAuth token management with validation and buffer
const getSalesforceToken = async (config) => {
  // Validate required config
  if (!config.instanceUrl || !config.clientId || !config.clientSecret) {
    throw new Error('Missing required Salesforce configuration');
  }
  
  let token = await configStore.get('access_token');
  
  // Check if token needs refresh (5 minute buffer before expiration)
  const EXPIRY_BUFFER = 5 * 60 * 1000; // 5 minutes in milliseconds
  if (!token || Date.now() >= (token.expires_at - EXPIRY_BUFFER)) {
    console.log('Refreshing Salesforce token');
    
    const response = await api.fetch(`${config.instanceUrl}/services/oauth2/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: config.clientId,
        client_secret: config.clientSecret
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`OAuth token request failed: ${response.status} - ${errorText}`);
    }
    
    const tokenData = await response.json();
    
    // Validate token response
    if (!tokenData.access_token || !tokenData.expires_in) {
      throw new Error('Invalid token response from Salesforce');
    }
    
    token = {
      access_token: tokenData.access_token,
      expires_at: Date.now() + (tokenData.expires_in * 1000)
    };
    
    await configStore.set('access_token', token);
    console.log('Salesforce token refreshed successfully');
  }
  
  return token.access_token;
};

// Configuration endpoints for Salesforce admin
export const configEndpoints = route()
  .get('/config', async (req) => {
    const config = await configStore.get('default') || {};
    return { 
      instanceUrl: config.instanceUrl || '',
      clientId: config.clientId || '',
      jiraProjectKey: config.jiraProjectKey || 'SH',
      jiraInstanceUrl: config.jiraInstanceUrl || 'https://shulman-hill.atlassian.net',
      configured: !!(config.clientId && config.clientSecret && config.instanceUrl)
    };
  })
  .post('/config', async (req) => {
    const { instanceUrl, clientId, clientSecret, jiraProjectKey, jiraInstanceUrl } = req.body;
    
    // Validate required fields
    if (!instanceUrl || !clientId || !clientSecret) {
      return {
        success: false,
        error: 'instanceUrl, clientId, and clientSecret are required'
      };
    }
    
    await configStore.set('default', {
      instanceUrl: instanceUrl.replace(/\/$/, ''), // Remove trailing slash
      clientId,
      clientSecret,
      jiraProjectKey: jiraProjectKey || 'SH',
      jiraInstanceUrl: (jiraInstanceUrl || 'https://shulman-hill.atlassian.net').replace(/\/$/, '')
    });
    
    return { success: true };
  });

export const configEndpoints = configEndpoints;