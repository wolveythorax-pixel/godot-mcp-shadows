#!/bin/bash

# Test script for godot-mcp-shadows operations
# Run from the godot-mcp-shadows directory

set -e

# Configuration
GODOT_BIN="${GODOT_BIN:-godot}"
SCRIPT_PATH="./build/scripts/godot_operations.gd"
TEST_PROJECT="${TEST_PROJECT:-./test_project}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
}

run_operation() {
    local operation=$1
    local params=$2
    local description=$3

    log_test "$description"

    if [ "$VERBOSE" = "true" ]; then
        echo "  Command: $GODOT_BIN --headless --script $SCRIPT_PATH $operation '$params'"
    fi

    cd "$TEST_PROJECT"

    if output=$("$GODOT_BIN" --headless --script "../$SCRIPT_PATH" "$operation" "$params" 2>&1); then
        log_info "PASSED: $description"
        if [ "$VERBOSE" = "true" ]; then
            echo "  Output: $output"
        fi
        ((TESTS_PASSED++))
        cd - > /dev/null
        return 0
    else
        log_error "FAILED: $description"
        echo "  Output: $output"
        ((TESTS_FAILED++))
        cd - > /dev/null
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Godot binary
    if ! command -v "$GODOT_BIN" &> /dev/null; then
        log_error "Godot binary not found: $GODOT_BIN"
        log_info "Set GODOT_BIN environment variable to your Godot executable path"
        exit 1
    fi

    # Check script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        log_error "Operations script not found: $SCRIPT_PATH"
        log_info "Run 'npm run build' first"
        exit 1
    fi

    # Create test project if needed
    if [ ! -d "$TEST_PROJECT" ]; then
        log_info "Creating test project directory..."
        mkdir -p "$TEST_PROJECT"

        # Create minimal project.godot
        cat > "$TEST_PROJECT/project.godot" << 'EOF'
; Engine configuration file.

config_version=5

[application]
config/name="Test Project"
config/features=PackedStringArray("4.3")

[rendering]
renderer/rendering_method="gl_compatibility"
EOF

        # Create icon
        touch "$TEST_PROJECT/icon.svg"
    fi

    log_info "Prerequisites check passed"
}

# Cleanup test artifacts
cleanup() {
    log_info "Cleaning up test artifacts..."

    if [ -d "$TEST_PROJECT" ]; then
        rm -f "$TEST_PROJECT"/*.tscn
        rm -rf "$TEST_PROJECT/scenes"
        rm -rf "$TEST_PROJECT/test_*"
    fi
}

# Run all tests
run_tests() {
    echo ""
    echo "========================================"
    echo "godot-mcp-shadows Operation Tests"
    echo "========================================"
    echo ""

    # Upstream operations
    echo "--- Upstream Operations ---"

    run_operation "create_scene" \
        '{"scene_path":"res://test_scene.tscn","root_node_type":"Node"}' \
        "Create basic scene"

    run_operation "create_scene" \
        '{"scene_path":"res://test_scene_3d.tscn","root_node_type":"Node3D"}' \
        "Create 3D scene"

    run_operation "add_node" \
        '{"scene_path":"res://test_scene.tscn","parent_node_path":"root","node_type":"Node3D","node_name":"TestChild"}' \
        "Add node to scene"

    run_operation "save_scene" \
        '{"scene_path":"res://test_scene.tscn","new_path":"res://test_scene_copy.tscn"}' \
        "Save scene copy"

    run_operation "get_uid" \
        '{"file_path":"res://project.godot"}' \
        "Get UID for file"

    # Custom Shadows of the Moth operations
    echo ""
    echo "--- Custom Scene Operations ---"

    run_operation "create_player_scene" \
        '{"scene_path":"res://scenes/player/TestPlayer.tscn"}' \
        "Create player scene"

    run_operation "create_npc_scene" \
        '{"scene_path":"res://scenes/npc/TestNPC.tscn"}' \
        "Create NPC scene"

    run_operation "create_hud_scene" \
        '{"scene_path":"res://scenes/ui/TestHUD.tscn"}' \
        "Create HUD scene"

    run_operation "create_test_level" \
        '{"scene_path":"res://scenes/levels/TestLevel.tscn","size":30}' \
        "Create test level"

    run_operation "create_main_scene" \
        '{"scene_path":"res://scenes/TestMain.tscn"}' \
        "Create main scene"

    run_operation "create_mechanics_test_map" \
        '{"scene_path":"res://scenes/levels/TestMechanics.tscn"}' \
        "Create mechanics test map"

    # New operations
    echo ""
    echo "--- New Operations ---"

    run_operation "add_patrol_waypoints" \
        '{"scene_path":"res://scenes/npc/TestNPC.tscn","waypoints":[[10,0,10],[10,0,-10],[-10,0,-10],[-10,0,10]],"loop":true}' \
        "Add patrol waypoints to NPC"

    run_operation "setup_system_groups" \
        '{"scene_path":"res://scenes/TestMain.tscn","groups":{"WorldSystems/TimeManager":["svc_time","managers"]}}' \
        "Setup system groups"

    # Template operations (if templates exist)
    if [ -f "../templates/test_level.json" ]; then
        # Copy template to test project for access
        cp "../templates/test_level.json" "$TEST_PROJECT/test_level_template.json"

        run_operation "create_from_template" \
            '{"template_path":"res://test_level_template.json","scene_path":"res://scenes/TemplateTest.tscn"}' \
            "Create scene from template"
    else
        log_warn "Skipping template test - templates not found"
        ((TESTS_SKIPPED++))
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo "========================================"

    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

# Main
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --godot)
                GODOT_BIN="$2"
                shift 2
                ;;
            --project)
                TEST_PROJECT="$2"
                shift 2
                ;;
            --cleanup)
                cleanup
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --verbose, -v    Show detailed output"
                echo "  --godot PATH     Path to Godot binary"
                echo "  --project PATH   Path to test project"
                echo "  --cleanup        Remove test artifacts"
                echo "  --help, -h       Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    check_prerequisites
    run_tests
    print_summary
}

main "$@"
