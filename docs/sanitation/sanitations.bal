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

type Items record {
    string 'type?;
    string[] 'enum?;
    string \$ref?;
};

type Schema record {
    string 'type?;
    boolean uniqueItems?;
    Items items?;
    string title?;
    json properties?;
};

type ParametersItem record {
    string name?;
    string 'in?;
    boolean required?;
    string description?;
    boolean explode?;
    Schema schema?;
    string \$ref?;
};

type EnumItems record {
    string 'type;
    string[] 'enum;
};

type EnumSchema record {
    string 'type;
    boolean uniqueItems;
    EnumItems items;
};

type Get record {
    string operationId?;
    string summary?;
    string description?;
    string[] tags?;
    ParametersItem[] parameters?;
    json responses?;
};

type Post record {
    string operationId?;
    string summary?;
    string description?;
    string[] tags?;
    json requestBody?;
    ParametersItem[] parameters?;
    json responses?;
};

# Swagger 2.0 body parameters (used for PUT/PATCH request payloads) are carried in `parameters`,
# not `requestBody` (an OpenAPI 3 concept) - reuse the `Post` shape for PUT/PATCH/DELETE since the
# fields we care about (operationId, parameters, responses) are identical.
type Method record {
    string operationId?;
    string summary?;
    string description?;
    string[] tags?;
    ParametersItem[] parameters?;
    json responses?;
};

type Parameter record {
    string name?;
    string 'in?;
    boolean required?;
    string description?;
    boolean explode?;
    json schema?;
};

type Path record {
    Parameter[] parameters?;
    Get get?;
    Post post?;
    Method put?;
    Method patch?;
    Method delete?;
};

type ResponseCode record {
    string description?;
    json content?;
};

type ResponseHeader record {
    json schema?;
};

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
    // Swagger 2.0 top-level definitions
    map<json> definitions?;
    // Swagger 2.0 top-level parameters
    map<json> parameters?;
    json responses?;
    json[] security?;
};

public function main(string apiName) returns error? {
    string specPath = string `spec/${apiName}.json`;
    check addMissingPathParameters(specPath);
    check fixMultiTypeDefinitions(specPath);
    check sanitizeSchemaNames(apiName, specPath);
    check sanitizeResponseSchemaNames(specPath);
}

// Swagger 2.0 allows only a single `type`, but the SuccessFactors Recruiting specs use type lists
// such as `["string", "null"]` (nullable), `["integer", "string"]` (Edm.Int64) or
// `["number", "string", "null"]` (nullable Edm.Decimal), which `bal openapi` cannot resolve and
// silently drops the operations that use them. A `null` member becomes `x-nullable: true`. When a
// list mixes `string` with a numeric type the value is narrowed to `string`, because OData V2
// serializes Edm.Int64 and Edm.Decimal as JSON strings. Otherwise the single remaining type is kept.
function fixMultiTypeDefinitions(string specPath) returns error? {
    json spec = check io:fileReadJson(specPath);
    narrowTypeLists(spec);
    check io:fileWriteJson(specPath, spec);
}

function narrowTypeLists(json node) {
    if node is map<json> {
        // Navigation collections are titled `Related Collection(SFOData.<Entity>)`. `bal openapi`
        // cannot turn that title into a type name, and drops every operation whose payload contains
        // one (for example `createCandidate`), so the title is rewritten to `RelatedCollectionOf<Entity>`.
        json title = node["title"];
        if title is string && title.startsWith("Related Collection(") && title.endsWith(")") {
            string entity = title.substring(19, title.length() - 1);
            if entity.startsWith("SFOData.") {
                entity = entity.substring(8);
            }
            node["title"] = "RelatedCollectionOf" + entity;
        } else if title is string && title.startsWith("Collection of ") {
            // List responses are titled `Collection of <Entity>`, which becomes an escaped-space
            // type name (`Collection\ of\ JobOffer`), so it is rewritten to `CollectionOf<Entity>`.
            node["title"] = "CollectionOf" + re ` `.replaceAll(title.substring(14), "");
        }
        json 'type = node["type"];
        if 'type is json[] {
            string[] types = from json t in 'type where t is string && t != "null" select t;
            if types.length() < 'type.length() {
                node["x-nullable"] = true;
            }
            if types.length() == 1 {
                node["type"] = types[0];
            } else {
                node["type"] = "string";
                _ = node.removeIfHasKey("format");
            }
        }
        foreach json child in node {
            narrowTypeLists(child);
        }
    } else if node is json[] {
        foreach json child in node {
            narrowTypeLists(child);
        }
    }
}

