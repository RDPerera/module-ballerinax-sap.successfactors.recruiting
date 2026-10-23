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
import ballerina/lang.regexp;

type Method record {
    string operationId?;
    string summary?;
    string description?;
    string[] tags?;
    json[] parameters?;
    json requestBody?;
    json responses?;
};

type Path record {|
    json[] parameters?;
    Method get?;
    Method post?;
    Method put?;
    Method patch?;
    Method delete?;
|};

type Specification record {
    string swagger?;
    string openapi?;
    json info;
    json externalDocs?;
    string x\-sap\-api\-type?;
    string x\-sap\-shortText?;
    string x\-sap\-software\-min\-version?;
    json[] x\-sap\-ext\-overview?;
    json[] servers?;
    json x\-sap\-extensible?;
    json[] tags?;
    string[] schemes?;
    string host?;
    string basePath?;
    string[] consumes?;
    string[] produces?;
    json x\-servers?;
    json securityDefinitions?;
    map<Path> paths;
    map<json> definitions?;
    map<json> parameters?;
    json responses?;
    json[] security?;
};

enum HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH
}

public function main(string apiName) returns error? {
    string specPath = string `spec/${apiName}.json`;
    json openAPISpec = check io:fileReadJson(specPath);

    Specification spec = check openAPISpec.cloneWithType(Specification);

    // SuccessFactors uses Swagger 2.0 (not OData v4)
    boolean isODATA4 = false;

    map<Path> paths = spec.paths;
    foreach var [key, value] in paths.entries() {
        if value.get is Method {
            value.get.operationId = check getSanitisedPathName(key, GET, isODATA4, value.get?.responses);
        }
        if value.post is Method {
            value.post.operationId = check getSanitisedPathName(key, POST, isODATA4);
        }
        if value.put is Method {
            value.put.operationId = check getSanitisedPathName(key, PUT, isODATA4);
        }
        if value.delete is Method {
            value.delete.operationId = check getSanitisedPathName(key, DELETE, isODATA4);
        }
        if value.patch is Method {
            value.patch.operationId = check getSanitisedPathName(key, PATCH, isODATA4);
        }
    }
    map<string> seen = {};
    foreach var [key, value] in paths.entries() {
        foreach Method? m in [value.get, value.post, value.put, value.delete, value.patch] {
            string? opId = m?.operationId;
            if opId is string {
                if seen.hasKey(opId) {
                    return error(string `Duplicate operationId '${opId}' for ${seen.get(opId)} and ${key}`);
                }
                seen[opId] = key;
            }
        }
    }
    check io:fileWriteJson(specPath, spec.toJson());
}

function getSanitisedPathName(string key, HttpMethod method, boolean isODATA4, json? response = ()) returns string|error {

    match key {
        "/rejectApprovalRequest" => {
            return "rejectApprovalRequest";
        }
        "/releaseApprovalRequest" => {
            return "releaseApprovalRequest";
        }
        "/$batch" => {
            return "performBatchOperation";
        }
        // Job Requisition has both `JobLocation` (job posting locations) and `JobLocations` (the
        // multi-select locations of a requisition, tagged "Job Requisition Locations" by SAP). Both
        // would pluralize to `JobLocations`, so the multi-select set is named after its SAP tag.
        "/JobLocations" => {
            return "listJobRequisitionLocations";
        }
        "/JobLocations({jobReqMultiSelectId})" => {
            return "getJobRequisitionLocations";
        }
        "/JobLocations({jobReqMultiSelectId})/value" => {
            return "getValueOfJobRequisitionLocations";
        }
    }

    string parameterName = "";

    // SuccessFactors OData v2 uses parentheses for key predicates: /Entity('key')
    regexp:RegExp pathRegex = re `/([^(]*)(\(.*\))?(/.*)?`;

    regexp:Groups? groups = pathRegex.findGroups(key);
    if groups is () {
        return "";
    }

    // Function imports (for example `/approveOffer` or `/inviteToApply`) are already verbs in
    // lower camel case, so their own name is the operation name. Entity sets start with an
    // upper-case letter and get a `list`/`get`/`create`/... prefix below.
    regexp:Span? functionImport = groups.length() == 2 ? groups[1] : ();
    if functionImport is regexp:Span {
        string name = functionImport.substring();
        if name.length() > 0 && name.substring(0, 1) != name.substring(0, 1).toUpperAscii() {
            return name;
        }
    }

    boolean isCollectionReturnedResult = isCollectionReturned(method, response);

    match (groups.length()) {
        0|1 => {
            io:println("Error: Invalid path " + key);
            parameterName += key;
        }
        2 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += getSanitizedName(basePath.substring(), isCollectionReturnedResult);
            }
        }
        3 => {
            regexp:Span? basePath = groups[1];
            if basePath !is () {
                parameterName += basePath.substring();
            }
        }
        4 => {
            regexp:Span? resourcePath = groups[3];
            if resourcePath !is () {
                string resourcePathString = resourcePath.substring();
                if resourcePathString.startsWith("/") {
                    resourcePathString = resourcePathString.substring(1);
                }
                if resourcePathString.startsWith("to_") {
                    resourcePathString = resourcePathString.substring(3);
                }
                if resourcePathString.startsWith("_") {
                    resourcePathString = resourcePathString.substring(1);
                }
                resourcePathString = resourcePathString.substring(0, 1).toUpperAscii() + resourcePathString.substring(1);
                resourcePathString = getSanitizedName(resourcePathString, isCollectionReturnedResult);

                regexp:Span? basePath = groups[1];
                if basePath is () {
                    return "";
                }
                parameterName += resourcePathString.concat("Of", basePath.substring());
            }
        }
    }

    if parameterName.endsWith("/") {
        parameterName = parameterName.substring(0, parameterName.length() - 1);
    }

    match method {
        GET => {
            if isCollectionReturnedResult {
                parameterName = "list" + parameterName;
            } else {
                parameterName = "get" + parameterName;
            }
        }
        POST => {
            parameterName = "create" + parameterName;
        }
        PUT => {
            parameterName = "update" + parameterName;
        }
        DELETE => {
            parameterName = "delete" + parameterName;
        }
        PATCH => {
            parameterName = "patch" + parameterName;
        }
    }

    return parameterName;
}

function getSanitizedName(string word, boolean isCollectionReturnedResult) returns string {
    if isCollectionReturnedResult && !word.endsWith("Details") {
        string pluralWord = pluralize(word);
        io:println(string `Plural of ${word} is ${pluralWord}`);
        return pluralWord;
    } else {
        return word;
    }
}

// Pluralizes a SuccessFactors entity name. Many entity names are already plural (for example
// `CandidateComments` or `JobLocations`), so a trailing `s` is kept as is, except for `-us`
// (`JobApplicationStatus` -> `JobApplicationStatuses`).
function pluralize(string word) returns string {
    if word.endsWith("us") || word.endsWith("ss") || word.endsWith("x") || word.endsWith("ch") || word.endsWith("sh") {
        return word + "es";
    }
    if word.endsWith("s") {
        return word;
    }
    if word.length() > 1 && word.endsWith("y") && !"aeiou".includes(word.substring(word.length() - 2, word.length() - 1)) {
        return word.substring(0, word.length() - 1) + "ies";
    }
    return word + "s";
}

function isCollectionReturned(HttpMethod method, json? response) returns boolean {
    if method == GET {
        if response is () {
            return false;
        }
        json|error description = response.'200.description;
        if description is json {
            return description.toBalString().includes("Retrieved entities");
        }
    }
    return false;
}
