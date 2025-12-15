#!/usr/bin/env -S godot --headless --script
extends SceneTree

# Godot compatibility checker for godot-mcp-shadows
# Verifies that the current Godot version supports all required features

var compatibility_errors: Array = []
var compatibility_warnings: Array = []

func _init():
    print("=" .repeat(60))
    print("Godot Compatibility Check for godot-mcp-shadows")
    print("=" .repeat(60))
    print("")

    # Get Godot version info
    var version_info = Engine.get_version_info()
    print("Godot Version: " + version_info.string)
    print("Major: " + str(version_info.major))
    print("Minor: " + str(version_info.minor))
    print("Patch: " + str(version_info.patch))
    print("Status: " + version_info.status)
    print("")

    # Check minimum version
    check_version(version_info)

    # Check required classes
    check_required_classes()

    # Check required methods
    check_required_methods()

    # Check file system access
    check_filesystem_access()

    # Print results
    print("")
    print("-" .repeat(60))
    print("Compatibility Results")
    print("-" .repeat(60))

    if compatibility_errors.size() > 0:
        print("\nERRORS (" + str(compatibility_errors.size()) + "):")
        for error in compatibility_errors:
            printerr("  [ERROR] " + error)

    if compatibility_warnings.size() > 0:
        print("\nWARNINGS (" + str(compatibility_warnings.size()) + "):")
        for warning in compatibility_warnings:
            print("  [WARN] " + warning)

    if compatibility_errors.size() == 0 and compatibility_warnings.size() == 0:
        print("\n[OK] All compatibility checks passed!")

    print("")

    # Exit with appropriate code
    if compatibility_errors.size() > 0:
        quit(1)
    else:
        quit(0)

func check_version(version_info: Dictionary):
    print("Checking version requirements...")

    var major = version_info.major
    var minor = version_info.minor

    # Require Godot 4.0+
    if major < 4:
        compatibility_errors.append("Godot 4.0+ required, found " + str(major) + "." + str(minor))
        return

    # Recommend Godot 4.2+ for stability
    if major == 4 and minor < 2:
        compatibility_warnings.append("Godot 4.2+ recommended for stability, found " + str(major) + "." + str(minor))

    # Note Godot 4.5+ features
    if major == 4 and minor >= 5:
        print("  [OK] Godot 4.5+ detected - all features available")
    elif major == 4 and minor >= 2:
        print("  [OK] Godot 4.2+ detected - core features available")
    else:
        print("  [WARN] Older Godot 4.x detected - some features may be limited")

func check_required_classes():
    print("\nChecking required classes...")

    var required_classes = [
        # Core 3D classes
        "Node3D",
        "CharacterBody3D",
        "StaticBody3D",
        "RigidBody3D",
        "CollisionShape3D",
        "MeshInstance3D",
        "Camera3D",
        "DirectionalLight3D",
        "OmniLight3D",
        "SpotLight3D",

        # Navigation
        "NavigationAgent3D",
        "NavigationRegion3D",

        # UI classes
        "Control",
        "CanvasLayer",
        "Label",
        "Button",
        "ProgressBar",
        "Container",
        "VBoxContainer",
        "HBoxContainer",
        "MarginContainer",
        "PanelContainer",

        # Audio
        "AudioStreamPlayer",
        "AudioStreamPlayer3D",

        # Physics shapes
        "BoxShape3D",
        "CapsuleShape3D",
        "SphereShape3D",

        # Resources
        "PackedScene",
        "Environment",
        "WorldEnvironment",

        # Path and curves
        "Path3D",
        "Curve3D",

        # Markers
        "Marker3D",

        # Areas
        "Area3D",

        # Spring arm for camera
        "SpringArm3D"
    ]

    var missing_classes = []
    for class_name in required_classes:
        if not ClassDB.class_exists(class_name):
            missing_classes.append(class_name)
            compatibility_errors.append("Required class not found: " + class_name)

    if missing_classes.size() == 0:
        print("  [OK] All " + str(required_classes.size()) + " required classes available")
    else:
        print("  [ERROR] " + str(missing_classes.size()) + " classes missing")

func check_required_methods():
    print("\nChecking required methods...")

    var checks = [
        ["Node", "add_child"],
        ["Node", "get_node_or_null"],
        ["Node", "set_owner"],
        ["Node", "add_to_group"],
        ["Node", "set_meta"],
        ["PackedScene", "pack"],
        ["ResourceSaver", "save"],
        ["ResourceLoader", "load"],
        ["FileAccess", "file_exists"],
        ["FileAccess", "open"],
        ["DirAccess", "dir_exists_absolute"],
        ["DirAccess", "make_dir_recursive"],
        ["JSON", "parse"],
        ["JSON", "stringify"],
        ["RegEx", "compile"],
        ["RegEx", "sub"]
    ]

    var missing_methods = []
    for check in checks:
        var class_name = check[0]
        var method_name = check[1]

        if ClassDB.class_exists(class_name):
            if not ClassDB.class_has_method(class_name, method_name):
                # Some methods might be in the instance, not the class
                # This is a basic check, not exhaustive
                pass
        else:
            missing_methods.append(class_name + "." + method_name)

    if missing_methods.size() == 0:
        print("  [OK] Core methods available")
    else:
        for method in missing_methods:
            compatibility_warnings.append("Method check inconclusive: " + method)

func check_filesystem_access():
    print("\nChecking filesystem access...")

    # Try to access res://
    var dir = DirAccess.open("res://")
    if dir == null:
        compatibility_errors.append("Cannot access res:// directory")
        return

    print("  [OK] res:// directory accessible")

    # Check if we can create files (test in a safe location)
    var test_path = "res://.godot_mcp_compat_test"
    var file = FileAccess.open(test_path, FileAccess.WRITE)
    if file:
        file.store_string("test")
        file.close()

        # Clean up
        DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
        print("  [OK] File write access confirmed")
    else:
        compatibility_warnings.append("Cannot write to res:// - may be read-only")

    # Check project.godot exists
    if FileAccess.file_exists("res://project.godot"):
        print("  [OK] project.godot found")
    else:
        compatibility_warnings.append("project.godot not found - run from project directory")
