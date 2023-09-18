for yaml in $(find . -type f -iname "*.custom.yaml"); do
    ln -sf $(pwd)/$yaml $(pwd)/../
done
