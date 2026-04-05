if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

sudo route -n add -net $1 -interface utun10
