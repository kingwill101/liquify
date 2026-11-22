require 'json'
require 'liquid'

class FixtureFileSystem
  def initialize(partials)
    @partials = partials
  end

  def read_template_file(name)
    @partials.fetch(name) { raise Liquid::FileSystemError, "Missing partial: #{name}" }
  end
end

results = JSON.parse($stdin.read).map do |fixture|
  environment = Liquid::Environment.build do |env|
    env.file_system = FixtureFileSystem.new(fixture.fetch('partials', {}))
  end
  begin
    template = Liquid::Template.parse(fixture.fetch('source'), environment: environment)
    { 'output' => template.render!(fixture.fetch('data', {}), strict_filters: true) }
  rescue Liquid::Error => error
    { 'error' => "#{error.class}: #{error.message}" }
  end
end

puts JSON.generate(results)
