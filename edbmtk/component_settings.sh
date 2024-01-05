# Array of all components to be built for edbmtk installer
# - This array must carry the same order as the build sequence
# - This should contain all components regardless of the platform support
PACKAGE="MigrationToolkit"
COMPONENTS=(edbmtk)
export CMD_INSTALLER_VERSION=$EDB_VERSION_EDBMTK
export CMD_PRODUCT_NAME="Migration.Toolkit.51#0.AS10"
export CMD_PRODUCT_COMMIT_LOG=""
export CMD_PRODUCT_INFO_LOG=""
export CMD_PRODUCT_DEPN_LOG=""

export CMD_PRODUCT_COMMIT_FUNCTION="Generate_MTK_Commit_log"

# Lists of disabled/unsupported components; this must be a 
# space separated list; e.g.
# - COMPONENTS_LINUX_DISABLED="comp1 comp5"
# - COMPONENTS_LINUX_UNSUPPORTED="comp2 comp3"
COMPONENTS_LINUX_DISABLED=""
COMPONENTS_LINUX_UNSUPPORTED=""

COMPONENTS_LINUX_X64_DISABLED=""
COMPONENTS_LINUX_X64_UNSUPPORTED=""

COMPONENTS_WINDOWS_DISABLED=""
COMPONENTS_WINDOWS_UNSUPPORTED=""

