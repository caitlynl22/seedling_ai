# frozen_string_literal: true

module SeedlingAi
  # Utility methods for the Seeder
  module Utils
    ModelInfo = Struct.new(
      :model,
      :attributes,
      :validations,
      :associations
    ) do
      def summary
        <<~SUMMARY
          Model: #{model.name}
          Attributes: #{attributes.map { |name, type| "#{name}: #{type}" }.join(", ")}
          Validations: #{validations.map { |v| "#{v[:attributes].join(", ")} -> #{v[:type]}" }.join(", ")}
          Associations: #{associations.map { |a| "#{a[:macro]}: #{a[:name]}" }.join(", ")}
        SUMMARY
      end

      def to_h
        {
          model: model.name,
          attributes: attributes.to_h,
          validations: validations,
          associations: associations
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end

    def find_model(name)
      model = name.safe_constantize
      raise ArgumentError, "Model '#{name}' not found" unless model && model < ActiveRecord::Base
      raise ArgumentError, "Model '#{name}' is abstract and cannot be seeded directly" if model.abstract_class?

      model
    end

    def model_info(model)
      attributes = model.columns_hash.transform_values(&:type)

      validations = model.validators.map do |v|
        {
          attributes: v.attributes.map(&:to_s),
          type: v.class.name.demodulize.gsub("Validator", "").downcase
        }
      end

      associations = model.reflect_on_all_associations.map do |a|
        { name: a.name.to_s, macro: a.macro.to_s }
      end

      ModelInfo.new(
        model: model,
        attributes: attributes,
        validations: validations,
        associations: associations
      )
    end
  end
end
