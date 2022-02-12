# nginx-throttling-leaderboard

```bash
 docker exec -it $(docker ps|grep redis|cut -f1 -d" ") /usr/local/bin/redis-cli monitor

 watch -n 5 -t  'docker exec -it $(docker ps|grep redis|cut -f1 -d" ") /usr/local/bin/redis-cli info memory | grep used_memory_human'
 ```
