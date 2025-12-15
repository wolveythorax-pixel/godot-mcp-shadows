#!/usr/bin/env -S godot --headless --script
extends SceneTree

# Debug mode flag
var debug_mode = false

func _init():
    var args = OS.get_cmdline_args()
    
    # Check for debug flag
    debug_mode = "--debug-godot" in args
    
    # Find the script argument and determine the positions of operation and params
    var script_index = args.find("--script")
    if script_index == -1:
        log_error("Could not find --script argument")
        quit(1)
    
    # The operation should be 2 positions after the script path (script_index + 1 is the script path itself)
    var operation_index = script_index + 2
    # The params should be 3 positions after the script path
    var params_index = script_index + 3
    
    if args.size() <= params_index:
        log_error("Usage: godot --headless --script godot_operations.gd <operation> <json_params>")
        log_error("Not enough command-line arguments provided.")
        quit(1)
    
    # Log all arguments for debugging
    log_debug("All arguments: " + str(args))
    log_debug("Script index: " + str(script_index))
    log_debug("Operation index: " + str(operation_index))
    log_debug("Params index: " + str(params_index))
    
    var operation = args[operation_index]
    var params_json = args[params_index]
    
    log_info("Operation: " + operation)
    log_debug("Params JSON: " + params_json)
    
    # Parse JSON using Godot 4.x API
    var json = JSON.new()
    var error = json.parse(params_json)
    var params = null
    
    if error == OK:
        params = json.get_data()
    else:
        log_error("Failed to parse JSON parameters: " + params_json)
        log_error("JSON Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
        quit(1)
    
    if not params:
        log_error("Failed to parse JSON parameters: " + params_json)
        quit(1)
    
    log_info("Executing operation: " + operation)
    
    match operation:
        "create_scene":
            create_scene(params)
        "add_node":
            add_node(params)
        "load_sprite":
            load_sprite(params)
        "export_mesh_library":
            export_mesh_library(params)
        "save_scene":
            save_scene(params)
        "get_uid":
            get_uid(params)
        "resave_resources":
            resave_resources(params)
        # Custom operations for Shadows of the Moth
        "create_main_scene":
            create_main_scene(params)
        "create_hud_scene":
            create_hud_scene(params)
        "create_player_scene":
            create_player_scene(params)
        "create_npc_scene":
            create_npc_scene(params)
        "create_test_level":
            create_test_level(params)
        "create_mechanics_test_map":
            create_mechanics_test_map(params)
        # Additional custom operations
        "configure_autoloads":
            configure_autoloads(params)
        "add_patrol_waypoints":
            add_patrol_waypoints(params)
        "setup_system_groups":
            setup_system_groups(params)
        "create_from_template":
            create_from_template(params)
        _:
            log_error("Unknown operation: " + operation)
            quit(1)
    
    quit()

# Logging functions
func log_debug(message):
    if debug_mode:
        print("[DEBUG] " + message)

func log_info(message):
    print("[INFO] " + message)

func log_error(message):
    printerr("[ERROR] " + message)

# Get a script by name or path
func get_script_by_name(name_of_class):
    if debug_mode:
        print("Attempting to get script for class: " + name_of_class)
    
    # Try to load it directly if it's a resource path
    if ResourceLoader.exists(name_of_class, "Script"):
        if debug_mode:
            print("Resource exists, loading directly: " + name_of_class)
        var script = load(name_of_class) as Script
        if script:
            if debug_mode:
                print("Successfully loaded script from path")
            return script
        else:
            printerr("Failed to load script from path: " + name_of_class)
    elif debug_mode:
        print("Resource not found, checking global class registry")
    
    # Search for it in the global class registry if it's a class name
    var global_classes = ProjectSettings.get_global_class_list()
    if debug_mode:
        print("Searching through " + str(global_classes.size()) + " global classes")
    
    for global_class in global_classes:
        var found_name_of_class = global_class["class"]
        var found_path = global_class["path"]
        
        if found_name_of_class == name_of_class:
            if debug_mode:
                print("Found matching class in registry: " + found_name_of_class + " at path: " + found_path)
            var script = load(found_path) as Script
            if script:
                if debug_mode:
                    print("Successfully loaded script from registry")
                return script
            else:
                printerr("Failed to load script from registry path: " + found_path)
                break
    
    printerr("Could not find script for class: " + name_of_class)
    return null

# Instantiate a class by name
func instantiate_class(name_of_class):
    if name_of_class.is_empty():
        printerr("Cannot instantiate class: name is empty")
        return null
    
    var result = null
    if debug_mode:
        print("Attempting to instantiate class: " + name_of_class)
    
    # Check if it's a built-in class
    if ClassDB.class_exists(name_of_class):
        if debug_mode:
            print("Class exists in ClassDB, using ClassDB.instantiate()")
        if ClassDB.can_instantiate(name_of_class):
            result = ClassDB.instantiate(name_of_class)
            if result == null:
                printerr("ClassDB.instantiate() returned null for class: " + name_of_class)
        else:
            printerr("Class exists but cannot be instantiated: " + name_of_class)
            printerr("This may be an abstract class or interface that cannot be directly instantiated")
    else:
        # Try to get the script
        if debug_mode:
            print("Class not found in ClassDB, trying to get script")
        var script = get_script_by_name(name_of_class)
        if script is GDScript:
            if debug_mode:
                print("Found GDScript, creating instance")
            result = script.new()
        else:
            printerr("Failed to get script for class: " + name_of_class)
            return null
    
    if result == null:
        printerr("Failed to instantiate class: " + name_of_class)
    elif debug_mode:
        print("Successfully instantiated class: " + name_of_class + " of type: " + result.get_class())
    
    return result

# Create a new scene with a specified root node type
func create_scene(params):
    print("Creating scene: " + params.scene_path)
    
    # Get project paths and log them for debugging
    var project_res_path = "res://"
    var project_user_path = "user://"
    var global_res_path = ProjectSettings.globalize_path(project_res_path)
    var global_user_path = ProjectSettings.globalize_path(project_user_path)
    
    if debug_mode:
        print("Project paths:")
        print("- res:// path: " + project_res_path)
        print("- user:// path: " + project_user_path)
        print("- Globalized res:// path: " + global_res_path)
        print("- Globalized user:// path: " + global_user_path)
        
        # Print some common environment variables for debugging
        print("Environment variables:")
        var env_vars = ["PATH", "HOME", "USER", "TEMP", "GODOT_PATH"]
        for env_var in env_vars:
            if OS.has_environment(env_var):
                print("  " + env_var + " = " + OS.get_environment(env_var))
    
    # Normalize the scene path
    var full_scene_path = params.scene_path
    if not full_scene_path.begins_with("res://"):
        full_scene_path = "res://" + full_scene_path
    if debug_mode:
        print("Scene path (with res://): " + full_scene_path)
    
    # Convert resource path to an absolute path
    var absolute_scene_path = ProjectSettings.globalize_path(full_scene_path)
    if debug_mode:
        print("Absolute scene path: " + absolute_scene_path)
    
    # Get the scene directory paths
    var scene_dir_res = full_scene_path.get_base_dir()
    var scene_dir_abs = absolute_scene_path.get_base_dir()
    if debug_mode:
        print("Scene directory (resource path): " + scene_dir_res)
        print("Scene directory (absolute path): " + scene_dir_abs)
    
    # Only do extensive testing in debug mode
    if debug_mode:
        # Try to create a simple test file in the project root to verify write access
        var initial_test_file_path = "res://godot_mcp_test_write.tmp"
        var initial_test_file = FileAccess.open(initial_test_file_path, FileAccess.WRITE)
        if initial_test_file:
            initial_test_file.store_string("Test write access")
            initial_test_file.close()
            print("Successfully wrote test file to project root: " + initial_test_file_path)
            
            # Verify the test file exists
            var initial_test_file_exists = FileAccess.file_exists(initial_test_file_path)
            print("Test file exists check: " + str(initial_test_file_exists))
            
            # Clean up the test file
            if initial_test_file_exists:
                var remove_error = DirAccess.remove_absolute(ProjectSettings.globalize_path(initial_test_file_path))
                print("Test file removal result: " + str(remove_error))
        else:
            var write_error = FileAccess.get_open_error()
            printerr("Failed to write test file to project root: " + str(write_error))
            printerr("This indicates a serious permission issue with the project directory")
    
    # Use traditional if-else statement for better compatibility
    var root_node_type = "Node2D"  # Default value
    if params.has("root_node_type"):
        root_node_type = params.root_node_type
    if debug_mode:
        print("Root node type: " + root_node_type)
    
    # Create the root node
    var scene_root = instantiate_class(root_node_type)
    if not scene_root:
        printerr("Failed to instantiate node of type: " + root_node_type)
        printerr("Make sure the class exists and can be instantiated")
        printerr("Check if the class is registered in ClassDB or available as a script")
        quit(1)
    
    scene_root.name = "root"
    if debug_mode:
        print("Root node created with name: " + scene_root.name)
    
    # Set the owner of the root node to itself (important for scene saving)
    scene_root.owner = scene_root
    
    # Pack the scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)
    if debug_mode:
        print("Pack result: " + str(result) + " (OK=" + str(OK) + ")")
    
    if result == OK:
        # Only do extensive testing in debug mode
        if debug_mode:
            # First, let's verify we can write to the project directory
            print("Testing write access to project directory...")
            var test_write_path = "res://test_write_access.tmp"
            var test_write_abs = ProjectSettings.globalize_path(test_write_path)
            var test_file = FileAccess.open(test_write_path, FileAccess.WRITE)
            
            if test_file:
                test_file.store_string("Write test")
                test_file.close()
                print("Successfully wrote test file to project directory")
                
                # Clean up test file
                if FileAccess.file_exists(test_write_path):
                    var remove_error = DirAccess.remove_absolute(test_write_abs)
                    print("Test file removal result: " + str(remove_error))
            else:
                var write_error = FileAccess.get_open_error()
                printerr("Failed to write test file to project directory: " + str(write_error))
                printerr("This may indicate permission issues with the project directory")
                # Continue anyway, as the scene directory might still be writable
        
        # Ensure the scene directory exists using DirAccess
        if debug_mode:
            print("Ensuring scene directory exists...")
        
        # Get the scene directory relative to res://
        var scene_dir_relative = scene_dir_res.substr(6)  # Remove "res://" prefix
        if debug_mode:
            print("Scene directory (relative to res://): " + scene_dir_relative)
        
        # Create the directory if needed
        if not scene_dir_relative.is_empty():
            # First check if it exists
            var dir_exists = DirAccess.dir_exists_absolute(scene_dir_abs)
            if debug_mode:
                print("Directory exists check (absolute): " + str(dir_exists))
            
            if not dir_exists:
                if debug_mode:
                    print("Directory doesn't exist, creating: " + scene_dir_relative)
                
                # Try to create the directory using DirAccess
                var dir = DirAccess.open("res://")
                if dir == null:
                    var open_error = DirAccess.get_open_error()
                    printerr("Failed to open res:// directory: " + str(open_error))
                    
                    # Try alternative approach with absolute path
                    if debug_mode:
                        print("Trying alternative directory creation approach...")
                    var make_dir_error = DirAccess.make_dir_recursive_absolute(scene_dir_abs)
                    if debug_mode:
                        print("Make directory result (absolute): " + str(make_dir_error))
                    
                    if make_dir_error != OK:
                        printerr("Failed to create directory using absolute path")
                        printerr("Error code: " + str(make_dir_error))
                        quit(1)
                else:
                    # Create the directory using the DirAccess instance
                    if debug_mode:
                        print("Creating directory using DirAccess: " + scene_dir_relative)
                    var make_dir_error = dir.make_dir_recursive(scene_dir_relative)
                    if debug_mode:
                        print("Make directory result: " + str(make_dir_error))
                    
                    if make_dir_error != OK:
                        printerr("Failed to create directory: " + scene_dir_relative)
                        printerr("Error code: " + str(make_dir_error))
                        quit(1)
                
                # Verify the directory was created
                dir_exists = DirAccess.dir_exists_absolute(scene_dir_abs)
                if debug_mode:
                    print("Directory exists check after creation: " + str(dir_exists))
                
                if not dir_exists:
                    printerr("Directory reported as created but does not exist: " + scene_dir_abs)
                    printerr("This may indicate a problem with path resolution or permissions")
                    quit(1)
            elif debug_mode:
                print("Directory already exists: " + scene_dir_abs)
        
        # Save the scene
        if debug_mode:
            print("Saving scene to: " + full_scene_path)
        var save_error = ResourceSaver.save(packed_scene, full_scene_path)
        if debug_mode:
            print("Save result: " + str(save_error) + " (OK=" + str(OK) + ")")
        
        if save_error == OK:
            # Only do extensive testing in debug mode
            if debug_mode:
                # Wait a moment to ensure file system has time to complete the write
                print("Waiting for file system to complete write operation...")
                OS.delay_msec(500)  # 500ms delay
                
                # Verify the file was actually created using multiple methods
                var file_check_abs = FileAccess.file_exists(absolute_scene_path)
                print("File exists check (absolute path): " + str(file_check_abs))
                
                var file_check_res = FileAccess.file_exists(full_scene_path)
                print("File exists check (resource path): " + str(file_check_res))
                
                var res_exists = ResourceLoader.exists(full_scene_path)
                print("Resource exists check: " + str(res_exists))
                
                # If file doesn't exist by absolute path, try to create a test file in the same directory
                if not file_check_abs and not file_check_res:
                    printerr("Scene file not found after save. Trying to diagnose the issue...")
                    
                    # Try to write a test file to the same directory
                    var test_scene_file_path = scene_dir_res + "/test_scene_file.tmp"
                    var test_scene_file = FileAccess.open(test_scene_file_path, FileAccess.WRITE)
                    
                    if test_scene_file:
                        test_scene_file.store_string("Test scene directory write")
                        test_scene_file.close()
                        print("Successfully wrote test file to scene directory: " + test_scene_file_path)
                        
                        # Check if the test file exists
                        var test_file_exists = FileAccess.file_exists(test_scene_file_path)
                        print("Test file exists: " + str(test_file_exists))
                        
                        if test_file_exists:
                            # Directory is writable, so the issue is with scene saving
                            printerr("Directory is writable but scene file wasn't created.")
                            printerr("This suggests an issue with ResourceSaver.save() or the packed scene.")
                            
                            # Try saving with a different approach
                            print("Trying alternative save approach...")
                            var alt_save_error = ResourceSaver.save(packed_scene, test_scene_file_path + ".tscn")
                            print("Alternative save result: " + str(alt_save_error))
                            
                            # Clean up test files
                            DirAccess.remove_absolute(ProjectSettings.globalize_path(test_scene_file_path))
                            if alt_save_error == OK:
                                DirAccess.remove_absolute(ProjectSettings.globalize_path(test_scene_file_path + ".tscn"))
                        else:
                            printerr("Test file couldn't be verified. This suggests filesystem access issues.")
                    else:
                        var write_error = FileAccess.get_open_error()
                        printerr("Failed to write test file to scene directory: " + str(write_error))
                        printerr("This confirms there are permission or path issues with the scene directory.")
                    
                    # Return error since we couldn't create the scene file
                    printerr("Failed to create scene: " + params.scene_path)
                    quit(1)
                
                # If we get here, at least one of our file checks passed
                if file_check_abs or file_check_res or res_exists:
                    print("Scene file verified to exist!")
                    
                    # Try to load the scene to verify it's valid
                    var test_load = ResourceLoader.load(full_scene_path)
                    if test_load:
                        print("Scene created and verified successfully at: " + params.scene_path)
                        print("Scene file can be loaded correctly.")
                    else:
                        print("Scene file exists but cannot be loaded. It may be corrupted or incomplete.")
                        # Continue anyway since the file exists
                    
                    print("Scene created successfully at: " + params.scene_path)
                else:
                    printerr("All file existence checks failed despite successful save operation.")
                    printerr("This indicates a serious issue with file system access or path resolution.")
                    quit(1)
            else:
                # In non-debug mode, just check if the file exists
                var file_exists = FileAccess.file_exists(full_scene_path)
                if file_exists:
                    print("Scene created successfully at: " + params.scene_path)
                else:
                    printerr("Failed to create scene: " + params.scene_path)
                    quit(1)
        else:
            # Handle specific error codes
            var error_message = "Failed to save scene. Error code: " + str(save_error)
            
            if save_error == ERR_CANT_CREATE:
                error_message += " (ERR_CANT_CREATE - Cannot create the scene file)"
            elif save_error == ERR_CANT_OPEN:
                error_message += " (ERR_CANT_OPEN - Cannot open the scene file for writing)"
            elif save_error == ERR_FILE_CANT_WRITE:
                error_message += " (ERR_FILE_CANT_WRITE - Cannot write to the scene file)"
            elif save_error == ERR_FILE_NO_PERMISSION:
                error_message += " (ERR_FILE_NO_PERMISSION - No permission to write the scene file)"
            
            printerr(error_message)
            quit(1)
    else:
        printerr("Failed to pack scene: " + str(result))
        printerr("Error code: " + str(result))
        quit(1)

# Add a node to an existing scene
func add_node(params):
    print("Adding node to scene: " + params.scene_path)
    
    var full_scene_path = params.scene_path
    if not full_scene_path.begins_with("res://"):
        full_scene_path = "res://" + full_scene_path
    if debug_mode:
        print("Scene path (with res://): " + full_scene_path)
    
    var absolute_scene_path = ProjectSettings.globalize_path(full_scene_path)
    if debug_mode:
        print("Absolute scene path: " + absolute_scene_path)
    
    if not FileAccess.file_exists(absolute_scene_path):
        printerr("Scene file does not exist at: " + absolute_scene_path)
        quit(1)
    
    var scene = load(full_scene_path)
    if not scene:
        printerr("Failed to load scene: " + full_scene_path)
        quit(1)
    
    if debug_mode:
        print("Scene loaded successfully")
    var scene_root = scene.instantiate()
    if debug_mode:
        print("Scene instantiated")
    
    # Use traditional if-else statement for better compatibility
    var parent_path = "root"  # Default value
    if params.has("parent_node_path"):
        parent_path = params.parent_node_path
    if debug_mode:
        print("Parent path: " + parent_path)
    
    var parent = scene_root
    if parent_path != "root":
        parent = scene_root.get_node(parent_path.replace("root/", ""))
        if not parent:
            printerr("Parent node not found: " + parent_path)
            quit(1)
    if debug_mode:
        print("Parent node found: " + parent.name)
    
    if debug_mode:
        print("Instantiating node of type: " + params.node_type)
    var new_node = instantiate_class(params.node_type)
    if not new_node:
        printerr("Failed to instantiate node of type: " + params.node_type)
        printerr("Make sure the class exists and can be instantiated")
        printerr("Check if the class is registered in ClassDB or available as a script")
        quit(1)
    new_node.name = params.node_name
    if debug_mode:
        print("New node created with name: " + new_node.name)
    
    if params.has("properties"):
        if debug_mode:
            print("Setting properties on node")
        var properties = params.properties
        for property in properties:
            if debug_mode:
                print("Setting property: " + property + " = " + str(properties[property]))
            new_node.set(property, properties[property])
    
    parent.add_child(new_node)
    new_node.owner = scene_root
    if debug_mode:
        print("Node added to parent and ownership set")
    
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)
    if debug_mode:
        print("Pack result: " + str(result) + " (OK=" + str(OK) + ")")
    
    if result == OK:
        if debug_mode:
            print("Saving scene to: " + absolute_scene_path)
        var save_error = ResourceSaver.save(packed_scene, absolute_scene_path)
        if debug_mode:
            print("Save result: " + str(save_error) + " (OK=" + str(OK) + ")")
        if save_error == OK:
            if debug_mode:
                var file_check_after = FileAccess.file_exists(absolute_scene_path)
                print("File exists check after save: " + str(file_check_after))
                if file_check_after:
                    print("Node '" + params.node_name + "' of type '" + params.node_type + "' added successfully")
                else:
                    printerr("File reported as saved but does not exist at: " + absolute_scene_path)
            else:
                print("Node '" + params.node_name + "' of type '" + params.node_type + "' added successfully")
        else:
            printerr("Failed to save scene: " + str(save_error))
    else:
        printerr("Failed to pack scene: " + str(result))

