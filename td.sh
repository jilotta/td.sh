#!/bin/sh
# = = = = = = = = = = = = = = = = #
# td.sh - a lightweight todo      #
# viewer, creator and remover     #  
# written in POSIX shell script.  #
#                                 #
# td is a great alternative to:   #
# - t (github.com/sjl/t)          #
# - plain .txt file               #
# = = = = = = = = = = = = = = = = #

if [ -n "${TD_FILE}" ]; then 
    file="${TD_FILE}"
elif [ -z "${file}" ]; then
    file="todo.txt"
fi

if [ -n "${TD_SEP}" ]; then
    sep="${TD_SEP}"
elif [ -z "${sep}" ]; then
    sep=": "
fi

MAX_COUNT=9999

mkstemp() { echo "mkstemp(/tmp/$1-XXXXXX)" | m4; }
posix_random() { echo $(( $(od -An -tu -N3 /dev/urandom) % ($1 + 1) )); }

sort_file() {
    tmpfile=$(mkstemp tdsh-sort)
    
    sort -n -t "$(printf %.1s "$sep")" -k 1 < "$file" | sed '/^[[:blank:]]*$/d' > "$tmpfile"
    mv "$tmpfile" "$file" &&
    rm -f "$tmpfile"
}

generate_id() {
    x="1"
    while grep -q "^$x" "$file"; do
        # pick another id until there are no lines that begin with the id
        if [ "$(wc -l < "$file")" -lt $MAX_COUNT ]; then
            x=$(posix_random $MAX_COUNT)
        else
            x=$(( $(posix_random $(( $(wc -l < "$file") - MAX_COUNT )) ) + MAX_COUNT + 1 ))
        fi
    done
    
    echo "$x"
}

task_add() {
    id="$(generate_id)"
    
    if grep -q "$sep$*" "$file"; then
        echo "Similar task(s) found:"
        grep "$sep$*$" "$file"
    else
        echo "$id$sep$*" >> "$file"
        echo "Task #$id added successully"
    fi
}

task_complete() {
    if grep -q "^$1" "$file"; then
        tmpfile=$(mkstemp tdsh)

        grep -v "^$1" "$file" > "$tmpfile" &&
        mv "$tmpfile" "$file" &&
        rm -f "$tmpfile"
    else
        echo "No task with id $* found."
        exit 1
    fi
}

task_complete_confirm() {
    if grep -q "^$1" "$file"; then
        echo "You want to delete task #$(grep "^$1" "$file")"
        
        printf "Did you complete it? [y/N] "
        read -r choice
        
        if [ "$choice" = "y" ]; then
            task_complete "$@"
        else
            echo "Task completion cancelled."
        fi
    else
        echo "No task with id $* found."
        exit 1
    fi
    
}

task_edit() {
    tmpfile=$(mkstemp tdsh-edit)
    task_id=$1
    shift
    grep -v "^$task_id" "$file" > "$tmpfile"
    
    if [ "$(printf %.1s "$*")" = "/" ]; then
        grep "^$task_id" "$file" | sed "s$*" > "${tmpfile}"
    else
        echo "${task_id}${sep}${*}" > "${tmpfile}"
    fi
    
    mv "$tmpfile" "$file"
}

main() {
    progname="$1"
    shift
    case "$@" in
        '') cat "$file";; # if no arguments, then read the file
        [0-9]*) task_complete_confirm "$@";; # if id, then complete the iask #id
        *) case $1 in
            "-g") shift; grep "$@" "$file";;
            "-a") shift; task_add "$@";; # if you need 2 add some numbers
            "-f") shift; task_complete "$@";;
            "-c"|"-r") shift; task_complete_confirm "$@";;
            "-e") shift; task_edit "$@";;
            "-h"|"--help") echo "$progname help"
                           echo "================================"
                           echo "no arguments | read the file"
                           echo "-f num       | complete the task with id <num>"
                           echo "-c num       | complete the task with the id <num> with confirmation"
                           echo "-r num       | same as -c"
                           echo "<number>     | same as -c"
                           echo "-g pattern   | search a todo list for a pattern <pattern>"
                           echo "-a task      | Add task <task> into the list"
                           echo "<non-number> | same as -a"
                           echo "-e id text   | change the text of task #<id> to <text>"
                           echo "-e id sedstr | use the \`sed s<sedstr>\` command on task #<id>"
                           echo "-h or --help | show this help"
                           echo "-v           | show the version of $progname"
                           echo "--version    | same as -v";;
            '-v'|'--version') echo "$progname v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1 by myrix";;
            *) task_add "$@";;
        esac;;
    esac
    sort_file
}

main "$0" "$@"
