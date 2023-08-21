# maintain_music_collection

Perl helper scripts for maintaining personal music collection.

## Docker commands
Tests with single Cassandra container.

    docker run -p 9042:9042 --rm --name cassandra -d cassandra:latest

Executing interactive cqlsh.

    docker exec -it cassandra cqlsh

Build container for collecting iTunes data.

    cd ./itunes
    DOCKER_BUILDKIT=1 docker build .
    
