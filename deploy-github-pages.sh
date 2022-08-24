GIT_REV="$(git rev-parse HEAD)"&& \
rm -rf dist && \
rm -rf node_modules && \
npm install && \
NODE_ENV=prod npm run build && \
cd dist/ && \
git init && \
git remote add origin git@github.com:kenodressel/more-tokens.git && \
git checkout -b gh-pages && \
git add * && \
git commit -m "more monsters ${GIT_REV} deployment to gh-pages" && \
git fetch && git rebase -s recursive -Xtheirs origin/gh-pages && \
git push origin gh-pages
