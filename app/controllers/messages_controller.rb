class MessagesController < ApplicationController

  #before_action를 설정해서 로그인한 유저들만 아래의 기능을 사용할 수 있다.
  before_action :authorize

  def index
    #지금까지 보낸 메시지 보여주기
    @messages = Message.all.reverse
  end

  def send_msg
    url = "https://api.telegram.org/bot"
    token = Rails.application.secrets.telegram_token

    res = HTTParty.get("#{url}#{token}/getUpdates")
    hash = JSON.parse(res.body)
    chat_id = hash["result"][0]["message"]["chat"]["id"]
    text = URI.encode("#{current_user.email} : " + params[:msg])
    #params[:msg]

    HTTParty.get("#{url}#{token}/sendMessage?chat_id=#{chat_id}&text=#{text}")
    #보낸 메시지 저장하기
    Message.create(
      user_id: session[:user_id],
      content: params[:msg]
    )

    redirect_to '/'
  end
end
