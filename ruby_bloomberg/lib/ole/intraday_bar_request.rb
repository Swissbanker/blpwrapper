module RubyBloomberg
  class IntradayBarRequest < OleRequest
    AVAILABLE_BARFIELDS = ["OPEN","HIGH","LOW","LAST_TRADE","NUMBER_TICKS","VOLUME"]
    AVAILABLE_FIELDS = ["LAST_PRICE", "BID", "ASK"]
    
    def process_param(key, value)
      case key.to_sym
      when :barsize, :bar_size, :barSize
        @bar_size = value
      when :barfields, :bar_fields, :barFields
        value.each do |v|
          raise "#{v} is not a valid barfield, valid options are #{AVAILABLE_BARFIELDS.join(", ")}" unless AVAILABLE_BARFIELDS.include?(v)
        end
        @bar_fields = value
      when :currency
        @currency = value
      when :start_date, :startDate
        @start_date = date_param_to_variant(value)
      when :end_date, :endDate
        @end_date = date_param_to_variant(value)
      else
        raise key.to_s
      end
    end
    
    def submit
      @params.each do |k, v|
        process_param(k, v)
      end
      
      raise "bar size must be > 0 for IntradayBarRequest" unless @bar_size > 0
      @bar_fields ||= AVAILABLE_BARFIELDS
      
      raw_result = fetch_raw_historical_request
      prepare_historical_data_table
      
      raw_result.each_with_index do |a, i|
        a.each_with_index do |b, j|
          b.first.each_with_index do |x, k|
            if k == 0
              next unless j == 0
              # Fill in dates. Only need to do this once due to evil hack.
              @data_table.rows[0].append_to_array(1, Time.parse(x))
            else
              @data_table.rows[j+1].append_to_array(k, detect_error(x))
            end
          end
        end
      end
    end
  end
end