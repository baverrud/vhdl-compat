# VHDL Compatibility Matrix

**Generated from 8 test runs across 2 tools.**

> Legend: ✅ PASS  ⚠️ PARTIAL  ❌ FAIL  ⬜ UNTESTED  ➖ N/A

| Feature | Standard | Category | ModelSim-2020.1 | Questa-2025.3 |
|---------|----------|----------|---|---|
| **VHDL-2000** | | | | |  | 
| Protected types -- class-like constructs with mutual exclusion | 2000 | protected_types | ✅ | ✅ |
| **VHDL-2002** | | | | |  | 
| Relaxed buffer port rules -- buffer ports can connect to out ports | 2002 | buffer_ports | ✅ | ✅ |
| **VHDL-2008** | | | | |  | 
| Named association in aggregates — mix positional and named elements | 2008 | aggregates | ✅ | ✅ |
| ?? (condition operator) -- convert std_logic to boolean | 2008 | expressions | ✅ | ✅ |
| Enhanced bit string literals -- width, signed/unsigned, don't-care | 2008 | expressions | ✅ | ✅ |
| Case-generate — conditional elaboration based on a discrete expression | 2008 | generate | ✅ | ✅ |
| If-generate with elsif/else — multi-way conditional elaboration | 2008 | generate | ✅ | ✅ |
| Generic types -- entities/functions parameterizable by type | 2008 | generics | ✅ | ✅ |
| Block comments /* ... */ | 2008 | misc | ✅ | ✅ |
| Context declarations — reusable sets of library/use clauses | 2008 | packages | ✅ | ✅ |
| Generic packages — packages parameterized by generics | 2008 | packages | ✅ | ✅ |
| Enhanced port maps — open keyword anywhere in port map | 2008 | ports | ✅ | ✅ |
| process(all) -- automatic sensitivity list inference | 2008 | processes | ✅ | ✅ |
| Matching case statement (case?) — don't-care aware pattern matching | 2008 | types | ✅ | ✅ |
| Unconstrained element types — records with unconstrained array fields | 2008 | types | ✅ | ✅ |
| External (hierarchical) names -- access signals across hierarchy | 2008 | verification | ✅ | ✅ |
| **VHDL-2019** | | | | |  | 
| Optional report clause in assert — assert without message string | 2019 | assert_api | ❌ | ✅ |
| New reflection attributes — 'designated_type, 'index, 'range | 2019 | attributes | ❌ | ✅ |
| Conditional analysis -- `if / `else / `end if tool directives | 2019 | conditional_analysis | ❌ | ✅ |
| Enhanced std.env — stop/finish with integer exit codes | 2019 | env | ❌ | ✅ |
| Enhanced FILE_OPEN/FILE_CLOSE with STATUS parameter | 2019 | file_io | ❌ | ✅ |
| Generic types on subprograms — functions/procedures parameterized by type | 2019 | generics_2019 | ❌ | ❌ |
| Array of interface records -- multiple channels using a single bundle type | 2019 | interfaces | ❌ | ✅ |
| Inout mode views -- bidirectional interface fields that can't use 'converse | 2019 | interfaces | ❌ | ✅ |
| Interface mode views — per-field direction control on composite types | 2019 | interfaces | ❌ | ✅ |
| Protected types as subprogram parameters | 2019 | protected_types | ❌ | ✅ |
| Embedded PSL directives — property specification language in comments | 2019 | psl | ❌ | ✅ |
| Sequential block statements — named scopes within processes | 2019 | sequential | ❌ | ❌ |
| Optional trailing semicolon in interface lists | 2019 | syntax | ❌ | ❌ |
| Empty records -- record types with no elements | 2019 | types_2019 | ❌ | ✅ |
| Inferred constraints — constrain unconstrained record elements at signal declaration | 2019 | types_2019 | ❌ | ✅ |
| Partially connected vectors — use `open` to leave port bits unconnected | 2019 | vectors | ❌ | ❌ |
