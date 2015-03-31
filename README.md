# Infrastructure CLI configuration

This document defines configuration of a local *nix workstation to extend
bash functionality in aiding common infrastructure configuration issues.
It has builtin helpers for dealing with multiple cloud provider account
secrets as well as Chef specific configuration helpers.

## Setup

### Install tools

To start, the required collection of tools must be installed. To prepare the
system, create `bin` directory in the home directory:

```
$ mkdir ~/bin
```

Next, install the tools

* rvm (optional)
  * https://rvm.io/rvm/install
* hub
  * https://github.com/github/hub/releases
  * Place `hub` executable at: `~/bin/hub`
* direnv
  * https://github.com/zimbatm/direnv/releases
  * Place `direnv` executable at: `~/bin/direnv`
* bash-it
  * `git clone https://github.com/bash-it/bash-it.git ~/.bash_it`

### Configure bash

Bash must be configured to use the bash-it library. Start by running the
install script:

```
$ ~/.bash_it/install.sh
```

Now check the `~/.bash_profile` configuration to ensure the following items
exist, adding where they do not:

```bash
# ~/.bash_profile
export PATH=$PATH:~/bin
export BASH_IT=$HOME/.bash_it
export BASH_IT_THEME="bobby"
export EDITOR="/usr/bin/emacs"
export GIT_EDITOR="/usr/bin/emacs"

source $BASH_IT/bash_it.sh
```

### Enable infra tools

Now enable the infra tools by installing the plugin and enabling it:

```
$ curl -o ~/.bash_it/custom/infra.plugin.bash https://raw.githubusercontent.com/hw-labs/infra-config/master/infra.plugin.bash
$ ln -s ~/.bash_it/custom/infra.plugin.bash ~/.bash_it/plugins/enabled/infra.plugin.bash
```

and append `infra_commands_enable` to the `~/.bash_profile` file:

```
echo "infra_commands_enable" >> ~/.bash_profile
```

### Load tools

Local configuration is now complete. The terminal may be closed, and all new
instances will have the tooling auto-enabled. If you would like to load the
tools directly into the existing instance, force the profile to reload:

```
$ source ~/.bash_profile
```

## Usage

Navigate to your local infrastructure repository.

### Initialization

To start, the directory must be initialized:

```
$ infra-config
```

This will create a custom `.envrc` file for `direnv` to use. If a `.envrc`
file already exists the command will print an error and exit. If the file
already exists, back it up and remove the `.envrc` file. Then run the command
again.

### Configuration

#### Accounts

Open the newly created `.envrc` file and locate the "User edit section" at
the top of the file. This is pre-filled with AWS as the provider and us-west-1
as the current region. It is important to note the `PROVIDER_ACCOUNT` value
which will be set to `default`.

In the next section (AWS) values exist for the `DEFAULT_ACCESS_KEY_ID` and the
`DEFAULT_SECRET_ACCESS_KEY`. The prefix used `DEFAULT` matches the name set
within the `PROVIDER_ACCOUNT` environment variable. This allows defining
multiple "accounts" and storing their credentials by changing the prefix.
For example, lets assume two accounts are currently in use: `default` and
`production`. To support these two accounts, values are defined for each:

```bash
DEFAULT_ACCESS_KEY_ID="CHANGEME_DEFAULT"
DEFAULT_SECRET_ACCESS_KEY="CHANGEME_DEFAULT"
PRODUCTION_ACCESS_KEY_ID="CHANGEME_PRODUCTION"
PRODUCTION_SECRET_ACCESS_KEY="CHANGEME_PRODUCTION"
```

#### Chef

The infra tools provide helpers for Chef. Settings for these are located
within the "Chef settings" section. These variables work just like the
credential variables above with the `PROVIDER_ACCOUNT` prefix. However,
unlike the credential variables, if no value is defined for the current
`PROVIDER_ACCOUNT`, it will fallback to using the "DEFAULT" prefix.

### Usage

After completion of configuration, the prompt will update itself to reflect
the current state of the configuration. It will now provide a visual outputs
for:

* Current provider
* Current account
* Current region
* Encrypted data bag status (enabled/disabled)

### Commands

* `infra-provider ARG` switch to provider named `ARG`
* `infra-acct ARG` switch to account named `ARG`
* `infra-region ARG` switch to region named `ARG`
* `infra-crypt` toggle encrypted data bag on/off
