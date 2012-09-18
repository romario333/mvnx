require 'term/ansicolor'
include Term::ANSIColor

module Console

  def self.info(message)
    puts message.bold
  end

  def self.attention(message)
    puts message.bold.cyan
  end

  def self.success(message)
    puts message.bold.green
  end

  def self.warning(message)
    puts message.yellow
  end

  def self.error(message)
    puts message.red.bold
  end

end