require 'guard'
require 'guard/guard'
require 'erb'

require 'sprockets'
require 'handlebars_assets'

module Guard
  class Sprockets < Guard
    def initialize(watchers=[], options={})
      super 
      
      ::Sprockets.register_engine '.hbs', HandlebarsAssets::TiltHandlebars

      # init Sprocket env for use later
      @sprockets_env = ::Sprockets::Environment.new
      
      @asset_paths = options.delete(:asset_paths) || []
      # add the asset_paths to the Sprockets env
      @asset_paths.each do |p|
        @sprockets_env.append_path p
      end
      # store the output destination
      @destination = options.delete(:destination)
      @opts = options
    end

    def start
       UI.info "Sprockets activated..."
       UI.info " -- external asset paths = [#{@asset_paths.inspect}]" unless @asset_paths.empty?
       UI.info " -- destination path = [#{@destination.inspect}]"
       UI.info "Sprockets is ready and waiting for some file changes..."
       run_all if options[:all_on_start]
    end
    
    def run_all
      run_on_change(Watcher.match_files(self, Dir.glob('**{,/*/**}/*.hbs')))
    end

    def run_on_change(paths)
      paths.each{ |js| sprocketize(js) }
      true
    end
    
    private
    
    def sprocketize(path)
      changed = Pathname.new(path)
      UI.info "Path is #{path}"

      #@sprockets_env.append_path changed.dirname

      output_basename = changed.basename.to_s
      output_basename = output_basename.split('.')[0..1].join('.')
      asset_name = "templates/#{output_basename}"

      output_file = Pathname.new(File.join(@destination, output_basename))
      UI.info "Sprockets started compiling #{output_file}"
      FileUtils.mkdir_p(output_file.parent) unless output_file.parent.exist?
      output_file.open('w') do |f|
        f.write @sprockets_env[asset_name]
      end
      UI.info "Sprockets finished compiling #{output_file}"
    end
  end
end
