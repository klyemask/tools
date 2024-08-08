#!/bin/bash

# Script name
SCRIPT_NAME=$(basename "$0")

# Function to display usage/help message
usage() {
    echo "Usage: $SCRIPT_NAME [options] --commands <command1;command2;...> [--servers <servers> | --servers-file <file>] [--sudo] [--dzdo] [--log <file>]"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo ""
    echo "Arguments:"
    echo "  --commands             Semicolon-separated list of commands to execute on remote servers (use quotes for commands with spaces)"
    echo "  --servers              Comma-separated list of servers (e.g., 'server1,server2,server3')"
    echo "  --servers-file         CSV file containing list of servers"
    echo "  --sudo                 Use sudo to execute the commands"
    echo "  --dzdo                 Use dzdo to execute the commands"
    echo "  --log                  Log output to specified file"
    echo ""
    echo "Example:"
    echo "  $SCRIPT_NAME --commands 'dnf -y update; systemctl restart httpd' --servers 'server1,server2' --sudo"
    echo "  $SCRIPT_NAME --commands 'dnf -y update; systemctl restart httpd' --servers-file 'servers.csv' --sudo --log 'output.log'"
}

# Function for argument parsing
parse_arguments() {
    while [[ "$1" != "" ]]; do
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
            --commands)
                shift
                COMMANDS="$1"
                ;;
            --servers)
                shift
                SERVERS="$1"
                ;;
            --servers-file)
                shift
                SERVERS_FILE="$1"
                ;;
            --sudo)
                USE_SUDO=true
                ;;
            --dzdo)
                USE_DZDO=true
                ;;
            --log)
                shift
                LOG_FILE="$1"
                ;;
            *)
                echo "Invalid option or argument: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# Function to validate required arguments
validate_arguments() {
    if [[ -z "$COMMANDS" ]]; then
        echo "Error: Missing required arguments."
        usage
        exit 1
    fi

    if [[ -z "$SERVERS" && -z "$SERVERS_FILE" ]]; then
        echo "Error: You must specify either --servers or --servers-file."
        usage
        exit 1
    fi

    if [[ -n "$SERVERS" && -n "$SERVERS_FILE" ]]; then
        echo "Error: You cannot specify both --servers and --servers-file at the same time."
        usage
        exit 1
    fi

    if [[ -n "$USE_SUDO" && -n "$USE_DZDO" ]]; then
        echo "Error: You cannot use both --sudo and --dzdo options at the same time."
        usage
        exit 1
    fi
}

# Function to read password securely
read_password() {
    echo -n "Enter SSH password: "
    read -s SSH_PASSWORD
    echo
}

# Function to read servers from a CSV file
read_servers_file() {
    if [[ -n "$SERVERS_FILE" ]]; then
        if [[ ! -f "$SERVERS_FILE" ]]; then
            echo "Error: Servers file '$SERVERS_FILE' not found."
            exit 1
        fi
        SERVERS=$(cat "$SERVERS_FILE" | tr '\n' ',' | sed 's/,$//')
    fi
}

# Main logic function
main() {
    IFS=',' read -r -a server_array <<< "$SERVERS"
    IFS=';' read -r -a command_array <<< "$COMMANDS"
    
    for server in "${server_array[@]}"
    do
        echo "Executing commands on $server..."
        
        for command in "${command_array[@]}"
        do
            if [[ -n "$USE_SUDO" ]]; then
                REMOTE_COMMAND="echo $SSH_PASSWORD | sudo -S $command"
            elif [[ -n "$USE_DZDO" ]]; then
                REMOTE_COMMAND="echo $SSH_PASSWORD | dzdo -S $command"
            else
                REMOTE_COMMAND="$command"
            fi
            
            sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$server" "$REMOTE_COMMAND"
            SSH_EXIT_STATUS=$?

            if [ $SSH_EXIT_STATUS -eq 0 ]; then  # Check if the SSH command was successful
                echo "Command '$command' on $server executed successfully."
            else
                echo "Failed to execute command '$command' on $server."
            fi
        done
    done

    echo "All commands executed."
}

# Parse and validate arguments
parse_arguments "$@"
validate_arguments

# Read the password securely
read_password

# Read the list of servers from the CSV file if provided
read_servers_file

# If log file is specified, log the date and redirect output to the log file
if [[ -n "$LOG_FILE" ]]; then
    echo "=================================================================================" >> "$LOG_FILE"
    echo "=================================================================================" >> "$LOG_FILE"
	date >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# Call the main function with parsed arguments
main



#          /\  /\
#          *******
#         **O**O **
#         *********
#          **NSA**
#         *********
#        ***********
#        ************
#       **************
#       **************
#        ************
#     ||||||||||||||||||
#     ||klye-was-here|||
#     ||||||||||||||||||
