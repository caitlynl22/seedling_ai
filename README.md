# 🍃 SeedlingAI
**AI-powered seed data generation for Ruby on Rails**

SeedlingAI is a Rails-first gem that generates **realistic, schema-aware, validation-respecting seed data** using the OpenAI API.
Give it a model, and SeedlingAI automatically:

- introspects attributes, validations, and associations
- generates natural, contextual sample records
- inserts them into the database **or** exports them to YAML/JSON
- handles invalid JSON, missing attributes, and database errors gracefully
- provides both a **CLI** and **Rails rake tasks**
- supports future extension (RSpec generation, cross-framework support, etc.)

---

## ✨ Features

- 🌱 **AI-generated seed data** based on model attributes & validations
- 🧠 **Optional natural-language context** to influence generation
- 📦 **Export to YAML or JSON** for longer-term reuse
- 🚀 **Insert directly using `insert_all` + transactions** for safety and speed
- 🧰 **Rails-first**, but designed for future non-Rails support
- 🛠️ **Thor CLI** for command-line usage
- 🎛️ **Rake tasks automatically loaded via Railtie**
- 🔐 **Flexible API key configuration**
- 📑 Clean, testable code with full RSpec examples

---

## 📦 Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

---

## 🔐 Configuration

SeedlingAI uses the OpenAI Ruby SDK and expects an API key.

You can set it as an environment variable:

```sh
export OPENAI_API_KEY=your_api_key_here
```

Or configure it in an initializer:

```ruby
# config/initializers/seedling_ai.rb
SeedlingAi.configure do |config|
  config.api_key = ENV["OPENAI_API_KEY"]
  config.model = "gpt-5"
end
```

### Available Settings

| Setting      | Description                   | Default                    |
|--------------|-------------------------------|----------------------------|
| `api_key`    | OpenAI API key                | `ENV["OPENAI_API_KEY"]`   |
| `model`      | Model used by the API         | `"gpt-5"`                 |
| `logger`     | Custom logger                 | `Rails.logger` or STDOUT  |

---

## 🌿 CLI Usage

Run inside your Rails app:

```sh
bundle exec seedling_ai seed User
```

Generate 25 records:

```sh
bundle exec seedling_ai seed User --count 25
```

Provide extra context:

```sh
bundle exec seedling_ai seed Order --context "holiday orders with discounts"
```

Export instead of inserting:

```sh
bundle exec seedling_ai seed User --export json
```

---

## 🌱 Rake Tasks (Rails)

SeedlingAI includes a Railtie that auto-loads its tasks.

### Generate Seed Data

```sh
rails seedling_ai:seed MODEL=User COUNT=10 EXPORT=json
```

Alternate form (rake args):

```sh
rake seedling_ai:seed[User,10,'some context','yaml']
```

### List All Models

```sh
rails seedling_ai:list_models
```

### Show Version

```sh
rails seedling_ai:version
```

---

## 🧪 Example Output

Given:

```ruby
class User < ApplicationRecord
  validates :email, presence: true
  has_many :posts
end
```

SeedlingAI might generate:

**JSON:**

```json
[
  {
    "name": "Alicia Mendez",
    "email": "amendez@example.com",
    "created_at": "2025-01-04T12:30:00Z"
  }
]
```

**YAML:**

```yaml
- name: "Evan Phillips"
  email: "evanp@example.com"
```

---

## 🧠 How It Works

### 1. Model Introspection
SeedlingAI gathers:

- attributes & types
- validations
- associations

### 2. Prompt Generation
SeedlingAI builds a structured prompt describing your model, constraints, and expected output format.

### 3. OpenAI Response API
SeedlingAI calls:

- `client.responses`
- with `max_output_tokens`, `temperature`, and required params
- extracts `output_text`

### 4. Parsing & Insertion
Responses are:

- safely parsed
- optionally exported
- or inserted via `insert_all` inside a transaction

---

## 🧪 Testing

SeedlingAI includes tests for:

- AI client behavior via verifying doubles
- model introspection utilities
- JSON error handling
- CLI error output & logging
- rake tasks (without allowing `exit` to kill the process)
- ActiveRecord operations wrapped safely in transactions

---

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

---

## 🚧 Roadmap

- 🌼 RSpec test generation
- 🌲 FactoryBot factory generation
- 🍁 Seed snapshots / deterministic seed replay
- 🌾 Non-Rails support
- 🌻 Custom structured output schema options

---

## 💬 Contributing

Contributions, bug reports, and feature suggestions are welcome!
The gem is intentionally structured for readability, extensibility, and safe modification.

---

## Code of Conduct

Everyone interacting in the SeedlingAi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/seedling_ai/blob/master/CODE_OF_CONDUCT.md).

---

## 📄 License

MIT License
