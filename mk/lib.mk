GPERF = gperf
GPERF_FILTER = sed -f mk/gperf-filter.sed
RAGEL = ragel
RAGEL_FILTER = sed -f mk/ragel-filter.sed
PREFIX_OBJ = $(addprefix $(1), $(addsuffix .o, $(2)))

define GPERF_GEN
  $(E) GPERF $(1)
  $(Q) $(GPERF) -m100 $(2) $(1:.c=.gperf) | $(GPERF_FILTER) > $(1)
endef

LIBGUMBO_OBJ_GPERF = $(call PREFIX_OBJ, build/lib/, \
    foreign_attrs svg_attrs svg_tags tag_lookup )

LIBGUMBO_OBJ = $(call PREFIX_OBJ, build/lib/, \
    ascii attribute error string_buffer tag utf8 vector char_ref parser \
    tokenizer util ) \
    $(LIBGUMBO_OBJ_GPERF)

TEST_OBJ = $(call PREFIX_OBJ, build/lib/test_, \
    attribute char_ref string_buffer string_piece test tokenizer \
    main parser utf8 vector )

build/lib/parser.o: XCFLAGS += -Wno-shadow
build/lib/test: $(LIBGUMBO_OBJ) $(TEST_OBJ)
build/lib/benchmark: $(LIBGUMBO_OBJ) build/lib/benchmark.o
build/lib/benchmark.o: lib/gumbo.h lib/macros.h

build/lib/test build/lib/benchmark:
	$(E) LINK '$@'
	$(Q) $(CC) $(XLDFLAGS) $(LDFLAGS) -o $@ $^

$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -c -o $@ $<

$(TEST_OBJ): build/lib/test_%.o: test/parser/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -Ilib -c -o $@ $<

build/lib/benchmark.o: test/benchmark/benchmark.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -Ilib -c -o $@ $<

build/lib/:
	@$(MKDIR) '$@'

check-lib: build/lib/test
	$(E) TEST '$<'
	$(Q) $<

benchmark: build/lib/benchmark
	$(E) RUN '$<'
	$(Q) $< test/benchmark/*.html

ragel-gen: | build/lib/
	$(RAGEL) -F0 -o build/lib/char_ref.c.tmp lib/char_ref.rl
	$(RAGEL_FILTER) build/lib/char_ref.c.tmp > lib/char_ref.c

gperf-gen:
	$(call GPERF_GEN, lib/tag_lookup.c)
	$(call GPERF_GEN, lib/svg_tags.c)
	$(call GPERF_GEN, lib/svg_attrs.c)
	$(call GPERF_GEN, lib/foreign_attrs.c, -n)


.PHONY: ragel-gen gperf-gen check-lib benchmark
