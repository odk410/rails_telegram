class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #아래의 함수를 이용하려면 current_user.email 이런식으로 사용 가능하다.
  def current_user
    #현재 로그인 되어있는 유저를 찾아 @user에 넣어준다.
    #session에 user_id가 있다면 앞의 문장을 실행해라...
    #if문을 한문장으로 사용할때 뒤에 붙여주면 된다.
    @user ||= User.find(session[:user_id]) if session[:user_id]
  end

  #before_action "함수명"
  #모든 컨트롤러가 발동되기 이전에
  #유저가 접속되어있는지 확인한다.
  def authorize #로그인 되었는지 판별하라
    redirect_to '/users/login' unless current_user
  end

  helper_method :current_user
end
