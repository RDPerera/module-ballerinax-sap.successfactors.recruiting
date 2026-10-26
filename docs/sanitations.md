# SAP SuccessFactors Recruiting OpenAPI Specification Sanitization

Author: @RDPerera

## Overview

The SAP SuccessFactors Recruiting APIs are delivered as Swagger 2.0 specifications from the
[SAP Business Accelerator Hub](https://api.sap.com/package/SuccessFactorsRecruiting/overview). These specifications
need several sanitization steps before `bal openapi` can generate idiomatic Ballerina connectors from them.

## Sanitization Steps

### 1. Operation ID Generation (`operation_id.bal`)

The specs do not include `operationId` fields, so the sanitizer derives one from the path and the HTTP method:

- `GET /JobRequisition` becomes `listJobRequisitions` (collection response)
- `GET /JobRequisition({jobReqId})` becomes `getJobRequisition` (single entity)
- `POST /JobRequisition` becomes `createJobRequisition`
- `PUT`, `PATCH` and `DELETE` become `update...`, `patch...` and `delete...`
- `GET /JobReqGOPosition({jobReqMultiSelectId})/value` becomes `listValuesOfJobReqGOPosition` (navigation property)

Additional rules:

- Function imports (paths that start with a lower-case letter, such as `/approveOffer` or `/inviteToApply`) keep
  their own name.
- Collection names are pluralized with English rules, so `JobApplicationStatus` becomes `JobApplicationStatuses`
  and `Candidate` becomes `Candidates`. Names that already end in `s` (for example `CandidateComments`) are kept.
- Job Requisition has both `JobLocation` and `JobLocations` entity sets. The multi-select `JobLocations` set is
  named after its SAP tag (`listJobRequisitionLocations`, `getJobRequisitionLocations`) so the two do not collide.
- The sanitizer fails if two operations end up with the same `operationId`.

### 2. Missing Path Parameters (`sanitations.bal`)

Some operations use a path parameter, such as `{jobReqId}`, without declaring it. The sanitizer copies the
declaration from a sibling operation on the same entity.

### 3. Multi-Type Definitions (`sanitations.bal`)

Some properties are typed as a list, such as `["string", "null"]`. The sanitizer narrows them to a single type and
marks them `x-nullable` when `null` is one of the types. Properties with several non-null types become `string`.

### 4. Schema Name Sanitization (`sanitations.bal`)

The specs use namespace-qualified definition names, such as `SFOData.JobRequisition`. The sanitizer:

- Strips the namespace prefix
- Removes suffixes such as `-create` and `-update` and prefixes the create and update variants instead
- Retitles `Related Collection(SFOData.X)` and `Collection of X` schemas to `RelatedCollectionOfX` and
  `CollectionOfX`. Without this, `bal openapi` silently drops the create and update operations that use them.
- Updates every `$ref` in the spec to match the renamed definitions

### 5. Response and Payload Envelope Titles (`sanitations.bal`)

OData V2 wraps every entity in a `{"d": ...}` envelope. The specs either leave this envelope untitled, so
`bal openapi` names it `Wrapper`/`Wrapper_N`, or reuse the entity's display name. The sanitizer titles each envelope
after its operation: `getJobRequisition` gets `GetJobRequisitionResponse`, and a body envelope gets
`<Operation>Payload`. When `<Operation>Response` is already a definition name, the envelope is titled
`<Operation>Result` instead, for example `InviteToApplyResult`.

### 6. Client Sanitization (`client_sanitations.bal`)

After code generation, the generated client uses a plain `http:Client`. This step:

- Replaces `http:Client` with `sap:Client`, which handles CSRF tokens and the OAuth 2.0 SAML Bearer flow
- Replaces `http:ClientConfiguration` with `sap:ConnectionConfig`
- Replaces the `serviceUrl` parameter with `string hostname, int port = 443` and builds the service URL as
  `` https://${hostname}:${port}/odata/v2 ``
- Changes `auth` in `types.bal` to `http:CredentialsConfig|sap:SamlBearerAuthConfig`
- Formats and builds the package, and fails if the build fails

## Running the Sanitization

### Prerequisites

- Ballerina Swan Lake 2201.13.0 or later
- The original API specifications in `docs/spec/<apiName>.json`

### Step-by-step Process

Run all commands from the `docs/` directory.

1. Add the operation IDs:

   ```bash
   bal run sanitation/operation_id.bal -- <apiName>
   ```

2. Sanitize the specification:

   ```bash
   bal run sanitation/sanitations.bal -- <apiName>
   ```

3. Generate the Ballerina client:

   ```bash
   bal openapi -i spec/<apiName>.json -o ../ballerina/<moduleName> --mode client --license license.txt
   ```

4. Sanitize the generated client:

   ```bash
   bal run sanitation/client_sanitations.bal -- <moduleName> odata/v2
   ```

### Supported Modules

| Module | API Name | API |
|--------|----------|-----|
| `rcmjobrequisition` | `RCMJobRequisition` | Job Requisition |
| `rcmjobapplication` | `RCMJobApplication` | Job Application |
| `rcmcandidate` | `RCMCandidate` | Candidate |
| `rcmoffer` | `RCMOffer` | Job Offer |
| `recruitingrcm` | `RecruitingRCM` | Job Application Interview |
