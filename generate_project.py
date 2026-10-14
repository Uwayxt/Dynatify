#!/usr/bin/env python3
"""Generate project.pbxproj for Dynatify — Xcode 27 / objectVersion 90 • by @uwayxt"""
import hashlib, os

def xid(seed):
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return h[:24]

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_DIR  = os.path.join(BASE_DIR, "MelodyIsland", "MelodyIsland")
PROJ_DIR = os.path.join(BASE_DIR, "MelodyIsland", "MelodyIsland.xcodeproj")

SOURCE_FILES = []
RESOURCE_FILES = []

for dp, _, fnames in os.walk(SRC_DIR):
    for f in sorted(fnames):
        rel = os.path.relpath(os.path.join(dp, f), SRC_DIR).replace("\\", "/")
        if f.endswith(".swift"):
            SOURCE_FILES.append(rel)
        elif f.endswith(".icns") or f.endswith(".png") or f.endswith(".json"):
            RESOURCE_FILES.append(rel)

SOURCE_FILES.sort()
RESOURCE_FILES.sort()
ALL_FILES = sorted(SOURCE_FILES + RESOURCE_FILES)
print("Source Files:", SOURCE_FILES)
print("Resource Files:", RESOURCE_FILES)

PROJ_ID       = xid("PROJECT")
MAIN_GRP      = xid("MAIN_GROUP")
PROD_GRP      = xid("PRODUCTS_GROUP")
SRC_GRP       = xid("SRC_GROUP")
APP_REF       = xid("APP_FILE_REF")
SRC_PHASE     = xid("SOURCES_PHASE")
FW_PHASE      = xid("FRAMEWORKS_PHASE")
RES_PHASE     = xid("RESOURCES_PHASE")
TARGET        = xid("TARGET")
CFG_LIST_PROJ = xid("CONFIG_LIST")
CFG_LIST_TGT  = xid("TARGET_CONFIG_LIST")
PROJ_DBG      = xid("PROJ_DEBUG")
PROJ_REL      = xid("PROJ_RELEASE")
TGT_DBG       = xid("DEBUG_CONFIG")
TGT_REL       = xid("RELEASE_CONFIG")

file_refs   = {p: xid("FR_" + p) for p in ALL_FILES}
build_files = {p: xid("BF_" + p) for p in ALL_FILES}

L = []
def w(s=""): L.append(s)

def build_tree(files):
    tree = {}
    for path in files:
        parts = path.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = file_refs[path]
    return tree

def emit_groups(tree, prefix):
    for name, val in sorted(tree.items()):
        if isinstance(val, dict):
            gid = xid("GRP_" + prefix + "_" + name)
            children = []
            for cname, cval in sorted(val.items()):
                if isinstance(cval, dict):
                    children.append(xid("GRP_" + prefix + "_" + name + "_" + cname))
                else:
                    children.append(cval)
            w("\t\t" + gid + " /* " + name + " */ = {")
            w("\t\t\tisa = PBXGroup;")
            w("\t\t\tchildren = (")
            for c in children:
                w("\t\t\t\t" + c + ",")
            w("\t\t\t);")
            w("\t\t\tname = " + name + ";")
            w("\t\t\tpath = " + name + ";")
            w('\t\t\tsourceTree = "<group>";')
            w("\t\t};")
            emit_groups(val, prefix + "_" + name)

tree = build_tree(ALL_FILES)
top_children = []
for name, val in sorted(tree.items()):
    if isinstance(val, dict):
        top_children.append(xid("GRP_SRC_" + name))
    else:
        top_children.append(val)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 90;")
w("\tobjects = {")
w()
w("/* Begin PBXBuildFile section */")
for p in SOURCE_FILES:
    fname = os.path.basename(p)
    w("\t\t" + build_files[p] + " /* " + fname + " in Sources */ = {isa = PBXBuildFile; fileRef = " + file_refs[p] + " /* " + fname + " */; };")
for p in RESOURCE_FILES:
    fname = os.path.basename(p)
    w("\t\t" + build_files[p] + " /* " + fname + " in Resources */ = {isa = PBXBuildFile; fileRef = " + file_refs[p] + " /* " + fname + " */; };")
w("/* End PBXBuildFile section */")
w()
w("/* Begin PBXFileReference section */")
w("\t\t" + APP_REF + " /* Dynatify.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Dynatify.app; sourceTree = BUILT_PRODUCTS_DIR; };")
for p in ALL_FILES:
    fname = os.path.basename(p)
    if fname.endswith(".swift"):
        ft = "sourcecode.swift"
    elif fname.endswith(".icns"):
        ft = "image.icns"
    elif fname.endswith(".png"):
        ft = "image.png"
    else:
        ft = "text"
    w("\t\t" + file_refs[p] + " /* " + fname + " */ = {isa = PBXFileReference; lastKnownFileType = " + ft + "; path = " + fname + '; sourceTree = "<group>"; };')
