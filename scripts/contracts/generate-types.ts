#!/usr/bin/env bun
import { $, YAML } from "bun";

type JsonObject = Record<string, unknown>;

type ResolvedRef = {
  filePath: string;
  targetKey: string;
  schema: unknown;
};

const rootDir = Bun.fileURLToPath(new URL("../../", import.meta.url)).replace(
  /[\\/]+$/,
  "",
);
const contractsDir = process.env.CONTRACTS_OUT_DIR ?? `${rootDir}/.contracts`;
const specPathInput =
  process.env.CONTRACTS_SPEC_PATH ??
  `${contractsDir}/services/social-care/openapi/openapi.yaml`;
const outPathInput =
  process.env.CONTRACTS_TYPES_OUT ??
  `${rootDir}/generated/contracts/openapi.types.g.ts`;

const rootDirUrl = Bun.pathToFileURL(
  rootDir.endsWith("/") || rootDir.endsWith("\\") ? rootDir : `${rootDir}/`,
);

function isAbsolutePath(path: string): boolean {
  return path.startsWith("/") || /^[a-zA-Z]:[\\/]/.test(path);
}

function resolveFromRoot(path: string): string {
  if (isAbsolutePath(path)) {
    return path;
  }
  return Bun.fileURLToPath(new URL(path, rootDirUrl));
}

const specPath = resolveFromRoot(specPathInput);
const outPath = resolveFromRoot(outPathInput);

const fileCache = new Map<string, unknown>();

function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function dirname(filePath: string): string {
  const slash = Math.max(filePath.lastIndexOf("/"), filePath.lastIndexOf("\\"));
  return slash === -1 ? "." : filePath.slice(0, slash);
}

function sanitizeTypeName(name: string): string {
  const clean = name.replace(/[^a-zA-Z0-9_]/g, "_");
  if (!clean) {
    return "AnonymousSchema";
  }
  if (/^[0-9]/.test(clean)) {
    return `Schema_${clean}`;
  }
  return clean;
}

function formatPropertyKey(key: string): string {
  return /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(key) ? key : JSON.stringify(key);
}

function toTsLiteral(value: unknown): string {
  if (value === null) return "null";
  if (typeof value === "string") return JSON.stringify(value);
  if (typeof value === "number" || typeof value === "boolean")
    return String(value);
  return "unknown";
}

function mapJsonType(typeName: string): string {
  switch (typeName) {
    case "string":
      return "string";
    case "integer":
    case "number":
      return "number";
    case "boolean":
      return "boolean";
    case "null":
      return "null";
    case "object":
      return "Record<string, unknown>";
    case "array":
      return "unknown[]";
    default:
      return "unknown";
  }
}

function withNullable(typeExpr: string, schema: JsonObject): string {
  if (schema.nullable === true && !typeExpr.includes("null")) {
    return `${typeExpr} | null`;
  }
  return typeExpr;
}

function indent(text: string, size = 2): string {
  const prefix = " ".repeat(size);
  return text
    .split("\n")
    .map((line) => (line ? `${prefix}${line}` : line))
    .join("\n");
}

function resolveJsonPointer(doc: unknown, pointer: string): unknown {
  if (!pointer || pointer === "/") {
    return doc;
  }

  if (!pointer.startsWith("/")) {
    fail(`Unsupported JSON pointer: #${pointer}`);
  }

  const segments = pointer
    .slice(1)
    .split("/")
    .map((segment) => segment.replace(/~1/g, "/").replace(/~0/g, "~"));

  let current: unknown = doc;
  for (const segment of segments) {
    if (Array.isArray(current)) {
      const index = Number(segment);
      current = current[index];
      continue;
    }
    if (!isObject(current)) {
      fail(`Could not resolve JSON pointer #${pointer}`);
    }
    current = current[segment];
  }

  return current;
}

async function parseYamlFile(filePath: string): Promise<unknown> {
  const cached = fileCache.get(filePath);
  if (cached !== undefined) {
    return cached;
  }

  const file = Bun.file(filePath);
  if (!(await file.exists())) {
    fail(`Referenced YAML file not found: ${filePath}`);
  }

  const parsed = YAML.parse(await file.text());
  fileCache.set(filePath, parsed);
  return parsed;
}

