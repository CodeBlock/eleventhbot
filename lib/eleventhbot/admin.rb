module EleventhBot
  class Admin
    include Plugin, Cinch::Plugin

    configru do
      option_array :masks, String
    end

    hook :pre, method: :admin?
    def admin?(m)
      admin = config.masks.any? {|mask| m.user.match(mask) }
      m.reply('You are not an administrator', true) unless admin
      admin
    end

    command :say, /say (\S+) (.+)/,
      'say {target} {thing}: Say something'
    def say(m, target, s)
      Target(target).msg(s)
    end

    command :action, /action (\S+) (.+)/,
      'action {target} {thing}: Do something'
    def action(m, target, s)
      Target(target).action(s)
    end

    command :nick, /nick(?: (\S+))?/,
      "nick [nick]: Change the bot's nick"
    def nick(m, nick)
      @bot.nick = nick || Configru.irc.nick
    end

    command :join, /join (\S+)(?: (\S+))?/,
      'join {channel} [key]: Join a channel'
    def join(m, channel, key)
      @bot.join(channel, key)
    end

    command :part, /part (\S+)(?: (.+))?/,
      'part {channel} [reason]: Leave a channel'
    def part(m, channel, reason)
      @bot.part(channel, reason)
    end

    command :plugins, /plugins/,
      'plugins: List loaded plugins',
      method: :plugins_cmd
    def plugins_cmd(m)
      plugins = loaded_plugins.map do |loaded|
        if plugin(loaded)
          loaded.plugin_name
        else
          "[#{loaded.plugin_name}]"
        end
      end
      m.reply(plugins.join(' '), true)
    end

    command :disable, /disable (\S+)/,
      'disable {plugin}: Disable a plugin'
    def disable(m, name)
      if plugin = plugin(name)
        @bot.plugins.unregister_plugin(plugin)
        m.reply("#{name} disabled", true)
      else
        m.reply("#{name} is not enabled", true)
      end
    end

    command :enable, /enable (\S+)/,
      'enable {plugin}: Enable a plugin'
    def enable(m, name)
      return m.reply("#{name} is already enabled", true) if plugin(name)
      if plugin = loaded_plugin(name)
        @bot.plugins.register_plugin(plugin)
        m.reply("#{name} enabled", true)
      else
        m.reply("#{name} does not exist", true)
      end
    end

    command :reload, /reload (\S+)/,
      'reload {plugin}: Reload a plugin'
    def reload(m, name)
      if plugin = plugin(name)
        @bot.plugins.unregister_plugin(plugin)
      else
        return m.reply("#{name} is not enabled", true)
      end

      begin
        load("eleventhbot/#{name}.rb")
      rescue Exception => e
        m.reply(e.message.capitalize, true)
        raise
      end

      if plugin = loaded_plugin(name)
        @bot.plugins.register_plugin(plugin)
        m.reply("#{name} reloaded", true)
      else
        m.reply("#{name} does not exist", true)
      end
    end
  end
end
