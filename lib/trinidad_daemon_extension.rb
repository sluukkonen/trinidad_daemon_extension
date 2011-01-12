require 'rubygems'
gem 'trinidad_jars'
require 'trinidad/extensions'
require 'trinidad/jars'

require File.expand_path('../../trinidad-libs/akuma', __FILE__)
require File.expand_path('../../trinidad-libs/trinidad-daemon-extension', __FILE__)

module Trinidad
  module Extensions
    module Daemon
      VERSION = '0.2.5'
    end

    class DaemonServerExtension < ServerExtension
      def configure(tomcat)
        org.jruby.trinidad.TrinidadDaemon.new(tomcat, @options[:pid_file], logger_options, jvm_args)
      end

      def override_tomcat?; true; end

      def logger_options
        return if @options.has_key?(:nolog)
        log = @options[:log] || {}
        log[:file] ||= 'log/trinidad.log'

        level = log[:level] || 'INFO'
        unless %w{ALL CONFIG FINE FINER FINEST INFO OFF SEVERE WARNING}.include?(level)
          puts "Invalid log level #{level}, using default: INFO"
          level = 'INFO'
        end
        log[:level] = level
        log = Hash[log.map{|k, v| [k.to_s, v]}]

        Java::java.util.HashMap.new(log)
      end

      def jvm_args
        (@options[:jvm_args] ? @options[:jvm_args].split : []).to_java(:string)
      end
    end

    class DaemonOptionsExtension < OptionsExtension
      def configure(parser, default_options)
        parser.on('--daemonize', '--daemonize [PID_FILE]', 'run Trinidad as a daemon, pid_file by default is ENV[$TMPDIR]/trinidad.pid') do |pid|
          extensions = default_options[:extensions] || {}
          extensions[:daemon] = {:pid_file => pid}
          default_options[:extensions] = extensions
        end
      end
    end
  end
end
