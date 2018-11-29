#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${SCRIPT_PATH}/scripts/includes/colors.sh

DEFAULT_DOMAIN="docker.test"

if [ "$ENV" == "production" ]
then
    COMPOSE_PATH="${SCRIPT_PATH}/environments/production"
    PROJECT_NAME="test"
    PRODUCTION=true
elif [ "$ENV" == "staging" ]
then
    COMPOSE_PATH="${SCRIPT_PATH}/environments/staging"
    PROJECT_NAME="staging.test"
else
    COMPOSE_PATH="${SCRIPT_PATH}/environments/development"
    PROJECT_NAME="sandbox.test"
fi

COMPOSE_FILE="${COMPOSE_PATH}/docker-compose.yml"

DOCKER_ID="xxxxxx"
DOCKER_REPOSITORY="${DOCKER_ID}/cdtsys-api"

#######################
# Helper Functions
#######################

# Prefix the docker-compose command with project setup options
function docker-compose {
    pushd ${COMPOSE_PATH} > /dev/null
    command docker-compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} ${@}
    popd > /dev/null
}

# Show a confirmation prompt
function confirm {
    echo -e -n "${LRED}Are you sure that you want to run this command? [y/N] ${RESTORE}"
    read -n 1 -r

    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
}

#######################
# Commands declaration
#######################

# Command: compose
# Run docker-compose command with given parameters
function command_compose {
    docker-compose ${@}
}

# Command: exec
# Run docker-compose exec as current user on given container
function command_exec {
    docker-compose exec --user ${UID} ${@}
}

# Command: bash
# Open bash as current user
function command_bash {
    docker-compose exec --user ${UID} www /bin/bash
}

# Command: bash:root
# Open bash as root
function command_bash_root {
    docker-compose exec www /bin/bash
}

# Command: up
# Create and start project containers
function command_up {
    # If .env does not exist on src path
    if [ ! -f src/.env ]; then
        # Copy our sample .env file to src path
        cp ${SCRIPT_PATH}/.env.docker ${SCRIPT_PATH}/src/.env
    fi

    docker-compose up -d ${@}
    docker-compose exec www useradd -ms /bin/bash -u $(id -u) $(whoami)
    docker-compose exec www apt update
    docker-compose exec www apt install -y php7.2-sqlite
}

# Command: down
# Stop and remove project containers
function command_down {
    docker-compose down ${@}
}

# Command: ps
# Run `docker-composer ps`
function command_ps {
    docker-compose ps ${@}
}

# Command: pull
# Pull latest container images
function command_pull {
    docker-compose pull ${@}
}

# Command: bind
# Bind hostname to container IP
function command_bind {
    ARG_DOMAIN=${DEFAULT_DOMAIN}

    while getopts ":d:" opt; do
        case ${opt} in
            d)
                ARG_DOMAIN=$OPTARG
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
            ;;
            \:)
                echo "Missing arguments to option: -$OPTARG" >&2
                exit 1
            ;;
        esac
    done
    shift $(($OPTIND - 1))

    echo "The sudo password may be asked to allow writing to hosts file."
    sudo echo -n

    if [ $? != 0 ]; then
        echo "You must provide a valid sudo password to run this command."
        exit 1
    fi

    # Remove any existing entry for HOST on /etc/hosts
    # and point HOST to our www service IP
    sudo sed -i'' -e '/\s'"${ARG_DOMAIN}"'$/d' /etc/hosts
    echo "127.0.0.1 ${ARG_DOMAIN}" | sudo tee -a /etc/hosts
    echo "Hostname \"${ARG_DOMAIN}\" bound to container."

    if [ "$(uname)" == "Darwin" ]; then
        echo "OS X detected. Flushing DNS Cache and restarting mDNSResponder"
        dscacheutil -flushcache; sudo killall -HUP mDNSResponder
    fi
}

# Command: artisan
# Run artisan command on www application
function command_artisan {
    command_exec www php /var/www/artisan ${@}
}

# Command: tinker
# Run artisan tinker command on www application
function command_tinker {
    command_exec www php /var/www/artisan tinker ${@}
}

# Command: composer
# Run composer on www application
function command_composer {
    # If no parameter was passed, show composer help
    if [ -z ${1} ]; then
        command_exec www composer
        exit $?
    fi

    command_exec www composer ${@} -d /var/www
}

# Command: migrate
# Migrate database on www application
function command_migrate {
    command_artisan migrate ${@}
}

