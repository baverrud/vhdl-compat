"""
Bulk-update test files to new naming convention:
  - Testbench entity: *_tb suffix (e.g. "condition_operator_tb")
  - Add SYNTH_ENTITY tag for synthesizable features
  - Update TEST_TYPE: sim -> both for RTL-capable categories
Does NOT add placeholder RTL entities — that's done manually per test.
"""

import re
from pathlib import Path

# Categories expected to be synthesizable (get TEST_TYPE: both + SYNTH_ENTITY)
RTL_CATEGORIES = {
    "expressions", "generics", "generate", "processes",
    "aggregates", "types", "packages", "ports",
    "generics_2019", "interfaces", "vectors", "types_2019",
    "syntax", "attributes", "conditional_analysis",
    "misc", "protected_types", "sequential",
}

# Categories that are simulation-only (stay TEST_TYPE: sim, no SYNTH_ENTITY)
SIM_ONLY = {
    "verification", "env", "file_io", "psl", "assert_api",
}


def update_file(filepath: Path) -> bool:
    content = filepath.read_text(encoding="utf-8", errors="replace")
    original = content
    category = filepath.parent.name

    # Find all entity names in the file
    entities = re.findall(r'entity\s+(\w+)\s+is', content)
    if not entities:
        return False

    # Find the testbench entity (starts with tb_ or is the last entity)
    tb_entity = entities[-1]  # Usually the last entity is the testbench
    for e in entities:
        if e.startswith("tb_"):
            tb_entity = e
            break

    # Extract feature name from TB entity
    if tb_entity.startswith("tb_"):
        feature_name = tb_entity[3:]
    elif tb_entity.endswith("_tb"):
        feature_name = tb_entity[:-3]
    else:
        feature_name = tb_entity

    new_tb_name = f"{feature_name}_tb"

    # Rename TB entity if needed
    if tb_entity != new_tb_name:
        content = content.replace(f"entity {tb_entity} is", f"entity {new_tb_name} is")
        content = content.replace(f"architecture test of {tb_entity} is",
                                  f"architecture test of {new_tb_name} is")
        content = content.replace(f"end architecture {tb_entity};",
                                  f"end architecture {new_tb_name};")

    # Also rename any uut instantiations referencing the old TB name
    for e in entities:
        if e != tb_entity and e.startswith("tb_"):
            feat = e[3:]
            new_name = f"{feat}_tb"
            content = content.replace(f"entity work.{e}", f"entity work.{new_name}")
            content = content.replace(f"entity {e} is", f"entity {new_name} is")

    # Update TEST_TYPE for RTL categories
    is_rtl = category in RTL_CATEGORIES
    if is_rtl and "TEST_TYPE:" in content:
        content = re.sub(r'TEST_TYPE:\s+sim', 'TEST_TYPE: both', content)

    # Add SYNTH_ENTITY tag for RTL categories
    if is_rtl and "SYNTH_ENTITY:" not in content:
        synth_line = f"-- SYNTH_ENTITY: {feature_name}\n"
        if "XREF:" in content:
            content = re.sub(r'(-- XREF:.+\n)', rf'\1{synth_line}', content, count=1)
        elif "CATEGORY:" in content:
            content = re.sub(r'(-- CATEGORY:.+\n)', rf'\1{synth_line}', content, count=1)

    if content != original:
        filepath.write_text(content, encoding="utf-8")
        print(f"  Updated: {filepath.relative_to(filepath.parents[2])}")
        return True
    return False


def main():
    tests_root = Path(__file__).resolve().parent.parent / "tests"
    count = 0
    for vhd_file in sorted(tests_root.rglob("*.vhd")):
        if vhd_file.name.startswith("_"):
            continue
        if update_file(vhd_file):
            count += 1
    print(f"\nUpdated {count} files.")


if __name__ == "__main__":
    main()
