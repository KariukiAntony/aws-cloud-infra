#! /bin/bash
: "A script to automate the creation of terraform directory structure, formating, cleaning, security scanning and  many more"

# ----Configurations------------

# project root
PROJECT_ROOT=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

# version
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="terraform-automation"

# Folders
readonly BASE_DIR="$PROJECT_ROOT/infra"         # terraform base directory
readonly MODULES_BASE_DIR="${BASE_DIR}/modules" # the folder to house the modules
readonly MODULES_DIRS=()

# files
readonly BASE_DIR_FILES=("main.tf" "variables.tf" "outputs.tf" "providers.tf" "terraform.tfvars" "backend.tf" ".terraformignore" "README.md")
readonly MODULE_FILES=("main.tf" "variables.tf" "outputs.tf" "versions.tf")

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ---- Error handling & Traps ---
set -eEuo pipefail
trap "terminate_script SIGINT" SIGINT
trap "terminate_script ERR" ERR

terminate_script() {
    local signal="$1"
    if [[ "$signal" == "SIGINT" ]]; then
        log_error "Script interrupted  by user (Ctrl+C). Exiting."
    elif [[ "$signal" == "ERR" ]]; then
        log_error "An unexpected error occured. Exiting"
    fi
    exit 1
}

# --- Helper functions ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Logging functions -------------
log_info() {
    echo -e "${BLUE}[INFO] $1 ${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1 ${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1 ${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1 ${NC}"
}

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# create the directory structure
setup_terraform_structure() {
    echo "Setting up Terraform directory structure."

    # create modules
    log_header "creating modules directory: $MODULES_BASE_DIR"
    mkdir -p "$MODULES_BASE_DIR"

    for module_dir in "${MODULES_DIRS[@]}"; do
        local full_module_path="$MODULES_BASE_DIR/$module_dir"
        mkdir -p "$full_module_path"
        for module_file in "${MODULE_FILES[@]}"; do
            touch "$MODULES_BASE_DIR/$module_dir/$module_file" || {
                echo "Error. Could not create file $full_module_path/$module_file"
                exit 1
            }
        done
    done

    # Create root files.
    log_info "creating base directory files"

    for file in "${BASE_DIR_FILES[@]}"; do
        touch "$BASE_DIR/$file" || {
            echo "Error: Could not create file $BASE_DIR/$file"
            exit 1
        }
    done

    log_success "Terraform structure setup complete!"
}

validate_terraform_configs() {
    if ! command_exists terraform; then
        log_error "Terraform is not installed or not added to PATH."
    fi

    log_info "Validating Terraform configurations."
    local validation_failed=false

    # validate base files
    if [[ -d "$BASE_DIR" ]]; then
        (cd "$BASE_DIR" && terraform init &>/dev/null) || {
            log_error "Error initializing terraform"
            exit 1
        }
        (cd "$BASE_DIR" && terraform validate) || {
            log_error "Validation failed for your infra configurations."
            validation_failed=true
        }
    fi

    if "$validation_failed"; then
        log_error "Terraform validation failed for one or more configurations."
        exit 1
    fi

}

helper_format_dir() {
    local base_dir="$1"
    log_info "Formating Terraform files in: $base_dir"

    find "$base_dir" -type f -name "*.tf" -exec terraform fmt {} +

    # check if there is any unformated files
    unformatted_files=$(find "$base_dir" -type f -name "*.tf" -print0 | xargs --null terraform fmt -check -list 2>&1 || true)
    if [[ -n "$unformatted_files" ]]; then
        log_warning "Warning: Some files in '$base_dir' were not formatted correctly by 'terraform fmt'. Please check manually."
        echo "$unformatted_files"
    fi

    log_success "Terraform formating complete!"
}

format_terraform_configs() {
    if ! command_exists terraform; then
        log_error "Error. Terraform is not installed or not added in your PATH"
    fi

    # format all files including those in modules.
    helper_format_dir "$BASE_DIR"

}

lint_terraform_config() {
    local format_command="$0 fmt"
    log_info "Checking for linting issues in your configuration"
    unformatted_files=$(find "$BASE_DIR" -type f -name "*.tf" -print0 | xargs --null terraform fmt -check -list 2>&1 || true)
    if [[ -n "$unformatted_files" ]]; then
        log_warning "Warning: Some files in '$BASE_DIR' are not formated. Run $format_command to format them for consistency"
        echo "$unformatted_files"
        exit 1
    fi
}