async function resolveRef(ref: string, fromFile: string): Promise<ResolvedRef> {
  const [rawFilePart, rawPointerPart] = ref.split("#", 2);
  const filePart = rawFilePart ?? "";
  const pointerPart = rawPointerPart ?? "";

  const resolvedFilePath = filePart
    ? Bun.resolveSync(filePart, dirname(fromFile))
    : fromFile;

  const doc = await parseYamlFile(resolvedFilePath);
  const schema = pointerPart
    ? resolveJsonPointer(
        doc,
        pointerPart.startsWith("/") ? pointerPart : `/${pointerPart}`,
      )
    : doc;

  return {
    filePath: resolvedFilePath,
    targetKey: `${resolvedFilePath}#${pointerPart}`,
    schema,
  };
}

async function derefValue(
  value: unknown,
  fromFile: string,
  seen = new Set<string>(),
): Promise<{ value: unknown; filePath: string }> {
  if (!isObject(value) || typeof value.$ref !== "string") {
    return { value, filePath: fromFile };
  }

  const resolved = await resolveRef(value.$ref, fromFile);
  if (seen.has(resolved.targetKey)) {
    return { value: resolved.schema, filePath: resolved.filePath };
  }

  const nextSeen = new Set(seen);
  nextSeen.add(resolved.targetKey);
  return derefValue(resolved.schema, resolved.filePath, nextSeen);
}

async function schemaToType(
  schema: unknown,
  fromFile: string,
  componentByTarget: Map<string, string>,
  stack = new Set<string>(),
): Promise<string> {
  if (!isObject(schema)) {
    return "unknown";
  }

  if (typeof schema.$ref === "string") {
    const resolved = await resolveRef(schema.$ref, fromFile);

    const mappedComponent = componentByTarget.get(resolved.targetKey);
    if (mappedComponent) {
      return `Schemas["${mappedComponent}"]`;
    }

    if (stack.has(resolved.targetKey)) {
      return "unknown";
    }

    const nextStack = new Set(stack);
    nextStack.add(resolved.targetKey);
    return schemaToType(
      resolved.schema,
      resolved.filePath,
      componentByTarget,
      nextStack,
    );
  }

  if (Array.isArray(schema.enum) && schema.enum.length > 0) {
    return withNullable(schema.enum.map(toTsLiteral).join(" | "), schema);
  }

  if (Object.hasOwn(schema, "const")) {
    return withNullable(toTsLiteral(schema.const), schema);
  }

  if (Array.isArray(schema.oneOf) && schema.oneOf.length > 0) {
    const variants = await Promise.all(
      schema.oneOf.map((entry) =>
        schemaToType(entry, fromFile, componentByTarget, stack),
      ),
    );
    return withNullable(variants.join(" | "), schema);
  }

  if (Array.isArray(schema.anyOf) && schema.anyOf.length > 0) {
    const variants = await Promise.all(
      schema.anyOf.map((entry) =>
        schemaToType(entry, fromFile, componentByTarget, stack),
      ),
    );
    return withNullable(variants.join(" | "), schema);
  }

  const compositionParts: string[] = [];
  if (Array.isArray(schema.allOf) && schema.allOf.length > 0) {
    const meaningful = schema.allOf.filter(
      (entry) =>
        isObject(entry) &&
        !Object.hasOwn(entry, "if") &&
        !Object.hasOwn(entry, "then") &&
        !Object.hasOwn(entry, "else"),
    );

    if (meaningful.length > 0) {
      const converted = await Promise.all(
        meaningful.map((entry) =>
          schemaToType(entry, fromFile, componentByTarget, stack),
        ),
      );
      compositionParts.push(...converted);
    }
  }

  let baseType = "unknown";

  if (Array.isArray(schema.type)) {
    baseType = schema.type
      .map((entry) => mapJsonType(String(entry)))
      .join(" | ");
  } else if (schema.type === "array") {
    const itemsType = await schemaToType(
      schema.items ?? {},
      fromFile,
      componentByTarget,
      stack,
    );
    baseType = `(${itemsType})[]`;
  } else if (
    schema.type === "object" ||
    isObject(schema.properties) ||
    Object.hasOwn(schema, "additionalProperties")
  ) {
    const required = new Set<string>(
      Array.isArray(schema.required)
        ? schema.required.filter(
            (item): item is string => typeof item === "string",
          )
        : [],
    );

    const props = isObject(schema.properties)
      ? Object.entries(schema.properties)
      : [];
    const lines: string[] = [];

    for (const [propName, propSchema] of props) {
      const propType = await schemaToType(
        propSchema,
        fromFile,
        componentByTarget,
        stack,
      );
      const optional = required.has(propName) ? "" : "?";
      lines.push(`${formatPropertyKey(propName)}${optional}: ${propType};`);
    }

    if (schema.additionalProperties === true) {
      lines.push("[key: string]: unknown;");
    } else if (isObject(schema.additionalProperties)) {
      const additionalType = await schemaToType(
        schema.additionalProperties,
        fromFile,
        componentByTarget,
        stack,
      );
      lines.push(`[key: string]: ${additionalType};`);
    }

    if (lines.length === 0) {
      baseType =
        schema.additionalProperties === false
          ? "Record<string, never>"
          : "Record<string, unknown>";
    } else {
      baseType = `\n{\n${indent(lines.join("\n"), 2)}\n}`;
      baseType = baseType.trim();
    }
  } else if (typeof schema.type === "string") {
    baseType = mapJsonType(schema.type);
  }

  if (compositionParts.length > 0) {
    compositionParts.unshift(baseType);
    baseType = compositionParts.join(" & ");
  }

  return withNullable(baseType, schema);
}

