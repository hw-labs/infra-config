# TODO: Can we check for functions prior?
#cite about-plugin
#about-plugin 'infra settings helpers'

## Add some simple helpers to get us rolling
function direnv_rc {
    direnv status | grep "Found RC path" | cut -d ' ' -f 4
}

function direnv_fload {
    direnv allow
    direnv reload
}

function current_infra_acct {
    echo ${PROVIDER_ACCOUNT:UNSET}
}

function current_infra_region {
    echo ${PROVIDER_REGION:UNSET}
}

function current_infra_provider {
    echo ${PROVIDER:UNSET}
}

function infra_error_msg {
    echo "${echo_red_bold}ERROR:${echo_reset_color} ${1}" >&2
}

function extract_infra_value {
    var="${INFRA_ACCOUNT}_${1}"
    val=${!var}
    if [[ -z val ]]
    then
        infra_error_msg "No value set for ${1} under account: ${PROVIDER_ACCOUNT}!"
        echo "UNSET"
    else
        echo ${!var}
    fi
}

function extract_infra_value_or_default {
    value=$(extract_infra_value ${1})
    if [[ value = '' ]]
    then
        var="${PROVIDER_ACCOUNT}_${1}"
        echo ${!var}
    else
        echo ${value}
    fi
}

## Define `infra-*` commands
function infra-config {
    about 'configures environment for infra'
    group 'infra'

    if [ -f .envrc ]
    then
        echo -e "${echo_bold_red}ERROR:${echo_reset_color} Will not overwrite existing .envrc file!"
    else
        cat << 'EOF' > .envrc
##### START: Helper loader (DO NOT MODIFY) #
source ~/.bash_it/custom/infra.plugin.bash #
##### END: Helper loader ###################

##### START: User edit section #####

# Provider settings
export PROVIDER="aws"
export PROVIDER_ACCOUNT="default"
export PROVIDER_REGION="us-east-1"

# AWS
DEFAULT_ACCESS_KEY_ID="CHANGEME"
DEFAULT_SECRET_ACCESS_KEY="CHANGEME"

# Chef settings
CHEF_ENABLED="yes"
DEFAULT_KNIFE_USER="${USER:UNSET}"
DEFAULT_KNIFE_CHEF_SECRET_FILE_PATH=""
DEFAULT_KNIFE_CHEF_SERVER_URL=""
DEFAULT_KNIFE_CLIENT_KEY=""

DEFAULT_SSH_IDENTITY_FILE="CHANGEME"

##### END: User edit section #####

##### START: Infra configuration (DO NOT MODIFY) #####
INFRA_PROVIDER=`echo ${PROVIDER} | tr '[:lower:]' '[:upper:]'`
INFRA_ACCOUNT=`echo ${PROVIDER_ACCOUNT} | tr '[:lower:]' '[:upper:]'`
export KNIFE_CHEF_ENCRYPTED="OFF"

if [[ $CHEF_ENABLED = "yes" ]]
then
    export KNIFE_USER=$(extract_infra_value "KNIFE_USER")
    export KNIFE_CHEF_SECRET_FILE_PATH=$(extract_infra_value_or_default "KNIFE_CHEF_SECRET_FILE_PATH")
    export KNIFE_CHEF_SERVER_URL=$(extract_infra_value_or_default "KNIFE_CHEF_SERVER_URL")
    export KNIFE_CHEF_CLIENT_KEY=$(extract_infra_value_or_default "KNIFE_CHEF_CLIENT_KEY")
    if [[ $KNIFE_CHEF_ENCRYPTED = "ON" ]]
    then
        export KNIFE_CHEF_SECRET_FILE="${KNIFE_CHEF_SECRET_FILE_PATH}"
    fi
fi

if [[ $INFRA_PROVIDER = "AWS" ]]
then
    export AWS_ACCESS_KEY_ID=$(extract_infra_value "ACCESS_KEY_ID")
    export AWS_SECRET_ACCESS_KEY=$(extract_infra_value "SECRET_ACCESS_KEY")
    export AWS_REGION="${PROVIDER_REGION}"
    export AWS_DEFAULT_REGION="${PROVIDER_REGION}"
elif [[ $INFRA_PROVIDER = "OPENSTACK" ]]
then
    echo 'Not implemented'
elif [[ $INFRA_PROVIDER = "RACKSPACE" ]]
then
    echo 'Not implemented'
else
    echo "ERROR: Unknown provider set - ${PROVIDER}"
fi

export KNIFE_SSH_KEY=$(extract_infra_value_or_default "SSH_IDENTITY_FILE")
export DIRENV_LOG_FORMAT=""

##### END: Infra configuration #####
EOF
        echo "Initialized direnv!"
        direnv_fload
    fi
}

