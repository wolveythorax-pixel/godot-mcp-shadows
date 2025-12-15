#!/usr/bin/env -S godot --headless --script
extends SceneTree

# Scene validation script for Shadows of the Moth
# Usage: godot --headless --script validate_scene.gd <scene_path> [expected_structure.json]

var validation_errors: Array = []
var validation_warnings: Array = []

func _init():
    var args = OS.get_cmdline_args()

    # Find the script argument
    var script_index = args.find("--script")
    if script_index == -1:
        printerr("Could not find --script argument")
        quit(1)

    var scene_path_index = script_index + 2
    if args.size() <= scene_path_index:
        print("Usage: godot --headless --script validate_scene.gd <scene_path> [expected_structure.json]")
        quit(1)

    var scene_path = args[scene_path_index]
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    print("=" .repeat(60))
    print("Scene Validation: " + scene_path)
    print("=" .repeat(60))

    # Check if scene exists
    if not FileAccess.file_exists(scene_path):
        printerr("Scene file not found: " + scene_path)
        quit(1)

    # Load and validate the scene
    var scene = load(scene_path)
    if not scene:
        printerr("Failed to load scene: " + scene_path)
        quit(1)

    var root = scene.instantiate()
    if not root:
        printerr("Failed to instantiate scene")
        quit(1)

    # Run validations
    validate_node_ownership(root, root)
    validate_node_names(root)
    validate_node_types(root)
    validate_required_nodes(root, scene_path)

    # Check for expected structure if provided
    var structure_path_index = script_index + 3
    if args.size() > structure_path_index:
        var structure_path = args[structure_path_index]
        validate_expected_structure(root, structure_path)

    # Print results
    print("")
    print("-" .repeat(60))
    print("Validation Results")
    print("-" .repeat(60))

    if validation_errors.size() > 0:
        print("\nERRORS (" + str(validation_errors.size()) + "):")
        for error in validation_errors:
            printerr("  [ERROR] " + error)

    if validation_warnings.size() > 0:
        print("\nWARNINGS (" + str(validation_warnings.size()) + "):")
        for warning in validation_warnings:
            print("  [WARN] " + warning)

    if validation_errors.size() == 0 and validation_warnings.size() == 0:
        print("\n[OK] All validations passed!")

    print("")
    print("Summary: " + str(validation_errors.size()) + " errors, " + str(validation_warnings.size()) + " warnings")

    # Cleanup
    root.queue_free()

    # Exit with error code if there were errors
    if validation_errors.size() > 0:
        quit(1)
    else:
        quit(0)

func validate_node_ownership(node: Node, owner: Node, path: String = ""):
    var current_path = path + "/" + node.name if path else node.name

    # Root node should be its own owner (or null)
    if node == owner:
        pass  # Root is fine
    elif node.owner != owner:
        validation_errors.append("Node '" + current_path + "' has incorrect owner (expected: " + owner.name + ")")

    for child in node.get_children():
        validate_node_ownership(child, owner, current_path)

func validate_node_names(node: Node, path: String = ""):
    var current_path = path + "/" + node.name if path else node.name

    # Check for empty names
    if node.name.is_empty():
        validation_errors.append("Node at '" + path + "' has empty name")

    # Check for problematic characters in names
    var problematic_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
    for char in problematic_chars:
        if node.name.contains(char):
            validation_warnings.append("Node '" + current_path + "' contains problematic character: " + char)

    # Check for duplicate sibling names
    if node.get_parent():
        var sibling_names = []
        for sibling in node.get_parent().get_children():
            if sibling.name in sibling_names:
                validation_errors.append("Duplicate node name '" + sibling.name + "' under " + node.get_parent().name)
            sibling_names.append(sibling.name)

    for child in node.get_children():
        validate_node_names(child, current_path)