function readJsonContentSchema(container: JsonObject): unknown {
  if (!isObject(container.content)) {
    return undefined;
  }

  if (isObject(container.content["application/json"])) {
    const mediaType = container.content["application/json"];
    return mediaType.schema;
  }

  const first = Object.values(container.content).find((entry) =>
    isObject(entry),
  );
  if (isObject(first)) {
    return first.schema;
  }

  return undefined;
}

async function buildParamsType(
  operation: JsonObject,
  fromFile: string,
  componentByTarget: Map<string, string>,
): Promise<string> {
  if (
    !Array.isArray(operation.parameters) ||
    operation.parameters.length === 0
  ) {
    return "never";
  }

  const lines: string[] = [];

  for (const rawParam of operation.parameters) {
    const { value: paramValue, filePath: paramFile } = await derefValue(
      rawParam,
      fromFile,
    );
    if (!isObject(paramValue) || typeof paramValue.name !== "string") {
      continue;
    }

    const paramType = await schemaToType(
      paramValue.schema ?? {},
      paramFile,
      componentByTarget,
    );
    const optional = paramValue.required === true ? "" : "?";
    lines.push(
      `${formatPropertyKey(paramValue.name)}${optional}: ${paramType};`,
    );
  }

  if (lines.length === 0) {
    return "never";
  }

  return `{\n${indent(lines.join("\n"), 2)}\n}`;
}

async function buildRequestBodyType(
  operation: JsonObject,
  fromFile: string,
  componentByTarget: Map<string, string>,
): Promise<string> {
  if (!operation.requestBody) {
    return "never";
  }

  const { value: bodyValue, filePath: bodyFile } = await derefValue(
    operation.requestBody,
    fromFile,
  );
  if (!isObject(bodyValue)) {
    return "unknown";
  }

  const schema = readJsonContentSchema(bodyValue);
  if (schema === undefined) {
    return "unknown";
  }

  const bodyType = await schemaToType(schema, bodyFile, componentByTarget);
  return bodyValue.required === true ? bodyType : `${bodyType} | undefined`;
}

async function buildResponsesType(
  operation: JsonObject,
  fromFile: string,
  componentByTarget: Map<string, string>,
): Promise<string> {
  if (!isObject(operation.responses)) {
    return "Record<string, never>";
  }

  const lines: string[] = [];

  for (const [statusCode, responseLike] of Object.entries(
    operation.responses,
  )) {
    const { value: responseValue, filePath: responseFile } = await derefValue(
      responseLike,
      fromFile,
    );
    if (!isObject(responseValue)) {
      lines.push(`${JSON.stringify(statusCode)}: unknown;`);
      continue;
    }

    const schema = readJsonContentSchema(responseValue);
    const responseType =
      schema === undefined
        ? "unknown"
        : await schemaToType(schema, responseFile, componentByTarget);

    lines.push(`${JSON.stringify(statusCode)}: ${responseType};`);
  }

  if (lines.length === 0) {
    return "Record<string, never>";
  }

  return `{\n${indent(lines.join("\n"), 2)}\n}`;
}

