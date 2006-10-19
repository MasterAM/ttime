require 'logic/repy'
require 'open-uri'
require 'pathname'
require 'gettext'

#require 'yaml'

GetText::bindtextdomain("ttime", "locale", nil, "utf-8")

module TTime
  class Data
    include GetText

    attr_reader :data

    def initialize(&status_report_proc)
      @status_report_proc = status_report_proc
      @status_report_proc = proc {} if @status_report_proc.nil?

      if USE_YAML && File::exists?(YAML_File)
        report _("Loading technion data from YAML")
        @data = File.open(YAML_File) { |yf| YAML::load(yf.read) }
      elsif File::exists?(MARSHAL_File)
        report _("Loading technion data")
        @data = File.open(MARSHAL_File) { |mf| Marshal.load(mf.read) }
      elsif File::exists?(REPY_File)
        @data = convert_repy
      else
        @data = download_repy
      end
    end
    
    private

    USE_YAML = false

    DATA_DIR = Pathname.new "data/"

    REPY_Zip_filename = "REPFILE.zip"
    REPY_Zip = DATA_DIR + REPY_Zip_filename
    REPY_File = DATA_DIR + "REPY"
    REPY_URI = "http://ug.technion.ac.il/rep/REPFILE.zip"
    YAML_File = DATA_DIR + "technion.yml"
    MARSHAL_File = DATA_DIR + "technion.mrshl"

    def convert_repy
      report _("Loading data from REPY")
      if USE_YAML
        update_yaml
      else
        update_marshal
      end
    end

    def download_repy
      report _("Downloading REPY file from Technion")

      open(REPY_URI) do |in_file|
        open(REPY_Zip,"w") do |out_file|
          out_file.write in_file.read
        end
      end

      report _("Extracting REPY file"), 0.5

      # FIXME: This kinda won't work on anything non-UNIX
      `bash -c 'cd #{DATA_DIR} && unzip #{REPY_Zip_filename} && rm #{REPY_Zip_filename}'`

      convert_repy
    end

    def load_repy
      Logic::Repy.new(open(REPY_File) { |f| f.read }, &@status_report_proc)
    end

    def update_yaml
      _repy = load_repy
      open(YAML_File,"w") { |f| f.write YAML::dump(_repy.hash) }
      _repy.hash
    end

    def update_marshal
      _repy = load_repy
      open(MARSHAL_File,"w") { |f| f.write Marshal.dump(_repy.hash) }
      _repy.hash
    end

    def report(text,frac = 0)
      @status_report_proc.call(text,frac)
    end
  end
end