# frozen_string_literal: true

module SeedlingAi
  # Utility methods for the Seeder
  module Utils
    MAX_ASSOCIATION_IDS = 50

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
      validations = map_validations(model)
      associations = map_associations(model)

      ModelInfo.new(
        model: model,
        attributes: attributes,
        validations: validations,
        associations: associations
      )
    end

    def load_existing_association_ids(model)
      non_nullable_foreign_key_associations(model).to_h do |association|
        klass = association.class_name.constantize

        ids = klass.limit(MAX_ASSOCIATION_IDS).pluck(:id)

        if ids.empty?
          raise "SeedlingAi Error: Cannot seed #{model.name} because it
          requires #{klass.name} records, but none exist in the database."
        end

        [
          association.foreign_key,
          {
            model: klass.name,
            ids: ids
          }
        ]
      end
    end

    private

    def map_validations(model)
      model.validators.map do |v|
        {
          attributes: v.attributes.map(&:to_s),
          type: v.class.name.demodulize.gsub("Validator", "").downcase
        }
      end
    end

    def map_associations(model)
      model.reflect_on_all_associations.map do |a|
        {
          name: a.name.to_s,
          macro: a.macro.to_s,
          foreign_key: a.foreign_key.to_s,
          class_name: a.class_name
        }
      end
    end

    def non_nullable_foreign_key_associations(model)
      model.load_schema

      model
        .reflect_on_all_associations(:belongs_to)
        .reject(&:polymorphic?)
        .select do |association|
          column = association.foreign_key
          model.columns_hash[column]&.null == false
        end
    end
  end
end