// Some SuccessFactors operations (for example `POST /JobRequisition({jobReqId})/location_objlist`)
// use a path key without declaring it, which `bal openapi` rejects. The other operations on the
// same path declare it, so the missing declaration is copied from them.
function addMissingPathParameters(string specPath) returns error? {
    map<json> spec = check (check io:fileReadJson(specPath)).ensureType();
    map<json> paths = check spec["paths"].ensureType();
    foreach [string, json] [path, pathItem] in paths.entries() {
        if pathItem !is map<json> {
            continue;
        }
        map<json> declared = {};
        foreach json operation in pathItem {
            if operation is map<json> && operation["parameters"] is json[] {
                foreach json param in <json[]>operation["parameters"] {
                    if param is map<json> && param["in"] == "path" && param["name"] is string {
                        declared[<string>param["name"]] = param;
                    }
                }
            }
        }
        foreach json operation in pathItem {
            if operation !is map<json> || operation["responses"] is () {
                continue;
            }
            json[] parameters = operation["parameters"] is json[] ? <json[]>operation["parameters"] : [];
            string[] present = from json p in parameters
                where p is map<json> && p["in"] == "path" && p["name"] is string
                select <string>p["name"];
            foreach regexp:Groups groups in re `\{(\w+)\}`.findAllGroups(path) {
                regexp:Span? name = groups[1];
                if name is regexp:Span && present.indexOf(name.substring()) is () && declared.hasKey(name.substring()) {
                    parameters.push(declared.get(name.substring()));
                }
            }
            operation["parameters"] = parameters;
        }
    }
    check io:fileWriteJson(specPath, spec);
}

function sanitizeSchemaNames(string apiName, string specPath) returns error? {
    json openAPISpec = check io:fileReadJson(specPath);
    Specification spec = check openAPISpec.cloneWithType(Specification);

    map<json> definitions = spec.definitions ?: {};
    map<json> updatedDefinitions = {};
    map<string> updatedNames = {};

    foreach [string, json] [schemaName, schema] in definitions.entries() {
        boolean schemaNameCheck = schemaName.includes(".");
        if schemaNameCheck {
            string updatedKey = getSanitizedSchemaName(schemaName);
            updatedDefinitions[updatedKey] = schema;
            updatedNames[schemaName] = updatedKey;
        } else {
            updatedDefinitions[schemaName] = schema;
        }
    }
    spec.definitions = updatedDefinitions;

    string updatedSpec = spec.toJsonString();
    foreach [string, string] [oldName, newName] in updatedNames.entries() {
        string sanitizedOldNameRegex = re `\.`.replace(oldName, "\\.");
        regexp:RegExp regexpPattern = re `${sanitizedOldNameRegex}"`;
        updatedSpec = regexpPattern.replaceAll(updatedSpec, newName + "\"");
    }

    check io:fileWriteString(specPath, updatedSpec);
}

