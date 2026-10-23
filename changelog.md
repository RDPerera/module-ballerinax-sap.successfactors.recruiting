# Changelog

This file contains all the notable changes done to the Ballerina `sap.successfactors.recruiting` module.

## [2.0.0] - Unreleased

### Fixed

- **Breaking:** renamed every meaningless `Wrapper`/`Wrapper_N` OData response-envelope type (476
  occurrences across all 21 modules) and every escaped-space-identifier envelope type in `rcmjobrequisition`
  occurrences across all 21 modules) and every escaped-space-identifier envelope type in `rcmjobapplication`
  occurrences across all 21 modules) and every escaped-space-identifier envelope type in `rcmcandidate`
  occurrences across all 21 modules) and every escaped-space-identifier envelope type in `rcmoffer`
  occurrences across all 21 modules) and every escaped-space-identifier envelope type in `recruitingrcm`
  specifically (132 occurrences, e.g. `` Time\ Account\ Posting\ Rule ``, `` Modified Work Schedule Day ``)
  to a meaningful, collision-free name derived from the operation that returns/accepts it, e.g.
  `getTimeAccountPostingRule` → `GetTimeAccountPostingRuleResponse`, `updateEmployeeTimeAUS` payload →
  `UpdateEmployeeTimeAUSPayload`. Anyone referencing these types by name (rather than through type
  inference) needs to update to the new names.

### Changed

- Bumped every connector package to version `2.0.0` (from `1.1.1`).

## [1.0.0] - Unreleased

### Fixed

- Fixed the OData service base path hardcoded in every connector's `client.bal` (and the matching mock servers):
  it was `/successfactors/odata/v2`, but the actual SAP SuccessFactors OData v2 endpoint is `/odata/v2`. Verified
  against a live SuccessFactors tenant — this bug made every connector in this repository unusable against a real
  server out of the box.
- Removed stray `.devcontainer.json` scaffolding files left over in 12 of the 21 modules.
- Removed the outdated root-level `issue_template.md` and `pull_request_template.md`, which duplicated and
  contradicted the actual templates under `.github/`.
- Fixed `pack_and_push_modules.sh`, which only listed 8 of the 21 modules, to cover all of them.
- Rewrote `ballerina/rcmjobrequisition/README.md`, which was a copy of the repository-wide package catalog instead
- Rewrote `ballerina/rcmjobapplication/README.md`, which was a copy of the repository-wide package catalog instead
- Rewrote `ballerina/rcmcandidate/README.md`, which was a copy of the repository-wide package catalog instead
- Rewrote `ballerina/rcmoffer/README.md`, which was a copy of the repository-wide package catalog instead
- Rewrote `ballerina/recruitingrcm/README.md`, which was a copy of the repository-wide package catalog instead
  of documentation for that module.

### Added

- Added a `release-all.yml` workflow to release every connector package in one dispatch, matching the pattern
  used in `module-ballerinax-sap.businessone`.

### Changed

- Bumped every connector package to version `1.0.0` (from `0.9.0`).
- Bumped the Ballerina distribution to `2201.12.0` (from `2201.13.0`) in every module.