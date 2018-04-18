require 'spec_helper'

describe Sequel::Model do
  it 'should load classes with non-default primary key' do
    expect do
      YAML.load(Story.create.to_yaml)
    end.not_to raise_error
  end


  it "should use the correct search_path for postgres" do
    if DB.database_type == :postgres
      Story.all.map &:delete

      DB.run "drop schema if exists other_schema CASCADE"
      DB.run "create schema other_schema"

      # create a Story inside the other schema
      yaml = Story.use_search_path([:other_schema]) do
        DB.drop_table? :stories
        DB.create_table :stories do
          primary_key :story_id
          String      :text
          TrueClass   :scoped, :default => true
        end
        Story.create.to_yaml
      end

      # this should be empty as the search has now been reset
      expect(Story.all).to be_empty
      Story.use_search_path([:other_schema]) do
        expect(Story.all).not_to be_empty
      end

      expect{YAML.load(yaml)}.not_to raise_error
    end
  end


end
