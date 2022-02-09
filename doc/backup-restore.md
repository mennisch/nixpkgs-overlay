# Bookwyrm
## Database restoration process

    mv /root/bookwyrm.sql.gz /tmp
    chown postgres /tmp/bookwyrm.sql.gz
    sudo -i -u postgres
    psql
    DROP DATABASE bookwyrm;
    zcat /tmp/bookwyrm.sql.gz | psql

## file backup/restore
### images

    docker compose run --rm -v /tmp:/backup web bash -c "cd /app/images && tar cvzf /backup/bookwyrm-images.tar.gz ."
    docker compose run --rm -v /tmp:/backup web bash -c "cd /app/images && tar xzvf /backup/bookwyrm-images.tar.gz ."

### static files

    docker compose run --rm -v /tmp:/backup web bash -c "cd /app/static && tar cvzf /backup/bookwyrm-static.tar.gz ."
    docker compose run --rm -v /tmp:/backup web bash -c "cd /app/static && tar xzvf /backup/bookwyrm-static.tar.gz ."
