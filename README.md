# maintain_music_collection

Perl helper scripts for maintaining personal music collection.

## Executing from shell
Mount windows folder providing the files **iTunes Music Library.xml** and **scrobbles.json**.
Set environment variable and run itunes_db.pl.

    export ITUNES_MUSIC_LIBRARY='/mnt/win_Music/iTunes/iTunes Music Library.xml'; ./itunes_db.pl

Set environment variable and run lastfm_db.pl.
    export LFM_SCROBBLES='/mnt/win_Music/iTunes/scrobbles.json'

## Docker commands
Tests with single YugabyteDB node.

    docker pull yugabytedb/yugabyte:2.18.2.1-b1

    docker run -d --name yugabyte  -p7000:7000 -p9000:9000 -p5433:5433 -p9042:9042 \
    yugabytedb/yugabyte:2.18.2.1-b1 bin/yugabyted start --daemon=false
    
    docker exec -it yugabyte /home/yugabyte/bin/ysqlsh --echo-queries

Build container for collecting iTunes data.

    cd ./itunes
    DOCKER_BUILDKIT=1 docker build .
    