# Load a sprite into a Sprite2D node
func load_sprite(params):
    print("Loading sprite into scene: " + params.scene_path)
    
    # Ensure the scene path starts with res:// for Godot's resource system
    var full_scene_path = params.scene_path
    if not full_scene_path.begins_with("res://"):
        full_scene_path = "res://" + full_scene_path
    
    if debug_mode:
        print("Full scene path (with res://): " + full_scene_path)
    
    # Check if the scene file exists
    var file_check = FileAccess.file_exists(full_scene_path)
    if debug_mode:
        print("Scene file exists check: " + str(file_check))
    
    if not file_check:
        printerr("Scene file does not exist at: " + full_scene_path)
        # Get the absolute path for reference
        var absolute_path = ProjectSettings.globalize_path(full_scene_path)
        printerr("Absolute file path that doesn't exist: " + absolute_path)
        quit(1)
    
    # Ensure the texture path starts with res:// for Godot's resource system
    var full_texture_path = params.texture_path
    if not full_texture_path.begins_with("res://"):
        full_texture_path = "res://" + full_texture_path
    
    if debug_mode:
        print("Full texture path (with res://): " + full_texture_path)
    
    # Load the scene
    var scene = load(full_scene_path)
    if not scene:
        printerr("Failed to load scene: " + full_scene_path)
        quit(1)
    
    if debug_mode:
        print("Scene loaded successfully")
    
    # Instance the scene
    var scene_root = scene.instantiate()
    if debug_mode:
        print("Scene instantiated")
    
    # Find the sprite node
    var node_path = params.node_path
    if debug_mode:
        print("Original node path: " + node_path)
    
    if node_path.begins_with("root/"):
        node_path = node_path.substr(5)  # Remove "root/" prefix
        if debug_mode:
            print("Node path after removing 'root/' prefix: " + node_path)
    
    var sprite_node = null
    if node_path == "":
        # If no node path, assume root is the sprite
        sprite_node = scene_root
        if debug_mode:
            print("Using root node as sprite node")
    else:
        sprite_node = scene_root.get_node(node_path)
        if sprite_node and debug_mode:
            print("Found sprite node: " + sprite_node.name)
    
    if not sprite_node:
        printerr("Node not found: " + params.node_path)
        quit(1)
    
    # Check if the node is a Sprite2D or compatible type
    if debug_mode:
        print("Node class: " + sprite_node.get_class())
    if not (sprite_node is Sprite2D or sprite_node is Sprite3D or sprite_node is TextureRect):
        printerr("Node is not a sprite-compatible type: " + sprite_node.get_class())
        quit(1)
    
    # Load the texture
    if debug_mode:
        print("Loading texture from: " + full_texture_path)
    var texture = load(full_texture_path)
    if not texture:
        printerr("Failed to load texture: " + full_texture_path)
        quit(1)
    
    if debug_mode:
        print("Texture loaded successfully")
    
    # Set the texture on the sprite
    if sprite_node is Sprite2D or sprite_node is Sprite3D:
        sprite_node.texture = texture
        if debug_mode:
            print("Set texture on Sprite2D/Sprite3D node")
    elif sprite_node is TextureRect:
        sprite_node.texture = texture
        if debug_mode:
            print("Set texture on TextureRect node")
    
    # Save the modified scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)
    if debug_mode:
        print("Pack result: " + str(result) + " (OK=" + str(OK) + ")")
    
    if result == OK:
        if debug_mode:
            print("Saving scene to: " + full_scene_path)
        var error = ResourceSaver.save(packed_scene, full_scene_path)
        if debug_mode:
            print("Save result: " + str(error) + " (OK=" + str(OK) + ")")
        
        if error == OK:
            # Verify the file was actually updated
            if debug_mode:
                var file_check_after = FileAccess.file_exists(full_scene_path)
                print("File exists check after save: " + str(file_check_after))
                
                if file_check_after:
                    print("Sprite loaded successfully with texture: " + full_texture_path)
                    # Get the absolute path for reference
                    var absolute_path = ProjectSettings.globalize_path(full_scene_path)
                    print("Absolute file path: " + absolute_path)
                else:
                    printerr("File reported as saved but does not exist at: " + full_scene_path)
            else:
                print("Sprite loaded successfully with texture: " + full_texture_path)
        else:
            printerr("Failed to save scene: " + str(error))
    else:
        printerr("Failed to pack scene: " + str(result))