func validate_node_types(node: Node, path: String = ""):
    var current_path = path + "/" + node.name if path else node.name

    # Check CollisionShape3D has a shape
    if node is CollisionShape3D:
        if not node.shape:
            validation_warnings.append("CollisionShape3D '" + current_path + "' has no shape assigned")

    # Check MeshInstance3D has a mesh
    if node is MeshInstance3D:
        if not node.mesh:
            validation_warnings.append("MeshInstance3D '" + current_path + "' has no mesh assigned")

    # Check Camera3D settings
    if node is Camera3D:
        if node.fov < 30 or node.fov > 120:
            validation_warnings.append("Camera3D '" + current_path + "' has unusual FOV: " + str(node.fov))

    # Check for orphaned physics bodies
    if node is PhysicsBody3D:
        var has_collision = false
        for child in node.get_children():
            if child is CollisionShape3D:
                has_collision = true
                break
        if not has_collision:
            validation_warnings.append("PhysicsBody3D '" + current_path + "' has no CollisionShape3D child")

    for child in node.get_children():
        validate_node_types(child, current_path)

func validate_required_nodes(root: Node, scene_path: String):
    # Scene-specific validations based on path

    if scene_path.contains("Player"):
        # Player scene requirements
        var required = ["CollisionShape3D", "Camera3D"]
        for req in required:
            if not find_node_by_type(root, req):
                validation_warnings.append("Player scene missing recommended node: " + req)

    elif scene_path.contains("NPC") or scene_path.contains("npc"):
        # NPC scene requirements
        var has_perception = root.get_node_or_null("Perception") != null
        if not has_perception:
            validation_warnings.append("NPC scene missing Perception node")

    elif scene_path.contains("Main"):
        # Main scene requirements
        var required_systems = ["WorldSystems", "AISystems"]
        for sys in required_systems:
            if not root.get_node_or_null(sys):
                validation_warnings.append("Main scene missing system: " + sys)

    elif scene_path.contains("UI") or scene_path.contains("HUD"):
        # UI scene requirements
        if not root is CanvasLayer:
            validation_warnings.append("UI scene root should be CanvasLayer")

func find_node_by_type(node: Node, type_name: String) -> Node:
    if node.get_class() == type_name:
        return node

    for child in node.get_children():
        var found = find_node_by_type(child, type_name)
        if found:
            return found

    return null

func validate_expected_structure(root: Node, structure_path: String):
    if not structure_path.begins_with("res://"):
        structure_path = "res://" + structure_path

    if not FileAccess.file_exists(structure_path):
        validation_warnings.append("Expected structure file not found: " + structure_path)
        return

    var file = FileAccess.open(structure_path, FileAccess.READ)
    if not file:
        validation_warnings.append("Could not open structure file: " + structure_path)
        return

    var json_text = file.get_as_text()
    file.close()

    var json = JSON.new()
    var error = json.parse(json_text)
    if error != OK:
        validation_warnings.append("Failed to parse structure JSON: " + json.get_error_message())
        return

    var expected = json.get_data()

    if expected.has("root_node"):
        validate_node_structure(root, expected.root_node, "")

func validate_node_structure(node: Node, expected: Dictionary, path: String):
    var current_path = path + "/" + node.name if path else node.name

    # Check type
    if expected.has("type"):
        if node.get_class() != expected.type:
            validation_errors.append("Node '" + current_path + "' expected type '" + expected.type + "', got '" + node.get_class() + "'")

    # Check name
    if expected.has("name"):
        if node.name != expected.name:
            validation_errors.append("Node at '" + current_path + "' expected name '" + expected.name + "', got '" + node.name + "'")

    # Check children
    if expected.has("children") and expected.children is Array:
        for child_expected in expected.children:
            if child_expected.has("name"):
                var child_node = node.get_node_or_null(child_expected.name)
                if child_node:
                    validate_node_structure(child_node, child_expected, current_path)
                else:
                    validation_errors.append("Missing expected child '" + child_expected.name + "' under '" + current_path + "'")
