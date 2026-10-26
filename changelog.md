# Changelog

This file contains all the notable changes done to the Ballerina SAP SuccessFactors Recruiting connectors.

## [1.0.0] - Unreleased

### Added

- Initial release of five connectors generated from the
  [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview):
  `sap.successfactors.rcmjobrequisition` (Job Requisition), `sap.successfactors.rcmjobapplication`
  (Job Application), `sap.successfactors.rcmcandidate` (Candidate), `sap.successfactors.rcmoffer` (Job Offer)
  and `sap.successfactors.recruitingrcm` (Job Application Interview).
- Each connector is built on `ballerinax/sap` 1.4.0 and supports Basic Authentication and OAuth 2.0 SAML Bearer.
- Mock services and tests for every connector.
