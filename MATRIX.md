# VHDL Compatibility Matrix

**Generated from 6 test runs across 4 tools.**

> Legend: ✅ PASS  ❌ FAIL  ⬜ not run  ➖ N/A (not applicable to this mode)

> sim = simulation  |  synth = synthesis (only features expected to synthesize)

| Feature | Category | Altera<br>ModelSim<br>Starter<br>2020.1<br>(sim) | Altera<br>Questa<br>Starter<br>2025.3<br>(sim) | Vivado<br>2023.2<br>(sim) | Vivado<br>2026.1<br>(sim) | Vivado<br>2023.2<br>(synth) | Vivado<br>2026.1<br>(synth) |
|---------|----------|---|---|---|---|---|---|
| **VHDL-2000** | |||||||
| [Global shared variables of protected types — package-level shared variables](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2000/protected_types/protected_types_global_shared.vhd) | protected_types | ✅ | ✅ | ✅ | ✅ | ⬜ | ⬜ |
| [Protected types -- class-like constructs with mutual exclusion](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2000/protected_types/protected_types_counter.vhd) | protected_types | ❌ | ❌ | ❌ | ❌ | ⬜ | ⬜ |
| **VHDL-2002** | |||||||
| [Relaxed buffer port rules -- buffer ports can connect to out ports](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2002/buffer_ports/buffer_ports_relaxed.vhd) | buffer_ports | ✅ | ✅ | ✅ | ✅ | ⬜ | ⬜ |
| **VHDL-2008** | |||||||
| [Aggregates as assignment targets — using aggregates on the left-hand side of <=](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/aggregates/aggregates_assignment_targets.vhd) | aggregates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Array slices in aggregates — assign ranges of array elements](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/aggregates/aggregates_slice_aggregates.vhd) | aggregates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Named association in aggregates — mix positional and named elements](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/aggregates/aggregates_named_association.vhd) | aggregates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [others => in record aggregates — shorthand for unmentioned record fields](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/aggregates/aggregates_others_record.vhd) | aggregates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [?? (condition operator) -- convert std_logic to boolean](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/expressions/expressions_condition_operator.vhd) | expressions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [FT09: Enhanced bit string literals -- width, signed/unsigned, don't-care](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/expressions/expressions_enhanced_bit_strings.vhd) | expressions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Matching equality/inequality (?=, ?/=) — don't-care aware comparison](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/expressions/expressions_matching_operators.vhd) | expressions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Shift/rotate operators — SLL, SRL, SLA, SRA, ROL, ROR for vectors](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/expressions/expressions_shift_rotate.vhd) | expressions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Unary reduction operators — and, or, xor, nand, nor, xnor on vectors](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/expressions/expressions_reduction_operators.vhd) | expressions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Case-generate — conditional elaboration based on a discrete expression](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generate/generate_case_generate.vhd) | generate | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [If-generate with elsif/else — multi-way conditional elaboration](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generate/generate_if_elsif_generate.vhd) | generate | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Generic subprograms on entities — entities with generic functions/procedures](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generics/generics_subprograms.vhd) | generics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Generic types -- entities/functions parameterizable by type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generics/generics_generic_types.vhd) | generics | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| [Block comments /* ... */](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_block_comments.vhd) | misc | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [IP encryption — protect tool directives for IP protection](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_ip_protect.vhd) | misc | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [minimum / maximum — standard min/max functions for all scalar types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_min_max.vhd) | misc | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [rising_edge / falling_edge for boolean signals](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_boolean_edge.vhd) | misc | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| [to_string / to_bstring / to_hstring / to_ostring — formatted string conversion](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_to_string.vhd) | misc | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Context declarations — reusable sets of library/use clauses](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_context.vhd) | packages | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| [Fixed-point package (fixed_pkg) — IEEE 1076.3 fixed-point arithmetic](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_fixed_point.vhd) | packages | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| [Floating-point package (float_pkg) — IEEE 754 floating-point types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_float_point.vhd) | packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Generic packages — packages parameterized by generics](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_generic_package.vhd) | packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [numeric_std_unsigned — arithmetic on std_logic_vector without casting](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_numeric_std_unsigned.vhd) | packages | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| [Enhanced port maps — open keyword anywhere in port map](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/ports/ports_enhanced_port_maps.vhd) | ports | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Expressions in port maps — use arbitrary expressions (not just signals) in associations](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/ports/ports_expressions_in_port_maps.vhd) | ports | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Reading output ports — out-mode ports can be read in the same entity](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/ports/ports_read_output.vhd) | ports | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Conditional sequential assignment — when/else inside processes](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/processes/processes_seq_assignments.vhd) | processes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [FT19: process(all) -- automatic sensitivity list inference](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/processes/processes_process_all.vhd) | processes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ['driving and 'driving_value — query signal driver status](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_driving_attributes.vhd) | types | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| [Matching case statement (case?) — don't-care aware pattern matching](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_matching_case.vhd) | types | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Predefined array types — boolean_vector, integer_vector, real_vector, time_vector](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_predefined_vectors.vhd) | types | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Unconstrained element types — records with unconstrained array fields](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_unconstrained_elements.vhd) | types | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [External names targeting arrays and records — UVVM signal spying pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_external_names.vhd) | uvvm | ✅ | ✅ | ❌ | ❌ | ➖ | ➖ |
| [Protected types with internal access types — UVVM dynamic data pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_protected_access.vhd) | uvvm | ✅ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [Unconstrained arrays of unconstrained vectors — UVVM data type pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_unconstrained_array.vhd) | uvvm | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [FT07: External (hierarchical) names -- access signals across hierarchy](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/verification/verification_external_names.vhd) | verification | ✅ | ✅ | ❌ | ❌ | ➖ | ➖ |
| [Force / Release — override signal values for verification](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/verification/verification_force_release.vhd) | verification | ✅ | ✅ | ❌ | ❌ | ➖ | ➖ |
| [std.env.stop / std.env.finish — standard simulation control](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/verification/verification_std_env.vhd) | verification | ✅ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [open in aggregates — leave aggregate elements unconnected](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/aggregates/aggregates_open_in_aggregates.vhd) | aggregates | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [Default values for generic types — generic type with optional default](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generics/generics_default_types.vhd) | generics | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [numeric_std_signed — signed arithmetic on std_logic_vector without casting](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_numeric_std_signed.vhd) | packages | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **VHDL-2019** | |||||||
| [LCS2016-050: Full assert API — IsVhdlAssertFailed, GetVhdlAssertCount, SetVhdlAssertFormat](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/assert_api/assert_api_lcs050_full_api.vhd) | assert_api | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-081: Optional report clause in assert — assert without message string](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/assert_api/assert_api_lcs081_no_message.vhd) | assert_api | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-012: 'IMAGE and TO_STRING for composite types — string representation of records and arrays](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs012_image_composite.vhd) | attributes | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-018/018a/018d: Enhanced enumerated type attributes — 'VAL, 'POS, 'SUCC, 'PRED, 'LEFTOF, 'RIGHTOF](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs018_enum_attributes.vhd) | attributes | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-106: New reflection attributes — 'designated_type, 'index, 'range](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs106_reflection.vhd) | attributes | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-041: Record introspection — 'reflect attribute for runtime type inspection](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs041_reflect.vhd) | attributes | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-061: Conditional analysis -- `if / `else / `end if tool directives](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/conditional_analysis/conditional_analysis_lcs061_conditional_compilation.vhd) | conditional_analysis | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-006f: Standard conditional analysis identifiers — VHDL_VERSION, TOOL_TYPE, etc.](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/conditional_analysis/conditional_analysis_lcs006f_standard_ids.vhd) | conditional_analysis | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-011: Date/time functions — LOCALTIME, GMTIME, EPOCH for testbench timestamps](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/env/env_lcs011_datetime.vhd) | env | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [Enhanced std.env — stop/finish with integer exit codes](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/env/env_enhanced_stop_finish.vhd) | env | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-006e: Environment variables — GETENV for reading system environment](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/env/env_lcs006e_getenv.vhd) | env | ❌ | ✅ | ❌ | ❌ | ➖ | ➖ |
| [LCS2016-015a: FILE_NAME, FILE_PATH, FILE_LINE — source location introspection](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/env/env_lcs015a_file_location.vhd) | env | ❌ | ✅ | ❌ | ❌ | ➖ | ➖ |
| [LCS2016-015: GET_CALL_PATH — runtime call stack introspection](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/env/env_lcs015_get_call_path.vhd) | env | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-006c: Directory API — DIR_OPEN, DIR_CREATEDIR, DIR_DELETEFILE, DIR_CLOSE](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/file_io/file_io_lcs006c_directory_api.vhd) | file_io | ❌ | ❌ | ❌ | ❌ | ➖ | ➖ |
| [LCS2016-103: Enhanced FILE_OPEN/FILE_CLOSE with STATUS parameter](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/file_io/file_io_lcs103_enhanced.vhd) | file_io | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-006a: File I/O extensions — FILE_REWIND, FILE_SEEK, FILE_TRUNCATE, FILE_STATE](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/file_io/file_io_lcs006a_extensions.vhd) | file_io | ❌ | ❌ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-059: Array type generics — generic parameters that are array types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/generics_2019/generics_2019_lcs059_array_type_generics.vhd) | generics_2019 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-109: Generic types on subprograms — functions/procedures parameterized by type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/generics_2019/generics_2019_lcs109_subprogram_generics.vhd) | generics_2019 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-049: Map generics on subprogram call — override generics at call site](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/generics_2019/generics_2019_lcs049_map_on_call.vhd) | generics_2019 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-045a: Array of interface records -- multiple channels using a single bundle type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/interfaces/interfaces_lcs045a_array_of_interfaces.vhd) | interfaces | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-045a: Inout mode views -- bidirectional interface fields that can't use 'converse](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/interfaces/interfaces_lcs045a_inout_views.vhd) | interfaces | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-045a: Interface mode views — per-field direction control on composite types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/interfaces/interfaces_lcs045a_mode_view.vhd) | interfaces | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-014: Composites of protected types — records and arrays containing PT elements](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs014_composites.vhd) | protected_types | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-030: Garbage collection — automatic memory management for access types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs030_garbage_collection.vhd) | protected_types | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-032: PATH_NAME/INSTANCE_NAME for protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs032_path_name.vhd) | protected_types | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-014a: Pointers to composites of protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs014a_pt_pointers.vhd) | protected_types | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-099: Protected types as subprogram parameters](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs099_subprogram_param.vhd) | protected_types | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-034: Protected types with generic clause — parameterizable protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs034_generic_pt.vhd) | protected_types | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-033: Public variable + PRIVATE keyword in protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs033_public_private.vhd) | protected_types | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-047: Shared variables on entity interface — shared variable ports/generics](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs047_shared_on_interface.vhd) | protected_types | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [Embedded PSL directives — property specification language in comments](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/psl/psl_enhanced_directives.vhd) | psl | ❌ | ✅ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-043: PSL attributes and functions — extended PSL built-in capabilities](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/psl/psl_lcs043_attributes.vhd) | psl | ❌ | ❌ | ✅ | ✅ | ➖ | ➖ |
| [LCS2016-036a: Conditional expressions in declarations — if/when in constant/signal defaults](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs036a_conditional_expr.vhd) | sequential | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-094a: Conditional return statement — return with when/else conditions](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs094a_conditional_return.vhd) | sequential | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-107: Sequential block statements — named scopes within processes](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs107_blocks.vhd) | sequential | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-007: Sequential declaration regions — declare variables anywhere in sequential code](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs007_declaration_regions.vhd) | sequential | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-086: All interface lists can be ordered — named association everywhere](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs086_ordered_interfaces.vhd) | syntax | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-099 (extended ranges — distinct from LCS2016-099 PT params): Extended ranges / range expressions — dynamic range computation](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs099_extended_ranges.vhd) | syntax | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-071a: Optional trailing semicolon in interface lists](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs071a_optional_trailing_semicolon.vhd) | syntax | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-I13: Precedence of unary operators — standardized unary operator binding](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcsI13_unary_precedence.vhd) | syntax | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-023: Relaxed library requirement on configurations](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs023_relaxed_library.vhd) | syntax | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-I03: Signatures in association lists — explicit subprogram signatures](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcsI03_signatures.vhd) | syntax | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-055a: Syntax regularization -- component declarations made optional](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs055a_components.vhd) | syntax | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-028: Access external types through library path — cross-library type visibility](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs028_external_types.vhd) | types_2019 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-016: Anonymous types in interface lists — types declared inline in ports/generics](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs016_anonymous_types.vhd) | types_2019 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-075: Closely related record types — implicit conversion between similar records](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs075_related_records.vhd) | types_2019 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-082: Empty records -- record types with no elements](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs082_empty_records.vhd) | types_2019 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-019: Inferred constraints — constrain unconstrained record elements at signal declaration](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs019_inferred_constraints.vhd) | types_2019 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| [LCS2016-026c: Long integers — 64-bit integer support](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs026c_long_integers.vhd) | types_2019 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| [LCS2016-059a: Scalar array ordering — relational operators on any scalar array type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs059a_scalar_ordering.vhd) | types_2019 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-072b: Function knows vector size — result type depends on input sizes](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/vectors/vectors_lcs072b_function_knows_size.vhd) | vectors | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [LCS2016-001: Partially connected vectors — use `open` to leave port bits unconnected](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/vectors/vectors_lcs001_partially_connected.vhd) | vectors | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |

