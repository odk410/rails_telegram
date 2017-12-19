#Rails_telegram
##기능
- 웹에서 메세지 입력시 Telegram Bot으로 출력하기
- 로그인, 로그아웃, 회원가입 가능
- 루트 페이지에 모든 메세지 기록 출력하기
- 보낸 메세지 모두 저장하기

## 조건문 한 줄로 사용하는 방법
- 조건에 맞으면 실행할 문장을 먼저 써주고 조건을 뒤에 써준다.
  ```ruby
    #만약 현재 유저가 로그인되어 있지 않다면 login페이지로 보내라.
    redirect_to '/users/login' unless current_user
  ```
## 컨트롤러 - application_controller.rb
- 모든 컨트롤러를 사용하기 전 가장 먼저 거쳐가는 곳
- 이 곳에서 함수를 정의하면 모든 컨트롤러에서 사용이 가능하다.
  ```ruby
  #아래의 함수를 이용하려면 current_user.email 이런식으로 사용 가능하다.
  def current_user
    #현재 로그인 되어있는 유저를 찾아 @user에 넣어준다.
    #session에 user_id가 있다면 앞의 문장을 실행해라...
    #if문을 한문장으로 사용할때 뒤에 붙여주면 된다.
    @user ||= User.find(session[:user_id]) if session[:user_id]
  end
  ```
- 만약 View에서 여기서 정의된 함수를 사용하고 싶다면 Helper에 등록해야한다.
  ```ruby
    # 여기서 등록을 해준다면 따로 Helpers로 가서 등록할 필요가 없다.
    helper_method :[함수명]
  ```

## 컨트롤러 - messages_controller.rb
- messages와 관련된 Controller
- 텔레그램의 bot과 관련된 Controller이다.
- 기능
  1. index
    - index에서 메세지를 입력하면 텔레그램의 bot이 메세지를 전달하고 입력한 모든 메세지를 보여주는 역할을 한다.
    - 때문에 messages변수에 @를 붙여 View에서도 사용가능하도록 설정
  2. send_msg
    - 메시지를 텔레그램으로 보내는 역할을 담당한다.
    - 메시지를 보내기 위해서는 url, token이 필요함.
    - 이는 telegram bot api를 구글에 검색하면 사용방법을 알 수 있음
    - token은 텔레그램의 BotFather에게서 알아낼 수 있다.
    - HTTParty를 이용해 HTML문서를 JSON으로 받아 올 수 있다.
    ```ruby
      url = "https://api.telegram.org/bot"
      token = Rails.application.secrets.telegram_token

      res = HTTParty.get("#{url}#{token}/getUpdates")
    ```
    - JSON.parse([받아온 문서].body)를 이용해 Hash형태로 변경해 변수로 저장할 수 있다.
    ```ruby
      hash = JSON.parse(res.body)
    ```
    - Bot이 메세지를 보내는 대상이 필요하다. 이는 대화를 한 내역이 있어야 상대방의 아이디를 알아낼 수 있다.
    - 원하는 대상의 아이디를 가져오는 방법은 아래와 같다.
    ```ruby
      #해시안에 있는 chat_id만 뽑아내기위해 계속 타고 들어간다.
      #계속 확인 할 때는 ap [변수명]를 이용해 console창에서 계속 확인하며 진행하면 된다.
      chat_id = hash["result"][0]["message"]["chat"]["id"]
    ```
    - 보낼 메세지를 편집해야 한다.
    ```ruby
      #URI.encode를 사용하는 이유는 한글을 사용하기 위해서
      text = URI.encode("#{current_user.email} : " + params[:msg])
    ```
    - 모든 준비가 끝나면 메시지를 보내주면 된다.
    ```ruby
      HTTParty.get("#{url}#{token}/sendMessage?chat_id=#{chat_id}&text=#{text}")
    ```
    - 마지막으로 보낸 메세지는 모두 저장해야 한다.
    ```ruby
      #보낸 메시지 저장하기
      Message.create(
        user_id: session[:user_id],
        content: params[:msg]
      )
    ```
    - 별도의 Rendering이 필요없기 때문에 루트페이지로 redirect_to 하면 된다.