# Command: seed
# Seed database on www application
function command_seed {
    command_artisan db:seed -n ${@}
}

# Command: install
# Install dependencies to www application
function command_install {
    command_exec www mkdir /var/www/storage/app /var/www/storage/thumbnail /var/www/storage/attachments /var/www/storage/framework /var/www/storage/framework/cache /var/www/storage/framework/sessions /var/www/storage/framework/views
    command_setup_permissions
    command_composer install --prefer-dist
    command_exec www php /var/www/artisan key:generate
    command_migrate
    command_exec www php /var/www/artisan role:refresh
}

# Command: phpunit
# Run phpunit tests on www application
function command_phpunit {
    command_exec www /var/www/vendor/bin/phpunit -c /var/www/phpunit.xml ${@}
}

# Comand: phpcs
# Run phpcs tests on www application
function command_phpcs {
    command_exec www /var/www/vendor/bin/phpcs --standard=/var/www/phpcs.xml ${@}
}

# Comand: phpcbf
# Run phpcbf tests on www application
function command_phpcbf {
    command_exec www /var/www/vendor/bin/phpcbf --standard=/var/www/phpcs.xml ${@}
}

# Command: setup:permissions
# Setup file permissions for the Laravel based project
function command_setup_permissions {
    echo -e "${YELLOW}Setting file permissions for /var/www${RESTORE}"
    # Files should belong to current user and www-data group
    echo -e "- Setting ownership to $(whoami):www-data"
    docker-compose exec www chown -R $(whoami):www-data /var/www/
    echo -e "- Setting directories permissions to 755"
    docker-compose exec www "find /var/www/ -type d -exec chmod 755 {} ;"
    echo -e "- Setting files permissions to 644"
    docker-compose exec www "find /var/www/ -type f -exec chmod 644 {} ;"
    echo -e "- Setting storage folder permissions to 775"
    docker-compose exec www "find /var/www/storage/ -type d -exec chmod 775 {} ;"
    echo -e "- Setting bootstrap/cache permissions to 775"
    docker-compose exec www "chmod -R 775 /var/www/bootstrap/cache"
    echo -e "- Setting vendor/bin permissions to +x"
    docker-compose exec www "find /var/www/vendor/bin -type l -exec chmod +x {} ;"
    echo -e "Done!"
}

function command_help {
    echo -e "${YELLOW}Usage:
    ${RESTORE}$(basename "$0") [command] [options]

${YELLOW}Docker related commands
    ${GREEN}up                  ${RESTORE}Create and start project containers
    ${GREEN}down                ${RESTORE}Stop and remove project containers
    ${GREEN}compose             ${RESTORE}Run 'docker-compose'
    ${GREEN}ps                  ${RESTORE}Run 'docker-compose ps'
    ${GREEN}exec                ${RESTORE}Run 'docker-compose exec' as current user on given container
    ${GREEN}pull                ${RESTORE}Pull latest container image versions
    ${GREEN}bash                ${RESTORE}SSH into the www container as current user
    ${GREEN}bash:root           ${RESTORE}SSH into the www container as root

${YELLOW}Application commands:
    ${GREEN}install             ${RESTORE}Install dependencies and setup application to run
    ${GREEN}artisan             ${RESTORE}Run artisan on www application
    ${GREEN}tinker              ${RESTORE}Run artisan tinker on www application
    ${GREEN}composer            ${RESTORE}Run composer on www application
    ${GREEN}phpunit             ${RESTORE}Run phpunit on www application
    ${GREEN}phpcs               ${RESTORE}Run phpcs on www application
    ${GREEN}phpcbf              ${RESTORE}Run phpcbf on www application
    ${GREEN}migrate             ${RESTORE}Shortcut to 'artisan migrate'
    ${GREEN}seed                ${RESTORE}Shortcut to 'artisan db:seed'
    ${GREEN}setup:permissions   ${RESTORE}Setup file permissions for the Laravel based project

${YELLOW}Other commands:
    ${GREEN}bind [-d=domain]    ${RESTORE}Bind domain to www container
    ${GREEN}help                ${RESTORE}Show this help message"
}

#########################
# Execution
#########################

COMMAND=${1//:/_}
if [ -z ${COMMAND} ]; then
    echo "You must provide a command."
    echo ""
    command_help
    exit 1
fi

if [ -n "$(type -t command_${COMMAND})" ]; then
    shift
    eval "command_${COMMAND} \"${@}\""
    exit $?
else
    echo "No such command:" ${1//_/:}
    echo ""
    command_help
    exit 1
fi