function toFileStem(typeName: string): string {
  const safe = sanitizeTypeName(typeName);
  return safe.length > 0 ? safe[0].toLowerCase() + safe.slice(1) : safe;
}

function normalizeSchemaReferences(typeExpr: string): {
  text: string;
  refs: Set<string>;
} {
  const refs = new Set<string>();
  const text = typeExpr.replace(/Schemas\["([^"]+)"\]/g, (_match, refName) => {
    const safeRefName = sanitizeTypeName(String(refName));
    refs.add(safeRefName);
    return safeRefName;
  });
  return { text, refs };
}

function generatedHeader(sourcePath: string): string {
  return `/* eslint-disable */
/**
 * This file is generated by scripts/contracts/generate-types.ts
 * Source: ${sourcePath}
 */
`;
}

function buildTypeFileContent(
  typeName: string,
  typeExpr: string,
  sourcePath: string,
): string {
  const normalized = normalizeSchemaReferences(typeExpr);
  const imports = [...normalized.refs]
    .filter((ref) => ref !== typeName)
    .sort()
    .map(
      (ref) => `import type { ${ref} } from "./${toFileStem(ref)}.g";`,
    );

  const importBlock = imports.length > 0 ? `${imports.join("\n")}\n\n` : "";
  return `${generatedHeader(sourcePath)}
${importBlock}export type ${typeName} = ${normalized.text};
`;
}