- 로그인에 성공한 유저만 메시지를 보낼 수 있게 필터링 하는 기능을 한다.
```ruby
  #authorize함수은 application_controller에서 정의해준다.
  #여기서 불러준다.
  before_action :authorize
```
## 컨트롤러 - users_controller.rb
- 로그인, 로그아웃, 회원가입과 관련된 signup, register, login, login_session, logout 기능과 관련된 Controller
- signup - 폼으로 가입정보를 받아 /register로 넘겨주는 역할
- register - 입력받은 값을 params로 받아 User DB에 생성해주는 역할
  ```ruby
    def register
      User.create(
        email: params[:email],
        password: params[:password]
      )
      redirect_to '/'
    end
  ```
- login - 폼으로 로그인 정보를 받아 /login_session으로 넘겨준다.
- login_session - 로그인과 관련된 기능은 Session을 이용한다.
  기존 Sinatra에서는 enable을 통해서 Session을 사용한다고 알려야 하지만 rails에서는 그냥 사용가능하다.

- 로그인 기능
  ```ruby
    #아래에 계속 써야하기 때문에 변수에 담아 놓는다.
    user = User.find_by(email: params[:email])

    # 1. User DB에 아이디가 존재하는지 확인한다.
    # 2. 아이이가 존재하다면 User DB의 비밀번호와 입력받은 비밀번호가 일치하는지 확인한다.
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
  ```
- logout - 로그아웃 기능
  ```ruby
    #Session에 담고 있는 로그인 정보를 clear하면 로그아웃이 된다.
    session.clear
  ```

## Helpers
- Controller에서 전역으로 설정된 함수를 View에서도 사용할 수 있게 도와준다.
- Controller에서 아래의 코드를 등록 안했다면 Helpers에서 따로 등록해주어야한다.
  ```ruby
    helper_method :[함수명]
  ```

##models - message.rb, user.rb
- 두 개의 관계를 정의할 수 있다.
- User와 Message의 관계는 1:N이라고 볼 수 있다.
- 따라서 각 파일에 다음과 같은 설정을 해주어야 한다.
```ruby
  #message.rb
  class Message < ActiveRecord::Base
    belongs_to :user
  end

  #user.rb
  class User < ActiveRecord::Base
    has_many :messages
  end
```

##Views - layout
- 이 곳에 무언가를 만든다면 모든 View에서 다 보인다.
```ruby
  @전역함수와 관계를 설정했기에 가능한 코드이다.
  current_user.email
```

##몇 분전에 보낸 것인지 표시하는 방법
```ruby
  #message가 몇 분 전에 만들어졌는지 알려준다. 분으로
  time_ago_in_words(message.created_at)
```

##Config - routes.rb
- root를 사용해주면 내가 원하는 곳을 루트로 지정할 수 있다.
- get에서 [경로]와 [컨트롤러#기능]이 같다면 [컨트롤러#기능]을 생략할 수 있다.
```ruby
  #같은 의미이다.
  # get '/' => 'messages#index'
  root 'messages#index'

  get 'messages/index'
  get 'messages/send_msg'
```

##Config - secrets.yml
- git에 올릴 때 숨기고 싶은 내용을 이곳에서 설정한다.
```ruby
  development:
    secret_key_base: a75ac911d59b3c092f834c45e79e6ddf89acba6a9e3f70d4bce8a02508eeb10bde5a03fa42b4a5aacfde3a2f68678d1a41e6020133fe7915b68804dfb7b99a41
    [변수 명]: [숨기고 싶은 값]
```
- 여기서 설정한 [변수 명]으로 원래코드에서도 변경해주어야한다.

##DB
- DB설정을 하고 난 뒤 rake db:migrate 하기
- 수정할 것이 있다면 지금은 rake db:rollback을 사용하고 다시 migrate하기


##.gitignore
- scretes.yml에서 숨길 값을 설정했다면
- 여기서는 git에 올릴 때 무시할 파일을 설정하는 곳이다.
```ruby
  # Ignore all logfiles and tempfiles.
  /log/*
  !/log/.keep
  /tmp
  #무시할 파일명을 아래와 같이 적어준다.
  /config/secrets.yml
```

##Gemfile
- 사용할 Gem을 적는 곳
- Git bash에서 bundle install을 통해 여기서 설정한 모든 Gem을 설치할 수 있다.