security_scan() {
    log_header "Running security scans"
    local issue_found=false

    # check for any hardcoded secrets
    log_info "Checking for potential hardcoded secrets"
    if find "$BASE_DIR" -name "*.tf" -o -name "*.tfvars" | xargs grep -l "password\|secret|key" >/dev/null 2>&1; then
        log_warning "Found potential hardcoded secrets. Please review the following files:"
        find "$BASE_DIR" -name "*.tf" -o -name "*.tfvars" | xargs grep -n "password\|secret|key" >/dev/null 2>&1 || true
        issue_found=true
    fi

    # check if *.tfstate* is added to .gitignore
    if find "$BASE_DIR" -name "*.tfstate*" | grep -v ".gitinore" >/dev/null 2>&1; then
        log_warning "Found .tfsate files. Make sure to add them to .gitignore"
        issue_found=true
    fi

    if ! $issue_found; then
        log_success "No obvious security issues found."
    fi

}

clean_terraform() {
    log_header "Cleaning terraform artifacts"

    # Remove .terraform directories.
    find "$BASE_DIR" -type d -name ".terraform" -exec rm -rf {} + >/dev/null 2>&1 || true

    # Remove .terraform.lock.hcl files
    find "$BASE_DIR" -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true

    # Remove plan files.
    find "$BASE_DIR" -type f -name "*.tfplan" -delete 2>/dev/null || true

    log_success "Terraform artifacts cleaned!"
}

show_structure() {
    log_header "Current terraform structure"

    if command_exists tree; then
        tree -a -I '.terraform|.git' --dirsfirst
    else
        log_info "Install 'tree' command for better visualization"
        find "$PROJECT_ROOT" -type d -name ".terraform" -prune -o -type d -name ".git" -prune -o -type f -print | sort
    fi
}

delete_structure() {

    log_warning "You are about to delete your infra configuration."
    read -p "Are you sure?(Y/n)" -n 1 -r input
    echo
    if [[ ${input,,} == "y" ]]; then

        rm -rf "$BASE_DIR"
    elif [[ ${input,,} == "n" ]]; then
        log_info "Skipping deletion."
        exit 0
    else
        log_error "Invalid option passed."
        exit 1
    fi

    log_success "Deleted the entire infra configuration. Run '$0 setup' to start afressh"
}

# --- Usage Information ----------
usage() {
    log_header "${CYAN}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
    echo ""
    log_header "Usage: $0 <command>"
    echo ""
    log_header "Commands:"
    log_info "  init || setup  : Creates the basic Terraform directory and file structure."
    log_info "  fmt      : Formats all .tf files within the 'infra' directory."
    log_info "  validate : Validates all Terraform configurations in 'infra' directory."
    log_info "  structure : Shows the project directory structure."
    log_info "  clean : Removes terraform artifacts."
    log_info "  scan : Runs a secrurity scan against your configuration."
    log_info "  lint : Checks if your configuration requires formating. Used by CI to ensure consistency"
    log_info "  all      : Runs 'setup', 'fmt', and 'validate' in sequence."
    log_info "  -h, --help : Display this help message."
    echo ""
    log_header "Examples:"
    log_success "  $0 setup"
    log_success "  $0 fmt"
    log_success "  $0 validate"
    log_success "  $0 scan"
    log_success "  $0 all"
    echo ""
    log_info "Configuration (edit script to change):"
    log_info "  Modules base directory: $MODULES_BASE_DIR"
    log_info "  Module directories: ${MODULES_DIRS[*]}"
}

main() {
    # show usage and exit if no argument is passed.
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    command="${1,,}"
    case "$command" in
    "init" | "setup")
        setup_terraform_structure
        ;;
    "fmt" | "format")
        format_terraform_configs
        ;;
    "lint")
        lint_terraform_config "$0"
        ;;
    "validate")
        validate_terraform_configs
        ;;
    "scan" | "security")
        security_scan
        ;;
    "clean")
        clean_terraform
        ;;
    "delete")
        delete_structure "$0"
        ;;
    "structure" | "tree")
        show_structure
        ;;
    "all")
        setup_terraform_structure
        format_terraform_configs
        validate_terraform_configs
        ;;
    "help" | "-h" | "--help")
        usage
        ;;
    *)
        log_error "Error: '$1' is not a valid command"
        usage
        exit 1
        ;;
    esac
}

# Execute the main function only when called directly.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
else
    log_error "Error: The main function cannot be sourced"
    exit 1
fi