function getSanitizedSchemaName(string schemaName) returns string {
    int? indexOfPeriod = schemaName.lastIndexOf(".");
    int substringStartIndex = indexOfPeriod == () ? 0 : indexOfPeriod + 1;
    string updatedKey = schemaName.substring(substringStartIndex);

    if updatedKey.endsWith("_Type") {
        updatedKey = updatedKey.substring(0, updatedKey.length() - 5);
    }

    if updatedKey.endsWith("_Type-create") {
        updatedKey = "Create" + updatedKey.substring(0, updatedKey.length() - 12);
    }

    if updatedKey.endsWith("_Type-update") {
        updatedKey = "Update" + updatedKey.substring(0, updatedKey.length() - 12);
    }

    if updatedKey.endsWith("Type") {
        updatedKey = updatedKey.substring(0, updatedKey.length() - 4);
    }

    if updatedKey.endsWith("-create") {
        updatedKey = "Create" + updatedKey.substring(0, updatedKey.length() - 7);
    }

    if updatedKey.endsWith("-update") {
        updatedKey = "Update" + updatedKey.substring(0, updatedKey.length() - 7);
    }
    return updatedKey;
}

function sanitizeResponseSchemaNames(string specPath) returns error? {
    json openAPISpec = check io:fileReadJson(specPath);
    Specification spec = check openAPISpec.cloneWithType(Specification);

    map<Path> paths = spec.paths;
    string[] definitionNames = (spec.definitions ?: {}).keys();
    foreach var [_, path] in paths.entries() {
        check retitleOperation(path.get?.operationId, path.get?.responses, path.get?.parameters, definitionNames);
        check retitleOperation(path.post?.operationId, path.post?.responses, path.post?.parameters, definitionNames);
        check retitleOperation(path.put?.operationId, path.put?.responses, path.put?.parameters, definitionNames);
        check retitleOperation(path.patch?.operationId, path.patch?.responses, path.patch?.parameters, definitionNames);
        check retitleOperation(path.delete?.operationId, path.delete?.responses, path.delete?.parameters, definitionNames);
    }

    check io:fileWriteJson(specPath, spec.toJson());
}

// SuccessFactors' OData v2 spec wraps every entity in a `{"d": ...}` envelope, both for responses
// and for body parameters. Swagger 2.0 either leaves that envelope schema untitled (bal openapi then
// invents a meaningless "Wrapper"/"Wrapper_N" name) or copies the entity's own human-readable display
// name onto it verbatim (e.g. "Time Account Posting Rule"), which collides with the entity's own
// generated type name and forces bal openapi to fall back to an escaped-space identifier. Giving the
// envelope a name derived from the operationId is always meaningful and can never collide with the
// entity type it wraps.
//
// When an SAP definition already has the `<OperationId>Response` name (for example the
// `InviteToApplyResponse` complex type), the envelope is named `<OperationId>Result` instead, so that
// `bal openapi` does not fall back to a suffixed name such as `InviteToApplyResponse_`.
function retitleOperation(string? operationId, json? responses, ParametersItem[]? parameters,
        string[] definitionNames = []) returns error? {
    string? opId = operationId;
    if opId is () {
        return;
    }

    if responses is map<json> {
        foreach var [code, response] in responses.entries() {
            if code == "default" {
                continue;
            }
            string responseTitle = capitalize(opId) + "Response";
            if definitionNames.indexOf(responseTitle) !is () {
                responseTitle = capitalize(opId) + "Result";
            }
            check retitleEnvelope(response, "schema", responseTitle);
        }
    }

    foreach ParametersItem parameterItem in parameters ?: [] {
        if parameterItem.'in == "body" {
            Schema? schema = parameterItem.schema;
            json? properties = schema?.properties;
            if schema is Schema && properties is map<json> && properties.hasKey("d") {
                schema.title = capitalize(opId) + "Payload";
            }
        }
    }
}

function retitleEnvelope(json response, string schemaField, string newTitle) returns error? {
    if response !is map<json> {
        return;
    }
    json? schema = response[schemaField];
    if schema is map<json> {
        retitleEnvelopeSchema(schema, newTitle);
    }
}

function retitleEnvelopeSchema(map<json> schema, string newTitle) {
    json? properties = schema["properties"];
    if properties is map<json> && properties.hasKey("d") {
        schema["title"] = newTitle;
    }
}

function capitalize(string value) returns string {
    if value == "" {
        return value;
    }
    return value.substring(0, 1).toUpperAscii() + value.substring(1);
}
