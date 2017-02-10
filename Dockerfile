FROM node:7
MAINTAINER Octoblu <docker@octoblu.com>

ENV NPM_CONFIG_LOGLEVEL error

EXPOSE 80

HEALTHCHECK CMD curl --fail http://localhost:80/healthcheck || exit 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN npm install --silent --global yarn

COPY package.json yarn.lock /usr/src/app/

RUN yarn install

COPY . /usr/src/app

CMD [ "node", "--max_old_space_size=256", "command.js" ]
