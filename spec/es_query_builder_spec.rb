require 'spec_helper'

describe EsQueryBuilder do
  let(:query_builder) do
    described_class.new(param)
  end

  let(:param) do
    {}
  end

  describe '#build' do
    subject do
      query_builder.build(query_string)
    end

    context 'when a term query is given' do
      let(:query_string) do
        term
      end

      let(:term) do
        'hello'
      end

      it 'returns a match query' do
        should eq(
          match: {
            '_all' => term
          }
        )
      end

      context 'and the query starts with a minus character' do
        let(:query_string) do
          '-' + term
        end

        it 'returns a bool query with must_not condition' do
          should eq(
            bool: {
              must_not: [
                {
                  match: {
                    '_all' => term
                  }
                }
              ]
            }
          )
        end
      end

      context 'and it is constructed with all_query_fields' do
        let(:param) do
          { all_query_fields: all_query_fields }
        end

        let(:all_query_fields) do
          ['field']
        end

        it 'returns a bool query for the specified query fields' do
          should eq(
            multi_match: {
              fields: all_query_fields,
              query: term
            }
          )
        end

        context 'and the query starts with a minus char' do
          let(:query_string) do
            '-' + term
          end

          it 'returns a must_not query for the specified query fields' do
            should eq(
              bool: {
                must_not: [
                  {
                    multi_match: {
                      fields: all_query_fields,
                      query: term
                    }
                  }
                ]
              }
            )
          end
        end
      end

      context 'and it is constructed with nested_fields' do
        let(:param) do
          { nested_fields: { hoge: ['hoge.title'] } }
        end

        let(:all_query_fields) do
          { nested: { hoge: ['hoge.title'] } }
        end

        it "returns a nested query for the specified nested path and fields" do
          should eq(
            {
              bool: {
                should: [
                  {
                    match: {
                      '_all' => term
                    }
                  },
                  {
                    nested: {
                      path: 'hoge',
                      query: {
                        multi_match: {
                          fields: ['hoge.title'],
                          query: term
                        }
                      }
                    }
                  }
                ]
              }
            }
          )
        end

        context 'and the query starts with a minus char' do
          let(:query_string) do
            '-' + term
          end

          it 'returns a must_not query for the specified query fields' do
            should eq(
              bool: {
                must_not: [
                  {
                    bool: {
                      should: [
                        {
                          match: {
                            '_all' => term
                          }
                        },
                        {
                          nested: {
                            path: 'hoge',
                            query: {
                              multi_match: {
                                fields: ['hoge.title'],
                                query: term
                              }
                            }
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            )
          end
        end
      end

      context 'and it is constructed with both fields and nested fields' do
        let(:param) do
          {
            all_query_fields: ['hoge'],
            nested_fields: { hoge: ['hoge.title'] }
          }
        end

        it "returns a nested query for the specified nested path and fields" do
          should eq(
            {
              bool: {
                should: [
                  {
                    multi_match: {
                      fields: ['hoge'],
                      query: term
                    }
                  },
                  {
                    nested: {
                      path: 'hoge',
                      query: {
                        multi_match: {
                          fields: ['hoge.title'],
                          query: term
                        }
                      }
                    }
                  }
                ]
              }
            }
          )
        end

        context 'and the query starts with a minus char' do
          let(:query_string) do
            '-' + term
          end

          it 'returns a must_not query for the specified query fields' do
            should eq(
              bool: {
                must_not: [
                  {
                    bool: {
                      should: [
                        {
                          multi_match: {
                            fields: ['hoge'],
                            query: term
                          }
                        },
                        {
                          nested: {
                            path: 'hoge',
                            query: {
                              multi_match: {
                                fields: ['hoge.title'],
                                query: term
                              }
                            }
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            )
          end
        end
      end
    end

    context 'when term queries are given' do
      let(:query_string) do
        "#{term_1} #{term_2}"
      end

      let(:term_1) do
        'hello'
      end

      let(:term_2) do
        'world'
      end

      it 'returns a bool query with must match queries' do
        should eq(
          bool: {
            must: [
              {
                match: {
                  '_all' => term_1
                }
              },
              {
                match: {
                  '_all' => term_2
                }
              }
            ]
          }
        )
      end

      context 'and one query starts with a minus character' do
        let(:query_string) do
          "#{term_1} -#{term_2}"
        end

        it 'returns a bool query with must and must_not queries' do
          should eq(
            bool: {
              must: [
                {
                  match: {
                    '_all' => term_1
                  }
                }
              ],
              must_not: [
                {
                  match: {
                    '_all' => term_2
                  }
                }
              ]
            }
          )
        end
      end

      context 'and both of them start with a minus character' do
        let(:query_string) do
          "-#{term_1} -#{term_2}"
        end

        it 'returns a bool query with must_not queries' do
          should eq(
            bool: {
              must_not: [
                {
                  match: {
                    '_all' => term_1
                  }
                },
                {
                  match: {
                    '_all' => term_2
                  }
                }
              ]
            }
          )
        end
      end

      context 'and one query is a filter query' do
        let(:query_string) do
          "#{field1}:#{term_1} #{term_2}"
        end

        let(:param) do
          { filter_fields: [field1] }
        end

        let(:field1) do
          'field'
        end

        it 'returns a filtered query' do
          should eq(
            filtered: {
              query: {
                match: {
                  '_all' => term_2
                }
              },
              filter: {
                term: {
                  field1 => term_1
                }
              }
            }
          )
        end
      end

      context 'and it is constructed with nested_fields' do
        let(:param) do
          { nested_fields: { nested_path => nested_fields } }
        end

        let(:nested_path) do
          'hoge'
        end

        let(:nested_fields) do
          ['hoge.title']
        end

        it 'returns a bool query with must match queries' do
          should eq(
            bool: {
              must: [
                {
                  bool: {
                    should: [
                      {
                        match: {
                          '_all' => term_1
                        }
                      },
                      {
                        nested: {
                          path: nested_path,
                          query: {
                            multi_match: {
                              fields: nested_fields,
                              query: term_1,
                            }
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        match: {
                          '_all' => term_2
                        }
                      },
                      {
                        nested: {
                          path: nested_path,
                          query: {
                            multi_match: {
                              fields: nested_fields,
                              query: term_2,
                            }
                          }
                        }
                      }
                    ]
                  }
                }
              ]
            }
          )
        end
      end
    end

    context 'when a field query is given' do
      let(:query_string) do
        "#{field}:#{field_query}"
      end

      let(:field) do
        'tag'
      end

      let(:field_query) do
        'hello'
      end

      context 'and it is a part of query_fields' do
        let(:param) do
          { query_fields: [field] }
        end

        it 'returns a match query for the field' do
          should eq(
            match: {
              field => field_query
            }
          )
        end
      end

      context 'and it is a part of filter_fields' do
        let(:param) do
          { filter_fields: [field] }
        end

        it 'returns a filtered query object' do
          should eq(
            filtered: {
              query: {
                match_all: {}
              },
              filter: {
                term: {
                  field => field_query
                }
              }
            }
          )
        end
      end

      context 'and the field is a part of neither query_fields nor filter_fields' do
        let(:param) do
          { all_query_fields: all_query_fields }
        end

        let(:all_query_fields) do
          ["foo_#{field}", "bar_#{field}"]
        end

        it 'returns a match query for all_query_fields' do
          should eq(
            multi_match: {
              fields: all_query_fields,
              query: field_query
            }
          )
        end
      end
    end

    context 'when a quoted query is given' do
      let(:query_string) do
        %("#{quoted_query}")
      end

      let(:quoted_query) do
        'hello world'
      end

      it 'returns a match query with the whole quoted query' do
        should eq(
          match: {
            '_all' => quoted_query
          }
        )
      end

      context 'and it is constructed with all_query_fields' do
        let(:param) do
          { all_query_fields: all_query_fields }
        end

        let(:all_query_fields) do
          %w(foo bar)
        end

        it 'returns a multi match query with the whole quoted query' do
          should eq(
            multi_match: {
              fields: all_query_fields,
              query: quoted_query
            }
          )
        end
      end
    end

    context 'when a quoted field query is given' do
      let(:query_string) do
        "#{field}:\"#{quoted_query}\""
      end

      let(:field) do
        'field'
      end

      let(:quoted_query) do
        "#{term_1} #{term_2}"
      end

      let(:term_1) do
        'hello'
      end

      let(:term_2) do
        'world'
      end

      context 'and the field is a part of query_fields' do
        let(:param) do
          { query_fields: [field] }
        end

        it 'returns a match query for the field' do
          should eq(
            match: {
              field => quoted_query
            }
          )
        end
      end

      context 'and the field is a part of filter_fields' do
        let(:param) do
          { filter_fields: [field] }
        end

        it 'returns a filtered query with must conditions' do
          should eq(
            filtered: {
              query: {
                match_all: {}
              },
              filter: {
                bool: {
                  must: [
                    {
                      term: {
                        field => term_1
                      }
                    },
                    {
                      term: {
                        field => term_2
                      }
                    }
                  ],
                  _cache: true
                }
              }
            }
          )
        end
      end

      context 'and the field is a part of neither query_fields nor filter_fields' do
        it 'returns a match query for _all field' do
          should eq(
            match: {
              '_all' => quoted_query
            }
          )
        end

        context 'and the query includes "OR"' do
          let(:quoted_query) do
            "#{term_1} OR #{term_2}"
          end

          it 'returns a match query inclues "OR" for _all field' do
            should eq(
              match: {
                '_all' => quoted_query
              }
            )
          end
        end
      end
    end

    context 'when an OR condition is given' do
      context 'and that is all' do
        let(:query_string) do
          'OR'
        end

        it { should be_nil }
      end

      context 'and it does not connect queries' do
        it 'does not returns a bool query' do
          expect(query_builder.build('OR term')).not_to have_key 'bool'
          expect(query_builder.build('term OR')).not_to have_key 'bool'
        end
      end

      context 'and it connects queries' do
        let(:query_string) do
          "#{term_1} #{field_2}:#{term_2} OR #{field_3}:#{term_3}"
        end

        let(:param) do
          {
            query_fields: [field_2],
            filter_fields: [field_3]
          }
        end

        let(:term_1) do
          'hello'
        end

        let(:field_2) do
          'title'
        end

        let(:term_2) do
          'world'
        end

        let(:field_3) do
          'user'
        end

        let(:term_3) do
          'qiitan'
        end

        it 'returns a bool query with should conditions' do
          should eq(
            bool: {
              should: [
                {
                  bool: {
                    must: [
                      {
                        match: {
                          '_all' => term_1
                        },
                      },
                      {
                        match: {
                          field_2 => term_2
                        }
                      }
                    ]
                  }
                },
                {
                  filtered: {
                    query: {
                      match_all: {}
                    },
                    filter: {
                      term: {
                        field_3 => term_3
                      }
                    }
                  }
                }
              ]
            }
          )
        end
      end
    end
  end
end
