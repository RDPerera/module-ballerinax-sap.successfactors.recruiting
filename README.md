# Ballerina SAP SuccessFactors Recruiting Connectors

[![Build](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-sap.successfactors.recruiting.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/successfactors.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fsuccessfactors)

[SAP SuccessFactors Recruiting](https://www.sap.com/products/hcm/recruiting-software.html) is the talent acquisition
module of SAP SuccessFactors. It covers the hiring process from opening a job requisition and posting it, through
candidate profiles and job applications, to interviews and job offers.

This repository encompasses all Ballerina packages pertaining to the SAP SuccessFactors Recruiting module. Notably:

1. [SAP SuccessFactors Job Requisition](ballerina/rcmjobrequisition) provides a way to interact with the
   [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview).
   The service allows to create and manage job requisitions, including their postings, locations, operators, screening questions and translations.

2. [SAP SuccessFactors Job Application](ballerina/rcmjobapplication) provides a way to interact with the
   [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview).
   The service allows to query and manage job applications, and to assess applicants through comments, status changes, assessments and background checks.

3. [SAP SuccessFactors Candidate](ballerina/rcmcandidate) provides a way to interact with the
   [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview).
   The service allows to query and maintain candidate profiles and their background information, such as education, work experience, certificates and languages.

4. [SAP SuccessFactors Job Offer](ballerina/rcmoffer) provides a way to interact with the
   [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview).
   The service allows to approve or decline job offers, and to query or manage offer approvers and offer letters.

5. [SAP SuccessFactors Job Application Interview](ballerina/recruitingrcm) provides a way to interact with the
   [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview).
   The service allows to view and edit job interviews, including their date and time, interviewers and assessments, and to invite candidates to apply for a job requisition.

## Issues and projects

The **Issues** and **Projects** tabs are disabled for this repository as this is part of the Ballerina library. To
report bugs, request new features, start new discussions, view project boards, etc., visit the Ballerina
library [parent repository](https://github.com/ballerina-platform/ballerina-library).

This repository only contains the source code for the package.

## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following
   sources:

   * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
   * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was
   installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

### Build options

Execute the commands below to build from the source.

1. To build all packages:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests in all packages:

   ```bash
   ./gradlew clean test
   ```

3. To build without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To build only one specific package:

   ```bash
   ./gradlew clean :recruiting-ballerina:<module_name>:build
   ```

   | Module Name         | Connector                                         |
   |---------------------|---------------------------------------------------|
   | rcmjobrequisition   | ballerinax/sap.successfactors.rcmjobrequisition   |
   | rcmjobapplication   | ballerinax/sap.successfactors.rcmjobapplication   |
   | rcmcandidate        | ballerinax/sap.successfactors.rcmcandidate        |
   | rcmoffer            | ballerinax/sap.successfactors.rcmoffer            |
   | recruitingrcm       | ballerinax/sap.successfactors.recruitingrcm       |

5. To run tests against a live server:

   ```bash
   IS_TEST_ON_SUCCESSFACTORS_SERVER=true ./gradlew clean test
   ```

   **Note**: `IS_TEST_ON_SUCCESSFACTORS_SERVER` is false by default, tests are run against the mock server.

6. To debug packages with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

7. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

8. Publish the generated artifacts to the local Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToLocalCentral=true
   ```

9. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`sap` package](https://lib.ballerina.io/ballerinax/sap/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
