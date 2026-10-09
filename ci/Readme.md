# How to run tests

6X:
```bash
docker run --rm -it -v .:/home/gpadmin/credcheck ghcr.io/greengagedb/greengage/ggdb6_ubuntu24.04:latest bash /home/gpadmin/credcheck/ci/test_in_docker.bash
```

7X:
```bash
docker run --rm -it -v .:/home/gpadmin/credcheck ghcr.io/greengagedb/greengage/ggdb7_ubuntu:latest bash /home/gpadmin/credcheck/ci/test_in_docker.bash
```
