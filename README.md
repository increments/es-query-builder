[![Build Status](https://travis-ci.org/increments/es-query-builder.svg?branch=master)](https://travis-ci.org/increments/es-query-builder)

NAME
====

`EsQueryBuilder` - A query builder for Elasticsearch in Ruby.

SYNOPSIS
========

```ruby
builder = EsQueryBuilder.new(
  # Fields allowed searching with match query.
  query_fields: ['field1'],
  # Fields for filtering. Queries for these fields do not affect search score.
  filter_fields: ['field2']
)

query = builder.build(query_string_given_by_user)

body = 
  if query.nil?
    # Empty query
    { size: 0 }
  else
    # Add other conditions, such as sort, highlight, fields and so on.
    {
      query: query,
      sort: { ... }
    }
  end

client = Elasticsearch::Client.new(host: 'http://server:9200')
client.search({
  index: 'index_name',
  type: 'type_name',
  body: body
})
# => #<Hash>
```

DESCRIPTION
===========

`EsQueryBuilder` converts a query string into a corresponding hash object for [elasticsearch-ruby](https://github.com/elasticsearch/elasticsearch-ruby).

Elasticsearch supports [query_string query](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html) dsl which is very useful to use internally, but too powerful to use as public interface. Allowing anonymous users to use the dsl may cause not only performance problems but also security risks if your index includes secret types.

This gem accepts the query_string-query-dsl-like string and converts the string into a query object using other query dsls. At the same time it sanitizes fields in the query.

INSTALLATION
============

```bash
gem install es-query-builder
```

LICENSE
=======

This software is licensed under [MIT license](https://github.com/increments/es-query-builder/tree/master/LICENSE.txt).
