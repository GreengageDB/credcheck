EXTENSION = credcheck
EXTVERSION = $(shell grep default_version $(EXTENSION).control | \
	       sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")

# Uncomment the following two lines to enable cracklib support, adapt the path
# to the cracklib dictionary following your distribution
#PG_CPPFLAGS = -DUSE_CRACKLIB '-DCRACKLIB_DICTPATH="/usr/lib/cracklib_dict"'
#SHLIB_LINK = -lcrack

PG_CPPFLAGS += -Wno-ignored-attributes -flto

MODULE_big = credcheck
OBJS = credcheck.o $(WIN32RES)
PGFILEDESC = "credcheck - postgresql credential checker"

DATA = $(wildcard updates/*--*.sql) sql/$(EXTENSION)--$(EXTVERSION).sql

REGRESS_OPTS  = --inputdir=test --load-extension=credcheck
TESTS := setup 01_username 02_password 03_rename 04_alter_pwd
PG_CONFIG = pg_config
ifeq ($(shell $(PG_CONFIG) --version | grep -E " 9\.4| 9\.5| 9\.6| 10| 11"; echo $$?),1)
	TESTS += 05_reuse_history
	TESTS += 06_reuse_interval
endif
TESTS += 07_valid_until 08_first_login teardown
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
