#!/bin/sh

markdown_preview_nvim=$HOME/.local/share/nvim/site/pack/plugins/start/markdown-preview.nvim/
pushd "$markdown_preview_nvim" 2> /dev/null && yarn install && popd

nvim -U NONE -c 'helptags ALL | quit'
