MotionRecord
============

*Miniature ActiveRecord for RubyMotion*

Everything you need to start using SQLite as the datastore for your RubyMotion
app.

:turtle: Android support should be [coming soon](https://github.com/magoosh/motion_record/issues/3)

[![Gem Version](https://badge.fury.io/rb/motion_record.svg)](http://badge.fury.io/rb/motion_record) [![Code Climate](https://codeclimate.com/github/magoosh/motion_record/badges/gpa.svg)](https://codeclimate.com/github/magoosh/motion_record) [![Test Coverage](https://codeclimate.com/github/magoosh/motion_record/badges/coverage.svg)](https://codeclimate.com/github/magoosh/motion_record)

Installation
------------

Add this line to your Gemfile:

```ruby
gem "motion_record"
```

On iOS, MotionRecord uses [motion-sqlite3](https://github.com/mattgreen/motion-sqlite3)
as a wrapper for connecting to SQLite, so add these too:

```ruby
gem "motion-sqlite3"
# Requires the most recent unpublished version of motion.h
# https://github.com/kastiglione/motion.h/issues/11
gem "motion.h", :git => "https://github.com/kastiglione/motion.h"
```

And then execute:

```
$ bundle
```

MotionRecord::Base
------------------

MotionRecord::Base provides a superclass for defining objects which are stored
in the database.

```ruby
class Message < MotionRecord::Base
  # That's all!
end
```

Attribute methods are inferred from the associated SQLite table definition.

```ruby
message = Message.new(subject: "Welcome!", body: "If you have any questions...")
# => #<Message: @id=nil @subject="Welcome!" @body="If you have any..." ...>
message.satisfaction
# => 0.0
```

Manage persistence with `save!`, `delete!`, and `persisted?`

```ruby
message = Message.new(subject: "Welcome!", body: "If you have any questions...")
message.save!
message.id
# => 1
message.delete!
message.persisted?
# => false
```

### Timestamp Columns

If any of the columns are named `created_at` or `updated_at`, then they are
automatically [serialized as Time objects](#motionrecordserialization) and set
to `Time.now` when the record is created or updated.

MotionRecord::Schema
--------------------

Define and run all pending SQLite migrations with the `up!` DSL.

```ruby
def application(application, didFinishLaunchingWithOptions:launchOptions)
  MotionRecord::Schema.up! do
    migration 1, "Create messages table" do
      create_table :messages do |t|
        t.text    :subject,      null: false
        t.text    :body
        t.integer :read_at
        t.integer :remote_id
        t.float   :satisfaction, default: 0.0
        t.timestamps
      end
    end

    migration 2, "Index messages table" do
      add_index :messages, :remote_id, :unique => true
      add_index :messages, [:subject, :read_at]
    end
  end
  # ...
end
```

#### Schema Configuration

By default, MotionRecord will print all SQL statements and use a file named
`"app.sqlite3"` in the application's Application Support folder. To disable
logging (for release) or change the filename, pass configuration options to `up!`

```ruby
resource_file = File.join(NSBundle.mainBundle.resourcePath, "data.sqlite3")
MotionRecord::Schema.up!(file: resource_file, debug: false) # ...
```

You can also specify that MotionRecord should use an in-memory SQLite database
which will be cleared every time the app process is killed.

```ruby
MotionRecord::Schema.up!(file: :memory) # ...
```

MotionRecord::Scope
-------------------

Build scopes on MotionRecord::Base classes with `where`, `order` and `limit`.

```ruby
Message.where(body: nil).order("read_at DESC").limit(3).find_all
```

Run queries on scopes with `exists?`, `first`, `find`, `find_all`, `pluck`,
`update_all`, and `delete_all`.

```ruby
Message.where(remote_id: 2).exists?
# => false
Message.find(21)
# => #<Message @id=21 @subject="What's updog?" ...>
Message.where(read_at: nil).pluck(:subject)
# => ["What's updog?", "What's updog?", "What's updog?"]
Message.where(read_at: nil).find_all
# => [#<Message @id=20 ...>, #<Message @id=21 ...>, #<Message @id=22 ...>]
Message.where(read_at: nil).update_all(read_at: Time.now.to_i)
```

Run calculations on scopes with `count`, `sum`, `maximum`, `minimum`, and
`average`.

```ruby
Message.where(subject: "Welcome!").count
# => 1
Message.where(subject: "How do you like the app?").maximum(:satisfaction)
# => 10.0
```

MotionRecord::Serialization
----------------------------------

SQLite has a very limited set of datatypes (TEXT, INTEGER, and REAL), but you
can easily store other objects as attributes in the database with serializers.

#### Built-in Serializers

MotionRecord provides a built-in serializer for Time objects to any column
datatype.

```ruby
class Message < MotionRecord::Base
  serialize :read_at, :time
end

Message.create!(subject: "Hello!", read_at: Time.now)
#    SQL: INSERT INTO messages (subject, body, read_at, ...) VALUES (?, ?, ?...)
# Params: ["Hello!", nil, 1420099200, ...]
Message.first.read_at
# => 2015-01-01 00:00:00 -0800
```

Boolean attributes can be serialized to INTEGER columns where 0 and NULL are
`false` and any other value is `true`.

```ruby
class Message < MotionRecord::Base
  serialize :satisfaction_submitted, :boolean
end
```

Objects can also be stored to TEXT columns as JSON.

```ruby
class Survey < MotionRecord::Base
  serialize :response, :json
end

survey = Survey.new(response: {nps: 10, what_can_we_improve: "Nothing :)"})
survey.save!
#    SQL: INSERT INTO surveys (response) VALUES (?)
# Params: ['{"nps":10, "what_can_we_improve":"Nothing :)"}']
Survey.first
# => #<Survey: @id=1 @response={"nps"=>10, "what_can_we_improve"=>"Nothing :)"}>
```

RubyMotion doesn't have a Date class, but as long as you're okay with using Time
objects with only the date attributes, you can serialize them to TEXT columns:

```ruby
class User < MotionRecord::Base
  serialize :birthday, :date
end

drake = User.new(birthday: Time.new(1986, 10, 24))
drake.save!
#    SQL: INSERT INTO users (birthday) VALUES (?)
# Params: ["1986-10-24"]
User.first.birthday
# => 1986-10-24 00:00:00 UTC
```

#### Custom Serializers

To write a custom serializer, extend MotionRecord::Serialization::BaseSerializer
and provide your class to `serialize` instead of a symbol.

```ruby
class MoneySerializer < MotionRecord::Serialization::BaseSerializer
  def serialize(value)
    raise "Wrong column type!" unless @column.type == :integer
    value.cents
  end

  def deserialize(value)
    raise "Wrong column type!" unless @column.type == :integer
    Money.new(value)
  end
end

class Purchase < MotionRecord::Base
  serialize :amount_paid_cents, MoneySerializer
end
```

MotionRecord::Association
-------------------------

[TODO](https://github.com/magoosh/motion_record/issues/7)


Contributing
------------

Please do!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
