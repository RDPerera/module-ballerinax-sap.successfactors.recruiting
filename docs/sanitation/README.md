# SAP Connector Sanitizer

This is a comprehensive sanitizer tool for SAP connectors. It provides unified sanitization for both OpenAPI specifications and generated Ballerina code, replacing all individual sanitization scripts.

## Overview

The sanitizer handles the complete workflow from OpenAPI specification sanitization to generated code sanitization, ensuring clean, valid, and properly structured SAP connector modules.

## Features

### 🔧 **OpenAPI Specification Sanitization**
- **Schema Names**: Sanitizes schema names for better Ballerina compatibility
- **Operation IDs**: Generates proper operation IDs based on paths and HTTP methods
- **Enum Parameters**: Handles enum parameter sanitization
- **Response Schemas**: Sanitizes response schema names
- **Parameter Conflicts**: Resolves parameter and schema name conflicts

### 📝 **Generated Code Sanitization**
- **Type Definitions**: Fixes invalid Ballerina type names with backslashes
- **Client Configuration**: Updates client.bal files for SAP client usage
- **Import Statements**: Adds required SAP imports and configurations

### 🚀 **Batch Processing**
- **Single Command**: Process all specs or all modules at once
- **Complete Workflow**: End-to-end sanitization from specs to modules
- **Selective Processing**: Target specific components as needed

## Installation & Usage

### Prerequisites
- Ballerina 2201.x or later
- Access to the project's docs/sanitation directory

### Basic Usage

```bash
# Display help and available commands
bal run sanitizer.bal
```

### Individual Operations

#### OpenAPI Specification Sanitization
```bash
# Sanitize a single OpenAPI spec
bal run sanitizer.bal -- sanitize-spec <apiName>

# Example
bal run sanitizer.bal -- sanitize-spec api_name
```

#### Module Code Sanitization
```bash
# Sanitize only type definitions
bal run sanitizer.bal -- sanitize-types <moduleName>

# Sanitize only client configuration
bal run sanitizer.bal -- sanitize-client <moduleName> <apiPostfix>

# Sanitize complete module (types + client)
bal run sanitizer.bal -- sanitize-module <moduleName> <apiPostfix>

# Examples
bal run sanitizer.bal -- sanitize-types module_name
bal run sanitizer.bal -- sanitize-client module_name api/postfix/path
bal run sanitizer.bal -- sanitize-module module_name api/postfix/path
```

### Batch Operations

#### Batch Specification Sanitization
```bash
# Sanitize all OpenAPI specs
bal run sanitizer.bal -- batch-specs
```

#### Batch Module Sanitization
```bash
# Sanitize types for all modules
bal run sanitizer.bal -- batch-types

# Sanitize everything for all modules
bal run sanitizer.bal -- batch-modules <apiPostfix>

# Example
bal run sanitizer.bal -- batch-modules api/postfix/path
```

#### Complete Workflow
```bash
# Complete end-to-end sanitization (specs + modules)
bal run sanitizer.bal -- batch-all <apiPostfix>

# Example
bal run sanitizer.bal -- batch-all api/postfix/path
```

## Process to Create a New SAP Connector

### Step 1: Initial Setup
Under the `ballerina` directory, create a simple case `<API_Name>` module:

```bash
cd ballerina
mkdir <API_Name>
cd <API_Name>
```

### Step 2: Initialize Module
```bash
bal new .
```

### Step 3: Add Documentation
Add `README.md` and `docs.json` files. For samples, refer to existing modules.

### Step 4: Update Build Configuration
Add the module to the main build configuration.

### Step 5: Add OpenAPI Specification
Add the `<API_NAME>.json` file under the `docs/spec` directory.

### Step 6: Sanitize OpenAPI Specification
**⚠️ Note: Following commands need to be run within the `docs/sanitation` directory.**

```bash
cd docs/sanitation

# Sanitize the OpenAPI specification
bal run sanitizer.bal -- sanitize-spec "<API_Name>"
```

### Step 7: Generate OpenAPI Client
```bash
cd docs

# Generate the Ballerina client from OpenAPI spec
bal openapi -i spec/<API_Name>.json -o ../ballerina/<Module_Name> --mode client --license license.txt
```

