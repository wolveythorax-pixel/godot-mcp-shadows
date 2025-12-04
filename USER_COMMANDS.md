# User Commands for Godot MCP

## Overview

This document describes user-facing commands that can be used in OpenCode/Claude Code to directly control Godot operations. These commands allow users to explicitly instruct the agent to perform specific Godot tasks rather than relying on the agent to infer when to use godot-mcp.

---

## Command Structure

Users give natural language commands that map to specific godot-mcp operations:

**User Command** → **Agent understands** → **Calls godot-mcp tool** → **Godot executes**

---

## Available Commands

### 1. Scene Creation Commands

#### Create Main Scene
**User says**:
- "Create the main scene with all system managers"
- "Generate Main.tscn"
- "Set up the main game scene"

**Agent calls**:
```typescript
godot_mcp.create_main_scene({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/Main.tscn"
})
```

#### Create UI Scene
**User says**:
- "Create the UI scene with HUD"
- "Generate UI.tscn"
- "Build the user interface scene"

**Agent calls**:
```typescript
godot_mcp.create_hud_scene({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/ui/UI.tscn",
  hud_script: "res://scripts/ui/HUD.gd"
})
```

#### Create Player Scene
**User says**:
- "Create the player scene"
- "Generate Player.tscn with movement and camera"
- "Set up player character"

**Agent calls**:
```typescript
godot_mcp.create_player_scene({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/player/Player.tscn",
  controller_script: "res://refs/ShadowsOfTheMoth/Scripts/Game/PlayerController.gd"
})
```

#### Create NPC Scene
**User says**:
- "Create an NPC scene with patrol waypoints at [10,0,10], [10,0,-10], [-10,0,-10], [-10,0,10]"
- "Generate NPC.tscn"
- "Set up enemy guard with AI"

**Agent calls**:
```typescript
godot_mcp.create_npc_scene({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/npc/NPC.tscn",
  patrol_waypoints: [
    [10.0, 0.0, 10.0],
    [10.0, 0.0, -10.0],
    [-10.0, 0.0, -10.0],
    [-10.0, 0.0, 10.0]
  ]
})
```

#### Create Test Level
**User says**:
- "Create a test level with ground and walls"
- "Generate TestLevel.tscn"
- "Set up testing environment"

**Agent calls**:
```typescript
godot_mcp.create_test_level({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/levels/TestLevel.tscn",
  size: [50, 50],
  include_player: true,
  include_npc: true
})
```

---

### 2. Scene Modification Commands

#### Add Node to Scene
**User says**:
- "Add a DirectionalLight3D called SunLight to Main.tscn at WorldSystems/LightManager"
- "Insert a Node3D named Enemies under the level root"

**Agent calls**:
```typescript
godot_mcp.add_node({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/Main.tscn",
  parent_node_path: "Main/WorldSystems/LightManager",
  node_type: "DirectionalLight3D",
  node_name: "SunLight"
})
```

#### Add Patrol Waypoints
**User says**:
- "Add patrol waypoints to NPC01 at positions [5,0,5], [5,0,-5], [-5,0,-5], [-5,0,5]"
- "Set up patrol path for the guard"

**Agent calls**:
```typescript
godot_mcp.add_patrol_waypoints({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/levels/TestLevel.tscn",
  npc_node_path: "TestLevel/NPCs/NPC01",
  waypoints: [
    [5.0, 0.0, 5.0],
    [5.0, 0.0, -5.0],
    [-5.0, 0.0, -5.0],
    [-5.0, 0.0, 5.0]
  ]
})
```

---

### 3. Project Configuration Commands

#### Configure Autoloads
**User says**:
- "Set up GameBus and HarmonyManager as autoloads"
- "Configure the project autoloads"
- "Add FocusManager to autoloads"

**Agent calls**:
```typescript
godot_mcp.configure_autoloads({
  project_path: "/path/to/Shadows_of_the_Moth",
  autoloads: [
    {
      name: "GameBus",
      path: "res://autoloads/GameBus.gd",
      singleton: true
    },
    {
      name: "HarmonyManager",
      path: "res://core/systems/harmony_manager.gd",
      singleton: true
    },
    {
      name: "FocusManager",
      path: "res://core/systems/focus_manager.gd",
      singleton: true
    }
  ]
})
```

#### Configure Input Actions
**User says**:
- "Set up input actions for pause (Escape), debug toggle (F3), and interact (E)"
- "Configure input mappings"

