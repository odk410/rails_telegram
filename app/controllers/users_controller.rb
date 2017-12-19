class UsersController < ApplicationController
  def signup
    #폼으로 가입정보를 받아 /register
  end

  def register
    User.create(
      email: params[:email],
      password: params[:password]
    )
    redirect_to '/'
  end

  def login
    # 폼으로 로그인 정보를 받아 /login_session
  end

  def login_session

    user = User.find_by(email: params[:email])

    if user
      if user.password == params[:password]
        session[:user_id] = user.id
        redirect_to '/'
      else
        puts "비밀번호가 틀렸습니다."
        redirect_to '/users/login'
      end
    else
      redirect_to '/users/signup'
    end

  end

  def logout
    session.clear
    redirect_to '/'
  end
end
