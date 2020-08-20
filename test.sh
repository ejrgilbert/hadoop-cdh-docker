SERVICE_PRECONDITION="blah blah2 blah3"
read -r -a check_if_up <<< "${SERVICE_PRECONDITION}"

for i in ${check_if_up[@]}; do
    echo "here is one: $i"
done