# Export a scene as a MeshLibrary resource
func export_mesh_library(params):
    print("Exporting MeshLibrary from scene: " + params.scene_path)
    
    # Ensure the scene path starts with res:// for Godot's resource system
    var full_scene_path = params.scene_path
    if not full_scene_path.begins_with("res://"):
        full_scene_path = "res://" + full_scene_path
    
    if debug_mode:
        print("Full scene path (with res://): " + full_scene_path)
    
    # Ensure the output path starts with res:// for Godot's resource system
    var full_output_path = params.output_path
    if not full_output_path.begins_with("res://"):
        full_output_path = "res://" + full_output_path
    
    if debug_mode:
        print("Full output path (with res://): " + full_output_path)
    
    # Check if the scene file exists
    var file_check = FileAccess.file_exists(full_scene_path)
    if debug_mode:
        print("Scene file exists check: " + str(file_check))
    
    if not file_check:
        printerr("Scene file does not exist at: " + full_scene_path)
        # Get the absolute path for reference
        var absolute_path = ProjectSettings.globalize_path(full_scene_path)
        printerr("Absolute file path that doesn't exist: " + absolute_path)
        quit(1)
    
    # Load the scene
    if debug_mode:
        print("Loading scene from: " + full_scene_path)
    var scene = load(full_scene_path)
    if not scene:
        printerr("Failed to load scene: " + full_scene_path)
        quit(1)
    
    if debug_mode:
        print("Scene loaded successfully")
    
    # Instance the scene
    var scene_root = scene.instantiate()
    if debug_mode:
        print("Scene instantiated")
    
    # Create a new MeshLibrary
    var mesh_library = MeshLibrary.new()
    if debug_mode:
        print("Created new MeshLibrary")
    
    # Get mesh item names if provided
    var mesh_item_names = params.mesh_item_names if params.has("mesh_item_names") else []
    var use_specific_items = mesh_item_names.size() > 0
    
    if debug_mode:
        if use_specific_items:
            print("Using specific mesh items: " + str(mesh_item_names))
        else:
            print("Using all mesh items in the scene")
    
    # Process all child nodes
    var item_id = 0
    if debug_mode:
        print("Processing child nodes...")
    
    for child in scene_root.get_children():
        if debug_mode:
            print("Checking child node: " + child.name)
        
        # Skip if not using all items and this item is not in the list
        if use_specific_items and not (child.name in mesh_item_names):
            if debug_mode:
                print("Skipping node " + child.name + " (not in specified items list)")
            continue
            
        # Check if the child has a mesh
        var mesh_instance = null
        if child is MeshInstance3D:
            mesh_instance = child
            if debug_mode:
                print("Node " + child.name + " is a MeshInstance3D")
        else:
            # Try to find a MeshInstance3D in the child's descendants
            if debug_mode:
                print("Searching for MeshInstance3D in descendants of " + child.name)
            for descendant in child.get_children():
                if descendant is MeshInstance3D:
                    mesh_instance = descendant
                    if debug_mode:
                        print("Found MeshInstance3D in descendant: " + descendant.name)
                    break
        
        if mesh_instance and mesh_instance.mesh:
            if debug_mode:
                print("Adding mesh: " + child.name)
            
            # Add the mesh to the library
            mesh_library.create_item(item_id)
            mesh_library.set_item_name(item_id, child.name)
            mesh_library.set_item_mesh(item_id, mesh_instance.mesh)
            if debug_mode:
                print("Added mesh to library with ID: " + str(item_id))
            
            # Add collision shape if available
            var collision_added = false
            for collision_child in child.get_children():
                if collision_child is CollisionShape3D and collision_child.shape:
                    mesh_library.set_item_shapes(item_id, [collision_child.shape])
                    if debug_mode:
                        print("Added collision shape from: " + collision_child.name)
                    collision_added = true
                    break
            
            if debug_mode and not collision_added:
                print("No collision shape found for mesh: " + child.name)
            
            # Add preview if available
            if mesh_instance.mesh:
                mesh_library.set_item_preview(item_id, mesh_instance.mesh)
                if debug_mode:
                    print("Added preview for mesh: " + child.name)
            
            item_id += 1
        elif debug_mode:
            print("Node " + child.name + " has no valid mesh")
    
    if debug_mode:
        print("Processed " + str(item_id) + " meshes")
    
    # Create directory if it doesn't exist
    var dir = DirAccess.open("res://")
    if dir == null:
        printerr("Failed to open res:// directory")
        printerr("DirAccess error: " + str(DirAccess.get_open_error()))
        quit(1)
        
    var output_dir = full_output_path.get_base_dir()
    if debug_mode:
        print("Output directory: " + output_dir)
    
    if output_dir != "res://" and not dir.dir_exists(output_dir.substr(6)):  # Remove "res://" prefix
        if debug_mode:
            print("Creating directory: " + output_dir)
        var error = dir.make_dir_recursive(output_dir.substr(6))  # Remove "res://" prefix
        if error != OK:
            printerr("Failed to create directory: " + output_dir + ", error: " + str(error))
            quit(1)
    
    # Save the mesh library
    if item_id > 0:
        if debug_mode:
            print("Saving MeshLibrary to: " + full_output_path)
        var error = ResourceSaver.save(mesh_library, full_output_path)
        if debug_mode:
            print("Save result: " + str(error) + " (OK=" + str(OK) + ")")
        
        if error == OK:
            # Verify the file was actually created
            if debug_mode:
                var file_check_after = FileAccess.file_exists(full_output_path)
                print("File exists check after save: " + str(file_check_after))
                
                if file_check_after:
                    print("MeshLibrary exported successfully with " + str(item_id) + " items to: " + full_output_path)
                    # Get the absolute path for reference
                    var absolute_path = ProjectSettings.globalize_path(full_output_path)
                    print("Absolute file path: " + absolute_path)
                else:
                    printerr("File reported as saved but does not exist at: " + full_output_path)
            else:
                print("MeshLibrary exported successfully with " + str(item_id) + " items to: " + full_output_path)
        else:
            printerr("Failed to save MeshLibrary: " + str(error))
    else:
        printerr("No valid meshes found in the scene")

# Find files with a specific extension recursively
func find_files(path, extension):
    var files = []
    var dir = DirAccess.open(path)
    
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            if dir.current_is_dir() and not file_name.begins_with("."):
                files.append_array(find_files(path + file_name + "/", extension))
            elif file_name.ends_with(extension):
                files.append(path + file_name)
            
            file_name = dir.get_next()
    
    return files

