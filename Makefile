DB = http://localhost:5984/oredev

reset-db: create-db
	curl --header 'Content-Type: application/json' --data @data/schedule.json -XPOST $(DB)/_bulk_docs
.PHONY: reset-db

create-db: delete-db
	curl -XPUT $(DB)

delete-db:
	curl -XDELETE $(DB)
.PHONY: delete-db
