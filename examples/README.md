# Examples

The SAP SuccessFactors Recruiting Ballerina connectors provide practical examples illustrating usage in various
scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/tree/main/examples),
covering use cases like syncing employee data and sending notifications.

1. [Google Sheets to SuccessFactors](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/tree/main/examples/google-sheets-to-successfactors) -
   Demonstrates how to read employee IDs from a Google Sheets roster and look up the corresponding Personal Information
   records in SAP SuccessFactors Recruiting.

2. [SuccessFactors to Slack](https://github.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/tree/main/examples/successfactors-to-slack) -
   Demonstrates how to fetch recently onboarded employees from SAP SuccessFactors Recruiting and send a welcome
   notification to a Slack channel via an incoming webhook.

## Prerequisites

Each example includes detailed steps.

## Running an Example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the Examples with the Local Module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the
module is manually written to the central repository as a workaround. Consequently, the bash script may modify your
local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
