#!/usr/bin/env bash

VerifyPwd () {
    FOLDER_NAME=$(pwd)
    # APP_NAME=$(basename $FOLDER_NAME)

    # echo -n "Please enter the name of the app (press enter for '$APP_NAME'): "
    # read OVERRIDE_APP
    # if [ -n "$OVERRIDE_APP" ]
    # then
    #     APP_NAME=$OVERRIDE_APP
    # fi
}

SetDomainFromFile () {
    FILE_PATH=$1

    SERVER_NAME_DIRECTIVE=$(grep "server_name" "$FILE_PATH")
    DOMAIN=$(awk -F" " '{print $2}' <<< $SERVER_NAME_DIRECTIVE | tr -d ";")
}

TestAndReloadNginx () {
    if ! nginx -t; then
        echo "Nginx test failed, not sure why. Better try and fix whatever happened!"
        exit 1
    fi

    echo "Reloading nginx..."
    nginx -s reload
    echo "Done."
}

RunCertbot () {
    docker run -it --rm \
        -v /var/www/certbot:/var/www/certbot:rw \
        -v /etc/nginx/ssl:/etc/letsencrypt:rw \
        certbot/certbot:latest \
        $@
}

TryDeleteSymlink () {
    local TITLE=$1
    local FILE_PATH=$2

    if [[ -L "$FILE_PATH" ]]
    then
        echo "Deleting $TITLE symlink '$FILE_PATH'..."
        rm $FILE_PATH
    else
	echo "No $TITLE symlink '$FILE_PATH' found to delete."

        if [[ -f "$FILE_PATH" ]]
        then
            echo "Deleting $TITLE file '$FILE_PATH'..."
            rm $FILE_PATH
        else
            echo "No $TITLE file '$FILE_PATH' found to delete."
        fi
    fi
}

TryCreateSymlink () {
    local TITLE=$1
    local SOURCE_PATH=$2
    local TARGET_PATH=$3

    echo "Linking $TITLE from '$SOURCE_PATH' to '$TARGET_PATH'..."
    ln -f $SOURCE_PATH $TARGET_PATH
}

InstallNginx () {
    VerifyPwd

    HTTP_CONF_PATH=$FOLDER_NAME/http
    HTTPS_CONF_PATH=$FOLDER_NAME/https

    if [[ ! -f "$HTTP_CONF_PATH" ]]
    then
        echo "Didn't find http file."
        exit 1
    fi

    # TODO: Add above file checking to SetDomainFromFile to make commands DRY
    # TODO: Add HTTP / HTTPS comparison and validation to SetDomainFromFile to make commands DRY
    SetDomainFromFile $HTTP_CONF_PATH $HTTPS_CONF_PATH
    # TODO: Add below error checking to SetDomainFromFile to make commands DRY

    if [ -z "$DOMAIN" ]
    then
        echo "No domain found in http nginx file."
        exit 1
    fi

    HTTP_TARGET_PATH=/etc/nginx/conf.d/$DOMAIN.http.conf
    HTTPS_TARGET_PATH=/etc/nginx/conf.d/$DOMAIN.https.conf

    echo "Symlinking http config to $HTTP_TARGET_PATH..."
    ln -s $HTTP_CONF_PATH $HTTP_TARGET_PATH
    TestAndReloadNginx

    if [[ ! -f "$HTTPS_CONF_PATH" ]]
    then
        echo "Didn't find https so skipping certbot install."
        echo "Nginx installation complete. Go to http://$DOMAIN/ to check that it worked."
        exit 1
    fi

    echo "Found https config, running certbot dry run..."

    echo "[CERTBOT DRY RUN]"
    RunCertbot certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d $DOMAIN
    read -p "Press enter if the dry run was successful, [Ctrl+C] if not."
        
    echo "[CERTBOT INSTALL]"
    RunCertbot certonly -n --webroot --webroot-path /var/www/certbot/ -d $DOMAIN
    read -p "Press enter if the cert creation was successful, [Ctrl+C] if not."
        
    echo "[NGINX HTTPS CONFIG]"
    echo "Symlinking https config to $HTTPS_TARGET_PATH..."
    ln -s $HTTPS_CONF_PATH $HTTPS_TARGET_PATH
    TestAndReloadNginx

    echo "Cert installation complete. Go to https://$DOMAIN/ to check that it worked."
}


UninstallNginx () {
    VerifyPwd

    HTTP_CONF_PATH=$FOLDER_NAME/http
    HTTPS_CONF_PATH=$FOLDER_NAME/https

    if [[ ! -f "$HTTP_CONF_PATH" ]]
    then
        echo "Didn't find http file."
        exit 1
    fi

    SetDomainFromFile $HTTP_CONF_PATH $HTTPS_CONF_PATH

    if [ -z "$DOMAIN" ]
    then
        echo "No domain found in http nginx file."
        exit 1
    fi

    HTTP_TARGET_PATH=/etc/nginx/conf.d/$DOMAIN.http.conf
    HTTPS_TARGET_PATH=/etc/nginx/conf.d/$DOMAIN.https.conf

    TryDeleteSymlink "http symlink" "$HTTP_TARGET_PATH"
    TryDeleteSymlink "https symlink" "$HTTPS_TARGET_PATH"

    TestAndReloadNginx

    echo "[CERTBOT UNINSTALL]"
    RunCertbot delete -n --webroot --webroot-path /var/www/certbot/ --cert-name $DOMAIN
        
    echo "Uninstallation complete. Go to https://$DOMAIN/ to check that it no longer works."
}

