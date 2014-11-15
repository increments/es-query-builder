class EsQueryBuilder
  class Tokenizer
    QUERY_REGEXP = /
      (
        (-)?                  # Minus
        (?:(\w+):)?           # Field
        (?:
          (?:"(.*?)(?<!\\)")  # Quoted query
          |
          ([^\s]+)            # Single query
        )
      )
    /x

    OR_CONDITION = /^OR$/i

    # Public: COnstruct the tokenizer object.
    #
    # filter_fields    - An Array of Strings for specifing allowed filtering
    #                    types (default: []).
    # all_query_fields - The String or Array of Strings for searching usual
    #                    query terms (default: '_all').
    #
    # Returns nothing.
    def initialize(query_fields = [], filter_fields = [])
      @query_fields = query_fields
      @filter_fields = filter_fields
    end

    # Public: Tokenize the given query string for parsing it later.
    #
    # query_string - The utf8 encoded String.
    #
    # Examples
    #
    #   tokenize('hello OR tag:world')
    #   # => [<Token: @full="hello",     @type=:query,  ...>,
    #         <Token: @full="OR",        @type=:or,     ...>,
    #         <Token: @full="tag:world", @type=:filter, ...>]
    #
    # Returns an Array of Tokens.
    def tokenize(query_string)
      query_string.scan(QUERY_REGEXP).map do |match|
        create_token(*match)
      end
    end

    private

    def create_token(full, minus, field, quoted, simple)
      if @filter_fields.include?(field)
        type = :filter
      elsif OR_CONDITION =~ full
        type = :or
      else
        field = nil unless @query_fields.include?(field)
        type = :query
      end

      Token.new(
        full: full,
        minus: minus,
        field: field,
        term: quoted || simple,
        type: type
      )
    end
  end
end
