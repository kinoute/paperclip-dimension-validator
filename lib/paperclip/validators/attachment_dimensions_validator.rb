module Paperclip
  module Validators
    class AttachmentDimensionsValidator < ActiveModel::EachValidator
      def initialize(options)
        super
      end

      def self.helper_method_name
        :validates_attachment_dimensions
      end

      def validate_each(record, attribute, value)
        return unless value.queued_for_write[:original]

        begin
          dimensions = Paperclip::Geometry.from_file(value.queued_for_write[:original].path)

          [:height, :width].each do |dimension|
            if options[dimension] && dimensions.send(dimension) != options[dimension].to_f
              record.errors.add(attribute.to_sym, :dimension, dimension_type: dimension.to_s, dimension: options[dimension], actual_dimension: dimensions.send(dimension).to_i)
            end
            max_dim = "max_#{dimension}".to_sym
            if options[max_dim] && dimensions.send(dimension) > options[max_dim]
              record.errors.add(attribute.to_sym, "#{dimension} should be a maximum of #{options[max_dim]} but is #{dimensions.send(dimension).to_i}")
            end
            min_dim = "min_#{dimension}".to_sym
            if options[min_dim] && dimensions.send(dimension) < options[min_dim]
              record.errors.add(attribute.to_sym, "#{dimension} should be a minimum of #{options[min_dim]} but is #{dimensions.send(dimension).to_i}")
            end
          end
          if options[:min_pixels] || options[:max_pixels]
            actual_pixels = (dimensions.width * dimensions.height).to_i
            if options[:min_pixels] && actual_pixels < options[:min_pixels]
              record.errors.add(:base, "width x height should be a minimum of #{options[:min_pixels]} but is #{actual_pixels}")
            end
            if options[:max_pixels] && (dimensions.width * dimensions.height) > options[:max_pixels]
              record.errors.add(:base, "width x height should be a maximum of #{options[:max_pixels]} but is #{actual_pixels}")
            end
          end
        rescue Paperclip::Errors::NotIdentifiedByImageMagickError
          Paperclip.log("cannot validate dimensions on #{attribute}")
        end
      end
    end

    module HelperMethods
      def validates_attachment_dimensions(*attr_names)
        options = _merge_attributes(attr_names)
        validates_with(AttachmentDimensionsValidator, options.dup)
        validate_before_processing(AttachmentDimensionsValidator, options.dup)
      end
    end
  end
end
