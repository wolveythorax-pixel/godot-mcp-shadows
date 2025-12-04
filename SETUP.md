# Setup Guide - Godot MCP Shadows Fork

## Prerequisites

### 1. Install Godot 4.5+

**Option A: Download from Official Site**
```bash
# Visit https://godotengine.org/download/
# Download Godot 4.5.x (Standard or Mono)
# Extract to desired location

# Make executable
chmod +x Godot_v4.5-stable_linux.x86_64

# Create symlink for easy access
sudo ln -s $(pwd)/Godot_v4.5-stable_linux.x86_64 /usr/local/bin/godot

# Verify installation
godot --version
```

**Option B: Install via Package Manager (Ubuntu/Debian)**
```bash
# Add Godot PPA
sudo add-apt-repository ppa:godot-engine/godot
sudo apt update

# Install Godot 4.5
sudo apt install godot-4.5

# Verify
godot4 --version
```

**Option C: Install via Flatpak**
```bash
flatpak install flathub org.godotengine.Godot
flatpak run org.godotengine.Godot --version
```

### 2. Install Node.js 20+

```bash
# Check version
node --version
npm --version

# If not installed, use nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

### 3. Clone and Setup Fork

```bash
cd /home/justin/Desktop/projects_Copy
git clone https://github.com/YOUR_USERNAME/godot-mcp-shadows.git
cd godot-mcp-shadows

# Install dependencies
npm install

# Build
npm run build

# Verify build succeeded
ls build/scripts/godot_operations.gd
```

---

## Quick Test

### 1. Test Godot Installation
```bash
godot --version
# Should output: 4.5.x.stable.official [hash]
```

### 2. Test Basic Operation
```bash
# Create temporary test directory
mkdir -p /tmp/godot-mcp-test
cd /tmp/godot-mcp-test

# Initialize minimal Godot project
cat > project.godot <<'EOF'
; Engine configuration file.

config_version=5

[application]
config/name="Test Project"
config/features=PackedStringArray("4.5")
EOF

# Test scene creation
godot --headless --script \
  /home/justin/Desktop/projects_Copy/godot-mcp-shadows/build/scripts/godot_operations.gd \
  create_scene \
  '{"scene_path":"res://test.tscn","root_node_type":"Node"}'

# Check result
ls test.tscn && echo "✅ Test passed!" || echo "❌ Test failed"
```

### 3. Test with Shadows of the Moth Project
```bash
cd /home/justin/Desktop/projects_Copy/Shadows_of_the_Moth

# Verify project.godot exists
ls project.godot

# Test creating a simple scene
godot --headless --script \
  ../godot-mcp-shadows/build/scripts/godot_operations.gd \
  create_scene \
  '{"scene_path":"res://test_scene.tscn","root_node_type":"Node"}'

# Verify scene was created
ls test_scene.tscn
```

---

## Configuration

### 1. Configure Godot Path (if not in PATH)

If `godot` command is not available globally, configure the path:

**Option A: Environment Variable**
```bash
export GODOT_BIN="/path/to/Godot_v4.5-stable_linux.x86_64"
```

**Option B: Modify godot-mcp Server Config**

Edit `src/index.ts` (before building):
```typescript
const config: GodotServerConfig = {
  godotPath: '/path/to/Godot_v4.5-stable_linux.x86_64',
  debugMode: true,
  godotDebugMode: true
};

const server = new GodotServer(config);
```

### 2. Configure for Qwen Tool Proxy

Add to `~/.bashrc` or `~/.zshrc`:
```bash
export GODOT_MCP_PATH="/home/justin/Desktop/projects_Copy/godot-mcp-shadows"
export GODOT_BIN="godot"  # or full path
```

---

## Troubleshooting

### Issue: "godot: command not found"

**Solution**: Install Godot 4.5+ or create symlink
```bash
# Find Godot binary
find ~ -name "Godot*" -type f 2>/dev/null

# Create symlink
sudo ln -s /path/to/godot /usr/local/bin/godot
```

### Issue: "Failed to parse JSON parameters"

**Solution**: Ensure JSON is properly escaped
```bash
# Good (single quotes around JSON)
godot --headless --script operations.gd create_scene '{"scene_path":"res://test.tscn"}'

# Bad (unescaped quotes)
godot --headless --script operations.gd create_scene {"scene_path":"res://test.tscn"}
```

### Issue: "Could not find --script argument"

**Solution**: Ensure correct order of arguments
```bash
# Correct order
godot --headless --script operations.gd <operation> '<json_params>'

# Wrong order
godot operations.gd --headless --script <operation> '<json_params>'
```

### Issue: "Operation returns no output"

**Solution**: Enable debug mode
```bash
godot --headless --script operations.gd --debug-godot create_scene '{"scene_path":"res://test.tscn"}'
```

### Issue: "Scene file not created"

**Checklist**:
1. ✓ Are you in a Godot project directory? (check for `project.godot`)
2. ✓ Does the scene path start with `res://`?
3. ✓ Do parent directories exist? (e.g., `res://scenes/` for `res://scenes/test.tscn`)
4. ✓ Do you have write permissions?

**Debug**:
```bash
# Check current directory
pwd
ls project.godot

# Test with absolute path
godot --headless --script operations.gd create_scene \
  '{"scene_path":"'"$(pwd)"'/test.tscn","root_node_type":"Node"}'
```

---

## Development Workflow

### 1. Make Changes to Operations

Edit `src/scripts/godot_operations.gd`:
```gdscript
func my_new_operation(params):
    log_info("Running my_new_operation")
    # Implementation
    quit(0)

# Add to match statement in _init()
match operation:
    "my_new_operation":
        my_new_operation(params)
```

### 2. Rebuild
```bash
npm run build
```

### 3. Test
```bash
godot --headless --script build/scripts/godot_operations.gd \
  my_new_operation \
  '{"param1":"value1"}'
```

### 4. Commit
```bash
git add src/scripts/godot_operations.gd
git commit -m "feat: Add my_new_operation"
git push origin main
```

---

## Integration with Shadows of the Moth

### 1. Link to Main Project

Create symlink for easy access:
```bash
cd /home/justin/Desktop/projects_Copy/Shadows_of_the_Moth
ln -s ../godot-mcp-shadows godot-mcp

# Now you can use relative paths
godot --headless --script godot-mcp/build/scripts/godot_operations.gd ...
```

### 2. Create Helper Script

Create `scripts/godot_mcp.sh` in Shadows of the Moth:
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
GODOT_MCP="$PROJECT_ROOT/../godot-mcp-shadows"

godot --headless --script "$GODOT_MCP/build/scripts/godot_operations.gd" "$@"
```

Usage:
```bash
chmod +x scripts/godot_mcp.sh
./scripts/godot_mcp.sh create_scene '{"scene_path":"res://test.tscn","root_node_type":"Node"}'
```

---

## Next Steps

1. ✅ Install Godot 4.5+
2. ✅ Build godot-mcp-shadows fork
3. ✅ Test basic operations
4. ⏭️ Add Shadows of the Moth-specific operations
5. ⏭️ Integrate with qwen-tool-proxy
6. ⏭️ Create scene templates
7. ⏭️ Test end-to-end with Qwen

See `README_FORK.md` for detailed operation documentation.
