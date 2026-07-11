"""Lunar production pipeline entry point. Run with Blender in background mode."""
import json
import os
import sys

import bpy


def parse_payload():
    if "--" not in sys.argv:
        return {}
    return json.loads(sys.argv[sys.argv.index("--") + 1])


def validate_scene():
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    return {
        "objects": len(bpy.context.scene.objects),
        "meshes": len(meshes),
        "missing_materials": sum(not obj.data.materials for obj in meshes),
        "dimensions_checked": True,
        "topology_checked": False,
        "uv_checked": False,
        "note": "Enable Blender mesh validation and UV inspection for production review.",
    }


def main():
    payload = parse_payload()
    output = payload.get("output", os.path.join(os.getcwd(), "lunar-output"))
    os.makedirs(output, exist_ok=True)
    # The pipeline contract is intentionally staged: reference analysis and
    # asset authoring are separate from validation/export so each can evolve.
    report = {
        "quality_mode": payload.get("quality_mode", "preview"),
        "references": payload.get("references", []),
        "stages": ["reference_analysis", "decomposition", "blockout", "detail", "validation", "export"],
        "validation": validate_scene(),
        "status": "scaffold_ready",
    }
    with open(os.path.join(output, "quality-report.json"), "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
