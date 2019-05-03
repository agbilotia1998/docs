#!/bin/bash -e

if [ ! -f /.dockerenv ]; then
  docker build -t mesg/docs:local -f Dockerfile.docs .

  docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/project mesg/docs:local ./generate-docs.sh
  exit
fi

VERSION=${version:-release-dev}

curl -sL https://github.com/mesg-foundation/core/archive/$VERSION.tar.gz | tar -xz

COREDIR=core-${VERSION#v}

PROJECT=$(pwd)
GRPC=$PROJECT/$COREDIR
cp generate.go $COREDIR

pushd $COREDIR
go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

echo "Generate API documentation"
API_DOCS="--doc_out=$PROJECT/api/ --doc_opt=$PROJECT/api.template"

protoc $API_DOCS,core.md --proto_path=$GRPC protobuf/coreapi/api.proto
protoc $API_DOCS,service.md --proto_path=$GRPC protobuf/serviceapi/api.proto

echo "Generate CLI documentation"
go run generate.go

popd

rm -rf $COREDIR
