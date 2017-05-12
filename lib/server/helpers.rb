module BlockStack
  # General helpers for the base BlockStack server
  module Helpers
    def application_name
      self.class.application_name
    end

    def json_format(payload)
      if params.include?(:pretty)
        JSON.pretty_generate(payload)
      else
        payload.to_json
      end
    end

    def yaml_format(payload)
      clean_values(payload).to_yaml
    end

    def xml_format(payload)
      payload = clean_values(payload)
      if payload.is_a?(Array)
        payload = { responses: { response: payload } }
      else
        payload = { response: payload }
      end
      '<?xml version="1.0" encoding="UTF-8"?>' + Gyoku.xml(payload, pretty_print: params.include?('pretty'), key_converter: proc { |key| key.to_s.title_case.drop_symbols })
    end

    def clean_values(payload)
      case [payload.class]
      when [Array]
        payload.map { |elem| clean_values(elem) }
      when [Hash]
        payload.hmap { |k, v| [clean_values(k), clean_values(v)] }
      when [String], [Integer], [Fixnum], [Float], [TrueClass], [FalseClass], [NilClass]
        payload
      else
        payload.to_s
      end
    end

    def csv_format(payload, type = :csv)
      delimiter = type == :tsv ? "\t" : ","
      if payload.is_a?(Hash)
        headers = payload.keys
        content = [payload.values]
      elsif payload.is_a?(Array)
        if payload.all? { |elem| elem.is_a?(Hash) }
          headers = payload.flat_map(&:keys).uniq
          content = payload.map do |row|
            headers.map { |header| row[header].to_s }
          end
        else
          headers = ['']
          content = [payload.map(&:to_s)]
        end
      else
        headers = ['']
        content = [[payload.to_s]]
      end
      headers.map { |header| "\"#{header.to_s.gsub('"', '\\"')}\"" }.join(delimiter) + "\n" +
      content.map do |row|
        row.map do |value|
          "\"#{value.to_s.gsub('"', '\\"')}\""
        end.join(delimiter)
      end.join("\n")
    end

  end
end
