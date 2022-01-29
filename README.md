# Prerequisites

It is expected that you have the following software already on your system.

- Docker (for running Postgres and Redis)
- `rbenv`
- `ruby 3.1.0` (installed via `rbenv`)
- `node` (pretty much any version)
- `yarn` (pretty much any version)

# Setup

## Clone the repository

```shell
git clone git@github.com:calebschoepp/canvasync.git
cd canvasync
```

## Install dependencies

```shell
bin/bundle install
yarn install
```

## Set environment variables with Figaro

TODO

## Initialize database

See **Running in devlopment** for how to start your database.

```shell
rails db:create
rails db:migrate
```

# Running in development

## Start Postgres

TODO: Ignore this for now, just using Sqlite locally

## Start Redis

TODO: Ignore this for now, not needed

## Serve

The following will run the rails server, a js compiler on watch mode, and a css compiler on watch mode. To see the commands to run them individually look at `Procfile.dev`.

```shell
bin/dev
```

Now you can see the app at http://localhost:3000.

# Testing

```shell
bin/rails test
bin/rails test:system
```

# Debugging

To open up a live REPL session in the context of the server run:

```shell
rails console
```

To set a breakpoint in your code that starts a REPL session insert the line `debugger` somewhere. Note that to use `debugger` you will need to start the server individually with:

```shell
bin/rails server
```

# Running in production

## Add Heroku remotes

TODO

## Pushing code

TODO

## Migrations

TODO
