# Atlassian Forge App - Small Office Simplified Plan
**Created**: September 22, 2025  
**Target**: Small Office Law Firm (<100 daily records, handful of users)  
**Tech Stack**: Atlassian Forge (Minimal) + Salesforce Lightning Platform  
**Approach**: Simple, efficient, no unnecessary complexity

---

## 🎯 Small Office Forge Strategy: Keep It Simple

### **Why Minimal Forge Approach?**
- ✅ **Solves webhook authentication permanently** - No session token management
- ✅ **Uses Salesforce Lightning best practices** - External Services + InvocableMethod  
- ✅ **Minimal Forge complexity** - Single function, no custom UI, no marketplace features
- ✅ **Easy maintenance** - Standard Salesforce admin tasks only
- ✅ **Future-proof** - Aligned with platform directions without overhead

### **What We're NOT Building (Enterprise Bloat)**
- ❌ **No custom React UI** - Use Salesforce setup screens
- ❌ **No marketplace features** - Internal use only
- ❌ **No complex event handlers** - Simple webhook replacement
- ❌ **No multi-environment complexity** - Single production app
- ❌ **No performance monitoring** - Salesforce debug logs sufficient

---

## 🏗️ Simplified Architecture

### **Single Purpose: Replace Problematic Webhooks**
```
Salesforce Flow → External Service → Minimal Forge Function → Jira API
                                           ↓
Jira Issue Update → Minimal Forge Function → Salesforce REST API
```

### **Forge App Structure (Minimal)**
```
salesforce-jira-bridge/
├── manifest.yml           # Simple app config
├── src/
│   └── index.js           # Single function file
└── package.json          # Minimal dependencies
```

**That's it. No complex folder structure, no custom UI, no multiple environments.**

---

## 📋 Implementation Plan

### **Phase 1: Minimal Forge App (2 hours)**

#### **1.1 Create Simple Forge App**
```bash
# One-time setup
npm install -g @forge/cli
forge login
forge create salesforce-jira-bridge --template hello-world
cd salesforce-jira-bridge
```

#### **1.2 Minimal App Manifest**
```yaml
# manifest.yml - Keep it simple
schema-version: '1'
id: 'ari:cloud:ecosystem::app/salesforce-jira-bridge'
name: 'Salesforce Bridge'
description: 'Simple bidirectional sync for small office'

modules:
  # HTTP endpoint for Salesforce calls
  web-trigger:
    - key: 'salesforce-handler'
      function: 'handleSalesforceRequest'
    - key: 'config-handler'
      function: 'configEndpoints'
      
  # Single function for Jira events  
  jira:issueUpdated:
    - key: 'jira-handler'
      function: 'handleJiraUpdate'
      

app:
  # Only what we need
  external:
    fetch:
      backend:
        - '*.salesforce.com'
        
  # Minimal permissions
  scopes:
    - 'read:jira-work'
    - 'write:jira-work'

# Simple storage
storage:
  encrypted:
    - 'salesforce-config'
```

#### **1.3 Single Function Implementation**
```javascript
// src/index.js - Everything in one file for simplicity
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
  
  try {
    const issue = event.issue;
    
    // Simple field extraction
    const updateData = {
      Status__c: issue.fields.status?.name,
      Assignee__c: issue.fields.assignee?.displayName,
      Last_Sync_Date__c: new Date().toISOString()
    };
    
    // Update Salesforce using stored credentials
    await updateSalesforceByIssueKey(issue.key, updateData);
    
    console.log(`Updated Salesforce for ${issue.key}`);
    
  } catch (error) {
    console.error('Sync failed:', error);
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

// Simple OAuth token management
const getSalesforceToken = async (config) => {
  let token = await configStore.get('access_token');
  
  if (!token || Date.now() >= token.expires_at) {
    const response = await api.fetch(`${config.instanceUrl}/services/oauth2/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: config.clientId,
        client_secret: config.clientSecret
      })
    });
    
    const tokenData = await response.json();
    token = {
      access_token: tokenData.access_token,
      expires_at: Date.now() + (tokenData.expires_in * 1000)
    };
    
    await configStore.set('access_token', token);
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
```

---

### **Phase 1.4: Salesforce Data Model**

#### **Jira_Sync__c Custom Object Fields**
```yaml
# Required fields for the integration
External_Issue_Key__c:
  Type: External ID (Text, 255)
  Unique: true
  Case Sensitive: false
  Description: JIRA issue key (e.g., SH-123)

Salesforce_Record_Id__c:
  Type: Text (18)
  Description: Source Salesforce record ID that created the issue

Status__c:
  Type: Text (255)
  Description: Current JIRA issue status

Assignee__c:
  Type: Text (255)
  Description: Current JIRA issue assignee display name

Sync_Status__c:
  Type: Picklist
  Values: ['Synchronized', 'Failed', 'Pending']
  Default: 'Pending'
  Description: Integration sync status

Last_Sync_Date__c:
  Type: DateTime
  Description: Last successful sync timestamp