w("/* End PBXFileReference section */")
w()
w("/* Begin PBXFrameworksBuildPhase section */")
w("\t\t" + FW_PHASE + " /* Frameworks */ = {")
w("\t\t\tisa = PBXFrameworksBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXFrameworksBuildPhase section */")
w()
w("/* Begin PBXGroup section */")
w("\t\t" + MAIN_GRP + " = {")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w("\t\t\t\t" + SRC_GRP + " /* Dynatify */,")
w("\t\t\t\t" + PROD_GRP + " /* Products */,")
w("\t\t\t);")
w('\t\t\tsourceTree = "<group>";')
w("\t\t};")
w("\t\t" + PROD_GRP + " /* Products */ = {")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
w("\t\t\t\t" + APP_REF + " /* Dynatify.app */,")
w("\t\t\t);")
w("\t\t\tname = Products;")
w('\t\t\tsourceTree = "<group>";')
w("\t\t};")
w("\t\t" + SRC_GRP + " /* Dynatify */ = {")
w("\t\t\tisa = PBXGroup;")
w("\t\t\tchildren = (")
for c in top_children:
    w("\t\t\t\t" + c + ",")
w("\t\t\t);")
w("\t\t\tname = Dynatify;")
w("\t\t\tpath = MelodyIsland;")
w('\t\t\tsourceTree = "<group>";')
w("\t\t};")
emit_groups(tree, "SRC")
w("/* End PBXGroup section */")
w()
w("/* Begin PBXNativeTarget section */")
w("\t\t" + TARGET + " /* Dynatify */ = {")
w("\t\t\tisa = PBXNativeTarget;")
w("\t\t\tbuildConfigurationList = " + CFG_LIST_TGT + " /* Build configuration list for PBXNativeTarget \"Dynatify\" */;")
w("\t\t\tbuildPhases = (")
w("\t\t\t\t" + SRC_PHASE + " /* Sources */,")
w("\t\t\t\t" + FW_PHASE + " /* Frameworks */,")
w("\t\t\t\t" + RES_PHASE + " /* Resources */,")
w("\t\t\t);")
w("\t\t\tbuildRules = (")
w("\t\t\t);")
w("\t\t\tdependencies = (")
w("\t\t\t);")
w("\t\t\tname = Dynatify;")
w("\t\t\tproductName = Dynatify;")
w("\t\t\tproductReference = " + APP_REF + " /* Dynatify.app */;")
w('\t\t\tproductType = "com.apple.product-type.application";')
w("\t\t};")
w("/* End PBXNativeTarget section */")
w()
w("/* Begin PBXProject section */")
w("\t\t" + PROJ_ID + " /* Project object */ = {")
w("\t\t\tisa = PBXProject;")
w("\t\t\tattributes = {")
w("\t\t\t\tBuildIndependentTargetsInParallel = YES;")
w("\t\t\t\tLastSwiftUpdateCheck = 2700;")
w("\t\t\t\tLastUpgradeCheck = 2700;")
w("\t\t\t\tTargetAttributes = {")
w("\t\t\t\t\t" + TARGET + " = {")
w("\t\t\t\t\t\tCreatedOnToolsVersion = 27.0;")
w("\t\t\t\t\t};")
w("\t\t\t\t};")
w("\t\t\t};")
w("\t\t\tbuildConfigurationList = " + CFG_LIST_PROJ + " /* Build configuration list for PBXProject \"Dynatify\" */;")
w('\t\t\tcompatibilityVersion = "Xcode 14.0";')
w("\t\t\tdevelopmentRegion = en;")
w("\t\t\thasScannedForEncodings = 0;")
w("\t\t\tknownRegions = (")
w("\t\t\t\ten,")
w("\t\t\t\tBase,")
w("\t\t\t);")
w("\t\t\tmainGroup = " + MAIN_GRP + ";")
w("\t\t\tproductRefGroup = " + PROD_GRP + " /* Products */;")
w('\t\t\tprojectDirPath = "";')
w('\t\t\tprojectRoot = "";')
w("\t\t\ttargets = (")
w("\t\t\t\t" + TARGET + " /* Dynatify */,")
w("\t\t\t);")
w("\t\t};")
w("/* End PBXProject section */")
w()
w("/* Begin PBXResourcesBuildPhase section */")
w("\t\t" + RES_PHASE + " /* Resources */ = {")
w("\t\t\tisa = PBXResourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for p in RESOURCE_FILES:
    fname = os.path.basename(p)
    w("\t\t\t\t" + build_files[p] + " /* " + fname + " in Resources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXResourcesBuildPhase section */")
w()
w("/* Begin PBXSourcesBuildPhase section */")
w("\t\t" + SRC_PHASE + " /* Sources */ = {")
w("\t\t\tisa = PBXSourcesBuildPhase;")
w("\t\t\tbuildActionMask = 2147483647;")
w("\t\t\tfiles = (")
for p in SOURCE_FILES:
    fname = os.path.basename(p)
    w("\t\t\t\t" + build_files[p] + " /* " + fname + " in Sources */,")
w("\t\t\t);")
w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t\t};")
w("/* End PBXSourcesBuildPhase section */")
w()
w("/* Begin XCBuildConfiguration section */")

