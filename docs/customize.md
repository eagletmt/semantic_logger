---
layout: default
---

## Custom Formatters

The formatting for each appender can be replaced with custom code. To replace the
existing formatter supply a block of code when creating the appender.

The formatter proc receives a single parameter which is the entire `Log Struct`.
For the format of the `Log Struct`, see [Log Struct](log_struct.html)

#### Example: Formatter that just returns the Log Struct

~~~ruby
require "semantic_logger"

SemanticLogger.default_level = :trace

formatter = Proc.new do |log|
  # This formatter just returns the log struct as a string
  log.inspect
end
SemanticLogger.add_appender(io: $stdout, formatter: formatter)

logger = SemanticLogger["Hello"]
logger.info "Hello World"
~~~
Output:

    #<struct SemanticLogger::Log level=:info, thread_name=70167090649820, name="Hello", message="Hello World", payload=nil, time=2012-10-24 10:09:33 -0400, duration=nil, tags=nil, level_index=2>


#### Example: Replace the default log file formatter

~~~ruby
require "semantic_logger"
SemanticLogger.default_level = :trace
~~~

Create a custom formatter:
~~~ruby
class MyFormatter < SemanticLogger::Formatters::Default
  # Return the complete log level name in uppercase
  def level
    log.level.upcase
  end
end
~~~

Specify the formatter when creating the appender:
~~~ruby
SemanticLogger.add_appender(file_name: "development.log", formatter: MyFormatter.new)
~~~

Example usage:
~~~ruby
Rails.logger.info "Hello World"

# => 2017-04-05 01:05:52.868286 INFO [13143:70216759638540 (irb):11] Rails -- Hello World
~~~

See [SemanticLogger::Formatters::Default](https://github.com/reidmorrison/semantic_logger/blob/master/lib/semantic_logger/formatters/default.rb) for all the methods that can be replaced to customize the output.

#### Example: Replace the colorized log file formatter

~~~ruby
require "semantic_logger"
SemanticLogger.default_level = :trace
~~~

Create a custom formatter:
~~~ruby
class MyFormatter < SemanticLogger::Formatters::Color
  # Return the complete log level name in uppercase
  def level
    "#{color}log.level.upcase#{clear}"
  end
end
~~~

Specify the formatter when creating the appender:
~~~ruby
SemanticLogger.add_appender(file_name: "development.log", formatter: MyFormatter.new)
~~~

Example usage:
~~~ruby
Rails.logger.info "Hello World"

# => 2017-04-05 01:05:52.868286 INFO [13143:70216759638540 (irb):11] Rails -- Hello World
~~~

See [SemanticLogger::Formatters::Color](https://github.com/reidmorrison/semantic_logger/blob/master/lib/semantic_logger/formatters/color.rb) for all the methods that can be replaced to customize the output.

#### Example: Replacing the format for an active logger, such as in Rails:

This example assumes you have `gem "rails_semantic_logger"` in your Gemfile.

Create a file called `config/initializers/semantic_logger.rb`:

~~~ruby
# Find file appender:
appender = SemanticLogger.appenders.find{ |a| a.is_a?(SemanticLogger::Appender::File) }

appender.formatter = MyFormatter.new
~~~

#### Example: Do not log the process ID

When running docker containers with a single process which is always 1, or when running only one
process on a server the PID ( Process ID ) is not relevant.

To leave out the pid, we can use a custom formatter:

```ruby
class NoPidFormatter < SemanticLogger::Formatters::Default
  # Leave out the pid
  def pid
  end
end
```

Specify the formatter when creating the appender:

```ruby
SemanticLogger.add_appender(file_name: "development.log", formatter: NoPidFormatter.new)
```

Or to use the colorized formatter, use `SemanticLogger::Formatters::Color` instead of 
`SemanticLogger::Formatters::Default`.

Or if the appender is already installed:
```ruby
SemanticLogger.appenders.first.formatter = NoPidFormatter.new
```

## Custom Appender

To write your own log appender it should meet the following requirements:

* Inherit from `SemanticLogger::Subscriber`
* In the initializer connect to the resource being logged to
* Implement #log(log) which needs to write to the relevant resource
* Implement #flush if the resource can be flushed
* Write a test for the new appender

The #log method takes the `Log Struct` as a parameter.
For the format of the `Log Struct`, see [Log Struct](log_struct.html)

Basic outline for an Appender:

~~~ruby
require "semantic_logger"

class SimpleAppender < SemanticLogger::Subscriber
  attr_reader :host
  
  # Add additional arguments to the initializer while supporting all existing ones.
  def initialize(host: host, **args, &block)
    @host = host
    super(**args, &block)
  end

  # Display the log struct and the text formatted output
  def log(log)
    # Display the raw log structure
    p log

    # Display the formatted output
    puts formatter.call(log)
  end

  # Optional
  def flush
    puts "Flush :)"
  end

  # Optional
  def close
    puts "Closing :)"
  end
end
~~~

Sample program calling the above appender:

~~~ruby
SemanticLogger.default_level = :trace
# Log to file dev.log
SemanticLogger.add_appender(file_name: "dev.log")
# Also log the above sample appender
SemanticLogger.add_appender(appender: SimpleAppender.new)

logger = SemanticLogger["Hello"]
logger.info "Hello World"
~~~

Look at the [existing appenders](https://github.com/reidmorrison/semantic_logger/tree/master/lib/semantic_logger/appender) for good examples

### Tests

To have your custom appender included in the standard list of appenders, submit it along
with complete working tests.
See the [Graylog Appender Test](https://github.com/reidmorrison/semantic_logger/blob/master/test/appender/graylog_test.rb) for an example.

## Design

This section introduces the internal design of Semantic Logger, which will be helpful for anyone
that wants to contribute changes for others in the community to take advantage of.

### Log message flow diagram

Shows how log messages events are emitted from the various log instances, placed in the in-memory queue,
and then written to one or more appenders on a separate thread.

![Log message flow diagram](images/log_event_flow.png "Flow Diagram")

### Class Diagram

![Class diagram](images/class_diagram.png "Class Diagram")

### [Next: Log Event ==>](log_struct.html)
