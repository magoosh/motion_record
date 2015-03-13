MotionRecord
============

*Miniature ActiveRecord for RubyMotion*

MotionRecord provides the core parts of ActiveRecord needed to start using
SQLite as the datastore for your RubyMotion iOS or Android app.

Installation
------------

Add this line to your Gemfile:

```ruby
gem "motion_record"
```

On iOS, MotionRecord uses [motion-sqlite3](https://github.com/mattgreen/motion-sqlite3)
as a wrapper for connecting to SQLite. Add these lines to your Gemfile too:

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

* TODO: Android???

MotionRecord::Schema
--------------------

Define and run all pending SQLite migrations with the `up!` DSL.

```ruby
def application(application, didFinishLaunchingWithOptions:launchOptions)
  MotionRecord::Schema.up! do
    migration 1, "Create messages table" do
      create_table "messages" do |t|
        t.text    :subject,      null: false
        t.text    :body
        t.integer :read_at
        t.integer :remote_id
        t.float   :satisfaction, default: 0.0
      end
    end

    migration 2, "Index messages table" do
      add_index "messages", :remote_id, :unique => true
      add_index "messages", :read_at
    end
  end
  # ...
end
```

* TODO: Add timestamp columns?

#### Schema Configuration

By default, MotionRecord will print all SQL statements and use a file named
`"app.sqlite3"` in the application's Application Support folder. To disable
logging (for release) or change the filename, pass configuration options to `up!`

```ruby
resource_file = File.join(NSBundle.mainBundle.resourcePath, "data.sqlite3")
MotionRecord::Schema.up!(file: resource_file, debug: false) do
  #...
end
```

You can also specify that MotionRecord should use an in-memory SQLite database
which will be cleared every time the app process is killed.

```ruby
MotionRecord::Schema.up!(file: :memory) do
  #...
end
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

* TODO: Return "rows modified" count for update_all and delete_all

Run calculations on scopes with `count`, `sum`, `maximum`, `minimum`, and
`average`.

```ruby
Message.where(subject: "Welcome!").count
# => 1
Message.where(subject: "How do you like the app?").maximum(:satisfaction)
# => 10.0
```

* TODO: Handle datatype conversion in `where` and `update_all`

MotionRecord::AttributeSerializers
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

* TODO: Make JSON serializer cross-platform

#### Custom Serializers

To write a custom serializer, subclass MotionRecord::AttributeSerializers::BaseSerializer
and provide your class to `serialize` instead of a symbol.

```ruby
class MoneySerializer < MotionRecord::AttributeSerializers::BaseSerializer
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

* TODO: has_many and belongs_to


Contributing
------------

Please do!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
