class EsQueryBuilder
  class Token
    attr_reader :full, :field, :term

    TYPE_KINDS = %i(query filter or).freeze

    def initialize(full: nil, minus: nil, field: nil, term: nil, type: nil)
      @full = full
      @minus = !!minus
      @field = field
      @term = term
      @type = type
    end

    def minus?
      @minus
    end

    TYPE_KINDS.each do |type|
      define_method "#{type}?" do
        @type == type
      end
    end
  end
end