# Get UID for a specific file
func get_uid(params):
    if not params.has("file_path"):
        printerr("File path is required")
        quit(1)
    
    # Ensure the file path starts with res:// for Godot's resource system
    var file_path = params.file_path
    if not file_path.begins_with("res://"):
        file_path = "res://" + file_path
    
    print("Getting UID for file: " + file_path)
    if debug_mode:
        print("Full file path (with res://): " + file_path)
    
    # Get the absolute path for reference
    var absolute_path = ProjectSettings.globalize_path(file_path)
    if debug_mode:
        print("Absolute file path: " + absolute_path)
    
    # Ensure the file exists
    var file_check = FileAccess.file_exists(file_path)
    if debug_mode:
        print("File exists check: " + str(file_check))
    
    if not file_check:
        printerr("File does not exist at: " + file_path)
        printerr("Absolute file path that doesn't exist: " + absolute_path)
        quit(1)
    
    # Check if the UID file exists
    var uid_path = file_path + ".uid"
    if debug_mode:
        print("UID file path: " + uid_path)
    
    var uid_check = FileAccess.file_exists(uid_path)
    if debug_mode:
        print("UID file exists check: " + str(uid_check))
    
    var f = FileAccess.open(uid_path, FileAccess.READ)
    
    if f:
        # Read the UID content
        var uid_content = f.get_as_text()
        f.close()
        if debug_mode:
            print("UID content read successfully")
        
        # Return the UID content
        var result = {
            "file": file_path,
            "absolutePath": absolute_path,
            "uid": uid_content.strip_edges(),
            "exists": true
        }
        if debug_mode:
            print("UID result: " + JSON.stringify(result))
        print(JSON.stringify(result))
    else:
        if debug_mode:
            print("UID file does not exist or could not be opened")
        
        # UID file doesn't exist
        var result = {
            "file": file_path,
            "absolutePath": absolute_path,
            "exists": false,
            "message": "UID file does not exist for this file. Use resave_resources to generate UIDs."
        }
        if debug_mode:
            print("UID result: " + JSON.stringify(result))
        print(JSON.stringify(result))

# Resave all resources to update UID references
func resave_resources(params):
    print("Resaving all resources to update UID references...")
    
    # Get project path if provided
    var project_path = "res://"
    if params.has("project_path"):
        project_path = params.project_path
        if not project_path.begins_with("res://"):
            project_path = "res://" + project_path
        if not project_path.ends_with("/"):
            project_path += "/"
    
    if debug_mode:
        print("Using project path: " + project_path)
    
    # Get all .tscn files
    if debug_mode:
        print("Searching for scene files in: " + project_path)
    var scenes = find_files(project_path, ".tscn")
    if debug_mode:
        print("Found " + str(scenes.size()) + " scenes")
    
    # Resave each scene
    var success_count = 0
    var error_count = 0
    
    for scene_path in scenes:
        if debug_mode:
            print("Processing scene: " + scene_path)
        
        # Check if the scene file exists
        var file_check = FileAccess.file_exists(scene_path)
        if debug_mode:
            print("Scene file exists check: " + str(file_check))
        
        if not file_check:
            printerr("Scene file does not exist at: " + scene_path)
            error_count += 1
            continue
        
        # Load the scene
        var scene = load(scene_path)
        if scene:
            if debug_mode:
                print("Scene loaded successfully, saving...")
            var error = ResourceSaver.save(scene, scene_path)
            if debug_mode:
                print("Save result: " + str(error) + " (OK=" + str(OK) + ")")
            
            if error == OK:
                success_count += 1
                if debug_mode:
                    print("Scene saved successfully: " + scene_path)
                
                    # Verify the file was actually updated
                    var file_check_after = FileAccess.file_exists(scene_path)
                    print("File exists check after save: " + str(file_check_after))
                
                    if not file_check_after:
                        printerr("File reported as saved but does not exist at: " + scene_path)
            else:
                error_count += 1
                printerr("Failed to save: " + scene_path + ", error: " + str(error))
        else:
            error_count += 1
            printerr("Failed to load: " + scene_path)
    
    # Get all .gd and .shader files
    if debug_mode:
        print("Searching for script and shader files in: " + project_path)
    var scripts = find_files(project_path, ".gd") + find_files(project_path, ".shader") + find_files(project_path, ".gdshader")
    if debug_mode:
        print("Found " + str(scripts.size()) + " scripts/shaders")
    
    # Check for missing .uid files
    var missing_uids = 0
    var generated_uids = 0
    
    for script_path in scripts:
        if debug_mode:
            print("Checking UID for: " + script_path)
        var uid_path = script_path + ".uid"
        
        var uid_check = FileAccess.file_exists(uid_path)
        if debug_mode:
            print("UID file exists check: " + str(uid_check))
        
        var f = FileAccess.open(uid_path, FileAccess.READ)
        if not f:
            missing_uids += 1
            if debug_mode:
                print("Missing UID file for: " + script_path + ", generating...")
            
            # Force a save to generate UID
            var res = load(script_path)
            if res:
                var error = ResourceSaver.save(res, script_path)
                if debug_mode:
                    print("Save result: " + str(error) + " (OK=" + str(OK) + ")")
                
                if error == OK:
                    generated_uids += 1
                    if debug_mode:
                        print("Generated UID for: " + script_path)
                    
                        # Verify the UID file was actually created
                        var uid_check_after = FileAccess.file_exists(uid_path)
                        print("UID file exists check after save: " + str(uid_check_after))
                    
                        if not uid_check_after:
                            printerr("UID file reported as generated but does not exist at: " + uid_path)
                else:
                    printerr("Failed to generate UID for: " + script_path + ", error: " + str(error))
            else:
                printerr("Failed to load resource: " + script_path)
        elif debug_mode:
            print("UID file already exists for: " + script_path)
    
    if debug_mode:
        print("Summary:")
        print("- Scenes processed: " + str(scenes.size()))
        print("- Scenes successfully saved: " + str(success_count))
        print("- Scenes with errors: " + str(error_count))
        print("- Scripts/shaders missing UIDs: " + str(missing_uids))
        print("- UIDs successfully generated: " + str(generated_uids))
    print("Resave operation complete")

# Save changes to a scene file
func save_scene(params):
    print("Saving scene: " + params.scene_path)
    
    # Ensure the scene path starts with res:// for Godot's resource system
    var full_scene_path = params.scene_path
    if not full_scene_path.begins_with("res://"):
        full_scene_path = "res://" + full_scene_path
    
    if debug_mode:
        print("Full scene path (with res://): " + full_scene_path)
    
    # Check if the scene file exists
    var file_check = FileAccess.file_exists(full_scene_path)
    if debug_mode:
        print("Scene file exists check: " + str(file_check))
    
    if not file_check:
        printerr("Scene file does not exist at: " + full_scene_path)
        # Get the absolute path for reference
        var absolute_path = ProjectSettings.globalize_path(full_scene_path)
        printerr("Absolute file path that doesn't exist: " + absolute_path)
        quit(1)
    
    # Load the scene
    var scene = load(full_scene_path)
    if not scene:
        printerr("Failed to load scene: " + full_scene_path)
        quit(1)
    
    if debug_mode:
        print("Scene loaded successfully")
    
    # Instance the scene
    var scene_root = scene.instantiate()
    if debug_mode:
        print("Scene instantiated")
    
    # Determine save path
    var save_path = params.new_path if params.has("new_path") else full_scene_path
    if params.has("new_path") and not save_path.begins_with("res://"):
        save_path = "res://" + save_path
    
    if debug_mode:
        print("Save path: " + save_path)
    
    # Create directory if it doesn't exist
    if params.has("new_path"):
        var dir = DirAccess.open("res://")
        if dir == null:
            printerr("Failed to open res:// directory")
            printerr("DirAccess error: " + str(DirAccess.get_open_error()))
            quit(1)
            
        var scene_dir = save_path.get_base_dir()
        if debug_mode:
            print("Scene directory: " + scene_dir)
        
        if scene_dir != "res://" and not dir.dir_exists(scene_dir.substr(6)):  # Remove "res://" prefix
            if debug_mode:
                print("Creating directory: " + scene_dir)
            var error = dir.make_dir_recursive(scene_dir.substr(6))  # Remove "res://" prefix
            if error != OK:
                printerr("Failed to create directory: " + scene_dir + ", error: " + str(error))
                quit(1)
    
    # Create a packed scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)
    if debug_mode:
        print("Pack result: " + str(result) + " (OK=" + str(OK) + ")")
    
    if result == OK:
        if debug_mode:
            print("Saving scene to: " + save_path)
        var error = ResourceSaver.save(packed_scene, save_path)
        if debug_mode:
            print("Save result: " + str(error) + " (OK=" + str(OK) + ")")
        
        if error == OK:
            # Verify the file was actually created/updated
            if debug_mode:
                var file_check_after = FileAccess.file_exists(save_path)
                print("File exists check after save: " + str(file_check_after))
                
                if file_check_after:
                    print("Scene saved successfully to: " + save_path)
                    # Get the absolute path for reference
                    var absolute_path = ProjectSettings.globalize_path(save_path)
                    print("Absolute file path: " + absolute_path)
                else:
                    printerr("File reported as saved but does not exist at: " + save_path)
            else:
                print("Scene saved successfully to: " + save_path)
        else:
            printerr("Failed to save scene: " + str(error))
    else:
        printerr("Failed to pack scene: " + str(result))

# ============================================================================
# CUSTOM OPERATIONS FOR SHADOWS OF THE MOTH
# ============================================================================

