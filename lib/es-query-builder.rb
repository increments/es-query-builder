# Public: The class has a responsibility for converting a query string into
# a corresponding query hash object for Elasticsearch.
#
# Examples
#
#   builder = EsQueryBuilder.new(
#     query_fields: ['query'],
#     filter_fields: ['filter']
#   )
#   # => #<EsQueryBuilder>
#
#   builder.build('term')
#   # => { match: { '_all' => 'term' } }
#
#   builder.build('query:term')
#   # => { match: { 'query' => 'hello' } }
#
#   builder.build('filter:term')
#   # => {
#   #      filtered: {
#   #        query: { match_all: {} },
#   #        filter: { term: { filter: 'hello' } }
#   #      }
#   #    }
#
#   builder.build('query\:term')
#   # => { match: { '_all' => 'query\:term' } }
#
#   builder.build('unknown:term')
#   # => { match: { '_all' => 'term' } }
class EsQueryBuilder
  require 'es-query-builder/token'
  require 'es-query-builder/tokenizer'
  require 'es-query-builder/parser'
  require 'es-query-builder/version'

  # Public: Construct the query builder object.
  #
  # query_fields     - An Array of Strings for specifing allowed quering
  #                    types (default: []).
  # filter_fields    - An Array of Strings for specifing allowed filtering
  #                    types (default: []).
  # all_query_fields - A String or an Array of Strings for searching usual
  #                    query terms (default: '_all').
  # hierarchy_fields - An Array of Strings which treats the trailing slash
  #                    character as a hierarchy (default: []).
  #
  # Returns nothing.
  def initialize(query_fields: [], filter_fields: [],
                 all_query_fields: '_all', hierarchy_fields: [],
                 nested_fields: {})
    @query_fields = query_fields
    @filter_fields = filter_fields
    @all_query_fields = all_query_fields
    @hierarchy_fields = hierarchy_fields
    @nested_fields = nested_fields
  end

  # Public: Convert the given query string into a query object.
  #
  # query_string - A query String for searching.
  #
  # Examples
  #
  #   build('hello world')
  #   # => {
  #   #      bool: {
  #   #        must: [
  #   #          { match: { '_all' => 'hello' } },
  #   #          { match: { '_all' => 'world' } }
  #   #        ]
  #   #      }
  #   #    }
  #
  # Returns a Hash for Elasticsearch client or nil.
  def build(query_string)
    parser.parse(tokenizer.tokenize(query_string))
  end

  private

  # Internal: Tokenizer for the builder.
  #
  # Returns a Tokenizer.
  def tokenizer
    @tokenizer ||= Tokenizer.new(@query_fields, @filter_fields)
  end

  # Internal: Parser for the builder.
  #
  # Returns a Parser.
  def parser
    @parser ||= Parser.new(
      all_query_fields: @all_query_fields,
      hierarchy_fields:  @hierarchy_fields,
      nested_fields: @nested_fields)
  end
end
