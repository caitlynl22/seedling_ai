# frozen_string_literal: true

require "spec_helper"

RSpec.describe SeedlingAi::Utils do
  # Create a test class that includes the Utils module
  let(:utils_class) { Class.new { include SeedlingAi::Utils } }
  let(:utils) { utils_class.new }

  # Set up test models
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :test_users do |t|
        t.string :name
        t.string :email
        t.timestamps
      end

      create_table :test_posts do |t|
        t.string :title
        t.text :content
        t.references :test_user
        t.timestamps
      end
    end

    class TestUser < ActiveRecord::Base
      has_many :test_posts
      validates :email, presence: true
      validates :name, length: { minimum: 2 }
    end

    class TestPost < ActiveRecord::Base
      belongs_to :test_user
      validates :title, presence: true
    end

    class AbstractTestModel < ActiveRecord::Base
      self.abstract_class = true
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :test_users
    ActiveRecord::Base.connection.drop_table :test_posts
    Object.send(:remove_const, :TestUser)
    Object.send(:remove_const, :TestPost)
    Object.send(:remove_const, :AbstractTestModel)
  end

  describe "#find_model" do
    it "returns the model class when it exists" do
      expect(utils.find_model("TestUser")).to eq(TestUser)
    end

    it "raises ArgumentError when model does not exist" do
      expect { utils.find_model("NonExistentModel") }
        .to raise_error(ArgumentError, "Model 'NonExistentModel' not found")
    end

    it "raises ArgumentError when model is abstract" do
      expect { utils.find_model("AbstractTestModel") }
        .to raise_error(ArgumentError, "Model 'AbstractTestModel' is abstract and cannot be seeded directly")
    end
  end

  describe "#model_info" do
    let(:user_info) { utils.model_info(TestUser) }

    it "returns a ModelInfo instance" do
      expect(user_info).to be_a(SeedlingAi::Utils::ModelInfo)
    end

    it "correctly identifies model attributes" do
      expect(user_info.attributes).to include(
        "name" => :string,
        "email" => :string
      )
    end

    it "correctly identifies model validations" do
      expect(user_info.validations).to include(
        { attributes: ["email"], type: "presence" },
        { attributes: ["name"], type: "length" }
      )
    end

    it "correctly identifies model associations" do
      expect(user_info.associations).to include(
        { name: "test_posts", macro: "has_many" }
      )
    end

    describe "#summary" do
      it "returns a formatted string with model information" do
        expect(user_info.summary).to include("Model: TestUser")
        expect(user_info.summary).to include("Attributes:")
        expect(user_info.summary).to include("Validations:")
        expect(user_info.summary).to include("Associations:")
      end
    end

    describe "#to_h" do
      it 'returns the expected keys and types' do
        hash = user_info.to_h
        expect(hash).to be_a(Hash)
        expect(hash[:model]).to eq('TestUser')
        expect(hash[:attributes]).to be_a(Hash)
        expect(hash[:attributes]).to include('name' => :string, 'email' => :string)
        expect(hash[:validations]).to be_an(Array)
        expect(hash[:associations]).to be_an(Array)
      end
    end
  end
end