---
## Vivado Sim vs Synth Comparison

Features where simulation and synthesis **disagree** —
works in one but not the other. Highlights the different
VHDL engines: xvhdl/xsim (Verific parser) vs synth_design.

### Vivado 2026.1

| Feature | Standard | Sim | Synth | Notes |
|---------|----------|:---:|:----:|-------|
| **VHDL-2008** | | | | |
| ['driving and 'driving_value — query signal driver status](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_driving_attributes.vhd) | VHDL-2008 | ❌ | ✅ | Synthesis only |
| [Context declarations — reusable sets of library/use clauses](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_context.vhd) | VHDL-2008 | ❌ | ✅ | Synthesis only |
| [Generic types -- entities/functions parameterizable by type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generics/generics_generic_types.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| [numeric_std_unsigned — arithmetic on std_logic_vector without casting](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_numeric_std_unsigned.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| [rising_edge / falling_edge for boolean signals](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_boolean_edge.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| **VHDL-2019** | | | | |
| ['IMAGE and TO_STRING for composite types — string representation of records and arrays](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs012_image_composite.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Access external types through library path — cross-library type visibility](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs028_external_types.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Conditional expressions in declarations — if/when in constant/signal defaults](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs036a_conditional_expr.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Long integers — 64-bit integer support](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs026c_long_integers.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Map generics on subprogram call — override generics at call site](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/generics_2019/generics_2019_lcs049_map_on_call.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Pointers to composites of protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs014a_pt_pointers.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Precedence of unary operators — standardized unary operator binding](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcsI13_unary_precedence.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Protected types with generic clause — parameterizable protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs034_generic_pt.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Public variable + PRIVATE keyword in protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs033_public_private.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Relaxed library requirement on configurations](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs023_relaxed_library.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |

### Vivado 2023.2

| Feature | Standard | Sim | Synth | Notes |
|---------|----------|:---:|:----:|-------|
| **VHDL-2008** | | | | |
| ['driving and 'driving_value — query signal driver status](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/types/types_driving_attributes.vhd) | VHDL-2008 | ❌ | ✅ | Synthesis only |
| [Context declarations — reusable sets of library/use clauses](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_context.vhd) | VHDL-2008 | ❌ | ✅ | Synthesis only |
| [Fixed-point package (fixed_pkg) — IEEE 1076.3 fixed-point arithmetic](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_fixed_point.vhd) | VHDL-2008 | ❌ | ✅ | Synthesis only |
| [Generic types -- entities/functions parameterizable by type](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/generics/generics_generic_types.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| [numeric_std_unsigned — arithmetic on std_logic_vector without casting](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/packages/packages_numeric_std_unsigned.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| [rising_edge / falling_edge for boolean signals](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_boolean_edge.vhd) | VHDL-2008 | ✅ | ❌ | Simulation only |
| **VHDL-2019** | | | | |
| ['IMAGE and TO_STRING for composite types — string representation of records and arrays](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/attributes/attributes_lcs012_image_composite.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Access external types through library path — cross-library type visibility](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs028_external_types.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Conditional expressions in declarations — if/when in constant/signal defaults](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/sequential/sequential_lcs036a_conditional_expr.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Long integers — 64-bit integer support](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/types_2019/types_2019_lcs026c_long_integers.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Map generics on subprogram call — override generics at call site](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/generics_2019/generics_2019_lcs049_map_on_call.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Pointers to composites of protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs014a_pt_pointers.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Precedence of unary operators — standardized unary operator binding](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcsI13_unary_precedence.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Protected types with generic clause — parameterizable protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs034_generic_pt.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Public variable + PRIVATE keyword in protected types](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/protected_types/protected_types_lcs033_public_private.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |
| [Relaxed library requirement on configurations](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2019/syntax/syntax_lcs023_relaxed_library.vhd) | VHDL-2019 | ❌ | ✅ | Synthesis only |

---
## UVVM Compatibility

UVVM (Universal VHDL Verification Methodology) is the leading
open-source VHDL verification framework. As of 2026-06-29,
**uvvm_util (20 files) and uvvm_vvc_framework (8 files) compile
and run on xsim 2026.1**. A minimal UVVM testbench with logging,
alerts, and check_value executes successfully.

The only confirmed VHDL language blocker for xsim is **external
names** (`<< signal >>`), which are required by some VIPs but
NOT by the UVVM core libraries. Multi-library compilation
(same file into different libraries) is a Vivado tool limitation
that affects VVC setup scripts but not VHDL compliance.

| Feature | Standard | Altera<br>ModelSim<br>Starter<br>2020.1<br>(sim) | Altera<br>Questa<br>Starter<br>2025.3<br>(sim) | Vivado<br>2023.2<br>(sim) | Vivado<br>2026.1<br>(sim) | Description |
|---------|----------|---|---|---|---|-----------|
| [Global shared variables of protected types — package-level shared variables](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2000/protected_types/protected_types_global_shared.vhd) | VHDL-2000 | ✅ | ✅ | ✅ | ✅ | Working — package-level shared variable (UVVM logger pattern) |
| [std.env.stop / std.env.finish — standard simulation control](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/verification/verification_std_env.vhd) | VHDL-2008 | ✅ | ✅ | ✅ | ✅ | Working — UVVM uses std.env for simulation control |
| [to_string / to_bstring / to_hstring / to_ostring — formatted string conversion](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/misc/misc_to_string.vhd) | VHDL-2008 | ✅ | ✅ | ✅ | ✅ | Working — UVVM uses string formatting for log messages |
| [Unconstrained arrays of unconstrained vectors — UVVM data type pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_unconstrained_array.vhd) | VHDL-2008 | ✅ | ✅ | ✅ | ✅ | Working — type slv_array is array(<>) of std_logic_vector |
| [Protected types with internal access types — UVVM dynamic data pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_protected_access.vhd) | VHDL-2008 | ✅ | ✅ | ✅ | ✅ | Working — allocate/deallocate in PTs (UVVM command queue) |
| [External names targeting arrays and records — UVVM signal spying pattern](https://github.com/baverrud/vhdl-compat/blob/main/tests/vhdl2008/uvvm/uvvm_external_names.vhd) | VHDL-2008 | ✅ | ✅ | ❌ | ❌ | BLOCKER — << signal >> not on xsim (VIP BFMs only, not core) |

> **Source:** uvvm_util (20 files) + uvvm_vvc_framework (8 files)
> compiled with xvhdl 2026.1 — all passed. A minimal UVVM testbench
> with log(), check_value(), and stop() executed successfully.
> The only blocker is `<< signal >>` (external names), which UVVM
> core does NOT use — only certain VIP BFMs need it.
