# TODO Application with Quarkus


## Prerequisites

* You need the _master_ branch of Quarkus (or Quarkus 0.15.0+)

## Database

Run Locally:

```bash
docker run --ulimit memlock=-1:-1 -it --rm=true --memory-swappiness=0 \
    --name postgres-quarkus-rest-http-crud -e POSTGRES_USER=restcrud \
    -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud \
    -p 5432:5432 postgres:10.5
```

## Application

Run Locally:

```bash
mvn compile quarkus:dev
```

Open: http://localhost:8080/

## OpenShift

```bash
-- create db
oc new-project quarkus-todo-app
oc process --parameters postgresql-persistent -n openshift
oc new-app postgresql-persistent -p POSTGRESQL_USER=restcrud -p POSTGRESQL_PASSWORD=restcrud -p DATABASE_SERVICE_NAME=postgres -p POSTGRESQL_DATABASE=rest-crud
-- Change the Postgresql database to accept prepared statements
oc set env dc/postgres POSTGRESQL_MAX_PREPARED_TRANSACTIONS=100

-- deps from internet
oc new-build --name=quarkus-todo-app quay.io/quarkus/centos-quarkus-native-s2i:graalvm-1.0.0-rc16~https://github.com/eformat/quarkus-todo-app

-- use nexus.nexus.svc
oc new-build --name=quarkus-todo-app quay.io/eformat/quarkus-native-s2i:graalvm-1.0.0-rc16~https://github.com/eformat/quarkus-todo-app

-- can set limits for build (optional)
oc cancel-build bc/quarkus-todo-app
oc patch bc/quarkus-todo-app -p '{"spec":{"resources":{"limits":{"cpu":"1", "memory":"4Gi"}}}}'
oc start-build bc/quarkus-todo-app

-- thin image using native executable, will trigger on build image above
oc new-build --name=todo-app \
    --docker-image=registry.access.redhat.com/ubi8/ubi:8.0 \
    --source-image=quarkus-todo-app \
    --source-image-path='/home/quarkus/application:.' \
    --dockerfile=$'FROM registry.access.redhat.com/ubi8/ubi:8.0\nCOPY application /application\nCMD /application -Xmx8M -Xms8M -Xmn8M\nEXPOSE 8080' \
    --allow-missing-imagestream-tags

# wait for the build to finish (web console or `oc logs -f bc/todo-app`)
oc new-app todo-app
oc expose svc todo-app

# handy db commands
oc get pods -lapp=postgresql-persistent | awk '{print }'
oc rsh $(oc get pods -lapp=postgresql-persistent --template='{{range .items}}{{.metadata.name}}{{end}}')
sh-4.2$ psql -h localhost -d rest-crud -U postgres
-- all tables
\dt+
-- show schemas
\dn
```
