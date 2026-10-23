// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/io;
import ballerina/os;

// Turns a generated SuccessFactors OData client into an `ballerinax/sap` client:
// - `http:Client` becomes `sap:Client`, which adds the CSRF and SAML bearer handling SAP needs.
// - `serviceUrl` (with or without a generated default) becomes `hostname` and `port`, and the
//   service URL is built as `https://<hostname>:<port>/<apiPostfix>`.
// - The client configuration is mapped onto `sap:ConnectionConfig`, and `auth` in `types.bal` accepts
//   Basic Auth or OAuth 2.0 SAML bearer (`http:CredentialsConfig|sap:SamlBearerAuthConfig`).
public function main(string moduleName, string apiPostfix) returns error? {
    string modulePath = string `../ballerina/${moduleName}`;
    string clientPath = modulePath + "/client.bal";
    string typesPath = modulePath + "/types.bal";

    string clientText = check io:fileReadString(clientPath);
    clientText = re `http:Client clientEp`.replaceAll(clientText, "sap:Client clientEp");
    clientText = re `http:Client httpEp`.replaceAll(clientText, "sap:Client httpEp");
    clientText = re `http:ClientConfiguration httpClientConfig`.replaceAll(clientText, "sap:ConnectionConfig httpClientConfig");
    clientText = re `string serviceUrl = "[^"]*"\) returns error\? \{`.replace(clientText,
            "string hostname, int port = 443) returns error? {\n        string serviceUrl = string `https://${hostname}:${port}/" + apiPostfix + "`;");
    clientText = re `string serviceUrl\) returns error\? \{`.replace(clientText,
            "string hostname, int port = 443) returns error? {\n        string serviceUrl = string `https://${hostname}:${port}/" + apiPostfix + "`;");
    clientText = addSapImport(clientText);
    check io:fileWriteString(clientPath, clientText);

    string typesText = check io:fileReadString(typesPath);
    typesText = re `http:CredentialsConfig auth;`.replace(typesText, "http:CredentialsConfig|sap:SamlBearerAuthConfig auth;");
    typesText = addSapImport(typesText);
    check io:fileWriteString(typesPath, typesText);

    check run("format", modulePath);
    check run("build", modulePath);
}

function addSapImport(string text) returns string {
    if text.includes("import ballerinax/sap;") {
        return text;
    }
    return re `import ballerina/http;`.replace(text, "import ballerina/http;\nimport ballerinax/sap;");
}

function run(string command, string modulePath) returns error? {
    os:Process process = check os:exec({value: "bal", arguments: [command, modulePath]});
    int exitCode = check process.waitForExit();
    if exitCode != 0 {
        return error(string `bal ${command} ${modulePath} failed with exit code ${exitCode}`);
    }
}