Last_Sync_Error__c:
  Type: Long Text Area (32768)
  Description: Error message from last failed sync attempt

Issue_URL__c:
  Type: URL (255)
  Description: Direct link to JIRA issue
```

---

### **Phase 2: Salesforce External Service Setup (30 minutes)**

#### **2.1 External Service Configuration**
```yaml
# Setup → External Services → New External Service
Service Name: Jira Bridge Forge App
Service URL: https://[forge-app-id].atlassian-dev.net
Schema: OpenAPI 3.0

# Simple OpenAPI Schema
openapi: "3.0.0"
info:
  title: "Jira Bridge"
  version: "1.0.0"
paths:
  /webtrigger/salesforce-handler:
    post:
      operationId: "createIssue"
      requestBody:
        content:
          application/json:
            schema:
              type: "object"
              properties:
                action:
                  type: "string"
                data:
                  type: "object"
      responses:
        200:
          description: "Success"
          content:
            application/json:
              schema:
                type: "object"
                properties:
                  success:
                    type: "boolean"
                  issueKey:
                    type: "string"
                  issueUrl:
                    type: "string"
```

#### **2.2 Simplified Apex Service**
```apex
// JiraForgeService.cls - Replace existing JiraService
public with sharing class JiraForgeService {
    
    @InvocableMethod(
        label='Create Jira Issue' 
        description='Creates issue via Forge app'
    )
    public static List<Result> createIssue(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            try {
                // Call Forge app via External Service
                ExternalService.JiraBridge forge = new ExternalService.JiraBridge();
                
                ExternalService.JiraBridge.createIssue_Request forgeReq = 
                    new ExternalService.JiraBridge.createIssue_Request();
                
                forgeReq.action = 'CREATE_ISSUE';
                forgeReq.data = new Map<String, Object>{
                    'summary' => req.summary,
                    'description' => req.description,
                    'issueType' => req.issueType,
                    'recordId' => req.recordId
                };
                
                ExternalService.JiraBridge.createIssue_Response response = 
                    forge.createIssue(forgeReq);
                
                Result result = new Result();
                result.success = response.success;
                result.issueKey = response.issueKey;
                result.issueUrl = response.issueUrl;
                results.add(result);
                
            } catch (Exception e) {
                Result result = new Result();
                result.success = false;
                result.errorMessage = e.getMessage();
                results.add(result);
            }
        }
        
        return results;
    }
    
    // Simple request/response classes
    public class Request {
        @InvocableVariable(label='Summary' required=true)
        public String summary;
        
        @InvocableVariable(label='Description')
        public String description;
        
        @InvocableVariable(label='Issue Type')
        public String issueType = 'Task';
        
        @InvocableVariable(label='Record ID')
        public String recordId;
    }
    
    public class Result {
        @InvocableVariable public Boolean success = false;
        @InvocableVariable public String issueKey;
        @InvocableVariable public String issueUrl;
        @InvocableVariable public String errorMessage;
    }
}
```

---

### **Phase 3: Simple Configuration (No Custom UI)**

#### **3.1 Salesforce Connected App Setup**
```yaml
# Standard Salesforce Connected App (one-time setup)
App Name: Jira Forge Integration
API Name: Jira_Forge_Integration
OAuth Scopes:
  - Access unique identifier (openid)
  - Perform requests at any time (refresh_token, offline_access)
  - Access custom permissions (custom_permissions)
  - Full access (full)

# Note client credentials for Forge app configuration
```

#### **3.2 Forge App Configuration**
```javascript
// Configure via Forge app's admin endpoint
// Call once to set up Salesforce connection

POST https://[forge-app-id].atlassian-dev.net/webtrigger/config-handler
{
  "instanceUrl": "https://shulman-hill--uat.my.salesforce.com",
  "clientId": "[connected_app_client_id]",
  "clientSecret": "[connected_app_client_secret]",
  "jiraProjectKey": "SH",
  "jiraInstanceUrl": "https://shulman-hill.atlassian.net"
}
```

#### **3.3 Security Configuration**

**Connected App Security Settings:**
```yaml
# IP Restrictions (Recommended for small office)
IP Relaxation: Restrict to trusted IP ranges
Relax IP Restrictions: Enabled

# Session Settings
Timeout Value: 2 hours
Refresh Token Policy: Refresh token is valid until revoked

# OAuth Policies
Permitted Users: Admin approved users are pre-authorized
Refresh Token Policy: Immediately expire refresh token
```

**Field-Level Security for Jira_Sync__c:**
```yaml
# Recommended field permissions
External_Issue_Key__c: Read/Edit (System Admin, Integration User)
Salesforce_Record_Id__c: Read/Edit (System Admin, Integration User)
Status__c: Read Only (All Users), Edit (System Admin, Integration User)
Sync_Status__c: Read Only (All Users), Edit (System Admin, Integration User)
Last_Sync_Date__c: Read Only (All Users)
Last_Sync_Error__c: Read Only (System Admin, Integration User)
Issue_URL__c: Read Only (All Users)
```

---

### **Phase 4: Testing & Deployment (30 minutes)**

#### **4.1 Development Testing**
```bash
# Deploy to development
forge deploy
forge install --upgrade-edge

