# frozen_string_literal: true

require "spec_helper"

RSpec.describe SeedlingAi::Utils do
  # Create a test class that includes the Utils module
  let(:utils_class) { Class.new { include SeedlingAi::Utils } }
  let(:utils) { utils_class.new }

  # rubocop:disable RSpec/BeforeAfterAll
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
  end

  before do
    test_user_klass = Class.new(ActiveRecord::Base) do
      has_many :test_posts
      validates :email, presence: true
      validates :name, length: { minimum: 2 }
    end
    stub_const("TestUser", test_user_klass)

    test_post_klass = Class.new(ActiveRecord::Base) do
      belongs_to :test_user
      validates :title, presence: true
    end
    stub_const("TestPost", test_post_klass)

    abstract_klass = Class.new(ActiveRecord::Base)
    abstract_klass.abstract_class = true
    stub_const("AbstractTestModel", abstract_klass)
  end

  # Drop tables after the whole group; constants will be restored automatically by stub_const.
  after(:context) do
    ActiveRecord::Base.connection.drop_table :test_posts
    ActiveRecord::Base.connection.drop_table :test_users
  end
  # rubocop:enable RSpec/BeforeAfterAll

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

    context "when inspecting attributes" do
      it "identifies the name attribute" do
        expect(user_info.attributes).to include("name" => :string)
      end

      it "identifies the email attribute" do
        expect(user_info.attributes).to include("email" => :string)
      end
    end

    context "when inspecting validations" do
      it "includes presence validation for email" do
        expect(user_info.validations).to include({ attributes: ["email"], type: "presence" })
      end

      it "includes length validation for name" do
        expect(user_info.validations).to include({ attributes: ["name"], type: "length" })
      end
    end

    context "when inspecting associations" do
      it "lists the has_many association to test_posts" do
        expect(user_info.associations).to include({ name: "test_posts", macro: "has_many" })
      end
    end

    describe "#summary" do
      it "includes the model name in the summary" do
        expect(user_info.summary).to include("Model: TestUser")
      end

      it "includes Attributes label in the summary" do
        expect(user_info.summary).to include("Attributes:")
      end

      it "includes Validations label in the summary" do
        expect(user_info.summary).to include("Validations:")
      end

      it "includes Associations label in the summary" do
        expect(user_info.summary).to include("Associations:")
      end
    end

    describe "#to_h" do
      it "returns a hash" do
        expect(user_info.to_h).to be_a(Hash)
      end

      it "has the model name as a string" do
        expect(user_info.to_h[:model]).to eq("TestUser")
      end

      it "contains attributes as a hash" do
        expect(user_info.to_h[:attributes]).to be_a(Hash)
      end

      it "contains validations as an array" do
        expect(user_info.to_h[:validations]).to be_an(Array)
      end

      it "contains associations as an array" do
        expect(user_info.to_h[:associations]).to be_an(Array)
      end

      it "includes known attributes in the attributes hash" do
        expect(user_info.to_h[:attributes]).to include("name" => :string, "email" => :string)
      end
    end
  end
end
