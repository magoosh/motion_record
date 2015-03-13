unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  # if Motion::Project.constants.include? :IOSConfig 
  #   # config for iOS app
  # end

  # if Motion::Project.constants.include? :AndroidConfig
  #   # config for Android app
  # end

  dirname = File.dirname(__FILE__)

  serial_files = Dir.glob(File.join(dirname, 'motion_record/serialization/*.rb'))
  conn_files   = Dir.glob(File.join(dirname, 'motion_record/connection_adapters/*.rb'))
  schema_files = Dir.glob(File.join(dirname, 'motion_record/schema/*.rb'))
  base_files   = Dir.glob(File.join(dirname, 'motion_record/*.rb'))

  # RubyMotion for Android can't infer file dependencies so we must explicitly
  # declare their compilation order
  (base_files + schema_files + conn_files + serial_files).reverse.each do |file|
    app.files.unshift(file)
  end

  # Some files don't have the same dependency order and alphabetic order
  {
    "motion_record/persistence.rb" => "motion_record/scope_helpers.rb"
  }.each do |file, dependency|
    app.files_dependencies File.join(dirname, file) => File.join(dirname, dependency)
  end
end

module MotionRecord
  # Your code goes here...
end
