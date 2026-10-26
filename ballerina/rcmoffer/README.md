## Overview

[SAP SuccessFactors Recruiting](https://www.sap.com/products/hcm/recruiting-software.html) is the talent acquisition
module of SAP SuccessFactors. It covers the hiring process from opening a job requisition and posting it, through
candidate profiles and job applications, to interviews and job offers.

WSO2 SAP SuccessFactors Job Offer provides a way to interact with the [SAP SuccessFactors Recruiting APIs](https://api.sap.com/package/SuccessFactorsRecruiting/overview). The service allows to approve or decline job offers, and to query or manage offer approvers and offer letters.

### Key Features

- Create and query job offers
- Approve or decline job offers
- Manage offer approvers and offer letters

## Setup guide

This connector supports two authentication methods: **Basic Authentication** and **OAuth 2.0 SAML Bearer**.

### Method 1: Basic Authentication

If you already have a username and password for this integration to work, you can use those directly. If you'd
rather create a new account with narrowed scope for this integration, follow these steps:

1. Sign in to your SAP SuccessFactors instance as an administrator.
2. Navigate to **Admin Center** > **Add New Employee** and create a new user account for this integration.
3. Navigate to **Admin Center** > **Manage Permission Roles**, create a role scoped to only the permissions this
   integration needs, and grant it to the new user. For Recruiting APIs this includes **Admin Access to OData API**
   and the relevant **Recruiting Permissions** (for example, read or write access to job requisitions, applications
   and candidates). Without the Recruiting permissions, insert, update, upsert and delete calls are rejected.
4. Navigate to **Admin Center** > **Reset User Password** and set a password for the new user account.

In either case, you will also need the API server hostname for your SuccessFactors region, for example,
`api12.successfactors.eu`. The complete list of API server hostnames by region is available in the
[SAP SuccessFactors API documentation](https://help.sap.com/viewer/d599f15995d348a1b45ba5603e2aba9b/LATEST/en-US/af2b8d5437494b12be88fe374eba75b6.html).

### Method 2: OAuth 2.0 SAML Bearer

#### Step 1: Generate a key pair and certificate

1. Generate an RSA key pair and a matching X.509 certificate. If you don't already have one, generate a self-signed
   pair with OpenSSL:

   ```sh
   openssl req -x509 -newkey rsa:2048 -keyout private_key.pem -out certificate.pem -days 365 -nodes -subj "/CN=YourAppName"
   ```

   `private_key.pem` is secret - it never leaves your machine or gets uploaded anywhere. Only `certificate.pem` is
   registered with SAP.

#### Step 2: Register an OAuth2 client application

1. Sign in to your SAP SuccessFactors instance as an administrator.

2. Search for **Manage OAuth2 Client Applications** in Admin Center's action search, or navigate to it directly under
   **Admin Center** > **Company Settings**.

   ![Search for Manage OAuth2 Client Applications](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/main/docs/setup/sf-2-search-oauth-action.png)

3. Choose **Register Client Application** and provide the following information:

   | Field | Description |
   |-------|-------------|
   | Application Name | A name to identify this integration |
   | Description | An optional description |
   | X.509 Certificate | The contents of `certificate.pem` as a single continuous base64 string, with the `-----BEGIN CERTIFICATE-----` / `-----END CERTIFICATE-----` lines and line breaks removed. Produce this with `awk '/BEGIN CERTIFICATE/{flag=1;next}/END CERTIFICATE/{flag=0}flag' certificate.pem \| tr -d '\n'` and paste the single line of output it prints. |

4. Choose **Register** to save the application.

#### Step 3: Note your credentials

After registering, open the application (choose **View** from the application list) to find the **Company ID** and
the **API Key** SAP assigned to it.

![View a registered OAuth2 client application](https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-sap.successfactors.recruiting/main/docs/setup/sf-3-saml-view-app.png)

You now have everything `sap:SamlBearerAuthConfig` needs:

- **apiKey** - the API Key from the application you just registered
- **companyId** - the Company ID shown on the same screen
- **username** - the SAP user to authenticate as
- **privateKey** - the path to your `private_key.pem` file
- **certificate** - the path to your `certificate.pem` file, or its content
- **tokenUrl** - your Admin Center's OAuth2 token endpoint, typically `https://<admin-center-host>/oauth/token`

## Quickstart

To use the `sap.successfactors.rcmoffer` connector in your Ballerina application, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `sap.successfactors.rcmoffer` module.

```ballerina
import ballerinax/sap.successfactors.rcmoffer as offer;
```

### Step 2: Instantiate a new connector

Use the hostname and credentials to initiate a client.

```ballerina
configurable string hostname = ?;
configurable string username = ?;
configurable string password = ?;

offer:Client offerClient = check new (
    {
      auth: {
        username,
        password
      }
    },
    hostname
);
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
offer:ListJobOffersResponse jobOffers = check offerClient->listJobOffers(\$top = 10);
```

### Step 4: Run the Ballerina application

```bash
bal run
```
