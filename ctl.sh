#!/bin/bash

function help {
	echo "./ctl.sh help     Tela atual, help"
	echo "./ctl.sh restart  Reinicia containers"
	echo "./ctl.sh build    Recriar imagens containers"
	echo "./ctl.sh start    Inicia containers"
	echo "./ctl.sh stop     Para os containers"
	echo "./ctl.sh logs     Mostra o log de um container"
	echo "./ctl.sh exec     Acessar container"
	echo "./ctl.sh ssl     Gerar certificado SSL"
}

case "$1" in
	help)
		help
		shift
		;;
    build)
		docker-compose -f $2 down
		docker-compose -f $2 up -d --build
		docker ps
		shift
		;;
	restart)
		docker-compose -f $2 stop
		docker-compose -f $2 up -d
		docker ps
		shift
		;;
	start)
		docker-compose -f $2 up -d
		docker ps
		shift
		;;
	stop)
		docker-compose -f $2 down
		shift
		;;
    exec)
		docker exec -it $2 bash
		shift
		;;     
    logs)
		docker logs $2
		shift
		;;
	ssl)
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./docker/nginx/ssl/local/server-key.pem -out ./docker/nginx/ssl/local/server.pem
		shift
		;;
	*)
		echo "Parametro inválido [$1]"
		help
		exit 3
		;;
esac

exit 0