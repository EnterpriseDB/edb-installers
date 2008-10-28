#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB

LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard"