**Agent calls**:
```typescript
godot_mcp.configure_autoloads({
  project_path: "/path/to/Shadows_of_the_Moth",
  input_actions: {
    "pause": ["KEY_ESCAPE"],
    "debug_toggle": ["KEY_F3"],
    "interact": ["KEY_E"],
    "focus_mode": ["KEY_F"]
  }
})
```

---

### 4. Scene Inspection Commands

#### Get Scene Structure
**User says**:
- "Show me the structure of Main.tscn"
- "What's in the Main scene?"
- "List all nodes in UI.tscn"

**Agent calls**:
```typescript
godot_mcp.get_scene_structure({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/Main.tscn"
})
```

**Returns**:
```json
{
  "scene_path": "res://scenes/Main.tscn",
  "root": {
    "type": "Node",
    "name": "Main",
    "children": [
      {
        "type": "Node",
        "name": "WorldSystems",
        "children": [
          {"type": "Node", "name": "TimeManager", "groups": ["svc_time"]},
          {"type": "Node", "name": "WeatherManager", "groups": ["svc_weather"]}
        ]
      }
    ]
  }
}
```

#### Get Node Properties
**User says**:
- "What properties does TimeManager have?"
- "Show me the exports on NPCController"

**Agent calls**:
```typescript
godot_mcp.get_node_properties({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/Main.tscn",
  node_path: "Main/WorldSystems/TimeManager"
})
```

---

### 5. Template-Based Commands

#### Create from Template
**User says**:
- "Create scenes from the main scene template"
- "Use the UI template to generate the interface"
- "Build all scenes from templates"

**Agent calls**:
```typescript
godot_mcp.create_from_template({
  project_path: "/path/to/Shadows_of_the_Moth",
  template_path: "templates/main_scene.json"
})
```

---

### 6. Batch Operations

#### Create All Core Scenes
**User says**:
- "Create all the core game scenes (Main, UI, Player, NPC, TestLevel)"
- "Generate the complete scene hierarchy"
- "Build all scenes from the scene assembly guide"

**Agent calls**:
```typescript
godot_mcp.batch_create_scenes({
  project_path: "/path/to/Shadows_of_the_Moth",
  scenes: [
    "main_scene",
    "ui_scene",
    "player_scene",
    "npc_scene",
    "test_level"
  ]
})
```

---

### 7. Validation Commands

#### Validate Scene Structure
**User says**:
- "Validate that Main.tscn has all required nodes"
- "Check if the scene structure is correct"
- "Verify UI.tscn follows the architecture"

**Agent calls**:
```typescript
godot_mcp.validate_scene({
  project_path: "/path/to/Shadows_of_the_Moth",
  scene_path: "res://scenes/Main.tscn",
  validation_rules: "strict" // or "permissive"
})
```

**Returns**:
```json
{
  "valid": true,
  "errors": [],
  "warnings": ["TimeManager missing export: speed_scale"],
  "missing_nodes": [],
  "missing_groups": []
}
```

---

## Command Patterns

### Pattern 1: Direct Scene Creation
```
User: "Create [scene_type] at [path]"
→ Agent creates scene with default configuration
```

### Pattern 2: Scene Creation with Customization
```
User: "Create [scene_type] at [path] with [specific configuration]"
→ Agent creates scene with custom parameters
```

### Pattern 3: Scene Modification
```
User: "Add [node_type] called [name] to [scene] at [parent_path]"
→ Agent modifies existing scene
```

### Pattern 4: Configuration
```
User: "Configure [setting_type] with [values]"
→ Agent modifies project.godot or scene properties
```

### Pattern 5: Inspection
```
User: "Show me [what] in [scene/node]"
→ Agent retrieves and displays structure/properties
```

### Pattern 6: Validation
```
User: "Validate [scene] against [rules/architecture]"
→ Agent checks scene conforms to expectations
```

---

## Integration with OpenCode

### Adding Commands to MCP Configuration

In your OpenCode MCP configuration, these commands become available as tools that the agent can call when the user requests them.

**Example `.opencode/mcp.json`**:
```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/path/to/godot-mcp-shadows/build/index.js"],
      "env": {
        "GODOT_PATH": "/usr/local/bin/godot",
        "PROJECT_PATH": "/home/justin/Desktop/projects_Copy/Shadows_of_the_Moth"
      }
    }
  }
}
```

### Agent Behavior

When configured, OpenCode/Claude Code will:

