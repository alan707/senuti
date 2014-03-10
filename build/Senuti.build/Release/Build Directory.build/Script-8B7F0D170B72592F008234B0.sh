#!/bin/sh
# create the project directory if needed
if ( ! [ -e "$BUILT_PRODUCTS_DIR" ] ); then
  mkdir -p "$BUILT_PRODUCTS_DIR"
fi
