# Build system inspired from Peter Miller's paper
# "Recursive make considered harmful".
#
# ---
# Incorporating this Makefile into a project:
#
# Create a link to this Makefile at the top of the project's directory
# structure.
# The project must be structured into submodules.
# A main module.mk should exist in the top directory defining `INCLUDEDIRS`
# as well as extra rules that may be necessary (e.g. subproject rules)
#
# Each module of the project defines a `module.mk` which is included by this
# Makefile in order to use a single Makefile for the project.
# Git submodules (which will be referred to as subprojects) are identified and
# built individually using recursive make.
#
# ---
# Usage:
# - `make all` should be used instead of `make` when building the whole project
#   as a simple `make` would simply build the first rule of the first module.
# - `make tests` builds all tests
# - module.mk's often declare directory targets to build submodules
#   individually
#   e.g.
#   	make set1/challenge1
#   	make set1/challenge1/tests
# - Submodules are built in `all` and cleaned in `clean`. They also have
#   individual build and clean targets; `submodule` and `clean-submodule`

-include module.mk

INCLUDES    := $(addprefix -I , $(INCLUDEDIRS))

CC	 := gcc
CFLAGS	 := -std=gnu11 -g -ggdb3 -Wall -Wextra -Werror -pedantic
CPPFLAGS := $(INCLUDES) -MMD -MP
ARFLAGS  := rv
RM	 := rm -rf

# Make sure to escape the `$`
SUBPROJECTS := $(shell git submodule status | awk '{print $$2}')
IGNORE_SUBPROJECTS := $(SUBPROJECTS:%=-not -path "./%/*")

# Ignore subprojects
SRCS := $(shell find . $(IGNORE_SUBPROJECTS) -name "*.c")
OBJS := $(SRCS:%.c=%.o)
DEPS := $(OBJS:%.o=%.d)
DSYM := $(shell find . $(IGNORE_SUBPROJECTS) -name "*.dSYM")

# Each module will add to these
PROGRAMS :=
TESTS	 :=
PHONYS   :=

# Note the module.mk from the top project directory should be the first one to
# be included. This hence relies on `find`'s preorder search behaviour
include $(shell find . $(IGNORE_SUBPROJECTS) -name "module.mk")

-include $(DEPS)

all: $(SUBPROJECTS) $(PROGRAMS) $(TESTS)

$(SUBPROJECTS):
	$(MAKE) all -C $@

$(SUBPROJECTS:%=clean-%):
	$(MAKE) clean -C $(@:clean-%=%)

tests: $(TESTS)

clean: $(SUBPROJECTS:%=clean-%)
	$(RM) $(PROGRAMS) $(TESTS) $(OBJS) $(DEPS) $(DSYM)

.PHONY: all tests clean $(PHONYS) $(SUBPROJECTS) $(SUBPROJECTS:%=clean-%)
