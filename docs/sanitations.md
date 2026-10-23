# SAP SuccessFactors Recruiting OpenAPI Specification Sanitization

Author: @RDPerera

## Overview

The SAP SuccessFactors Recruiting APIs are delivered as Swagger 2.0 specifications from the SAP API Hub. These specifications require several sanitization steps before they can be used to generate idiomatic Ballerina connectors using the `bal openapi` tool.

## Sanitization Steps

### 1. Schema Name Sanitization (`sanitations.bal`)

SuccessFactors Swagger 2.0 specs use fully qualified schema names with dots in the `definitions` section (e.g., `SFOData.EmpEmployment`). These cannot be directly mapped to Ballerina type names.

The sanitizer:
- Strips the namespace prefix (everything before the last `.`)
- Removes common suffixes like `_Type`, `Type`, `-create`, `-update`
- Prefixes Create/Update variants appropriately
- Updates all `$ref` references throughout the spec to match renamed definitions

### 2. Response/Payload Envelope Title Sanitization (`sanitations.bal`)

OData v2 wraps every entity in a `{"d": ...}` envelope, both in responses and in PUT/PATCH body
parameters. Swagger 2.0 either leaves this envelope schema untitled (in which case `bal openapi`
invents a meaningless `Wrapper`/`Wrapper_N` name for it) or copies the entity's own human-readable
display name onto it verbatim, e.g. `"Time Account Posting Rule"` (which collides with the entity's
own generated type name and forces `bal openapi` to fall back to an escaped-space identifier like
`` Time\ Account\ Posting\ Rule ``, unusable as a normal identifier).

The sanitizer retitles every such envelope schema — for both responses and body parameters, across
`get`/`post`/`put`/`patch`/`delete` — from the operation's own `operationId`:
`getTimeAccountPostingRule` → response envelope titled `GetTimeAccountPostingRuleResponse`;
`updateEmployeeTimeAUS` → body envelope titled `UpdateEmployeeTimeAUSPayload`. This is always
meaningful and, since it's derived from the (unique) operation name rather than the entity's own
name, can never collide with the entity type it wraps.

### 3. Operation ID Generation (`operationId.bal`)

SAP SuccessFactors Swagger 2.0 specs do not include `operationId` fields on path operations. Without these, `bal openapi` cannot generate distinct function names.

The sanitizer generates operation IDs based on the path and HTTP method:
- `GET /EmpEmployment` → `listEmpEmployments` (collection response)
- `GET /EmpEmployment('userId')` → `getEmpEmployment` (single entity)
- `POST /EmpEmployment` → `createEmpEmployment`
- `DELETE /EmpEmployment('userId')` → `deleteEmpEmployment`
- `PATCH /EmpEmployment('userId')` → `patchEmpEmployment`

The function name prefix (`list`/`get`/`create`/`update`/`delete`/`patch`) is determined by the HTTP method and whether the response description is `"Retrieved entities"` (collection) or `"Retrieved entity"` (single).

### 4. Client Sanitization (`clientSanitations.bal`)

After code generation with `bal openapi`, the generated `client.bal` uses a raw `ballerina/http:Client`. This step:
- Replaces `import ballerina/http;` with `import ballerinax/sap;`
- Replaces `http:Client clientEp` with `sap:Client clientEp`
- Replaces the `string serviceUrl` parameter with `string hostname, int port = 443`
- Adds the full service URL construction: `` string serviceUrl = string `https://${hostname}:${port}/successfactors/odata/v2`; ``

The `ballerinax/sap` client provides SAP-specific authentication and connection handling on top of the standard HTTP client.

## Running the Sanitization

### Prerequisites

- Ballerina Swan Lake 2201.13.0 or later
- API specifications in `docs/spec/<apiName>.json`

### Step-by-step Process

1. **Obtain OpenAPI specs** from the [SAP API Hub](https://api.sap.com/package/SuccessFactorsRecruiting/odata) and place them in `docs/spec/`.

2. **Sanitize schema names** for each API (run from `docs/`, not `docs/sanitation/` — the script
   resolves specs at `spec/<apiName>.json` relative to the current directory):
   ```bash
   cd docs
   bal run sanitation/sanitations.bal -- <apiName>
   ```

3. **Add operation IDs** for each API (also run from `docs/`):
   ```bash
   bal run sanitation/operationId.bal -- <apiName>
   ```

4. **Generate Ballerina client** from the sanitized spec:
   ```bash
   bal openapi -i docs/spec/<apiName>.json -o ballerina/<moduleName> --mode client
   ```

5. **Sanitize the generated client**:
   ```bash
   cd docs/sanitation
   bal run clientSanitations.bal -- <moduleName> odata/v2
   ```
   (the real SAP SuccessFactors OData v2 endpoint is `/odata/v2`, not `/successfactors/odata/v2` —
   see `changelog.md`)

6. **Build and verify**:
   ```bash
   ./gradlew :ballerina:<moduleName>:build
   ```

### Supported Modules

| Module | API Name |
|--------|----------|
| `rcmjobrequisition` | `rcmjobrequisition` |
| `rcmjobapplication` | `rcmjobapplication` |
| `rcmcandidate` | `rcmcandidate` |
| `rcmoffer` | `rcmoffer` |
| `recruitingrcm` | `recruitingrcm` |
