#!/usr/bin/env bash
__BASEDIR="$(readlink -f "$(dirname "$0")")";if [[ -z "$__BASEDIR" ]]; then echo "__BASEDIR: undefined";exit 1;fi

installPackageIfCommandNotFound() {
  local cmd="$1"
  local pkg="$2"

  if ! command -v ${cmd}; then
    DEBIAN_FRONTEND=noninteractive \
    apt-get update \
    && apt-get install -y -qq \
      ${pkg} \
    && rm -rf /var/lib/apt/lists/* \
    || return $?
  fi

}


optimizeLibJvm(){
  local outputDir="$1"

  echo "Built JRE: $(du -sh "$outputDir")"

  # See: https://github.com/docker-library/openjdk/issues/217
  echo "... optimizing libjvm.so size ..."

  installPackageIfCommandNotFound strip binutils

  strip -p --strip-unneeded "$outputDir/lib/server/libjvm.so" \
  || return $?

  echo "Built JRE: $(du -sh "$outputDir")"
}

optimizeJars(){
  local file="$1"

  echo "... optimize JARs size ..."
  installPackageIfCommandNotFound advzip advancecomp

  for file in "$@"; do
    advzip -4 -a "$file.recompress" "$file" \
    && ls -ldh "$file.recompress" "$file" \
    && rm -f "$file" \
    && mv "$file.recompress" "$file" \
    || return $?
  done
}

main(){
  local unpackDir="$1"
  shift
  local outputDir="$1"
  shift
  local jars="$@"
  local unpackDir=""

  for f in ${jars}; do
    if [[ ! -f "$f" ]]; then
      echo "ERROR : JAR introuvable: $f"
      return 1
    fi
  done

  local _retCode=0

  echo "> - Output directory: $outputDir"

  if [[ ! -z "$unpackDir" ]]; then
    echo "> - JARs: $jars"
    echo "> - Unpack Dir: $unpackDir"
    mkdir -p "$unpackDir"

    pushd "$unpackDir" > /dev/null
      for f in ${jars}; do
        echo "> - Unzip $f into: $unpackDir"
        jar xf "$springBootArtifact"
      done
      jars=$(find "$unpackDir" -name '*.jar')
    popd > /dev/null
  fi

  echo "> [jdeps] Find modules for:"
  echo "$jars" | tr ' ' '\n'

  local modules=`jdeps --multi-release 11 --list-deps ${jars} \
    | sed -E 's, +,,' \
    | grep -v -E 'java.base/sun.security.util|java.base/sun.security.x509' \
    | tr '\n' ',' \
    | sed -E 's/^,|,$//g' \
  `
  echo "> [jlink] Build JRE with modules:"
  echo "$modules" | tr ',' '\n'

  jlink \
    --verbose \
    --no-header-files \
    --no-man-pages \
    --compress=2 \
    --strip-debug \
    --add-modules "$modules" \
    --output "$outputDir" \
  || return $?

  optimizeLibJvm "$outputDir"

  # Uncomment following line to recompress JAR files
  #optimizeJars ${jarsList}
}

main "$@"

exit $?