async function main(): Promise<void> {
  const specFile = Bun.file(specPath);
  if (!(await specFile.exists())) {
    fail(`OpenAPI spec not found: ${specPath}`);
  }

  const specData = YAML.parse(await specFile.text());
  if (!isObject(specData)) {
    fail(`Invalid OpenAPI document: expected object in ${specPath}`);
  }

  const components = isObject(specData.components) ? specData.components : {};
  const rawSchemas = isObject(components.schemas) ? components.schemas : {};

  const componentNames = Object.keys(rawSchemas).sort();
  const componentByTarget = new Map<string, string>();
  const componentTypeNames = new Set<string>();

  for (const componentName of componentNames) {
    const typeName = sanitizeTypeName(componentName);
    componentTypeNames.add(typeName);

    const internalPointerKey = `${specPath}#/components/schemas/${componentName}`;
    componentByTarget.set(internalPointerKey, typeName);

    const schemaValue = rawSchemas[componentName];
    if (isObject(schemaValue) && typeof schemaValue.$ref === "string") {
      const resolved = await resolveRef(schemaValue.$ref, specPath);
      componentByTarget.set(resolved.targetKey, typeName);
    }
  }

  const generatedTypes: Array<{
    schemaName: string;
    typeName: string;
    typeExpr: string;
  }> = [];

  for (const componentName of componentNames) {
    const typeName = sanitizeTypeName(componentName);
    const schemaValue = rawSchemas[componentName];
    let typeExpr: string;

    if (isObject(schemaValue) && typeof schemaValue.$ref === "string") {
      const resolved = await resolveRef(schemaValue.$ref, specPath);
      const initialStack = new Set<string>([resolved.targetKey]);
      typeExpr = await schemaToType(
        resolved.schema,
        resolved.filePath,
        componentByTarget,
        initialStack,
      );
    } else {
      typeExpr = await schemaToType(schemaValue, specPath, componentByTarget);
    }

    generatedTypes.push({
      schemaName: componentName,
      typeName,
      typeExpr,
    });
  }

  const methods = [
    "get",
    "put",
    "post",
    "delete",
    "options",
    "head",
    "patch",
    "trace",
  ] as const;
  const rawPaths = isObject(specData.paths) ? specData.paths : {};
  const pathBlocks: string[] = [];

  for (const [pathKey, rawPathItem] of Object.entries(rawPaths)) {
    if (!isObject(rawPathItem)) {
      continue;
    }

    const methodBlocks: string[] = [];

    for (const method of methods) {
      const maybeOperation = rawPathItem[method];
      if (!isObject(maybeOperation)) {
        continue;
      }

      const operation = maybeOperation;
      const operationId =
        typeof operation.operationId === "string"
          ? operation.operationId
          : `${method}_${pathKey}`;
      const paramsType = await buildParamsType(
        operation,
        specPath,
        componentByTarget,
      );
      const requestBodyType = await buildRequestBodyType(
        operation,
        specPath,
        componentByTarget,
      );
      const responsesType = await buildResponsesType(
        operation,
        specPath,
        componentByTarget,
      );

      methodBlocks.push(
        `${method}: {\n${indent(
          [
            `operationId: ${JSON.stringify(operationId)};`,
            `params: ${paramsType};`,
            `requestBody: ${requestBodyType};`,
            `responses: ${responsesType};`,
          ].join("\n"),
          2,
        )}\n};`,
      );
    }

    if (methodBlocks.length === 0) {
      continue;
    }

    pathBlocks.push(
      `${JSON.stringify(pathKey)}: {\n${indent(methodBlocks.join("\n"), 2)}\n};`,
    );
  }

  const outputRootDir = dirname(outPath);
  const openApiDir = `${outputRootDir}/openAPI`;
  const typesDir = `${openApiDir}/types`;
  const interfacesDir = `${openApiDir}/interfaces`;
  const legacyOutputPath = `${rootDir}/src/contracts/openapi.types.ts`;

  await $`rm -rf ${openApiDir}`;
  await $`rm -f ${legacyOutputPath}`;
  await $`mkdir -p ${typesDir}`;
  await $`mkdir -p ${interfacesDir}`;
  await $`mkdir -p ${outputRootDir}`;

  for (const typeDef of generatedTypes) {
    const filePath = `${typesDir}/${toFileStem(typeDef.typeName)}.g.ts`;
    const content = buildTypeFileContent(typeDef.typeName, typeDef.typeExpr, specPath);
    await Bun.write(filePath, content);
  }

  const typeIndexContent = `${generatedHeader(specPath)}
${generatedTypes
  .map((typeDef) => `export * from "./${toFileStem(typeDef.typeName)}.g";`)
  .join("\n")}
`;
  await Bun.write(`${typesDir}/index.g.ts`, typeIndexContent);

  const schemaImports = generatedTypes
    .map(
      (typeDef) =>
        `import type { ${typeDef.typeName} } from "../types/${toFileStem(typeDef.typeName)}.g";`,
    )
    .join("\n");
  const schemaMapLines = generatedTypes.map(
    (typeDef) => `${JSON.stringify(typeDef.schemaName)}: ${typeDef.typeName};`,
  );
  const schemasInterfaceContent = `${generatedHeader(specPath)}
${schemaImports}

export interface Schemas {
${indent(schemaMapLines.join("\n"), 2)}
}
`;
  await Bun.write(`${interfacesDir}/Schemas.g.ts`, schemasInterfaceContent);

  const rawPathsInterface = `{
${indent(pathBlocks.join("\n"), 2)}
}`;
  const normalizedPaths = normalizeSchemaReferences(rawPathsInterface);
  const pathImports = [...normalizedPaths.refs]
    .filter((typeName) => componentTypeNames.has(typeName))
    .sort()
    .map(
      (typeName) =>
        `import type { ${typeName} } from "../types/${toFileStem(typeName)}.g";`,
    )
    .join("\n");
  const pathsInterfaceContent = `${generatedHeader(specPath)}
${pathImports}

export interface Paths ${normalizedPaths.text}
`;
  await Bun.write(`${interfacesDir}/Paths.g.ts`, pathsInterfaceContent);

  const interfacesIndexContent = `${generatedHeader(specPath)}
export * from "./Schemas.g";
export * from "./Paths.g";
`;
  await Bun.write(`${interfacesDir}/index.g.ts`, interfacesIndexContent);

  const aggregateExports = [
    `export * from "./openAPI/types/index.g";`,
    `export * from "./openAPI/interfaces/index.g";`,
  ];
  const aggregateContent = `${generatedHeader(specPath)}
${aggregateExports.join("\n")}
`;
  await Bun.write(outPath, aggregateContent);

  console.log(`Generated contract typings at: ${outputRootDir}`);
}

await main();
