source scripts/load-jekyll-version.sh
docker run --volume="$PWD:/srv/jekyll" -p 127.0.0.1:4000:4000 -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve --watch --drafts
