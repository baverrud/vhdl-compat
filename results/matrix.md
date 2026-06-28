# VHDL Compatibility Matrix

**Generated from 8 test runs across 2 tools.**

> Legend: ✅ PASS  ⚠️ PARTIAL  ❌ FAIL  ⬜ UNTESTED  ➖ N/A

| Feature | Standard | Category | Questa-2025.3 | ModelSim-2020.1 |
|---------|----------|----------|---|---|
| **VHDL-2000** | | | | |  | 
| Protected types -- class-like constructs with mutual exclusion | 2000 | protected_types | ✅ | ✅ |
| **VHDL-2002** | | | | |  | 
| Relaxed buffer port rules -- buffer ports can connect to out ports | 2002 | buffer_ports | ✅ | ✅ |
| **VHDL-2008** | | | | |  | 
| Aggregates as assignment targets — using aggregates on the left-hand side of <= | 2008 | aggregates | ✅ | ➖ |
| Array slices in aggregates — assign ranges of array elements | 2008 | aggregates | ✅ | ✅ |
| Named association in aggregates — mix positional and named elements | 2008 | aggregates | ✅ | ✅ |
| open in aggregates — leave aggregate elements unconnected | 2008 | aggregates | ❌ | ➖ |
| others => in record aggregates — shorthand for unmentioned record fields | 2008 | aggregates | ✅ | ➖ |
| ?? (condition operator) -- convert std_logic to boolean | 2008 | expressions | ✅ | ✅ |
| Enhanced bit string literals -- width, signed/unsigned, don't-care | 2008 | expressions | ✅ | ✅ |
| Matching equality/inequality (?=, ?/=) — don't-care aware comparison | 2008 | expressions | ✅ | ✅ |
| Shift/rotate operators — SLL, SRL, SLA, SRA, ROL, ROR for vectors | 2008 | expressions | ✅ | ✅ |
| Unary reduction operators — and, or, xor, nand, nor, xnor on vectors | 2008 | expressions | ✅ | ✅ |
| Case-generate — conditional elaboration based on a discrete expression | 2008 | generate | ✅ | ✅ |
| If-generate with elsif/else — multi-way conditional elaboration | 2008 | generate | ✅ | ✅ |
| Default values for generic types — generic type with optional default | 2008 | generics | ❌ | ➖ |
| Generic subprograms on entities — entities with generic functions/procedures | 2008 | generics | ✅ | ✅ |
| Generic types -- entities/functions parameterizable by type | 2008 | generics | ✅ | ✅ |
| Block comments /* ... */ | 2008 | misc | ✅ | ✅ |
| IP encryption — protect tool directives for IP protection | 2008 | misc | ✅ | ➖ |
| minimum / maximum — standard min/max functions for all scalar types | 2008 | misc | ✅ | ✅ |
| rising_edge / falling_edge for boolean signals | 2008 | misc | ✅ | ➖ |
| to_string / to_bstring / to_hstring / to_ostring — formatted string conversion | 2008 | misc | ✅ | ✅ |
| Context declarations — reusable sets of library/use clauses | 2008 | packages | ✅ | ✅ |
| Fixed-point package (fixed_pkg) — IEEE 1076.3 fixed-point arithmetic | 2008 | packages | ✅ | ✅ |
| Floating-point package (float_pkg) — IEEE 754 floating-point types | 2008 | packages | ✅ | ✅ |
| Generic packages — packages parameterized by generics | 2008 | packages | ✅ | ✅ |
| numeric_std_signed — signed arithmetic on std_logic_vector without casting | 2008 | packages | ❌ | ➖ |
| numeric_std_unsigned — arithmetic on std_logic_vector without casting | 2008 | packages | ✅ | ✅ |
| Enhanced port maps — open keyword anywhere in port map | 2008 | ports | ✅ | ✅ |
| Expressions in port maps — use arbitrary expressions (not just signals) in associations | 2008 | ports | ✅ | ➖ |
| Reading output ports — out-mode ports can be read in the same entity | 2008 | ports | ✅ | ✅ |
| Conditional sequential assignment — when/else inside processes | 2008 | processes | ✅ | ✅ |
| process(all) -- automatic sensitivity list inference | 2008 | processes | ✅ | ✅ |
| 'driving and 'driving_value — query signal driver status | 2008 | types | ❌ | ➖ |
| Matching case statement (case?) — don't-care aware pattern matching | 2008 | types | ✅ | ✅ |
| Predefined array types — boolean_vector, integer_vector, real_vector, time_vector | 2008 | types | ✅ | ✅ |
| Unconstrained element types — records with unconstrained array fields | 2008 | types | ✅ | ✅ |
| External (hierarchical) names -- access signals across hierarchy | 2008 | verification | ✅ | ✅ |
| Force / Release — override signal values for verification | 2008 | verification | ✅ | ✅ |
| std.env.stop / std.env.finish — standard simulation control | 2008 | verification | ✅ | ➖ |
| **VHDL-2019** | | | | |  | 
| LCS2016-050: Full assert API — IsVhdlAssertFailed, GetVhdlAssertCount, SetVhdlAssertFormat | 2019 | assert_api | ✅ | ➖ |
| LCS2016-081: Optional report clause in assert — assert without message string | 2019 | assert_api | ✅ | ❌ |
| LCS2016-012: 'IMAGE and TO_STRING for composite types — string representation of records and arrays | 2019 | attributes | ✅ | ➖ |
| LCS2016-106: New reflection attributes — 'designated_type, 'index, 'range | 2019 | attributes | ✅ | ❌ |
| LCS2016-041: Record introspection — 'reflect attribute for runtime type inspection | 2019 | attributes | ✅ | ➖ |
| LCS2016-061: Conditional analysis -- `if / `else / `end if tool directives | 2019 | conditional_analysis | ✅ | ❌ |
| LCS2016-006f: Standard conditional analysis identifiers — VHDL_VERSION, TOOL_TYPE, etc. | 2019 | conditional_analysis | ✅ | ➖ |
| LCS2016-011: Date/time functions — LOCALTIME, GMTIME, EPOCH for testbench timestamps | 2019 | env | ✅ | ➖ |
| Enhanced std.env — stop/finish with integer exit codes | 2019 | env | ✅ | ❌ |
| LCS2016-006e: Environment variables — GETENV for reading system environment | 2019 | env | ✅ | ➖ |
| LCS2016-015a: FILE_NAME, FILE_PATH, FILE_LINE — source location introspection | 2019 | env | ✅ | ➖ |
| LCS2016-015: GET_CALL_PATH — runtime call stack introspection | 2019 | env | ✅ | ➖ |
| LCS2016-103: Enhanced FILE_OPEN/FILE_CLOSE with STATUS parameter | 2019 | file_io | ✅ | ❌ |
| LCS2016-059: Array type generics — generic parameters that are array types | 2019 | generics_2019 | ✅ | ➖ |
| LCS2016-045a: Array of interface records -- multiple channels using a single bundle type | 2019 | interfaces | ✅ | ❌ |
| LCS2016-045a: Inout mode views -- bidirectional interface fields that can't use 'converse | 2019 | interfaces | ✅ | ❌ |
| LCS2016-045a: Interface mode views — per-field direction control on composite types | 2019 | interfaces | ✅ | ❌ |
| LCS2016-030: Garbage collection — automatic memory management for access types | 2019 | protected_types | ✅ | ➖ |
| LCS2016-032: PATH_NAME/INSTANCE_NAME for protected types | 2019 | protected_types | ✅ | ➖ |
| LCS2016-099: Protected types as subprogram parameters | 2019 | protected_types | ✅ | ❌ |
| LCS2016-047: Shared variables on entity interface — shared variable ports/generics | 2019 | protected_types | ✅ | ➖ |
| Embedded PSL directives — property specification language in comments | 2019 | psl | ✅ | ❌ |
| LCS2016-036a: Conditional expressions in declarations — if/when in constant/signal defaults | 2019 | sequential | ✅ | ➖ |
| LCS2016-086: All interface lists can be ordered — named association everywhere | 2019 | syntax | ✅ | ➖ |
| LCS2016-099 (extended ranges — distinct from LCS2016-099 PT params): Extended ranges / range expressions — dynamic range computation | 2019 | syntax | ✅ | ➖ |
| LCS2016-071a: Optional trailing semicolon in interface lists | 2019 | syntax | ✅ | ❌ |
| LCS2016-I03: Signatures in association lists — explicit subprogram signatures | 2019 | syntax | ✅ | ➖ |
| LCS2016-055a: Syntax regularization -- component declarations made optional | 2019 | syntax | ✅ | ➖ |
| LCS2016-082: Empty records -- record types with no elements | 2019 | types_2019 | ✅ | ❌ |
| LCS2016-019: Inferred constraints — constrain unconstrained record elements at signal declaration | 2019 | types_2019 | ✅ | ❌ |
| LCS2016-059a: Scalar array ordering — relational operators on any scalar array type | 2019 | types_2019 | ✅ | ➖ |
| LCS2016-072b: Function knows vector size — result type depends on input sizes | 2019 | vectors | ✅ | ➖ |
| LCS2016-018/018a/018d: Enhanced enumerated type attributes — 'VAL, 'POS, 'SUCC, 'PRED, 'LEFTOF, 'RIGHTOF | 2019 | attributes | ❌ | ➖ |
| LCS2016-006c: Directory API — DIR_OPEN, DIR_CREATEDIR, DIR_DELETEFILE, DIR_CLOSE | 2019 | file_io | ❌ | ➖ |
| LCS2016-006a: File I/O extensions — FILE_REWIND, FILE_SEEK, FILE_TRUNCATE, FILE_STATE | 2019 | file_io | ❌ | ➖ |
| LCS2016-109: Generic types on subprograms — functions/procedures parameterized by type | 2019 | generics_2019 | ❌ | ❌ |
| LCS2016-049: Map generics on subprogram call — override generics at call site | 2019 | generics_2019 | ❌ | ➖ |
| LCS2016-014: Composites of protected types — records and arrays containing PT elements | 2019 | protected_types | ❌ | ➖ |
| LCS2016-014a: Pointers to composites of protected types | 2019 | protected_types | ❌ | ➖ |
| LCS2016-034: Protected types with generic clause — parameterizable protected types | 2019 | protected_types | ❌ | ➖ |
| LCS2016-033: Public variable + PRIVATE keyword in protected types | 2019 | protected_types | ❌ | ➖ |
| LCS2016-043: PSL attributes and functions — extended PSL built-in capabilities | 2019 | psl | ❌ | ➖ |
| LCS2016-094a: Conditional return statement — return with when/else conditions | 2019 | sequential | ❌ | ➖ |
| LCS2016-107: Sequential block statements — named scopes within processes | 2019 | sequential | ❌ | ❌ |
| LCS2016-007: Sequential declaration regions — declare variables anywhere in sequential code | 2019 | sequential | ❌ | ➖ |
| LCS2016-I13: Precedence of unary operators — standardized unary operator binding | 2019 | syntax | ❌ | ➖ |
| LCS2016-023: Relaxed library requirement on configurations | 2019 | syntax | ❌ | ➖ |
| LCS2016-028: Access external types through library path — cross-library type visibility | 2019 | types_2019 | ❌ | ➖ |
| LCS2016-016: Anonymous types in interface lists — types declared inline in ports/generics | 2019 | types_2019 | ❌ | ➖ |
| LCS2016-075: Closely related record types — implicit conversion between similar records | 2019 | types_2019 | ❌ | ➖ |
| LCS2016-026c: Long integers — 64-bit integer support | 2019 | types_2019 | ❌ | ➖ |
| LCS2016-001: Partially connected vectors — use `open` to leave port bits unconnected | 2019 | vectors | ❌ | ❌ |