# Create Main.tscn with all system managers
func create_main_scene(params):
    print("Creating Main scene for Shadows of the Moth...")
    
    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/Main.tscn"
    
    # Normalize path
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path
    
    if debug_mode:
        print("Scene path: " + scene_path)
    
    # Create root node
    var root = Node.new()
    root.name = "Main"
    
    # WorldSystems container
    var world_systems = Node.new()
    world_systems.name = "WorldSystems"
    root.add_child(world_systems)
    world_systems.set_owner(root)
    
    # System managers
    var managers = [
        "TimeManager",
        "WeatherManager",
        "LightManager",
        "SkyController"
    ]
    
    for manager_name in managers:
        var manager = Node.new()
        manager.name = manager_name
        world_systems.add_child(manager)
        manager.set_owner(root)
        if debug_mode:
            print("Added manager: " + manager_name)
    
    # Add lights to LightManager
    var light_manager = world_systems.get_node("LightManager")
    if light_manager:
        var sun_light = DirectionalLight3D.new()
        sun_light.name = "SunLight"
        sun_light.light_energy = 1.0
        sun_light.rotation_degrees = Vector3(-45, -30, 0)
        light_manager.add_child(sun_light)
        sun_light.set_owner(root)
        
        var moon_light = DirectionalLight3D.new()
        moon_light.name = "MoonLight"
        moon_light.light_energy = 0.3
        moon_light.visible = false
        moon_light.rotation_degrees = Vector3(-45, 150, 0)
        light_manager.add_child(moon_light)
        moon_light.set_owner(root)
    
    # AISystems container
    var ai_systems = Node.new()
    ai_systems.name = "AISystems"
    root.add_child(ai_systems)
    ai_systems.set_owner(root)
    
    var navigation_grid = Node3D.new()
    navigation_grid.name = "NavigationGrid"
    ai_systems.add_child(navigation_grid)
    navigation_grid.set_owner(root)
    
    var squad_manager = Node.new()
    squad_manager.name = "SquadManager"
    ai_systems.add_child(squad_manager)
    squad_manager.set_owner(root)
    
    # StealthSystems container
    var stealth_systems = Node.new()
    stealth_systems.name = "StealthSystems"
    root.add_child(stealth_systems)
    stealth_systems.set_owner(root)
    
    var noise_emitter = Node.new()
    noise_emitter.name = "NoiseEmitter"
    stealth_systems.add_child(noise_emitter)
    noise_emitter.set_owner(root)
    
    var perception_manager = Node.new()
    perception_manager.name = "PerceptionManager"
    stealth_systems.add_child(perception_manager)
    perception_manager.set_owner(root)
    
    # WorldEnvironment
    var world_env = WorldEnvironment.new()
    world_env.name = "WorldEnvironment"
    var environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    world_env.environment = environment
    root.add_child(world_env)
    world_env.set_owner(root)
    
    # UI CanvasLayer (placeholder - will be populated later)
    var ui_layer = CanvasLayer.new()
    ui_layer.name = "UI"
    root.add_child(ui_layer)
    ui_layer.set_owner(root)
    
    # Save scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)
    
    if result == OK:
        # Ensure directory exists
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))  # Remove "res://"
        
        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Main scene created successfully at: " + scene_path)
            print("  - WorldSystems with 4 managers")
            print("  - AISystems with NavigationGrid and SquadManager")
            print("  - StealthSystems with NoiseEmitter and PerceptionManager")
            print("  - WorldEnvironment with sky")
            print("  - UI CanvasLayer")
        else:
            printerr("Failed to save Main scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack Main scene: " + str(result))
        quit(1)

# Create Player.tscn with CharacterBody3D, camera, and controller
func create_player_scene(params):
    print("Creating Player scene...")

    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/player/Player.tscn"
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    var root = CharacterBody3D.new()
    root.name = "Player"

    # Collision shape
    var collision = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var capsule_shape = CapsuleShape3D.new()
    capsule_shape.radius = 0.4
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    root.add_child(collision)
    collision.set_owner(root)

    # Visual mesh (placeholder)
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.name = "MeshInstance3D"
    var capsule_mesh = CapsuleMesh.new()
    capsule_mesh.radius = 0.4
    capsule_mesh.height = 1.8
    mesh_instance.mesh = capsule_mesh
    root.add_child(mesh_instance)
    mesh_instance.set_owner(root)

    # Camera rig
    var camera_rig = Node3D.new()
    camera_rig.name = "CameraRig"
    camera_rig.position = Vector3(0, 1.6, 0)
    root.add_child(camera_rig)
    camera_rig.set_owner(root)

    var camera_arm = SpringArm3D.new()
    camera_arm.name = "CameraArm"
    camera_arm.spring_length = 5.0
    camera_rig.add_child(camera_arm)
    camera_arm.set_owner(root)

    var camera = Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera_arm.add_child(camera)
    camera.set_owner(root)

    var camera_manager = Node.new()
    camera_manager.name = "CameraManager"
    camera_rig.add_child(camera_manager)
    camera_manager.set_owner(root)

    # States container
    var states = Node.new()
    states.name = "States"
    root.add_child(states)
    states.set_owner(root)

    # Abilities container
    var abilities = Node.new()
    abilities.name = "Abilities"
    root.add_child(abilities)
    abilities.set_owner(root)

    # Save scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)

    if result == OK:
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))

        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Player scene created successfully at: " + scene_path)
        else:
            printerr("Failed to save Player scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack Player scene: " + str(result))
        quit(1)

# Create NPC.tscn with AI, navigation, and perception
func create_npc_scene(params):
    print("Creating NPC scene...")

    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/npc/NPC.tscn"
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    var root = CharacterBody3D.new()
    root.name = "NPC"

    # Collision shape
    var collision = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var capsule_shape = CapsuleShape3D.new()
    capsule_shape.radius = 0.4
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    root.add_child(collision)
    collision.set_owner(root)

    # Visual mesh with different color
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.name = "MeshInstance3D"
    var capsule_mesh = CapsuleMesh.new()
    capsule_mesh.radius = 0.4
    capsule_mesh.height = 1.8
    mesh_instance.mesh = capsule_mesh
    root.add_child(mesh_instance)
    mesh_instance.set_owner(root)

    # Perception container
    var perception = Node.new()
    perception.name = "Perception"
    root.add_child(perception)
    perception.set_owner(root)

    # Vision sensor
    var vision_sensor = Node.new()
    vision_sensor.name = "VisionSensor"
    perception.add_child(vision_sensor)
    vision_sensor.set_owner(root)

    # Vision cone
    var vision_cone = Area3D.new()
    vision_cone.name = "VisionCone"
    vision_sensor.add_child(vision_cone)
    vision_cone.set_owner(root)

    # Hearing sensor
    var hearing_sensor = Node.new()
    hearing_sensor.name = "HearingSensor"
    perception.add_child(hearing_sensor)
    hearing_sensor.set_owner(root)

    # Suspicion accumulator
    var suspicion = Node.new()
    suspicion.name = "SuspicionAccumulator"
    perception.add_child(suspicion)
    suspicion.set_owner(root)

    # Debug container
    var debug_node = Node.new()
    debug_node.name = "Debug"
    root.add_child(debug_node)
    debug_node.set_owner(root)

    # Save scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)

    if result == OK:
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))

        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("NPC scene created successfully at: " + scene_path)
        else:
            printerr("Failed to save NPC scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack NPC scene: " + str(result))
        quit(1)

# Create HUD/UI scene with complete interface hierarchy
func create_hud_scene(params):
    print("Creating HUD scene...")

    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/ui/UI.tscn"
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    var root = CanvasLayer.new()
    root.name = "UI"

    # HUD container
    var hud = Control.new()
    hud.name = "HUD"
    hud.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(hud)
    hud.set_owner(root)

    # Margin container
    var margin = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    hud.add_child(margin)
    margin.set_owner(root)

    # VBox container
    var vbox = VBoxContainer.new()
    vbox.name = "VBoxContainer"
    margin.add_child(vbox)
    vbox.set_owner(root)

    # Top bar
    var top_bar = HBoxContainer.new()
    top_bar.name = "TopBar"
    vbox.add_child(top_bar)
    top_bar.set_owner(root)

    var harmony_bar = ProgressBar.new()
    harmony_bar.name = "HarmonyBar"
    harmony_bar.min_value = -100
    harmony_bar.max_value = 100
    harmony_bar.value = 0
    harmony_bar.custom_minimum_size = Vector2(200, 30)
    top_bar.add_child(harmony_bar)
    harmony_bar.set_owner(root)

    var time_display = Label.new()
    time_display.name = "TimeDisplay"
    time_display.text = "00:00"
    top_bar.add_child(time_display)
    time_display.set_owner(root)

    # Center info
    var center_info = VBoxContainer.new()
    center_info.name = "CenterInfo"
    center_info.alignment = BoxContainer.ALIGNMENT_CENTER
    center_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(center_info)
    center_info.set_owner(root)

    var interaction_prompt = Label.new()
    interaction_prompt.name = "InteractionPrompt"
    interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center_info.add_child(interaction_prompt)
    interaction_prompt.set_owner(root)

    # Bottom bar
    var bottom_bar = HBoxContainer.new()
    bottom_bar.name = "BottomBar"
    vbox.add_child(bottom_bar)
    bottom_bar.set_owner(root)

    var debug_info = Label.new()
    debug_info.name = "DebugInfo"
    debug_info.text = "Debug"
    bottom_bar.add_child(debug_info)
    debug_info.set_owner(root)

    # Save scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)

    if result == OK:
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))

        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("HUD scene created successfully at: " + scene_path)
        else:
            printerr("Failed to save HUD scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack HUD scene: " + str(result))
        quit(1)

# Create test level with ground, walls, lighting
func create_test_level(params):
    print("Creating test level...")

    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/levels/TestLevel.tscn"
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    var size_x = 50.0
    var size_z = 50.0
    if params.has("size"):
        if typeof(params.size) == TYPE_ARRAY:
            if params.size.size() >= 2:
                size_x = float(params.size[0])
                size_z = float(params.size[1])
            elif params.size.size() == 1:
                size_x = float(params.size[0])
                size_z = float(params.size[0])
        else:
            # Single number - use for both dimensions
            size_x = float(params.size)
            size_z = float(params.size)

    var root = Node3D.new()
    root.name = "TestLevel"

    # World geometry container
    var world_geo = Node3D.new()
    world_geo.name = "WorldGeometry"
    root.add_child(world_geo)
    world_geo.set_owner(root)

    # Ground
    var ground = StaticBody3D.new()
    ground.name = "Ground"
    world_geo.add_child(ground)
    ground.set_owner(root)

    var ground_collision = CollisionShape3D.new()
    var ground_shape = BoxShape3D.new()
    ground_shape.size = Vector3(size_x, 0.2, size_z)
    ground_collision.shape = ground_shape
    ground_collision.position = Vector3(0, -0.1, 0)
    ground.add_child(ground_collision)
    ground_collision.set_owner(root)

    var ground_mesh = MeshInstance3D.new()
    var plane_mesh = PlaneMesh.new()
    plane_mesh.size = Vector2(size_x, size_z)
    ground_mesh.mesh = plane_mesh
    ground.add_child(ground_mesh)
    ground_mesh.set_owner(root)

    # Lighting
    var lighting = Node3D.new()
    lighting.name = "Lighting"
    root.add_child(lighting)
    lighting.set_owner(root)

    var ambient_light = OmniLight3D.new()
    ambient_light.name = "AmbientLight"
    ambient_light.light_energy = 0.5
    ambient_light.position = Vector3(0, 10, 0)
    lighting.add_child(ambient_light)
    ambient_light.set_owner(root)

    # Spawn points
    var spawn_points = Node3D.new()
    spawn_points.name = "SpawnPoints"
    root.add_child(spawn_points)
    spawn_points.set_owner(root)

    var player_spawn = Marker3D.new()
    player_spawn.name = "PlayerSpawn"
    player_spawn.position = Vector3(0, 1, 0)
    spawn_points.add_child(player_spawn)
    player_spawn.set_owner(root)

    # NPCs container
    var npcs = Node3D.new()
    npcs.name = "NPCs"
    root.add_child(npcs)
    npcs.set_owner(root)

    # Save scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)

    if result == OK:
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))

        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Test level created successfully at: " + scene_path)
            print("  - Size: " + str(size_x) + "x" + str(size_z))
        else:
            printerr("Failed to save test level: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack test level: " + str(result))
        quit(1)

