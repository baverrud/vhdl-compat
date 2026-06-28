# VHDL Compatibility Matrix

**Generated from 4 test runs across 2 tools.**

> Legend: ✅ PASS  ⚠️ PARTIAL  ❌ FAIL  ⬜ UNTESTED  ➖ N/A

| Feature | Standard | Category | ModelSim-2020.1 | Questa-2025.3 |
|---------|----------|----------|---|---|
| **VHDL-2008** | | | | |  | 
| ?? (condition operator) -- convert std_logic to boolean | 2008 | expressions | ✅ | ✅ |
| Enhanced bit string literals -- width, signed/unsigned, don't-care | 2008 | expressions | ✅ | ✅ |
| Generic types -- entities/functions parameterizable by type | 2008 | generics | ✅ | ✅ |
| Block comments /* ... */ | 2008 | misc | ✅ | ✅ |
| process(all) -- automatic sensitivity list inference | 2008 | processes | ✅ | ✅ |
| External (hierarchical) names -- access signals across hierarchy | 2008 | verification | ✅ | ✅ |
| **VHDL-2019** | | | | |  | 
| Conditional analysis -- `if / `else / `end if tool directives | 2019 | conditional_analysis | ✅ | ✅ |
| Optional trailing semicolon in interface lists | 2019 | syntax | ❌ | ❌ |
| Empty records -- record types with no elements | 2019 | types_2019 | ✅ | ✅ |
