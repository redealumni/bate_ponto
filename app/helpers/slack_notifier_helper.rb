module SlackNotifierHelper
  
  def is_late_notification(user_name,minutes)
    notifier.ping ":clock10: *#{user_name}* chegou  atrasado(a) `#{minutes} minutos`!! :clock10:"
  end

  def missed_today_notification(user_name,minutes_late)
    minutes_exceeded = minutes_late - 10
    notifier.ping ":warning: *#{user_name}* faltou pois chegou muito atrasado(a)!! `#{minutes_exceeded} minutos` além do tolerado!!:warning: " if minutes_exceeded < 60
    notifier.ping ":warning: *#{user_name}* faltou pois chegou muito atrasado(a)!! `#{DatetimeHelper.readable_duration(minutes_exceeded*60)}` além do tolerado!!:warning: " if minutes_exceeded >= 60
  end

  def break_too_long_notification(user_name, minutes_exceeded)
    notifier.ping ":clock10: *#{user_name}* teve o intervalo muito grande, `#{minutes_exceeded} minutos` além do tolerado! :clock10:"
  end

  def missed_the_day_notification(user_name,day)
    notifier.ping ":warning: *#{user_name}* faltou no dia :date:`#{day.strftime("%d/%m/%Y")}` :warning:"
  end

  def forgot_punch_notification(user_name, slack_name)
    notifier.channel = slack_name
    notifier.ping ":clock10: *#{user_name}*, você esqueceu de bater o ponto na saída, preste mais atenção! :clock10:"
  end

  private
  def notifier
    @notifier ||= Slack::Notifier.new "https://hooks.slack.com/services/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", 
                            channel:  "#cagou_no_pau_no_ponto",
                            username: "Seu Zé da portaria"
  end

end
