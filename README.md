# Oredev

This application shows how [GenStage](https://github.com/elixir-lang/gen_stage) can be used to model consumption of events from CouchDB.

CouchDB exposes an http endpoint that returns all changes made to the database, 1 json line per event. This endpoint can be streamed to replay the entire database history (for more details see <http://docs.couchdb.org/en/2.1.1/api/database/changes.html>). Any database change done while tailing the changes feed is instantly streamed to the consumer.

This application processes the CouchDB changes feed for a given database of Oredev sessions (see Setup - Step 1 to see how to create it) and calculates two schedules: one with events per day, another with events per topic. Schedules update almost instantly for each change done in CouchDB.

## Structure

The application contains two event processing implementations:

- A traditional pub sub implementation built on top of `Registry`. For each change captured by `Oredev.Changes.Feed`, an event is broadcasted asynchronously. Two subscribers, `Oredev.Subscriber.DailySchedule` and `Oredev.Subscriber.TopicSchedule` listen to these events to update their state. 

- A `gen_stage` based implementation. Every time `Oredev.Changes.Feed` captures an event, it publishes it synchronously to a producer, which is consumed by `Oredev.Consumer.DailySchedule` and `Oredev.Consumer.TopicSchedule`.

## Key differences

- When using pub sub, the feed publishes as soon as it receives an event. Being pub sub completely asynchronous, the feed can ingest events without any concern for the ability of the rest of the system to process them.

- When using the producer, the feed blocks to publish the event. This means that unless the producer accepts the new event, the feed can't move on and process a new event from CouchDB. In other words, the speed of ingestion is directly influenced by the speed of processing.

## Setup

Assuming you have a working, local installation of CouchDB >= 2.0.

#### Step 1 - create and populate a CouchDB database

You can use the provided `make reset-db` task to create a `oredev` database populated with the schedule data for the conference (~150 sessions).

If you visit <http://localhost:5984/oredev/_changes> you should be able to see the list of changes applied to the newly created db (in form of ids and revisions).

#### Step 2 - dependencies

Assuming you have Elixir >= 1.5 installed, you can:

- `mix deps.get` to install dependencies
- `iex -S mix` to start the application

#### Step 3 - run the demo

You can use `Oredev.DbSupervisor.start_child("oredev")` to start processing data from the `oredev` database created in step 1.

Note that the application logs at `log/dev/{info,error}.log`, so make sure you tail them in a separate window to see if anything goes wrong.

If you see any `tcp` errors, you can: `Application.stop(:oredev); Application.ensure_all_started(:oredev); Oredev.DbSupervisor.start_child("oredev")` to stop the application and restart the process.

#### Step 4 - see how the system is affected

You can call `Oredev.Change.Supervisor.healthcheck("oredev")` to see the pending message count for consumers and subscribers.
