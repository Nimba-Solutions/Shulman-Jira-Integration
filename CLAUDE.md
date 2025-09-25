# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project Context - Small Office Environment
This is a small law office with:
- Handful of users (not enterprise scale)
- <100 records processed daily
- Internal trusted team environment

When performing code reviews or suggesting improvements:
- Focus on functionality and user experience issues
- Deprioritize enterprise-scale concerns like:
  - Massive dataset performance optimization
  - Advanced security auditing for untrusted users  
  - Concurrent user conflict scenarios
  - Query indexing for large volumes
  - Sophisticated caching strategies
- Prioritize issues that affect daily workflow and core functionality

## Project Overview
This is a Salesforce-JIRA integration project for Shulman law firm. The project is in transition from a webhook-based approach (v3) to a simplified Atlassian Forge-based solution (v4) for bidirectional synchronization between Salesforce and JIRA.

## Architecture
- **Platform**: Salesforce Lightning Platform (API version 64.0)
- **Development Framework**: CumulusCI for build and deployment
- **Integration Target**: JIRA via Atlassian Forge App
- **Testing**: Robot Framework for automated testing
- **Dependencies**: Shulman-Core package from Nimba Solutions

## Development Commands

### Core CumulusCI Commands
```bash
# Deploy to development org
cci flow run dev_org --org dev

# Open development org in browser
cci org browser dev

# Run all tests
cci task run run_tests

# Deploy specific tests
cci task run robot

# Generate test documentation
cci task run robot_testdoc
```

### Testing Commands
- **Required Code Coverage**: 75% minimum (configured in cumulusci.yml)
- **Test Directory**: robot/Shulman-Jira-Integration/tests/
- **Test Results**: robot/Shulman-Jira-Integration/results/
- **Test Documentation**: robot/Shulman-Jira-Integration/doc/

## Key Files and Structure

### Configuration Files
- `cumulusci.yml`: Main CumulusCI configuration with project settings, dependencies, and task definitions
- `sfdx-project.json`: Salesforce DX project configuration
- `datasets/mapping.yml`: Data mapping configuration for Account and Contact objects

### Source Code
- `force-app/main/default/`: Standard Salesforce source directory (currently empty - project in early stages)

### Testing
- `robot/Shulman-Jira-Integration/tests/create_contact.robot`: Sample Robot Framework test demonstrating API and UI testing patterns

### Documentation
- `unpackaged/tasks/JIRA_INTEGRATION_MODERN_PLAN_v4_SIMPLIFIED.md`: Comprehensive implementation plan for simplified Forge-based JIRA integration

## Development Context

### Current State
This project appears to be in early development stages with:
- Basic CumulusCI scaffold in place
- Sample Robot Framework tests
- Dependency on Shulman-Core package
- Planning documentation for JIRA integration via Atlassian Forge

### Integration Approach (v4 Simplified Plan)
The planned integration uses:
- **Atlassian Forge**: Minimal serverless functions for webhook replacement
- **External Services**: Salesforce platform standard for calling external APIs
- **InvocableMethod**: Lightning Flow integration point
- **No Complex UI**: Uses standard Salesforce setup screens

### Git Workflow
- **Main branch**: `main`
- **Feature branches**: `feature/*`
- **Beta branches**: `beta/*` 
- **Release branches**: `release/*`

## File Editing Best Practices
CRITICAL EDITING REQUIREMENTS:
1. ALWAYS use Read tool before any Edit/Write operations
2. Use MultiEdit for multiple changes to same file
3. Use replace_all=true when updating all instances of a string
4. Provide sufficient context in old_string to ensure uniqueness
5. These practices prevent editing errors and improve reliability

## Code Review Template - Small Office Context

SYSTEMATIC CODE REVIEW - SMALL OFFICE ANALYSIS:

Perform a targeted analysis of Salesforce Lightning components using small office context (handful of users, <100 daily records, internal trusted team).

REVIEW METHODOLOGY:
1. **Functionality Analysis**: Does the code work as intended? Are there logical errors affecting daily workflow?
2. **User Experience**: Are there UX issues that impact productivity for small teams?
3. **Salesforce Standards**: Does it follow Lightning platform best practices and SLDS?
4. **Code Quality**: Is it maintainable and readable for small team development?
5. **Critical Testing**: Are core business functions properly tested?

FOCUS AREAS (Small Office Priority):
- Broken functionality that affects daily operations
- Missing user feedback and loading states
- Memory leaks and component lifecycle issues
- Basic error handling and recovery
- Test coverage for core business logic

DEPRIORITIZE (Enterprise-Only Concerns):
- Massive dataset performance optimization (irrelevant for <100 records)
- Advanced security auditing for untrusted users
- Concurrent user conflict scenarios (handful of users)
- Query indexing recommendations (small datasets)
- Sophisticated caching and scaling strategies

SKIP AS NON-ISSUES FOR SMALL OFFICE:
- Hard-coded navigation URL construction (works correctly for single-org deployment)
- Missing field validation in isValidQueueRecord (sufficient for trusted internal users)
- Accessibility issues with dynamic content (existing ARIA labels adequate for small team)
- Hard-coded business logic (appropriate for stable business rules, Custom Metadata overkill)
- Business logic duplication (minimal duplication acceptable without Custom Metadata complexity)
- Hardcoded priority maps (serve as business logic filters to control queue-eligible values, dynamic queries would expose unwanted values)

**IMPORTANT**: Read ALL component files completely before analysis. Focus on issues that directly impact small office daily workflow.

Provide practical solutions appropriate for small office environment with implementation details.

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.