#!/bin/bash

# Vérifier si le conteneur est déjà en cours d'exécution et le lance si non
if [ ! "$(docker ps -q -f name=apache_php81)" ]; then
    docker-compose up -d
fi

# Lire et traiter les informations du fichier config.yml
projects=$(yq eval '.projects | keys | .[]' config.yml)
for project in $projects; do
    echo "DEBUT DU PROJET $project"

    project_name=$(yq eval '.projects."'$project'".project_name' config.yml | sed 's#/#\\/#g')
    document_root=$(yq eval '.projects."'$project'".document_root' config.yml  | sed 's#/#\\/#g')
    project_path=$(yq eval '.projects."'$project'".project_path' config.yml  | sed 's#/#\\/#g')

        echo "CREATION DU .CONF"

        # Créer le .conf
        docker exec apache_php81-webserver cp "/etc/apache2/sites-available/template.conf" "/etc/apache2/sites-available/${project_name}.conf"
        # Compléter le fichier .conf
        docker exec apache_php81-webserver sed -i "s/__document_root__/${document_root}/g" "/etc/apache2/sites-available/${project_name}.conf"
        docker exec apache_php81-webserver sed -i "s/__domain__/${project_name}/g" "/etc/apache2/sites-available/${project_name}.conf"
        # Activer le site
        docker exec apache_php81-webserver a2ensite "${project_name}.conf"

        echo "CREATION DU .CONF SSL"
        # Créer le .conf
        docker exec apache_php81-webserver cp "/etc/apache2/sites-available/template-ssl.conf" "/etc/apache2/sites-available/${project_name}-ssl.conf"
        # Compléter le fichier .conf
        docker exec apache_php81-webserver sed -i "s/__document_root__/${document_root}/g" "/etc/apache2/sites-available/${project_name}-ssl.conf"
        docker exec apache_php81-webserver sed -i "s/__domain__/${project_name}/g" "/etc/apache2/sites-available/${project_name}-ssl.conf"
        # Activer le site
        docker exec apache_php81-webserver a2ensite "${project_name}-ssl.conf"

    if ! grep -q "${project_name}.docker" /etc/hosts; then
        # Ajouter une entrée dans /etc/hosts pour le vhost du projet sur le Mac
        echo "127.0.0.1    ${project_name}.docker" | sudo tee -a /etc/hosts > /dev/null
    fi
done

docker exec apache_php81-webserver service apache2 reload