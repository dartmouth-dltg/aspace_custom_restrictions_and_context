# Run with: ruby test/helper_test.rb
require 'minitest/autorun'

# minimal stand-in for ArchivesSpace's AppConfig (raises on unset keys like the real one)
module AppConfig
  @params = {}
  def self.[](key); @params.fetch(key) { raise "No value set for config parameter: #{key}" }; end
  def self.[]=(key, value); @params[key] = value; end
  def self.has_key?(key); @params.has_key?(key); end
  def self.reset; @params = {}; end
end

require_relative '../lib/aspace_custom_restrictions_and_context_helper'

class HelperTest < Minitest::Test
  H = AspaceCustomRestrictionsContextHelper

  def setup
    AppConfig.reset
  end

  def test_record_level_for_solr_doc_without_level
    assert_equal 'Accession', H.record_level('primary_type' => 'accession')
  end

  def test_record_level_for_json_other_level
    assert_equal 'Box', H.record_level('level' => 'otherlevel', 'other_level' => 'Box')
    assert_equal 'Digital object component', H.record_level('jsonmodel_type' => 'digital_object_component')
  end

  def test_type_mapping_only_limits_mapped_types
    AppConfig[:aspace_custom_restriction_type_mapping] = {'some_materials_restricted' => ['series']}
    file = {'level' => 'file'}

    assert_equal({}, H.restriction_applies_to_object?(file, {'File' => 'some_materials_restricted'}))
    assert_equal({'File' => 'access_restricted'}, H.restriction_applies_to_object?(file, {'File' => 'access_restricted'}))
    assert_equal({'Series' => 'some_materials_restricted'}, H.restriction_applies_to_object?({'level' => 'series'}, {'Series' => 'some_materials_restricted'}))
  end

  def test_no_mapping_leaves_restrictions_alone
    assert_equal({'File' => 'x'}, H.restriction_applies_to_object?({'level' => 'file'}, {'File' => 'x'}))
  end

  def test_access_note_skip_phrases
    notes = [{'type' => 'accessrestrict', 'subnotes' => [{'content' => 'Open for access'}]}]
    assert H.has_local_access_note?(notes)

    AppConfig[:aspace_custom_restrictions_access_note_skip_phrases] = ['open for access']
    refute H.has_local_access_note?(notes)

    # a second, non-skipped note still counts
    notes << {'type' => 'accessrestrict', 'subnotes' => [{'content' => 'Closed until 2050'}]}
    assert H.has_local_access_note?(notes)
  end

  def test_accessrestrict_can_be_disabled
    assert H.use_accessrestrict?
    AppConfig[:aspace_custom_restrictions_use_accessrestrict] = false
    refute H.use_accessrestrict?
  end

  def test_restriction_precedence
    rec = {'level' => 'file', 'restrictions_apply' => true, 'custom_restriction' => {'custom_restriction_type' => 'access_restricted'}}
    assert_equal({'file' => 'access_restricted'}, H.is_restricted?(rec))
    assert_equal({'file' => 'default'}, H.is_restricted?('level' => 'file', 'restrictions_apply' => true))
    assert_equal({}, H.is_restricted?('level' => 'file'))
  end
end
