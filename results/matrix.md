# VHDL Compatibility Matrix

**Generated from 12 test runs across 2 tools.**

> Legend: ✅ PASS  ⚠️ PARTIAL  ❌ FAIL  ⬜ UNTESTED  ➖ N/A

| Feature | Standard | Category | ModelSim-2020.1 | Questa-2025.3 |
|---------|----------|----------|---|---|
| **VHDL-2000** | | | | |  | 
| Predefined functions to_string, minimum, maximum clash with user code | 2000 | functions | ✅ | ✅ |
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 2000 | keywords | ✅ | ✅ |
| Reserved keyword "context" -- breaks VHDL-93 identifiers named "context" | 2000 | keywords | ✅ | ✅ |
| Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view" | 2000 | keywords | ✅ | ✅ |
| Protected types -- class-like constructs with mutual exclusion | 2000 | protected_types | ✅ | ✅ |
| Shared variables must be of protected type | 2000 | semantic | ❌ | ❌ |
| File declaration syntax changed from VHDL-87 | 2000 | syntax | ❌ | ❌ |
| std_logic_vector redefined as subtype of std_ulogic_vector | 2000 | types | ❌ | ❌ |
| **VHDL-2002** | | | | |  | 
| Relaxed buffer port rules -- buffer ports can connect to out ports | 2002 | buffer_ports | ✅ | ✅ |
| Predefined functions to_string, minimum, maximum clash with user code | 2002 | functions | ✅ | ✅ |
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 2002 | keywords | ✅ | ✅ |
| Reserved keyword "context" -- breaks VHDL-93 identifiers named "context" | 2002 | keywords | ✅ | ✅ |
| Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view" | 2002 | keywords | ✅ | ✅ |
| Shared variables must be of protected type | 2002 | semantic | ❌ | ❌ |
| File declaration syntax changed from VHDL-87 | 2002 | syntax | ❌ | ❌ |
| std_logic_vector redefined as subtype of std_ulogic_vector | 2002 | types | ❌ | ❌ |
| **VHDL-2008** | | | | |  | 
| ?? (condition operator) -- convert std_logic to boolean | 2008 | expressions | ✅ | ✅ |
| Enhanced bit string literals -- width, signed/unsigned, don't-care | 2008 | expressions | ✅ | ✅ |
| Predefined functions to_string, minimum, maximum clash with user code | 2008 | functions | ❌ | ❌ |
| Generic types -- entities/functions parameterizable by type | 2008 | generics | ✅ | ✅ |
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 2008 | keywords | ✅ | ✅ |
| Reserved keyword "context" -- breaks VHDL-93 identifiers named "context" | 2008 | keywords | ✅ | ✅ |
| Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view" | 2008 | keywords | ✅ | ✅ |
| Block comments /* ... */ | 2008 | misc | ✅ | ✅ |
| process(all) -- automatic sensitivity list inference | 2008 | processes | ✅ | ✅ |
| Shared variables must be of protected type | 2008 | semantic | ❌ | ❌ |
| File declaration syntax changed from VHDL-87 | 2008 | syntax | ❌ | ❌ |
| std_logic_vector redefined as subtype of std_ulogic_vector | 2008 | types | ✅ | ✅ |
| External (hierarchical) names -- access signals across hierarchy | 2008 | verification | ✅ | ✅ |
| **VHDL-2019** | | | | |  | 
| Conditional analysis -- `if / `else / `end if tool directives | 2019 | conditional_analysis | ❌ | ✅ |
| Predefined functions to_string, minimum, maximum clash with user code | 2019 | functions | ✅ | ❌ |
| Array of interface records -- multiple channels using a single bundle type | 2019 | interfaces | ❌ | ✅ |
| Inout mode views -- bidirectional interface fields that can't use 'converse | 2019 | interfaces | ❌ | ✅ |
| Interface mode views — per-field direction control on composite types | 2019 | interfaces | ❌ | ✅ |
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 2019 | keywords | ✅ | ✅ |
| Reserved keyword "context" -- breaks VHDL-93 identifiers named "context" | 2019 | keywords | ✅ | ✅ |
| Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view" | 2019 | keywords | ✅ | ✅ |
| Shared variables must be of protected type | 2019 | semantic | ✅ | ❌ |
| File declaration syntax changed from VHDL-87 | 2019 | syntax | ✅ | ❌ |
| Optional trailing semicolon in interface lists | 2019 | syntax | ❌ | ❌ |
| std_logic_vector redefined as subtype of std_ulogic_vector | 2019 | types | ✅ | ✅ |
| Empty records -- record types with no elements | 2019 | types_2019 | ❌ | ✅ |
| Inferred constraints — constrain unconstrained record elements at signal declaration | 2019 | types_2019 | ❌ | ✅ |
| Partially connected vectors — use `open` to leave port bits unconnected | 2019 | vectors | ❌ | ❌ |
| **VHDL-87** | | | | |  | 
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 87 | keywords | ❌ | ❌ |
| File declaration syntax changed from VHDL-87 | 87 | syntax | ✅ | ✅ |
| **VHDL-93** | | | | |  | 
| Predefined functions to_string, minimum, maximum clash with user code | 93 | functions | ✅ | ✅ |
| New VHDL-93 reserved keywords (shared, xnor, etc.) | 93 | keywords | ✅ | ✅ |
| Reserved keyword "context" -- breaks VHDL-93 identifiers named "context" | 93 | keywords | ❌ | ❌ |
| Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view" | 93 | keywords | ✅ | ✅ |
| Shared variables must be of protected type | 93 | semantic | ✅ | ✅ |
| File declaration syntax changed from VHDL-87 | 93 | syntax | ❌ | ❌ |
| std_logic_vector redefined as subtype of std_ulogic_vector | 93 | types | ❌ | ❌ |