**⚠️ Important: DO NOT FORGET to delete `main.bal` after generation.**

### Step 8: Sanitize Generated Client
```bash
cd sanitation

# Sanitize the generated client code
bal run sanitizer.bal -- sanitize-module "<Module_Name>" "<API_Postfix>"

# Example
bal run sanitizer.bal -- sanitize-module module_name api/postfix/path
```

### Step 9: Generate Mock Server (Optional)
For testing purposes, create a mock server:

1. Remove any parameterized paths in the spec
2. Save as `spec/<API_NAME>_MOCK.json`
3. Generate mock server:

```bash
cd docs

# Generate mock server
bal openapi -i spec/<API_NAME>_MOCK.json -o ../ballerina/<Module_Name>/modules/mock --mode service --license license.txt
```

### Step 10: Testing Setup
Ensure test cases are written against both mock and live servers, with `isTestOnLiveServer` parameter to switch between them.

### Step 11: Commit Strategy
**⚠️ Note: Commit each change separately for easier future reviews.**

Recommended commit sequence:
1. Initial module structure
2. OpenAPI specification addition
3. Specification sanitization
4. Client code generation
5. Client code sanitization
6. Mock server setup (if applicable)
7. Test implementations

## Transformations Applied

### Type Name Sanitization
The sanitizer fixes invalid Ballerina type names:

#### Before Sanitization
```ballerina
public type Collection\ of\ EntityRecord record {
    EntityRecord[] results?;
};

public type Created\ ItemChange record {
    ItemChange d?;
};

public type Related\ CollectionSFOData\.EntityJob record {
    json d?;
};
```

#### After Sanitization
```ballerina
public type CollectionofEntityRecord record {
    EntityRecord[] results?;
};

public type CreatedItemChange record {
    ItemChange d?;
};

public type RelatedCollectionSFOData_EntityJob record {
    json d?;
};
```

### Client Configuration Updates
The sanitizer updates client.bal files for SAP integration:

#### Before Sanitization
```ballerina
import ballerina/http;

public isolated client class Client {
    final http:Client clientEp;
    
    public isolated function init(ConnectionConfig config, string serviceUrl) returns error? {
        // ...
    }
}
```

#### After Sanitization
```ballerina
import ballerina/http;
import ballerinax/sap;

public isolated client class Client {
    final sap:Client clientEp;
    
    public isolated function init(ConnectionConfig config, string hostname, int port = 443) returns error? {
        string serviceUrl = string `${hostname}:${port}/api/postfix/path`;
        // ...
    }
}
```

### Operation ID Generation
For OpenAPI specifications, the sanitizer generates proper operation IDs:

- **GET** collection endpoints → `list<ResourceName>s`
- **GET** single entity endpoints → `get<ResourceName>`  
- **POST** endpoints → `create<ResourceName>`
- **PUT** endpoints → `update<ResourceName>`
- **DELETE** endpoints → `delete<ResourceName>`
- **PATCH** endpoints → `patch<ResourceName>`

## Supported Modules

The sanitizer automatically processes these modules:
- module1
- module2
- module3
- [Add your specific modules here]

## Files Processed

### For OpenAPI Specifications
- `docs/spec/<API_NAME>.json` - OpenAPI/Swagger specification files

### For Generated Code
- `<module>/types.bal` - Type definitions
- `<module>/client.bal` - Client implementation
- `<module>/utils.bal` - Utility functions

## Automatic Operations

After each sanitization operation, the sanitizer automatically:
1. **Formats** the code using `bal format`
2. **Builds** the module using `bal build`  
3. **Reports** success/failure status
4. **Validates** that changes don't break compilation

## Verification

### Check Type Sanitization
Verify that no backslash patterns remain in source files:

```bash
# Check for remaining backslash patterns
find ballerina -name "*.bal" -not -path "*/build/*" -not -path "*/target/*" -exec grep -l "Collection\\\\\|Created\\\\\|Modified\\\\\|Related\\\\" {} \;
```

If the command returns no results, all patterns have been successfully sanitized.

### Check Generated Types
Verify that types are properly transformed:

```bash
# Check for properly transformed types
grep -n "Collectionof\|Created\|Modified\|Related" ballerina/<module>/types.bal | head -5
```