def quote_val(v):
    if v.startswith("'") and v.endswith("'"):
        v = v[1:-1]
    if v.startswith('"') and v.endswith('"'):
        return v
    import re
    if re.match(r"^[a-zA-Z0-9_]+$", v):
        return v
    escaped = v.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'

def cfg_settings(pairs):
    for k, v in pairs:
        w("\t\t\t\t" + k + " = " + quote_val(v) + ";")

# Project Debug
w("\t\t" + PROJ_DBG + " /* Debug */ = {")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
cfg_settings([
    ("ALWAYS_SEARCH_USER_PATHS","NO"),
    ("CLANG_ANALYZER_NONNULL","YES"),
    ("CLANG_CXX_LANGUAGE_STANDARD",'"gnu++20"'),
    ("CLANG_ENABLE_MODULES","YES"),
    ("CLANG_ENABLE_OBJC_ARC","YES"),
    ("CLANG_ENABLE_OBJC_WEAK","YES"),
    ("COPY_PHASE_STRIP","NO"),
    ("DEBUG_INFORMATION_FORMAT","dwarf"),
    ("ENABLE_STRICT_OBJC_MSGSEND","YES"),
    ("ENABLE_TESTABILITY","YES"),
    ("GCC_C_LANGUAGE_STANDARD","gnu17"),
    ("GCC_NO_COMMON_BLOCKS","YES"),
    ("GCC_OPTIMIZATION_LEVEL","0"),
    ("GCC_WARN_64_TO_32_BIT_CONVERSION","YES"),
    ("GCC_WARN_ABOUT_RETURN_TYPE","YES_ERROR"),
    ("GCC_WARN_UNDECLARED_SELECTOR","YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS","YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION","YES"),
    ("GCC_WARN_UNUSED_VARIABLE","YES"),
    ("MACOSX_DEPLOYMENT_TARGET","27.0"),
    ("MTL_ENABLE_DEBUG_INFO","INCLUDE_SOURCE"),
    ("MTL_FAST_MATH","YES"),
    ("ONLY_ACTIVE_ARCH","YES"),
    ("SDKROOT","macosx"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS",'"DEBUG $(inherited)"'),
    ("SWIFT_OPTIMIZATION_LEVEL","'-Onone'"),
])
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

# Project Release
w("\t\t" + PROJ_REL + " /* Release */ = {")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
cfg_settings([
    ("ALWAYS_SEARCH_USER_PATHS","NO"),
    ("CLANG_CXX_LANGUAGE_STANDARD",'"gnu++20"'),
    ("CLANG_ENABLE_MODULES","YES"),
    ("CLANG_ENABLE_OBJC_ARC","YES"),
    ("CLANG_ENABLE_OBJC_WEAK","YES"),
    ("COPY_PHASE_STRIP","NO"),
    ("DEBUG_INFORMATION_FORMAT",'"dwarf-with-dsym"'),
    ("ENABLE_NS_ASSERTIONS","NO"),
    ("ENABLE_STRICT_OBJC_MSGSEND","YES"),
    ("GCC_C_LANGUAGE_STANDARD","gnu17"),
    ("GCC_NO_COMMON_BLOCKS","YES"),
    ("GCC_WARN_64_TO_32_BIT_CONVERSION","YES"),
    ("GCC_WARN_ABOUT_RETURN_TYPE","YES_ERROR"),
    ("GCC_WARN_UNDECLARED_SELECTOR","YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS","YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION","YES"),
    ("GCC_WARN_UNUSED_VARIABLE","YES"),
    ("MACOSX_DEPLOYMENT_TARGET","27.0"),
    ("MTL_FAST_MATH","YES"),
    ("SDKROOT","macosx"),
    ("SWIFT_COMPILATION_MODE","wholemodule"),
    ("VALIDATE_PRODUCT","YES"),
])
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")

# Target Debug
w("\t\t" + TGT_DBG + " /* Debug */ = {")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
cfg_settings([
    ("CODE_SIGN_ENTITLEMENTS","MelodyIsland/Dynatify.entitlements"),
    ("CODE_SIGN_IDENTITY","'-'"),
    ("CODE_SIGN_STYLE","Automatic"),
    ("CODE_SIGNING_REQUIRED","NO"),
    ("COMBINE_HIDPI_IMAGES","YES"),
    ("CURRENT_PROJECT_VERSION","1"),
    ("GENERATE_INFOPLIST_FILE","NO"),
    ("INFOPLIST_FILE","MelodyIsland/Info.plist"),
    ("MACOSX_DEPLOYMENT_TARGET","14.0"),
    ("MARKETING_VERSION","1.0.0"),
    ("PRODUCT_BUNDLE_IDENTIFIER","com.uwayxt.Dynatify"),
    ("PRODUCT_NAME","$(TARGET_NAME)"),
    ("SDKROOT","macosx"),
    ("SWIFT_DEFAULT_ACTOR_ISOLATION","MainActor"),
    ("SWIFT_EMIT_LOC_STRINGS","YES"),
    ("SWIFT_OPTIMIZATION_LEVEL","'-Onone'"),
    ("SWIFT_VERSION","6.0"),
])
w("\t\t\t};")
w("\t\t\tname = Debug;")
w("\t\t};")

# Target Release
w("\t\t" + TGT_REL + " /* Release */ = {")
w("\t\t\tisa = XCBuildConfiguration;")
w("\t\t\tbuildSettings = {")
cfg_settings([
    ("CODE_SIGN_ENTITLEMENTS","MelodyIsland/Dynatify.entitlements"),
    ("CODE_SIGN_IDENTITY","'-'"),
    ("CODE_SIGN_STYLE","Automatic"),
    ("CODE_SIGNING_REQUIRED","NO"),
    ("COMBINE_HIDPI_IMAGES","YES"),
    ("CURRENT_PROJECT_VERSION","1"),
    ("GENERATE_INFOPLIST_FILE","NO"),
    ("INFOPLIST_FILE","MelodyIsland/Info.plist"),
    ("MACOSX_DEPLOYMENT_TARGET","14.0"),
    ("MARKETING_VERSION","1.0.0"),
    ("PRODUCT_BUNDLE_IDENTIFIER","com.uwayxt.Dynatify"),
    ("PRODUCT_NAME","$(TARGET_NAME)"),
    ("SDKROOT","macosx"),
    ("SWIFT_COMPILATION_MODE","wholemodule"),
    ("SWIFT_DEFAULT_ACTOR_ISOLATION","MainActor"),
    ("SWIFT_EMIT_LOC_STRINGS","YES"),
    ("SWIFT_VERSION","6.0"),
])
w("\t\t\t};")
w("\t\t\tname = Release;")
w("\t\t};")
w("/* End XCBuildConfiguration section */")
w()
w("/* Begin XCConfigurationList section */")
w("\t\t" + CFG_LIST_PROJ + ' /* Build configuration list for PBXProject "Dynatify" */ = {')
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w("\t\t\t\t" + PROJ_DBG + " /* Debug */,")
w("\t\t\t\t" + PROJ_REL + " /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w("\t\t" + CFG_LIST_TGT + ' /* Build configuration list for PBXNativeTarget "Dynatify" */ = {')
w("\t\t\tisa = XCConfigurationList;")
w("\t\t\tbuildConfigurations = (")
w("\t\t\t\t" + TGT_DBG + " /* Debug */,")
w("\t\t\t\t" + TGT_REL + " /* Release */,")
w("\t\t\t);")
w("\t\t\tdefaultConfigurationIsVisible = 0;")
w("\t\t\tdefaultConfigurationName = Release;")
w("\t\t};")
w("/* End XCConfigurationList section */")
w()
w("\t};")
w("\trootObject = " + PROJ_ID + " /* Project object */;")
w("}")
w()

pbxproj = "\n".join(L)

out_path = os.path.join(PROJ_DIR, "project.pbxproj")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(pbxproj)

print("Generated:", out_path)
print("TARGET_ID =", TARGET)
print("Lines:", len(L))
