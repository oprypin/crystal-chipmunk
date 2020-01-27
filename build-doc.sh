#!/bin/bash

git_uri="$1"
docs_branch="gh-pages"

set -ex

# Change to script's directory
cd "$(dirname "$0")"

if [ -n "$git_uri" ]; then
    git clone -b "$docs_branch" -- "$git_uri" docs || true
fi

rm -rf -- docs/*

# Get current git commit's hash
rev="$(git rev-parse HEAD)"

crystal doc src/chipmunk.cr

cd docs

# Replace README link with title
title='<a style="font-size: 130%" href="https://github.com/oprypin/crystal-chipmunk">crystal-chipmunk</a>'
find . -type f -exec sed -i -r -e "s,<a.+>README</a>,$title," {} \;

# Redirect from / to /CP.html
cat << EOF > index.html
<!DOCTYPE HTML>
<html>
<head>
    <meta http-equiv="refresh" content="1;url=CP.html"/>
    <title>Redirecting...</title>
    <script type="text/javascript">
        window.location.href = "CP.html";
    </script>
</head>
<body>
    <a href="CP.html">Redirecting...</a>
</body>
</html>
EOF

if [ -n "$git_uri" ]; then
    git add -A
    if git commit -m "Generate API documentation ($rev)"; then
        git push origin "HEAD:$docs_branch" >/dev/null 2>/dev/null
    fi
fi
