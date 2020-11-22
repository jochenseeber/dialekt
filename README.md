# What is it?

With Dialekt you can easily define properties for DSL objects that support nice accessor methods, type checking and transformation.

Dialekt is based on [Docile], which is a great tool to create DSLs in Ruby. However, you will soon find yourself creating lots of repetetive code to implement your DSL accessors. Dialekt aims to simplify this task.

[Docile]: https://github.com/ms-ati/docile

## Example

Let's assume you want to create a build tool called Backscratcher (sort of a [small rake][Backscratcher] to scratch an itch :-) that uses a DSL for configuration. Your tool supports tasks and dependencies between tasks, and tasks can be grouped into namespaces. You start by creating a model and using Dialekt to define the properties.

[Backscratcher]: https://en.wikipedia.org/wiki/Backscratcher

```ruby
    require "dialekt"
    require "forwardable"

    module Backscratcher
      extend Forwardable

      class Task
        attr_reader :name

        # Create a set property containing strings
        dsl_set :dependencies, value_type: String

        def initialize(name:)
          @name = name
        end
      end

      class FileTask < Task
      end

      class Namespace
        attr_reader :name

        # Create a tasks hash with string keys
        dsl_map :tasks, key_type: String, value_type: Task do
          # Create an accessor for task entries
          entry :task, value_factory: ->(key:) { Task.new(name: key) }
          # Create an accessor for file task entries
          entry :file, value_type: FileTask, value_factory: ->(key:) { FileTask.new(name: key) }
        end

        # Create a namespace hash with string keys
        dsl_map :namespaces, key_type: String, value_type: Namespace do
          # Create an accessor for namespace entries
          entry :namespace, value_factory: ->(key:) { Namespace.new(name: key) }
        end

        def initialize(name:)
          @name = name
          @namespaces = {}
          @tasks = {}
        end
      end

      # Make some methods available in the root namespace for convenience
      def_delegators :root, :namespace, :task, :file

      def root
        @root ||= Namespace.new(name: "")
      end
    end

    include Backscratcher
```

You now have a DSL for your build tool giving you methods to create namespaces, tasks and dependencies. Dialekt will handle the definition of accessores, type checking, creating new collection entries and applying DSL configurations:

```ruby
    task "build" do
      dependency "db:create"
      dependency "db:load"
    end

    file "test.txt"

    namespace "db" do
      task "create"

      task "load" do
        dependencies ["db:create"]
      end
    end
```