function infra-crypt {
    about 'toggles chef data bag encryption'
    group 'infra'

    echo -e -n "${echo_bold_black}Data bag item encryption:${echo_reset_color} "
    if [[ $KNIFE_CHEF_ENCRYPTED = 'ON' ]]
    then
        sed -i bak "s/export KNIFE_CHEF_ENCRYPTED=.*/export KNIFE_CHEF_ENCRYPTED=OFF/" $(direnv_rc)
        echo -e -n "${echo_red}disabled"
    else
        sed -i bak "s/export KNIFE_CHEF_ENCRYPTED=.*/export KNIFE_CHEF_ENCRYPTED=ON/" $(direnv_rc)
        echo -e -n "${echo_green}enabled"
    fi
    echo -e "${echo_reset_color}"
    direnv_fload
}

function infra-acct {
    about 'switch infra account'
    param '1: account name'
    example '$ infra-acct default'
    group 'infra'

    ACCT=${1:default}
    echo -e "${echo_bold_black}Account changed to:${echo_reset_color} ${echo_purple}${ACCT}${echo_reset_color}"
    sed -i bak "s/export PROVIDER_ACCOUNT=.*/export PROVIDER_ACCOUNT=${ACCT}/" $(direnv_rc)
    direnv_fload
}

function infra-provider {
    about 'switch infra provider'
    param '1: provider name'
    example '$ infra-provider aws'
    group 'infra'

    PROV=${1:aws}
    echo -e "${echo_bold_black}Provider changed to:${echo_reset_color} ${echo_purple}${PROV}${echo_reset_color}"
    sed -i bak "s/export PROVIDER=.*/export PROVIDER=${PROV}/" $(direnv_rc)
    direnv_fload
}

function infra-region {
    about 'switch infra region'
    param '1: region name'
    example '$ infra-region us-east-1'
    group 'infra'

    REGION=${1:unset}
    echo -e "${echo_bold_black}Region change to:${echo_reset_color} ${echo_purple}${REGION}${echo_reset_color}"
    sed -i bak "s/export PROVIDER_REGION=.*/export PROVIDER_REGION=${REGION}/" $(direnv_rc)
    direnv_fload
}

## Display helpers
function infra_account_display {
    if [[ $PROVIDER != '' ]]
    then
        echo -e "[${yellow}$(current_infra_provider)${orange}:${bold_blue}$(current_infra_acct)${orange}:${purple}$(current_infra_region)${orange}] "
    fi
}

function infra_data_bag_crypt_display {
    if [[ $KNIFE_CHEF_ENCRYPTED != '' ]]
    then
        if [[ $KNIFE_CHEF_ENCRYPTED = 'ON' ]]
        then
            echo -e "${red}{x} "
        else
            echo -e "${cyan}{-} "
        fi
    fi
}

# Configure prompt to display all information
function infra_command_prompt {
    PS1="\n${yellow}$(ruby_version_prompt) ${black}\h ${reset_color}in ${black}\w\n${bold_cyan}$(scm_char)${green}$(scm_prompt_info) ${orange}$(infra_account_display)${red}$(infra_data_bag_crypt_display)${green}→${reset_color} "
}

# Enable the commands
function infra_commands_enable {
    eval "$(direnv hook bash)"
    PROMPT_COMMAND="_direnv_hook;infra_command_prompt"
}
