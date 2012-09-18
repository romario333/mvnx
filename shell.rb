require 'pty'
# TODO: proc potrebuje tohle? melo by mu stacit console
# TODO: sloucit shell a console do jednoho
require 'term/ansicolor'
include Term::ANSIColor

require_relative "console"

module Shell

  def shell(command, options = {})
    puts "$ #{command}".dark

    system(command)

    if $? != 0
      Console.error("Shell command returned #{$?}.")
      # TODO: tohle je divny, ma to smysl?
      if options[:terminate_on_error] == nil || options[:terminate_on_error]
        raise TerminateException.new("Shell command returned #{$?}.")
      end
    end
  end

  def shell_ex(command, options = {}, &line_callback)
    puts "$ #{command}".dark

    # TODO: doc, ktere options jsou k dispozici
    return_code = pty_shell(command, options, &line_callback)
    if return_code != 0
      error = "Shell command returned #{$?}."
      if line_callback != nil
        line_callback.call(error)
      end
      Console.error(error)

      if options[:terminate_on_error] == nil || options[:terminate_on_error]
        raise TerminateException.new(error)
      end
    end
    return_code

  end

private

  def pty_shell(command, options = {}, &line_callback)
    begin
      output_filters = options[:output_filters]
      if output_filters.nil?
        output_filters = []
      end


      PTY.spawn( command ) do |r, w, pid|
        begin

          interrupt_requested = false

          while true
            begin
              r.each do |line|

                if line_callback != nil
                  line_callback.call(line)
                end

                for filter in output_filters
                  line = filter.process(line)
                end

                print line
              end
            rescue Interrupt

              if !interrupt_requested
                # 1st attempt - send SIGINT to the spawned process and its children
                Console.error("Interrupt requested, forwarding to process group #{-pid}")
                Process.kill 'SIGINT', -pid
                interrupt_requested = true
              else
                # 2nd attempt - kill that b$#!h
                Console.error("Interrupt requested for the second time, KILLING process group #{-pid}")
                Process.kill 'SIGKILL', -pid
              end

            end
          end

        rescue Errno::EIO
          exit_status = PTY.check(pid)
          if exit_status == nil
            # FIXME: examine what's going on in here, unfortunately this cannot be reproduced reliably
            # process is still alive, wait and re-read exit status
            sleep(0.25)
            exit_status = PTY.check(pid)
          end
          return exit_status
        end
      end
    rescue PTY::ChildExited => e
      # child process exited, I'm not sure when this happens
      Console.error("The child process exited - so WHEN EXACTLY DOES THIS HAPPEN?")
      Console.error("Exception: #{e}.")
      return e.status.exitstatus
    end
  end


end