# Create comprehensive mechanics test map with stealth, climbing, and bow areas
func create_mechanics_test_map(params):
    print("Creating comprehensive mechanics test map...")

    var scene_path = params.scene_path if params.has("scene_path") else "res://scenes/levels/MechanicsTestMap.tscn"
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    var root = Node3D.new()
    root.name = "MechanicsTestMap"

    # === WORLD GEOMETRY ===
    var world_geo = Node3D.new()
    world_geo.name = "WorldGeometry"
    root.add_child(world_geo)
    world_geo.set_owner(root)

    # Main ground (100x100)
    var ground = StaticBody3D.new()
    ground.name = "Ground"
    world_geo.add_child(ground)
    ground.set_owner(root)

    var ground_collision = CollisionShape3D.new()
    var ground_shape = BoxShape3D.new()
    ground_shape.size = Vector3(100, 0.2, 100)
    ground_collision.shape = ground_shape
    ground_collision.transform.origin = Vector3(0, -0.1, 0)
    ground.add_child(ground_collision)
    ground_collision.set_owner(root)

    var ground_mesh_inst = MeshInstance3D.new()
    var ground_mesh = PlaneMesh.new()
    ground_mesh.size = Vector2(100, 100)
    ground_mesh_inst.mesh = ground_mesh
    ground.add_child(ground_mesh_inst)
    ground_mesh_inst.set_owner(root)

    # === STEALTH TEST ZONE (Fenced area with guard) ===
    var stealth_zone = Node3D.new()
    stealth_zone.name = "StealthZone"
    stealth_zone.transform.origin = Vector3(-30, 0, 0)
    root.add_child(stealth_zone)
    stealth_zone.set_owner(root)

    # Fence walls (4 walls forming enclosure)
    var fence_positions = [
        Vector3(0, 1, -10),   # North wall
        Vector3(0, 1, 10),    # South wall
        Vector3(-10, 1, 0),   # West wall
        Vector3(10, 1, 0)     # East wall
    ]
    var fence_sizes = [
        Vector3(20, 2, 0.2),  # North/South
        Vector3(20, 2, 0.2),  # North/South
        Vector3(0.2, 2, 20),  # West/East
        Vector3(0.2, 2, 20)   # West/East
    ]

    for i in range(4):
        var fence = StaticBody3D.new()
        fence.name = "Fence" + str(i + 1)
        fence.transform.origin = fence_positions[i]
        stealth_zone.add_child(fence)
        fence.set_owner(root)

        var fence_collision = CollisionShape3D.new()
        var fence_shape = BoxShape3D.new()
        fence_shape.size = fence_sizes[i]
        fence_collision.shape = fence_shape
        fence.add_child(fence_collision)
        fence_collision.set_owner(root)

        var fence_mesh_inst = MeshInstance3D.new()
        var fence_mesh = BoxMesh.new()
        fence_mesh.size = fence_sizes[i]
        fence_mesh_inst.mesh = fence_mesh
        fence.add_child(fence_mesh_inst)
        fence_mesh_inst.set_owner(root)

    # Guard spawn marker inside fence
    var guard_spawn = Marker3D.new()
    guard_spawn.name = "GuardSpawn"
    guard_spawn.transform.origin = Vector3(0, 0.5, 0)
    stealth_zone.add_child(guard_spawn)
    guard_spawn.set_owner(root)

    # Cover objects (crates for hiding)
    for i in range(3):
        var crate = StaticBody3D.new()
        crate.name = "Crate" + str(i + 1)
        crate.transform.origin = Vector3(-5 + i * 5, 0.5, -5)
        stealth_zone.add_child(crate)
        crate.set_owner(root)

        var crate_collision = CollisionShape3D.new()
        var crate_shape = BoxShape3D.new()
        crate_shape.size = Vector3(2, 1, 2)
        crate_collision.shape = crate_shape
        crate.add_child(crate_collision)
        crate_collision.set_owner(root)

        var crate_mesh_inst = MeshInstance3D.new()
        var crate_mesh = BoxMesh.new()
        crate_mesh.size = Vector3(2, 1, 2)
        crate_mesh_inst.mesh = crate_mesh
        crate.add_child(crate_mesh_inst)
        crate_mesh_inst.set_owner(root)

    # === CLIMBING TEST AREA ===
    var climbing_zone = Node3D.new()
    climbing_zone.name = "ClimbingZone"
    climbing_zone.transform.origin = Vector3(30, 0, 0)
    root.add_child(climbing_zone)
    climbing_zone.set_owner(root)

    # Cliff wall
    var cliff = StaticBody3D.new()
    cliff.name = "CliffWall"
    cliff.transform.origin = Vector3(0, 5, 0)
    climbing_zone.add_child(cliff)
    cliff.set_owner(root)

    var cliff_collision = CollisionShape3D.new()
    var cliff_shape = BoxShape3D.new()
    cliff_shape.size = Vector3(15, 10, 1)
    cliff_collision.shape = cliff_shape
    cliff.add_child(cliff_collision)
    cliff_collision.set_owner(root)

    var cliff_mesh_inst = MeshInstance3D.new()
    var cliff_mesh = BoxMesh.new()
    cliff_mesh.size = Vector3(15, 10, 1)
    cliff_mesh_inst.mesh = cliff_mesh
    cliff.add_child(cliff_mesh_inst)
    cliff_mesh_inst.set_owner(root)

    # Ladder (series of platforms)
    for i in range(5):
        var ladder_rung = StaticBody3D.new()
        ladder_rung.name = "LadderRung" + str(i + 1)
        ladder_rung.transform.origin = Vector3(-8, 2 + i * 1.5, 0.6)
        climbing_zone.add_child(ladder_rung)
        ladder_rung.set_owner(root)

        var rung_collision = CollisionShape3D.new()
        var rung_shape = BoxShape3D.new()
        rung_shape.size = Vector3(1, 0.2, 0.2)
        rung_collision.shape = rung_shape
        rung_collision.transform.origin = Vector3(0, 0, 0)
        ladder_rung.add_child(rung_collision)
        rung_collision.set_owner(root)

        var rung_mesh_inst = MeshInstance3D.new()
        var rung_mesh = BoxMesh.new()
        rung_mesh.size = Vector3(1, 0.2, 0.2)
        rung_mesh_inst.mesh = rung_mesh
        ladder_rung.add_child(rung_mesh_inst)
        rung_mesh_inst.set_owner(root)

    # Rope climb point (marker with visual pole)
    var rope_pole = StaticBody3D.new()
    rope_pole.name = "RopePole"
    rope_pole.transform.origin = Vector3(0, 5, 2)
    climbing_zone.add_child(rope_pole)
    rope_pole.set_owner(root)

    var pole_collision = CollisionShape3D.new()
    var pole_shape = CapsuleShape3D.new()
    pole_shape.radius = 0.2
    pole_shape.height = 10
    pole_collision.shape = pole_shape
    rope_pole.add_child(pole_collision)
    pole_collision.set_owner(root)

    var pole_mesh_inst = MeshInstance3D.new()
    var pole_mesh = CapsuleMesh.new()
    pole_mesh.radius = 0.2
    pole_mesh.height = 10
    pole_mesh_inst.mesh = pole_mesh
    rope_pole.add_child(pole_mesh_inst)
    pole_mesh_inst.set_owner(root)

    # Upper platform
    var upper_platform = StaticBody3D.new()
    upper_platform.name = "UpperPlatform"
    upper_platform.transform.origin = Vector3(0, 10, 0)
    climbing_zone.add_child(upper_platform)
    upper_platform.set_owner(root)

    var platform_collision = CollisionShape3D.new()
    var platform_shape = BoxShape3D.new()
    platform_shape.size = Vector3(10, 0.5, 10)
    platform_collision.shape = platform_shape
    platform_collision.transform.origin = Vector3(0, 0, 0)
    upper_platform.add_child(platform_collision)
    platform_collision.set_owner(root)

    var platform_mesh_inst = MeshInstance3D.new()
    var platform_mesh = BoxMesh.new()
    platform_mesh.size = Vector3(10, 0.5, 10)
    platform_mesh_inst.mesh = platform_mesh
    upper_platform.add_child(platform_mesh_inst)
    platform_mesh_inst.set_owner(root)

    # === BOW SHOOTING RANGE ===
    var shooting_zone = Node3D.new()
    shooting_zone.name = "ShootingRange"
    shooting_zone.transform.origin = Vector3(0, 0, 30)
    root.add_child(shooting_zone)
    shooting_zone.set_owner(root)

    # Target stands at varying distances
    var target_distances = [10, 20, 30]
    for i in range(3):
        var target = StaticBody3D.new()
        target.name = "Target" + str(i + 1)
        target.transform.origin = Vector3(0, 2, target_distances[i])
        shooting_zone.add_child(target)
        target.set_owner(root)

        # Target board
        var target_collision = CollisionShape3D.new()
        var target_shape = BoxShape3D.new()
        target_shape.size = Vector3(2, 2, 0.2)
        target_collision.shape = target_shape
        target.add_child(target_collision)
        target_collision.set_owner(root)

        var target_mesh_inst = MeshInstance3D.new()
        var target_mesh = BoxMesh.new()
        target_mesh.size = Vector3(2, 2, 0.2)
        target_mesh_inst.mesh = target_mesh
        target.add_child(target_mesh_inst)
        target_mesh_inst.set_owner(root)

        # Target stand/pole
        var stand = StaticBody3D.new()
        stand.name = "TargetStand" + str(i + 1)
        stand.transform.origin = Vector3(0, 1, 0)
        target.add_child(stand)
        stand.set_owner(root)

        var stand_collision = CollisionShape3D.new()
        var stand_shape = BoxShape3D.new()
        stand_shape.size = Vector3(0.2, 2, 0.2)
        stand_collision.shape = stand_shape
        stand.add_child(stand_collision)
        stand_collision.set_owner(root)

        var stand_mesh_inst = MeshInstance3D.new()
        var stand_mesh = BoxMesh.new()
        stand_mesh.size = Vector3(0.2, 2, 0.2)
        stand_mesh_inst.mesh = stand_mesh
        stand.add_child(stand_mesh_inst)
        stand_mesh_inst.set_owner(root)

    # === LIGHTING ===
    var lighting = Node3D.new()
    lighting.name = "Lighting"
    root.add_child(lighting)
    lighting.set_owner(root)

    # Sun light
    var sun = DirectionalLight3D.new()
    sun.name = "Sun"
    sun.transform.basis = Basis(Vector3(0.8660254, 0.35355338, -0.35355338), Vector3(0, 0.70710677, 0.70710677), Vector3(0.5, -0.6123724, 0.6123724))
    sun.light_energy = 1.0
    lighting.add_child(sun)
    sun.set_owner(root)

    # Ambient light over map
    var ambient = OmniLight3D.new()
    ambient.name = "AmbientLight"
    ambient.transform.origin = Vector3(0, 20, 0)
    ambient.light_energy = 0.3
    ambient.omni_range = 100
    lighting.add_child(ambient)
    ambient.set_owner(root)

    # === SPAWN POINTS ===
    var spawns = Node3D.new()
    spawns.name = "SpawnPoints"
    root.add_child(spawns)
    spawns.set_owner(root)

    # Player spawn (near center)
    var player_spawn = Marker3D.new()
    player_spawn.name = "PlayerSpawn"
    player_spawn.transform.origin = Vector3(0, 1, -40)
    spawns.add_child(player_spawn)
    player_spawn.set_owner(root)

    # Save the scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)
    if result == OK:
        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Mechanics test map created successfully at: " + scene_path)
            print("  - Stealth Zone: Fenced area with guard spawn at (-30, 0, 0)")
            print("  - Climbing Zone: Cliff, ladder, rope at (30, 0, 0)")
            print("  - Shooting Range: 3 targets at distances 10m, 20m, 30m at (0, 0, 30)")
        else:
            printerr("Failed to save mechanics test map: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack mechanics test map: " + str(result))
        quit(1)

