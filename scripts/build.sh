source scripts/load-jekyll-version.sh
docker run --rm --volume="$PWD:/srv/jekyll:Z" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build