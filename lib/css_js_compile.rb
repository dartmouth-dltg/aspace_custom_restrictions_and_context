require 'securerandom'

class CssJsCompile

  def self.compiled_asset_name(plugin_name)
    plugin_name + "-" + SecureRandom.hex
  end

  def self.reaggregate_files(css_files, js_files, plugin_directory)

    plugin_name = plugin_directory.split("/")[-2]

    old_aggregated_files = Dir.glob(File.join(plugin_directory, "assets", "#{plugin_name}-*"))

    old_aggregated_files.each do |oaf|
      File.delete(oaf) if File.exist?(oaf)
    end

    asset_name = compiled_asset_name(plugin_name)
    compile_css(css_files, asset_name, plugin_directory)
    compile_js(js_files, asset_name, plugin_directory)

    asset_name

  end

  def self.compile_css(css_files, asset_name, plugin_directory)    

    File.open(File.join(plugin_directory, "assets", "#{asset_name}.css"), "w") do |output_file|
      output_file.puts '@charset "utf-8";'
      css_files.each do |input_file|
        File.open(input_file) do |file|
          file.each { |line|
            unless line.include?('@charset')
              output_file.puts line
            end
          }
        end
      end
    end
  end

  def self.compile_js(js_files, asset_name, plugin_directory)

    File.open(File.join(plugin_directory, "assets", "#{asset_name}.js"), "w") do |output_file|
      js_files.each do |input_file|
        File.open(input_file) do |file|
          file.each { |line| output_file.puts line }
        end
      end
    end

  end

end
