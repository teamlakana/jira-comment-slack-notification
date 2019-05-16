ARG NODE_VERSION=8.9.4
FROM node:${NODE_VERSION}

WORKDIR /usr/src/app

# need public key for DocumentDB
RUN wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

ADD package*.json ./

# Set up dependencies
RUN npm install --production

ADD . .

EXPOSE 5000

CMD ["npm", "start", "5000"]