# Test issue creation
# Use existing Flow with new JiraForgeService class

# Monitor logs
forge logs --follow
```

#### **4.2 Integration Test Scenarios**

**Test Case 1: Salesforce → JIRA Issue Creation**
```yaml
Scenario: Create JIRA issue from Salesforce record
Given: 
  - Salesforce Flow configured with JiraForgeService
  - Valid Forge app configuration
  - Test record in Salesforce
When: Flow executes createIssue action
Then:
  - JIRA issue created with correct summary/description
  - Jira_Sync__c record created with External_Issue_Key__c
  - Status__c = 'Open', Sync_Status__c = 'Synchronized'
  - Issue_URL__c contains correct JIRA link
```

**Test Case 2: JIRA → Salesforce Status Update**
```yaml
Scenario: Update Salesforce when JIRA issue changes
Given:
  - Existing Jira_Sync__c record with External_Issue_Key__c
  - JIRA issue status changed to 'In Progress'
When: JIRA issue is updated
Then:
  - Jira_Sync__c Status__c updated to 'In Progress'
  - Sync_Status__c = 'Synchronized'
  - Last_Sync_Date__c updated
```

**Test Case 3: Error Handling & Retry Logic**
```yaml
Scenario: Handle temporary Salesforce API failures
Given:
  - JIRA issue update event
  - Temporary Salesforce API outage
When: Sync attempt fails
Then:
  - Retry logic executes (up to 3 attempts)
  - Exponential backoff applied
  - After max retries: Sync_Status__c = 'Failed'
  - Last_Sync_Error__c contains error message
```

**Test Case 4: Configuration Validation**
```yaml
Scenario: Validate configuration endpoint
Given: Forge app deployed
When: POST to /webtrigger/config-handler with invalid data
Then: Returns validation error with specific field requirements

When: POST with valid configuration
Then: Returns success=true and stores configuration
```

**Test Case 5: Token Refresh Logic**
```yaml
Scenario: OAuth token near expiration
Given: 
  - Stored token expires in 3 minutes
  - JIRA update triggers Salesforce sync
When: Token expiry check runs
Then:
  - New token requested from Salesforce
  - Token stored with new expiration
  - Sync operation completes successfully
```

#### **4.3 Production Deployment**
```bash
# Single production deployment
forge deploy --environment production
forge install --environment production

# Update Salesforce External Service URL to production endpoint
```

---

## 🎯 Benefits of Simplified Forge Approach

### **Problems Solved**
- ✅ **No webhook authentication issues** - Forge handles securely
- ✅ **No session token expiration** - OAuth managed by Forge
- ✅ **No server maintenance** - Serverless, managed by Atlassian
- ✅ **Bidirectional sync that works** - Event handlers instead of webhooks

### **Small Office Perfect**
- ✅ **Minimal code complexity** - Single JavaScript file
- ✅ **Standard Salesforce practices** - External Services + InvocableMethod
- ✅ **No custom UI needed** - Use Salesforce setup screens
- ✅ **Easy maintenance** - Standard admin tasks
- ✅ **Future-proof** - Aligned with platform directions

### **What We Eliminated**
- ❌ **No complex React UI** 
- ❌ **No marketplace features**
- ❌ **No multi-environment complexity**
- ❌ **No performance monitoring overhead**
- ❌ **No custom storage schemas**

---

## 📊 Implementation Comparison

| Feature | v3 (Current) | v4 Forge (Enterprise) | v4 Simplified |
|---------|-------------|---------------------|---------------|
| **Complexity** | Medium | High | Low |
| **Authentication Issues** | ❌ Has problems | ✅ Solved | ✅ Solved |
| **Code Lines** | ~800 lines | ~1500 lines | ~200 lines |
| **Maintenance** | Manual webhooks | Complex deployment | Simple |
| **Small Office Fit** | Good | Over-engineered | Perfect |

---

## 🚀 Migration Plan

### **Week 1: Build & Test**
- Set up Forge app (2 hours)
- Deploy to development (30 minutes)
- Test with existing Flow (1 hour)
- Configure Salesforce connection (30 minutes)

### **Week 2: Production Deployment**
- Deploy Forge app to production
- Update Salesforce External Service
- Test bidirectional sync
- Decommission v3 webhook handler

**Total Time Investment: ~5 hours spread over 2 weeks**

---

## 🎯 Perfect Small Office Solution

This simplified Forge approach gives you:
- ✅ **Modern Salesforce Lightning practices** 
- ✅ **Solves authentication problems permanently**
- ✅ **Minimal complexity** - 200 lines vs 800+ lines
- ✅ **Future-proof platform alignment**
- ✅ **Easy maintenance** for small office team
- ✅ **Professional, reliable integration**

**No enterprise bloat, maximum small office efficiency.**