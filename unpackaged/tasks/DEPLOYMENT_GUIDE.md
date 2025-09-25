# 🚀 JIRA Integration v4 - Deployment Guide

**Small Office Optimized** | **Simple & Efficient** | **Production Ready**

---

## 📋 Prerequisites Checklist

### ✅ **Required Access & Permissions**
- [ ] Atlassian admin access to shulman-hill.atlassian.net
- [ ] Salesforce System Administrator privileges  
- [ ] Node.js 18+ installed on development machine
- [ ] Git access to this repository

### ✅ **Environment Readiness**
- [ ] JIRA project "SH" exists and is active
- [ ] Salesforce org is accessible and has sufficient storage
- [ ] Network connectivity between Salesforce and Atlassian Cloud

---

## 🗂️ Automated Components (Ready to Deploy)

### ✅ **Salesforce Components**
```
force-app/main/default/
├── classes/
│   ├── JiraForgeService.cls           # Main integration service
│   ├── JiraForgeService.cls-meta.xml
│   ├── JiraForgeServiceTest.cls       # Comprehensive tests
│   └── JiraForgeServiceTest.cls-meta.xml
└── objects/
    └── Jira_Sync__c/                  # Complete custom object
        ├── Jira_Sync__c.object-meta.xml
        ├── fields/                     # All required fields
        ├── compactLayouts/             # User-friendly layouts
        └── listViews/                  # Admin & troubleshooting views
```

### ✅ **Forge App Components**
```
unpackaged/tasks/forge-app/
├── manifest.yml                       # Forge app configuration
├── package.json                       # Dependencies & scripts
└── src/
    └── index.js                       # Complete integration logic
```

### ✅ **Integration Assets**
```
unpackaged/tasks/
├── external-service-schema.json       # Ready-to-import OpenAPI spec
├── jira_integration_e2e.robot        # End-to-end tests
└── MANUAL_CONFIG_CHECKLIST.md        # Your progress tracker
```

---

## 🏗️ Deployment Steps

### **Phase 1: Deploy Salesforce Components**

#### 1.1 Deploy via CumulusCI (Recommended)
```bash
# Navigate to project root
cd C:\Users\sean\Projects\Salesforce\Shulman\Shulman-Jira-Integration

# Deploy to your development org
cci flow run dev_org --org dev

# Run tests to verify deployment
cci task run run_tests --org dev
```

#### 1.2 Alternative: Deploy via Salesforce CLI
```bash
# If you prefer sfdx commands
sf project deploy start --source-dir force-app/main/default --target-org YOUR_ORG_ALIAS

# Run tests
sf apex run test --class-names JiraForgeServiceTest --target-org YOUR_ORG_ALIAS
```

### **Phase 2: Set Up Forge App**

#### 2.1 Copy Forge Files to Development Directory
```bash
# Create forge app directory
mkdir C:\temp\salesforce-jira-bridge
cd C:\temp\salesforce-jira-bridge

# Copy all files from unpackaged/tasks/forge-app/
# (Copy manifest.yml, package.json, src/index.js)
```

#### 2.2 Deploy Forge App
```bash
# Install dependencies and deploy
npm install
forge deploy

# Install to your Atlassian site
forge install --upgrade-edge
```

### **Phase 3: Configure Integration**

#### 3.1 Update Manual Configuration Checklist
- Complete all tasks in `MANUAL_CONFIG_CHECKLIST.md`
- Record all URLs, keys, and settings as you go

#### 3.2 Import External Service Schema
- Use `external-service-schema.json` in Salesforce Setup
- Update the server URL with your actual Forge app URL

### **Phase 4: Testing & Validation**

#### 4.1 Run Salesforce Tests
```bash
# Unit tests
cci task run run_tests --org dev

# Integration tests (Robot Framework)
cci task run robot --org dev
```

#### 4.2 Manual Integration Tests
Follow the test scenarios in `jira_integration_e2e.robot` manually to verify:
- ✅ JIRA issue creation from Salesforce
- ✅ Status updates from JIRA to Salesforce  
- ✅ Error handling and retry logic
- ✅ Small office volume testing (50-100 records)

---

## 🎯 Configuration Reference

### **Key Configuration Points**

