down:
	docker-compose down -v

up: down
	docker-compose up nginx

safe_users:
	for i in {19..29}; do curl -s "localhost:8080/m?token=$${i}ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"; done

abuser_users:
	watch -n 2 'curl -s "localhost:8080/m?token=0ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"'

simulate_users:
	wrk -c10 -t2 -d600s -s ./src/load_tests.lua --latency http://localhost:8080
