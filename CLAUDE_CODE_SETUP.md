# Claude Code Integration Guide

This guide explains how to use godot-mcp-shadows with Claude Code CLI for AI-assisted Godot development.

---

## Quick Setup

### 1. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "godot-mcp-shadows": {
      "command": "node",
      "args": [
        "/home/justin/Desktop/projects_Copy/godot-mcp-shadows/build/index.js"
      ],
      "env": {
        "GODOT_PATH": "/home/justin/Applications/Godot/Godot_v4.5.1-stable_linux.x86_64",
        "PROJECT_PATH": "/home/justin/Desktop/projects_Copy/Shadows_of_the_Moth"
      }
    }
  }
}
```

### 2. Restart Claude Code

After updating settings, restart Claude Code for the MCP server to be loaded.

### 3. Verify Connection

Ask Claude: "What Godot MCP tools are available?"

---

## Available Operations

### Scene Creation
| Operation | Description |
|-----------|-------------|
| `create_scene` | Create a new scene with specified root node type |
| `create_player_scene` | Create player with camera rig, collision, states |
| `create_npc_scene` | Create NPC with AI, perception sensors |
| `create_hud_scene` | Create UI with HUD elements |
| `create_test_level` | Create test level with ground, lighting, spawns |
| `create_main_scene` | Create main game scene with system managers |
| `create_mechanics_test_map` | Create comprehensive test map |

### Scene Modification
| Operation | Description |
|-----------|-------------|
| `add_node` | Add a node to an existing scene |
| `load_sprite` | Load a texture into a Sprite node |
| `save_scene` | Save scene to a new path |
| `add_patrol_waypoints` | Add patrol path to NPC |
| `setup_system_groups` | Configure node groups for service discovery |

### Project Configuration
| Operation | Description |
|-----------|-------------|
| `configure_autoloads` | Add autoloads to project.godot |
| `get_uid` | Get UID for a resource file |
| `resave_resources` | Regenerate UIDs for all resources |

### Advanced
| Operation | Description |
|-----------|-------------|
| `create_from_template` | Create scene from JSON template |
| `export_mesh_library` | Export MeshLibrary from scene |

---

## Example Prompts

### Creating Scenes

**Basic scene:**
> "Create a new 3D scene at res://scenes/MyLevel.tscn"

**Player character:**
> "Create a player scene with camera and collision at res://scenes/player/Player.tscn"

**NPC with patrol:**
> "Create an NPC scene and add patrol waypoints at positions (10,0,10), (10,0,-10), (-10,0,-10), (-10,0,10)"

**Test environment:**
> "Create a test level that's 100x100 units with spawn points"

### Modifying Scenes

**Add a node:**
> "Add a SpotLight3D named 'Flashlight' to the Player scene under the CameraRig node"

**Add to groups:**
> "Add the TimeManager node in Main.tscn to the 'svc_time' and 'managers' groups"

### Project Setup

**Configure autoloads:**
> "Add GameBus as an autoload singleton from res://autoloads/GameBus.gd"

**Set up physics layers:**
> "Configure physics layers: 1=World, 2=Player, 3=NPC, 4=Projectiles"

### Using Templates

**From template:**
> "Create a scene using the npc_scene.json template"

---

## Workflow Examples

### Starting a New Level

```
1. "Create a test level at res://scenes/levels/Level1.tscn with size 80"
2. "Add a DirectionalLight3D named 'Sun' to the Lighting node"
3. "Create 3 NPC scenes for guards at res://scenes/npc/Guard1.tscn, Guard2.tscn, Guard3.tscn"
4. "Add patrol waypoints to each guard"
```

### Setting Up Game Systems

```
1. "Create the main scene at res://scenes/Main.tscn"
2. "Configure autoloads for GameBus, HarmonyManager, and SaveSystem"
3. "Setup system groups for all manager nodes"
```

### Creating UI

```
1. "Create a HUD scene at res://scenes/ui/HUD.tscn"
2. "Add a ProgressBar for health to the TopBar"
3. "Add a Label for score display"
```

---

## Tips for Best Results

1. **Be specific about paths** - Always use full `res://` paths
2. **Specify node types** - Say "Node3D" not just "node"
3. **Reference parent nodes** - When adding children, specify the parent path
4. **Use templates** - For complex scenes, templates ensure consistency
5. **Check results** - Open Godot editor to verify scene changes

---

## Troubleshooting

### MCP Server Not Connecting
- Check that Node.js is installed
- Verify paths in settings.json are correct
- Restart Claude Code after config changes

### Operations Failing
- Ensure you're in the correct project directory
- Check that scene files exist before modifying
- Verify Godot binary path is correct

### Scene Not Saving
- Check write permissions on project folder
- Ensure parent directories exist
- Try with absolute paths

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GODOT_PATH` | Path to Godot executable | `/home/user/Godot/godot` |
| `PROJECT_PATH` | Path to Godot project root | `/home/user/MyGame` |
| `DEBUG` | Enable debug logging | `true` |

---

## Related Documentation

- [TESTED_CONFIG.md](TESTED_CONFIG.md) - Full test results and verified operations
- [README_FORK.md](README_FORK.md) - Fork-specific features and operations
- [templates/](templates/) - JSON scene templates

---

Last updated: December 15, 2025