# Configure autoloads in project.godot
func configure_autoloads(params):
    print("Configuring autoloads in project.godot...")

    var project_path = params.project_path if params.has("project_path") else "res://"
    if not project_path.ends_with("/"):
        project_path += "/"

    var godot_project_file = project_path + "project.godot"
    if not godot_project_file.begins_with("res://"):
        godot_project_file = "res://" + godot_project_file.trim_prefix("/")

    var absolute_path = ProjectSettings.globalize_path(godot_project_file)

    if debug_mode:
        print("Project file path: " + godot_project_file)
        print("Absolute path: " + absolute_path)

    # Check if project.godot exists
    if not FileAccess.file_exists(godot_project_file):
        printerr("project.godot not found at: " + godot_project_file)
        quit(1)

    # Read existing project.godot
    var file = FileAccess.open(godot_project_file, FileAccess.READ)
    if not file:
        printerr("Failed to open project.godot: " + str(FileAccess.get_open_error()))
        quit(1)

    var content = file.get_as_text()
    file.close()

    var modified = false

    # Process autoloads
    if params.has("autoloads") and params.autoloads is Array:
        for autoload in params.autoloads:
            if not autoload.has("name") or not autoload.has("path"):
                log_error("Autoload entry missing 'name' or 'path': " + str(autoload))
                continue

            var autoload_name = autoload.name
            var autoload_path = autoload.path
            var is_singleton = autoload.singleton if autoload.has("singleton") else true

            # Format: autoload/GameBus="*res://autoloads/GameBus.gd"
            # The * prefix means it's a singleton (enabled)
            var autoload_key = "autoload/" + autoload_name
            var autoload_value = ("*" if is_singleton else "") + autoload_path
            var autoload_line = autoload_key + "=\"" + autoload_value + "\""

            if debug_mode:
                print("Processing autoload: " + autoload_name + " -> " + autoload_path)

            # Check if this autoload already exists
            var existing_pattern = "autoload/" + autoload_name + "="
            if content.find(existing_pattern) != -1:
                # Update existing autoload
                var regex = RegEx.new()
                regex.compile("autoload/" + autoload_name + "=\"[^\"]*\"")
                content = regex.sub(content, autoload_line)
                print("Updated autoload: " + autoload_name)
                modified = true
            else:
                # Add new autoload - find or create [autoload] section
                if content.find("[autoload]") == -1:
                    # Add autoload section at the end
                    content += "\n[autoload]\n\n" + autoload_line + "\n"
                else:
                    # Add after [autoload] section header
                    var autoload_pos = content.find("[autoload]")
                    var insert_pos = autoload_pos + 10  # Length of "[autoload]"
                    # Find the end of the line
                    while insert_pos < content.length() and content[insert_pos] != '\n':
                        insert_pos += 1
                    insert_pos += 1  # Move past the newline
                    content = content.substr(0, insert_pos) + autoload_line + "\n" + content.substr(insert_pos)
                print("Added autoload: " + autoload_name)
                modified = true

    # Process input actions
    if params.has("input_actions") and params.input_actions is Dictionary:
        for action_name in params.input_actions:
            var keys = params.input_actions[action_name]
            if debug_mode:
                print("Processing input action: " + action_name + " -> " + str(keys))

            # Check if [input] section exists
            if content.find("[input]") == -1:
                content += "\n[input]\n\n"

            # Check if action already exists
            var action_pattern = action_name + "="
            if content.find(action_pattern) == -1:
                # Add input action after [input] section
                var input_pos = content.find("[input]")
                var insert_pos = input_pos + 7  # Length of "[input]"
                while insert_pos < content.length() and content[insert_pos] != '\n':
                    insert_pos += 1
                insert_pos += 1

                # Build input action entry
                var events_str = "{\n"
                events_str += "\"deadzone\": 0.5,\n"
                events_str += "\"events\": ["

                var first = true
                for key in keys:
                    if not first:
                        events_str += ", "
                    first = false
                    # Convert key name to InputEventKey
                    events_str += "Object(InputEventKey,\"resource_local_to_scene\":false,\"resource_name\":\"\",\"device\":-1,\"window_id\":0,\"alt_pressed\":false,\"shift_pressed\":false,\"ctrl_pressed\":false,\"meta_pressed\":false,\"pressed\":false,\"keycode\":0,\"physical_keycode\":" + str(get_key_code(key)) + ",\"key_label\":0,\"unicode\":0,\"location\":0,\"echo\":false,\"script\":null)"
                events_str += "]\n}"

                var action_line = action_name + "=" + events_str + "\n"
                content = content.substr(0, insert_pos) + action_line + content.substr(insert_pos)
                print("Added input action: " + action_name)
                modified = true

    # Process physics layers
    if params.has("physics_layers") and params.physics_layers is Dictionary:
        for layer_num in params.physics_layers:
            var layer_name = params.physics_layers[layer_num]
            var layer_key = "layer_names/3d_physics/layer_" + str(layer_num)

            if debug_mode:
                print("Processing physics layer: " + layer_num + " -> " + layer_name)

            # Check if layer already defined
            if content.find(layer_key) == -1:
                # Find or create layer_names section
                if content.find("[layer_names]") == -1:
                    content += "\n[layer_names]\n\n"

                var layer_pos = content.find("[layer_names]")
                var insert_pos = layer_pos + 13  # Length of "[layer_names]"
                while insert_pos < content.length() and content[insert_pos] != '\n':
                    insert_pos += 1
                insert_pos += 1

                var layer_line = layer_key + "=\"" + layer_name + "\"\n"
                content = content.substr(0, insert_pos) + layer_line + content.substr(insert_pos)
                print("Added physics layer: " + layer_num + " = " + layer_name)
                modified = true

    # Write back if modified
    if modified:
        var write_file = FileAccess.open(godot_project_file, FileAccess.WRITE)
        if not write_file:
            printerr("Failed to write project.godot: " + str(FileAccess.get_open_error()))
            quit(1)

        write_file.store_string(content)
        write_file.close()
        print("project.godot updated successfully")
    else:
        print("No changes needed to project.godot")

# Helper function to get key code from string
func get_key_code(key_string: String) -> int:
    # Common key mappings
    var key_map = {
        "KEY_ESCAPE": 4194305,
        "KEY_F1": 4194332,
        "KEY_F2": 4194333,
        "KEY_F3": 4194334,
        "KEY_F4": 4194335,
        "KEY_F5": 4194336,
        "KEY_F6": 4194337,
        "KEY_F7": 4194338,
        "KEY_F8": 4194339,
        "KEY_F9": 4194340,
        "KEY_F10": 4194341,
        "KEY_F11": 4194342,
        "KEY_F12": 4194343,
        "KEY_SPACE": 32,
        "KEY_ENTER": 4194309,
        "KEY_TAB": 4194306,
        "KEY_SHIFT": 4194325,
        "KEY_CTRL": 4194326,
        "KEY_ALT": 4194328,
    }

    if key_map.has(key_string):
        return key_map[key_string]

    # Try to get ASCII code for single character keys
    if key_string.length() == 1:
        return key_string.unicode_at(0)

    # Default
    return 0