#### Forge App Configuration
```json
{
  "instanceUrl": "https://YOUR-ORG.my.salesforce.com",
  "clientId": "YOUR_CONNECTED_APP_CONSUMER_KEY",
  "clientSecret": "YOUR_CONNECTED_APP_CONSUMER_SECRET", 
  "jiraProjectKey": "SH",
  "jiraInstanceUrl": "https://shulman-hill.atlassian.net"
}
```

#### Salesforce External Service
- **Service Name**: Jira Bridge Forge App
- **Service URL**: `https://[YOUR-FORGE-APP-ID].atlassian.net`
- **Schema**: Use `external-service-schema.json`

---

## 🔍 Validation & Troubleshooting

### **Health Check Commands**

#### Check Salesforce Deployment
```bash
# Verify objects deployed
sf sobject describe --sobject Jira_Sync__c --target-org YOUR_ORG

# Verify classes deployed  
sf apex list class --target-org YOUR_ORG | grep JiraForge
```

#### Check Forge App Status
```bash
# Check deployment status
forge status

# Monitor logs
forge logs --follow

# List installed apps
forge install --list
```

### **Common Issues & Solutions**

#### ❌ **External Service Import Fails**
- **Cause**: Incorrect Forge app URL
- **Fix**: Get correct URL with `forge install --list`

#### ❌ **Connected App Authentication Fails**  
- **Cause**: Incorrect Consumer Key/Secret
- **Fix**: Double-check Connected App settings in Salesforce

#### ❌ **JIRA Issue Creation Fails**
- **Cause**: Incorrect project key or permissions
- **Fix**: Verify "SH" project exists and Forge app has permissions

#### ❌ **Tests Fail with "External Service Not Found"**
- **Cause**: External Service not configured yet
- **Fix**: Complete External Service setup before running full tests

---

## 📊 Small Office Optimization Verification

### **Performance Benchmarks**
- [ ] ✅ Single issue creation: < 3 seconds
- [ ] ✅ Batch of 50 issues: < 30 seconds  
- [ ] ✅ Status sync: < 2 seconds
- [ ] ✅ Error recovery: < 10 seconds (3 retries)

### **Usability Checks**
- [ ] ✅ JIRA_Sync__c records visible in standard list views
- [ ] ✅ Failed syncs easily identifiable in "Failed Syncs" view
- [ ] ✅ JIRA links clickable from Salesforce records
- [ ] ✅ Error messages helpful for troubleshooting

---

## 🎉 Go-Live Checklist

### **Pre-Production**
- [ ] All unit tests pass (75%+ coverage requirement met)
- [ ] Integration tests pass manually
- [ ] Health check returns positive results
- [ ] Error handling verified with failed scenarios
- [ ] User access permissions configured

### **Production Deployment**
- [ ] Deploy Forge app to production: `forge deploy --environment production`
- [ ] Update Salesforce External Service to production URL
- [ ] Update Connected App security settings (IP restrictions)
- [ ] Configure monitoring and alerting
- [ ] Train users on new JIRA sync functionality

### **Post Go-Live**  
- [ ] Monitor sync success rate (target: >95%)
- [ ] Review error logs daily for first week
- [ ] Gather user feedback on functionality
- [ ] Document any additional troubleshooting steps

---

## 📞 Support & Maintenance

### **Ongoing Tasks**
- **Daily**: Check "Failed Syncs" list view for any issues
- **Weekly**: Review sync success rate via health check
- **Monthly**: Review and cleanup old sync records if needed

### **Troubleshooting Resources**
- **Salesforce Debug Logs**: Enable for JiraForgeService class
- **Forge Logs**: `forge logs --follow` for real-time monitoring  
- **JIRA Audit Log**: Check issue creation/update history
- **Health Check**: Use `JiraForgeService.checkIntegrationHealth()` method

---

## 🏆 Success Metrics

**Small Office Integration Success = Simple + Reliable + Low Maintenance**

- ✅ **99%+ sync reliability** (target for small office)
- ✅ **< 5 minutes setup time** for new users
- ✅ **Zero daily maintenance** required
- ✅ **Clear error messages** when issues occur
- ✅ **One-click access** to JIRA from Salesforce

**You're ready for a production-quality, small office optimized JIRA integration! 🚀**