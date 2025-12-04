# Godot MCP - Shadows of the Moth Fork

This is a fork of [godot-mcp](https://github.com/Coding-Solo/godot-mcp) adapted for the **Shadows of the Moth** game project and optimized for Godot 4.5 + Qwen3-Coder-30B integration.

---

## What's Different in This Fork

### 1. **Godot 4.5 Compatibility**
- Version checks for Godot 4.5+
- Tested with Godot 4.5 stable
- All operations verified against 4.5 API

### 2. **Shadows of the Moth Operations**
Custom operations for our game project:

- `create_hud_scene`: Creates UI.tscn with complete HUD hierarchy
- `create_main_scene`: Creates Main.tscn with all system managers
- `create_player_scene`: Creates Player.tscn with movement and camera
- `create_npc_scene`: Creates NPC.tscn with AI and perception
- `create_test_level`: Creates TestLevel.tscn with geometry and spawn points
- `configure_autoloads`: Modifies project.godot with autoloads and settings
- `add_patrol_waypoints`: Adds patrol waypoints to NPCs
- `setup_system_groups`: Adds nodes to service discovery groups

### 3. **Qwen Tool Proxy Integration**
- HTTP bridge for qwen-tool-proxy.py
- Simplified JSON-based API
- Batch operation support
- Error reporting optimized for LLM understanding

### 4. **Scene Templates**
JSON templates for common scenes:
- `/templates/main_scene.json`
- `/templates/ui_scene.json`
- `/templates/player_scene.json`
- `/templates/npc_scene.json`
- `/templates/test_level.json`

### 5. **Validation Scripts**
- `validate_scene.gd`: Verify scene structure
- `test_operations.sh`: Test all operations
- `check_compatibility.gd`: Verify Godot version and APIs

---

## Quick Start

### 1. Install Dependencies
```bash
npm install
npm run build
```

### 2. Test Godot 4.5 Compatibility
```bash
# Verify Godot 4.5+ installed
godot --version

# Test basic operation
godot --headless --script build/scripts/godot_operations.gd create_scene \
  '{"scene_path":"res://test.tscn","root_node_type":"Node"}'
```

### 3. Create Shadows of the Moth Scenes
```bash
# Create Main scene
godot --headless --script build/scripts/godot_operations.gd create_main_scene \
  '{"project_path":"../Shadows_of_the_Moth","scene_path":"res://scenes/Main.tscn"}'

# Create UI scene
godot --headless --script build/scripts/godot_operations.gd create_hud_scene \
  '{"project_path":"../Shadows_of_the_Moth","scene_path":"res://scenes/ui/UI.tscn"}'

# Create Player scene
godot --headless --script build/scripts/godot_operations.gd create_player_scene \
  '{"project_path":"../Shadows_of_the_Moth","scene_path":"res://scenes/player/Player.tscn"}'
```

### 4. Use with Qwen Tool Proxy
```python
# In qwen-tool-proxy.py
import requests

response = requests.post("http://localhost:3000/godot/create_scene", json={
    "operation": "create_main_scene",
    "params": {
        "project_path": "/path/to/Shadows_of_the_Moth",
        "scene_path": "res://scenes/Main.tscn"
    }
})

print(response.json())
```

---

## Custom Operations Documentation

### `create_hud_scene`

Creates a complete HUD scene with all UI elements.

**Parameters**:
```json
{
  "scene_path": "res://scenes/ui/UI.tscn",
  "hud_script": "res://scripts/ui/HUD.gd",
  "pause_menu_script": "res://scripts/ui/PauseMenu.gd",
  "ui_manager_script": "res://scripts/ui/UIManager.gd"
}
```

**Structure Created**:
```
UI (CanvasLayer)
├── HUD (Control)
│   ├── TopBar (HBoxContainer)
│   │   ├── HarmonyPanel (PanelContainer)
│   │   ├── SanityPanel (PanelContainer)
│   │   └── FocusPanel (PanelContainer)
│   ├── CenterInfo (CenterContainer)
│   └── BottomBar (HBoxContainer)
├── Menus (Control)
│   └── PauseMenu (PanelContainer)
└── DebugOverlay (CanvasLayer)
```

### `create_main_scene`

Creates the main game scene with all system managers.

**Parameters**:
```json
{
  "scene_path": "res://scenes/Main.tscn",
  "ui_scene_path": "res://scenes/ui/UI.tscn"
}
```

**Structure Created**:
```
Main (Node)
├── WorldSystems (Node)
│   ├── TimeManager (svc_time)
│   ├── WeatherManager (svc_weather)
│   ├── LightManager
│   └── SkyController
├── AISystems (Node)
│   ├── NavigationGrid (svc_navigation)
│   └── SquadManager (svc_squad)
├── StealthSystems (Node)
├── WorldEnvironment
└── UI (Instance)
```

### `create_player_scene`

Creates player character with movement and camera.

**Parameters**:
```json
{
  "scene_path": "res://scenes/player/Player.tscn",
  "controller_script": "res://refs/ShadowsOfTheMoth/Scripts/Game/PlayerController.gd"
}
```

### `create_npc_scene`

Creates NPC with AI controller and perception.

**Parameters**:
```json
{
  "scene_path": "res://scenes/npc/NPC.tscn",
  "controller_script": "res://scripts/actors/npc/NPCController.gd",
  "patrol_waypoints": [
    [10.0, 0.0, 10.0],
    [10.0, 0.0, -10.0],
    [-10.0, 0.0, -10.0],
    [-10.0, 0.0, 10.0]
  ]
}
```

### `configure_autoloads`

Modifies project.godot with autoloads and settings.

**Parameters**:
```json
{
  "autoloads": [
    {
      "name": "GameBus",
      "path": "res://autoloads/GameBus.gd",
      "singleton": true
    },
    {
      "name": "HarmonyManager",
      "path": "res://core/systems/harmony_manager.gd",
      "singleton": true
    }
  ],
  "input_actions": {
    "pause": ["KEY_ESCAPE"],
    "debug_toggle": ["KEY_F3"]
  },
  "physics_layers": {
    "1": "World",
    "2": "Player",
    "3": "NPC"
  }
}
```

---

## Template System

Templates are JSON files describing scene structure. Example:

```json
{
  "scene_path": "res://scenes/Main.tscn",
  "root_node": {
    "type": "Node",
    "name": "Main",
    "children": [
      {
        "type": "Node",
        "name": "WorldSystems",
        "children": [
          {
            "type": "Node",
            "name": "TimeManager",
            "script": "res://scripts/systems/world/TimeManager.gd",
            "groups": ["svc_time"],
            "exports": {
              "seconds_per_day": 21600.0,
              "current_hour": 12.0
            }
          }
        ]
      }
    ]
  }
}
```

Use with `create_from_template` operation:

```bash
godot --headless --script build/scripts/godot_operations.gd create_from_template \
  '{"template_path":"templates/main_scene.json"}'
```

---

## Testing

### Run All Tests
```bash
./test_operations.sh
```

### Test Individual Operations
```bash
# Test scene creation
npm run test:create-scene

# Test node addition
npm run test:add-node

# Test template system
npm run test:templates
```

### Validation
```bash
# Validate scene structure
godot --headless --script build/scripts/validate_scene.gd \
  res://scenes/Main.tscn
```

---

## Integration with Qwen

### Setup qwen-tool-proxy Bridge

Add to `qwen-tool-proxy.py`:

```python
from flask import Flask, request, jsonify
import subprocess
import json

app = Flask(__name__)

@app.route('/godot/operation', methods=['POST'])
def godot_operation():
    data = request.json
    operation = data.get('operation')
    params = data.get('params', {})

    # Build command
    cmd = [
        'godot',
        '--headless',
        '--script',
        './godot-mcp-shadows/build/scripts/godot_operations.gd',
        operation,
        json.dumps(params)
    ]

    # Execute
    result = subprocess.run(cmd, capture_output=True, text=True)

    return jsonify({
        'success': result.returncode == 0,
        'stdout': result.stdout,
        'stderr': result.stderr
    })
```

### Example Qwen Workflow

**User**: "Create the main scene with all system managers"

**Qwen**:
1. Calls `create_godot_scene` tool
2. Tool proxy forwards to godot-mcp
3. Scene created, output returned
4. Qwen reports success to user

---

## Development

### Adding New Operations

1. **Add to `godot_operations.gd`**:
```gdscript
func my_custom_operation(params):
    log_info("Running my_custom_operation")
    # Implementation here
    quit(0)
```

2. **Add to match statement**:
```gdscript
match operation:
    "my_custom_operation":
        my_custom_operation(params)
```

3. **Test**:
```bash
godot --headless --script build/scripts/godot_operations.gd my_custom_operation \
  '{"param1":"value1"}'
```

### Building

```bash
npm run build
```

Compiles TypeScript and bundles `godot_operations.gd` into `build/`.

---

## Upstream Synchronization

To pull updates from original godot-mcp:

```bash
# Add upstream if not already added
git remote add upstream https://github.com/Coding-Solo/godot-mcp.git

# Fetch upstream changes
git fetch upstream

# Merge upstream main into your branch
git merge upstream/main

# Resolve conflicts if any
# Test to ensure custom operations still work
npm run build
./test_operations.sh

# Push to your fork
git push origin main
```

---

## Project Structure

```
godot-mcp-shadows/
├── src/
│   ├── index.ts                    # MCP server (from upstream)
│   └── scripts/
│       └── godot_operations.gd     # GDScript operations (extended)
├── templates/                      # Scene JSON templates (new)
│   ├── main_scene.json
│   ├── ui_scene.json
│   ├── player_scene.json
│   └── npc_scene.json
├── tests/                          # Test scripts (new)
│   ├── validate_scene.gd
│   └── test_operations.sh
├── package.json
├── tsconfig.json
├── README.md                       # Original README
└── README_FORK.md                  # This file
```

---

## Contributing

This fork is specific to Shadows of the Moth, but contributions are welcome for:
- Bug fixes
- Godot 4.5+ compatibility improvements
- General-purpose operations
- Documentation improvements

For Shadows of the Moth-specific operations, see the main project repo.

---

## License

MIT License (same as original godot-mcp)

---

## Credits

- **Original godot-mcp**: [Coding-Solo](https://github.com/Coding-Solo/godot-mcp)
- **Shadows of the Moth Fork**: Adapted for game-specific operations and Qwen integration
- **Godot Engine**: https://godotengine.org/

---

## Links

- **Upstream**: https://github.com/Coding-Solo/godot-mcp
- **Shadows of the Moth**: (your game repo link here)
- **Integration Docs**: `../Shadows_of_the_Moth/docs/GODOT_MCP_INTEGRATION.md`