# Add patrol waypoints to an NPC scene
func add_patrol_waypoints(params):
    print("Adding patrol waypoints to NPC...")

    if not params.has("scene_path"):
        printerr("scene_path is required")
        quit(1)

    var scene_path = params.scene_path
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    if debug_mode:
        print("Scene path: " + scene_path)

    # Load the scene
    if not FileAccess.file_exists(scene_path):
        printerr("Scene file not found: " + scene_path)
        quit(1)

    var scene = load(scene_path)
    if not scene:
        printerr("Failed to load scene: " + scene_path)
        quit(1)

    var scene_root = scene.instantiate()

    # Get or create PatrolPath node
    var patrol_path = scene_root.get_node_or_null("PatrolPath")
    if not patrol_path:
        patrol_path = Path3D.new()
        patrol_path.name = "PatrolPath"
        scene_root.add_child(patrol_path)
        patrol_path.set_owner(scene_root)
        if debug_mode:
            print("Created PatrolPath node")

    # Create the curve if it doesn't exist
    if not patrol_path.curve:
        patrol_path.curve = Curve3D.new()

    # Clear existing points if requested
    if params.has("clear_existing") and params.clear_existing:
        patrol_path.curve.clear_points()
        if debug_mode:
            print("Cleared existing waypoints")

    # Add waypoints
    if params.has("waypoints") and params.waypoints is Array:
        var waypoint_count = 0
        for waypoint in params.waypoints:
            var position = Vector3.ZERO
            if waypoint is Array and waypoint.size() >= 3:
                position = Vector3(float(waypoint[0]), float(waypoint[1]), float(waypoint[2]))
            elif waypoint is Dictionary:
                position = Vector3(
                    float(waypoint.x) if waypoint.has("x") else 0.0,
                    float(waypoint.y) if waypoint.has("y") else 0.0,
                    float(waypoint.z) if waypoint.has("z") else 0.0
                )

            patrol_path.curve.add_point(position)
            waypoint_count += 1
            if debug_mode:
                print("Added waypoint: " + str(position))

        print("Added " + str(waypoint_count) + " patrol waypoints")

    # Also create waypoint markers for visual reference
    if params.has("create_markers") and params.create_markers:
        var markers_container = scene_root.get_node_or_null("PatrolMarkers")
        if not markers_container:
            markers_container = Node3D.new()
            markers_container.name = "PatrolMarkers"
            scene_root.add_child(markers_container)
            markers_container.set_owner(scene_root)

        # Clear existing markers
        for child in markers_container.get_children():
            child.queue_free()

        # Create marker for each point
        for i in range(patrol_path.curve.point_count):
            var marker = Marker3D.new()
            marker.name = "Waypoint" + str(i + 1)
            marker.position = patrol_path.curve.get_point_position(i)
            markers_container.add_child(marker)
            marker.set_owner(scene_root)

    # Set patrol-related metadata if provided
    if params.has("loop") and patrol_path:
        patrol_path.set_meta("patrol_loop", params.loop)
    if params.has("wait_time"):
        patrol_path.set_meta("patrol_wait_time", params.wait_time)
    if params.has("speed"):
        patrol_path.set_meta("patrol_speed", params.speed)

    # Save the scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)

    if result == OK:
        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Patrol waypoints added successfully to: " + scene_path)
        else:
            printerr("Failed to save scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack scene: " + str(result))
        quit(1)

# Setup system groups for service discovery
func setup_system_groups(params):
    print("Setting up system groups...")

    if not params.has("scene_path"):
        printerr("scene_path is required")
        quit(1)

    var scene_path = params.scene_path
    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    if debug_mode:
        print("Scene path: " + scene_path)

    # Load the scene
    if not FileAccess.file_exists(scene_path):
        printerr("Scene file not found: " + scene_path)
        quit(1)

    var scene = load(scene_path)
    if not scene:
        printerr("Failed to load scene: " + scene_path)
        quit(1)

    var scene_root = scene.instantiate()

    # Process group assignments
    if params.has("groups") and params.groups is Dictionary:
        var groups_added = 0
        for node_path in params.groups:
            var group_names = params.groups[node_path]

            # Find the node
            var node = scene_root.get_node_or_null(node_path)
            if not node:
                log_error("Node not found: " + node_path)
                continue

            # Add groups
            if group_names is Array:
                for group_name in group_names:
                    node.add_to_group(group_name)
                    groups_added += 1
                    if debug_mode:
                        print("Added " + node.name + " to group: " + group_name)
            elif group_names is String:
                node.add_to_group(group_names)
                groups_added += 1
                if debug_mode:
                    print("Added " + node.name + " to group: " + group_names)

        print("Added " + str(groups_added) + " group assignments")

    # Process service tags (metadata for service discovery)
    if params.has("services") and params.services is Dictionary:
        var services_tagged = 0
        for node_path in params.services:
            var service_info = params.services[node_path]

            var node = scene_root.get_node_or_null(node_path)
            if not node:
                log_error("Node not found for service: " + node_path)
                continue

            # Set service metadata
            if service_info is Dictionary:
                for key in service_info:
                    node.set_meta("svc_" + key, service_info[key])
                    if debug_mode:
                        print("Set service meta on " + node.name + ": svc_" + key + " = " + str(service_info[key]))
            elif service_info is String:
                node.set_meta("service_type", service_info)
                if debug_mode:
                    print("Set service type on " + node.name + ": " + service_info)

            services_tagged += 1

        print("Tagged " + str(services_tagged) + " services")

    # Save the scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(scene_root)

    if result == OK:
        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("System groups configured successfully for: " + scene_path)
        else:
            printerr("Failed to save scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack scene: " + str(result))
        quit(1)

# Create a scene from a JSON template
func create_from_template(params):
    print("Creating scene from template...")

    if not params.has("template_path"):
        printerr("template_path is required")
        quit(1)

    var template_path = params.template_path
    if not template_path.begins_with("res://"):
        template_path = "res://" + template_path

    if debug_mode:
        print("Template path: " + template_path)

    # Load the template JSON
    if not FileAccess.file_exists(template_path):
        printerr("Template file not found: " + template_path)
        quit(1)

    var file = FileAccess.open(template_path, FileAccess.READ)
    if not file:
        printerr("Failed to open template: " + str(FileAccess.get_open_error()))
        quit(1)

    var json_text = file.get_as_text()
    file.close()

    # Parse JSON
    var json = JSON.new()
    var error = json.parse(json_text)
    if error != OK:
        printerr("Failed to parse template JSON: " + json.get_error_message())
        quit(1)

    var template = json.get_data()

    # Get scene path from template or params
    var scene_path = params.scene_path if params.has("scene_path") else template.scene_path if template.has("scene_path") else null
    if not scene_path:
        printerr("No scene_path specified in params or template")
        quit(1)

    if not scene_path.begins_with("res://"):
        scene_path = "res://" + scene_path

    if debug_mode:
        print("Output scene path: " + scene_path)

    # Build the scene from template
    if not template.has("root_node"):
        printerr("Template missing 'root_node' definition")
        quit(1)

    var root = _create_node_from_template(template.root_node, null)
    if not root:
        printerr("Failed to create root node from template")
        quit(1)

    # Apply variable substitutions if provided
    if params.has("variables") and params.variables is Dictionary:
        _apply_template_variables(root, params.variables)

    # Save the scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root)

    if result == OK:
        # Ensure directory exists
        var scene_dir = scene_path.get_base_dir()
        if scene_dir != "res://":
            var dir = DirAccess.open("res://")
            if dir:
                dir.make_dir_recursive(scene_dir.substr(6))

        var save_error = ResourceSaver.save(packed_scene, scene_path)
        if save_error == OK:
            print("Scene created from template successfully at: " + scene_path)
        else:
            printerr("Failed to save scene: " + str(save_error))
            quit(1)
    else:
        printerr("Failed to pack scene: " + str(result))
        quit(1)

# Helper: Create a node tree from template definition
func _create_node_from_template(node_def: Dictionary, owner_node) -> Node:
    if not node_def.has("type"):
        log_error("Node definition missing 'type'")
        return null

    var node = instantiate_class(node_def.type)
    if not node:
        log_error("Failed to instantiate node type: " + node_def.type)
        return null

    # Set name
    if node_def.has("name"):
        node.name = node_def.name

    # Determine the owner (root node owns itself, others get owner_node)
    var actual_owner = owner_node if owner_node else node

    # Set properties/exports
    if node_def.has("properties"):
        for prop_name in node_def.properties:
            var prop_value = node_def.properties[prop_name]
            _set_node_property(node, prop_name, prop_value)

    if node_def.has("exports"):
        for export_name in node_def.exports:
            var export_value = node_def.exports[export_name]
            _set_node_property(node, export_name, export_value)

    # Set transform if provided
    if node_def.has("position") and node is Node3D:
        var pos = node_def.position
        if pos is Array and pos.size() >= 3:
            node.position = Vector3(pos[0], pos[1], pos[2])
        elif pos is Dictionary:
            node.position = Vector3(
                pos.x if pos.has("x") else 0,
                pos.y if pos.has("y") else 0,
                pos.z if pos.has("z") else 0
            )

    if node_def.has("rotation_degrees") and node is Node3D:
        var rot = node_def.rotation_degrees
        if rot is Array and rot.size() >= 3:
            node.rotation_degrees = Vector3(rot[0], rot[1], rot[2])

    if node_def.has("scale") and node is Node3D:
        var scl = node_def.scale
        if scl is Array and scl.size() >= 3:
            node.scale = Vector3(scl[0], scl[1], scl[2])

    # Set script if provided
    if node_def.has("script"):
        var script_path = node_def.script
        if ResourceLoader.exists(script_path):
            var script = load(script_path)
            if script:
                node.set_script(script)

    # Add to groups
    if node_def.has("groups"):
        var groups = node_def.groups
        if groups is Array:
            for group_name in groups:
                node.add_to_group(group_name)
        elif groups is String:
            node.add_to_group(groups)

    # Process children
    if node_def.has("children") and node_def.children is Array:
        for child_def in node_def.children:
            var child = _create_node_from_template(child_def, actual_owner)
            if child:
                node.add_child(child)
                child.set_owner(actual_owner)

    return node

# Helper: Set a property on a node with type conversion
func _set_node_property(node: Node, prop_name: String, value):
    # Handle special property types
    if prop_name == "color" and value is Array and value.size() >= 3:
        var alpha = value[3] if value.size() > 3 else 1.0
        node.set(prop_name, Color(value[0], value[1], value[2], alpha))
    elif prop_name.ends_with("_color") and value is Array:
        var alpha = value[3] if value.size() > 3 else 1.0
        node.set(prop_name, Color(value[0], value[1], value[2], alpha))
    elif (prop_name == "position" or prop_name == "size") and value is Array:
        if value.size() == 2:
            node.set(prop_name, Vector2(value[0], value[1]))
        elif value.size() == 3:
            node.set(prop_name, Vector3(value[0], value[1], value[2]))
    else:
        node.set(prop_name, value)

# Helper: Apply variable substitutions to node properties
func _apply_template_variables(node: Node, variables: Dictionary):
    # This would need to be expanded for complex use cases
    # For now, just recurse through children
    for child in node.get_children():
        _apply_template_variables(child, variables)
