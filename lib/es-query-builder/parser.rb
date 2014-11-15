class EsQueryBuilder
  # Public: The class which has a responsibility for creatign a query.
  #
  # Note that the term "query" has two different meanings in the terminology of
  # Elasticsearch. One represents how to retrieve documents from Elasticsearch
  # and it consists of query and filter, so that is to say the other is a
  # part of previous one. In this file, "query" and "query hash" represents the
  # former and the latter respectively:
  #
  #   "query" = "query hash" + "filter hash"
  #
  class Parser
    # Public: Construct the parser object.
    #
    # query_fields     - An Array of Strings for specifing allowed quering
    #                    types (default: []).
    # hierarchy_fields - An Array of Strings which treats the trailing slash
    #                    character as a hierarchy (default: []).
    #
    # Returns nothing.
    def initialize(all_query_fields = '_all', hierarchy_fields = [])
      @all_query_fields = all_query_fields
      @hierarchy_fields = hierarchy_fields
    end

    # Public: Parse the given tokens and build a query hash.
    #
    # tokens - An Array of Tokens.
    #
    # Returns a Hash for Elasticsearch client or nil.
    def parse(tokens)
      connect_queries(build_queries(tokens))
    end

    private

    # Internal: Convert the given tokens into sequence of queries.
    #
    # tokens - An Array of Tokens.
    #
    # Returns an Array of Hashes. Each hash represents a query.
    def build_queries(tokens)
      split_by_or_token(tokens).map do |or_less_tokens|
        query_hash = build_query_hash(or_less_tokens.select(&:query?))
        filter_hash = build_filter_hash(or_less_tokens.select(&:filter?))
        create_query(query_hash, filter_hash)
      end
    end

    # Internal: Merge sequence of queries into a single query.
    #
    # queries - An Array of Hashes. Eash hash represents a query.
    #
    # Returns a Hash or nil.
    def connect_queries(queries)
      case queries.size
      when 0
        nil
      when 1
        queries.first
      else
        {
          bool: {
            should: queries
          }
        }
      end
    end

    # Internal: Divide the given tokens array into sub arrays by 'or' token.
    #
    # tokens - An Array of Search::QueryBuilder::Token.
    #
    # Examples
    #
    #   split_by_or_token([<Query>, <OR>, <Query>, <Filter>])
    #   #=> [[<Query>], [<Query>, <Filter>]]
    #
    # Returns an Array of Arrays of Tokens.
    def split_by_or_token(tokens)
      expressions = [[]]
      tokens.each do |token|
        if token.or?
          expressions << []
        else
          expressions.last << token
        end
      end
      expressions.select { |e| e.size > 0 }
    end

    # Internal: Connect given query hash and filter hash objects.
    #
    # query_hash  - A Hash represents a query hash.
    # filter_hash - A Hash represents a filter hash.
    #
    # Returns a Hash represents a query.
    def create_query(query_hash, filter_hash)
      if filter_hash.size > 0
        {
          filtered: {
            query: query_hash,
            filter: filter_hash
          }
        }
      else
        query_hash
      end
    end

    # Internal: Build a query hash by query tokens
    #
    # query_tokens - An Array of query Tokens.
    #
    # Returns a Hash represents a query hash.
    def build_query_hash(query_tokens)
      return { match_all: {} } if query_tokens.empty?
      must, must_not = create_bool_queries(query_tokens)
      if must.size == 1 && must_not.empty?
        must.first
      else
        bool = {}
        bool[:must]     = must     if must.size > 0
        bool[:must_not] = must_not if must_not.size > 0
        { bool: bool }
      end
    end

    # Internal: Build a filter parameter hash by query tokens
    #
    # filter_tokens - An Array of filter Tokens.
    #
    # Returns a Hash represents a filter hash.
    def build_filter_hash(filter_tokens)
      return {} if filter_tokens.empty?
      must, should, must_not = create_bool_filters(filter_tokens)
      if must.size == 1 && should.empty? && must_not.empty?
        # Term filter is cached by default.
        must.first
      else
        bool = {}
        bool[:must]     = must     if must.size > 0
        bool[:should]   = should   if should.size > 0
        bool[:must_not] = must_not if must_not.size > 0
        # Bool filter is not cached by default.
        { bool: bool.merge(_cache: true) }
      end
    end

    # Internal: Create boolean query based with the given query tokens.
    #
    # query_tokens - An Array of query Tokens.
    #
    # Returns an Array consists of must and must_not query arrays.
    def create_bool_queries(query_tokens)
      must, must_not = [], []
      query_tokens.each do |token|
        # When the field is not given or invalid one, search by all fields.
        field = token.field || @all_query_fields
        queries = token.minus? ? must_not : must
        if field.is_a?(String)
          queries << {
            match: {
              field => token.term
            }
          }
        else
          queries << {
            multi_match: {
              fields: field,
              query: token.term
            }
          }
        end
      end
      [must, must_not]
    end

    # Internal: Create boolean filter based on the filter matches.
    # If a field query in hierarchy fields ends with '/', it matches to all
    # descendant terms.
    #
    # query_tokens - An Array of filter Tokens.
    #
    # Examples
    #
    #   # When 'tag:"foo bar"'
    #   create_bool_filters([...])
    #   # => [[{ term: { tag: 'foo' }}, { term: { tag: 'bar' }], [], []]
    #
    #   # When '-tag:foo'
    #   create_bool_filters([...])
    #   # => [[], [], [{ term: { tag: 'foo' } }]]
    #
    #   # Suppose @hierarchy_fields contains 'tag'
    #
    #   # When 'tag:foo/'
    #   create_bool_filters([...])
    #   # => [[], [{ term: { tag: 'foo' } }, { prefix: { tag: 'foo/' } }], []]
    #
    #   # When '-tag:foo/'
    #   create_bool_filters([...])
    #   # => [[], [], [{ prefix: { tag: 'foo/' } }, { term: { tag: 'foo' } }]]
    #
    # Returns an Array consists of must, should and must_not filters arrays.
    def create_bool_filters(filter_tokens)
      must, should, must_not = [], [], []
      filter_tokens.each do |token|
        token.term.split.each do |term|
          if @hierarchy_fields.include?(token.field) && term.end_with?('/')
            cond = token.minus? ? must_not : should
            cond << { prefix: { token.field => term.downcase } }
            # Exactly matches to the tag.
            cond << { term: { token.field => term[0...-1].downcase } }
          else
            cond = token.minus? ? must_not : must
            cond << { term: { token.field => term.downcase } }
          end
        end
      end
      [must, should, must_not]
    end
  end
end