1. **Understand natural language commands** that map to Godot operations
2. **Automatically call the appropriate godot-mcp tool** when user requests it
3. **Show the user the results** (scene created, nodes added, etc.)
4. **Handle errors gracefully** (missing files, invalid paths, etc.)

---

## Example Workflows

### Workflow 1: Create Complete Game Structure

**User**: "Create all the core scenes for the game following the scene architecture guide"

**Agent**:
1. Reads `docs/SCENE_ARCHITECTURE.md`
2. Calls `create_main_scene`
3. Calls `create_ui_scene`
4. Calls `create_player_scene`
5. Calls `create_npc_scene`
6. Calls `create_test_level`
7. Reports: "All core scenes created successfully! You can now open Main.tscn in Godot."

### Workflow 2: Add NPC with Custom Patrol

**User**: "Add a guard NPC to TestLevel that patrols around the perimeter"

**Agent**:
1. Reads TestLevel.tscn structure
2. Calculates perimeter waypoints based on level size
3. Calls `add_node` to instance NPC.tscn
4. Calls `add_patrol_waypoints` with calculated points
5. Reports: "Added Guard01 NPC with 8-point perimeter patrol"

### Workflow 3: Verify Scene Structure

**User**: "Make sure Main.tscn has all the required system managers"

**Agent**:
1. Calls `get_scene_structure` on Main.tscn
2. Compares against SCENE_ARCHITECTURE.md requirements
3. Reports missing nodes/groups if any
4. Suggests fixes: "Missing: SquadManager. Would you like me to add it?"

---

## Error Handling

### Common User Command Errors

**Problem**: User gives ambiguous command
```
User: "Create the scene"
```

**Agent Response**:
"Which scene would you like me to create? Options:
- Main scene (Main.tscn)
- UI scene (UI.tscn)
- Player scene (Player.tscn)
- NPC scene (NPC.tscn)
- Test level (TestLevel.tscn)"

---

**Problem**: Scene already exists
```
User: "Create Main.tscn"
```

**Agent Response**:
"Main.tscn already exists. Would you like me to:
1. Overwrite it (⚠️ will lose existing changes)
2. Create Main_new.tscn instead
3. Show current structure
4. Cancel"

---

**Problem**: Missing dependencies
```
User: "Add NPCController script to NPC.tscn"
```

**Agent Response**:
"Error: Script not found at res://scripts/actors/npc/NPCController.gd
Would you like me to:
1. Create the script first
2. Use a different script path
3. Skip script attachment"

---

## Command Aliases

Users can use natural variations:

### "Create" Aliases
- Create / Generate / Build / Make / Set up

### "Add" Aliases
- Add / Insert / Place / Attach

### "Show" Aliases
- Show / Display / List / Get / Inspect

### "Validate" Aliases
- Validate / Check / Verify / Test

---

## Advanced Commands

### Conditional Creation
**User**: "Create Main.tscn only if it doesn't exist"

**Agent**: Checks existence first, creates if absent

### Incremental Building
**User**: "Add TimeManager to Main.tscn, then connect it to the UI"

**Agent**: Performs multi-step operation with validation between steps

### Template Customization
**User**: "Create UI.tscn from template but change the harmony bar to vertical"

**Agent**: Loads template, modifies parameters, creates scene

---

## Best Practices

### For Users

1. **Be specific about paths**: "Create scenes/ui/UI.tscn" vs "Create the UI"
2. **Mention if scene exists**: "Recreate Main.tscn" vs "Create Main.tscn"
3. **Specify coordinates clearly**: Use array format `[x, y, z]` for waypoints
4. **Reference the architecture**: "following SCENE_ARCHITECTURE.md"

### For Agents

1. **Always verify paths exist** before attempting operations
2. **Show user what will happen** before destructive operations
3. **Validate scene structure** after creation
4. **Provide next steps**: "Scene created. You can now..."

---

## Testing Commands

Users can test commands safely:

**User**: "Test creating Main.tscn (don't actually create it, just show what you would do)"

**Agent**: Performs dry-run, shows planned operations without executing

---

## Summary

These user commands allow direct control over godot-mcp operations through natural language in OpenCode/Claude Code. The agent interprets user intent and calls the appropriate MCP tools, providing a seamless workflow for Godot scene automation without leaving the chat interface.

**Key Benefits**:
- ✅ No need to learn MCP tool syntax
- ✅ Natural language interface
- ✅ Agent handles parameter mapping
- ✅ Validation and error handling built-in
- ✅ Works with OpenCode/Claude Code MCP integration
