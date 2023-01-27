#!/usr/bin/make -f

PROFILE_EXCLUDES =

# TEST_EXCLUDES is defined in debian/rules.test and already sourced by debian/rules
PROFILE_OPTS = -x $(sort $(TEST_EXCLUDES) $(PROFILE_EXCLUDES))
