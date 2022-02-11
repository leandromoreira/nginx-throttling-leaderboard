run:
	docker run --rm \
		-p 8080:8080 -p 8081:8081 \
		-v `pwd`/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf \
		-v `pwd`/src:/lua/src \
		openresty/openresty

safe_users:
	for i in {19..29}; do curl -s "localhost:8080/m?token=$${i}ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"; done

abuser_users:
	watch -n 2 'curl -s "localhost:8080/m?token=0ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"'
