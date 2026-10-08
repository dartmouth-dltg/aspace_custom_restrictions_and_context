require 'digest'
require 'fileutils'

# Aggregates the plugin's css & js into one file each, named for a digest of the
# contents. The name only changes when the files do (cache busting without churn),
# concurrent processes agree on the name, and an already compiled set is never
# rewritten (so a read-only deploy works if the files were generated ahead of time).
class CssJsCompile

  def self.reaggregate_files(css_files, js_files, plugin_directory)
    plugin_name = plugin_directory.split("/")[-2]
    assets_dir = File.join(plugin_directory, "assets")

    css = compile_css(css_files)
    js = compile_js(js_files)
    asset_name = "#{plugin_name}-#{Digest::SHA256.hexdigest(css + js)[0, 32]}"

    write_if_missing(File.join(assets_dir, "#{asset_name}.css"), css)
    write_if_missing(File.join(assets_dir, "#{asset_name}.js"), js)

    Dir.glob(File.join(assets_dir, "#{plugin_name}-*")).each do |old|
      next if old.end_with?('.tmp') || File.basename(old, '.*') == asset_name
      File.delete(old)
    end

    asset_name
  end

  def self.compile_css(css_files)
    lines = ['@charset "utf-8";']
    css_files.each do |input_file|
      File.foreach(input_file) {|line| lines << line.chomp unless line.include?('@charset')}
    end

    lines.join("\n") + "\n"
  end

  def self.compile_js(js_files)
    js_files.map {|input_file| File.read(input_file).chomp + "\n"}.join
  end

  # write to a temp file and rename so readers never see a partial file
  def self.write_if_missing(path, content)
    return if File.exist?(path)

    tmp = "#{path}.#{Process.pid}.tmp"
    File.write(tmp, content)
    File.rename(tmp, path)
  end

end
