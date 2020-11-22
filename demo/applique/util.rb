# frozen_string_literal: true

require "pathname"

def command_env
  {
    "PATH" => @path.join(File::PATH_SEPARATOR),
  }
end

Before do
  @current_directory = Pathname.pwd

  raise "Current directory does not contain '/tmp/'" unless @current_directory.to_s.include?("/tmp/")

  @current_directory.glob("*").each(&:rmtree)
  @root_directory = Pathname(QED::Utils.root)

  @path = [@root_directory / "cmd"]

  ENV["PATH"]&.then do |path|
    @path += path.split(File::PATH_SEPARATOR).map { |p| Pathname(p) }
  end
end

When %r{run the following command}i do |text|
  text.lines.map(&:chomp).reject(&:empty?).each do |line|
    system(command_env, line, exception: true)
  end
end

When %r{create [^.]*file [^.]*`(.+)` with [^.]*content}i do |file_name, text|
  file = Pathname(file_name).cleanpath
  raise "File name must be reltive" unless file.relative?

  file.dirname.mkpath unless file.dirname.exist?
  file.write(text)
end
