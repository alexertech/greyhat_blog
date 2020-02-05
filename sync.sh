#!/bin/sh
rsync -avz -e "ssh -p 7822 -i /home/alex/id_rsa_new" * alex@167.71.176.223:/var/www/blog --exclude '.git' --exclude 'sync.sh' --exclude 'tmp' --exclude 'log' --exclude 'node_modules'
